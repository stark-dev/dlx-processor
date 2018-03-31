library IEEE;

use IEEE.std_logic_1164.all;
use WORK.DLX_package.all;

entity tb_dlx is
end tb_dlx;

architecture TEST of tb_dlx is
    signal Clock      : std_logic := '0';
    signal Reset      : std_logic;
    signal Irq_line_s : std_logic_vector(7 downto 0);
    signal Debug      : std_logic;
    signal Crash      : std_logic;
    signal Ack_line_s : std_logic_vector(7 downto 0);

    component DLX
      port (
        Clk                 : in  std_logic;
        Rst                 : in  std_logic;                -- Active Low
        Irq_line            : in  std_logic_vector(7 downto 0);
        DBG                 : IN std_logic;
        Crash               : out std_logic;
        Ack_line            : out std_logic_vector(7 downto 0));
      end component;
begin


        -- instance of DLX
	U1: DLX
	 Port Map (Clock, Reset, Irq_line_s, Debug, Crash, Ack_line_s);

  PCLOCK : process(Clock)
	begin
		Clock <= not(Clock) after 0.5 ns;
	end process;

  Irq_line_s <= (others => '0');
  Reset <= '0', '1' after 1.5 ns;
  Debug <= '0';


end TEST;

-------------------------------

configuration CFG_TB of tb_dlx  is
	for TEST
	end for;
end CFG_TB;
