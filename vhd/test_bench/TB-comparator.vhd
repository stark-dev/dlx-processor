library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY TB_signed_comparator IS
END ENTITY;

ARCHITECTURE test OF TB_signed_comparator IS
	
	constant N : integer :=32;
	constant C_freq : integer :=4;
	signal A, B, S : std_logic_vector(N-1 downto 0);
	signal addn_sub, C_out, V, S_Un, RES : std_logic;
	signal OP : std_logic_vector(2 downto 0);

	component p4_adder 
 	 generic( N : integer := 32;           -- N must be a power of 2
		   C_freq : integer :=4);       -- C_freq must be a power of 2, not
 	                                       -- greater than N
 	 port( A, B : in std_logic_vector(N downto 1);
		Cin  : in std_logic;            -- Cin=0  --> S = A + B,
                                        -- Cin=1  --> S = A - B
		S    : out std_logic_vector(N downto 1);  -- result
  		Cout : out std_logic;          -- Carry out. It is not an overflow signal
		V    : out std_logic);
	end component;

	
	component comparator 
		generic(N : integer := 32);
		port(	SUM   : IN  std_logic_vector(N-1 downto 0);
			CARRY : IN  std_logic;
			V     : IN  std_logic;
			OP    : IN  std_logic_vector(2 downto 0);
			S_Un  : IN std_logic;
			RES   : OUT std_logic);
	end component;



BEGIN
	adder: p4_adder
	  generic map(N, C_freq)
	  port map(A,B,addn_sub, S, C_out, V);

	DUT : comparator
	  generic map(N)
	  port map(S, C_out, V, OP, S_Un, RES);

	sig_generator : process
	begin
		wait for 1 ns;
		addn_sub <= '1';
		S_Un <= '1'; --signed
		OP <= "000"; -- greater
		A  <= std_logic_vector(to_signed(4893, N));
		B  <= std_logic_vector(to_signed(380, N));
		wait for 1 ns;
		A  <= std_logic_vector(to_signed(4893, N));
		B  <= std_logic_vector(to_signed(4893, N));
		wait for 1 ns;
		A  <= std_logic_vector(to_signed(4893, N));
		B  <= std_logic_vector(to_signed(5892184, N));
		wait for 1 ns;
		A  <= std_logic_vector(to_signed(0, N));
		B  <= std_logic_vector(to_signed(-498121, N));
		wait for 1 ns;
		A  <= std_logic_vector(to_signed(0, N));
		B  <= std_logic_vector(to_signed(0, N));
		wait for 1 ns;
		A  <= std_logic_vector(to_signed(-386432141, N));
		B  <= std_logic_vector(to_signed(-4219219, N));
		wait for 5 ns;
		S_Un <= '0'; --unsigned
		OP <= "000"; -- greater
		A  <= std_logic_vector(to_unsigned(4893, N));
		B  <= std_logic_vector(to_unsigned(380, N));
		wait for 1 ns;
		A  <= std_logic_vector(to_unsigned(4893, N));
		B  <= std_logic_vector(to_unsigned(4893, N));
		wait for 1 ns;
		A  <= std_logic_vector(to_unsigned(4893, N));
		B  <= std_logic_vector(to_unsigned(5892184, N));
		wait for 1 ns;
		A  <= std_logic_vector(to_unsigned(0, N));
		B  <= std_logic_vector(to_unsigned(498121, N));
		wait for 1 ns;
		A  <= std_logic_vector(to_unsigned(0, N));
		B  <= std_logic_vector(to_unsigned(0, N));
		wait;


	end process;


END ARCHITECTURE;
