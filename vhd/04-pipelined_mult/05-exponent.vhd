library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY Exponent_eval IS
  PORT( CLK : IN std_logic;
        RST_N : IN std_logic;
        FIRST_STAGE_EN : IN std_logic;
        SECOND_STAGE_EN : IN std_logic;
        exp1 : IN std_logic_vector(7 downto 0);
        exp2 : IN std_logic_vector(7 downto 0);
        incr : IN std_logic;
        exp_res : OUT std_logic_vector(9 downto 0));
END ENTITY;

ARCHITECTURE Structural OF Exponent_eval IS

  component reg
    generic(N : integer := 1;
            RESET_VALUE : integer := 0);
    Port (	D:	In	std_logic_vector(N-1 downto 0);
            CK:	In	std_logic;
            RESET:	In	std_logic;
            EN:     in      std_logic;
            Q:	Out	std_logic_vector(N-1 downto 0));
  end component ;

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

  signal exp1_ext, exp2_ext : std_logic_vector(8 downto 0);
  signal intermediate_sum : std_logic_vector(8 downto 0);
  signal intermediate_sum_delayed : std_logic_vector(8 downto 0);
  signal intermediate_cout : std_logic;
  signal bias : std_logic_vector(8 downto 0);
  signal exp_res_partial, exp_res_incr : std_logic_vector(9 downto 0);
  signal exp_res_partial_delayed, exp_res_incr_delayed : std_logic_vector(9 downto 0);

BEGIN

  exp1_ext(8) <= '0';
  exp1_ext(7 downto 0) <= exp1;

  exp2_ext(8) <= '0';
  exp2_ext(7 downto 0) <= exp2;

  bias <= std_logic_vector(to_signed(-127, 9));

  first_add : RCA
    generic map(9)
    port map(exp1_ext, exp2_ext, '0', intermediate_sum, intermediate_cout);

  pipeline_reg_1 : REG
    generic map(9)
    port map(intermediate_sum, CLK, RST_N, FIRST_STAGE_EN, intermediate_sum_delayed);

  second_add : RCA
    generic map(9)
    port map(intermediate_sum_delayed, bias, '0', exp_res_partial(8 downto 0), exp_res_partial(9));

  pipeline_reg_2 : REG
    generic map(10)
    port map(exp_res_partial, CLK, RST_N, SECOND_STAGE_EN, exp_res_partial_delayed);

  pipeline_reg_3 : REG
    generic map(10)
    port map(exp_res_incr, CLK, RST_N, SECOND_STAGE_EN, exp_res_incr_delayed);

  Mux1 : mux2to1
    generic map(10)
    port map(exp_res_partial_delayed, exp_res_incr_delayed, incr, exp_res);

  exp_res_incr <= std_logic_vector(unsigned(exp_res_partial)+1);



END ARCHITECTURE;
