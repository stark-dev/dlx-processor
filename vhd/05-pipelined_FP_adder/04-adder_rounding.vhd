library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

-- rounding mode: 00 --> minus infinity
--                01 --> plus infinity
--                10 --> Zero
--                11 --> Nearest


ENTITY adder_rounding IS
  PORT( result : IN std_logic_vector(23 downto 0);
        rounding_mode : IN std_logic_vector(1 downto 0);
        result_sign : IN std_logic;
        round_bit  : IN std_logic;
        sticky_bit : IN std_logic;
        rounded_result : OUT std_logic_vector(23 downto 0);
        exp_incr : OUT std_logic);
END ENTITY;

ARCHITECTURE Behavioral OF adder_rounding IS
  signal extended_result, extended_rounded_result : std_logic_vector(24 downto 0);
BEGIN

    extended_result <= '0' & result;

    rounding_mode_proc: process(extended_result, rounding_mode, result_sign, sticky_bit, round_bit, result(0))
    begin
      extended_rounded_result <= extended_result;

      case rounding_mode is
        when "00" => if result_sign = '1' then
                      if round_bit = '1' or sticky_bit = '1' then
                        extended_rounded_result <= std_logic_vector(unsigned(extended_result)+1);
                      end if;
                    end if;
        when "01" =>  if result_sign = '0' then
                      if round_bit = '1' or sticky_bit = '1' then
                        extended_rounded_result <= std_logic_vector(unsigned(extended_result)+1);
                      end if;
                    end if;
        when "10" =>   extended_rounded_result <= extended_result;
        when others => if round_bit = '1' and (sticky_bit = '1' or result(0) = '1') then
                       extended_rounded_result <= std_logic_vector(unsigned(extended_result)+1);
                     end if;
      end case;
    end process;

    exp_incr <= extended_rounded_result(24);
    rounded_result <= extended_rounded_result(23 downto 0) when extended_rounded_result(24) = '0' else
                      extended_rounded_result(24 downto 1);


END ARCHITECTURE;
