library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity flip_flop_load is
	Port (	D       :	In	std_logic;
		      CK      :	In	std_logic;
		      RESET   :	In	std_logic;
          LD_EN   : in  std_logic;
          LD_VAL  : in  std_logic;
          EN      : in  std_logic;
		      Q       :	Out	std_logic);
end flip_flop_load;


architecture Behavioral of flip_flop_load is -- flip flop D with asyncronous reset and asyncronous load

begin

	PASYNCH: process(CK,RESET)
	begin
	  if RESET='0' then
	    Q <= '0';
	  elsif CK'event and CK='1' then -- positive edge triggered:
			if LD_EN = '1' then
				Q <= LD_VAL;
      elsif EN = '1' then
        Q <= D;
      end if;
	  end if;
	end process;

end Behavioral;
