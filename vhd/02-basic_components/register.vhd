library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity REG is
  generic(N : integer := 1;
          RESET_VALUE : integer := 0);
	Port (	D:	In	std_logic_vector(N-1 downto 0);
		      CK:	In	std_logic;
		      RESET:	In	std_logic;
          EN:     in      std_logic;
		      Q:	Out	std_logic_vector(N-1 downto 0));
end REG;


architecture SYNCHRONOUS_BH of REG is -- flip flop D with syncronous reset

begin
	PSYNCH: process(CK,RESET)
	begin
	  if CK'event and CK='1' then -- positive edge triggered:
	    if RESET='0' then -- active low reset
	      Q <= std_logic_vector(to_signed(RESET_VALUE, N));
	    else
              if EN = '1' then
                Q <= D; -- input is written on output
              end if;
	    end if;
	  end if;
	end process;

end SYNCHRONOUS_BH;

architecture ASYNCHRONOUS_BH of REG is -- flip flop D with asyncronous reset

begin

	PASYNCH: process(CK,RESET)
	begin
    if RESET='0' then -- active low reset
      Q <= std_logic_vector(to_signed(RESET_VALUE, N));
	  elsif CK'event and CK='1' then -- positive edge triggered:
      if EN = '1' then
        Q <= D;
      end if;
	  end if;
	end process;

end ASYNCHRONOUS_BH;


configuration CFG_REG_SYNC of REG is
	for SYNCHRONOUS_BH
	end for;
end CFG_REG_SYNC;


configuration CFG_REG_ASYNC of REG is
	for ASYNCHRONOUS_BH
	end for;
end CFG_REG_ASYNC;
