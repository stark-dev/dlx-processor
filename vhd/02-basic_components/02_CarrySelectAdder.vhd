library ieee;
use ieee.std_logic_1164.all;

ENTITY CarrySelectAdder IS
  generic (N  : integer := 8);
  PORT(  A,B  : in  std_logic_vector(N-1 downto 0);
         Cin  : in  std_logic;
         S    : out std_logic_vector(N-1 downto 0);
         Cout : out std_logic);

end ENTITY;

architecture STRUCTURAL of CarrySelectAdder is

  component RCA is
	generic (N     :        integer := 8);
	Port (	A:	In	std_logic_vector(N-1 downto 0);
		B:	In	std_logic_vector(N-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(N-1 downto 0);
		Co:	Out	std_logic);
  end component;

  component Mux2to1 is
    generic (N:integer := 16);
	Port (  A:	In	std_logic_vector (N-1 downto 0);
		B:	In	std_logic_vector (N-1 downto 0);
		S:	In	std_logic;
		Y:	Out	std_logic_vector (N-1 downto 0));
  end component;

  --SIGNALS
  type arr is array (0 to 1) of std_logic_vector(N-1 downto 0);
  type arr_bit is array (0 to 1) of std_logic;
  signal sum : arr;
  signal carry : arr_bit;

begin  -- STRUCTURAL

  RCA0 : RCA
    GENERIC MAP (N => N)
    port map (A, B, '0', sum(0), carry(0));

  RCA1 : RCA
    GENERIC MAP (N => N)
    port map (A, B, '1', sum(1), carry(1));

  MUX : Mux2to1
    GENERIC MAP (N => N)
    port map (sum(0), sum(1), Cin, S);

  Cout <= carry(0) when Cin = '0' else
          carry(1);


end STRUCTURAL;
