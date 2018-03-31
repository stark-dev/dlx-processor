library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

-- rounding mode: 00 --> minus infinity
--                01 --> plus infinity
--                10 --> Zero
--                11 --> Nearest


ENTITY rounding IS
  PORT( result : IN std_logic_vector(47 downto 0);
        rounding_mode : IN std_logic_vector(1 downto 0);
        result_sign : IN std_logic;
        rounded_result : OUT std_logic_vector(23 downto 0);
        exp_incr : OUT std_logic);
END ENTITY;

ARCHITECTURE Behavioral OF rounding IS

  signal product : std_logic_vector(47 downto 0);
  signal sticky_bit : std_logic;
  signal round_bit : std_logic;
  signal exp_incr_partial_1, exp_incr_partial_2 : std_logic;
  signal rounded_res : std_logic_vector(23 downto 0);

BEGIN

  round_proc : process(result)
    begin
      product <= result;
      sticky_bit <= or_reduce(result(21 downto 0));
      round_bit <= result(22);
      exp_incr_partial_1 <='0';

      if result(47) = '0' then
        product(47 downto 24) <= result(46 downto 23);
      else
        sticky_bit <= or_reduce(result(22 downto 0));
        round_bit <= result(23);
        exp_incr_partial_1 <= '1';
      end if;

    end process;

    rounding_mode_proc: process(product, rounding_mode, result_sign, sticky_bit, round_bit)
    begin
      rounded_res <= product(47 downto 24);

      case rounding_mode is
        when "00" => if result_sign = '1' then
                      if round_bit = '1' or sticky_bit = '1' then
                        rounded_res <= std_logic_vector(unsigned(product(47 downto 24))+1);
                      end if;
                    end if;
        when "01" =>  if result_sign = '0' then
                      if round_bit = '1' or sticky_bit = '1' then
                        rounded_res <= std_logic_vector(unsigned(product(47 downto 24))+1);
                      end if;
                    end if;
        when "10" => rounded_res <= product(47 downto 24);
        when others => if round_bit = '1' and (sticky_bit = '1' or product(24) = '1') then
                        rounded_res <= std_logic_vector(unsigned(product(47 downto 24))+1);
                     end if;
      end case;

    end process;

    exp_incr_partial_2 <= not(or_reduce(rounded_res));

    exp_incr <= exp_incr_partial_1 or exp_incr_partial_2;
    rounded_result <= rounded_res;



END ARCHITECTURE;
