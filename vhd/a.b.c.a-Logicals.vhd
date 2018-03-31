
library ieee;
use ieee.std_logic_1164.all;

--This block is able to produce the logical functions AND, OR and XOR.
-- AND --> S0 = 0, S1 = 1
-- OR  --> S0 = 1, S1 = 1
-- XOR --> S0 = 1, S1 = 0

ENTITY logicals IS
	generic(N : integer := 32);
	port(	S0 : IN std_logic;
		S1 : IN std_logic;
		R1 : IN std_logic_vector(N-1 downto 0);
		R2 : IN std_logic_vector(N-1 downto 0);
		D_OUT : OUT std_logic_vector(N-1 downto 0));
END ENTITY;

ARCHITECTURE Structural OF logicals IS
	
	signal L0, L1, L2 : std_logic_vector(N-1 downto 0);
	signal S0_extended, S1_extended : std_logic_vector(N-1 downto 0);

BEGIN

	S0_extended <= (others => S0);
	S1_extended <= (others => S1);
	L0 <= not(S0_extended and not(R1) and R2);
	L1 <= not(S0_extended and R1 and not(R2));
	L2 <= not(S1_extended and R1 and R2);

	D_OUT <= not(L0 and L1 and L2);

END ARCHITECTURE;