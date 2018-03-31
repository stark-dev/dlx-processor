library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY increment IS
  PORT( exponent : IN std_logic_vector(8 downto 0);
        inc_exponent : OUT std_logic_vector(8 downto 0));
END ENTITY;

ARCHITECTURE Behavioral OF increment IS

BEGIN

  inc_exponent <= std_logic_vector(unsigned(exponent) + 1);

END ARCHITECTURE;
