library ieee;
use ieee.std_logic_1164.all;
use work.DLX_package.all;
use ieee.numeric_std.all;

ENTITY PUSH_POP_adder IS
	generic(N : integer := 32);
	port(   D : IN  std_logic_vector(N-1 downto 0);
					S : IN  std_logic; -- 0 -> pop, 1 -> push
		 			O : OUT std_logic_vector(N-1 downto 0));
END ENTITY;

ARCHITECTURE Behavioral OF PUSH_POP_adder IS

BEGIN

	O <= std_logic_vector(unsigned(D) - 4) when S = '1' else
			 std_logic_vector(unsigned(D) + 4);

END ARCHITECTURE;
