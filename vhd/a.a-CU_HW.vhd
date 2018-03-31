library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

entity dlx_cu is
  port (
    Clk                : in  std_logic;  -- Clock
    Rst                : in  std_logic;  -- Reset:Active-Low
    DBG                : IN std_logic;  -- debug port input
    CRASH              : out std_logic;  -- Disaster pin

    -- enable signals
    FETCH_EN           : OUT std_logic;
    DECODE_EN          : OUT std_logic;
    EXECUTION_EN       : OUT std_logic;
    E_INT_EN           : OUT std_logic;
    E_MUL_EN           : OUT std_logic_vector(1 to MULT_PIPE_LENGTH);
    E_ADD_EN           : OUT std_logic_vector(1 to FP_ADD_PIPE_LENGTH);
    MEMORY_EN          : OUT std_logic;
    WRITEBACK_EN       : OUT std_logic;

    -- PC
    PC                 : in  std_logic_vector(Nbit-1 downto 0);
    -- Instruction Register
    IR_IN              : in std_logic_vector(Nbit-1 downto 0); -- Input to IR
    IR_d               : in std_logic_vector(Nbit-1 downto 0); -- IR output
    IR_e               : in std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX stage)
    IR_E1_MUL          : in std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX first stage mult)
    IR_E2_MUL          : in std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX second stage mult)
    IR_E3_MUL          : in std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX third stage mult)
    IR_E1_ADD          : in std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX first stage add)
    IR_E2_ADD          : in std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX second stage add)
    IR_E3_ADD          : in std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX third stage add)
    IR_E4_ADD          : in std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX fourth stage add)
    IR_m               : in std_logic_vector(Nbit-1 downto 0); -- IR output delayed (MEM stage)

    IR_CLEAR_D         : out std_logic;  -- Clear to decode stage
    IR_CLEAR_E         : out std_logic;  -- Clear to exec stage
    IR_CLEAR_M         : out std_logic;  -- Clear to memory stage
    IR_CLEAR_W         : out std_logic;  -- Clear to writeback stage
    IR_CLEAR_EX_INT    : out std_logic;  -- Reset to execution IR register
    IR_CLEAR_EX_MUL    : out std_logic;  -- Reset to first mul execution IR Register
    IR_CLEAR_EX_ADD    : out std_logic;  -- Reset to first add execution IR Register

    ALU_OUT_SEL        : out std_logic_vector(1 downto 0); -- It selects the correct execution unit to be connected to memory stage

    -- muxes
    IR_MUX_SEL         : out std_logic_vector(1 downto 0); --IR Mux input
    SR_MUX_SEL         : out std_logic;
    BRANCH_DETECTED    : in  std_logic;
    JUMP_MUX_SEL       : out std_logic_vector(2 downto 0);

    -- forwarding muxes
    BR_FWD_MUX_SEL     : OUT std_logic_vector(1 downto 0);  --branch forwarding
    ST_FWD_MUX_SEL     : OUT std_logic_vector(2 downto 0);  --stall forwarding

    -- control signals
    -- stage 1
    FP_INTn_RD1        : out std_logic;
    FP_INTn_RD2        : out std_logic;
    RF_EN              : out std_logic;  -- Register file Enable
    MUX_IMM_SEL        : out std_logic;
    -- stage 2
    MUXA_SEL           : out std_logic_vector(2 downto 0);  -- MUX-A Sel
    MUXB_SEL           : out std_logic_vector(2 downto 0);  -- MUX-B Sel
    PUSH_POP_MUX_SEL   : out std_logic;
    -- stage 3
    DRAM_CS            : out std_logic;
    DRAM_R_W           : out std_logic_vector(1 downto 0);
    LOAD_MUX_SEL       : out std_logic_vector(2 downto 0);
    WR_MUX_SEL         : out std_logic_vector(1 downto 0);  -- write address MUX
    -- stage 4
    RF_WE              : out std_logic;  -- Register File Write Enable
    FP_INTn_WR         : out std_logic;
    WB_MUX_SEL         : out std_logic;  -- Write Back MUX Sel
    RF_WE_SP           : out std_logic;  -- Register File address 29 Write Enable

    -- opcodes
    ALU_OP             : out aluOp;
    BRANCH_OP          : out branchOp;

    -- RF signals
    RF_WE_SR           : out std_logic;  -- Register File address 25 Write Enable

    -- ALU overflow/underflow
    ALU_OVF            : IN  std_logic;
    ALU_UFL            : IN  std_logic;
    ALU_INVALID_CONV   : IN  std_logic;
    ALU_CARRY          : IN  std_logic;
    ALU_ZERO           : IN  std_logic;

    -- exception handling
    EPC_EN             : OUT std_logic;     -- exception program counter en
    ECP_CODE           : OUT exceptionCode; -- exception code to select jump address
    IRQ_CODE           : OUT irqCode;       -- irq code to select jump address

    -- control and status registers
    CR_REG_OUT         : IN std_logic_vector(Nbit-1 downto 0);
    SR_REG_OUT         : IN std_logic_vector(Nbit-1 downto 0);
    SR_REG_IN          : OUT std_logic_vector(Nbit-1 downto 0);

    -- interrupt
    INTERRUPT_LINE     : IN  std_logic_vector(7 downto 0);
    ACK_LINE           : OUT std_logic_vector(7 downto 0);

    -- ram signals
    IRAM_EN            : out std_logic;
    DRAM_ADDRESS       : IN std_logic_vector(Nbit-1 downto 0);

    -- DMA
    SPILL              : IN  std_logic;
    FILL               : IN  std_logic;
    CALL               : OUT std_logic;
    RET                : OUT std_logic;
    CALL_ROLLBACK      : OUT std_logic;
    RET_ROLLBACK       : OUT std_logic;
    CWP_ENABLE         : OUT std_logic
    );
end dlx_cu;

ARCHITECTURE dlx_cu_hw OF dlx_cu IS

  -----------------------------------------------------------
  -- constants
  -----------------------------------------------------------

  constant NOP_INDEX           : natural := 21;
  constant NULL_INDEX          : natural := 63;

  constant CW_2_SIZE           : natural := CW_SIZE - 3;
  constant CW_3_SIZE           : natural := CW_SIZE - 10;
  constant CW_4_SIZE           : natural := CW_SIZE - 18;

  subtype CW_1_RANGE is natural range (CW_SIZE -1) downto 0;
  subtype CW_2_RANGE is natural range (CW_2_SIZE -1) downto 0;
  subtype CW_3_RANGE is natural range (CW_3_SIZE -1) downto 0;
  subtype CW_4_RANGE is natural range (CW_4_SIZE -1) downto 0;

  constant FP_INTn_RD1_ID      : natural := CW_SIZE - 1;
  constant FP_INTn_RD2_ID      : natural := CW_SIZE - 2;
  constant MUX_IMM_SEL_ID      : natural := CW_SIZE - 3;

  subtype  MUXA_SEL_ID         is natural range (CW_SIZE - 4) downto (CW_SIZE - 6);
  subtype  MUXB_SEL_ID         is natural range (CW_SIZE - 7) downto (CW_SIZE - 9);

  constant PUSH_POP_MUX_SEL_ID : natural := CW_SIZE - 10;
  constant DRAM_CS_ID          : natural := CW_SIZE - 11;
  subtype  DRAM_R_W_ID         is natural range (CW_SIZE - 12) downto (CW_SIZE - 13);
  subtype  LOAD_MUX_SEL_ID     is natural range (CW_SIZE - 14) downto (CW_SIZE - 16);
  subtype  WR_MUX_SEL_ID       is natural range (CW_SIZE - 17) downto (CW_SIZE - 18);

  constant RF_WE_ID            : natural := CW_SIZE - 19;
  constant FP_INTn_WR_ID       : natural := CW_SIZE - 20;
  constant WB_MUX_SEL_ID       : natural := CW_SIZE - 21;
  constant RF_WE_SP_ID         : natural := CW_SIZE - 22;

  -----------------------------------------------------------
  -- memories
  -----------------------------------------------------------

  type mem_array is array (integer range 0 to MICROCODE_MEM_SIZE - 1) of std_logic_vector(CW_SIZE - 1 downto 0);
  constant cw_mem : mem_array := ("0011000000000000011010", -- R type (0x00)
                                  "1111000000000000011110", -- F type (0x01)
                                  "0001000000000000000010", -- J (0x02)
                                  "0000111010000000101010", -- JAL
                                  "0011000000000000000010", -- BEQZ
                                  "0011000000000000000010", -- BNEZ
                                  "0011000000000000010010", -- BFPT, NOT IMPLEMENTED
                                  "0011000000000000010010", -- BFPF, NOT IMPLEMENTED
                                  "0011000010000000001010", -- ADDI  (0x08)
                                  "0011000010000000001010", -- ADDUI, NOT IMPLEMENTED
                                  "0011000010000000001010", -- SUBI  (0x0A)
                                  "0011000010000000001010", -- SUBUI, NOT IMPLEMENTED
                                  "0011000010000000001010", -- ANDI  (0x0C)
                                  "0011000010000000001010", -- ORI   (0x0D)
                                  "0011000010000000001010", -- XORI  (0x0E)
                                  "0011000010000000001010", -- LHI (0x0F)
                                  "0011000000000000010010", -- RFE (0x10)
                                  "0011000000000000010010", -- TRAP, NOT IMPLEMENTED
                                  "0001000000000000000010", -- JR (0x12)
                                  "0010111010000000101010", -- JALR (0x13)
                                  "0011000010000000001010", -- SLLI  (0X14)
                                  "0011000000000000010010", -- NOP   (0X15)
                                  "0011000010000000001010", -- SRLI  (0X16)
                                  "0011000010000000001010", -- SRAI (0x17)
                                  "0011000010000000001010", -- SEQI (0x18)
                                  "0011000010000000001010", -- SNEI  (0X19)
                                  "0011000010000000001010", -- SLTI (0x1A)
                                  "0011000010000000001010", -- SGTI (0x1B)
                                  "0011000010000000001010", -- SLEI, (0X1C)
                                  "0011000010000000001010", -- SGEI  (0X1D)
                                  "0011000011101000010011", -- PUSH (0X1E)
                                  "0011000010100000001001", -- POP (0X1F)
                                  "0011000010100001001000", -- LB (0x20)
                                  "0011000010100011001000", -- LH (0x21)
                                  "0011000000000000010010", -- IT DOES NOT CORRESPOND TO ANYTHING (0X22)
                                  "0011000010100000001000", -- LW (0X23)
                                  "0011000010100010001000", -- LBU (0x24)
                                  "0011000010100100001000", -- LHU (0x25)
                                  "0011000010100000001100", -- LF, NOT IMPLEMENTED
                                  "0011000000000000010010", -- LD, NOT IMPLEMENTED
                                  "0011000010111000000010", -- SB (0x28)
                                  "0011000010110000000010", -- SH,(0x29)
                                  "0011000000000000010010", -- IT DOES NOT CORRESPOND TO ANYTHING (0X2A)
                                  "0011000010101000000010", -- SW (0X2B)
                                  "0111000011101000010011", -- PUSHF (0x2C)
                                  "0011000010100000001101", -- POPF (0x2D)
                                  "0111000010101000000010", -- SF, (0X2E)
                                  "0011000000000000010010", -- SD, NOT IMPLEMENTED(0X2F)
                                  "0000111010000000101010", -- CALL(0x30)
                                  "0001000000000000000010", -- RET(0x31)
                                  "1011000000000000001010", -- MOVFP2I(0x32)
                                  "0011000000000000001110", -- MOVI2FP(0x33)
                                  "1011000000000000001110", -- CVTF2I(0x34)
                                  "0011000000000000001010", -- CVTI2F(0x35)
                                  "0011000000000000010010", -- NOTHING
                                  "0011000000000000010010", -- NOTHING
                                  "0011000000000000010010", -- ITLB, NOT IMPLEMENTED (0X38)
                                  "0011000000000000010010", -- NOTHING
                                  "0011000010000000001010", -- SLTUI (0X3A)
                                  "0011000010000000001010", -- SGTUI (0X3B)
                                  "0011000010000000001010", -- SLEUI, NOT IMPLEMENTED (0X3C)
                                  "0011000010000000001010", -- SGEUI (0X3D)
                                  "0011000000000000010010", -- NOTHING
                                  "0011000000000000010010");-- NULL instruction (0x3F)

  type ecp_array is array (integer range 0 to 2**(ECP_SIZE)-1) of std_logic_vector(ECP_SIZE-1 downto 0);
  constant ecp_codes : ecp_array :=("00000",
                                    "00001",
                                    "00010",
                                    "00011",
                                    "00100",
                                    "00101",
                                    "00110",
                                    "00111",
                                    "01000",
                                    "01001",
                                    "01010",
                                    "01011",
                                    "01100",
                                    "01101",
                                    "01110",
                                    "01111",
                                    "10000",
                                    "10001",
                                    "10010",
                                    "10011",
                                    "10100",
                                    "10101",
                                    "10110",
                                    "10111",
                                    "11000",
                                    "11001",
                                    "11010",
                                    "11011",
                                    "11100",
                                    "11101",
                                    "11110",
                                    "11111");

  -----------------------------------------------------------
  -- OPCODE, ALU_OPCODE, BRANCH_OPCODE
  -----------------------------------------------------------

  -- IR
  signal IR_opcode : std_logic_vector(OPCODE_SIZE -1 downto 0);  -- OpCode part of IR
  signal IR_func : std_logic_vector(FUNC_SIZE-1 downto 0);   -- Func part of IR when Rtype

  -- ALU opcode
  signal aluOpcode_i: aluOp; -- ALUOP defined in package
  signal aluOpcode1: aluOp;
  signal aluOpcode2: aluOp;

  -- Branch opcode
  signal branchOpcode_i : branchOp;
  signal branchOpcode1  : branchOp;

  -----------------------------------------------------------
  -- control word
  -----------------------------------------------------------

  -- enable

  signal cw_2_int_en    : std_logic;

  signal cw_2_m1_en     : std_logic;
  signal cw_2_m2_en     : std_logic;
  signal cw_2_m3_en     : std_logic;

  signal cw_2_a1_en     : std_logic;
  signal cw_2_a2_en     : std_logic;
  signal cw_2_a3_en     : std_logic;
  signal cw_2_a4_en     : std_logic;

  -- cw reg out

  signal cw_1_out        : std_logic_vector(CW_1_RANGE);

  signal cw_2_int_out    : std_logic_vector(CW_2_RANGE);

  signal cw_2_m1_out     : std_logic_vector(CW_2_RANGE);
  signal cw_2_m2_out     : std_logic_vector(CW_2_RANGE);
  signal cw_2_m3_out     : std_logic_vector(CW_2_RANGE);

  signal cw_2_a1_out     : std_logic_vector(CW_2_RANGE);
  signal cw_2_a2_out     : std_logic_vector(CW_2_RANGE);
  signal cw_2_a3_out     : std_logic_vector(CW_2_RANGE);
  signal cw_2_a4_out     : std_logic_vector(CW_2_RANGE);

  signal cw_2_out        : std_logic_vector(CW_2_RANGE);

  signal cw2_mux_sel_s   : std_logic_vector(1 downto 0); -- It selects the correct cw2 to be connected to exec stage

  signal cw   : std_logic_vector(CW_1_RANGE); -- full control word read from cw_mem

  -- control word is shifted to the correct stage

  signal cw1 : std_logic_vector(CW_1_RANGE); -- first stage
  signal cw2 : std_logic_vector(CW_2_RANGE); -- second stage
  signal cw3 : std_logic_vector(CW_3_RANGE); -- third stage
  signal cw4 : std_logic_vector(CW_4_RANGE); -- fourth stage


  -----------------------------------------------------------
  -- MUXES
  -----------------------------------------------------------

  -- branch forwarding mux

  signal br_fwd_mux_sel1 : std_logic_vector(1 downto 0);

  -- store forwarding mux

  signal st_fwd_mux_sel1  : std_logic_vector(2 downto 0);
  signal st_fwd_mux_sel2  : std_logic_vector(2 downto 0);

  -- memory stage input mux

  signal alu_out_sel_s    : std_logic_vector(1 downto 0); -- It selects the correct execution unit to be connected to memory stage

  -----------------------------------------------------------
  -- pipe control
  -----------------------------------------------------------

  -- main pipe

  signal f_enable_s      : std_logic;
  signal d_enable_s      : std_logic;
  signal e_enable_s      : std_logic;
  signal m_enable_s      : std_logic;
  signal w_enable_s      : std_logic;

  signal e_int_en_s      : std_logic;
  signal e_mul_en_s      : std_logic_vector(1 to MULT_PIPE_LENGTH);
  signal e_add_en_s      : std_logic_vector(1 to FP_ADD_PIPE_LENGTH);

  -- branch

  signal branch_flush : std_logic;  -- 1 if a branch is detected -> requires fetch flush

  -- ecp pipe control

  signal f_ecp_enable_s       : std_logic;
  signal d_ecp_enable_s       : std_logic;
  signal e_ecp_int_enable_s   : std_logic;
  signal e_ecp_mul1_enable_s  : std_logic;
  signal e_ecp_mul2_enable_s  : std_logic;
  signal e_ecp_mul3_enable_s  : std_logic;
  signal e_ecp_add1_enable_s  : std_logic;
  signal e_ecp_add2_enable_s  : std_logic;
  signal e_ecp_add3_enable_s  : std_logic;
  signal e_ecp_add4_enable_s  : std_logic;
  signal m_ecp_enable_s       : std_logic;
  signal w_ecp_enable_s       : std_logic;

  signal ecp_flush_s          : std_logic; -- 1 if exception detected -> flush all pipe
  signal ecp_flush_sync_s     : std_logic;

  signal ecp_pipe_rst         : std_logic;

  signal irq_pipe_rst         : std_logic;

  signal ecp_lock_n           : std_logic;

  -- CALL/RET control

  signal call_s             : std_logic;
  signal ret_s              : std_logic;
  signal call_rollback_s    : std_logic;
  signal ret_rollback_s     : std_logic;
  signal cwp_enable_s       : std_logic;

  signal spill_delay_1      : std_logic;
  signal spill_delay_2      : std_logic;
  signal spill_delay_3      : std_logic;
  signal spill_delay_4      : std_logic;
  signal spill_delay_s      : std_logic;

  signal fill_delay_1       : std_logic;
  signal fill_delay_2       : std_logic;
  signal fill_delay_3       : std_logic;
  signal fill_delay_4       : std_logic;
  signal fill_delay_s       : std_logic;

  -- crash signal

  signal crash_s                 : std_logic;
  signal crash_sync              : std_logic;

  --debug mode signal

  signal dbg_step      : std_logic;

  -- Multiple Execution Units

  signal int_pipe : std_logic;
  signal mul_pipe : std_logic;
  signal add_pipe : std_logic;

  signal int_ex_clr   : std_logic;
  signal mul_ex_clr   : std_logic;
  signal add_ex_clr   : std_logic;

  signal f_clear_s    : std_logic;
  signal d_clear_s    : std_logic;
  signal e_clear_s    : std_logic;
  signal m_clear_s    : std_logic;
  signal w_clear_s    : std_logic;

  signal int_pipe_clr : std_logic;
  signal mul_pipe_clr : std_logic;
  signal add_pipe_clr : std_logic;

  signal mul_pipe_sync : std_logic;
  signal add_pipe_sync : std_logic;

  signal mul_stages             : std_logic_vector(1 to MULT_PIPE_LENGTH);
  signal add_stages             : std_logic_vector(1 to FP_ADD_PIPE_LENGTH);

  -----------------------------------------------------------
  -- exceptions
  -----------------------------------------------------------

  -- exceptions registers

  signal ecp_cause_fd_in      : std_logic_vector(ECP_SIZE-1 downto 0);
  signal ecp_cause_fd_out     : std_logic_vector(ECP_SIZE-1 downto 0);
  signal ecp_cause_de_in      : std_logic_vector(ECP_SIZE-1 downto 0);

  signal ecp_cause_e_int_out  : std_logic_vector(ECP_SIZE-1 downto 0);

  signal ecp_cause_e1_mul_out : std_logic_vector(ECP_SIZE-1 downto 0);
  signal ecp_cause_e2_mul_out : std_logic_vector(ECP_SIZE-1 downto 0);
  signal ecp_cause_e3_mul_out : std_logic_vector(ECP_SIZE-1 downto 0);

  signal ecp_cause_e1_add_out : std_logic_vector(ECP_SIZE-1 downto 0);
  signal ecp_cause_e2_add_out : std_logic_vector(ECP_SIZE-1 downto 0);
  signal ecp_cause_e3_add_out : std_logic_vector(ECP_SIZE-1 downto 0);
  signal ecp_cause_e4_add_out : std_logic_vector(ECP_SIZE-1 downto 0);

  signal ecp_cause_de_out     : std_logic_vector(ECP_SIZE-1 downto 0);

  signal ecp_cause_em_in      : std_logic_vector(ECP_SIZE-1 downto 0);
  signal ecp_cause_em_out     : std_logic_vector(ECP_SIZE-1 downto 0);
  signal ecp_cause_s          : std_logic_vector(ECP_SIZE-1 downto 0);
  signal ecp_code_s           : exceptionCode;

  -- interrupt registers

  signal interrupt_in_s        : std_logic_vector(IRQ_ARRAY);
  signal irq_masks             : std_logic_vector(IRQ_ARRAY);
  signal irq_delay_1_s         : std_logic_vector(IRQ_ARRAY);
  signal irq_delay_2_s         : std_logic_vector(IRQ_ARRAY);

  signal irq_delay_3_int_s     : std_logic_vector(IRQ_ARRAY);

  signal irq_delay_3_mul1_s    : std_logic_vector(IRQ_ARRAY);
  signal irq_delay_3_mul2_s    : std_logic_vector(IRQ_ARRAY);
  signal irq_delay_3_mul3_s    : std_logic_vector(IRQ_ARRAY);

  signal irq_delay_3_add1_s    : std_logic_vector(IRQ_ARRAY);
  signal irq_delay_3_add2_s    : std_logic_vector(IRQ_ARRAY);
  signal irq_delay_3_add3_s    : std_logic_vector(IRQ_ARRAY);
  signal irq_delay_3_add4_s    : std_logic_vector(IRQ_ARRAY);

  signal irq_delay_3_mux_s     : std_logic_vector(IRQ_ARRAY);

  signal irq_delay_4_s         : std_logic_vector(IRQ_ARRAY);

  -- interrupt signals

  signal irq_detected_s   : std_logic;

  signal ack_cu_s         : std_logic;
  signal handshake_s      : std_logic;

  -- exception causes

  signal ecp_invalid_op   : std_logic;

  signal iram_misaligned_s  : std_logic;
  signal iram_reserved_s    : std_logic;

  signal dram_misaligned_s  : std_logic;
  signal dram_reserved_s    : std_logic;

  -----------------------------------------------------------
  -- status register
  -----------------------------------------------------------

  -- status register

  signal sr_reg_in_s : std_logic_vector(Nbit-1 downto 0);

  --status flags delayed signals

  signal alu_ovf_delay   : std_logic;
  signal alu_ufl_delay   : std_logic;
  signal alu_carry_delay : std_logic;
  signal alu_zero_delay  : std_logic;
  signal alu_inv_delay   : std_logic;

  -----------------------------------------------------------
  -- components declaration
  -----------------------------------------------------------


component mux3to1 is
   generic (N:integer := 16);
       Port (
           In1:	In	std_logic_vector (N-1 downto 0);
           IN2:	In	std_logic_vector (N-1 downto 0);
           IN3:	In	std_logic_vector (N-1 downto 0);
           S:	In	std_logic_vector(1 downto 0);
           Y:	Out	std_logic_vector (N-1 downto 0));
end component;

component REG
  generic(N : integer := 1;
          RESET_VALUE : integer := 0);
    Port (D:	In	std_logic_vector(N-1 downto 0);
          CK:	In	std_logic;
          RESET:	In	std_logic;
          EN:     in      std_logic;
          Q:	Out	std_logic_vector(N-1 downto 0));
end component;

component REG_CLEAR is
  generic(N : integer := 1;
          RESET_VALUE : integer := 0;
          CLEAR_VALUE : integer := 0);
	Port (	D     :	IN	std_logic_vector(N-1 downto 0);
		      CK    :	IN	std_logic;
		      RESET :	IN	std_logic;
		      CLEAR :	IN	std_logic;
          EN    : IN  std_logic;
		      Q     :	OUT	std_logic_vector(N-1 downto 0));
end component;

component flip_flop
	Port (	D:	In	std_logic;
		      CK:	In	std_logic;
		      RESET:	In	std_logic;
          EN:     in      std_logic;
		      Q:	Out	std_logic);
end component;

component interrupt_arbiter
  generic( 	N               : integer);
     port(	rst							: IN  std_logic;
            interrupt_in    : IN  std_logic_vector(N-1 downto 0);
            ack_cu					: IN 	std_logic;
            interrupt_code  : OUT irqCode;
            ack_out					: OUT std_logic_vector(N-1 downto 0);
            handshake       : OUT std_logic
         );
end component;

component mem_ecp_checker
     port( opcode    				: IN  std_logic_vector(OPCODE_SIZE-1 downto 0);
           stack_protection  : IN std_logic;
           iram_protection   : IN std_logic;
           dram_address			: IN 	std_logic_vector(Nbit-1 downto 0);
           dram_misaligned   : OUT std_logic;
           dram_reserved     : OUT std_logic;
           iram_address			: IN 	std_logic_vector(Nbit-1 downto 0);
           iram_misaligned   : OUT std_logic;
           iram_reserved     : OUT std_logic
         );
end component;

component ecp_decoder
	   port( 	ecp_cause       : IN  std_logic_vector(ECP_SIZE-1 downto 0);
		 			 	ecp_code        : OUT exceptionCode
	       );
end component;

component pulse_gen IS
	 GENERIC (N : integer := 16);
    	PORT (
				clk			: IN	std_logic;
				rst_n		: IN	std_logic;
				trigger	: IN	std_logic;
				pulse		: OUT std_logic
			);
end component;

BEGIN  -- dlx_cu_rtl

  ----------------------------------------------------------
  -- components instances
  ----------------------------------------------------------

  -- crash signal

  crash_ff : flip_flop
    port map(crash_s, Clk, Rst, m_enable_s, crash_sync);

  -- debouncer for debug signal

  dbg_step_pulse : pulse_gen
    generic map(DBG_DELAY_COUNTER_N)
    port map(Clk, Rst, DBG, dbg_step);

  -- control word registers

  cw_1_r : REG_CLEAR
    generic map(CW_SIZE, to_integer(signed(cw_mem(NULL_INDEX))), to_integer(signed(cw_mem(NULL_INDEX))))
    port map(cw, clk, Rst, d_clear_s, d_enable_s, cw_1_out);

  cw_2_int_r : REG_CLEAR
    generic map(CW_2_SIZE, to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))), to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))))
    port map(cw1(CW_2_RANGE), clk, Rst, int_pipe_clr, cw_2_int_en, cw_2_int_out);

  cw_2_m1_r : REG_CLEAR
    generic map(CW_2_SIZE, to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))), to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))))
    port map(cw1(CW_2_RANGE), clk, Rst, mul_pipe_clr, cw_2_m1_en, cw_2_m1_out);

  cw_2_m2_r : REG_CLEAR
    generic map(CW_2_SIZE, to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))), to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))))
    port map(cw_2_m1_out, clk, Rst, e_clear_s, cw_2_m2_en, cw_2_m2_out);

  cw_2_m3_r : REG_CLEAR
    generic map(CW_2_SIZE, to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))), to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))))
    port map(cw_2_m2_out, clk, Rst, e_clear_s, cw_2_m3_en, cw_2_m3_out);

  cw_2_a1_r : REG_CLEAR
    generic map(CW_2_SIZE, to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))), to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))))
    port map(cw1(CW_2_RANGE), clk, Rst, add_pipe_clr, cw_2_a1_en, cw_2_a1_out);

  cw_2_a2_r : REG_CLEAR
    generic map(CW_2_SIZE, to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))), to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))))
    port map(cw_2_a1_out, clk, Rst, e_clear_s, cw_2_a2_en, cw_2_a2_out);

  cw_2_a3_r : REG_CLEAR
    generic map(CW_2_SIZE, to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))), to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))))
    port map(cw_2_a2_out, clk, Rst, e_clear_s, cw_2_a3_en, cw_2_a3_out);

  cw_2_a4_r : REG_CLEAR
    generic map(CW_2_SIZE, to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))), to_integer(signed(cw_mem(NULL_INDEX)(CW_2_RANGE))))
    port map(cw_2_a3_out, clk, Rst, e_clear_s, cw_2_a4_en, cw_2_a4_out);

  cw2_mux : mux3to1
    generic map(CW_2_SIZE)
    port map (cw_2_out, cw_2_m1_out, cw_2_a1_out, cw2_mux_sel_s, cw2);

  cw_2_out <= cw_2_m3_out when alu_out_sel_s = "01" else
              cw_2_a4_out when alu_out_sel_s = "10" else
              cw_2_int_out;

  cw_3_r : REG_CLEAR
    generic map(CW_3_SIZE, to_integer(signed(cw_mem(NULL_INDEX)(CW_3_RANGE))), to_integer(signed(cw_mem(NULL_INDEX)(CW_3_RANGE))))
    port map(cw_2_out(CW_3_RANGE), clk, Rst, m_clear_s, m_enable_s, cw3);

  cw_4_r : REG_CLEAR
    generic map(CW_4_SIZE, to_integer(signed(cw_mem(NULL_INDEX)(CW_4_RANGE))), to_integer(signed(cw_mem(NULL_INDEX)(CW_4_RANGE))))
    port map(cw3(CW_4_RANGE), clk, Rst, w_clear_s, w_enable_s, cw4);  -- WB is not cleared by ecp flush

  -- exception propagation registers

  ecp_cause_reg_fd : REG_CLEAR
    generic map(ECP_SIZE)
    port map(ecp_cause_fd_in, clk, ecp_pipe_rst, d_clear_s, d_ecp_enable_s, ecp_cause_fd_out);

  ecp_cause_reg_int_de : REG_CLEAR
    generic map(ECP_SIZE)
    port map(ecp_cause_de_in, clk, ecp_pipe_rst, int_pipe_clr, e_ecp_int_enable_s, ecp_cause_e_int_out);

  ecp_cause_reg_mul_de1 : REG_CLEAR
    generic map(ECP_SIZE)
    port map(ecp_cause_de_in, clk, ecp_pipe_rst, mul_pipe_clr, e_ecp_mul1_enable_s, ecp_cause_e1_mul_out);

  ecp_cause_reg_mul_de2 : REG_CLEAR
    generic map(ECP_SIZE)
    port map(ecp_cause_e1_mul_out, clk, ecp_pipe_rst, e_clear_s, e_ecp_mul2_enable_s, ecp_cause_e2_mul_out);

  ecp_cause_reg_mul_de3 : REG_CLEAR
    generic map(ECP_SIZE)
    port map(ecp_cause_e2_mul_out, clk, ecp_pipe_rst, e_clear_s, e_ecp_mul3_enable_s, ecp_cause_e3_mul_out);

  ecp_cause_reg_add_de1 : REG_CLEAR
    generic map(ECP_SIZE)
    port map(ecp_cause_de_in, clk, ecp_pipe_rst, add_pipe_clr, e_ecp_add1_enable_s, ecp_cause_e1_add_out);

  ecp_cause_reg_add_de2 : REG_CLEAR
    generic map(ECP_SIZE)
    port map(ecp_cause_e1_add_out, clk, ecp_pipe_rst, e_clear_s, e_ecp_add2_enable_s, ecp_cause_e2_add_out);

  ecp_cause_reg_add_de3 : REG_CLEAR
    generic map(ECP_SIZE)
    port map(ecp_cause_e2_add_out, clk, ecp_pipe_rst, e_clear_s, e_ecp_add3_enable_s, ecp_cause_e3_add_out);

  ecp_cause_reg_add_de4 : REG_CLEAR
    generic map(ECP_SIZE)
    port map(ecp_cause_e3_add_out, clk, ecp_pipe_rst, e_clear_s, e_ecp_add4_enable_s, ecp_cause_e4_add_out);

  ecp_cause_em_mux_in : mux3to1
    generic map(ECP_SIZE)
    port map(ecp_cause_e_int_out, ecp_cause_e3_mul_out, ecp_cause_e4_add_out, alu_out_sel_s, ecp_cause_de_out);

  ecp_cause_reg_em : REG_CLEAR
    generic map(ECP_SIZE)
    port map(ecp_cause_em_in, clk, ecp_pipe_rst, m_clear_s, m_ecp_enable_s, ecp_cause_em_out);

  -- exception decoder

  ecp_dec : ecp_decoder
    port map (ecp_cause_s, ecp_code_s);

  -- IRQ propagation registers

  irq_delay_1_reg : REG_CLEAR
    generic map(interrupt_in_s'LENGTH)
    port map(interrupt_in_s, clk, irq_pipe_rst, f_clear_s, f_ecp_enable_s, irq_delay_1_s);

  irq_delay_2_reg : REG_CLEAR
    generic map(interrupt_in_s'LENGTH)
    port map(irq_delay_1_s, clk, irq_pipe_rst, d_clear_s, d_ecp_enable_s, irq_delay_2_s);

  irq_delay_3_int_reg : REG_CLEAR
    generic map(interrupt_in_s'LENGTH)
    port map(irq_delay_2_s, clk, irq_pipe_rst, int_pipe_clr, e_ecp_int_enable_s, irq_delay_3_int_s);

  irq_delay_3_mul1_reg : REG_CLEAR
    generic map(interrupt_in_s'LENGTH)
    port map(irq_delay_2_s, clk, irq_pipe_rst, mul_pipe_clr, e_ecp_mul1_enable_s, irq_delay_3_mul1_s);

  irq_delay_3_mul2_reg : REG_CLEAR
    generic map(interrupt_in_s'LENGTH)
    port map(irq_delay_3_mul1_s, clk, irq_pipe_rst, e_clear_s, e_ecp_mul2_enable_s, irq_delay_3_mul2_s);

  irq_delay_3_mul3_reg : REG_CLEAR
    generic map(interrupt_in_s'LENGTH)
    port map(irq_delay_3_mul2_s, clk, irq_pipe_rst, e_clear_s, e_ecp_mul3_enable_s, irq_delay_3_mul3_s);

  irq_delay_3_add1_reg : REG_CLEAR
    generic map(interrupt_in_s'LENGTH)
    port map(irq_delay_2_s, clk, irq_pipe_rst, add_pipe_clr, e_ecp_add1_enable_s, irq_delay_3_add1_s);

  irq_delay_3_add2_reg : REG_CLEAR
    generic map(interrupt_in_s'LENGTH)
    port map(irq_delay_3_add1_s, clk, irq_pipe_rst, e_clear_s, e_ecp_add2_enable_s, irq_delay_3_add2_s);

  irq_delay_3_add3_reg : REG_CLEAR
    generic map(interrupt_in_s'LENGTH)
    port map(irq_delay_3_add2_s, clk, irq_pipe_rst, e_clear_s, e_ecp_add3_enable_s, irq_delay_3_add3_s);

  irq_delay_3_add4_reg : REG_CLEAR
    generic map(interrupt_in_s'LENGTH)
    port map(irq_delay_3_add3_s, clk, irq_pipe_rst, e_clear_s, e_ecp_add4_enable_s, irq_delay_3_add4_s);

  irq_delay_3_mux : mux3to1
    generic map(interrupt_in_s'LENGTH)
    port map(irq_delay_3_int_s, irq_delay_3_mul3_s, irq_delay_3_add4_s, alu_out_sel_s, irq_delay_3_mux_s);

  irq_delay_4_reg : REG_CLEAR
    generic map(interrupt_in_s'LENGTH)
    port map(irq_delay_3_mux_s, clk, irq_pipe_rst, m_clear_s, m_ecp_enable_s, irq_delay_4_s);

  -- store forwarding mux signal

  st_fwd_mux_sel_r : REG
    generic map(3)
    port map(st_fwd_mux_sel1, Clk, Rst, e_enable_s, st_fwd_mux_sel2);

  -- ecp pipe select signals

  mul_pipe_r : flip_flop
    port map(mul_pipe, Clk, Rst, e_enable_s, mul_pipe_sync);

  add_pipe_r : flip_flop
    port map(add_pipe, Clk, Rst, e_enable_s, add_pipe_sync);

  -- interrupt arbiter

  arbiter : interrupt_arbiter
    generic map (interrupt_in_s'LENGTH)
    port map (
      rst => Rst,
      interrupt_in => INTERRUPT_LINE,
      ack_cu => ack_cu_s,
      interrupt_code => IRQ_CODE,
      ack_out => ACK_LINE,
      handshake => handshake_s
      );

  -- memory exceptions checker

  data_mem_check : mem_ecp_checker
    port map( IR_m(OPCODE_RANGE),
              SR_REG_OUT(STACK_FLAG),
              SR_REG_OUT(IRAM_FLAG),
              DRAM_ADDRESS,
              dram_misaligned_s,
              dram_reserved_s,
              PC,
              iram_misaligned_s,
              iram_reserved_s
              );

  -- Delay registers for Status flags

  ovf_delay : flip_flop
    port map(ALU_OVF, Clk, Rst, m_enable_s, alu_ovf_delay);

  ufl_delay : flip_flop
    port map(ALU_UFL, Clk, Rst, m_enable_s, alu_ufl_delay);

  carry_delay : flip_flop
    port map(ALU_CARRY, Clk, Rst, m_enable_s, alu_carry_delay);

  zero_delay : flip_flop
    port map(ALU_ZERO, Clk, Rst, m_enable_s, alu_zero_delay);

  inv_delay : flip_flop
    port map(ALU_INVALID_CONV, Clk, Rst, m_enable_s, alu_inv_delay);

  ----------------------------------------------------------
  -- assignments
  ----------------------------------------------------------

  -- pipe control

  FETCH_EN     <= f_enable_s;
  DECODE_EN    <= d_enable_s;
  EXECUTION_EN <= e_enable_s;
  E_INT_EN     <= e_int_en_s;
  E_MUL_EN     <= e_mul_en_s;
  E_ADD_EN     <= e_add_en_s;
  MEMORY_EN    <= m_enable_s;
  WRITEBACK_EN <= w_enable_s;

  CRASH <= crash_sync;

  f_clear_s    <= ecp_flush_s;
  d_clear_s    <= ecp_flush_s;
  e_clear_s    <= ecp_flush_s;
  m_clear_s    <= ecp_flush_s;
  w_clear_s    <= ecp_flush_s;

  int_pipe_clr <= ecp_flush_s or (not(int_pipe) or int_ex_clr);
  mul_pipe_clr <= ecp_flush_s or (not(mul_pipe) or mul_ex_clr);
  add_pipe_clr <= ecp_flush_s or (not(add_pipe) or add_ex_clr);

  -- IR pipe

  IR_CLEAR_D      <= d_clear_s;
  IR_CLEAR_E      <= e_clear_s;
  IR_CLEAR_M      <= m_clear_s;
  IR_CLEAR_W      <= w_clear_s;
  IR_CLEAR_EX_INT <= int_pipe_clr;
  IR_CLEAR_EX_MUL <= mul_pipe_clr;
  IR_CLEAR_EX_ADD <= add_pipe_clr;

  -- EXCEPTION control

  f_ecp_enable_s      <= f_enable_s and ecp_lock_n;
  d_ecp_enable_s      <= d_enable_s and ecp_lock_n and not(branch_flush); --disable excepions on instruction to be flushed
  e_ecp_int_enable_s  <= e_enable_s and ecp_lock_n and e_int_en_s;
  e_ecp_mul1_enable_s <= e_enable_s and ecp_lock_n and e_mul_en_s(1);
  e_ecp_mul2_enable_s <= e_enable_s and ecp_lock_n and e_mul_en_s(2);
  e_ecp_mul3_enable_s <= e_enable_s and ecp_lock_n and e_mul_en_s(3);
  e_ecp_add1_enable_s <= e_enable_s and ecp_lock_n and e_add_en_s(1);
  e_ecp_add2_enable_s <= e_enable_s and ecp_lock_n and e_add_en_s(2);
  e_ecp_add3_enable_s <= e_enable_s and ecp_lock_n and e_add_en_s(3);
  e_ecp_add4_enable_s <= e_enable_s and ecp_lock_n and e_add_en_s(4);
  m_ecp_enable_s      <= m_enable_s and ecp_lock_n;

  -- exception signals

  ECP_CODE          <= ecp_code_s;
  ecp_pipe_rst      <= Rst and not(ecp_flush_sync_s);

  -- interrupts

  irq_pipe_rst      <= rst and not(ecp_flush_sync_s) and not(call_s or ret_s) and not(SPILL or FILL); -- irq flush on CALL/RET SPILL/FILL
  interrupt_in_s    <= INTERRUPT_LINE;
  irq_masks         <= CR_REG_OUT(IRQ_ARRAY);
  irq_detected_s    <= or_reduce(irq_delay_4_s and irq_masks);

  -- ALU and BRANCH opcode

  ALU_OP <= aluOpcode2;
  BRANCH_OP <= branchOpcode1;

  -- CW

  cw_2_int_en <= e_enable_s and e_int_en_s;

  cw_2_m1_en <= e_enable_s and e_mul_en_s(1);
  cw_2_m2_en <= e_enable_s and e_mul_en_s(2);
  cw_2_m3_en <= e_enable_s and e_mul_en_s(3);

  cw_2_a1_en <= e_enable_s and e_add_en_s(1);
  cw_2_a2_en <= e_enable_s and e_add_en_s(2);
  cw_2_a3_en <= e_enable_s and e_add_en_s(3);
  cw_2_a4_en <= e_enable_s and e_add_en_s(4);

  cw <= cw_mem(to_integer(unsigned(IR_opcode)));

  cw2_mux_sel_s <= "01" when mul_pipe_sync = '1' else
                   "10" when add_pipe_sync = '1' else
                   "00";

  -- IRAM enable

  IRAM_EN <= f_enable_s;

  -- stage one control signals

  FP_INTn_RD1       <= cw1(FP_INTn_RD1_ID);
  FP_INTn_RD2       <= cw1(FP_INTn_RD2_ID);
  MUX_IMM_SEL       <= cw1(MUX_IMM_SEL_ID);

  -- stage two control signals

  MUXA_SEL          <= cw2(MUXA_SEL_ID);
  MUXB_SEL          <= cw2(MUXB_SEL_ID);
  PUSH_POP_MUX_SEL  <= cw2(PUSH_POP_MUX_SEL_ID);

  -- stage three control signals

  DRAM_CS           <= cw3(DRAM_CS_ID) and not(dram_reserved_s or dram_misaligned_s);
  DRAM_R_W          <= cw3(DRAM_R_W_ID) when clk = '1' else "00";
  LOAD_MUX_SEL      <= cw3(LOAD_MUX_SEL_ID);
  WR_MUX_SEL        <= cw3(WR_MUX_SEL_ID);

  -- stage four control signals

  RF_WE             <= cw4(RF_WE_ID);
  FP_INTn_WR        <= cw4(FP_INTn_WR_ID);
  WB_MUX_SEL        <= cw4(WB_MUX_SEL_ID);
  RF_WE_SP          <= cw4(RF_WE_SP_ID);

  -- IR

  IR_opcode <= IR_IN(31 downto 26);
  IR_func  <= IR_IN(FUNC_SIZE - 1 downto 0);

  -- ALU OUT SEL

  ALU_OUT_SEL <= alu_out_sel_s;

  -- CALL/RET

  CALL          <= call_s;
  RET           <= ret_s;

  CALL_ROLLBACK <= call_rollback_s;
  RET_ROLLBACK  <= ret_rollback_s;
  CWP_ENABLE    <= cwp_enable_s and e_enable_s;

  spill_delay_s <= spill_delay_1 or spill_delay_2 or spill_delay_3 or spill_delay_4;
  fill_delay_s  <= fill_delay_1 or fill_delay_2 or fill_delay_3 or fill_delay_4;

  -- STATUS Register

  SR_REG_IN <= sr_reg_in_s;

  -- MUXES

  BR_FWD_MUX_SEL <= br_fwd_mux_sel1;
  ST_FWD_MUX_SEL <= st_fwd_mux_sel2;

  ----------------------------------------------------------
  -- implicit processes
  ----------------------------------------------------------

  -- pipe

  crash_s <= '1' when (spill_delay_s = '1' and ecp_flush_s = '1') else
             '1' when (fill_delay_s = '1' and ecp_flush_s = '1') else
             '0';

  -- flush signals

  branch_flush <= BRANCH_DETECTED and not(SR_REG_OUT(BRANCH_DELAY_SLOT));

  -- exception handling

  ecp_invalid_op <= '0' when is_valid(IR_d(OPCODE_RANGE)) else
                    '1';

  -- Exec unit stages

  mul_stages(1) <= '1' when not(is_null(IR_E1_MUL(OPCODE_RANGE))) else '0';
  mul_stages(2) <= '1' when not(is_null(IR_E2_MUL(OPCODE_RANGE))) else '0';
  mul_stages(3) <= '1' when not(is_null(IR_E3_MUL(OPCODE_RANGE))) else '0';

  add_stages(1) <= '1' when not(is_null(IR_E1_ADD(OPCODE_RANGE))) else '0';
  add_stages(2) <= '1' when not(is_null(IR_E2_ADD(OPCODE_RANGE))) else '0';
  add_stages(3) <= '1' when not(is_null(IR_E3_ADD(OPCODE_RANGE))) else '0';
  add_stages(4) <= '1' when not(is_null(IR_E4_ADD(OPCODE_RANGE))) else '0';

  -- Execution unit out select

  alu_out_sel_s <= "10" when add_stages(4) = '1' else
                   "01" when mul_stages(3) = '1' else
                   "00";

  -- Jump mux sel signal

  JUMP_MUX_SEL <= "101" when SR_REG_OUT(CPU_MODE) = SRT_MODE else
                  "011" when ecp_flush_s = '1' else
                  "010" when branchOpcode1 = JR or branchOpcode1 = JALR else
                  "100" when IR_d(OPCODE_RANGE) = "010000" else --RFE
                  "001" when BRANCH_DETECTED = '1' else
                  "000";

  -- Status Register Write enable

  RF_WE_SR <= '1' when SR_REG_OUT(CPU_MODE) = SRT_MODE else
              '1' when and_reduce(SR_REG_OUT and sr_reg_in_s) = '0' else
              '0';

  -- SR mux sel signal

  SR_MUX_SEL <= '0' when SR_REG_OUT(CPU_MODE) = SRT_MODE else
                '1';

  -- CALL/RET

  call_s <= '1' when IR_e(OPCODE_RANGE) = std_logic_vector(to_unsigned(48,OPCODE_SIZE)) else --CALL
            '0';

  ret_s  <= '1' when IR_e(OPCODE_RANGE) = std_logic_vector(to_unsigned(49,OPCODE_SIZE)) else --RET
            '0';

  cwp_enable_s <= call_s or ret_s or call_rollback_s or ret_rollback_s;

  ----------------------------------------------------------
  -- processes
  ----------------------------------------------------------

  ir_mux_sel_p : process(dbg_step, SR_REG_OUT(CPU_MODE), branch_flush, SPILL, FILL, fill_delay_s)
  begin
    case SR_REG_OUT(CPU_MODE) is
      when DBG_MODE =>
        if FILL = '1' or SPILL = '1' then
          IR_MUX_SEL <= "01";
        elsif dbg_step = '1' then
          IR_MUX_SEL <= "00";
        else
          IR_MUX_SEL <= "10";
        end if;
      when others =>
        if FILL = '1' or SPILL = '1' then
          IR_MUX_SEL <= "01";
        elsif branch_flush = '1' or fill_delay_s = '1' then
          IR_MUX_SEL <= "10";
        else
          IR_MUX_SEL <= "00";
        end if;
    end case;
  end process;

  -- ack process

  ack_cu_p : process(Clk, Rst)
  begin
    if Rst = '0' then
      ack_cu_s <= '0';
    elsif Clk'event and Clk = '1' then
      if ecp_lock_n = '1' and irq_detected_s = '1' then
        ack_cu_s <= '1';
      elsif handshake_s = '1' then
        ack_cu_s <= '0';
      end if;
    end if;
  end process;

  -- excepion enable

  ecp_enable_p : process(Rst, ecp_flush_sync_s, IR_e)
  begin
    if Rst = '0' then
      ecp_lock_n <= '1';
    elsif ecp_flush_sync_s = '1' then
      ecp_lock_n <= '0';
    elsif to_integer(unsigned(IR_e(31 downto 26))) = 16 then
      ecp_lock_n <= '1';
    end if;
  end process;

  -- ecp handling

  ecp_flush_sync_s_p : process (clk)
  begin
    if clk'event and clk = '1' then
        ecp_flush_sync_s <= ecp_flush_s;
    end if;
  end process;

  ---------------------------------------------------------------
  -- Exe pipe selection
  ---------------------------------------------------------------

  pipe_sel_p : process(IR_d)
  begin
    int_pipe <= '0';
    mul_pipe <= '0';
    add_pipe <= '0';
    if is_add_type(IR_d(OPCODE_RANGE), IR_d(FUNC_RANGE)) then
      add_pipe <= '1';
    elsif is_mul_type(IR_d(OPCODE_RANGE), IR_d(FUNC_RANGE)) then
      mul_pipe <= '1';
    else
      int_pipe <= '1';
    end if;
  end process;

  ---------------------------------------------------------------
  -- Control word propagation
  ---------------------------------------------------------------

  FWD_PROCESS: process (Rst, IR_d, IR_e, IR_E3_MUL, IR_E4_ADD, IR_m, cw_1_out)
  begin  -- process Clk

    cw1 <= cw_1_out;

    if Rst = '0' then                   -- asynchronous reset (active low)

      br_fwd_mux_sel1 <= "00";
      st_fwd_mux_sel1 <= "000";

    else
      ------------------------------------------------------------------------------
      -- Forwarding control in memory stage
      -------------------------------------------------------------------------------

      br_fwd_mux_sel1 <= "00";
      st_fwd_mux_sel1 <= "000";

      if is_pp(IR_m(OPCODE_RANGE)) then
        if IR_d(25 downto 21)="11101" and not is_ftype(IR_d(OPCODE_RANGE)) and not is_f_itype(IR_d(OPCODE_RANGE)) and not is_movfp2i(IR_d(OPCODE_RANGE)) then
          cw1(MUXA_SEL_ID) <= "110";
        end if;
        if is_rtype(IR_d(OPCODE_RANGE)) and IR_d(20 downto 16) = "11101" then
          cw1(MUXB_SEL_ID) <= "111";
        end if;
        if is_store(IR_d(OPCODE_RANGE)) and IR_d(20 downto 16) = "11101" then
          st_fwd_mux_sel1 <= "100";
        end if;
        if is_branch(IR_d(OPCODE_RANGE)) and IR_d(25 downto 21)= "11101" then
          br_fwd_mux_sel1 <= "10";
        end if;
      end if;

      if is_load(IR_m(OPCODE_RANGE)) then --if the operation in memory stage is a load
        if IR_m(20 downto 16) = IR_d(25 downto 21) and not is_ftype(IR_d(OPCODE_RANGE)) and not is_f_itype(IR_d(OPCODE_RANGE)) and not is_movfp2i(IR_d(OPCODE_RANGE)) then
          cw1(MUXA_SEL_ID) <= "010";
        end if;
        if is_rtype(IR_d(OPCODE_RANGE)) and IR_m(20 downto 16) = IR_d(20 downto 16) then
          cw1(MUXB_SEL_ID) <= "010";
        end if;
        if is_store(IR_d(OPCODE_RANGE))and IR_m(20 downto 16) = IR_d(20 downto 16) then
          st_fwd_mux_sel1 <= "101";
        end if;

      elsif is_rtype(IR_m(OPCODE_RANGE)) then     -- if the operation in the memory stage is an R-type
        if IR_m(15 downto 11) = IR_d(25 downto 21) and not is_ftype(IR_d(OPCODE_RANGE)) and not is_f_itype(IR_d(OPCODE_RANGE)) and not is_movfp2i(IR_d(OPCODE_RANGE)) then
          cw1(MUXA_SEL_ID) <= "001";
        end if;
        if is_rtype(IR_d(OPCODE_RANGE)) and IR_m(15 downto 11) = IR_d(20 downto 16) then
          cw1(MUXB_SEL_ID) <= "011";
        end if;
        if is_store(IR_d(OPCODE_RANGE))and IR_m(15 downto 11) = IR_d(20 downto 16) then
          st_fwd_mux_sel1 <= "010";
        end if;
        if is_branch(IR_d(OPCODE_RANGE)) and IR_m(15 downto 11) = IR_d(25 downto 21) then
          br_fwd_mux_sel1 <= "01";
        end if;

      elsif is_itype(IR_m(OPCODE_RANGE)) then     -- if the operation in the memory stage is an I-type
        if IR_m(20 downto 16) = IR_d(25 downto 21) and not is_ftype(IR_d(OPCODE_RANGE)) and not is_f_itype(IR_d(OPCODE_RANGE)) and not is_movfp2i(IR_d(OPCODE_RANGE)) then
          cw1(MUXA_SEL_ID) <= "001";
        end if;
        if is_rtype(IR_d(OPCODE_RANGE)) and IR_m(20 downto 16) = IR_d(20 downto 16) then
          cw1(MUXB_SEL_ID) <= "011";
        end if;
        if is_store(IR_d(OPCODE_RANGE)) and IR_m(20 downto 16) = IR_d(20 downto 16) then
          st_fwd_mux_sel1 <= "010";
        end if;
        if is_branch(IR_d(OPCODE_RANGE)) and IR_m(20 downto 16) = IR_d(25 downto 21) then
          br_fwd_mux_sel1 <= "01";
        end if;

      elsif IR_m(OPCODE_RANGE)="000011"  or IR_m(OPCODE_RANGE)="010011" then  --jal or jalr in memory
        if IR_d(25 downto 21)="11111" and not is_ftype(IR_d(OPCODE_RANGE)) and not is_f_itype(IR_d(OPCODE_RANGE)) and not is_movfp2i(IR_d(OPCODE_RANGE)) then
          cw1(MUXA_SEL_ID) <= "001";
        end if;
        if is_rtype(IR_d(OPCODE_RANGE)) and IR_d(20 downto 16) = "11111" then
          cw1(MUXB_SEL_ID) <= "011";
        end if;
        if is_store(IR_d(OPCODE_RANGE)) and IR_d(20 downto 16) = "11111" then
          st_fwd_mux_sel1 <= "010";
        end if;
        if is_branch(IR_d(OPCODE_RANGE)) and IR_d(25 downto 21)= "11111" then
          br_fwd_mux_sel1 <= "01";
        end if;

      elsif is_ftype(IR_m(OPCODE_RANGE)) then     -- if the operation in the memory stage is an F-type
        if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_m(15 downto 11) = IR_d(25 downto 21)) then
          cw1(MUXA_SEL_ID) <= "001";
        end if;
        if is_ftype(IR_d(OPCODE_RANGE)) and IR_m(15 downto 11) = IR_d(20 downto 16) then
          cw1(MUXB_SEL_ID) <= "011";
        end if;
        if is_store_f(IR_d(OPCODE_RANGE)) and IR_m(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
          st_fwd_mux_sel1 <= "010";
        end if;

      elsif is_f_itype(IR_m(OPCODE_RANGE)) then     -- if the operation in the memory stage is an F-Itype
        if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_m(20 downto 16) = IR_d(25 downto 21)) then
          cw1(MUXA_SEL_ID) <= "001";
        end if;
        if is_ftype(IR_d(OPCODE_RANGE)) and IR_m(20 downto 16) = IR_d(20 downto 16) then
          cw1(MUXB_SEL_ID) <= "011";
        end if;
        if is_store_f(IR_d(OPCODE_RANGE)) and IR_m(20 downto 16) = IR_d(20 downto 16) then -- SF or PUSHF
          st_fwd_mux_sel1 <= "010";
        end if;

      elsif is_movfp2i(IR_m(OPCODE_RANGE)) then     -- if the operation in the memory stage is a movfp2i
        if IR_m(20 downto 16) = IR_d(25 downto 21) and not is_ftype(IR_d(OPCODE_RANGE)) and not is_f_itype(IR_d(OPCODE_RANGE)) and not is_movfp2i(IR_d(OPCODE_RANGE)) then
          cw1(MUXA_SEL_ID) <= "001";
        end if;
        if is_rtype(IR_d(OPCODE_RANGE)) and IR_m(20 downto 16) = IR_d(20 downto 16) then
          cw1(MUXB_SEL_ID) <= "011";
        end if;
        if is_store(IR_d(OPCODE_RANGE)) and IR_m(20 downto 16) = IR_d(20 downto 16) then
          st_fwd_mux_sel1 <= "010";
        end if;
        if is_branch(IR_d(OPCODE_RANGE)) and IR_m(20 downto 16) = IR_d(25 downto 21) then
          br_fwd_mux_sel1 <= "01";
        end if;

      elsif IR_m(OPCODE_RANGE) = "110011" then -- MOVI2FP
        if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_m(20 downto 16) = IR_d(25 downto 21)) then
          cw1(MUXA_SEL_ID) <= "001";
        end if;
        if is_ftype(IR_d(OPCODE_RANGE)) and IR_m(20 downto 16) = IR_d(20 downto 16) then
          cw1(MUXB_SEL_ID) <= "011";
        end if;
        if is_store_f(IR_d(OPCODE_RANGE)) and IR_m(20 downto 16) = IR_d(20 downto 16) then -- SF or PUSHF
          st_fwd_mux_sel1 <= "010";
        end if;

      elsif IR_m(OPCODE_RANGE) = "100110" or IR_m(OPCODE_RANGE) = "101101" then -- LF or POPF
        if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_m(20 downto 16) = IR_d(25 downto 21)) then
          cw1(MUXA_SEL_ID) <= "001";
        end if;
        if is_ftype(IR_d(OPCODE_RANGE)) and IR_m(20 downto 16) = IR_d(20 downto 16) then
          cw1(MUXB_SEL_ID) <= "010";
        end if;
        if is_store_f(IR_d(OPCODE_RANGE)) and IR_m(20 downto 16) = IR_d(20 downto 16) then -- SF or PUSHF
          st_fwd_mux_sel1 <= "101";
        end if;
      end if;

      ------------------------------------------------------------------------------
      -- Forwarding control in execution stage
      ------------------------------------------------------------------------------

      if is_pp(IR_e(OPCODE_RANGE)) then
        if IR_d(25 downto 21)="11101" and not is_ftype(IR_d(OPCODE_RANGE)) and not is_f_itype(IR_d(OPCODE_RANGE)) and not is_movfp2i(IR_d(OPCODE_RANGE)) then
          cw1(MUXA_SEL_ID) <= "101";
        end if;
        if is_rtype(IR_d(OPCODE_RANGE)) and IR_d(20 downto 16) = "11101" then
          cw1(MUXB_SEL_ID) <= "110";
        end if;
        if is_store(IR_d(OPCODE_RANGE)) and IR_d(20 downto 16) = "11101" then
          st_fwd_mux_sel1 <= "011";
        end if;
      end if;

      if is_rtype(IR_e(OPCODE_RANGE)) then     -- if the operation in the execution stage is an R-type
        if IR_e(15 downto 11) = IR_d(25 downto 21) and not is_ftype(IR_d(OPCODE_RANGE)) and not is_f_itype(IR_d(OPCODE_RANGE)) and not is_movfp2i(IR_d(OPCODE_RANGE)) then
          cw1(MUXA_SEL_ID) <= "000";
        end if;
        if is_rtype(IR_d(OPCODE_RANGE)) and IR_e(15 downto 11) = IR_d(20 downto 16) then
          cw1(MUXB_SEL_ID) <= "100";
        end if;
        if is_store(IR_d(OPCODE_RANGE)) and IR_e(15 downto 11) = IR_d(20 downto 16) then
          st_fwd_mux_sel1 <= "001";
        end if;

      elsif is_itype(IR_e(OPCODE_RANGE)) then     -- if the operation in the execution stage is an I-type
        if IR_e(20 downto 16) = IR_d(25 downto 21) and not is_ftype(IR_d(OPCODE_RANGE)) and not is_f_itype(IR_d(OPCODE_RANGE)) and not is_movfp2i(IR_d(OPCODE_RANGE)) then
          cw1(MUXA_SEL_ID) <= "000";
        end if;
        if is_rtype(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then
          cw1(MUXB_SEL_ID) <= "100";
        end if;
        if is_store(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then
          st_fwd_mux_sel1 <= "001";
        end if;


      elsif IR_e(OPCODE_RANGE)="000011"  or IR_e(OPCODE_RANGE)="010011" then --jal or jalr in execution (not necessary, the instruction should be flushed anyway)
        if IR_d(25 downto 21)="11111" and not is_ftype(IR_d(OPCODE_RANGE)) and not is_f_itype(IR_d(OPCODE_RANGE)) and not is_movfp2i(IR_d(OPCODE_RANGE)) then
          cw1(MUXA_SEL_ID) <= "000";
        end if;
        if is_rtype(IR_d(OPCODE_RANGE)) and IR_d(20 downto 16)="11111" then
          cw1(MUXB_SEL_ID) <= "100";
        end if;
        if is_store(IR_d(OPCODE_RANGE)) and IR_d(20 downto 16) = "11111" then
          st_fwd_mux_sel1 <= "001";
        end if;


      elsif is_mul_type(IR_E3_MUL(OPCODE_RANGE), IR_E3_MUL(FUNC_RANGE)) then     -- if the operation in the execution stage is a mul-type
        if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E3_MUL(15 downto 11) = IR_d(25 downto 21)) then
          cw1(MUXA_SEL_ID) <= "000";
        end if;
        if is_ftype(IR_d(OPCODE_RANGE)) and IR_E3_MUL(15 downto 11) = IR_d(20 downto 16) then
          cw1(MUXB_SEL_ID) <= "100";
        end if;
        if is_store_f(IR_d(OPCODE_RANGE)) and IR_E3_MUL(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
          st_fwd_mux_sel1 <= "001";
        end if;

      elsif is_add_type(IR_E4_ADD(OPCODE_RANGE), IR_E4_ADD(FUNC_RANGE)) then     -- if the operation in the execution stage is an add-type
        if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E4_ADD(15 downto 11) = IR_d(25 downto 21)) then
          cw1(MUXA_SEL_ID) <= "000";
        end if;
        if is_ftype(IR_d(OPCODE_RANGE)) and IR_E4_ADD(15 downto 11) = IR_d(20 downto 16) then
          cw1(MUXB_SEL_ID) <= "100";
        end if;
        if is_store_f(IR_d(OPCODE_RANGE)) and IR_E4_ADD(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
          st_fwd_mux_sel1 <= "001";
        end if;

      elsif is_f_itype(IR_e(OPCODE_RANGE)) then     -- if the operation in the execution stage is an F-Itype
        if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_e(20 downto 16) = IR_d(25 downto 21)) then
          cw1(MUXA_SEL_ID) <= "000";
        end if;
        if is_ftype(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then
          cw1(MUXB_SEL_ID) <= "100";
        end if;
        if is_store_f(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then -- SF of PUSHF
          st_fwd_mux_sel1 <= "001";
        end if;

      elsif is_movfp2i(IR_e(OPCODE_RANGE)) then     -- if the operation in the execution stage is a movfp2i
        if IR_e(20 downto 16) = IR_d(25 downto 21) and not is_ftype(IR_d(OPCODE_RANGE)) and not is_f_itype(IR_d(OPCODE_RANGE)) and not is_movfp2i(IR_d(OPCODE_RANGE)) then
          cw1(MUXA_SEL_ID) <= "000";
        end if;
        if is_rtype(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then
          cw1(MUXB_SEL_ID) <= "100";
        end if;
        if is_store(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then
          st_fwd_mux_sel1 <= "001";
        end if;

      elsif IR_e(OPCODE_RANGE) = "110011" then -- MOVI2FP
        if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_e(20 downto 16) = IR_d(25 downto 21)) then
          cw1(MUXA_SEL_ID) <= "000";
        end if;
        if is_ftype(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then
          cw1(MUXB_SEL_ID) <= "100";
        end if;
        if is_store_f(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then -- SF or PUSHF
          st_fwd_mux_sel1 <= "001";
        end if;
      end if;
    end if;
  end process;

  branchOpcode1_p : process(Rst, Clk)
  begin
    if Rst = '0' then
      branchOpcode1 <= NOBRANCH;
    elsif Clk'event and Clk = '1' then
      if ecp_flush_s = '1' then
        branchOpcode1 <= NOBRANCH;
      elsif d_enable_s = '1' then
        branchOpcode1 <= branchOpcode_i;
      end if;
    end if;
  end process;

  alu_op_1_p : process(Rst, Clk)
  begin
    if Rst = '0' then
      aluOpcode1 <= NOP_OP;
      aluOpcode2 <= NOP_OP;
    elsif Clk'event and Clk = '1' then
      if ecp_flush_s = '1' then
        aluOpcode1 <= NOP_OP;
        aluOpcode2 <= NOP_OP;
      else
        if d_clear_s = '1' then
          aluOpcode1 <= NOP_OP;
        elsif d_enable_s = '1' then
          aluOpcode1 <= aluOpcode_i;
        end if;
        if e_clear_s = '1' then
          aluOpcode2 <= NOP_OP;
        elsif e_enable_s = '1' and (int_ex_clr = '0' or mul_ex_clr = '0' or add_ex_clr = '0') then
          aluOpcode2 <= aluOpcode1;
        end if;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------
  -- ALU OP assignment
  ---------------------------------------------------------------

   ALU_OP_CODE_P : process (IR_opcode, IR_func)
   begin  -- process ALU_OP_CODE_P
	  case to_integer(unsigned(IR_opcode)) is
	    -- case of R type requires analysis of FUNC
	    when 0 =>
	      case to_integer(unsigned(IR_func)) is
	        when 4 => aluOpcode_i <= SLL_OP;   -- sll  (0x04)
	        when 6 => aluOpcode_i <= SRL_OP;   -- srl  (0x06)
	        when 7 => aluOpcode_i <= SRA_OP;   -- srl  (0x06)
          when 32 => aluOpcode_i <= ADD_OP;  -- add (0x20)
          when 33 => aluOpcode_i <= ADDU_OP; -- addu (0x21)
          when 34 => aluOpcode_i <= SUB_OP;  -- sub (0x22)
          when 35 => aluOpcode_i <= SUBU_OP; -- subu (0x23)
          when 36 => aluOpcode_i <= AND_OP;  -- and (0x24)
          when 37 => aluOpcode_i <= OR_OP;   -- or  (0x25)
          when 38 => aluOpcode_i <= XOR_OP;  -- xor (0x26)
          when 40 => aluOpcode_i <= SEQ_OP;  -- seq (0x28)
          when 41 => aluOpcode_i <= SNE_OP;  -- sne (0x29)
          when 42 => aluOpcode_i <= SLT_OP;  -- slt (0x2a)
          when 43 => aluOpcode_i <= SGT_OP;  -- sgt (0x2b)
          when 44 => aluOpcode_i <= SLE_OP;  -- sle (0x2c)
          when 45 => aluOpcode_i <= SGE_OP;  -- sge (0x2d)
          when 58 => aluOpcode_i <= SLTU_OP; -- sltu (0x3a)
          when 59 => aluOpcode_i <= SGTU_OP; -- sgtu (0x3b)
          when 60 => aluOpcode_i <= SLEU_OP; -- sleu (0x3c)
          when 61 => aluOpcode_i <= SGEU_OP; -- sgeu (0x3d)
	        when others => aluOpcode_i <= NOP_OP;
      end case;
    -- case of F type requires analysis of FUNC
    when 1 =>
      case to_integer(unsigned(IR_func)) is
          when 0  => aluOpcode_i <= ADDF_OP;    -- addf  (0x00)
          when 1  => aluOpcode_i <= SUBF_OP;    -- subf  (0x01)
          when 2  => aluOpcode_i <= MULTF_OP;   -- multf (0x02)
          when 14 => aluOpcode_i <= MULT_OP;    -- mult  (0x0E)
          when 22 => aluOpcode_i <= MULTU_OP;   -- multu (0x16)
          when others => aluOpcode_i <= NOP_OP;
      end case;
    when 2 => aluOpcode_i <= NOP_OP; -- j (0X02)
	  when 3 => aluOpcode_i <= ADD_OP; -- jal (0x03)
    when 4  => aluOpcode_i <= NOP_OP; -- beqz (0x04)
    when 5  => aluOpcode_i <= NOP_OP; -- bneqz (0x05)
		when 8  => aluOpcode_i <= ADD_OP; -- addi (0x08)
    when 9  => aluOpcode_i <= ADDU_OP; -- addui (0x09)
    when 10 => aluOpcode_i <= SUB_OP; -- subi (0x0A)
    when 11 => aluOpcode_i <= SUBU_OP; -- subui (0x0B)
    when 12 => aluOpcode_i <= AND_OP; -- andi (0x0C)
    when 13 => aluOpcode_i <= OR_OP; -- ori (0x0D)
    when 14 => aluOpcode_i <= XOR_OP; -- xori (0x0E)
    when 15 => aluOpcode_i <= LHI_OP; -- lhi (0x0F)
    WHEN 18 => aluOpcode_i <= NOP_OP; -- jr (0X12)
    when 19 => aluOpcode_i <= ADD_OP; -- jalr (0x13)
    when 20 => aluOpcode_i <= SLL_OP; -- slli (0x14)
    when 22 => aluOpcode_i <= SRL_OP; -- srli (0x16)
    when 23 => aluOpcode_i <= SRA_OP; -- srai (0x17)
    when 24 => aluOpcode_i <= SEQ_OP; -- seqi (0x18)
    when 25 => aluOpcode_i <= SNE_OP; -- snei (0x19)
    when 26 => aluOpcode_i <= SLT_OP; -- slti (0x1a)
    when 27 => aluOpcode_i <= SGT_OP; -- sgti (0x1b)
    when 28 => aluOpcode_i <= SLE_OP; -- slei (0x1C)
    when 29 => aluOpcode_i <= SGE_OP; -- sgei (0x1D)
    when 32 => aluOpcode_i <= ADD_OP; -- lb (0x20)
    when 33 => aluOpcode_i <= ADD_OP; -- lh (0x21)
    when 35 => aluOpcode_i <= ADD_OP; -- lw (0x23)
    when 36 => aluOpcode_i <= ADD_OP; -- lbu (0x24)
    when 37 => aluOpcode_i <= ADD_OP; -- lhu (0x24)
    when 38 => aluOpcode_i <= ADD_OP; -- lf (0x26)
    when 40 => aluOpcode_i <= ADD_OP; -- sb (0x28)
    when 43 => aluOpcode_i <= ADD_OP; -- sw (0x2b)
    when 46 => aluOpcode_i <= ADD_OP; -- sf (0x2e)
    when 50 => aluOpcode_i <= MOV_OP;  -- movfp2i (0x32)
    when 51 => aluOpcode_i <= MOV_OP;  -- movi2fp (0x33)
    when 52 => aluOpcode_i <= FP2I_OP; -- cvtf2i (0x34)
    when 53 => aluOpcode_i <= I2FP_OP; -- cvti2f (0x35)
    when 58 => aluOpcode_i <= SLTU_OP; -- sltui (0x3a)
    when 59 => aluOpcode_i <= SGTU_OP; -- sgtui (0x3b)
    when 60 => aluOpcode_i <= SLEU_OP; -- sleui (0x3c)
    when 61 => aluOpcode_i <= SGEU_OP; -- sgeui (0x3d)
		when others => aluOpcode_i <= NOP_OP;
	 end case;
	end process ALU_OP_CODE_P;

  ---------------------------------------------------------------
  -- BRANCH OP assignment
  ---------------------------------------------------------------

  Branch_Op_P : process(IR_opcode)
  begin
    case to_integer(unsigned(IR_opcode)) is
      when 2  => branchOpcode_i <= J;
      when 3  => branchOpcode_i <= JAL;
      when 4  => branchOpcode_i <= BEQZ;
      when 5  => branchOpcode_i <= BNEZ;
      when 16 => branchOpcode_i <= RFE;
      when 18 => branchOpcode_i <= JR;
      when 19 => branchOpcode_i <= JALR;
      when 48 => branchOpcode_i <= JAL; -- CALL
      when 49 => branchOpcode_i <= JR;  -- RET
      when others => branchOpcode_i <= NOBRANCH;
    end case;
  end process;

  ---------------------------------------------------------------
  -- STALL handling process
  ---------------------------------------------------------------

  Stalls_P : process(Rst, crash_sync, ack_cu_s, SPILL, FILL, fill_delay_s,
                     IR_d, IR_e, IR_E1_MUL, IR_E2_MUL, IR_E3_MUL,
                     IR_E1_ADD, IR_E2_ADD, IR_E3_ADD, IR_m,
                     mul_stages, add_stages, dbg_step, ecp_flush_s,
                     SR_REG_OUT(CPU_MODE), BRANCH_DETECTED)
  begin
    if(Rst = '0') then
      RF_EN <= '0';
	    f_enable_s <= '0';
      d_enable_s <= '0';
      e_enable_s <= '0';
      e_int_en_s <= '0';
      e_mul_en_s <= (others => '0');
      e_add_en_s <= (others => '0');
      m_enable_s <= '0';
      w_enable_s <= '0';
      int_ex_clr <= '0';
      mul_ex_clr <= '0';
      add_ex_clr <= '0';
    elsif crash_sync = '1' then
      RF_EN <= '0';
      f_enable_s <= '0';
      d_enable_s <= '0';
      e_enable_s <= '0';
      e_int_en_s <= '0';
      e_mul_en_s <= (others => '0');
      e_add_en_s <= (others => '0');
      m_enable_s <= '0';
      w_enable_s <= '0';
      int_ex_clr <= '0';
      mul_ex_clr <= '0';
      add_ex_clr <= '0';
    else
      case SR_REG_OUT(CPU_MODE) is
        when SRT_MODE =>
          RF_EN <= '1';
          f_enable_s <= '1';
          d_enable_s <= '1';
          e_enable_s <= '1';
          e_int_en_s <= '1';
          e_mul_en_s <= (others => '0');
          e_add_en_s <= (others => '0');
          m_enable_s <= '1';
          w_enable_s <= '1';
          int_ex_clr <= '0';
          mul_ex_clr <= '0';
          add_ex_clr <= '0';

        when DBG_MODE =>

          if ack_cu_s = '1' then
            RF_EN <= '0';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '0';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '0';
            w_enable_s <= '0';
            int_ex_clr <= '0';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif (IR_d(OPCODE_RANGE) = "110000" or IR_d(OPCODE_RANGE) = "110001") and -- CALL/RET
                ((IR_e(OPCODE_RANGE) /= IR_NULL_VALUE(OPCODE_RANGE)) or (IR_m(OPCODE_RANGE) /= IR_NULL_VALUE(OPCODE_RANGE)) or or_reduce(mul_stages) = '1' or or_reduce(add_stages) = '1') then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '1';
            mul_ex_clr <= '1';
            add_ex_clr <= '1';
          elsif BRANCH_DETECTED = '1' or ecp_flush_s = '1' then
            RF_EN <= '1';
            f_enable_s <= '1';
            d_enable_s <= '1';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '0';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif FILL = '1' or fill_delay_s = '1' or SPILL = '1' then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '1';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '0';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif dbg_step = '1' then
            RF_EN <= '1';
            f_enable_s <= '1';
            d_enable_s <= '1';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '0';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          else
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '1';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '0';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          end if;

          -- multiple exec unit stalls

          -- multiplier stages

          if mul_stages(1) = '1' then
            if not(is_mul_type(IR_d(OPCODE_RANGE), IR_d(FUNC_RANGE))) then
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
            if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E1_MUL(15 downto 11) = IR_d(25 downto 21)) then
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
            if is_ftype(IR_d(OPCODE_RANGE)) and IR_E1_MUL(15 downto 11) = IR_d(20 downto 16) then
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
            if is_store_f(IR_d(OPCODE_RANGE)) and IR_E1_MUL(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
          end if;

          if mul_stages(2) = '1' then
            if not(is_mul_type(IR_d(OPCODE_RANGE), IR_d(FUNC_RANGE))) then
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
            if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E2_MUL(15 downto 11) = IR_d(25 downto 21)) then
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
            if is_ftype(IR_d(OPCODE_RANGE)) and IR_E2_MUL(15 downto 11) = IR_d(20 downto 16) then
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
            if is_store_f(IR_d(OPCODE_RANGE)) and IR_E2_MUL(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
          end if;

          -- adder stages

          if add_stages(1) = '1' then
            if not(is_add_type(IR_d(OPCODE_RANGE), IR_d(FUNC_RANGE))) then
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
            if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E1_ADD(15 downto 11) = IR_d(25 downto 21)) then
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
            if is_ftype(IR_d(OPCODE_RANGE)) and IR_E1_ADD(15 downto 11) = IR_d(20 downto 16) then
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
            if is_store_f(IR_d(OPCODE_RANGE)) and IR_E1_ADD(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
          end if;

          if add_stages(2) = '1' then
            if not(is_add_type(IR_d(OPCODE_RANGE), IR_d(FUNC_RANGE))) then
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
            if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E2_ADD(15 downto 11) = IR_d(25 downto 21)) then
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
            if is_ftype(IR_d(OPCODE_RANGE)) and IR_E2_ADD(15 downto 11) = IR_d(20 downto 16) then
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
            if is_store_f(IR_d(OPCODE_RANGE)) and IR_E2_ADD(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
          end if;

          if add_stages(3) = '1' then
            if not(is_add_type(IR_d(OPCODE_RANGE), IR_d(FUNC_RANGE))) then
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
            if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E3_ADD(15 downto 11) = IR_d(25 downto 21)) then
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
            if is_ftype(IR_d(OPCODE_RANGE)) and IR_E3_ADD(15 downto 11) = IR_d(20 downto 16) then
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
            if is_store_f(IR_d(OPCODE_RANGE)) and IR_E3_ADD(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
          end if;

        when STD_MODE =>

          if ack_cu_s = '1' then
            RF_EN <= '0';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '0';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '0';
            w_enable_s <= '0';
            int_ex_clr <= '0';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif is_load(IR_e(OPCODE_RANGE)) and not is_ftype(IR_d(OPCODE_RANGE)) and not is_f_itype(IR_d(OPCODE_RANGE)) and not is_movfp2i(IR_d(OPCODE_RANGE)) then
            if IR_e(20 downto 16) = IR_d(25 downto 21) then
              RF_EN <= '1';
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '0';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '0';
              add_ex_clr <= '0';
            elsif is_rtype(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then
              RF_EN <= '1';
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '0';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '0';
              add_ex_clr <= '0';
            elsif is_store(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then
              RF_EN <= '1';
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '0';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '0';
              add_ex_clr <= '0';
            elsif is_branch(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(25 downto 21) then
              RF_EN <= '1';
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '0';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '0';
              add_ex_clr <= '0';
            end if;
          elsif is_pp(IR_e(OPCODE_RANGE)) and is_branch(IR_d(OPCODE_RANGE)) and IR_d(25 downto 21) = "11101" then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '1';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif is_rtype(IR_e(OPCODE_RANGE)) and is_branch(IR_d(OPCODE_RANGE)) and IR_d(25 downto 21) = IR_e(15 downto 11) then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '1';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif is_itype(IR_e(OPCODE_RANGE)) and is_branch(IR_d(OPCODE_RANGE)) and IR_d(25 downto 21) = IR_e(20 downto 16) then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '1';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif (IR_e(OPCODE_RANGE)="000011" or IR_e(OPCODE_RANGE)="010011") and is_branch(IR_d(OPCODE_RANGE)) and IR_d(25 downto 21) = "11111" then -- jal or jalr
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '1';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif is_movfp2i(IR_e(OPCODE_RANGE)) and is_branch(IR_d(OPCODE_RANGE)) and IR_d(25 downto 21) = IR_e(20 downto 16) then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '1';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif IR_e(OPCODE_RANGE) = "100110" or IR_e(OPCODE_RANGE) = "101101" then -- LF or POPF
            if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_e(20 downto 16) = IR_d(25 downto 21)) then
              RF_EN <= '1';
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '0';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            elsif is_ftype(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then
              RF_EN <= '1';
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '0';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            elsif is_store_f(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then -- SF or PUSHF
              RF_EN <= '1';
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '0';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
          elsif is_load(IR_m(OPCODE_RANGE)) and is_branch(IR_d(OPCODE_RANGE)) and IR_m(20 downto 16) = IR_d(25 downto 21) then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '1';
            mul_ex_clr <= '1';
            add_ex_clr <= '1';

          elsif (IR_d(OPCODE_RANGE) = "110000" or IR_d(OPCODE_RANGE) = "110001") and  -- CALL / RET
                ((IR_e(OPCODE_RANGE) /= IR_NULL_VALUE(OPCODE_RANGE)) or (IR_m(OPCODE_RANGE) /= IR_NULL_VALUE(OPCODE_RANGE)) or or_reduce(mul_stages) = '1' or or_reduce(add_stages) = '1') then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '1';
            mul_ex_clr <= '1';
            add_ex_clr <= '1';
          elsif FILL = '1' or fill_delay_s = '1' or SPILL = '1' then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '1';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '0';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          else
            RF_EN <= '1';
            f_enable_s <= '1';
            d_enable_s <= '1';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '0';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          end if;

          -- multiple exec unit stalls

          if ecp_flush_s = '0' then

            -- multiplier stages

            if mul_stages(1) = '1' then
              if not(is_mul_type(IR_d(OPCODE_RANGE), IR_d(FUNC_RANGE))) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E1_MUL(15 downto 11) = IR_d(25 downto 21)) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_ftype(IR_d(OPCODE_RANGE)) and IR_E1_MUL(15 downto 11) = IR_d(20 downto 16) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_store_f(IR_d(OPCODE_RANGE)) and IR_E1_MUL(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
            end if;

            if mul_stages(2) = '1' then
              if not(is_mul_type(IR_d(OPCODE_RANGE), IR_d(FUNC_RANGE))) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E2_MUL(15 downto 11) = IR_d(25 downto 21)) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_ftype(IR_d(OPCODE_RANGE)) and IR_E2_MUL(15 downto 11) = IR_d(20 downto 16) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_store_f(IR_d(OPCODE_RANGE)) and IR_E2_MUL(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
            end if;

            -- adder stages

            if add_stages(1) = '1' then
              if not(is_add_type(IR_d(OPCODE_RANGE), IR_d(FUNC_RANGE))) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E1_ADD(15 downto 11) = IR_d(25 downto 21)) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_ftype(IR_d(OPCODE_RANGE)) and IR_E1_ADD(15 downto 11) = IR_d(20 downto 16) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_store_f(IR_d(OPCODE_RANGE)) and IR_E1_ADD(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
            end if;

            if add_stages(2) = '1' then
              if not(is_add_type(IR_d(OPCODE_RANGE), IR_d(FUNC_RANGE))) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E2_ADD(15 downto 11) = IR_d(25 downto 21)) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_ftype(IR_d(OPCODE_RANGE)) and IR_E2_ADD(15 downto 11) = IR_d(20 downto 16) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_store_f(IR_d(OPCODE_RANGE)) and IR_E2_ADD(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
            end if;

            if add_stages(3) = '1' then
              if not(is_add_type(IR_d(OPCODE_RANGE), IR_d(FUNC_RANGE))) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E3_ADD(15 downto 11) = IR_d(25 downto 21)) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_ftype(IR_d(OPCODE_RANGE)) and IR_E3_ADD(15 downto 11) = IR_d(20 downto 16) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_store_f(IR_d(OPCODE_RANGE)) and IR_E3_ADD(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
            end if;
          end if;

        when FST_MODE =>

          if ack_cu_s = '1' then
            RF_EN <= '0';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '0';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '0';
            w_enable_s <= '0';
            int_ex_clr <= '0';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif is_load(IR_e(OPCODE_RANGE)) and not is_ftype(IR_d(OPCODE_RANGE)) and not is_f_itype(IR_d(OPCODE_RANGE)) and not is_movfp2i(IR_d(OPCODE_RANGE)) then
            if IR_e(20 downto 16) = IR_d(25 downto 21) then
              RF_EN <= '1';
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '0';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '0';
              add_ex_clr <= '0';
            elsif is_rtype(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then
              RF_EN <= '1';
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '0';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '0';
              add_ex_clr <= '0';
            elsif is_store(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then
              RF_EN <= '1';
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '0';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '0';
              add_ex_clr <= '0';
            elsif is_branch(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(25 downto 21) then
              RF_EN <= '1';
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '0';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '0';
              add_ex_clr <= '0';
            end if;
          elsif is_pp(IR_e(OPCODE_RANGE)) and is_branch(IR_d(OPCODE_RANGE)) and IR_d(25 downto 21) = "11101" then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '1';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif is_rtype(IR_e(OPCODE_RANGE)) and is_branch(IR_d(OPCODE_RANGE)) and IR_d(25 downto 21) = IR_e(15 downto 11) then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '1';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif is_itype(IR_e(OPCODE_RANGE)) and is_branch(IR_d(OPCODE_RANGE)) and IR_d(25 downto 21) = IR_e(20 downto 16) then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '1';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif (IR_e(OPCODE_RANGE)="000011" or IR_e(OPCODE_RANGE)="010011") and is_branch(IR_d(OPCODE_RANGE)) and IR_d(25 downto 21) = "11111" then -- jal or jalr
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '1';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif is_movfp2i(IR_e(OPCODE_RANGE)) and is_branch(IR_d(OPCODE_RANGE)) and IR_d(25 downto 21) = IR_e(20 downto 16) then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '1';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif IR_e(OPCODE_RANGE) = "100110" or IR_e(OPCODE_RANGE) = "101101" then -- LF or POPF
            if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_e(20 downto 16) = IR_d(25 downto 21)) then
              RF_EN <= '1';
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            elsif is_ftype(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then
              RF_EN <= '1';
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            elsif is_store_f(IR_d(OPCODE_RANGE)) and IR_e(20 downto 16) = IR_d(20 downto 16) then -- SF or PUSHF
              RF_EN <= '1';
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
            end if;
          elsif is_load(IR_m(OPCODE_RANGE)) and is_branch(IR_d(OPCODE_RANGE)) and IR_m(20 downto 16) = IR_d(25 downto 21) then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '1';
            mul_ex_clr <= '1';
            add_ex_clr <= '1';
          elsif (IR_d(OPCODE_RANGE) = "110000" or IR_d(OPCODE_RANGE) = "110001") and -- CALL / RET
                ((IR_e(OPCODE_RANGE) /= IR_NULL_VALUE(OPCODE_RANGE)) or (IR_m(OPCODE_RANGE) /= IR_NULL_VALUE(OPCODE_RANGE)) or or_reduce(mul_stages) = '1' or or_reduce(add_stages) = '1') then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '0';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '1';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          elsif FILL = '1' or fill_delay_s = '1' or SPILL = '1' then
            RF_EN <= '1';
            f_enable_s <= '0';
            d_enable_s <= '1';
            e_enable_s <= '1';
            m_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            w_enable_s <= '1';
            int_ex_clr <= '0';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          else
            RF_EN <= '1';
            f_enable_s <= '1';
            d_enable_s <= '1';
            e_enable_s <= '1';
            e_int_en_s <= '1';
            e_mul_en_s <= (others => '1');
            e_add_en_s <= (others => '1');
            m_enable_s <= '1';
            w_enable_s <= '1';
            int_ex_clr <= '0';
            mul_ex_clr <= '0';
            add_ex_clr <= '0';
          end if;

          -- multiple exec unit stalls

          if ecp_flush_s = '0' then

            -- multiplier stages
            if mul_stages(1) = '1' then
              if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E1_MUL(15 downto 11) = IR_d(25 downto 21)) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_ftype(IR_d(OPCODE_RANGE)) and IR_E1_MUL(15 downto 11) = IR_d(20 downto 16) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_store_f(IR_d(OPCODE_RANGE)) and IR_E1_MUL(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              -- WAW -> current instruction would finish after instruction in decode and destination is the same
              if is_sidf(IR_d(OPCODE_RANGE)) and IR_E1_MUL(15 downto 11) = IR_d(20 downto 16) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
            end if;

            if mul_stages(2) = '1' then
              if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E2_MUL(15 downto 11) = IR_d(25 downto 21)) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_ftype(IR_d(OPCODE_RANGE)) and IR_E2_MUL(15 downto 11) = IR_d(20 downto 16) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_store_f(IR_d(OPCODE_RANGE)) and IR_E2_MUL(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              -- WAW -> current instruction would finish after instruction in decode and destination is the same
              if is_sidf(IR_d(OPCODE_RANGE)) and IR_E2_MUL(15 downto 11) = IR_d(20 downto 16) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
            end if;

            if mul_stages(3) = '1' then
              if IR_e(OPCODE_RANGE) /= IR_NULL_VALUE(OPCODE_RANGE) then
                f_enable_s <= '1';
                d_enable_s <= '1';
                e_enable_s <= '1';
                e_int_en_s <= '0';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '0';
                mul_ex_clr <= '0';
                add_ex_clr <= '0';
                if not(is_ftype(IR_d(OPCODE_RANGE))) then
                  f_enable_s <= '0';
                  d_enable_s <= '0';
                  e_enable_s <= '1';
                  e_int_en_s <= '0';
                  e_mul_en_s <= (others => '1');
                  e_add_en_s <= (others => '1');
                  m_enable_s <= '1';
                  w_enable_s <= '1';
                  int_ex_clr <= '0';
                  mul_ex_clr <= '0';
                  add_ex_clr <= '0';
                end if;
              end if;
            end if;

            -- adder stages

            if add_stages(1) = '1' then
              if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E1_ADD(15 downto 11) = IR_d(25 downto 21)) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_ftype(IR_d(OPCODE_RANGE)) and IR_E1_ADD(15 downto 11) = IR_d(20 downto 16) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_store_f(IR_d(OPCODE_RANGE)) and IR_E1_ADD(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '0';
              add_ex_clr <= '0';
              end if;
              -- WAW -> current instruction would finish after instruction in decode and destination is the same
              if is_sidf(IR_d(OPCODE_RANGE)) and IR_E1_ADD(15 downto 11) = IR_d(20 downto 16) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '0';
                add_ex_clr <= '0';
              elsif is_mul_type(IR_d(OPCODE_RANGE), IR_d(FUNC_RANGE)) and IR_E1_ADD(15 downto 11) = IR_d(15 downto 11) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '0';
                mul_ex_clr <= '1';
                add_ex_clr <= '0';
              end if;
            end if;

            if add_stages(2) = '1' then
              if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E2_ADD(15 downto 11) = IR_d(25 downto 21)) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_ftype(IR_d(OPCODE_RANGE)) and IR_E2_ADD(15 downto 11) = IR_d(20 downto 16) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_store_f(IR_d(OPCODE_RANGE)) and IR_E2_ADD(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
              end if;
              -- WAW -> current instruction would finish after instruction in decode and destination is the same
              if is_sidf(IR_d(OPCODE_RANGE)) and IR_E2_ADD(15 downto 11) = IR_d(20 downto 16) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '0';
                add_ex_clr <= '0';
              elsif is_mul_type(IR_d(OPCODE_RANGE), IR_d(FUNC_RANGE)) and IR_E2_ADD(15 downto 11) = IR_d(15 downto 11) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '0';
                mul_ex_clr <= '1';
                add_ex_clr <= '0';
              end if;
            end if;

            if add_stages(3) = '1' then
              if (is_ftype(IR_d(OPCODE_RANGE)) or is_f_itype(IR_d(OPCODE_RANGE)) or is_movfp2i(IR_d(OPCODE_RANGE))) and (IR_E3_ADD(15 downto 11) = IR_d(25 downto 21)) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_ftype(IR_d(OPCODE_RANGE)) and IR_E3_ADD(15 downto 11) = IR_d(20 downto 16) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '1';
                e_mul_en_s <= (others => '1');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '1';
                mul_ex_clr <= '1';
                add_ex_clr <= '1';
              end if;
              if is_store_f(IR_d(OPCODE_RANGE)) and IR_E3_ADD(15 downto 11) = IR_d(20 downto 16) then -- SF or PUSHF
              f_enable_s <= '0';
              d_enable_s <= '0';
              e_enable_s <= '1';
              e_int_en_s <= '1';
              e_mul_en_s <= (others => '1');
              e_add_en_s <= (others => '1');
              m_enable_s <= '1';
              w_enable_s <= '1';
              int_ex_clr <= '1';
              mul_ex_clr <= '1';
              add_ex_clr <= '1';
              end if;
            end if;

            if add_stages(4) = '1' then
              if (IR_E3_MUL(OPCODE_RANGE) /= IR_NULL_VALUE(OPCODE_RANGE)) or (IR_e(OPCODE_RANGE) /= IR_NULL_VALUE(OPCODE_RANGE)) then
                f_enable_s <= '0';
                d_enable_s <= '0';
                e_enable_s <= '1';
                e_int_en_s <= '0';
                e_mul_en_s <= (others => '0');
                e_add_en_s <= (others => '1');
                m_enable_s <= '1';
                w_enable_s <= '1';
                int_ex_clr <= '0';
                mul_ex_clr <= '0';
                add_ex_clr <= '0';
              end if;
            end if;
          end if;

        when others =>
          null;
      end case;
    end if;
  end process;

  ---------------------------------------------------------------
  --exception cause processes
  ---------------------------------------------------------------

  -- exception cause in fetch stage

  ecp_cause_fetch_p : process(iram_misaligned_s, iram_reserved_s)
  begin
    if iram_misaligned_s = '1' then
      ecp_cause_fd_in <= ecp_codes(exceptionCode'pos(IRM_ECP)); -- misaligned iram exception code
    elsif iram_reserved_s = '1' then
      ecp_cause_fd_in <= ecp_codes(exceptionCode'pos(IRR_ECP)); -- reserved iram exception code
    else
      ecp_cause_fd_in <= ecp_codes(exceptionCode'pos(NO_ECP));
    end if;
  end process;

  -- exception cause in decode stage

  ecp_cause_decode_p : process(ecp_cause_fd_out, ecp_invalid_op)
  begin
    if ecp_invalid_op = '1' then
      ecp_cause_de_in <= ecp_codes(exceptionCode'pos(IOP_ECP)); -- invalid op exception code
    else
      ecp_cause_de_in <= ecp_cause_fd_out;
    end if;
  end process;

  -- exception cause in execution stage

  ecp_cause_execution_p : process(ecp_cause_de_out, ALU_OVF, ALU_UFL, ALU_INVALID_CONV, SR_REG_OUT(ECP_ARITH))
  begin
    ecp_cause_em_in <= ecp_cause_de_out;

    if SR_REG_OUT(ECP_ARITH) = '1' then
      if ALU_OVF = '1' then
        ecp_cause_em_in <= ecp_codes(exceptionCode'pos(OVF_ECP)); -- arith overflow exception code
      elsif ALU_UFL = '1' then
        ecp_cause_em_in <= ecp_codes(exceptionCode'pos(UFL_ECP)); -- arith underflow exception code
      elsif ALU_INVALID_CONV = '1' then
        ecp_cause_em_in <= ecp_codes(exceptionCode'pos(INV_CON_ECP)); -- arith underflow exception code
      end if;
    end if;
  end process;

  -- exception detection

  ecp_detect_p : process(ecp_cause_em_out, irq_detected_s, dram_misaligned_s, dram_reserved_s, ecp_lock_n, IR_m, SR_REG_OUT(ECP_EN))
  begin
    EPC_EN  <= '0';
    ecp_flush_s <= '0';
    call_rollback_s <= '0';
    ret_rollback_s <= '0';
    ecp_cause_s <= ecp_codes(exceptionCode'pos(NO_ECP));
    if SR_REG_OUT(ECP_EN) = '1' then
      ecp_cause_s <= ecp_cause_em_out;
      if ecp_lock_n = '1' then
        if irq_detected_s = '1' then   -- interrupt handling
          EPC_EN <= '1';
          ecp_flush_s <= '1';
          call_rollback_s <= '0';
          ret_rollback_s <= '0';
          ecp_cause_s <= ecp_codes(exceptionCode'pos(IRQ_ECP)); -- interrupt request
          if IR_m(OPCODE_RANGE) = std_logic_vector(to_unsigned(48, OPCODE_SIZE)) then --exception on CALL
            call_rollback_s <= '1';
          elsif IR_m(OPCODE_RANGE) = std_logic_vector(to_unsigned(49, OPCODE_SIZE)) then --exception on RET
            ret_rollback_s <= '1';
          end if;
        elsif dram_misaligned_s = '1' then
          EPC_EN  <= '1';
          ecp_flush_s <= '1';
          call_rollback_s <= '0';
          ret_rollback_s <= '0';
          ecp_cause_s <= ecp_codes(exceptionCode'pos(DRM_ECP)); -- misaligned dram exception code
          if IR_m(OPCODE_RANGE) = std_logic_vector(to_unsigned(48, OPCODE_SIZE)) then --exception on CALL
            call_rollback_s <= '1';
          elsif IR_m(OPCODE_RANGE) = std_logic_vector(to_unsigned(49, OPCODE_SIZE)) then --exception on RET
            ret_rollback_s <= '1';
          end if;
        elsif dram_reserved_s = '1' then
          EPC_EN  <= '1';
          ecp_flush_s <= '1';
          call_rollback_s <= '0';
          ret_rollback_s <= '0';
          ecp_cause_s <= ecp_codes(exceptionCode'pos(DRR_ECP)); -- reserved dram exception code
          if IR_m(OPCODE_RANGE) = std_logic_vector(to_unsigned(48, OPCODE_SIZE)) then --exception on CALL
            call_rollback_s <= '1';
          elsif IR_m(OPCODE_RANGE) = std_logic_vector(to_unsigned(49, OPCODE_SIZE)) then --exception on RET
            ret_rollback_s <= '1';
          end if;
        elsif ecp_cause_em_out /= ecp_codes(exceptionCode'pos(NO_ECP)) then
          EPC_EN  <= '1';
          ecp_flush_s <= '1';
          call_rollback_s <= '0';
          ret_rollback_s <= '0';
          ecp_cause_s <= ecp_cause_em_out;
          if IR_m(OPCODE_RANGE) = std_logic_vector(to_unsigned(48, OPCODE_SIZE)) then --exception on CALL
            call_rollback_s <= '1';
          elsif IR_m(OPCODE_RANGE) = std_logic_vector(to_unsigned(49, OPCODE_SIZE)) then --exception on RET
            ret_rollback_s <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- STATUS register

  status_register_in_p : process(interrupt_in_s, alu_ovf_delay, alu_ufl_delay, alu_carry_delay, alu_zero_delay, alu_inv_delay,
                                 SR_REG_OUT, ecp_lock_n)
  begin
    sr_reg_in_s(CPU_MODE) <= SR_REG_OUT(CPU_MODE);
    sr_reg_in_s(STACK_FLAG) <= SR_REG_OUT(STACK_FLAG);
    sr_reg_in_s(IRAM_FLAG) <= ecp_lock_n;
    sr_reg_in_s(ECP_LOCK) <= not(ecp_lock_n);
    sr_reg_in_s(BRANCH_DELAY_SLOT) <= SR_REG_OUT(BRANCH_DELAY_SLOT);
    sr_reg_in_s(ECP_MODE) <= SR_REG_OUT(ECP_MODE);
    sr_reg_in_s(IRQ_ARRAY) <= interrupt_in_s;            -- irq line
    sr_reg_in_s(OVF_FLAG) <= alu_ovf_delay;
    sr_reg_in_s(UFL_FLAG) <= alu_ufl_delay;
    sr_reg_in_s(CARRY_FLAG) <= alu_carry_delay;
    sr_reg_in_s(ZERO_FLAG) <= alu_zero_delay;
    sr_reg_in_s(INV_FLAG) <= alu_inv_delay;
    sr_reg_in_s(Nbit-1 downto INV_FLAG+1) <= SR_REG_OUT(Nbit-1 downto INV_FLAG+1);
  end process;

  --SPILL delay

  spill_delay_p : process(Clk, Rst)
  begin
    if Rst = '0' then
      spill_delay_1 <= '0';
      spill_delay_2 <= '0';
      spill_delay_3 <= '0';
      spill_delay_4 <= '0';
    elsif Clk'event and Clk = '1' then
      if (d_enable_s = '1') then
        spill_delay_1 <= SPILL;
        spill_delay_2 <= spill_delay_1;
        spill_delay_3 <= spill_delay_2;
        spill_delay_4 <= spill_delay_3;
      end if;
    end if;
  end process;

  --FILL delay

  fill_delay_p : process(Clk, Rst)
  begin
    if Rst = '0' then
      fill_delay_1 <= '0';
      fill_delay_2 <= '0';
      fill_delay_3 <= '0';
      fill_delay_4 <= '0';
    elsif Clk'event and Clk = '1' then
      if (d_enable_s = '1') then
        fill_delay_1 <= FILL;
        fill_delay_2 <= fill_delay_1;
        fill_delay_3 <= fill_delay_2;
        fill_delay_4 <= fill_delay_3;
      end if;
    end if;
  end process;

end dlx_cu_hw;

configuration CFG_CU of dlx_cu is
  for dlx_cu_hw
    for all : REG
      use configuration WORK.CFG_REG_ASYNC;
    end for;
  end for;

end CFG_CU;
