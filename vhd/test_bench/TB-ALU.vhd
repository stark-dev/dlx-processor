library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

ENTITY TB_ALU IS
END ENTITY;

ARCHITECTURE test OF TB_ALU IS
	constant N : integer := 32;
	signal func : aluOP;
	signal In1, In2 : std_logic_vector(N-1 downto 0);
	signal ALUOUT : std_logic_vector(N-1 downto 0);

	component ALU 
      	  generic (N : integer := 32);
	  port( FUNC: IN aluOp;
           	DATA1: IN std_logic_vector(N-1 downto 0);
	        DATA2: IN std_logic_vector(N-1 downto 0);
           	OUTALU: OUT std_logic_vector(N-1 downto 0));
	end component;

BEGIN

	DUT : ALU
	  generic map(N)
	  port map(func, In1, In2, ALUOUT);

	sig_gen : process
	begin
	wait for 1 ns;
	In1 <= std_logic_vector(to_unsigned(76282, N));
	In2 <= std_logic_vector(to_unsigned(23718, N));

	FUNC <= ADD_OP;
	wait for 1 ns;
	FUNC <= SUB_OP;
	wait for 1 ns;
	FUNC <= AND_OP;
	wait for 1 ns;
	FUNC <= OR_OP;
	wait for 1 ns;
	FUNC <= XOR_OP;
	wait for 1 ns;
	FUNC <= SGE_OP;
	wait for 1 ns;
	FUNC <= SLE_OP;
	wait for 1 ns;
	FUNC <= SLL_OP;
	wait for 1 ns;
	FUNC <= SNE_OP;
	wait for 1 ns;
	FUNC <= SRL_OP;
	wait;
	end process;


END ARCHITECTURE;

