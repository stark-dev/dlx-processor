library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.DLX_package.all;

ENTITY ALU IS
  generic (N : integer := 32);          -- N needs to be an even number
  port 	 ( RST_N               : IN std_logic;
           Clk                 : IN std_logic;
           E2_MUL_EN           : IN std_logic;
           E3_MUL_EN           : IN std_logic;
           E2_ADD_EN           : IN std_logic;
           E3_ADD_EN           : IN std_logic;
           E4_ADD_EN           : IN std_logic;
           FUNC                : IN aluOp;
           ALU_OUT_SEL         : IN std_logic_vector(1 downto 0);
           ROUNDING_MODE       : IN std_logic_vector(1 downto 0);
           DATA1               : IN std_logic_vector(N-1 downto 0);
	         DATA2               : IN std_logic_vector(N-1 downto 0);
           OUTALU              : OUT std_logic_vector(N-1 downto 0);
           OVERFLOW            : OUT std_logic;
           UNDERFLOW           : OUT std_logic;
           INVALID             : OUT std_logic;
           CARRY               : OUT std_logic;
           ZERO                : OUT std_logic);
END ALU;

ARCHITECTURE Structural OF ALU IS

  ----------------------------------------------------------------
  -- constants
  ----------------------------------------------------------------

  constant zeros : std_logic_vector(N-1 downto 1) := (others => '0');

  ----------------------------------------------------------------
  -- logicals signals
  ----------------------------------------------------------------

  signal logical_in1 : std_logic_vector(N-1 downto 0);
  signal logical_in2 : std_logic_vector(N-1 downto 0);
  signal logical_sel_s0, logical_sel_s1 : std_logic;         --select the logical function that is to be performed
                                                             -- AND --> S0 = 0, S1 = 1
                                                             -- OR  --> S0 = 1, S1 = 1
                                                             -- XOR --> S0 = 1, S1 = 0
  signal logical_out : std_logic_vector(N-1 downto 0);       --output signal of the logicals block
  signal logicals_latch_en : std_logic;

  ----------------------------------------------------------------
  -- Shifter signals
  ----------------------------------------------------------------

  signal arith_logicaln : std_logic;                          -- decides if the shift operation is logical or arithmetical
  signal right_leftn : std_logic;	                            -- decides if the shift operation is left or right
  signal shifter_out : std_logic_vector(N-1 downto 0);	      -- output signal of the shifter
  signal shifter_latch_en : std_logic;
  signal shifter_in1 : std_logic_vector(N-1 downto 0);
  signal shifter_in2 : std_logic_vector(N-1 downto 0);

  ----------------------------------------------------------------
  -- Adder / Subtractor signals
  ----------------------------------------------------------------

  constant carry_freq : integer := 4;
  signal adder_in1 : std_logic_vector(N-1 downto 0);
  signal adder_in2 : std_logic_vector(N-1 downto 0);
  signal addn_sub : std_logic;                                -- decides if the operation is ADD or SUB
  signal carry_int : std_logic;                                 -- carry out of the adder
  signal carry_out : std_logic;                               -- carry out of the adder
  signal overflow_p4 : std_logic;                             -- overflow signal of the adder
  signal overflow_int : std_logic;                            -- overflow signal of the integer pipe
  signal invalid_int  : std_logic;
  signal adder_out : std_logic_vector(N-1 downto 0);          -- output of the adder
  signal adder_latch_en : std_logic;

  ----------------------------------------------------------------
  -- Comparator signals
  ----------------------------------------------------------------

  signal comp_op : std_logic_vector(2 downto 0);            -- decides the operation of the comparator (>, >=, <; <= or =)
  signal signed_unsignedn : std_logic;                      -- decides if the numbers are considered signed or unsigned
  signal comparator_out : std_logic;                        -- output signal of the comparator

  ----------------------------------------------------------------
  -- LHI signals
  ----------------------------------------------------------------

  signal imm16_ext : std_logic_vector(Nbit-1 downto 0);            -- extends ALU port B

  ----------------------------------------------------------------
  -- I2FP signals
  ----------------------------------------------------------------

  signal i2fp_in       : std_logic_vector(N-1 downto 0);
  signal i2fp_out      : std_logic_vector(Nbit-1 downto 0);
  signal i2fp_latch_en : std_logic;

  ----------------------------------------------------------------
  -- FP2I signals
  ----------------------------------------------------------------

  signal fp2i_in       : std_logic_vector(N-1 downto 0);
  signal fp2i_out      : std_logic_vector(Nbit-1 downto 0);
  signal fp2i_overflow : std_logic;
  signal fp2i_invalid  : std_logic;
  signal fp2i_latch_en : std_logic;

  ----------------------------------------------------------------
  -- MUL signals
  ----------------------------------------------------------------

  signal mul_in1            : std_logic_vector(N-1 downto 0);
  signal mul_in2            : std_logic_vector(N-1 downto 0);
  signal mul_latch_en       : std_logic;
  signal mult_int_FPn       : std_logic;
  signal mult_S_Un          : std_logic;
  signal mult_overflow      : std_logic;
  signal mult_underflow     : std_logic;
  signal mult_invalid       : std_logic;

  ----------------------------------------------------------------
  -- fp add signals
  ----------------------------------------------------------------

  signal fp_add_in1         : std_logic_vector(N-1 downto 0);
  signal fp_add_in2         : std_logic_vector(N-1 downto 0);
  signal fp_add_latch_en    : std_logic;
  signal fp_add_overflow    : std_logic;
  signal fp_add_underflow   : std_logic;
  signal fp_add_invalid     : std_logic;

  ----------------------------------------------------------------
  -- other signals
  ----------------------------------------------------------------

  signal outalu_s            : std_logic_vector(N-1 downto 0);
  signal outalu_int          : std_logic_vector(N-1 downto 0);
  signal outalu_mul          : std_logic_vector(N-1 downto 0);
  signal outalu_add          : std_logic_vector(N-1 downto 0);

  ----------------------------------------------------------------
  -- Components
  ----------------------------------------------------------------

  component LATCH
    GENERIC  (N     : integer := 32);
    PORT (  Rst_n : in  std_logic;
            Clk   : in  std_logic;
            D     : in  std_logic_vector(N-1 downto 0);
            Q     : out std_logic_vector(N-1 downto 0));
  end component;

  component logicals IS
    generic(N : integer := 32);
    port(	S0 : IN std_logic;
    S1 : IN std_logic;
    R1 : IN std_logic_vector(N-1 downto 0);
    R2 : IN std_logic_vector(N-1 downto 0);
    D_OUT : OUT std_logic_vector(N-1 downto 0));
  end component;

  component Shifter IS
    generic(N : integer := 32);
    port( 	R	       : IN std_logic_vector(N-1 downto 0);
    arith_logicaln : IN std_logic;
    right_leftn    : IN std_logic;
    count	       : IN std_logic_vector(4 downto 0);
    R_OUT	       : OUT std_logic_vector(N-1 downto 0));
  end component;

  component p4_adder
    generic( N : integer := 32;
    C_freq : integer :=4);
    port( A, B : in std_logic_vector(N downto 1);
    Cin  : in std_logic;
    S    : out std_logic_vector(N downto 1);
    Cout : out std_logic;
    V    : out std_logic);
  end component;

  component comparator
    generic(N : integer := 32);
    port(	SUM   : IN  std_logic_vector(N-1 downto 0);
    CARRY : IN  std_logic;
    V     : IN  std_logic;
    OP    : IN  std_logic_vector(2 downto 0);
    S_Un  : IN  std_logic;
    RES   : OUT std_logic);
  end component;

  component INT2FP_CONVERTER
    PORT( DATA_IN       : IN std_logic_vector(31 downto 0);
          ROUNDING_MODE : IN std_logic_vector(1 downto 0);
          DATA_OUT      : OUT std_logic_vector(31 downto 0)
    );
  end component;

  component FP2INT_CONVERTER
    PORT( DATA_IN       : IN std_logic_vector(31 downto 0);
          ROUNDING_MODE : IN std_logic_vector(1 downto 0);
          DATA_OUT      : OUT std_logic_vector(31 downto 0);
          OVERFLOW      : OUT std_logic;
          INVALID       : OUT std_logic
    );
  end component;

  component FP_mult is
    port( CLK : IN std_logic;
          RST_N : IN std_logic;
          FIRST_STAGE_EN : IN std_logic;
          SECOND_STAGE_EN : IN std_logic;
          A : IN std_logic_vector(31 downto 0);
          B : IN std_logic_vector(31 downto 0);
          int_FPn: IN std_logic;
          S_Un : IN std_logic;
          rounding_mode : IN std_logic_vector(1 downto 0);
          product : OUT std_logic_vector(31 downto 0);
          overflow : OUT std_logic;
          underflow : OUT std_logic;
          invalid : OUT std_logic);

  end component;

  component FP_adder is
    PORT( CLK : IN std_logic;
          RST_N : IN std_logic;
          A1 : IN std_logic_vector(Nbit-1 downto 0);
          A2 : IN std_logic_vector(Nbit-1 downto 0);
          STAGE2_EN : IN std_logic;
          STAGE3_EN : IN std_logic;
          STAGE4_EN : IN std_logic;
          ADDn_SUB : IN std_logic;
          ROUNDING_MODE : IN std_logic_vector(1 downto 0);
          SUM : OUT std_logic_vector(Nbit-1 downto 0);
          OVERFLOW : OUT std_logic;
          UNDERFLOW : OUT std_logic;
          INVALID : OUT std_logic);
  end component;

BEGIN

latch_1 : LATCH
  generic map(N)
  port map(RST_N, logicals_latch_en, DATA1, logical_in1);

latch_2 : LATCH
  generic map(N)
  port map(RST_N, logicals_latch_en, DATA2, logical_in2);

latch_3 : LATCH
  generic map(N)
  port map(RST_N, adder_latch_en, DATA1, adder_in1);

latch_4 : LATCH
  generic map(N)
  port map(RST_N, adder_latch_en, DATA2, adder_in2);

latch_5 : LATCH
  generic map(N)
  port map(RST_N, shifter_latch_en, DATA1, shifter_in1);

latch_6 : LATCH
  generic map(N)
  port map(RST_N, shifter_latch_en, DATA2, shifter_in2);

latch_7 : LATCH
  generic map(N)
  port map(RST_N, fp2i_latch_en, DATA1, fp2i_in);

latch_8 : LATCH
  generic map(N)
  port map(RST_N, i2fp_latch_en, DATA1, i2fp_in);

latch_9 : LATCH
  generic map(N)
  port map(RST_N, fp_add_latch_en, DATA1, fp_add_in1);

latch_10 : LATCH
  generic map(N)
  port map(RST_N, fp_add_latch_en, DATA2, fp_add_in2);

latch_11 : LATCH
  generic map(N)
  port map(RST_N, mul_latch_en, DATA1, mul_in1);

latch_12 : LATCH
  generic map(N)
  port map(RST_N, mul_latch_en, DATA2, mul_in2);

alu_logicals : logicals
  generic map(N)
  port map(logical_sel_s0, logical_sel_s1, DATA1, DATA2, logical_out);

alu_shifter : Shifter
  generic map(N)
  port map(DATA1, arith_logicaln, right_leftn, DATA2(4 downto 0), shifter_out);

alu_adder : p4_adder
  generic map(N, carry_freq)
  port map(DATA1, DATA2, addn_sub, adder_out, carry_out, overflow_p4);

alu_comparator : comparator
    generic map(N)
    port map(adder_out, carry_out, overflow_p4, comp_op, signed_unsignedn, comparator_out);

  imm16_ext(Nbit-1 downto 16) <= DATA2(15 downto 0);
  imm16_ext(15 downto 0) <= (others => '0');

i2fp : INT2FP_CONVERTER
  port map(i2fp_in, ROUNDING_MODE, i2fp_out);

fp2i : FP2INT_CONVERTER
  port map(fp2i_in, ROUNDING_MODE, fp2i_out, fp2i_overflow, fp2i_invalid);

mult_FP : FP_mult
  port map(CLK, RST_N, E2_MUL_EN, E3_MUL_EN, mul_in1, mul_in2, mult_int_FPn, mult_S_Un,
          ROUNDING_MODE, outalu_mul, mult_overflow, mult_underflow, mult_invalid);

add_FP : FP_adder
  port map(CLK, RST_N, fp_add_in1, fp_add_in2, E2_ADD_EN, E3_ADD_EN, E4_ADD_EN, addn_sub, ROUNDING_MODE,
           outalu_add, fp_add_overflow, fp_add_underflow, fp_add_invalid);

OUTALU <= outalu_s;

outalu_s <= outalu_add when ALU_OUT_SEL = "10" else
            outalu_mul when ALU_OUT_SEL = "01" else
            outalu_int;

OVERFLOW <= fp_add_overflow when ALU_OUT_SEL = "10" else
            mult_overflow when ALU_OUT_SEL = "01" else
            overflow_int;

UNDERFLOW <= fp_add_underflow when ALU_OUT_SEL = "10" else
            mult_underflow when ALU_OUT_SEL = "01" else
            '0';

INVALID  <= fp_add_invalid when ALU_OUT_SEL = "10" else
            mult_invalid when ALU_OUT_SEL = "01" else
            invalid_int;

ZERO <= '1' when or_reduce(outalu_s) = '0' else
        '0';

CARRY <= carry_int when ALU_OUT_SEL = "00" else
         '0';

  P_ALU: process (FUNC, adder_out, comparator_out, shifter_out, logical_out, overflow_p4,
                  fp2i_out, i2fp_out, fp2i_overflow, fp2i_invalid, carry_out, imm16_ext, DATA1,
                  mult_overflow, mult_underflow, fp_add_overflow, fp_add_underflow)
  begin
    logicals_latch_en  <= '0';
    adder_latch_en     <= '0';
    shifter_latch_en   <= '0';
    i2fp_latch_en      <= '0';
    fp2i_latch_en      <= '0';
    mul_latch_en       <= '0';
    fp_add_latch_en    <= '0';
    mult_int_FPn       <= '0';
    mult_S_Un          <= '1';
    logical_sel_s0     <= '0';
    logical_sel_s1     <= '1';
    arith_logicaln     <= '0';
    right_leftn        <= '0';
    addn_sub           <= '0';
    comp_op            <= "000";
    signed_unsignedn   <= '0';
    outalu_int         <= adder_out;
    overflow_int       <= '0';
    invalid_int        <= '0';
    carry_int          <= '0';

    case FUNC is
      when NOP_OP 	=> null;
	    when ADD_OP 	=>  adder_latch_en  <= '1';
                        addn_sub <= '0';
                        outalu_int <= adder_out;
                        overflow_int <= overflow_p4;
                        carry_int <= carry_out;
      when ADDU_OP  =>  adder_latch_en  <= '1';
                        addn_sub <= '0';
                        outalu_int <= adder_out;
                        carry_int <= carry_out;
	    when SUB_OP   =>  adder_latch_en  <= '1';
                        addn_sub <= '1';
                        outalu_int <= adder_out;
                        overflow_int <= overflow_p4;
                        carry_int <= carry_out;
	    when SUBU_OP   => adder_latch_en  <= '1';
                        addn_sub <= '1';
                        outalu_int <= adder_out;
                        carry_int <= carry_out;
      when AND_OP 	=>  logicals_latch_en  <= '1';
                        logical_sel_s0 <= '0';
                        logical_sel_s1 <= '1';
                        outalu_int <= logical_out;
	    when OR_OP 	=>    logicals_latch_en  <= '1';
                        logical_sel_s0 <= '1';
                        logical_sel_s1 <= '1';
                        outalu_int <= logical_out;
	    when XOR_OP 	=>  logicals_latch_en <= '1';
                        logical_sel_s0 <= '1';
                        logical_sel_s1 <= '0';
                        outalu_int <= logical_out;
	    when SGE_OP 	=>  adder_latch_en  <= '1';
                        addn_sub <= '1';
			                  comp_op <= "001";
                        signed_unsignedn <= '1';
                        outalu_int <= zeros & comparator_out;
      when SGEU_OP 	=>  adder_latch_en  <= '1';
                        addn_sub <= '1';
                  	    comp_op <= "001";
                        signed_unsignedn <= '0';
                        outalu_int <= zeros & comparator_out;
      when SGT_OP 	=>  adder_latch_en  <= '1';
                        addn_sub <= '1';
                        comp_op <= "000";
                        signed_unsignedn <= '1';
                        outalu_int <= zeros & comparator_out;
      when SGTU_OP 	=>  adder_latch_en  <= '1';
                        addn_sub <= '1';
                        comp_op <= "000";
                        signed_unsignedn <= '0';
                        outalu_int <= zeros & comparator_out;
	    when SLE_OP 	=>  adder_latch_en  <= '1';
                        addn_sub <= '1';
			                  comp_op <= "011";
                        signed_unsignedn <= '1';
                        outalu_int <= zeros & comparator_out;
      when SLEU_OP 	=>  adder_latch_en  <= '1';
                        addn_sub <= '1';
                        comp_op <= "011";
                        signed_unsignedn <= '0';
                        outalu_int <= zeros & comparator_out;
      when SLT_OP 	=>  adder_latch_en  <= '1';
                        addn_sub <= '1';
                        comp_op <= "010";
                        signed_unsignedn <= '1';
                        outalu_int <= zeros & comparator_out;
      when SLTU_OP 	=>  adder_latch_en  <= '1';
                        addn_sub <= '1';
                        comp_op <= "010";
                        signed_unsignedn <= '0';
                        outalu_int <= zeros & comparator_out;
      when SNE_OP 	=>  adder_latch_en  <= '1';
                        addn_sub <= '1';
			                  comp_op <= "100";
                        signed_unsignedn <= '0';
                        outalu_int <= zeros & not(comparator_out);
      when SEQ_OP 	=>  adder_latch_en  <= '1';
                        addn_sub <= '1';
                        comp_op <= "100";
                        signed_unsignedn <= '0';
                        outalu_int <= zeros & comparator_out;
      when SLL_OP 	=>  shifter_latch_en  <= '1';
                        arith_logicaln <= '0';
                        right_leftn <= '0';
                        outalu_int <= shifter_out;
      when SRL_OP 	=>  shifter_latch_en  <= '1';
                        arith_logicaln <= '0';
                        right_leftn <= '1';
                        outalu_int <= shifter_out;
      when SRA_OP 	=>  shifter_latch_en <= '1';
                        arith_logicaln <= '1';
                        right_leftn <= '1';
                        outalu_int <= shifter_out;
      when LHI_OP   =>  outalu_int <= imm16_ext;
      when MOV_OP 	=>  outalu_int <= DATA1;
      when I2FP_OP  =>  i2fp_latch_en  <= '1';
                        outalu_int <= i2fp_out;
      when FP2I_OP 	=>  fp2i_latch_en <= '1';
                        outalu_int <= fp2i_out;
                        overflow_int <= fp2i_overflow;
                        invalid_int <= fp2i_invalid;
      when ADDF_OP  =>  fp_add_latch_en  <= '1';
                        addn_sub <= '0';
	    when SUBF_OP  =>  fp_add_latch_en  <= '1';
                        addn_sub <= '1';
      when MULT_OP  =>  mul_latch_en <= '1';
                        mult_int_FPn <= '1';
                        mult_S_Un    <= '1';
      when MULTU_OP =>  mul_latch_en <= '1';
                        mult_int_FPn <= '1';
                        mult_S_Un    <= '0';
      when MULTF_OP =>  mul_latch_en <= '1';
                        mult_int_FPn <= '0';
                        mult_S_Un    <= '0';
    end case;
  end process P_ALU;

END Structural;

configuration CFG_ALU_Structural of ALU is
  for Structural
  end for;
end CFG_ALU_Structural;
