library IEEE;

use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use WORK.DLX_package.all;

entity tb_iram is
end tb_iram;

architecture TEST of tb_iram is
--constants
  constant FILE_PATH : string  := "test.bin.mem";
  constant RAM_DEPTH : integer := 48;
  constant I_SIZE    : integer := Nbit; 
--signals
  signal t_reset : std_logic;
  signal t_addr : std_logic_vector(I_SIZE - 1 downto 0);
  signal t_enable : std_logic;
  signal t_data_out : std_logic_vector(I_SIZE - 1 downto 0);

--components instantiation  
  component IRAM is
  generic (
    FILE_PATH  : string  := "test.asm.mem"; -- IRAM data file
    RAM_DEPTH  : integer := 48;             -- Number of lines in the IRAM
    I_SIZE     : integer := Nbit);           -- Number of bits per word
  port (
    Rst        : in  std_logic;
    Addr       : in  std_logic_vector(I_SIZE - 1 downto 0);
    Enable     : in  std_logic;
    Dout       : out std_logic_vector(I_SIZE - 1 downto 0));

  end component;

begin
  DUT : IRAM
    generic map(FILE_PATH, RAM_DEPTH, I_SIZE)
    port map(t_reset, t_addr, t_enable, t_data_out);

  t_reset <= '0', '1' after 2 ns;
  t_enable <= '1';
  
  addr_gen : process
  begin
      t_addr <= ( others => '0');
      wait for 4 ns;
      for i in 0 to RAM_DEPTH-1 loop
         t_addr <= std_logic_vector(unsigned(t_addr) + 1);
         wait for 2 ns;
      end loop;
      wait;
  end process;

end architecture;
