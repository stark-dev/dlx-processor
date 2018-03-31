library ieee;
use ieee.std_logic_1164.all;


ENTITY sign_eval IS
  PORT( SIGN1 : IN std_logic;
        SIGN2 : IN std_logic;
        SwAP  : IN std_logic;
        COMPL : IN std_logic;
        SIGN_RES : OUT std_logic);
END ENTITY;

ARCHITECTURE Structural OF sign_eval IS

BEGIN

  sign_res <= '1' when SWAP = '1' and SIGN1 = '0' and SIGN2 = '1' else
              '0' when SWAP = '1' and SIGN1 = '1' and SIGN2 = '0' else
              '0' when SWAP = '0' and COMPL = '0' and SIGN1 = '0' and SIGN2 = '1' else
              '1' when SWAP = '0' and COMPL = '0' and SIGN1 = '1' and SIGN2 = '0' else
              '1' when SWAP = '0' and COMPL = '1' and SIGN1 = '0' and SIGN2 = '1' else
              '0' when SWAP = '0' and COMPL = '1' and SIGN1 = '1' and SIGN2 = '0' else
              SIGN1;

END ARCHITECTURE;
