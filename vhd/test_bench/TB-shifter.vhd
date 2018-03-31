library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY TB_Shifter IS
END ENTITY;

ARCHITECTURE test OF TB_Shifter IS

	constant N : integer := 32;
	signal R, R_OUT : std_logic_vector(N-1 downto 0);
	signal count : std_logic_vector(4 downto 0);
	signal arith_logicaln, right_leftn : std_logic;

	component Shifter IS
		generic(N : integer := 32);
		port( 	R	       : IN std_logic_vector(N-1 downto 0);
			arith_logicaln : IN std_logic;
			right_leftn    : IN std_logic;
			count	       : IN std_logic_vector(4 downto 0);
			R_OUT	       : OUT std_logic_vector(N-1 downto 0));
	end component;
	
BEGIN

	DUT : Shifter
		generic map(N)
		port map(R, arith_logicaln, right_leftn, count, R_out);

	sig_val : process
	begin
		R <= "11001010101101000110100110110001";
		wait for 1 ns;
		arith_logicaln <= '0';
		right_leftn <= '0';
		count <= std_logic_vector(to_unsigned(3, 5));
		wait for 1 ns;
		count <= std_logic_vector(to_unsigned(7, 5));
		wait for 1 ns;
		count <= std_logic_vector(to_unsigned(14, 5));
		wait for 1 ns;
		count <= std_logic_vector(to_unsigned(20, 5));
		wait for 1 ns;
		count <= std_logic_vector(to_unsigned(27, 5));
		wait for 1 ns;
		count <= std_logic_vector(to_unsigned(31, 5));
		wait for 1 ns;
		arith_logicaln <= '0';
		right_leftn <= '1';
		count <= std_logic_vector(to_unsigned(0, 5));
		wait for 1 ns;
		count <= std_logic_vector(to_unsigned(5, 5));
		wait for 1 ns;
		count <= std_logic_vector(to_unsigned(9, 5));
		wait for 1 ns;
		count <= std_logic_vector(to_unsigned(11, 5));
		wait for 1 ns;
		count <= std_logic_vector(to_unsigned(17, 5));
		wait for 1 ns;
		count <= std_logic_vector(to_unsigned(28, 5));
		wait for 1 ns;
		arith_logicaln <= '1';
		right_leftn <= '1';
		count <= std_logic_vector(to_unsigned(1, 5));
		wait for 1 ns;
		count <= std_logic_vector(to_unsigned(15, 5));
		wait for 1 ns;
		count <= std_logic_vector(to_unsigned(16, 5));
		wait for 1 ns;
		count <= std_logic_vector(to_unsigned(21, 5));
		wait for 1 ns;
		count <= std_logic_vector(to_unsigned(24, 5));
		wait for 1 ns;
		count <= std_logic_vector(to_unsigned(26, 5));
		wait;
	end process;

END ARCHITECTURE;
