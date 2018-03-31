library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity REG_CLEAR is
  generic(N : integer := 1;
          RESET_VALUE : integer := 0;
          CLEAR_VALUE : integer := 0);
	Port (	D     :	IN	std_logic_vector(N-1 downto 0);
		      CK    :	IN	std_logic;
		      RESET :	IN	std_logic;
		      CLEAR :	IN	std_logic;
          EN    : IN  std_logic;
		      Q     :	OUT	std_logic_vector(N-1 downto 0));
end REG_CLEAR;


architecture ASYNCHRONOUS_BH of REG_CLEAR is -- flip flop D with asyncronous reset and synchronous clear

begin

	PASYNCH: process(CK,RESET)
	begin
    if RESET='0' then -- active low reset
      Q <= std_logic_vector(to_signed(RESET_VALUE, N));
	  elsif CK'event and CK='1' then -- positive edge triggered:
      if CLEAR = '1' then
        q <= std_logic_vector(to_signed(CLEAR_VALUE, N));
      elsif EN = '1' then
        Q <= D;
      end if;
	  end if;
	end process;

end ASYNCHRONOUS_BH;
