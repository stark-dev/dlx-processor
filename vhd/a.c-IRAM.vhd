library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.DLX_package.all;


-- Instruction memory for DLX
-- Memory filled by a process which reads from a file
-- file name is "test.asm.mem"
entity IRAM is
  generic (
    FILE_PATH  : string  := "iram.mem"); -- IRAM data file
  port (
    Rst        : in  std_logic;
    Addr       : in  std_logic_vector(Nbit - 1 downto 0);
    Enable     : in  std_logic;
    Dout       : out std_logic_vector(Nbit - 1 downto 0)
    );

end IRAM;



architecture IRam_Bhe of IRAM is

  type RAMtype is array (0 to IRAM_DEPTH - 1) of std_logic_vector(Nbit - 1 downto 0);

  signal IRAM_mem : RAMtype;

begin  -- IRam_Bhe


  -- purpose: This process is in charge of filling the Instruction RAM with the firmware
  -- type   : combinational
  -- inputs : Rst
  -- outputs: IRAM_mem
  FILL_MEM_P: process (Rst)
    file mem_fp: text;
    variable file_line : line;
    variable index : integer := 0;
    variable tmp_data_u : std_logic_vector(Nbit-1 downto 0);
  begin  -- process FILL_MEM_P
    if (Rst = '0') then
      file_open(mem_fp, FILE_PATH, READ_MODE);
      while (not endfile(mem_fp) and index < IRAM_DEPTH) loop
        readline(mem_fp,file_line);
        hread(file_line,tmp_data_u);
        IRAM_mem(index) <= tmp_data_u;
        index := index + 1;
      end loop;
    end if;
  end process FILL_MEM_P;

  READ_MEM_P: process(Rst, Enable, Addr)
  BEGIN
    if Rst = '0' then
      Dout <= (others => '0');
    elsif Enable = '1' then
      Dout <= IRAM_mem(to_integer(unsigned(Addr(Nbit-1 downto 2))));
    end if;
  end process;

end IRam_Bhe;
