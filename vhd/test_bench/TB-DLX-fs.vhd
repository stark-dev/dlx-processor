library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

entity tb_dlx_fs is
end entity;

architecture TEST of tb_dlx_fs is
-- component declaration
  component DLX
    port (
      Clk                 : in  std_logic;
      Rst                 : in  std_logic;                -- Active Low
      Irq_line            : in  std_logic_vector (7 downto 0);
      Dram_out            : in  std_logic_vector (Nbit-1 downto 0);
      Iram_out            : in  std_logic_vector (Nbit-1 downto 0);
      Iram_en             : out std_logic;
      Dram_cs             : out std_logic;
      Dram_r_w            : out std_logic_vector(1 downto 0);
      Dram_in             : out std_logic_vector (Nbit-1 downto 0);
      Dram_addr           : out std_logic_vector (Nbit-1 downto 0);
      Iram_in             : out std_logic_vector (Nbit-1 downto 0));
  end component;

  -- signals
  signal clk_s          : std_logic := '0';
  signal rst_s          : std_logic;
  signal Irq_line_s     : std_logic_vector(7 downto 0);
  signal Dram_in_s      : std_logic_vector(Nbit-1 downto 0);
  signal Dram_out_s     : std_logic_vector(Nbit-1 downto 0);
  signal Dram_addr_s    : std_logic_vector(Nbit-1 downto 0);
  signal Dram_cs_s      : std_logic;
  signal Dram_r_w_s     : std_logic_vector(1 downto 0);
  signal Dram_wr_byte_s : std_logic;
  signal Iram_en_s      : std_logic;
  signal Iram_in_s      : std_logic_vector(Nbit-1 downto 0);
  signal Iram_out_s     : std_logic_vector(Nbit-1 downto 0);

  type RAMtype is array (0 to 255) of std_logic_vector(31 downto 0);
  signal iram : RAMtype := (others => (others => '0'));

begin
-- instance of DLX
	DUT: DLX
      port map (
      Clk           => clk_s,
      Rst           => rst_s,
      Irq_line      => Irq_line_s,
      Dram_out      => Dram_out_s,
      Iram_out      => Iram_out_s,
      Iram_en       => Iram_en_s,
      Dram_cs       => Dram_cs_s,
      Dram_r_w      => Dram_r_w_s,
      Dram_in       => Dram_in_s,
      Dram_addr     => Dram_addr_s,
      Iram_in       => Iram_in_s
      );

  clk_s <= not(clk_s) after 1 ns;
  rst_s <= '0', '1' after 2 ns;

  Irq_line_s <= (others => '0');

  Iram_out_s <= iram(to_integer(unsigned(Iram_in_s(31 downto 2))));
  Dram_out_s <= std_logic_vector(to_unsigned(16#00000002#, Dram_out_s'length));

  iram_reset_s : process(rst_s)
  begin
      if(rst_s = '0') then
         iram(0) <= std_logic_vector(to_signed(16#20010003#, Iram_out_s'length)); --addi r1,r0,#3
         iram(1) <= std_logic_vector(to_signed(16#8c030000#, Iram_out_s'length)); --lw r3,0(r0)
         iram(2) <= std_logic_vector(to_signed(16#20020001#, Iram_out_s'length)); --addi r2,r0,#1
         iram(3) <= std_logic_vector(to_signed(16#28210001#, Iram_out_s'length)); --label:  subi r1,r1,#1
         iram(4) <= std_logic_vector(to_signed(16#00431004#, Iram_out_s'length)); --sll r2,r2,r3
         iram(5) <= std_logic_vector(to_signed(16#54000000#, Iram_out_s'length)); --nop
         iram(6) <= std_logic_vector(to_signed(16#54000000#, Iram_out_s'length)); --nop
         iram(7) <= std_logic_vector(to_signed(16#0022202c#, Iram_out_s'length)); --sle r4,r1,r2
         iram(8) <= std_logic_vector(to_signed(16#1420ffe8#, Iram_out_s'length)); --bnez r1, label
         iram(9) <= std_logic_vector(to_signed(16#ac020000#, Iram_out_s'length)); --lw sw 0(r0),r2
     end if;
  end process;

end architecture;
