library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;


ENTITY FP_adder IS
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
END ENTITY;

ARCHITECTURE Structural OF FP_adder IS

  component reg
    generic(N : integer := 1;
            RESET_VALUE : integer := 0);
      Port (D:	In	std_logic_vector(N-1 downto 0);
            CK:	In	std_logic;
            RESET:	In	std_logic;
            EN:     in      std_logic;
            Q:	Out	std_logic_vector(N-1 downto 0));
  end component ;

  component flip_flop
  	Port (	D:	In	std_logic;
  		      CK:	In	std_logic;
  		      RESET:	In	std_logic;
            EN:     in      std_logic;
  		      Q:	Out	std_logic);
  end component;

  component RCA
    generic(N       :       integer := 8);
    Port (	A:	In	std_logic_vector(N-1 downto 0);
          B:	In	std_logic_vector(N-1 downto 0);
          Ci:	In	std_logic;
          S:	Out	std_logic_vector(N-1 downto 0);
          Co:	Out	std_logic);
  end component;

  component mux2to1
    generic (N:integer := 16);
    Port (
      A:	In	std_logic_vector (N-1 downto 0);
      B:	In	std_logic_vector (N-1 downto 0);
      S:	In	std_logic;
      Y:	Out	std_logic_vector (N-1 downto 0));
  end component;


  component sign_eval
    PORT( SIGN1 : IN std_logic;
          SIGN2 : IN std_logic;
          SwAP  : IN std_logic;
          COMPL : IN std_logic;
          SIGN_RES : OUT std_logic);
  end component;

  component shift_right
    PORT( SIGNIFICAND : IN std_logic_vector(23 downto 0);
          D      : IN std_logic_vector(7 downto 0);
          SIG_OUT  : OUT std_logic_vector(23 downto 0);
          G     : OUT std_logic;
          R     : OUT std_logic;
          S      : OUT std_logic);
  end component;

  component CLA
    GENERIC(N : integer := 32);
      PORT
          (A   :  IN   std_logic_vector(N-1 downto 0);
           B   :  IN   std_logic_vector(N-1 downto 0);
           Cin :  IN   std_logic;
           S   :  OUT  std_logic_vector(N-1 downto 0);
           Cout :  OUT  STD_LOGIC);
  end component;

  component Normalization
    PORT(
          SIGNIFICAND : IN std_logic_vector(23 downto 0);
          GUARD       : IN std_logic;
          ROUND_BIT   : IN std_logic;
          STICKY      : IN std_logic;
          CARRY       : IN std_logic;
          EXPONENT    : IN std_logic_vector(7 downto 0);
          RESULT      : OUT std_logic_vector(23 downto 0);
          EXP_CHANGE  : OUT std_logic_vector(7 downto 0);
          NEW_ROUND   : OUT std_logic;
          NEW_STICKY  : OUT std_logic);
  end component;

  component adder_rounding
    PORT( result : IN std_logic_vector(23 downto 0);
          rounding_mode : IN std_logic_vector(1 downto 0);
          result_sign : IN std_logic;
          round_bit  : IN std_logic;
          sticky_bit : IN std_logic;
          rounded_result : OUT std_logic_vector(23 downto 0);
          exp_incr : OUT std_logic);
  end component;

  signal a1_delayed1, a1_delayed2, a1_delayed3 : std_logic_vector(31 downto 0);
  signal a2_delayed1, a2_delayed2, a2_delayed3 : std_logic_vector(31 downto 0);
  signal rounding_mode_delayed1, rounding_mode_delayed2, rounding_mode_delayed3 : std_logic_vector(1 downto 0);
  signal sign1, sign2, sign_res : std_logic;
  signal sign1_delayed1, sign1_delayed2 : std_logic;
  signal sign2_delayed1, sign2_delayed2: std_logic;
  signal sign_res_delayed : std_logic;
  signal unpack1, unpack2 : std_logic;
  signal swap : std_logic;
  signal swap_delayed1, swap_delayed2 : std_logic;
  signal e1, e2, exp1, exp2, exp2_neg, diff, exp_change, exp_res, final_exp : std_logic_vector(7 downto 0);
  signal e1_delayed1, e1_delayed2, e1_delayed3 : std_logic_vector(7 downto 0);
  signal e2_delayed1, e2_delayed2, e2_delayed3 : std_logic_vector(7 downto 0);
  signal exp1_delayed1, exp1_delayed2, exp1_delayed3 : std_logic_vector(7 downto 0);
  signal exp_change_delayed : std_logic_vector(7 downto 0);
  signal s1, s2, significand1, significand2, shifted_significand2, ca2_significand2 : std_logic_vector(23 downto 0);
  signal significand1_delayed, shifted_significand2_delayed : std_logic_vector(23 downto 0);
  signal small_Cout, big_Cout, exp_Cout : std_logic;
  signal guard_bit, round_bit, sticky_bit, new_round, new_sticky : std_logic;
  signal guard_bit_delayed1, guard_bit_delayed2 : std_logic;
  signal round_bit_delayed1, round_bit_delayed2 : std_logic;
  signal sticky_bit_delayed1, sticky_bit_delayed2 : std_logic;
  signal new_round_delayed, new_sticky_delayed : std_logic;
  signal subtraction : std_logic;
  signal subtraction_extended : std_logic_vector(23 downto 0);
  signal partial_result, partial_result2, ca2_partial_result, norm_result, rounded_result : std_logic_vector(23 downto 0);
  signal partial_result_delayed : std_logic_vector(23 downto 0);
  signal norm_result_delayed : std_logic_vector(23 downto 0);
  signal final_result : std_logic_vector(22 downto 0);
  signal complement : std_logic;
  signal complement_delayed : std_logic;
  signal shift_right_needed : std_logic;
  signal shift_right_needed_delayed1, shift_right_needed_delayed2 : std_logic;
  signal exp_incr : std_logic;
  signal valid, finite : std_logic;
BEGIN

  sign1 <= A1(31);
  sign2 <= A2(31) xor ADDn_SUB;

  a1_del_1 : reg
    generic map(32)
    port map(A1, CLK, RST_N, STAGE2_EN, a1_delayed1);

  a1_del_2 : reg
    generic map(32)
    port map(a1_delayed1, CLK, RST_N, STAGE3_EN, a1_delayed2);

  a1_del_3 : reg
    generic map(32)
    port map(a1_delayed2, CLK, RST_N, STAGE4_EN, a1_delayed3);

  a2_del_1 : reg
    generic map(32)
    port map(a2, CLK, RST_N, STAGE2_EN, a2_delayed1);

  a2_del_2 : reg
    generic map(32)
    port map(a2_delayed1, CLK, RST_N, STAGE3_EN, a2_delayed2);

  a2_del_3 : reg
    generic map(32)
    port map(a2_delayed2, CLK, RST_N, STAGE4_EN, a2_delayed3);

  sign_del_1 : flip_flop
    port map(sign1, CLK, RST_N, STAGE2_EN, sign1_delayed1);

  sign_del_2 : flip_flop
    port map(sign1_delayed1, CLK, RST_N, STAGE3_EN, sign1_delayed2);

  sign_del_3 : flip_flop
    port map(sign2, CLK, RST_N, STAGE2_EN, sign2_delayed1);

  sign_del_4 : flip_flop
    port map(sign2_delayed1, CLK, RST_N, STAGE3_EN, sign2_delayed2);

  swap_del_1 : flip_flop
    port map(swap, CLK, RST_N, STAGE2_EN, swap_delayed1);

  swap_del_2 : flip_flop
    port map(swap_delayed1, CLK, RST_N, STAGE3_EN, swap_delayed2);

  significand1_del : reg
    generic map(24)
    port map(significand1, CLK, RST_N, STAGE2_EN, significand1_delayed);

  shifted_significand2_del : reg
    generic map(24)
    port map(shifted_significand2, CLK, RST_N, STAGE2_EN, shifted_significand2_delayed);

  exp_del_1 : reg
    generic map(8)
    port map(exp1, CLK, RST_N, STAGE2_EN, exp1_delayed1);

  exp_del_2 : reg
    generic map(8)
    port map(exp1_delayed1, CLK, RST_N, STAGE3_EN, exp1_delayed2);

  exp_del_3 : reg
    generic map(8)
    port map(exp1_delayed2, CLK, RST_N, STAGE4_EN, exp1_delayed3);

  e1_del_1 : reg
    generic map(8)
    port map(e1, CLK, RST_N, STAGE2_EN, e1_delayed1);

  e1_del_2 : reg
    generic map(8)
    port map(e1_delayed1, CLK, RST_N, STAGE3_EN, e1_delayed2);

  e1_del_3 : reg
    generic map(8)
    port map(e1_delayed2, CLK, RST_N, STAGE4_EN, e1_delayed3);

  e2_del_1 : reg
    generic map(8)
    port map(e2, CLK, RST_N, STAGE2_EN, e2_delayed1);

  e2_del_2 : reg
    generic map(8)
    port map(e2_delayed1, CLK, RST_N, STAGE3_EN, e2_delayed2);

  e2_del_3 : reg
    generic map(8)
    port map(e2_delayed2, CLK, RST_N, STAGE4_EN, e2_delayed3);

  partial_result_del : reg
    generic map(24)
    port map(partial_result, CLK, RST_N, STAGE3_EN, partial_result_delayed);

  complement_del : flip_flop
    port map(complement, CLK, RST_N, STAGE3_EN, complement_delayed);

  guard_bit_del_1 : flip_flop
    port map(guard_bit, CLK, RST_N, STAGE2_EN, guard_bit_delayed1);

  guard_bit_del_2 : flip_flop
    port map(guard_bit_delayed1, CLK, RST_N, STAGE3_EN, guard_bit_delayed2);

  round_bit_del_1 : flip_flop
    port map(round_bit, CLK, RST_N, STAGE2_EN, round_bit_delayed1);

  round_bit_del_2 : flip_flop
    port map(round_bit_delayed1, CLK, RST_N, STAGE3_EN, round_bit_delayed2);

  sticky_bit_del_1 : flip_flop
    port map(sticky_bit, CLK, RST_N, STAGE2_EN, sticky_bit_delayed1);

  sticky_bit_del_2 : flip_flop
    port map(sticky_bit_delayed1, CLK, RST_N, STAGE3_EN, sticky_bit_delayed2);

  shift_right_needed_del_1 : flip_flop
    port map(shift_right_needed, CLK, RST_N, STAGE3_EN, shift_right_needed_delayed1);

  shift_right_needed_del_2 : flip_flop
    port map(shift_right_needed_delayed1, CLK, RST_N, STAGE4_EN, shift_right_needed_delayed2);

  norm_result_del : reg
    generic map(24)
    port map(norm_result, CLK, RST_N, STAGE4_EN, norm_result_delayed);

  rounding_mode_del_1 : reg
    generic map(2)
    port map(ROUNDING_MODE, CLK, RST_N, STAGE2_EN, rounding_mode_delayed1);

  rounding_mode_del_2 : reg
    generic map(2)
    port map(rounding_mode_delayed1, CLK, RST_N, STAGE3_EN, rounding_mode_delayed2);

  rounding_mode_del_3 : reg
    generic map(2)
    port map(rounding_mode_delayed2, CLK, RST_N, STAGE4_EN, rounding_mode_delayed3);

  sign_res_del_1 : flip_flop
    port map(sign_res, CLK, RST_N, STAGE4_EN, sign_res_delayed);

  new_round_del : flip_flop
    port map(new_round, CLK, RST_N, STAGE4_EN, new_round_delayed);

  new_sticky_del: flip_flop
    port map(new_sticky, CLK, RST_N, STAGE4_EN, new_sticky_delayed);

  exp_change_del : reg
    generic map(8)
    port map(exp_change, CLK, RST_N, STAGE4_EN, exp_change_delayed);


  subtraction <= sign1_delayed1 xor sign2_delayed1;
  subtraction_extended <= (others => subtraction);

  e1 <= A1(30 downto 23) when (or_reduce(A1(30 downto 23)) ='1' or or_reduce(A1(22 downto 0))='0') else
        "00000001";
  e2 <= A2(30 downto 23) when (or_reduce(A2(30 downto 23)) ='1' or or_reduce(A2(22 downto 0))='0') else
        "00000001";

  exp2_neg <= not(exp2);

  unpack1 <= '1' when or_reduce(A1(30 downto 23)) ='1' else
             '0';
  unpack2 <= '1' when or_reduce(A2(30 downto 23)) ='1' else
             '0';

  s1 <= unpack1 & A1(22 downto 0);
  s2 <= unpack2 & A2(22 downto 0);

  ca2_significand2 <= shifted_significand2_delayed xor subtraction_extended;
  complement <= subtraction and not(big_Cout);
  shift_right_needed <= not(subtraction) and big_Cout;

  swap_proc : process (e1, e2)
  begin
    swap <= '0';
    if unsigned(e1) < unsigned(e2) then
      swap <= '1';
    end if;
  end process;


  muxA : mux2to1
    generic map(8)
    port map(e1, e2, swap, exp1);


  muxB : mux2to1
    generic map(8)
    port map(e2, e1, swap, exp2);

  small_alu : RCA
    generic map(8)
    port map(exp1, exp2_neg, '1', diff, small_Cout);

  muxC : mux2to1
    generic map(24)
    port map(s1, s2, swap, significand1);

  muxD : mux2to1
    generic map(24)
    port map(s2, s1, swap, significand2);

  right_shift : shift_right
    port map(significand2, diff, shifted_significand2, guard_bit, round_bit, sticky_bit);

  big_alu : CLA
    generic map(24)
    port map(significand1_delayed, ca2_significand2, subtraction, partial_result, big_Cout);

  ca2_partial_result <= std_logic_vector(unsigned(not(partial_result_delayed)) + 1);

  muxE : mux2to1
    generic map(24)
    port map(partial_result_delayed, ca2_partial_result, complement_delayed, partial_result2);

  Norm : Normalization
    port map(partial_result2, guard_bit_delayed2, round_bit_delayed2, sticky_bit_delayed2,
             shift_right_needed_delayed1, exp1_delayed2, norm_result, exp_change, new_round, new_sticky);

  sign_calc : sign_eval
    port map(sign1_delayed2, sign2_delayed2, swap_delayed2, complement_delayed, sign_res);

  rounding : adder_rounding
    port map(norm_result_delayed, rounding_mode_delayed3, sign_res_delayed, new_round_delayed,
    new_sticky_delayed, rounded_result, exp_incr);

  exp_eval : RCA
    generic map(8)
    port map(exp1_delayed3, exp_change_delayed, exp_incr, exp_res, exp_Cout);

  final_exp <= "11111111" when and_reduce(e1_delayed3) = '1' or and_reduce(e2_delayed3) = '1' else
               exp_res when (rounded_result(23) = '1' or or_reduce(rounded_result(22 downto 0))='0') else
               "00000000";

  fin_res : process(a1_delayed3, a2_delayed3, rounded_result)
  begin
    valid <= '0';
    finite <= '0';
    if and_reduce(a1_delayed3(30 downto 23)) = '1' and or_reduce(a1_delayed3(22 downto 0)) = '1' then
       final_result <= a1_delayed3(22 downto 0);
     elsif and_reduce(a2_delayed3(30 downto 23)) = '1' and or_reduce(a2_delayed3(22 downto 0)) = '1'  then
       final_result <= a2_delayed3(22 downto 0);
     elsif and_reduce(a1_delayed3(30 downto 23)) = '1' and or_reduce(a1_delayed3(22 downto 0)) = '0' and and_reduce(a2_delayed3(30 downto 23)) = '1' and or_reduce(a2_delayed3(22 downto 0)) = '0' then
       if (a1_delayed3(31) xor a2_delayed3(31)) = '0' then
         final_result <= a1_delayed3(22 downto 0);
         valid <= '1';
       else
         final_result <= (others => '1');
       end if;
     elsif and_reduce(a1_delayed3(30 downto 23)) = '1' and or_reduce(a1_delayed3(22 downto 0)) = '0' then
       final_result <= a1_delayed3(22 downto 0);
       valid <= '1';
     elsif and_reduce(a2_delayed3(30 downto 23)) = '1' and or_reduce(a2_delayed3(22 downto 0)) = '0' then
       final_result <= a2_delayed3(22 downto 0);
       valid <= '1';
     else
       final_result <= rounded_result(22 downto 0);
       valid <= '1';
       finite <= '1';
     end if;
  end process;

  SUM <= sign_res_delayed & final_exp & final_result;

  OVERFLOW <= '1' when ((shift_right_needed_delayed2 or exp_incr) and and_reduce(exp_res) and finite) = '1' else
              '0';

  UNDERFLOW <= '1' when or_reduce(final_exp) = '0' and or_reduce(final_result) = '1' else
               '0';

  INVALID <= '1' when valid = '0' else
             '0';


END ARCHITECTURE;

configuration CFG_FP_ADD_Structural of FP_adder is
  for Structural
    for all : REG
      use configuration WORK.CFG_REG_ASYNC;
    end for;
  end for;

end CFG_FP_ADD_Structural;
