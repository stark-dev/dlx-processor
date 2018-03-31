library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

ENTITY TB_DLX_DP IS
END ENTITY;

ARCHITECTURE test OF TB_DLX_DP IS

	constant MICROCODE_MEM_SIZE : integer := 64;
	constant FUNC_SIZE : integer := 11;
	constant OP_CODE_SIZE : integer := 6;
	constant IR_SIZE : integer := 32;
	constant CW_SIZE : integer := 16;

	signal Clk           : std_logic := '0';
	signal Rst_n         : std_logic;
	signal Control_word_s : std_logic_vector(CW_SIZE -1 downto 0);
	signal Alu_op_s      : aluOp;
	signal Branch_op_s   : branchOp;
	signal Branch_out_s  : std_logic;

  signal Iram_in_s     : std_logic_vector(Nbit-1 downto 0);
  signal Iram_out_s    : std_logic_vector(Nbit-1 downto 0);
  signal Dram_add_s    : std_logic_vector(Nbit-1 downto 0);
  signal Dram_in_s     : std_logic_vector(Nbit-1 downto 0);
  signal Dram_out_s    : std_logic_vector(Nbit-1 downto 0);

  signal  Fetch_en_s        : std_logic;
  signal  Decode_en_s       : std_logic;
  signal  Execution_en_s    : std_logic;
  signal  Memory_en_s       : std_logic;
  signal  Writeback_en_s    : std_logic;

  COMPONENT DataPath IS
    PORT ( Clk       : IN std_logic;
		Rst             : IN std_logic;
      RF_EN           : IN std_logic;
      RF_RD1          : IN std_logic;
      RF_RD2          : IN std_logic;
      RF_WE           : IN std_logic;
     WR_MUX_SEL      : IN std_logic_vector(1 downto 0);  --Destination Register mux select
      WB_MUX_SEL      : IN std_logic;
  
     MUX_JUMP_SEL    : IN std_logic;
      MUX_A_SEL       : IN std_logic_vector(2 downto 0);
      MUX_B_SEL       : IN std_logic_vector(2 downto 0);
  
      ALU_OPCODE      : IN aluOp;
      BRANCH_OP       : IN branchOp;
  
     BRANCH_OUT      : OUT std_logic;
  
  
      IRAM_in	       : OUT std_logic_vector(Nbit-1 downto 0);
      IRAM_out	       : IN  std_logic_vector(Nbit-1 downto 0);
      DRAM_ADDRESS    : OUT std_logic_vector(Nbit-1 downto 0);
      DRAM_in         : OUT std_logic_vector(Nbit-1 downto 0);
      DRAM_out        : IN  std_logic_vector(Nbit-1 downto 0);
  
      FETCH_EN        : IN std_logic;
      DECODE_EN       : IN std_logic;
      EXECUTION_EN    : IN std_logic;
      MEMORY_EN       : IN std_logic;
      WRITEBACK_EN    : IN std_logic);
  END COMPONENT;


BEGIN

  DUT : DataPath
    port map( Clk,
              Rst_n,
              Control_word_s(15),
              Control_word_s(14),
              Control_word_s(13),
              Control_word_s(1),
              Control_word_s(12 downto 11),
              Control_word_s(0),
              Control_word_s(10),
              Control_word_s(9 downto 7),
              Control_word_s(6 downto 4),
              Alu_op_s,
              Branch_op_s,
              Branch_out_s,
              Iram_in_s,
              Iram_out_s,
              Dram_add_s,
              Dram_in_s,
              Dram_out_s,
              Fetch_en_s,
              Decode_en_s,
              Execution_en_s,
              Memory_en_s,
              Writeback_en_s);

	Rst_n <= '0', '1' after 1.2 ns;
	Clk <= not(Clk) after 1 ns;

  

  Fetch_en_s      <= '1';
  Decode_en_s     <= '1';
  Execution_en_s  <= '1';
  Memory_en_s     <= '1';
  Writeback_en_s  <= '1';
  
--  Control_word_s <= "1110111000001111";   --r type
--  Control_word_s <= "1100011000011111";   --i-type
--  Control_word_s <= "1100011000011110";   --lw
--  Control_word_s <= "1110011000011001";   --sw
--  Control_word_s <= "1100011000001101";   --beqz/bnez
--  Control_word_s <= "1000001000001101";   --j
  Control_word_s <= "1001000111011111";   --jal
--  Control_word_s <= "1110111000001111";   --nop

--  Alu_op_s <= NOP_OP;
  Alu_op_s <= ADD_OP;
--  Alu_op_s <= SUB_OP;
--  Alu_op_s <= AND_OP;
--  Alu_op_s <= OR_OP;
--  Alu_op_s <= XOR_OP;
--  Alu_op_s <= SGE_OP;
--  Alu_op_s <= SLE_OP;
--  Alu_op_s <= SLL_OP;
--  Alu_op_s <= SNE_OP;
--  Alu_op_s <= SRL_OP;

--  Branch_op_s <= NOBRANCH;
--  Branch_op_s <= BNEZ;
--  Branch_op_s <= BEQZ;
--  Branch_op_s <= J;
  Branch_op_s <= JAL;
  
  Dram_out_s <= (others => '0');
--  Iram_out_s <= std_logic_vector(to_signed(16#01491020#, Iram_out_s'length));  --add r2,r10,r9
--  Iram_out_s <= std_logic_vector(to_signed(16#200a0001#, Iram_out_s'length));  --addi r10,r0,#1
--  Iram_out_s <= std_logic_vector(to_signed(16#012a4824#, Iram_out_s'length));  --and r9,r9,r10
--  Iram_out_s <= std_logic_vector(to_signed(16#31340008#, Iram_out_s'length));  --andi r20,r9,#8
--  Iram_out_s <= std_logic_vector(to_signed(16#8d490002#, Iram_out_s'length));  --lw r9, 2(r10)
--  Iram_out_s <= std_logic_vector(to_signed(16#ad2a0002#, Iram_out_s'length));  --sw 2(r9), r10
--  Iram_out_s <= std_logic_vector(to_signed(16#54000000#, Iram_out_s'length));  --nop
--  Iram_out_s <= std_logic_vector(to_unsigned(16#012a4825#, Iram_out_s'length));  --or r9,r9,r10
--  Iram_out_s <= std_logic_vector(to_unsigned(16#352900ff#, Iram_out_s'length));  --ori r9,r9,#255
--  Iram_out_s <= std_logic_vector(to_unsigned(16#012a4804#, Iram_out_s'length));  --sll r9,r9,r10
--  Iram_out_s <= std_logic_vector(to_unsigned(16#51290002#, Iram_out_s'length));  --slli r9,r9,#2
--  Iram_out_s <= std_logic_vector(to_unsigned(16#012a082c#, Iram_out_s'length));  --sle r1,r9,r10
--  Iram_out_s <= std_logic_vector(to_unsigned(16#71220002#, Iram_out_s'length));  --slei r2,r9,#2
--  Iram_out_s <= std_logic_vector(to_unsigned(16#0bffffd4#, Iram_out_s'length));  -- j lab
  Iram_out_s <= std_logic_vector(to_unsigned(16#0c000008#, Iram_out_s'length));  --jal lab
--  Iram_out_s <= std_logic_vector(to_unsigned(16#1020000c#, Iram_out_s'length));  --beqz r1, lab
--  Iram_out_s <= std_logic_vector(to_unsigned(16#1420ffd0#, Iram_out_s'length));  --bnez r1, lab



END ARCHITECTURE;
