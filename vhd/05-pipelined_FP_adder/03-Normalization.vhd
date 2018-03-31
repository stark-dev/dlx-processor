library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

ENTITY Normalization IS
  PORT(
        SIGNIFICAND : IN std_logic_vector(23 downto 0);
        GUARD       : IN std_logic;
        ROUND_BIT   : IN std_logic;
        STICKY      : IN std_logic;
        CARRY       : IN std_logic;
        EXPONENT    : IN std_logic_vector(7 downto 0);
        RESULT      : OUT std_logic_vector(23 downto 0);
        EXP_CHANGE  : OUT std_logic_vector(7 downto 0);
        NEW_ROUND   : OUT std_logic;
        NEW_STICKY  : OUT std_logic);
END ENTITY;

ARCHITECTURE Behavioral OF Normalization IS

BEGIN

  norm_proc : process ( SIGNIFICAND, GUARD, CARRY, ROUND_BIT, STICKY, EXPONENT )
    variable count : integer;
    variable i     : natural;
    variable shift : std_logic_vector(47 downto 0);
  begin
    count := 0;
    i := 0;
    shift(47 downto 24) := SIGNIFICAND;
    shift(23) := GUARD;
    shift(22 downto 0) := (others => '0');

    if CARRY = '1' THEN
      NEW_ROUND <= SIGNIFICAND(0);
      NEW_STICKY <= GUARD or ROUND_BIT or STICKY;
      RESULT <= '1' & SIGNIFICAND(23 downto 1);
      EXP_CHANGE <= std_logic_vector(to_signed(1, 8));
    else
      if or_reduce(SIGNIFICAND) = '1' then
        while SIGNIFICAND(23-i) = '0' and (count + 1) /= unsigned(EXPONENT) and i<= 23 loop
          count := count + 1;
          i := i + 1;
        end loop;
      end if;

  --      for i in 0 to 23 loop
  --        if SIGNIFICAND(23-i) = '0' and (count + 1) /= unsigned(EXPONENT) then
--              count := count + 1;
--          else
--            exit;
--          end if;
--          end loop;
--        end if;

      shift := std_logic_vector(unsigned(shift) sll count);
      RESULT <= shift(47 downto 24);

      if count = 0 then
        NEW_ROUND <= GUARD;
        NEW_STICKY <= ROUND_BIT or STICKY;
      elsif count = 1 then
        NEW_ROUND <= ROUND_BIT;
        NEW_STICKY <= STICKY;
      else
        NEW_ROUND <= '0';
        NEW_STICKY <= '0';
      end if;

      EXP_CHANGE <= std_logic_vector(to_signed(-count, 8));

    end if;
  end process;


END ARCHITECTURE;
