library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY LATCH IS
  GENERIC  (N     : integer := 32);
	    PORT (Rst_n : in  std_logic;
            Clk   : in  std_logic;
            D     : in	std_logic_vector(N-1 downto 0);
            Q     : out std_logic_vector(N-1 downto 0));
END LATCH;

ARCHITECTURE behavioral OF LATCH IS
BEGIN
  process(Rst_n, Clk, D)
    begin
    if Rst_n = '0' then
      Q <= (others => '0');
    else
      if Clk = '1' then
        Q <= D;
      end if;
    end if;
  end process;
END ARCHITECTURE;
