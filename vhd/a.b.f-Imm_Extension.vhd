library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

ENTITY Imm_extension IS
  generic ( N    : integer  := 16;
	          M    : integer := 32);
  port (    Din : IN std_logic_vector(N-1 downto 0);
	          Dout : OUT std_logic_vector(M-1 downto 0));
END ENTITY;

ARCHITECTURE Structural OF Imm_Extension IS

BEGIN
  
  Dout(M-1 downto N) <= ( others => Din(N-1));
  Dout(N-1 downto 0) <= Din;

END ARCHITECTURE;
