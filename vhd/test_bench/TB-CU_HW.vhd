library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

ENTITY TB_DLX_CU IS
END ENTITY;

ARCHITECTURE test OF TB_DLX_CU IS

	constant MICROCODE_MEM_SIZE : integer := 64;
	constant FUNC_SIZE : integer := 11;
	constant OP_CODE_SIZE : integer := 6;
	constant IR_SIZE : integer := 32;
	constant CW_SIZE : integer := 16;

	signal Clk : std_logic := '0';
	signal Rst_n : std_logic;
	signal IR_IN : std_logic_vector(IR_SIZE-1 downto 0);
	signal IRAM_EN : std_logic;
	signal RF_EN : std_logic;
	signal RF_RD1 : std_logic;
	signal RF_RD2 : std_logic;
	signal WR_MUX_SEL : std_logic_vector(1 downto 0);
	signal MUX_JUMP_SEL : std_logic;
	signal MUXA_SEL : std_logic_vector(2 downto 0);
	signal MUXB_SEL : std_logic_vector(2 downto 0);
	signal ALU_OP : aluOp;
	signal BRANCH_OP : branchOp;
	signal DRAM_CS : std_logic;
	signal DRAM_R_Wn : std_logic;
	signal WB_MUX_SEL : std_logic;
	signal RF_WE : std_logic;

        signal FETCH_EN : std_logic;
        signal DECODE_EN : std_logic;
        signal EXECUTION_EN : std_logic;
        signal MEMORY_EN : std_logic;
        signal WRITEBACK_EN : std_logic;

	signal branch_detected : std_logic;

	component dlx_cu 
  generic (
    MICROCODE_MEM_SIZE :     integer := 64;  -- Microcode Memory Size
    FUNC_SIZE          :     integer := 11;  -- Func Field Size for R-Type Ops
    OP_CODE_SIZE       :     integer := 6;  -- Op Code Size
    -- ALU_OPC_SIZE       :     integer := 6;  -- ALU Op Code Word Size
    IR_SIZE            :     integer := 32;  -- Instruction Register Size
    CW_SIZE            :     integer := 16);  -- Control Word Size
  port (
    Clk                : in  std_logic;  -- Clock
    Rst                : in  std_logic;  -- Reset:Active-Low
    -- Instruction Register
    IR_IN              : in  std_logic_vector(IR_SIZE - 1 downto 0);
    BRANCH_DETECTED    : in std_logic;


    IRAM_EN            : out std_logic;

    -- IF Control Signal
    RF_EN              : out std_logic;  -- Register file Enable
    RF_RD1             : out std_logic;  -- Register file read 1 Enable
    RF_RD2             : out std_logic;  -- Register file read 2 Enable
    WR_MUX_SEL         : out std_logic_vector(1 downto 0);  -- write address MUX
    MUX_JUMP_SEL       : out std_logic;


    MUXA_SEL           : out std_logic_vector(2 downto 0);  -- MUX-A Sel
    MUXB_SEL           : out std_logic_vector(2 downto 0);  -- MUX-B Sel
    ALU_OP             : out aluOp;
    BRANCH_OP          : out branchOp;

    DRAM_CS            : out std_logic;
    DRAM_R_Wn          : out std_logic;

    WB_MUX_SEL         : out std_logic;  -- Write Back MUX Sel
    RF_WE              : out std_logic;  -- Register File Write Enable

    FETCH_EN           : out std_logic;
    DECODE_EN          : out std_logic;
    EXECUTION_EN       : out std_logic;
    MEMORY_EN          : out std_logic;
    WRITEBACK_EN       : out std_logic);
	end component;
	

BEGIN

	Rst_n <= '0', '1' after 1.2 ns;
	Clk <= not(Clk) after 1 ns;

	DUT : dlx_cu
		generic map(MICROCODE_MEM_SIZE, FUNC_SIZE, OP_CODE_SIZE, IR_SIZE ,CW_SIZE)
		port map(Clk, Rst_n, IR_IN, branch_detected, IRAM_EN, RF_EN, RF_RD1, RF_RD2, WR_MUX_SEL, MUX_JUMP_SEL, MUXA_SEL, MUXB_SEL,
			 ALU_OP, BRANCH_OP, DRAM_CS, DRAM_R_Wn, WB_MUX_SEL, RF_WE, FETCH_EN, DECODE_EN, EXECUTION_EN,
			 MEMORY_EN, WRITEBACK_EN);

	IR_IN <= "10001100010000110000000000000100", "00000000001000110010100000000100" after 5.4 ns;
	branch_detected <= '0';--'1' after 5.4 ns;


END ARCHITECTURE;
