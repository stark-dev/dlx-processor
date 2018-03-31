library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package DLX_package is

  --constants
  constant Nbit : integer := 32;  --Number of bits of the architecture
  constant Nreg : integer := 32;  --Number of registers in the RF

  constant N_globals : integer := 8;              -- Number of global registers
  constant in_local_out_width : integer := 8;     -- Number of registers in each IN, OUT and LOCALS
  constant N_windows  : integer := 4;             -- Number of windows

  constant MICROCODE_MEM_SIZE : integer := 64;    -- Microcode Memory Size
  constant CW_SIZE            : integer := 22;    -- Size of the Control Word
  constant IRAM_DEPTH         : integer := 256;    -- Number of lines in the IRAM
  constant DRAM_DEPTH         : natural := 4096;  -- Number of lines in the DRAM
  constant OPCODE_SIZE        : integer := 6;     --OPCODE Size
  constant FUNC_SIZE          : integer := 11;    --Func Field Size for R-Type Ops
  constant STACK_DEPTH        : integer := 512;
  constant CONFIG_ADDRESS     : integer := 0;
  constant R0_ADDRESS         : integer := 4;
  constant R1_ADDRESS         : integer := 20;
  constant R2_ADDRESS         : integer := 36;
  constant R3_ADDRESS         : integer := 52;
  constant R4_ADDRESS         : integer := 68;
  constant R5_ADDRESS         : integer := 84;
  constant R6_ADDRESS         : integer := 100;
  constant R7_ADDRESS         : integer := 116;
  constant R8_ADDRESS         : integer := 132;
  constant R9_ADDRESS         : integer := 148;
  constant TEXT_ADDRESS       : integer := 164;

  constant DRAM_FILE_PATH      : string := "dump.mem";
  constant DRAM_FILE_PATH_INIT : string := "data.mem";
  constant IRAM_FILE_PATH      : string  := "iram.mem";

  constant INTEGER_PIPE_LENGTH : integer := 1; -- number of execution stages inside the integer pipe
  constant MULT_PIPE_LENGTH    : integer := 3; -- number of execution stages inside the multiplier pipe
  constant FP_ADD_PIPE_LENGTH  : integer := 4; -- number of execution stages inside the fp adder pipe

  constant DBG_DELAY_COUNTER_N : integer := 2; -- number of bits of dbg delay counter

  function log2 (X : positive)  return natural;  -- Y = log2(X)
  function up_int_log2 (X : positive) return natural;  -- log2 rounded to upper int
  function and_reduce(datain : std_logic_vector) return std_logic;
  function or_reduce(datain : std_logic_vector) return std_logic;
  function is_rtype(opcode : std_logic_vector) return boolean;
  function is_ftype(opcode : std_logic_vector) return boolean;
  function is_nop(opcode : std_logic_vector) return boolean;
  function is_null(opcode : std_logic_vector) return boolean;
  function is_mul_type(opcode : std_logic_vector; func : std_logic_vector) return boolean;
  function is_add_type(opcode : std_logic_vector; func : std_logic_vector) return boolean;
  function is_jtype(opcode : std_logic_vector) return boolean;
  function is_movfp2i(opcode : std_logic_vector) return boolean;
  function is_sidf(opcode : std_logic_vector) return boolean;
  function is_pp(opcode : std_logic_vector) return boolean;
  function is_load(opcode : std_logic_vector(OPCODE_SIZE-1 downto 0)) return boolean;
  function is_itype(opcode : std_logic_vector) return boolean;
  function is_f_itype(opcode : std_logic_vector) return boolean;
  function is_branch(opcode : std_logic_vector(OPCODE_SIZE-1 downto 0)) return boolean;
  function is_store(opcode : std_logic_vector(OPCODE_SIZE-1 downto 0)) return boolean;
  function is_store_f(opcode : std_logic_vector(OPCODE_SIZE-1 downto 0)) return boolean;
  function is_valid(opcode : std_logic_vector(OPCODE_SIZE-1 downto 0)) return boolean;



  type aluOp is (
    NOP_OP, ADD_OP, ADDU_OP,	SUB_OP, SUBU_OP, AND_OP,	OR_OP,	XOR_OP,	SGE_OP,	SLE_OP,	SLEU_OP, SLL_OP,	SNE_OP,
    SRL_OP, SRA_OP, SGEU_OP, SGT_OP, SGTU_OP, SLT_OP, SLTU_OP, SEQ_OP, LHI_OP, MOV_OP, FP2I_OP, I2FP_OP, MULT_OP, MULTU_OP, MULTF_OP, ADDF_OP, SUBF_OP
  );

  type branchOp is (
    NOBRANCH, BNEZ, BEQZ, J, JAL, JR, JALR, RFE
  );

  type exceptionCode is (
    NO_ECP, OVF_ECP, UFL_ECP, INV_CON_ECP, IOP_ECP, IRM_ECP, IRR_ECP, DRM_ECP, DRR_ECP, IRQ_ECP, GEN_ECP
  );

  type irqCode is (
    IRQ0, IRQ1, IRQ2, IRQ3, IRQ4, IRQ5, IRQ6, IRQ7, NO_IRQ
  );

-- status and control registers indexes
  constant ECP_SIZE : integer := 5;   -- exception cause size

  subtype OPCODE_RANGE is natural range Nbit-1 downto Nbit-OPCODE_SIZE;
  subtype FUNC_RANGE is natural range 10 downto 0;

  subtype IRQ_ARRAY is natural range 15 downto 8;

  subtype CPU_MODE is natural range 1 downto 0;
  subtype ROUND_MODE is natural range 1 downto 0;
  constant STACK_FLAG        : integer := 2;
  constant IRAM_FLAG         : integer := 3;
  constant ECP_LOCK          : integer := 4;
  constant BRANCH_DELAY_SLOT : integer := 5;
  constant OVF_FLAG          : integer := 16;
  constant UFL_FLAG          : integer := 17;
  constant CARRY_FLAG        : integer := 18;
  constant ZERO_FLAG         : integer := 19;
  constant INV_FLAG          : integer := 20;

  constant SRT_MODE : std_logic_vector(CPU_MODE) := "00";
  constant STD_MODE : std_logic_vector(CPU_MODE) := "01";
  constant FST_MODE : std_logic_vector(CPU_MODE) := "10";
  constant DBG_MODE : std_logic_vector(CPU_MODE) := "11";

  constant ECP_EN    : integer := 7;
  constant ECP_ARITH : integer := 6;
  subtype ECP_MODE is natural range ECP_EN downto ECP_ARITH;

  constant START_CODE_POINTER : std_logic_vector(Nbit-1 downto 0) := std_logic_vector(to_unsigned(TEXT_ADDRESS, Nbit));

  constant SP_index : integer := (2*N_windows-3)*in_local_out_width + 29; -- Stack pointer index inside register file
  constant CR_index : integer := (2*N_windows-3)*in_local_out_width + 28; -- control register index inside register file
  constant SR_index : integer := (2*N_windows-3)*in_local_out_width + 25; -- status register index inside register file

  constant IR_NOP_VALUE : std_logic_vector(Nbit-1 downto 0) := "01010111000110001100000000000000";
  constant IR_NULL_VALUE : std_logic_vector(Nbit-1 downto 0) := "11111100000000000000000000000000";

end DLX_package;

package body DLX_package is

-------------------------------------------------------------------------------

  function log2 (X : positive) return natural is
    variable cnt : integer;
    variable tmp : integer;
  begin

    cnt := 0;
    tmp := X;
    while tmp >= 2 loop
      tmp := tmp/2;
      cnt := cnt + 1;
    end loop;

    return cnt;

  end log2;

-------------------------------------------------------------------------------

  function up_int_log2 (X : positive) return natural is

    variable N : natural;

  begin

    N := log2(X);

    if (X > (2**N)) then
      return (N+1);
    else
      return N;
    end if;

  end up_int_log2;

--------------------------------------------------------------------------------

function and_reduce(datain : std_logic_vector) return std_logic is
  variable res : std_logic := '1';
begin
  for i in datain'range loop
    res := res and datain(i);
  end loop;
  return res;
end and_reduce;

--------------------------------------------------------------------------------

function or_reduce(datain : std_logic_vector) return std_logic is
  variable res : std_logic := '0';
begin
  for i in datain'range loop
    res := res or datain(i);
  end loop;
  return res;
end or_reduce;

--------------------------------------------------------------------------------

function is_rtype(opcode : std_logic_vector) return boolean is
  variable res : boolean := false;
begin

  if opcode = "000000" then
        res := true;
  end if;
  return res;
end is_rtype;

--------------------------------------------------------------------------------

function is_ftype(opcode : std_logic_vector) return boolean is
  variable res : boolean := false;
begin

  if opcode = "000001" then
        res := true;
  end if;
  return res;
end is_ftype;

--------------------------------------------------------------------------------

function is_nop(opcode : std_logic_vector) return boolean is
  variable res : boolean := false;
begin

  if opcode = "010101" then
        res := true;
  end if;
  return res;
end is_nop;

--------------------------------------------------------------------------------

function is_null(opcode : std_logic_vector) return boolean is
  variable res : boolean := false;
begin

  if opcode = "111111" then
        res := true;
  end if;
  return res;
end is_null;

--------------------------------------------------------------------------------

function is_mul_type(opcode : std_logic_vector; func : std_logic_vector) return boolean is
  variable res : boolean := false;
begin

  if opcode = "000001" then
    if func = "00000000010" or func = "00000001110" or func = "00000010110" then --multf, mult, multu
        res := true;
    end if;
  end if;
  return res;
end is_mul_type;

--------------------------------------------------------------------------------

function is_add_type(opcode : std_logic_vector; func : std_logic_vector) return boolean is
  variable res : boolean := false;
begin

  if opcode = "000001" then
    if func = "00000000000" or func = "00000000001" then --addf, subf
        res := true;
    end if;
  end if;
  return res;
end is_add_type;

--------------------------------------------------------------------------------

function is_jtype(opcode : std_logic_vector) return boolean is
  variable res : boolean := false;
begin

  if opcode = "000010" or OPCODE = "000011" or OPCODE = "110000" or OPCODE = "010000" then -- J, JAL, CALL, RFE
        res := true;
  end if;
  return res;
end is_jtype;

--------------------------------------------------------------------------------

function is_movfp2i(opcode : std_logic_vector) return boolean is
  variable res : boolean := false;
begin

  if opcode = "110010" then -- MOVFP2I
        res := true;
  end if;
  return res;
end is_movfp2i;

--------------------------------------------------------------------------------

function is_sidf(opcode : std_logic_vector) return boolean is -- source integer, dest float
  variable res : boolean := false;
begin

  if opcode = "110011" then -- MOVI2FP
        res := true;
  elsif opcode = "100110" then  -- LF
        res := true;
  elsif opcode = "101101" then  -- POPF
        res := true;
  end if;
  return res;
end is_sidf;

--------------------------------------------------------------------------------

function is_pp(opcode : std_logic_vector) return boolean is -- push pop pushf popf
  variable res : boolean := false;
begin

  if opcode = "011110" then -- PUSH
        res := true;
  elsif opcode = "011111" then  -- POP
        res := true;
  elsif opcode = "101100" then  -- PUSHF
        res := true;
  elsif opcode = "101101" then  -- POPF
        res := true;
  end if;
  return res;
end is_pp;

--------------------------------------------------------------------------------

function is_f_itype(opcode : std_logic_vector) return boolean is
  variable res : boolean := false;
begin

  if opcode = "110100" then -- CONVFP2I
        res := true;
  end if;
  return res;
end is_f_itype;

--------------------------------------------------------------------------------

function is_load(opcode : std_logic_vector(OPCODE_SIZE-1 downto 0)) return boolean is
    variable res : boolean := false;
begin

  case opcode is
    when "011111" => res := true;  -- POP
    when "100011" => res := true;  -- LW
    when "100000" => res := true;  -- LB
    when "100001" => res := true;  -- LH
    when "100100" => res := true;  -- LBU
    when "100101" => res := true;  -- LHU
    when others => res := false;
  end case;

  return res;
end is_load;

--------------------------------------------------------------------------------

function is_itype(opcode : std_logic_vector) return boolean is
  variable res : boolean := false;
begin

  if not(is_rtype(opcode)) and not(is_jtype(opcode)) and
     not(is_load(opcode)) and not(is_branch(opcode)) and
     not(is_store(opcode)) and not(is_ftype(opcode)) and
     not(is_f_itype(opcode)) and not(is_movfp2i(opcode)) and
     not(is_sidf(opcode)) and not(is_null(opcode)) and
     not(is_store_f(opcode)) and not(is_nop(opcode)) then
        res := true;
  end if;
  return res;
end is_itype;

--------------------------------------------------------------------------------

function is_branch(opcode : std_logic_vector(OPCODE_SIZE-1 downto 0)) return boolean is
  variable res : boolean := false;
begin

  case opcode is
    when "000100" => res := true;  -- BEQZ
    when "000101" => res := true;  -- BNEZ
    when "010010" => res := true;  -- JR
    when "010011" => res := true;  -- JALR
    when "110001" => res := true;  -- RET
    when others => res := false;
  end case;

  return res;
end is_branch;


--------------------------------------------------------------------------------

function is_store(opcode : std_logic_vector(OPCODE_SIZE-1 downto 0)) return boolean is
    variable res : boolean := false;
begin

  case opcode is
    when "101000" => res := true;  -- SB
    when "101001" => res := true;  -- SH
    when "101011" => res := true;  -- SW
    when "011110" => res := true;  -- PUSH
    when others => res := false;
  end case;

  return res;
end is_store;

--------------------------------------------------------------------------------

function is_store_f(opcode : std_logic_vector(OPCODE_SIZE-1 downto 0)) return boolean is
    variable res : boolean := false;
begin

  case opcode is
    when "101110" => res := true;  -- SF
    when "101100" => res := true;  -- PUSHF
    when others => res := false;
  end case;
  return res;
end is_store_f;

--------------------------------------------------------------------------------

function is_valid(opcode : std_logic_vector(OPCODE_SIZE-1 downto 0)) return boolean is
  variable res : boolean := true;
begin
  case opcode is
    when "000000" => res := true;  -- R type
    when "000001" => res := true;  -- F type
    when "000010" => res := true;  -- J (0x02)
    when "000011" => res := true;  -- JAL
    when "000100" => res := true;  -- BEQZ
    when "000101" => res := true;  -- BNEZ
    when "000110" => res := false; -- BFPT, NOT IMPLEMENTED
    when "000111" => res := false; -- BFPF, NOT IMPLEMENTED
    when "001000" => res := true;  -- ADDI  (0x08)
    when "001001" => res := true;  -- ADDUI (0x09)
    when "001010" => res := true;  -- SUBI  (0x0A)
    when "001011" => res := true;  -- SUBUI (0xB)
    when "001100" => res := true;  -- ANDI  (0x0C)
    when "001101" => res := true;  -- ORI   (0x0D)
    when "001110" => res := true;  -- XORI  (0x0E)
    when "001111" => res := true;  -- LHI (0x0F)
    when "010000" => res := true;  -- RFE (0x10)
    when "010001" => res := false; -- TRAP, NOT IMPLEMENTED
    when "010010" => res := true;  -- JR (0x12)
    when "010011" => res := true;  -- JALR (0x13)
    when "010100" => res := true;  -- SLLI  (0X14)
    when "010101" => res := true;  -- NOP   (0X15)
    when "010110" => res := true;  -- SRLI  (0X16)
    when "010111" => res := true; -- SRAI (0x17)
    when "011000" => res := true;  -- SEQI (0x18)
    when "011001" => res := true;  -- SNEI  (0X19)
    when "011010" => res := true;  -- SLTI (0x1A)
    when "011011" => res := true;  -- SGTI (0x1B)
    when "011100" => res := true;  -- SLEI, (0X1C)
    when "011101" => res := true;  -- SGEI  (0X1D)
    when "011110" => res := true; -- PUSH (0X1E)
    when "011111" => res := true; -- POP (0X1F)
    when "100000" => res := true;  -- LB (0x20)
    when "100001" => res := true;  -- LH (0x21)
    when "100010" => res := false; -- IT DOES NOT CORRESPOND TO ANYTHING (0X22)
    when "100011" => res := true;  -- LW (0X23)
    when "100100" => res := true;  -- LBU (0x24)
    when "100101" => res := true;  -- LHU (0x25)
    when "100110" => res := true;  -- LF, (0x26)
    when "100111" => res := false; -- LD, NOT IMPLEMENTED
    when "101000" => res := true;  -- SB (0x28)
    when "101001" => res := true;  -- SH,(0x29)
    when "101010" => res := false; -- IT DOES NOT CORRESPOND TO ANYTHING (0X2A)
    when "101011" => res := true;  -- SW (0X2B)
    when "101100" => res := true;  -- PUSHF (0x2C)
    when "101101" => res := true;  -- POPF (0x2D)
    when "101110" => res := true;  -- SF, (0X2E)
    when "101111" => res := false; -- SD, NOT IMPLEMENTED(0X2F)
    when "110000" => res := true; -- CALL(0x30)
    when "110001" => res := true; -- RET(0x31)
    when "110010" => res := true; -- MOVFP2I(0x32)
    when "110011" => res := true; -- MOVI2FP(0x33)
    when "110100" => res := true; --CVTF2I(0x34)
    when "110101" => res := true; --CVTI2F(0x35)
    when "110110" => res := false; -- NOTHING
    when "110111" => res := false; -- NOTHING
    when "111000" => res := false; -- ITLB, NOT IMPLEMENTED (0X38)
    when "111001" => res := false; -- NOTHING
    when "111010" => res := true;  -- SLTUI (0X3A)
    when "111011" => res := true;  -- SGTUI (0X3B)
    when "111100" => res := true; -- SLEUI (0X3C)
    when "111101" => res := true;  -- SGEUI (0X3D)
    when "111110" => res := false; -- NOTHING
    when "111111" => res := false; -- NOTHING
    when others => res := false;
  end case;
  return res;
end is_valid;

end DLX_package;
