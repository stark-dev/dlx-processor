library ieee;
use ieee.std_logic_1164.all;
use work.DLX_package.all;

-- This component performs a comparation between A and B. The input OP determines which type of comparation
-- is to be performed, the input S_Un is to decide between Signed and Unsigned numbers.
-- OP = "000" --> A > B
-- OP = "001" --> A >= B
-- OP = "010" --> A < B
-- OP = "011" --> A <= B
-- OP = "100" --> A = B
ENTITY comparator IS
	generic(N : integer := 32);
	port(	SUM   : IN  std_logic_vector(N-1 downto 0);
		CARRY : IN  std_logic;
		V     : IN  std_logic;
		OP    : IN  std_logic_vector(2 downto 0);
		S_Un  : IN  std_logic;
		RES   : OUT std_logic);
END ENTITY;

ARCHITECTURE Structural OF comparator IS
	signal u_greater, u_greater_equal, u_smaller, u_smaller_equal : std_logic;
	signal s_greater, s_greater_equal, s_smaller, s_smaller_equal : std_logic;
	signal equal : std_logic;
	signal z : std_logic;
	signal sel : std_logic_vector(3 downto 0);
BEGIN
	z <= not(or_reduce(SUM));
	u_greater <= CARRY and not(z);
	u_greater_equal <= CARRY;
	u_smaller <= not(CARRY);
	u_smaller_equal <= (not(CARRY) or z);
	s_greater <= not((V xor SUM(N-1)) or z);
	s_greater_equal <= not(V xor SUM(N-1));
	s_smaller <= V xor SUM(N-1);
	s_smaller_equal <= (V xor SUM(N-1)) or z;
	equal <= z;

	sel <= OP(2) & S_Un & OP(1 downto 0);

	RES <= u_greater       when sel= "0000" else
	       u_greater_equal when sel= "0001" else
	       u_smaller       when sel= "0010" else
	       u_smaller_equal when sel= "0011" else
	       s_greater       when sel= "0100" else
	       s_greater_equal when sel= "0101" else
	       s_smaller       when sel= "0110" else
	       s_smaller_equal when sel= "0111" else
	       equal;

END ARCHITECTURE;
