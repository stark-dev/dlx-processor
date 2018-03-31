library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

entity tb_dram is
end tb_dram;

architecture TEST of tb_dram is
--constants
  constant FILE_PATH : string := "dump.mem";
  constant FILE_PATH_INIT : string := "in.mem";
  constant RAM_DEPTH : integer := 128;
  constant WORD_SIZE : integer := Nbit;
--signals
  signal t_reset : std_logic := '0';
  signal t_addr : std_logic_vector(up_int_log2(RAM_DEPTH)-1 downto 0);
  signal t_cs : std_logic := '0';
  signal t_rd_wr : std_logic_vector(1 downto 0);
  signal t_data_in : std_logic_vector(Nbit - 1 downto 0);
  signal t_data_out : std_logic_vector(Nbit - 1 downto 0);
  
--time delay
  signal delay_time : time := (2+2*(RAM_DEPTH-1)) * 1 ns;
  
--components instantiation
  component DataRam IS
  GENERIC(
    FILE_PATH      : string  := "dump.mem";   -- DRAM output data file
    FILE_PATH_INIT : string  := "in.mem";     -- DRAM initialization data file
    RAM_DEPTH      : natural := 128;          -- Number of lines in the DRAM
    WORD_SIZE      : integer := 32);          -- Number of bits per word
  PORT(  RESET       : IN std_logic;
         Address     : IN std_logic_vector(up_int_log2(RAM_DEPTH)-1 DOWNTO 0);
         CS          : IN std_logic;
         RD_WR       : IN std_logic_vector(1 downto 0); -- 00 -> read; 01 -> write word; 10 -> write half w; 11 -> write byte
         Data_in     : IN std_logic_vector(WORD_SIZE-1 DOWNTO 0);
         Data_out    : OUT std_logic_vector(WORD_SIZE-1 DOWNTO 0));
  END component;



begin
  DUT : DataRam
    generic map(FILE_PATH, FILE_PATH_INIT, RAM_DEPTH, WORD_SIZE)
    port map(t_reset, t_addr, t_cs, t_rd_wr, t_data_in, t_data_out);

  t_reset <= '0', '1' after 2 ns;
  t_cs <= '1';
  t_rd_wr <= "00", "01" after 400 ns;--, "10" after delay_time  + 2 ns, "11" after delay_time + 4 ns;
  t_data_in <= (others => '1');

  addr_gen : process
  begin
      t_addr <= ( others => '0');

      wait for 4 ns;
      for i in 0 to RAM_DEPTH-1 loop
         t_addr <= std_logic_vector(unsigned(t_addr) + 1);
         wait for 2 ns;
      end loop;
      t_addr <= ( others => '0');
      wait for 2 ns;
      --t_addr <= std_logic_vector(to_unsigned(1,t_addr'length));
      wait for 2 ns;
      --t_addr <= std_logic_vector(to_unsigned(2,t_addr'length));
      wait;
  end process;

end architecture;
