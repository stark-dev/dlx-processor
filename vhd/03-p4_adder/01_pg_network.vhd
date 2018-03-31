library ieee;
use ieee.std_logic_1164.all;

ENTITY PG_network IS
  generic (N : integer := 32);
  port (A, B : in   std_logic_vector(N downto 1);
        Cin  : in   std_logic;
        P    : out  std_logic_vector(N-1 downto 1);
        G    : out  std_logic_vector(N downto 1));
END ENTITY;


ARCHITECTURE BEHAVIORAL OF PG_network IS
  signal g1, p1 : std_logic;
BEGIN
  g1 <= A(1) and B(1);
  p1 <= A(1) or B(1);
  P <= A(N downto 2) or B(N downto 2);
  G(N downto 2) <= A(N downto 2) and B(N downto 2);
  G(1) <= g1 or (p1 and Cin);


END  ARCHITECTURE;
