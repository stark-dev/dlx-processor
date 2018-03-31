library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;


ENTITY shift_right IS
  PORT( SIGNIFICAND : IN std_logic_vector(23 downto 0);
        D      : IN std_logic_vector(7 downto 0);
        SIG_OUT  : OUT std_logic_vector(23 downto 0);
        G     : OUT std_logic;
        R     : OUT std_logic;
        S      : OUT std_logic);
END ENTITY;

ARCHITECTURE Structural OF shift_right IS
  signal discard : std_logic_vector(23 downto 0);
BEGIN

  shift_proc : process(SIGNIFICAND, D)
    variable shifter : std_logic_vector(47 downto 0);
    constant zeros : std_logic_vector(23 downto 0) := (others => '0');
  begin

    shifter := SIGNIFICAND & zeros;
    shifter := std_logic_vector(unsigned(shifter) srl to_integer(unsigned(D)));

    SIG_OUT <= shifter(47 downto 24);
    discard <= shifter(23 downto 0);

  end process;

  G <= discard(23);
  R <= discard(22);
  S <= or_reduce(discard(21 downto 0));

END ARCHITECTURE;
