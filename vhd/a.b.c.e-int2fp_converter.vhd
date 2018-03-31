library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.DLX_package.all;

ENTITY INT2FP_CONVERTER IS  -- WOLOLO I2F
  PORT( DATA_IN       : IN std_logic_vector(31 downto 0);
        ROUNDING_MODE : IN std_logic_vector(1 downto 0);
        DATA_OUT      : OUT std_logic_vector(31 downto 0)
  );
END ENTITY;

-- -- rounding mode: 00 --> minus infinity
-- --                01 --> plus infinity
-- --                10 --> Zero
-- --                11 --> Nearest


ARCHITECTURE Behavioral OF INT2FP_CONVERTER IS

  signal sign_bit     : std_logic;
  signal partial_exponent     : std_logic_vector(7 downto 0);
  signal partial_mantissa     : std_logic_vector(22 downto 0);

  signal exponent     : std_logic_vector(7 downto 0);
  signal mantissa     : std_logic_vector(22 downto 0);

  signal mantissa_ext : std_logic_vector(23 downto 0);

  signal data_in_after_sign : std_logic_vector(31 downto 0);
  signal complement : std_logic_vector(31 downto 0);
  signal sign_bit_integer : natural;

  signal r : std_logic;
  signal s : std_logic;

BEGIN

  DATA_OUT <= sign_bit & exponent & mantissa;

  sign_bit <= DATA_IN(31);
  sign_bit_integer <= 1 when sign_bit = '1' else 0;

  mantissa <= mantissa_ext(22 downto 0);

  exponent <= partial_exponent when mantissa_ext(23) = '0' else
                std_logic_vector(unsigned(partial_exponent)+1);

  complement <= (others => DATA_IN(31));

  data_in_after_sign <= std_logic_vector(unsigned(DATA_IN xor complement)+sign_bit_integer);

  conv_p : process(data_in_after_sign)
    variable exp_int : integer;
    variable shifted_value : std_logic_vector(61 downto 0);
  begin
    exp_int := 31;
      while exp_int >= 0 and data_in_after_sign(exp_int) = '0' loop
        exp_int := exp_int - 1;
      end loop;

      case exp_int is
        when -1 => shifted_value := (others => '0');
                   partial_exponent <= (others => '0');
                   partial_mantissa <= shifted_value(29 downto 7);
                   r <= '0';
                   s <= '0';
        when 0 to 31 => shifted_value := std_logic_vector((unsigned(data_in_after_sign & "000000000000000000000000000000") srl exp_int));
                        partial_exponent <= std_logic_vector(to_unsigned(exp_int+127,8));
                        partial_mantissa <= shifted_value(29 downto 7);
                        r <= shifted_value(6);
                        s <= or_reduce(shifted_value(5 downto 0));
        when others =>  shifted_value := (others => '0');
                        partial_exponent <= (others => '0');
                        partial_mantissa <= shifted_value(29 downto 7);
                        r <= '0';
                        s <= '0';
      end case;
  end process;



  roundin_p : process(partial_mantissa, ROUNDING_MODE, sign_bit, r, s)
  begin
    mantissa_ext <= std_logic_vector(unsigned('0' & partial_mantissa));
    case ROUNDING_MODE is
      when "00"  => if sign_bit = '1' then
                      if r = '1' or s = '1' then
                        mantissa_ext <= std_logic_vector(unsigned('0' & partial_mantissa)+1);
                      end if;
                    end if;
      when "01"  => if sign_bit = '0' then
                      if r = '1' or s = '1' then
                        mantissa_ext <= std_logic_vector(unsigned('0' & partial_mantissa)+1);
                      end if;
                    end if;
      when "10"  => mantissa_ext <= std_logic_vector(unsigned('0' & partial_mantissa));
      when "11"  => if (r='1' and partial_mantissa(0)='1') or (r='1' and s = '1') then
                      mantissa_ext <= std_logic_vector(unsigned('0' & partial_mantissa)+1);
                    end if;
      when others => mantissa_ext <= std_logic_vector(unsigned('0' & partial_mantissa));
    end case;
  end process;

END ARCHITECTURE;
