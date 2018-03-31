library ieee;
use ieee.std_logic_1164.all;
use work.DLX_package.all;
use ieee.numeric_std.all;

entity DLX_fs is
  port (
    Clk                 : in  std_logic;
    Rst                 : in  std_logic;                -- Active Low
    Irq_line            : in  std_logic_vector(7 downto 0);
    DBG                 : IN std_logic;
    Crash               : out std_logic;
    Ack_line            : out std_logic_vector(7 downto 0);
    --IRAM
    IRAM_Dout           : in std_logic_vector(Nbit - 1 downto 0);
    IRAM_Address        : out std_logic_vector(Nbit - 1 downto 0);
    IRAM_Enable         : out std_logic;
    --DRAM
    DRAM_Data_out       : in std_logic_vector(Nbit-1 DOWNTO 0);
    DRAM_Address        : out std_logic_vector(Nbit-1 DOWNTO 0);
    DRAM_CS             : out std_logic;
    DRAM_RD_WR          : out std_logic_vector(1 downto 0); -- 00 -> read; 01 -> write word; 10 -> write half w; 11 -> write byte
    DRAM_Data_in        : out std_logic_vector(Nbit-1 DOWNTO 0)
  );
end DLX_fs;

architecture dlx_rtl of DLX_fs is
--------------------------------------------------------------------
-- Components Declaration
--------------------------------------------------------------------
COMPONENT dlx_cu is
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

    IR_CLEAR_D         : out std_logic;  -- Clear to IR
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
  END COMPONENT;


  component DataPath
    PORT (
      Clk               : IN std_logic;
      Rst               : IN std_logic;

      -- enable signals
      FETCH_EN          : IN std_logic;
      DECODE_EN         : IN std_logic;
      EXECUTION_EN      : IN std_logic;
      E_INT_EN          : IN std_logic;
      E_MUL_EN          : IN std_logic_vector(1 to MULT_PIPE_LENGTH);
      E_ADD_EN          : IN std_logic_vector(1 to FP_ADD_PIPE_LENGTH);
      MEMORY_EN         : IN std_logic;
      WRITEBACK_EN      : IN std_logic;

      -- IR forwarding
      IR_i              : OUT std_logic_vector(Nbit-1 downto 0); -- Input to IR
      IR_d              : OUT std_logic_vector(Nbit-1 downto 0); -- IR output
      IR_e              : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX stage)
      IR_E1_MUL         : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX first stage mult)
      IR_E2_MUL         : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX second stage mult)
      IR_E3_MUL         : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX third stage mult)
      IR_E1_ADD         : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX first stage add)
      IR_E2_ADD         : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX second stage add)
      IR_E3_ADD         : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX third stage add)
      IR_E4_ADD         : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (EX fourth stage add)
      IR_m              : OUT std_logic_vector(Nbit-1 downto 0); -- IR output delayed (MEM stage)

      IR_CLEAR_D        : IN std_logic;  -- Clear to IR
      IR_CLEAR_E        : IN std_logic;  -- Clear to exec stage
      IR_CLEAR_M        : IN std_logic;  -- Clear to memory stage
      IR_CLEAR_W        : IN std_logic;  -- Clear to writeback stage
      IR_CLEAR_EX_INT   : IN std_logic;  -- Reset to execution IR register
      IR_CLEAR_EX_MUL   : IN std_logic;  -- Reset to first mul execution IR Register
      IR_CLEAR_EX_ADD   : IN std_logic;  -- Reset to first add execution IR Register

      ALU_OUT_SEL       : IN std_logic_vector(1 downto 0); -- It selects the correct execution unit to be connected to memory stage

      -- muxes
      IR_MUX_SEL        : IN std_logic_vector(1 downto 0); --IR Mux input
      SR_MUX_SEL        : IN std_logic;                    --SR Mux selection
      BRANCH_OUT        : OUT std_logic;
      JUMP_MUX_SEL      : IN  std_logic_vector(2 downto 0);

      -- forwarding muxes
      BR_FWD_MUX_SEL    : IN std_logic_vector(1 downto 0); --branch forwarding
      ST_FWD_MUX_SEL    : IN std_logic_vector(2 downto 0); --stall forwarding

      -- control signals

      -- stage 1
      FP_INTn_RD1       : IN std_logic;
      FP_INTn_RD2       : IN std_logic;
      RF_EN             : IN std_logic;
      MUX_IMM_SEL       : IN std_logic;
      -- stage 2
      MUX_A_SEL         : IN std_logic_vector(2 downto 0);
      MUX_B_SEL         : IN std_logic_vector(2 downto 0);
      PUSH_POP_MUX_SEL  : IN std_logic;
      -- stage 3
      LOAD_MUX_SEL      : IN std_logic_vector(2 downto 0);
      WR_MUX_SEL        : IN std_logic_vector(1 downto 0);  --Destination Register mux select
      -- stage 4
      RF_WE             : IN std_logic;
      FP_INTn_WR        : IN std_logic;
      WB_MUX_SEL        : IN std_logic;
      RF_WE_SP          : IN std_logic;

      -- opcodes
      ALU_OPCODE        : IN aluOp;
      BRANCH_OP         : IN branchOp;

      -- RF signals
      RF_WE_SR          : IN std_logic;

      -- ALU overflow/underflow
      ALU_OVF           : OUT std_logic;
      ALU_UFL           : OUT std_logic;
      ALU_INVALID_CONV  : OUT std_logic;
      ALU_CARRY         : OUT std_logic;
      ALU_ZERO          : OUT std_logic;

      -- exception handling
      EPC_EN            : IN  std_logic;    -- exception program counter wr en
      ECP_CODE          : IN exceptionCode; -- exception code to select jump address
      IRQ_CODE          : IN irqCode;       -- irq code to select jump address

      -- control and status registers
      CR_REG_OUT        : OUT std_logic_vector(Nbit-1 downto 0);
      SR_REG_OUT        : OUT std_logic_vector(Nbit-1 downto 0);
      SR_REG_IN         : IN  std_logic_vector(Nbit-1 downto 0);

      --ram signals
      IRAM_in	          : OUT std_logic_vector(Nbit-1 downto 0);
      IRAM_out	        : IN  std_logic_vector(Nbit-1 downto 0);
      DRAM_ADDRESS      : OUT std_logic_vector(Nbit-1 downto 0);
      DRAM_in           : OUT std_logic_vector(Nbit-1 downto 0);
      DRAM_out          : IN  std_logic_vector(Nbit-1 downto 0);

      -- DMA
      CWP               : IN unsigned(up_int_log2(N_windows)-1 downto 0);
      DMA_OUT           : IN std_logic_vector(Nbit-1 downto 0)
      );
  end component;

  component DMA
      GENERIC(N_bit : integer := 64;         --Number of bits
              M : integer := 8;              -- Number of global registers
              N : integer := 8;              -- Number of registers in each IN, OUT and LOCALS
              F : integer := 4);             -- Number of windows
      PORT(
        RESET_N           : IN std_logic;
        CLK               : IN std_logic;
        CALL              : IN std_logic;
        RET               : IN std_logic;
        CALL_ROLLBACK     : IN std_logic;
        RET_ROLLBACK      : IN std_logic;
        CWP_ENABLE        : IN std_logic;
        SPILL             : OUT std_logic;
        FILL              : OUT std_logic;
        CWP               : OUT unsigned(up_int_log2(F)-1 downto 0);
        DATA_OUT          : OUT std_logic_vector(Nbit-1 downto 0));
  end component;


----------------------------------------------------------------
-- Constants Declaration
----------------------------------------------------------------
constant  MICROCODE_MEM_SIZE_C  : integer := 64;
constant  FUNC_SIZE_C           : integer := 11;  -- Func Field Size for R-Type Ops
constant  OP_CODE_SIZE_C        : integer := 6;  -- Op Code Size
--constant   ALU_OPC_SIZE_C     : integer := 6;  -- ALU Op Code Word Size
constant  IR_SIZE_C             : integer := 32;  -- Instruction Register Size

----------------------------------------------------------------
-- Signals Declaration
----------------------------------------------------------------
-- rf signals
signal rf_en_s                      : std_logic;
signal rf_we_s                      : std_logic;
signal rf_we_sp_s                   : std_logic;
signal rf_we_sr_s                   : std_logic;
signal cr_reg_out_s                 : std_logic_vector(Nbit-1 downto 0);
signal sr_reg_out_s                 : std_logic_vector(Nbit-1 downto 0);
signal sr_reg_in_s                  : std_logic_vector(Nbit-1 downto 0);
--mux signals
signal wr_mux_sel_s                 : std_logic_vector(1 downto 0);
signal mux_imm_sel_s                : std_logic;
signal mux_a_sel_s                  : std_logic_vector(2 downto 0);
signal mux_b_sel_s                  : std_logic_vector(2 downto 0);
signal wb_mux_sel_s                 : std_logic;
signal sr_mux_sel_s                 : std_logic;
signal load_mux_sel_s               : std_logic_vector(2 downto 0);
--alu and branch signals
signal alu_op_s                     : aluOp;
signal branch_op_s                  : branchOp;
signal branch_out_s                 : std_logic;
signal jump_mux_sel_s               : std_logic_vector(2 downto 0);
--enable signals
signal fetch_en_s                   : std_logic;
signal decode_en_s                  : std_logic;
signal execution_en_s               : std_logic;
signal e_int_en_s                   : std_logic;
signal e_mul_en_s                   : std_logic_vector(1 to MULT_PIPE_LENGTH);
signal e_add_en_s                   : std_logic_vector(1 to FP_ADD_PIPE_LENGTH);
signal memory_en_s                  : std_logic;
signal write_back_en_s              : std_logic;
--IR signals
signal IR_i_s         : std_logic_vector(Nbit -1 downto 0);
signal IR_d_s         : std_logic_vector(Nbit -1 downto 0);
signal IR_e_s         : std_logic_vector(Nbit -1 downto 0);
signal IR_e1_mul_s    : std_logic_vector(Nbit -1 downto 0);
signal IR_e2_mul_s    : std_logic_vector(Nbit -1 downto 0);
signal IR_e3_mul_s    : std_logic_vector(Nbit -1 downto 0);
signal IR_e1_add_s    : std_logic_vector(Nbit -1 downto 0);
signal IR_e2_add_s    : std_logic_vector(Nbit -1 downto 0);
signal IR_e3_add_s    : std_logic_vector(Nbit -1 downto 0);
signal IR_e4_add_s    : std_logic_vector(Nbit -1 downto 0);
signal IR_m_s         : std_logic_vector(Nbit -1 downto 0);
signal ir_mux_sel_s   : std_logic_vector(1 downto 0);
--IR reset signals
signal ir_clear_d_s      : std_logic;
signal ir_clear_e_s      : std_logic;
signal ir_clear_m_s      : std_logic;
signal ir_clear_w_s      : std_logic;
signal ir_clear_ex_int_s : std_logic;
signal ir_clear_ex_mul_s : std_logic;
signal ir_clear_ex_add_s : std_logic;
--ALU out select
signal alu_out_sel_s     : std_logic_vector(1 downto 0);
--exceptions signals
signal alu_ovf_s                    : std_logic;
signal alu_ufl_s                    : std_logic;
signal alu_invalid_conv_s           : std_logic;
signal alu_carry_s                  : std_logic;
signal alu_zero_s                   : std_logic;
signal epc_en_s                     : std_logic;
signal ecp_code_s                   : exceptionCode;
signal irq_code_s                   : irqCode;
--iram signals
signal iram_in_s                    : std_logic_vector (Nbit-1 downto 0);
signal iram_out_s                   : std_logic_vector (Nbit-1 downto 0);
signal iram_en_s                    : std_logic;
--dram signals
signal dram_addr_s                  : std_logic_vector (Nbit-1 downto 0);
--branch and store forwarding signals
signal br_fwd_mux_sel_s             : std_logic_vector(1 downto 0);
signal st_fwd_mux_sel_s             : std_logic_vector(2 downto 0);
--push pop signals
signal push_pop_mux_sel_s           : std_logic;
--call/ret signals
signal spill_s                      : std_logic;
signal fill_s                       : std_logic;
signal call_s                       : std_logic;
signal ret_s                        : std_logic;
signal call_rollback_s              : std_logic;
signal ret_rollback_s               : std_logic;
signal cwp_enable_s                 : std_logic;
signal cwp_s                        : unsigned(up_int_log2(N_windows)-1 downto 0);
signal dma_out_s                    : std_logic_vector(Nbit-1 downto 0);
--FP signals
signal fp_intn_rd1_s                : std_logic;
signal fp_intn_rd2_s                : std_logic;
signal fp_intn_wr_s                 : std_logic;

for control_unit : dlx_cu use configuration WORK.CFG_CU;
for data_path : DataPath use configuration WORK.CFG_DP_Structural;

begin

----------------------------------------------------------------
-- direct assignents
----------------------------------------------------------------

IRAM_Address      <= iram_in_s;
DRAM_Address      <= dram_addr_s;

----------------------------------------------------------------
-- component instantiation
----------------------------------------------------------------

control_unit : dlx_cu
  port map (
    Clk               => clk,
    Rst               => rst,
    DBG               => DBG,
    CRASH             => Crash,

    FETCH_EN          => fetch_en_s,
    DECODE_EN         => decode_en_s,
    EXECUTION_EN      => execution_en_s,
    E_INT_EN          => e_int_en_s,
    E_MUL_EN          => e_mul_en_s,
    E_ADD_EN          => e_add_en_s,
    MEMORY_EN         => memory_en_s,
    WRITEBACK_EN      => write_back_en_s,

    PC                => iram_in_s,
    IR_IN             => IR_i_s,
    IR_d              => IR_d_s,
    IR_e              => IR_e_s,
    IR_E1_MUL         => IR_e1_mul_s,
    IR_E2_MUL         => IR_e2_mul_s,
    IR_E3_MUL         => IR_e3_mul_s,
    IR_E1_ADD         => ir_e1_add_s,
    IR_E2_ADD         => ir_e2_add_s,
    IR_E3_ADD         => ir_e3_add_s,
    IR_E4_ADD         => ir_e4_add_s,
    IR_m              => IR_m_s,

    IR_CLEAR_D        => ir_clear_d_s,
    IR_CLEAR_E        => ir_clear_e_s,
    IR_CLEAR_M        => ir_clear_m_s,
    IR_CLEAR_W        => ir_clear_w_s,
    IR_CLEAR_EX_INT   => ir_clear_ex_int_s,
    IR_CLEAR_EX_MUL   => ir_clear_ex_mul_s,
    IR_CLEAR_EX_ADD   => ir_clear_ex_add_s,

    ALU_OUT_SEL       => alu_out_sel_s,

    IR_MUX_SEL        => ir_mux_sel_s,
    SR_MUX_SEL        => sr_mux_sel_s,
    BRANCH_DETECTED   => branch_out_s,
    JUMP_MUX_SEL      => jump_mux_sel_s,

    BR_FWD_MUX_SEL    => br_fwd_mux_sel_s,
    ST_FWD_MUX_SEL    => st_fwd_mux_sel_s,

    FP_INTn_RD1       => fp_intn_rd1_s,
    FP_INTn_RD2       => fp_intn_rd2_s,
    RF_EN             => rf_en_s,
    MUX_IMM_SEL      => mux_imm_sel_s,

    MUXA_SEL          => mux_a_sel_s,
    MUXB_SEL          => mux_b_sel_s,
    PUSH_POP_MUX_SEL  => push_pop_mux_sel_s,

    DRAM_CS           => DRAM_CS,
    DRAM_R_W          => DRAM_RD_WR,
    LOAD_MUX_SEL      => load_mux_sel_s,
    WR_MUX_SEL        => wr_mux_sel_s,

    RF_WE             => rf_we_s,
    FP_INTn_WR        => fp_intn_wr_s,
    WB_MUX_SEL        => wb_mux_sel_s,
    RF_WE_SP          => rf_we_sp_s,

    ALU_OP            => alu_op_s,
    BRANCH_OP         => branch_op_s,

    RF_WE_SR          => rf_we_sr_s,

    ALU_OVF           => alu_ovf_s,
    ALU_UFL           => alu_ufl_s,
    ALU_INVALID_CONV  => alu_invalid_conv_s,
    ALU_CARRY         => alu_carry_s,
    ALU_ZERO          => alu_zero_s,

    EPC_EN            => epc_en_s,
    ECP_CODE          => ecp_code_s,
    IRQ_CODE          => irq_code_s,

    CR_REG_OUT        => cr_reg_out_s,
    SR_REG_OUT        => sr_reg_out_s,
    SR_REG_IN         => sr_reg_in_s,

    INTERRUPT_LINE    => Irq_line,
    ACK_LINE          => Ack_line,

    IRAM_EN           => IRAM_Enable,
    DRAM_ADDRESS      => dram_addr_s,

    SPILL             => spill_s,
    FILL              => fill_s,
    CALL              => call_s,
    RET               => ret_s,
    CALL_ROLLBACK     => call_rollback_s,
    RET_ROLLBACK      => ret_rollback_s,
    CWP_ENABLE        => cwp_enable_s
    );


data_path : DataPath
  port map (
    Clk               =>   clk,
    Rst               =>   rst,

    FETCH_EN          =>   fetch_en_s,
    DECODE_EN         =>   decode_en_s,
    EXECUTION_EN      =>   execution_en_s,
    E_INT_EN          =>   e_int_en_s,
    E_MUL_EN          =>   e_mul_en_s,
    E_ADD_EN          =>   e_add_en_s,
    MEMORY_EN         =>   memory_en_s,
    WRITEBACK_EN      =>   write_back_en_s,

    IR_i              =>   IR_i_s,
    IR_d              =>   IR_d_s,
    IR_e              =>   IR_e_s,
    IR_E1_MUL         =>   IR_e1_mul_s,
    IR_E2_MUL         =>   IR_e2_mul_s,
    IR_E3_MUL         =>   IR_e3_mul_s,
    IR_E1_ADD         =>   ir_e1_add_s,
    IR_E2_ADD         =>   ir_e2_add_s,
    IR_E3_ADD         =>   ir_e3_add_s,
    IR_E4_ADD         =>   ir_e4_add_s,
    IR_m              =>   IR_m_s,

    IR_CLEAR_D        =>   ir_clear_d_s,
    IR_CLEAR_E        =>   ir_clear_e_s,
    IR_CLEAR_M        =>   ir_clear_m_s,
    IR_CLEAR_W        =>   ir_clear_w_s,
    IR_CLEAR_EX_INT   =>   ir_clear_ex_int_s,
    IR_CLEAR_EX_MUL   =>   ir_clear_ex_mul_s,
    IR_CLEAR_EX_ADD   =>   ir_clear_ex_add_s,

    ALU_OUT_SEL       =>   alu_out_sel_s,

    IR_MUX_SEL        =>   ir_mux_sel_s,
    SR_MUX_SEL        =>   sr_mux_sel_s,
    BRANCH_OUT        =>   branch_out_s,
    JUMP_MUX_SEL      =>   jump_mux_sel_s,

    BR_FWD_MUX_SEL    =>   br_fwd_mux_sel_s,
    ST_FWD_MUX_SEL    =>   st_fwd_mux_sel_s,

    FP_INTn_RD1       =>   fp_intn_rd1_s,
    FP_INTn_RD2       =>   fp_intn_rd2_s,
    RF_EN             =>   rf_en_s,
    MUX_IMM_SEL       =>   mux_imm_sel_s,

    MUX_A_SEL         =>   mux_a_sel_s,
    MUX_B_SEL         =>   mux_b_sel_s,
    PUSH_POP_MUX_SEL  =>   push_pop_mux_sel_s,

    LOAD_MUX_SEL      =>   load_mux_sel_s,
    WR_MUX_SEL        =>   wr_mux_sel_s,

    RF_WE             =>   rf_we_s,
    FP_INTn_WR        =>   fp_intn_wr_s,
    WB_MUX_SEL        =>   wb_mux_sel_s,
    RF_WE_SP          =>   rf_we_sp_s,

    ALU_OPCODE        =>   alu_op_s,
    BRANCH_OP         =>   branch_op_s,

    RF_WE_SR          =>   rf_we_sr_s,

    ALU_OVF           =>   alu_ovf_s,
    ALU_UFL           =>   alu_ufl_s,
    ALU_INVALID_CONV  =>   alu_invalid_conv_s,
    ALU_CARRY         =>   alu_carry_s,
    ALU_ZERO          =>   alu_zero_s,

    EPC_EN            =>   epc_en_s,
    ECP_CODE          =>   ecp_code_s,
    IRQ_CODE          =>   irq_code_s,

    CR_REG_OUT        =>   cr_reg_out_s,
    SR_REG_OUT        =>   sr_reg_out_s,
    SR_REG_IN         =>   sr_reg_in_s,

    IRAM_in           =>   iram_in_s,
    IRAM_out          =>   IRAM_Dout,
    DRAM_ADDRESS      =>   dram_addr_s,
    DRAM_in           =>   DRAM_Data_in,
    DRAM_out          =>   DRAM_Data_out,

    CWP               =>   cwp_s,
    DMA_OUT           =>   dma_out_s
  );

  DMA_c : DMA
    generic map(Nbit, in_local_out_width, N_globals, N_windows)
      port map(
        RESET_N           => rst,
        CLK               => clk,
        CALL              => call_s,
        RET               => ret_s,
        CALL_ROLLBACK     => call_rollback_s,
        RET_ROLLBACK      => ret_rollback_s,
        CWP_ENABLE        => cwp_enable_s,
        SPILL             => spill_s,
        FILL              => fill_s,
        CWP               => cwp_s,
        DATA_OUT          => dma_out_s
      );

end architecture;
