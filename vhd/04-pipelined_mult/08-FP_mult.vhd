library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

ENTITY FP_mult IS
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

END ENTITY;

ARCHITECTURE Behavioral OF FP_mult IS

  component reg
    generic(N : integer := 1;
            RESET_VALUE : integer := 0);
    Port (	D:	In	std_logic_vector(N-1 downto 0);
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

  component multiplier
    generic ( N :         integer := 24);
        port( CLK : IN std_logic;
              RST_N : IN std_logic;
              PIPELINE_EN : IN std_logic;
              A :     in  std_logic_vector(N-1 downto 0);
              B :     in  std_logic_vector(N-1 downto 0);
              S_Un :  in  std_logic;    -- 0 -> unsigned; 1 -> signed
              Z :     out std_logic_vector(2*N-1 downto 0)
              );
  end component;

  component Exponent_eval
    PORT( CLK : IN std_logic;
          RST_N : IN std_logic;
          FIRST_STAGE_EN : IN std_logic;
          SECOND_STAGE_EN : IN std_logic;
          exp1 : IN std_logic_vector(7 downto 0);
          exp2 : IN std_logic_vector(7 downto 0);
          incr : IN std_logic;
          exp_res : OUT std_logic_vector(9 downto 0));
  end component;

  component rounding
    port( result : IN std_logic_vector(47 downto 0);
          rounding_mode : IN std_logic_vector(1 downto 0);
          result_sign : IN std_logic;
          rounded_result : OUT std_logic_vector(23 downto 0);
          exp_incr : OUT std_logic);
  end component;

  component mux2to1
    generic (N:integer := 16);
     Port (
      A:	In	std_logic_vector (N-1 downto 0);
      B:	In	std_logic_vector (N-1 downto 0);
      S:	In	std_logic;
      Y:	Out	std_logic_vector (N-1 downto 0));
  end component;

  signal a_delayed_1 : std_logic_vector(31 downto 0);
  signal a_delayed_2 : std_logic_vector(31 downto 0);
  signal b_delayed_1 : std_logic_vector(31 downto 0);
  signal b_delayed_2 : std_logic_vector(31 downto 0);

  signal rounding_mode_delayed_1 : std_logic_vector(1 downto 0);
  signal rounding_mode_delayed_2 : std_logic_vector(1 downto 0);

  signal int_FPn_delayed_1 : std_logic;
  signal int_FPn_delayed_2 : std_logic;
  signal S_Un_delayed_1: std_logic;
  signal S_Un_delayed_2: std_logic;

  signal A_int : std_logic_vector(23 downto 0);
  signal B_int : std_logic_vector(23 downto 0);
  signal A_FP : std_logic_vector(23 downto 0);
  signal B_FP : std_logic_vector(23 downto 0);
  signal In1 : std_logic_vector(23 downto 0);
  signal In2 : std_logic_vector(23 downto 0);

  signal mult_out : std_logic_vector(47 downto 0);
  signal mult_out_delayed : std_logic_vector(47 downto 0);

  signal sign_out : std_logic;
  signal sign_out_delayed_1 : std_logic;
  signal sign_out_delayed_2 : std_logic;

  signal mantissa : std_logic_vector(23 downto 0);
  signal mantissa_after_control : std_logic_vector(22 downto 0);
  signal incr : std_logic;
  signal exp_result : std_logic_vector(9 downto 0);
  signal exp_after_control : std_logic_vector(7 downto 0);

BEGIN

  Signed_Unsigned_proc : process(A, B, S_Un)
  begin
    if S_Un = '0' then
      A_int(23 downto 16) <= (others => '0');
      B_int(23 downto 16) <= (others => '0');
    else
      A_int(23 downto 16) <= (others => A(15));
      B_int(23 downto 16) <= (others => B(15));
    end if;
  end process;

  A_int(15 downto 0) <= A(15 downto 0);
  B_int(15 downto 0) <= B(15 downto 0);

  A_FP <= '1' & A(22 downto 0);
  B_FP <= '1' & B(22 downto 0);

  sign_out <= A(31) xor B(31);

  pipeline_reg_1 : flip_flop
    port map(sign_out, CLK, RST_N, FIRST_STAGE_EN, sign_out_delayed_1);

  pipeline_reg_2 : flip_flop
    port map(sign_out_delayed_1, CLK, RST_N, SECOND_STAGE_EN, sign_out_delayed_2);

  pipeline_reg_4 : REG
    generic map(32)
    port map(A, CLK, RST_N, FIRST_STAGE_EN, a_delayed_1);

  pipeline_reg_5 : REG
    generic map(32)
    port map(a_delayed_1, CLK, RST_N, SECOND_STAGE_EN, a_delayed_2);

  pipeline_reg_6 : REG
    generic map(32)
    port map(B, CLK, RST_N, FIRST_STAGE_EN, b_delayed_1);

  pipeline_reg_7: REG
    generic map(32)
    port map(b_delayed_1, CLK, RST_N, SECOND_STAGE_EN, b_delayed_2);

  pipeline_reg_8 : flip_flop
    port map(int_FPn, CLK, RST_N, FIRST_STAGE_EN, int_FPn_delayed_1);

  pipeline_reg_9 : flip_flop
    port map(int_FPn_delayed_1, CLK, RST_N, SECOND_STAGE_EN, int_FPn_delayed_2);

  pipeline_reg_10 : flip_flop
    port map(S_Un, CLK, RST_N, FIRST_STAGE_EN, S_Un_delayed_1);

  pipeline_reg_11 : flip_flop
    port map(S_Un_delayed_1, CLK, RST_N, SECOND_STAGE_EN, S_Un_delayed_2);

  pipeline_reg_12 : REG
    generic map(2)
    port map(rounding_mode, CLK, RST_N, FIRST_STAGE_EN, rounding_mode_delayed_1);

  pipeline_reg_13 : REG
    generic map(2)
    port map(rounding_mode_delayed_1, CLK, RST_N, SECOND_STAGE_EN, rounding_mode_delayed_2);

  mux1 : mux2to1
    generic map(24)
    port map(A_FP, A_int, int_FPn, In1);

  mux2 : mux2to1
    generic map(24)
    port map(B_FP, B_int, int_FPn, In2);

  mult : multiplier
    generic map(24)
    port map(CLK, RST_N, FIRST_STAGE_EN, In1, In2, S_Un, mult_out);

  pipeline_reg_3 : REG
    generic map(48)
    port map(mult_out, CLK, RST_N, SECOND_STAGE_EN, mult_out_delayed);

  rounding_comp : rounding
    port map(mult_out_delayed, rounding_mode_delayed_2, sign_out_delayed_2, mantissa, incr);

  exp_eval : Exponent_eval
    port map(CLK, RST_N, FIRST_STAGE_EN, SECOND_STAGE_EN, A(30 downto 23), B(30 downto 23), incr, exp_result);

  control : process(a_delayed_2, b_delayed_2, exp_result, mantissa, int_FPn_delayed_2)
  begin
    exp_after_control <= exp_result(7 downto 0);
    mantissa_after_control<= mantissa(22 downto 0);
    overflow <= '0';
    underflow <= '0';
    invalid <= '0';
    if int_FPn_delayed_2 = '0' then
      if and_reduce(a_delayed_2(30 downto 23)) = '1' and or_reduce(a_delayed_2(22 downto 0)) = '1' then     -- NaN * x
        exp_after_control <= (others => '1');
        mantissa_after_control <= a_delayed_2(22 downto 0);
        invalid <= '1';
      elsif and_reduce(b_delayed_2(30 downto 23)) = '1' and or_reduce(b_delayed_2(22 downto 0)) = '1'  then -- x * NaN
        exp_after_control <= (others => '1');
        mantissa_after_control <= b_delayed_2(22 downto 0);
        invalid <= '1';
      elsif and_reduce(a_delayed_2(30 downto 23)) = '1' and or_reduce(a_delayed_2(22 downto 0)) = '0' and or_reduce(b_delayed_2(30 downto 23)) = '0' then  --INF * 0
        exp_after_control <= (others => '1');
        mantissa_after_control <= (others => '1');
        invalid <= '1';
      elsif and_reduce(b_delayed_2(30 downto 23)) = '1' and or_reduce(b_delayed_2(22 downto 0)) = '0' and or_reduce(a_delayed_2(30 downto 23)) = '0' then  --0 * INF
        exp_after_control <= (others => '1');
        mantissa_after_control <= (others => '1');
        invalid <= '1';
      elsif (and_reduce(a_delayed_2(30 downto 23)) = '1' and or_reduce(a_delayed_2(22 downto 0)) = '0') or (and_reduce(b_delayed_2(30 downto 23)) = '1' and or_reduce(b_delayed_2(22 downto 0)) = '0') then --INF * x or x*INF
        exp_after_control <= (others => '1');
        mantissa_after_control <= (others => '0');
      elsif or_reduce(a_delayed_2(30 downto 23)) = '0' or or_reduce(b_delayed_2(30 downto 23)) = '0' then --0 * x or x * 0
        exp_after_control <= (others => '0');
        mantissa_after_control <= (others => '0');
      else
        exp_after_control <= exp_result(7 downto 0);
        mantissa_after_control <= mantissa(22 downto 0);
        if exp_result(9 downto 8) = "11" or (exp_result(9 downto 8)="10" and exp_result(7 downto 0)= "11111111") then
          overflow <= '1';
        elsif exp_result(9 downto 8) = "01" or (exp_result(9 downto 8)="10" and exp_result(7 downto 0)= "00000000") then
          underflow <= '1';
        end if;
      end if;
    end if;
  end process;

  resutl_proc : process(sign_out_delayed_2, exp_after_control, mantissa_after_control, mult_out_delayed, int_FPn_delayed_2, S_Un_delayed_2)
  begin
    if int_FPn_delayed_2 = '1' then
      if S_Un_delayed_2 = '1' then
        product <= mult_out_delayed(47) & mult_out_delayed(30 downto 0);
      else
        product <= mult_out_delayed(31 downto 0);
      end if;
    else
        product <= sign_out_delayed_2 & exp_after_control & mantissa_after_control;
    end if;

  end process;


END ARCHITECTURE;
