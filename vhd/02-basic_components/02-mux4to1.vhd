library ieee;
use ieee.std_logic_1164.all;

entity mux4to1 is
	 generic (N:integer := 16);
    	 Port (
	   In1:	In	std_logic_vector (N-1 downto 0);
       	   IN2:	In	std_logic_vector (N-1 downto 0);
       	   IN3:	In	std_logic_vector (N-1 downto 0);
       	   IN4:	In	std_logic_vector (N-1 downto 0);
	   S:	In	std_logic_vector(1 downto 0);
	   Y:	Out	std_logic_vector (N-1 downto 0));
end mux4to1;


architecture BEHAVIORAL of mux4to1 is

begin
	Y <= In1 when S= "00" else 
	     In2 when S= "01" else 
	     In3 when S= "10" else 
	     In4 when S= "11";

end BEHAVIORAL;