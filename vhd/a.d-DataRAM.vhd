library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.DLX_package.all;

ENTITY DataRam IS
  GENERIC(
      FILE_PATH      : string  := "dump.mem";   -- DRAM output data file
      FILE_PATH_INIT : string  := "data.mem";   -- DRAM initialization data file
      WORD_SIZE      : integer := 32);          -- Number of bits per word
  PORT(  RESET       : IN std_logic;
         Clk         : IN std_logic;
         Address     : IN std_logic_vector(up_int_log2(DRAM_DEPTH+IRAM_DEPTH)-1 DOWNTO 0);
         CS          : IN std_logic;
         RD_WR       : IN std_logic_vector(1 downto 0); -- 00 -> read; 01 -> write word; 10 -> write half w; 11 -> write byte
         Data_in     : IN std_logic_vector(WORD_SIZE-1 DOWNTO 0);
         Data_out    : OUT std_logic_vector(WORD_SIZE-1 DOWNTO 0));
END DataRam;

ARCHITECTURE Behavioral OF DataRam IS

  Type ram_array IS array (IRAM_DEPTH*4 To DRAM_DEPTH-1) OF std_logic_vector(7 DOWNTO 0);
	signal mem         :   ram_array;

BEGIN

	write_pr : process( RESET, Clk) is
	file mem_fp: text;
	file mem_fp_init: text;
	variable index : integer := 0;
   variable file_line : line;
   variable tmp_data_u : std_logic_vector(7 downto 0);
	begin
	   if (RESET = '0') then
        file_open(mem_fp_init, FILE_PATH_INIT, READ_MODE);
        index := IRAM_DEPTH*4;
        while (not endfile(mem_fp_init)) loop
          readline(mem_fp_init,file_line);
          hread(file_line,tmp_data_u);
          mem(index) <= tmp_data_u;
          index := index + 1;
        end loop;
        file_close(mem_fp_init);
      elsif Clk'event and Clk='0' then
        if( CS = '1') then
          if RD_WR = "01" then -- write word
            for i in 0 to (WORD_SIZE/8)-1 loop
              mem(to_integer(unsigned(Address)+(WORD_SIZE/8)-1-i)) <= Data_in((i+1)*8-1 downto i*8);
            end loop;
          elsif RD_WR = "10" then -- write half word
            for i in 0 to (WORD_SIZE/16)-1 loop
              mem(to_integer(unsigned(Address)+(WORD_SIZE/16)-1-i)) <= Data_in((i+1)*8-1 downto i*8);
            end loop;
          elsif RD_WR = "11" then -- write byte
            mem(to_integer(unsigned(Address))) <= Data_in(7 downto 0);
          end if;
        end if;
      end if;
		file_open(mem_fp, FILE_PATH, WRITE_MODE);
      for i in IRAM_DEPTH*4 to DRAM_DEPTH -1 loop
        tmp_data_u := mem(i);
        hwrite(file_line,tmp_data_u);
        writeline(mem_fp, file_line);
      end loop;
      file_close(mem_fp);
	end process;

	read_pr : process(RESET, Clk) is
	begin
    if (RESET = '1') then
      if Clk'event and Clk='0' then
        if CS = '1' and RD_WR = "00" then
          for i in 0 to (WORD_SIZE/8)-1 loop
            Data_out((i+1)*8-1 downto i*8) <= mem(to_integer(unsigned(Address)+(WORD_SIZE/8)-1-i));
          end loop;
        end if;
      end if;
    end if;

  end process;

END ARCHITECTURE;
