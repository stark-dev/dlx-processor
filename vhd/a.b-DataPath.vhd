library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

ENTITY DataPath IS
  PORT (
    Clk               : IN std_logic;
    Rst               : IN std_logic;

    -- enable signals
    FETCH_EN          : IN std_logic;
    DECODE_EN         : IN std_logic;
    EXECUTION_EN      : IN std_logic;
    E_INT_EN          : IN std_logic;
    E_MUL_EN          : IN std_logic_vector(1 to MULT_PIPE_LENGTH);
    E_ADD_EN          : IN std_logic_vector(1 to FP_ADD_PIPE_LENGTH);
    MEMORY_EN         : IN std_logic;
    WRITEBACK_EN      : IN std_logic;

    -- IR forwarding
    IR_i              : OUT std_logic_vector(Nbit-1 downto 0); -- Input to IR
    IR_d              : OUT std_logic_vector(Nbit-1 downto 0); -- IR output
    IR_e              : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX stage)
    IR_E1_MUL         : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX first stage mult)
    IR_E2_MUL         : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX second stage mult)
    IR_E3_MUL         : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX third stage mult)
    IR_E1_ADD         : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX first stage add)
    IR_E2_ADD         : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX second stage add)
    IR_E3_ADD         : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX third stage add)
    IR_E4_ADD         : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX fourth stage add)
    IR_m              : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (MEM stage)

    IR_CLEAR_D        : IN std_logic;  -- Clear to IR
    IR_CLEAR_E        : IN std_logic;  -- Clear to exec stage
    IR_CLEAR_M        : IN std_logic;  -- Clear to memory stage
    IR_CLEAR_W        : IN std_logic;  -- Clear to writeback stage
    IR_CLEAR_EX_INT   : IN std_logic;  -- Reset to execution IR register
    IR_CLEAR_EX_MUL   : IN std_logic;  -- Reset to first mul execution IR Register
    IR_CLEAR_EX_ADD   : IN std_logic;  -- Reset to first add execution IR Register

    ALU_OUT_SEL       : IN std_logic_vector(1 downto 0); -- It selects the correct execution unit to be connected to memory stage

    -- muxes
    IR_MUX_SEL        : IN std_logic_vector(1 downto 0); --IR Mux input
    SR_MUX_SEL        : IN std_logic;                    --SR Mux selection
    BRANCH_OUT        : OUT std_logic;
    JUMP_MUX_SEL      : IN  std_logic_vector(2 downto 0);

    -- forwarding muxes
    BR_FWD_MUX_SEL    : IN std_logic_vector(1 downto 0); --branch forwarding
    ST_FWD_MUX_SEL    : IN std_logic_vector(2 downto 0); --stall forwarding

    -- control signals

    -- stage 1
    FP_INTn_RD1       : IN std_logic;
    FP_INTn_RD2       : IN std_logic;
    RF_EN             : IN std_logic;
    MUX_IMM_SEL       : IN std_logic;
    -- stage 2
    MUX_A_SEL         : IN std_logic_vector(2 downto 0);
    MUX_B_SEL         : IN std_logic_vector(2 downto 0);
    PUSH_POP_MUX_SEL  : IN std_logic;
    -- stage 3
    LOAD_MUX_SEL      : IN std_logic_vector(2 downto 0);
    WR_MUX_SEL        : IN std_logic_vector(1 downto 0);  --Destination Register mux select
    -- stage 4
    RF_WE             : IN std_logic;
    FP_INTn_WR        : IN std_logic;
    WB_MUX_SEL        : IN std_logic;
    RF_WE_SP          : IN std_logic;

    -- opcodes
    ALU_OPCODE        : IN aluOp;
    BRANCH_OP         : IN branchOp;

    -- RF signals
    RF_WE_SR          : IN std_logic;

    -- ALU overflow/underflow
    ALU_OVF           : OUT std_logic;
    ALU_UFL           : OUT std_logic;
    ALU_INVALID_CONV  : OUT std_logic;
    ALU_CARRY         : OUT std_logic;
    ALU_ZERO          : OUT std_logic;

    -- exception handling
    EPC_EN            : IN  std_logic;    -- exception program counter wr en
    ECP_CODE          : IN exceptionCode; -- exception code to select jump address
    IRQ_CODE          : IN irqCode;       -- irq code to select jump address

    -- control and status registers
    CR_REG_OUT        : OUT std_logic_vector(Nbit-1 downto 0);
    SR_REG_OUT        : OUT std_logic_vector(Nbit-1 downto 0);
    SR_REG_IN         : IN  std_logic_vector(Nbit-1 downto 0);

    --ram signals
    IRAM_in	          : OUT std_logic_vector(Nbit-1 downto 0);
    IRAM_out	        : IN  std_logic_vector(Nbit-1 downto 0);
    DRAM_ADDRESS      : OUT std_logic_vector(Nbit-1 downto 0);
    DRAM_in           : OUT std_logic_vector(Nbit-1 downto 0);
    DRAM_out          : IN  std_logic_vector(Nbit-1 downto 0);

    -- DMA
    CWP               : IN unsigned(up_int_log2(N_windows)-1 downto 0);
    DMA_OUT           : IN std_logic_vector(Nbit-1 downto 0)
    );
END DataPath;



ARCHITECTURE Structural OF DataPath IS

  -----------------------------------------------------------
  -- constants
  -----------------------------------------------------------

  constant value_31       : std_logic_vector(4 downto 0) := std_logic_vector(to_unsigned(31, 5));

  -----------------------------------------------------------
  -- PC signals
  -----------------------------------------------------------

  signal PC_i                  : std_logic_vector(Nbit-1 downto 0);
  signal PC_bus                : std_logic_vector(Nbit-1 downto 0);
  signal NPC                   : std_logic_vector(Nbit-1 downto 0);
  signal NPC_bus               : std_logic_vector(Nbit-1 downto 0);
  signal NPC_bus_del_ex_int    : std_logic_vector(Nbit-1 downto 0);
  signal NPC_bus_del_ex_mul1   : std_logic_vector(Nbit-1 downto 0);
  signal NPC_bus_del_ex_mul2   : std_logic_vector(Nbit-1 downto 0);
  signal NPC_bus_del_ex_mul3   : std_logic_vector(Nbit-1 downto 0);
  signal NPC_bus_del_ex_add1   : std_logic_vector(Nbit-1 downto 0);
  signal NPC_bus_del_ex_add2   : std_logic_vector(Nbit-1 downto 0);
  signal NPC_bus_del_ex_add3   : std_logic_vector(Nbit-1 downto 0);
  signal NPC_bus_del_ex_add4   : std_logic_vector(Nbit-1 downto 0);
  signal NPC_bus_del_ex        : std_logic_vector(Nbit-1 downto 0);
  signal NPC_bus_del_mem       : std_logic_vector(Nbit-1 downto 0);
  signal NPC_bus_del_wb        : std_logic_vector(Nbit-1 downto 0);
  signal EPC_bus               : std_logic_vector(Nbit-1 downto 0);

  -----------------------------------------------------------
  -- IR signals
  -----------------------------------------------------------

  signal IR_BUS         : std_logic_vector(Nbit-1 downto 0);
  signal IR_MUX_out_s   : std_logic_vector(Nbit-1 downto 0);
  signal SR_MUX_out_s   : std_logic_vector(Nbit-1 downto 0);

  signal IR_e_int_s     : std_logic_vector(Nbit-1 downto 0);
  signal IR_e1_mul_s    : std_logic_vector(Nbit-1 downto 0);
  signal IR_e2_mul_s    : std_logic_vector(Nbit-1 downto 0);
  signal IR_e3_mul_s    : std_logic_vector(Nbit-1 downto 0);
  signal IR_e1_add_s    : std_logic_vector(Nbit-1 downto 0);
  signal IR_e2_add_s    : std_logic_vector(Nbit-1 downto 0);
  signal IR_e3_add_s    : std_logic_vector(Nbit-1 downto 0);
  signal IR_e4_add_s    : std_logic_vector(Nbit-1 downto 0);
  signal IR_m_in_s      : std_logic_vector(Nbit-1 downto 0);

  signal IR_m_s         : std_logic_vector(Nbit -1 downto 0);

  signal stage_e_int_en    : std_logic;
  signal stage_e1_mul_en   : std_logic;
  signal stage_e2_mul_en   : std_logic;
  signal stage_e3_mul_en   : std_logic;
  signal stage_e1_add_en   : std_logic;
  signal stage_e2_add_en   : std_logic;
  signal stage_e3_add_en   : std_logic;
  signal stage_e4_add_en   : std_logic;

  -----------------------------------------------------------
  -- Immediate Extension signals
  -----------------------------------------------------------

  signal Imm_ext_16 : std_logic_vector(Nbit-1 downto 0);
  signal Imm_ext_26 : std_logic_vector(Nbit-1 downto 0);
  signal immediate_out : std_logic_vector(Nbit-1 downto 0);

  -----------------------------------------------------------
  -- Branch adder signals
  -----------------------------------------------------------

  signal br_mux_fwd_out : std_logic_vector(Nbit-1 downto 0);

  -----------------------------------------------------------
  -- Branch adder signals
  -----------------------------------------------------------

  signal jump_offset      : std_logic_vector(Nbit-1 downto 0);
  signal branch_adder_out : std_logic_vector(Nbit-1 downto 0);
  signal branch_adder_cout: std_logic;
  signal branch_adder_ov  : std_logic;

  -----------------------------------------------------------
  -- Register File signals
  -----------------------------------------------------------

  signal write_back : std_logic_vector(Nbit-1 downto 0);
  signal RF_out1    : std_logic_vector(Nbit-1 downto 0);
  signal RF_out2    : std_logic_vector(Nbit-1 downto 0);

  -----------------------------------------------------------
  -- Stack Pointer update signals
  -----------------------------------------------------------

  signal updated_SP        : std_logic_vector(Nbit-1 downto 0);
  signal updated_SP_memory : std_logic_vector(Nbit-1 downto 0);
  signal updated_SP_wb     : std_logic_vector(Nbit-1 downto 0);

  -----------------------------------------------------------
  -- RegA and RegB output signals
  -----------------------------------------------------------

  signal RegA_out : std_logic_vector(Nbit-1 downto 0);
  signal RegB_out : std_logic_vector(Nbit-1 downto 0);
  -----------------------------------------------------------
  -- ALU signals
  -----------------------------------------------------------

  signal ALU_in1 : std_logic_vector(Nbit-1 downto 0);
  signal ALU_in2 : std_logic_vector(Nbit-1 downto 0);
  signal ALU_out : std_logic_vector(Nbit-1 downto 0);

  signal ALU_REG_OUT : std_logic_vector(Nbit-1 downto 0);
  signal alu_out_delayed : std_logic_vector(Nbit-1 downto 0);

  -----------------------------------------------------------
  -- Pipeline Register after DRAM signal
  -----------------------------------------------------------

  signal DRAM_REG_out : std_logic_vector(Nbit-1 downto 0);

  -----------------------------------------------------------
  -- Load mux signals
  -----------------------------------------------------------
  signal dram_out_lb  : std_logic_vector(Nbit-1 downto 0);
  signal dram_out_lbu : std_logic_vector(Nbit-1 downto 0);
  signal dram_out_lh  : std_logic_vector(Nbit-1 downto 0);
  signal dram_out_lhu : std_logic_vector(Nbit-1 downto 0);
  signal load_mux_out : std_logic_vector(Nbit-1 downto 0);

  -----------------------------------------------------------
  -- Store mux signals
  -----------------------------------------------------------
  signal st_mux_fwd_out : std_logic_vector(Nbit-1 downto 0);

  -----------------------------------------------------------
  -- WR ADD DELAY REGISTERS
  -----------------------------------------------------------
  signal addr_wr           : std_logic_vector(4 downto 0);
  signal ADD_WR_RF         : std_logic_vector(4 downto 0);

  -----------------------------------------------------------
  -- Exception signals
  -----------------------------------------------------------
  signal ecp_jump_address : std_logic_vector(Nbit-1 downto 0);

  -----------------------------------------------------------
  -- numerical signals
  -----------------------------------------------------------
  signal branch_ret_value : std_logic_vector(Nbit-1 downto 0);

  -----------------------------------------------------------
  -- control and status registers
  -----------------------------------------------------------
  signal cr_reg_out_s     : std_logic_vector(Nbit-1 downto 0);
  signal sr_reg_out_s     : std_logic_vector(Nbit-1 downto 0);

  -----------------------------------------------------------
  -- components
  -----------------------------------------------------------

  component Mux2to1
    generic (N:integer := 16);
    Port (
	   A:	In	std_logic_vector (N-1 downto 0);
       	   B:	In	std_logic_vector (N-1 downto 0);
	   S:	In	std_logic;
	   Y:	Out	std_logic_vector (N-1 downto 0));
  end component;

  component mux3to1 is
  	 generic (N:integer := 16);
      	 Port (
  	   In1:	In	std_logic_vector (N-1 downto 0);
         	   IN2:	In	std_logic_vector (N-1 downto 0);
         	   IN3:	In	std_logic_vector (N-1 downto 0);
  	   S:	In	std_logic_vector(1 downto 0);
  	   Y:	Out	std_logic_vector (N-1 downto 0));
  end component;

  component mux4to1 is
  	 generic (N:integer := 16);
      	 Port (
  	   In1:	In	std_logic_vector (N-1 downto 0);
         	   IN2:	In	std_logic_vector (N-1 downto 0);
         	   IN3:	In	std_logic_vector (N-1 downto 0);
         	   IN4:	In	std_logic_vector (N-1 downto 0);
  	   S:	In	std_logic_vector(1 downto 0);
  	   Y:	Out	std_logic_vector (N-1 downto 0));
  end component;

  component mux5to1 is
  	 generic (N:integer := 16);
      	 Port (
  	   In1:	In	std_logic_vector (N-1 downto 0);
         	   IN2:	In	std_logic_vector (N-1 downto 0);
         	   IN3:	In	std_logic_vector (N-1 downto 0);
         	   IN4:	In	std_logic_vector (N-1 downto 0);
  	   In5:	In	std_logic_vector (N-1 downto 0);
  	   S:	In	std_logic_vector(2 downto 0);
  	   Y:	Out	std_logic_vector (N-1 downto 0));
  end component;

  component mux6to1 is
  	 generic (N:integer := 16);
      	 Port (
  	   In1:	In	std_logic_vector (N-1 downto 0);
         	   IN2:	In	std_logic_vector (N-1 downto 0);
         	   IN3:	In	std_logic_vector (N-1 downto 0);
         	   IN4:	In	std_logic_vector (N-1 downto 0);
  	   In5:	In	std_logic_vector (N-1 downto 0);
         	   IN6:	In	std_logic_vector (N-1 downto 0);
  	   S:	In	std_logic_vector(2 downto 0);
  	   Y:	Out	std_logic_vector (N-1 downto 0));
  end component;

  component mux7to1
    generic (N:integer := 16);
    Port (
  	 In1:	In	std_logic_vector (N-1 downto 0);
     IN2:	In	std_logic_vector (N-1 downto 0);
     IN3:	In	std_logic_vector (N-1 downto 0);
     IN4:	In	std_logic_vector (N-1 downto 0);
  	 In5:	In	std_logic_vector (N-1 downto 0);
     IN6:	In	std_logic_vector (N-1 downto 0);
     IN7:	In	std_logic_vector (N-1 downto 0);
     S:	In	std_logic_vector(2 downto 0);
  	 Y:	Out	std_logic_vector (N-1 downto 0));
  end component;

  component mux8to1
  	 generic (N:integer := 16);
      	 Port (
  	   In1:	In	std_logic_vector (N-1 downto 0);
         	   IN2:	In	std_logic_vector (N-1 downto 0);
         	   IN3:	In	std_logic_vector (N-1 downto 0);
         	   IN4:	In	std_logic_vector (N-1 downto 0);
  	   In5:	In	std_logic_vector (N-1 downto 0);
         	   IN6:	In	std_logic_vector (N-1 downto 0);
         	   IN7:	In	std_logic_vector (N-1 downto 0);
         	   IN8:	In	std_logic_vector (N-1 downto 0);
  	   S:	In	std_logic_vector(2 downto 0);
  	   Y:	Out	std_logic_vector (N-1 downto 0));
  end component;

  component REG
    generic(N : integer := 1;
            RESET_VALUE : integer := 0);
      Port (D:	In	std_logic_vector(N-1 downto 0);
            CK:	In	std_logic;
            RESET:	In	std_logic;
            EN:     in      std_logic;
            Q:	Out	std_logic_vector(N-1 downto 0));
  end component;

  component REG_CLEAR is
    generic(N : integer := 1;
            RESET_VALUE : integer := 0;
            CLEAR_VALUE : integer := 0);
  	Port (	D     :	IN	std_logic_vector(N-1 downto 0);
  		      CK    :	IN	std_logic;
  		      RESET :	IN	std_logic;
  		      CLEAR :	IN	std_logic;
            EN    : IN  std_logic;
  		      Q     :	OUT	std_logic_vector(N-1 downto 0));
  end component;

  component ALU
    generic (N          : integer := 32);
    port(    RST_N               : IN std_logic;
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
  end component;

  component register_file IS
    GENERIC( N_bit : integer := 32;
             N : integer := 8;             -- Number of registers in each IN, OUT and LOCALS
             F : integer := 4;             -- Number of windows
             M : integer := 8);            -- Number of global registers
    PORT (  RESET_N: 	IN std_logic;
      CLK :    IN std_logic;
      ENABLE: 	IN std_logic;
      WR: 		  IN std_logic;
      WR_SP:   IN std_logic;
      WR_SR:   IN std_logic;
      FP_INTn_RD1 :IN std_logic;
      FP_INTn_RD2 :IN std_logic;
      FP_INTn_WR :IN std_logic;
      ADD_WR: 	IN std_logic_vector(up_int_log2(3*N+M)-1 downto 0);
      ADD_RD1: IN std_logic_vector(up_int_log2(3*N+M)-1 downto 0);
      ADD_RD2: IN std_logic_vector(up_int_log2(3*N+M)-1 downto 0);
      DATAIN: 	IN std_logic_vector(N_bit-1 downto 0);
      DATAIN_SP: IN std_logic_vector(N_bit-1 downto 0);
      DATAIN_SR : IN std_logic_vector(N_bit-1 downto 0);

      CWP:     IN unsigned(up_int_log2(F)-1 downto 0);

      OUT1: 		OUT std_logic_vector(N_bit-1 downto 0);
      OUT2: 		OUT std_logic_vector(N_bit-1 downto 0);
      OUT_SR  : OUT std_logic_vector(N_bit-1 downto 0);
      OUT_CR  : OUT std_logic_vector(N_bit-1 downto 0));
  end component;

  component NPC_adder
	generic( N : integer := 32);
	port(    D : IN  std_logic_vector(N-1 downto 0);
		 O : OUT std_logic_vector(N-1 downto 0));
  end component;

  component PUSH_POP_adder
  generic(N : integer := 32);
	port(   D : IN  std_logic_vector(N-1 downto 0);
					S : IN  std_logic; -- 0 -> push, 1 -> pop
		 			O : OUT std_logic_vector(N-1 downto 0));
  END component;

  component p4_adder
    generic( N : integer := 32;
    C_freq : integer :=4);
    port( A, B : in std_logic_vector(N downto 1);
    Cin  : in std_logic;
    S    : out std_logic_vector(N downto 1);
    Cout : out std_logic;
    V    : out std_logic);
  end component;

  component Imm_extension IS
       generic ( N    : integer := 16;
                  M    : integer := 32);
       port (    Din : IN std_logic_vector(N-1 downto 0);
                  Dout : OUT std_logic_vector(M-1 downto 0));
  end component;

  component Branch
    Generic( N : integer :=32);
    Port( A               : IN std_logic_vector(N-1 downto 0);
          BRANCH_OP       : IN branchOp;
          BRANCH_OUT      : OUT std_logic);
  end component;

  component ecp_lut is
  	   port( 	ecp_in          : IN  exceptionCode;
              irq_in					: IN  irqCode;
  		 			 	ecp_addr        : OUT std_logic_vector(Nbit-1 downto 0)
  	       );
  end component;

BEGIN


  ProgramCounter : REG
    generic map(Nbit)
    port map(PC_i, Clk, Rst, FETCH_EN, PC_BUS);

  IR_in_mux : Mux3to1
    generic map(Nbit)
    port map(IRAM_out, DMA_OUT, IR_NOP_VALUE, IR_MUX_SEL, IR_MUX_out_s);

  InstructionRegister: REG_CLEAR
		generic map(Nbit, to_integer(signed(IR_NOP_VALUE)), to_integer(signed(IR_NOP_VALUE)))
		port map(IR_MUX_out_s, Clk, Rst, IR_CLEAR_D, DECODE_EN, IR_BUS);

  -- IR propagation registers

  IR_e_r : REG_CLEAR
    generic map(Nbit, to_integer(signed(IR_NULL_VALUE)), to_integer(signed(IR_NULL_VALUE)))
    port map(IR_BUS, Clk, Rst, IR_CLEAR_EX_INT, stage_e_int_en, IR_e_int_s);

  IR_e_m1_r : REG_CLEAR
    generic map(Nbit, to_integer(signed(IR_NULL_VALUE)), to_integer(signed(IR_NULL_VALUE)))
    port map(IR_BUS, Clk, Rst, IR_CLEAR_EX_MUL, stage_e1_mul_en, IR_e1_mul_s);

  IR_e_m2_r : REG_CLEAR
    generic map(Nbit, to_integer(signed(IR_NULL_VALUE)), to_integer(signed(IR_NULL_VALUE)))
    port map(IR_e1_mul_s, Clk, Rst, IR_CLEAR_E, stage_e2_mul_en, IR_e2_mul_s);

  IR_e_m3_r : REG_CLEAR
    generic map(Nbit, to_integer(signed(IR_NULL_VALUE)), to_integer(signed(IR_NULL_VALUE)))
    port map(IR_e2_mul_s, Clk, Rst, IR_CLEAR_E, stage_e3_mul_en, IR_e3_mul_s);

  IR_e_a1_r : REG_CLEAR
    generic map(Nbit, to_integer(signed(IR_NULL_VALUE)), to_integer(signed(IR_NULL_VALUE)))
    port map(IR_BUS, Clk, Rst, IR_CLEAR_EX_ADD, stage_e1_add_en, IR_e1_add_s);

  IR_e_a2_r : REG_CLEAR
    generic map(Nbit, to_integer(signed(IR_NULL_VALUE)), to_integer(signed(IR_NULL_VALUE)))
    port map(IR_e1_add_s, Clk, Rst, IR_CLEAR_E, stage_e2_add_en, IR_e2_add_s);

  IR_e_a3_r : REG_CLEAR
    generic map(Nbit, to_integer(signed(IR_NULL_VALUE)), to_integer(signed(IR_NULL_VALUE)))
    port map(IR_e2_add_s, Clk, Rst, IR_CLEAR_E, stage_e3_add_en, IR_e3_add_s);

  IR_e_a4_r : REG_CLEAR
    generic map(Nbit, to_integer(signed(IR_NULL_VALUE)), to_integer(signed(IR_NULL_VALUE)))
    port map(IR_e3_add_s, Clk, Rst, IR_CLEAR_E, stage_e4_add_en, IR_e4_add_s);

  IR_m_in_mux : mux3to1
    generic map(Nbit)
    port map(IR_e_int_s, IR_e3_mul_s, IR_e4_add_s, ALU_OUT_SEL, IR_m_in_s);

  IR_m_r : REG_CLEAR
    generic map(Nbit, to_integer(signed(IR_NULL_VALUE)), to_integer(signed(IR_NULL_VALUE)))
    port map(IR_m_in_s, Clk, Rst, IR_CLEAR_M, MEMORY_EN, IR_m_s);

  NPC_eval: NPC_adder
    generic map(Nbit)
    port map(PC_BUS, NPC);

  MUX_PC : Mux6to1
    generic map(Nbit)
    port map(NPC, branch_adder_out, br_mux_fwd_out, ecp_jump_address, EPC_bus, START_CODE_POINTER, JUMP_MUX_SEL, PC_i);

  NextProgramCounter: REG
    generic map(Nbit)
    port map(PC_i, Clk, Rst, DECODE_EN, NPC_bus);

  Extension_imm_16: Imm_extension
    generic map(Nbit/2,Nbit)
    port map(IR_BUS(Nbit/2 -1 downto 0), Imm_ext_16);

  Extension_imm_26: Imm_extension
    generic map(26,Nbit)
    port map(IR_BUS(25 downto 0), Imm_ext_26);

  SR_MUX_IN : mux2to1
    generic map(Nbit)
    port map(IR_BUS, SR_REG_IN, SR_MUX_SEL, SR_MUX_out_s);

  WRF: register_File
    generic map(Nbit, in_local_out_width, N_windows, N_globals)
    port map(
      RESET_N     => Rst,
      CLK         => Clk,
	    ENABLE      => RF_EN,
  	  WR          => RF_WE,
      WR_SP       => RF_WE_SP,
      WR_SR       => RF_WE_SR,
      FP_INTn_RD1 => FP_INTn_RD1,
      FP_INTn_RD2 => FP_INTn_RD2,
      FP_INTn_WR  => FP_INTn_WR,
      ADD_WR      => ADD_WR_RF,
	    ADD_RD1     => IR_BUS(Nbit-1-OPCODE_SIZE downto Nbit-1-OPCODE_SIZE-4),
	    ADD_RD2     => IR_BUS(Nbit-1-OPCODE_SIZE-5 downto Nbit-1-OPCODE_SIZE-9),
	    DATAIN      => write_back,
      DATAIN_SP   => updated_SP_wb,
      DATAIN_SR   => SR_MUX_out_s,
      CWP         => CWP,
      OUT1        => RF_out1,
	    OUT2        => RF_out2,
      OUT_SR      => sr_reg_out_s,
      OUT_CR      => cr_reg_out_s);

  Mux_jump : Mux2to1
    generic map(Nbit)
    port map(Imm_ext_26, Imm_ext_16, MUX_IMM_SEL, jump_offset);

  Branch_Adder : p4_adder
    generic map(Nbit)
    port map(NPC_bus, jump_offset, '0', branch_adder_out, branch_adder_cout, branch_adder_ov);

  Branch_fwd_mux : Mux3to1
    generic map(Nbit)
    port map(RF_out1, ALU_REG_OUT, updated_SP_memory, BR_FWD_MUX_SEL, br_mux_fwd_out);

  Branch_Block: Branch
    generic map(Nbit)
    port map(br_mux_fwd_out, BRANCH_OP, BRANCH_OUT);

  DestinationRegisterMux: Mux3to1
    generic map(5)
    port map(IR_m_s(Nbit-1-OPCODE_SIZE-5 downto Nbit-1-OPCODE_SIZE-9), IR_m_s(Nbit-1-OPCODE_SIZE-10 downto Nbit-1-OPCODE_SIZE-14), value_31, WR_MUX_SEL, addr_wr);

  addr_wr_w_r : REG_CLEAR
    generic map (5, -8, -8) -- Reset to R24 (-8 signed on 5 bits)
    port map(addr_wr, Clk, Rst, IR_CLEAR_W, WRITEBACK_EN, ADD_WR_RF);

  RegA: REG_CLEAR
    generic map(Nbit)
    port map(RF_out1, Clk, Rst, IR_CLEAR_E, EXECUTION_EN, RegA_out);

  RegB: REG_CLEAR
    generic map(Nbit)
    port map(RF_out2, Clk, Rst, IR_CLEAR_E, EXECUTION_EN, RegB_out);

  RegImm : REG_CLEAR
    generic map(Nbit)
    port map(Imm_ext_16, Clk, Rst, IR_CLEAR_E, EXECUTION_EN, immediate_out);

  Store_fwd_mux : Mux6to1
    generic map(Nbit)
    port map(RegB_out, ALU_REG_OUT, alu_out_delayed, updated_SP_memory, updated_SP_wb, DRAM_REG_out, ST_FWD_MUX_SEL, st_mux_fwd_out);

  RegB_DRAM: REG_CLEAR
    generic map (Nbit)
    port map (st_mux_fwd_out, Clk, Rst, IR_CLEAR_M, MEMORY_EN, DRAM_in);

   MUXA: mux7to1
     generic map(Nbit)
     port map(ALU_REG_OUT, alu_out_delayed, DRAM_REG_out, NPC_bus_del_ex, RegA_out, updated_SP_memory, updated_SP_wb, MUX_A_SEL, ALU_in1);

   MUXB: mux8to1
     generic map(Nbit)
     port map(RegB_out, immediate_out, DRAM_REG_out, alu_out_delayed, ALU_REG_OUT, branch_ret_value, updated_SP_memory, updated_SP_wb, MUX_B_SEL, ALU_in2);

  ALU_DLX: ALU
    generic map(Nbit)
    port map(
      RST_N         => Rst,
      Clk           => Clk,
      E2_MUL_EN     => stage_e2_mul_en,
      E3_MUL_EN     => stage_e3_mul_en,
      E2_ADD_EN     => stage_e2_add_en,
      E3_ADD_EN     => stage_e3_add_en,
      E4_ADD_EN     => stage_e4_add_en,
      FUNC          => ALU_OPCODE,
      ALU_OUT_SEL   => ALU_OUT_SEL,
      ROUNDING_MODE => cr_reg_out_s(ROUND_MODE),
      DATA1         => ALU_in1,
      DATA2         => ALU_in2,
      OUTALU        => ALU_out,
      OVERFLOW      => ALU_OVF,
      UNDERFLOW     => ALU_UFL,
      INVALID       => ALU_INVALID_CONV,
      CARRY         => ALU_CARRY,
      ZERO          => ALU_ZERO
    );

  ALU_OUT_R: REG_CLEAR
    generic map(Nbit)
    port map(ALU_out, Clk, Rst, IR_CLEAR_E, MEMORY_EN, ALU_REG_OUT);

  adder_push : PUSH_POP_adder
    generic map(Nbit)
    port map(ALU_in1, PUSH_POP_MUX_SEL, updated_SP); --SP goes into RegA to be sent as address to DRAM

  sp_delay_reg_1 : REG_CLEAR
    generic map(Nbit)
    port map(updated_SP, Clk, Rst, IR_CLEAR_M, MEMORY_EN, updated_SP_memory);

  sp_delay_reg_2 : REG_CLEAR
    generic map(Nbit)
    port map(updated_SP_memory, Clk, Rst, IR_CLEAR_W, WRITEBACK_EN, updated_SP_wb);

  LOAD_MUX : mux5to1
    generic map(Nbit)
    port map(DRAM_out, dram_out_lb, dram_out_lbu, dram_out_lh, dram_out_lhu, LOAD_MUX_SEL, load_mux_out);

  MEM_REG: REG_CLEAR
    generic map(Nbit)
    port map(load_mux_out, Clk, Rst, IR_CLEAR_W, WRITEBACK_EN, DRAM_REG_out);

  Alu_out_delay_reg : REG_CLEAR
    generic map(Nbit)
    port map(ALU_REG_OUT, Clk, Rst, IR_CLEAR_M, WRITEBACK_EN, alu_out_delayed);

  WB_MUX: Mux2to1
    generic map(Nbit)
    port map(DRAM_REG_out, alu_out_delayed, WB_MUX_SEL, write_back);

  NPC_del_reg_d_e_int: REG_CLEAR
    generic map(Nbit)
    port map(NPC_bus, Clk, Rst, IR_CLEAR_EX_INT, stage_e_int_en, NPC_bus_del_ex_int);

  NPC_del_reg_d_e_mul1: REG_CLEAR
    generic map(Nbit)
    port map(NPC_bus, Clk, Rst, IR_CLEAR_EX_MUL, stage_e1_mul_en, NPC_bus_del_ex_mul1);

  NPC_del_reg_d_e_mul2: REG
    generic map(Nbit)
    port map(NPC_bus_del_ex_mul1, Clk, Rst, stage_e2_mul_en, NPC_bus_del_ex_mul2);

  NPC_del_reg_d_e_mul3: REG
    generic map(Nbit)
    port map(NPC_bus_del_ex_mul2, Clk, Rst, stage_e3_mul_en, NPC_bus_del_ex_mul3);

  NPC_del_reg_d_e_add1: REG_CLEAR
    generic map(Nbit)
    port map(NPC_bus, Clk, Rst, IR_CLEAR_EX_ADD, stage_e1_add_en, NPC_bus_del_ex_add1);

  NPC_del_reg_d_e_add2: REG
    generic map(Nbit)
    port map(NPC_bus_del_ex_add1, Clk, Rst, stage_e2_add_en, NPC_bus_del_ex_add2);

  NPC_del_reg_d_e_add3: REG
    generic map(Nbit)
    port map(NPC_bus_del_ex_add2, Clk, Rst, stage_e3_add_en, NPC_bus_del_ex_add3);

  NPC_del_reg_d_e_add4: REG
    generic map(Nbit)
    port map(NPC_bus_del_ex_add3, Clk, Rst, stage_e4_add_en, NPC_bus_del_ex_add4);

  NPC_del_e_mux :mux3to1
    generic map(Nbit)
    port map(NPC_bus_del_ex_int, NPC_bus_del_ex_mul3, NPC_bus_del_ex_add4, ALU_OUT_SEL, NPC_bus_del_ex);

  NPC_del_reg_e_m: REG
    generic map(Nbit)
    port map(NPC_bus_del_ex, Clk, Rst, MEMORY_EN, NPC_bus_del_mem);

  NPC_del_reg_m_w: REG
    generic map(Nbit)
    port map(NPC_bus_del_mem, Clk, Rst, MEMORY_EN, NPC_bus_del_wb);

--exception handling

  EPC: REG
    generic map(Nbit)
    port map(NPC_bus_del_wb, Clk, Rst, EPC_EN, EPC_bus);

  ecp_addr_lut : ecp_lut
    port map (ECP_CODE, IRQ_CODE, ecp_jump_address);

  -----------------------------------------------------------
  -- implicit assignments
  -----------------------------------------------------------

  IRAM_in <= PC_BUS;

  IR_i <= IR_MUX_out_s;
  IR_d <= IR_BUS;
  IR_e <= IR_e_int_s;
  IR_E1_MUL <= IR_e1_mul_s;
  IR_E2_MUL <= IR_e2_mul_s;
  IR_E3_MUL <= IR_e3_mul_s;
  IR_E1_ADD <= IR_e1_add_s;
  IR_E2_ADD <= IR_e2_add_s;
  IR_E3_ADD <= IR_e3_add_s;
  IR_E4_ADD <= IR_e4_add_s;
  IR_m <= IR_m_s;

  DRAM_ADDRESS <= ALU_REG_OUT;

  SR_REG_OUT <= sr_reg_out_s;
  CR_REG_OUT <= cr_reg_out_s;

  -----------------------------------------------------------
  -- IR pipe enable
  -----------------------------------------------------------

  stage_e_int_en   <= EXECUTION_EN and E_INT_EN;
  stage_e1_mul_en  <= EXECUTION_EN and E_MUL_EN(1);
  stage_e2_mul_en  <= EXECUTION_EN and E_MUL_EN(2);
  stage_e3_mul_en  <= EXECUTION_EN and E_MUL_EN(3);
  stage_e1_add_en  <= EXECUTION_EN and E_ADD_EN(1);
  stage_e2_add_en  <= EXECUTION_EN and E_ADD_EN(2);
  stage_e3_add_en  <= EXECUTION_EN and E_ADD_EN(3);
  stage_e4_add_en  <= EXECUTION_EN and E_ADD_EN(4);

  -----------------------------------------------------------
  -- DRAM out value
  -----------------------------------------------------------

  dram_out_lb(7 downto 0)         <= dram_out(Nbit-1 downto 24);
  dram_out_lb(Nbit-1 downto 8)    <= (others => dram_out(Nbit-1));
  dram_out_lbu(7 downto 0)        <= dram_out(Nbit-1 downto 24);
  dram_out_lbu(Nbit-1 downto 8)   <= (others => '0');
  dram_out_lh(15 downto 0)        <= dram_out(Nbit-1 downto 16);
  dram_out_lh(Nbit-1 downto 16)   <= (others => dram_out(Nbit-1));
  dram_out_lhu(15 downto 0)       <= dram_out(Nbit-1 downto 16);
  dram_out_lhu(Nbit-1 downto 16)  <= (others => '0');

  branch_ret_value <= std_logic_vector(to_unsigned(4, Nbit)) when sr_reg_out_s(BRANCH_DELAY_SLOT)= '1' else
                      (others => '0');

END ARCHITECTURE;



configuration CFG_DP_Structural of DataPath is
  for Structural
    for all : REG
      use configuration WORK.CFG_REG_ASYNC;
    end for;
  end for;

end CFG_DP_Structural;
