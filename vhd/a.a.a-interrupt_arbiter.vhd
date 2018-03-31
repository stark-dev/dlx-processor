library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

entity interrupt_arbiter is
	generic( 	N               : integer);
	   port(	rst							: IN  std_logic;
		  			interrupt_in    : IN  std_logic_vector(N-1 downto 0);
						ack_cu					: IN 	std_logic;
           	interrupt_code  : OUT irqCode;
						ack_out					: OUT std_logic_vector(N-1 downto 0);
           	handshake       : OUT std_logic
	       );
end entity interrupt_arbiter;

architecture arbiter_behav of interrupt_arbiter is
	signal irq_code_s 		 : irqCode;
	signal handshake_s 		 : std_logic;

begin
	interrupt_code <= irq_code_s;
	handshake <= handshake_s;

	code_p : process (rst, ack_cu, interrupt_in)
	variable found : boolean;
	variable index : integer;
	begin
	  found := false;
	  index := N-1;
		if rst = '0' then
			irq_code_s <= NO_IRQ;
		elsif ack_cu = '0' then	--freezes code when ack_cu = '1'
			irq_code_s <= NO_IRQ;
			while (not found) and ( index >= 0 ) loop
				if interrupt_in(index) = '1' then
					irq_code_s <= irqCode'val(index);
					found := true;
				end if;
				index := index - 1;
			end loop;
	end if;
	end process;

	ack_p : process (ack_cu, handshake_s, irq_code_s)
	begin
		if handshake_s = '1' then	--resets ack on handshake
      ack_out <= (others => '0');
    elsif ack_cu = '1' then --sets ack
			ack_out(irqCode'pos(irq_code_s)) <= '1';
		end if;
	end process;

	handshake_p : process(rst, ack_cu, interrupt_in, irq_code_s)
	begin
		if rst = '0' then
			handshake_s <= '1';
		elsif ack_cu = '1' then
			handshake_s <= '0';
			if interrupt_in(irqCode'pos(irq_code_s)) = '0' then
				handshake_s <= '1';
			end if;
		end if;
	end process;

end architecture;
