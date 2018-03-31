library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

entity ecp_lut is
	   port( 	ecp_in          : IN  exceptionCode;
		 				irq_in					: IN  irqCode;
		 			 	ecp_addr        : OUT std_logic_vector(Nbit-1 downto 0)
	       );
end entity ecp_lut;

architecture lut_behav of ecp_lut is
begin
	addr_out_p : process(ecp_in, irq_in) is
		begin
			case ecp_in is
		    when NO_ECP      => ecp_addr <= std_logic_vector(to_unsigned(TEXT_ADDRESS, Nbit));
		    when OVF_ECP     => ecp_addr <= std_logic_vector(to_unsigned(R0_ADDRESS, Nbit));
		    when UFL_ECP     => ecp_addr <= std_logic_vector(to_unsigned(R0_ADDRESS, Nbit));
		    when INV_CON_ECP => ecp_addr <= std_logic_vector(to_unsigned(R1_ADDRESS, Nbit));
		    when IOP_ECP     => ecp_addr <= std_logic_vector(to_unsigned(R2_ADDRESS, Nbit));
		    when IRM_ECP     => ecp_addr <= std_logic_vector(to_unsigned(R3_ADDRESS, Nbit));
		    when IRR_ECP     => ecp_addr <= std_logic_vector(to_unsigned(R3_ADDRESS, Nbit));
		    when DRM_ECP     => ecp_addr <= std_logic_vector(to_unsigned(R4_ADDRESS, Nbit));
		    when DRR_ECP     => ecp_addr <= std_logic_vector(to_unsigned(R4_ADDRESS, Nbit));
		    when IRQ_ECP     =>
					case irq_in is
						when NO_IRQ  => ecp_addr <= std_logic_vector(to_unsigned(R5_ADDRESS, Nbit));
						when IRQ0    => ecp_addr <= std_logic_vector(to_unsigned(R5_ADDRESS, Nbit));
						when IRQ1    => ecp_addr <= std_logic_vector(to_unsigned(R6_ADDRESS, Nbit));
						when IRQ2    => ecp_addr <= std_logic_vector(to_unsigned(R6_ADDRESS, Nbit));
						when IRQ3    => ecp_addr <= std_logic_vector(to_unsigned(R7_ADDRESS, Nbit));
						when IRQ4    => ecp_addr <= std_logic_vector(to_unsigned(R7_ADDRESS, Nbit));
						when IRQ5    => ecp_addr <= std_logic_vector(to_unsigned(R8_ADDRESS, Nbit));
						when IRQ6    => ecp_addr <= std_logic_vector(to_unsigned(R8_ADDRESS, Nbit));
						when IRQ7    => ecp_addr <= std_logic_vector(to_unsigned(R9_ADDRESS, Nbit));
						when others  => ecp_addr <= std_logic_vector(to_unsigned(R9_ADDRESS, Nbit));
					end case;
		    when GEN_ECP 		=> ecp_addr <= std_logic_vector(to_unsigned(TEXT_ADDRESS, Nbit));
		    when others 		=> ecp_addr <= std_logic_vector(to_unsigned(TEXT_ADDRESS, Nbit));
		end case;
	end process;
end architecture;
