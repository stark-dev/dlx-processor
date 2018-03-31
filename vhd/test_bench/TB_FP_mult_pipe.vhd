library ieee;
use ieee.std_logic_1164.all;

ENTITY TB_FP_mult IS
END ENTITY;

ARCHITECTURE test OF TB_FP_mult IS


  component FP_mult
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

  signal Clk : std_logic;
  signal rst_n : std_logic;
  signal A, B : std_logic_vector(31 downto 0);
  signal first_stage_en : std_logic;
  signal second_stage_en : std_logic;
  signal int_FPn : std_logic;
  signal S_Un : std_logic;
  signal rounding_mode : std_logic_vector(1 downto 0);
  signal product : std_logic_vector(31 downto 0);
  signal overflow : std_logic;
  signal underflow : std_logic;
  signal invalid : std_logic;
BEGIN

  DUT : FP_mult
    port map(Clk, rst_n, first_stage_en, second_stage_en, A, B, int_FPn, S_Un, rounding_mode, product, overflow, underflow, invalid);

  clock_gen : process
  begin
    clk <= '1';
    wait for 0.5 ns;
    clk <= '0';
    wait for 0.5 ns;
  end process;

  sig_gen : process
  begin
    rst_n <= '0';
    first_stage_en <= '1';
    second_stage_en <= '1';
    A <= "00000000000000000000000011111111";
    B <= "01000100010001001000001000101010";
    wait for 1.2 ns;
    rst_n <= '1';
    wait for 1 ns;
    --
    -- A <= "00000000000000001111110000111111";
    -- B <= "00000000000000000000011110001110";
    -- wait for 1 ns;
    -- A <= "11001010011000010010100000000000";
    -- B <= "01001010101011101011001010101010";
    -- wait for 1 ns;
    -- A <= "00101010101010101010111010101000";
    -- B <= "10010101011001100010100000000000";
    -- wait for  1 ns;
    -- A <= "11111111111000010010100000000000";
    -- B <= "10001110101010000000000000000000";
    -- wait for 1 ns;
    -- A <= "11001010011000010010100000000000";
    -- B <= "11111111111000010010100000000000";
    -- wait for 1 ns;
    -- A <= "01111111100000000000000000000000";
    -- B <= "10011000011000010010100000000000";
    -- wait for 1 ns;
    -- A <= "10000000000000000000000000000000";
    -- B <= "01111111100000000000000000000000";
    wait;
end process;

  int_FPn <= '0';
  S_Un <= '1';
  rounding_mode <= "00";

END ARCHITECTURE;
