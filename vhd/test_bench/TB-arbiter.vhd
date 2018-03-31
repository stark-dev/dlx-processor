library ieee;
use ieee.std_logic_1164.all;
use work.DLX_package.all;
use ieee.numeric_std.all;

entity tb_arbiter is
end tb_arbiter;

architecture test of tb_arbiter is
  component interrupt_arbiter IS
    generic( 	N               : integer);
       port(	rst							: IN  std_logic;
              interrupt_in    : IN  std_logic_vector(N-1 downto 0);
              ack_cu					: IN 	std_logic;
              interrupt_code  : OUT irqCode;
              ack_out					: OUT std_logic_vector(N-1 downto 0);
              handshake       : OUT std_logic
           );
  end component;

  constant N  : integer := 8;

  signal rst_s        : std_logic;
  signal irq_in       : std_logic_vector(N-1 downto 0);
  signal ack_cu       : std_logic;

  signal irq_code_s   : irqCode;
  signal ack_out_s    : std_logic_vector(N-1 downto 0);
  signal handshake_s  : std_logic;

begin  -- test

  DUT: interrupt_arbiter
    generic map (N)
    port map (rst_s, irq_in, ack_cu, irq_code_s, ack_out_s, handshake_s);


  input_gen: process
    begin
      rst_s   <= '0';
      irq_in  <= (others => '0');
      ack_cu  <= '0';
      wait for 4 ns;
      rst_s   <= '1';
      wait for 4 ns;
      irq_in  <= "00010100";
      ack_cu  <= '0';
      wait for 4 ns;
      ack_cu  <= '1';
      wait for 4 ns;
      irq_in  <= "10010100";
      ack_cu  <= '1';
      wait for 4 ns;
      irq_in  <= "10000100";
      ack_cu  <= '1';
      wait for 1 ns;
      ack_cu  <= '0';
      wait for 4 ns;
      irq_in  <= "10000100";
      ack_cu  <= '1';

      wait;
  end process;


end test;
