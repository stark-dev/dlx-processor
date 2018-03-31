library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic


entity mux2to1 is
    generic (N:integer := 16);
	Port (
	   A:	In	std_logic_vector (N-1 downto 0);
		B:	In	std_logic_vector (N-1 downto 0);
		S:	In	std_logic;
		Y:	Out	std_logic_vector (N-1 downto 0));
end mux2to1;


architecture BEHAVIORAL of mux2to1 is

begin
	Y <= A when S='0' else B;

end BEHAVIORAL;


