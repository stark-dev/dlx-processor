library ieee;
use ieee.std_logic_1164.all;


ENTITY G_block  IS
  port (Pik, Gik, Gk_1j : in   std_logic;
        Gij             : out  std_logic);
END ENTITY;

ARCHITECTURE BEHAVIORAL OF G_block IS

BEGIN

  Gij <= Gik or (Pik and Gk_1j);

end ARCHITECTURE;
