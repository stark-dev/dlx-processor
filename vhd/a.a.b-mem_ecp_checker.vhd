library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

entity mem_ecp_checker is
	   port(	opcode    				: IN  std_logic_vector(OPCODE_SIZE-1 downto 0);
		 				stack_protection  : IN std_logic;
		 				iram_protection   : IN std_logic;
		 			 	dram_address			: IN 	std_logic_vector(Nbit-1 downto 0);
           	dram_misaligned   : OUT std_logic;
           	dram_reserved     : OUT std_logic;
		 			 	iram_address			: IN 	std_logic_vector(Nbit-1 downto 0);
           	iram_misaligned   : OUT std_logic;
           	iram_reserved     : OUT std_logic
	       );
end entity mem_ecp_checker;

architecture mem_ecp_checker_bh of mem_ecp_checker is

begin
	dram_check_proc : process(opcode, dram_address, stack_protection)
  begin
		case opcode is
			when "100011" | "101011" | "011110" | "011111" => if dram_address(1 downto 0) /= "00" then	-- lw | sw | push | pop
																													dram_misaligned <= '1';
																												else
																													dram_misaligned <= '0';
																												end if;
			when "100001" | "101001" | "100101"=> if dram_address(0) /= '0' then	--lh | sh | lhu
																							dram_misaligned <= '1';
																						else
																							dram_misaligned <= '0';
																						end if;
			when others => dram_misaligned <= '0';
		end case;

		dram_reserved <= '0';
		if(is_store(opcode) or is_load(opcode)) then
			if to_integer(unsigned(dram_address)) < (IRAM_DEPTH*4) or to_integer(unsigned(dram_address)) >= DRAM_DEPTH then
				dram_reserved <= '1';
			else
				if opcode = "011110" or opcode = "011111" then	-- push / pop can access only stack
					if stack_protection = '1' and to_integer(unsigned(dram_address)) <= (DRAM_DEPTH-1-STACK_DEPTH) then
						dram_reserved <= '1';
					end if;
				else -- load store can't access stack
					if stack_protection = '1' and to_integer(unsigned(dram_address)) > (DRAM_DEPTH-1-STACK_DEPTH) then
						dram_reserved <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;

	iram_check_proc : process(iram_address, iram_protection)
	begin
		if to_integer(unsigned(iram_address(Nbit-1 downto 2))) > (IRAM_DEPTH-1) then
			iram_reserved <= '1';
		elsif(iram_protection = '1' and (unsigned(iram_address) < unsigned(START_CODE_POINTER))) then
			iram_reserved <= '1';
		else
			iram_reserved <= '0';
		end if;
		if iram_address(1 downto 0) /= "00" then
			iram_misaligned <= '1';
		else
			iram_misaligned <= '0';
		end if;
  end process;
end architecture;
