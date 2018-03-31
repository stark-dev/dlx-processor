library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

ENTITY TB_FP_adder IS
END ENTITY;

ARCHITECTURE test OF TB_FP_adder IS

  component FP_adder
    PORT( A1 : IN std_logic_vector(Nbit-1 downto 0);
          A2 : IN std_logic_vector(Nbit-1 downto 0);
          ADDn_SUB : IN std_logic;
          ROUNDING_MODE : IN std_logic_vector(1 downto 0);
          SUM : OUT std_logic_vector(Nbit-1 downto 0);
          OVERFLOW : OUT std_logic;
          UNDERFLOW : OUT std_logic;
          INVALID : OUT std_logic);
  end component;

  signal A1, A2, SUM : std_logic_vector(Nbit-1 downto 0);
  signal ADDn_SUB : std_logic;
  signal Overflow, Underflow, Invalid : std_logic;
  signal ROUNDING_MODE : std_logic_vector(1 downto 0);

BEGIN

  DUT : FP_adder
    port map(A1, A2, ADDn_SUB, ROUNDING_MODE, SUM, Overflow, Underflow, Invalid);

    ROUNDING_MODE <= "10";
    --A1 <= "10111111101000000000000000000000";
    A1 <= "00000000100000000000000000000000";
    --A2 <= "00000000000000000000000000000001";
    A2 <= "00000000001000000000000000000000";
    ADDn_SUB <= '1';

END ARCHITECTURE;
