library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY TB_logicals IS
END ENTITY;

ARCHITECTURE test of TB_logicals IS

	constant N : integer:=4;
	signal S0, S1 : std_logic;
	signal R1,R2,D_OUT : std_logic_vector(N-1 downto 0);

	component logicals IS
		generic(N : integer := 32);
		port(	S0 : IN std_logic;
			S1 : IN std_logic;
			R1 : IN std_logic_vector(N-1 downto 0);
			R2 : IN std_logic_vector(N-1 downto 0);
			D_OUT : OUT std_logic_vector(N-1 downto 0));
	end component;

BEGIN

	func : logicals 
		generic map(N)
		port map(S0, S1, R1, R2, D_out);

	test_proc : process
		begin
		R1 <= std_logic_vector(to_unsigned(4, N));
		R2 <= std_logic_vector(to_unsigned(5, N));
		wait for 1 ns;
		S0 <= '0';
		S1 <= '1';
		wait for 1 ns;
		S0 <= '1';
		S1 <= '1';
		wait for 1 ns;
		S0 <= '1';
		S1 <= '0';
		wait;
	end process;

END ARCHITECTURE;




