library ieee;
use ieee.std_logic_1164.all;

ENTITY CSA IS
  generic (N  : integer := 8);
  PORT(  A,B, C  : in  std_logic_vector(N-1 downto 0);
         S    : out std_logic_vector(N-1 downto 0);
         Cout : out std_logic_vector(N-1 downto 0));
END ENTITY;


ARCHITECTURE Structural OF CSA is

    component FA
      Port (A:	In	std_logic;
           B:	In	std_logic;
           Ci:	In	std_logic;
           S:	Out	std_logic;
           Co:	Out	std_logic);
    end component;

BEGIN

  adders: for i in 0 to N-1 generate
    FullAdder: FA
      port map(A(i), B(i), C(i), S(i), Cout(i));
    end generate;

END ARCHITECTURE;
