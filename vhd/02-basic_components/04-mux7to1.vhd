library ieee;
use ieee.std_logic_1164.all;

entity mux7to1 is
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
end mux7to1;


architecture BEHAVIORAL of mux7to1 is

begin
	Y <= In1 when S= "000" else
	     In2 when S= "001" else
	     In3 when S= "010" else
	     In4 when S= "011" else
	     In5 when S= "100" else
	     In6 when S= "101" else
	     In7;

end BEHAVIORAL;
