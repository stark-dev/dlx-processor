library ieee;
use ieee.std_logic_1164.all;
use work.DLX_package.all;
use ieee.numeric_std.all;

ENTITY NPC_adder IS
	generic( N : integer := 32);
	port(    D : IN  std_logic_vector(N-1 downto 0);
		 O : OUT std_logic_vector(N-1 downto 0));
END ENTITY;

ARCHITECTURE Behavioral OF NPC_adder IS

BEGIN

	O <= std_logic_vector(unsigned(D) + 4);

END ARCHITECTURE;
