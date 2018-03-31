library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

entity ecp_decoder is
	   port( 	ecp_cause       : IN  std_logic_vector(ECP_SIZE-1 downto 0);
		 			 	ecp_code        : OUT exceptionCode
	       );
end entity ecp_decoder;

architecture decoder_behav of ecp_decoder is
begin
	code_out_p : process (ecp_cause) is
		begin
			case ecp_cause is
		    when "00000" => ecp_code <= NO_ECP ;
		    when "00001" => ecp_code <= OVF_ECP;
		    when "00010" => ecp_code <= UFL_ECP;
		    when "00011" => ecp_code <= INV_CON_ECP;
		    when "00100" => ecp_code <= IOP_ECP;
		    when "00101" => ecp_code <= IRM_ECP;
		    when "00110" => ecp_code <= IRR_ECP;
		    when "00111" => ecp_code <= DRM_ECP;
		    when "01000" => ecp_code <= DRR_ECP;
		    when "01001" => ecp_code <= IRQ_ECP;
		    when "01010" => ecp_code <= GEN_ECP;
		    when others => ecp_code <= NO_ECP;
		end case;
	end process;
end architecture;
