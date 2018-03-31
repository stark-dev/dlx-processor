library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity flip_flop is
	Port (	D:	In	std_logic;
		      CK:	In	std_logic;
		      RESET:	In	std_logic;
          EN:     in      std_logic;
		      Q:	Out	std_logic);
end flip_flop;


architecture Behavioral of flip_flop is -- flip flop D with asyncronous reset

begin

	PASYNCH: process(CK,RESET)
	begin
	  if RESET='0' then
	    Q <= '0';
	  elsif CK'event and CK='1' then -- positive edge triggered:
            if EN = '1' then
              Q <= D;
            end if;
	  end if;
	end process;

end Behavioral;
