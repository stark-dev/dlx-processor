library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY up_down_counter IS
  GENERIC( N        : integer := 16);
  PORT( CLK      : IN std_logic;
        RESET_N  : IN std_logic;
        EN       : IN std_logic;
        TC_value : IN std_logic_vector(N-1 downto 0);
        UP_DOWN  : IN std_logic;  -- 0 up, 1 down
        Q        : OUT std_logic_vector(N-1 downto 0);
        TC       : OUT std_logic);
END ENTITY;

ARCHITECTURE behavioral OF up_down_counter IS
  signal q_temp : unsigned(N-1 downto 0);
  signal tc_temp : std_logic;
BEGIN
  count: process(CLK)
  begin
    if CLK'event and CLK='1' then
      if RESET_N = '0' or tc_temp = '1' then
        q_temp <= to_unsigned(0, N);
      elsif EN='1' then
        if UP_DOWN = '0' then
          q_temp <= q_temp + 1;
        else
          q_temp <= q_temp - 1;
        end if;
      end if;
    end if;
  end process;

  Q <= std_logic_vector(q_temp);

  tc_temp <= '1' when q_temp = unsigned(TC_value) else
             '0';

  TC <= tc_temp;

END ARCHITECTURE;
