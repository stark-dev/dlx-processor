library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY sign_extension IS
  generic ( N    :      integer := 24);
  port    ( IN1  : in   std_logic_vector(N-1 downto 0);
            IN2  : in   std_logic_vector(N-1 downto 0);
            S_Un : in   std_logic;        -- 1 -> signed; 0 -> unsigned
            OUT1 : out  std_logic_vector(N downto 0);
            OUT2 : out  std_logic_vector(N downto 0)
          );
END ENTITY;

ARCHITECTURE behavioral OF sign_extension IS
BEGIN
  sign_ext : process(IN1, IN2, S_Un)
  begin
    case S_Un is
      --unsigned
      when '0'    => OUT1 <= '0' & IN1;
                     OUT2 <= '0' & IN2;
      --signed
      when others => OUT1 <= IN1(N-1) & IN1;
                     OUT2 <= IN2(N-1) & IN2;
    end case;
  end process;
END ARCHITECTURE;
