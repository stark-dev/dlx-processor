library ieee;
use ieee.std_logic_1164.all;


ENTITY PG_block  IS
  port (Pik, Gik, Pk_1j,Gk_1j : in   std_logic;
        Pij, Gij              : out  std_logic);
END ENTITY;

ARCHITECTURE BEHAVIORAL OF PG_block IS

BEGIN

  Pij <= Pik and Pk_1j;
  Gij <= Gik or (Pik and Gk_1j);

end ARCHITECTURE;







