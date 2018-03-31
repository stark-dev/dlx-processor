library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.DLX_package.all;

ENTITY DMA is
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
END ENTITY;


ARCHITECTURE Behavioral OF DMA IS

  component up_counter
    GENERIC( N        : integer := 16);
    PORT( CLK      : IN std_logic;
          RESET_N  : IN std_logic;
          EN       : IN std_logic;
          TC_value : IN std_logic_vector(N-1 downto 0);
          Q        : OUT std_logic_vector(N-1 downto 0);
          TC       : OUT std_logic);
  end component;

  component down_counter
    GENERIC( N        : integer := 16);
    PORT( CLK      : IN std_logic;
          RESET_N  : IN std_logic;
          EN       : IN std_logic;
          TC_value : IN std_logic_vector(N-1 downto 0);
          Q        : OUT std_logic_vector(N-1 downto 0);
          TC       : OUT std_logic);
  end component;

  -- constants

  constant swp_reset_val   : unsigned(up_int_log2(F)-1 downto 0) := (others => '1');
  constant up_counter_tc   : std_logic_vector(up_int_log2(3*N)-1 downto 0) := std_logic_vector(to_unsigned(23, up_int_log2(3*N)));
  constant down_counter_tc : std_logic_vector(up_int_log2(3*N)-1 downto 0) := std_logic_vector(to_unsigned(0, up_int_log2(3*N)));

  -- cwp/swp

  signal cwp_s          : unsigned(up_int_log2(F)-1 downto 0);
  signal cwp_reg_s      : unsigned(up_int_log2(F)-1 downto 0);
  signal swp_s          : unsigned(up_int_log2(F)-1 downto 0);

  signal spill_s          : std_logic;
  signal fill_s           : std_logic;
  signal fill_delay_1     : std_logic;
  signal fill_delay_2     : std_logic;
  signal fill_delay_3     : std_logic;
  signal fill_delay_4     : std_logic;
  signal fill_delay_s     : std_logic;

  signal intn_fp_reg_s    : std_logic;
  signal spill_fill_end_s : std_logic;

  -- signal SWP        : unsigned(up_int_log2(F)-1 downto 0);

  signal cansave_canrestore_s : std_logic;

  -- counters

  signal up_counter_out       : std_logic_vector(up_int_log2(4*N)-1 downto 0);
  signal down_counter_out     : std_logic_vector(up_int_log2(4*N)-1 downto 0);
  signal up_tc                : std_logic;
  signal down_tc              : std_logic;

  signal reset_n_up_counter   : std_logic;
  signal reset_n_down_counter : std_logic;

  signal IR_value             : std_logic_vector(Nbit-1 downto 0);

BEGIN

  SPILL       <= spill_s;
  FILL        <= fill_s;

  DATA_OUT    <= IR_value;

  CWP <= swp_s when fill_delay_s = '1' else
         cwp_reg_s;

  reset_n_up_counter   <= RESET_N;
  reset_n_down_counter <= RESET_N;

  fill_delay_s <= fill_delay_1 or fill_delay_2 or fill_delay_3 or fill_delay_4;

  up_counter_c : up_counter
    generic map(up_int_log2(3*N))
    port map(CLK, reset_n_up_counter, spill_s, up_counter_tc, up_counter_out, up_tc);

  down_counter_c : down_counter
    generic map(up_int_log2(3*N))
    port map(CLK, reset_n_down_counter, fill_s, down_counter_tc, down_counter_out, down_tc);

  cwp_counter_p : process(RESET_N, CALL, RET, CALL_ROLLBACK, RET_ROLLBACK)
  begin
    if RESET_N = '0' then
      cwp_s <= (others => '0');
    elsif CALL = '1' or RET_ROLLBACK = '1' then
      cwp_s <= cwp_s + 1;
    elsif RET = '1' or CALL_ROLLBACK = '1' then
      cwp_s <= cwp_s - 1;
    end if;
  end process;

  cwp_reg_p : process(RESET_N, CLK)
  begin
    if RESET_N = '0' then
      cwp_reg_s <= (others => '0');
    elsif CLK'event and CLK = '1' then
      cwp_reg_s <= cwp_s;
    end if;
  end process;

  swp_counter_p : process(RESET_N, CLK)
  begin
    if RESET_N = '0' then
      swp_s <= (others => '1');
    elsif CLK'event and CLK = '1' then
      if (CALL = '1' and cansave_canrestore_s = '0') then
        swp_s <= swp_s + 1;
      elsif (RET = '1' and cansave_canrestore_s = '0') then
        swp_s <= swp_s - 1;
      end if;
    end if;
  end process;

  cansave_canrestore_p : process(swp_s, cwp_s)
  begin
    if swp_s - cwp_s = 0 then
      cansave_canrestore_s <= '0';
    else
      cansave_canrestore_s <= '1';
    end if;
  end process;

  spill_p : process(RESET_N, spill_fill_end_s, CALL, cansave_canrestore_s)
  begin
    if RESET_N = '0' then
      spill_s <= '0';
    else
      if spill_fill_end_s = '1' then
        spill_s <= '0';
      elsif (CALL = '1' and cansave_canrestore_s = '0') then
        spill_s <= '1';
      end if;
    end if;
  end process;

  fill_p : process(RESET_N, spill_fill_end_s, RET, cansave_canrestore_s)
  begin
    if RESET_N = '0' then
      fill_s <= '0';
    else
      if spill_fill_end_s = '1' then
        fill_s <= '0';
      elsif (RET = '1' and cansave_canrestore_s = '0') then
        fill_s <= '1';
      end if;
    end if;
  end process;

  intn_fp_flag_p : process(RESET_N, CLK, CALL, RET, CALL_ROLLBACK, RET_ROLLBACK)
  begin
    if RESET_N = '0' or CALL = '1' or CALL_ROLLBACK = '1' or RET_ROLLBACK = '1' then
      intn_fp_reg_s <= '0';
    elsif CLK'event and CLK = '1' then
      if up_tc = '1' or down_tc = '1' then
        intn_fp_reg_s <= not(intn_fp_reg_s);
      end if;
    end if;
  end process;

  spill_fill_end_p : process(RESET_N, CLK)
  begin
    if RESET_N = '0' then
      spill_fill_end_s <= '0';
    elsif CLK'event and CLK = '1' then
      if (up_tc = '1' or down_tc = '1') and intn_fp_reg_s = '1' then
        spill_fill_end_s <= '1';
      else
        spill_fill_end_s <= '0';
      end if;
    end if;
  end process;

  fill_delay_p : process(CLK, RESET_N)
  begin
    if RESET_N = '0' then
      fill_delay_1 <= '0';
      fill_delay_2 <= '0';
      fill_delay_3 <= '0';
      fill_delay_4 <= '0';
    elsif CLK'event and CLK = '1' then
      fill_delay_1 <= fill_s;
      fill_delay_2 <= fill_delay_1;
      fill_delay_3 <= fill_delay_2;
      fill_delay_4 <= fill_delay_3;
    end if;
  end process;

  -----------------------------------------------------------
  -- IR spill fill value
  -----------------------------------------------------------

  instruction_process : process(spill_s, fill_s, up_counter_out, down_counter_out, intn_fp_reg_s)
  begin
    if spill_s = '1' then
      -- opcode
      if intn_fp_reg_s = '0' then
        IR_value(OPCODE_RANGE) <= "011110"; -- PUSH (0x1E)
      else
        IR_value(OPCODE_RANGE) <= "101100"; -- PUSHF (0x2C)
      end if;
      -- source reg
      IR_value(25 downto 21) <= "11101"; -- R29 (stack pointer)
      -- dest reg
      IR_value(20 downto 16) <= up_counter_out; -- address of reg to save
      --immediate
      IR_value(15 downto 0)  <= (others => '0');
    elsif fill_s = '1' then
      -- opcode
      if intn_fp_reg_s = '0' then
        IR_value(OPCODE_RANGE) <= "101101"; -- POPF (0x2D)
      else
        IR_value(OPCODE_RANGE) <= "011111"; -- POP (0x1F)
      end if;
      -- source reg
      IR_value(25 downto 21) <= "11101"; -- R29 (stack pointer)
      -- dest reg
      IR_value(20 downto 16) <= down_counter_out; -- address of reg to write
      --immediate
      IR_value(15 downto 0)  <= std_logic_vector(to_unsigned(4, 16));
    else
      IR_value <= IR_NOP_VALUE;
    end if;
  end process;

END ARCHITECTURE;
