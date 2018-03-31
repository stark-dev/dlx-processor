library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DLX_package.all;

ENTITY TB_DMA IS
END ENTITY;

ARCHITECTURE test OF TB_DMA IS

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
      DATA_OUT          : OUT std_logic_vector(4 downto 0));
  end component;

  signal reset_n_t :std_logic;
  signal clk_t :std_logic;
  signal call_t :std_logic;
  signal ret_t :std_logic;
  signal call_rollback_t :std_logic;
  signal ret_rollback_t :std_logic;
  signal cwp_enable_t :std_logic;
  signal spill_t :std_logic;
  signal fill_t :std_logic;
  signal cwp_t : unsigned(up_int_log2(N_windows)-1 downto 0);
  signal data_out_t :std_logic_vector(4 downto 0);

BEGIN

  DUT : DMA
    generic map(Nbit, N_globals, in_local_out_width, N_windows)
    port map(reset_n_t, clk_t, call_t, ret_t, call_rollback_t, ret_rollback_t, cwp_enable_t, spill_t, fill_t, cwp_t, data_out_t);

  clock_process : process
  begin
     wait for 0.5 ns;
      clk_t <= '0';
     wait for 0.5 ns;
      clk_t <= '1';
   end process;


   input_gen : process
   begin
     wait for 0.2 ns;
     reset_n_t         <= '0';
     call_t            <= '0';
     ret_t             <= '0';
     call_rollback_t   <= '0';
     ret_rollback_t    <= '0';
     cwp_enable_t      <= '0';

     wait for 1 ns;

     reset_n_t         <= '1';
     call_t            <= '0';
     ret_t             <= '0';
     call_rollback_t   <= '0';
     ret_rollback_t    <= '0';
     cwp_enable_t      <= '0';

     wait for 1 ns;

     reset_n_t         <= '1';
     call_t            <= '1';
     ret_t             <= '0';
     call_rollback_t   <= '0';
     ret_rollback_t    <= '0';
     cwp_enable_t      <= '0';

     wait for 1 ns;

     reset_n_t         <= '1';
     call_t            <= '1';
     ret_t             <= '0';
     call_rollback_t   <= '0';
     ret_rollback_t    <= '0';
     cwp_enable_t      <= '1';

     wait for 1 ns;

     reset_n_t         <= '1';
     call_t            <= '1';
     ret_t             <= '0';
     call_rollback_t   <= '0';
     ret_rollback_t    <= '0';
     cwp_enable_t      <= '1';

     wait for 1 ns;

     reset_n_t         <= '1';
     call_t            <= '1';
     ret_t             <= '0';
     call_rollback_t   <= '0';
     ret_rollback_t    <= '0';
     cwp_enable_t      <= '1';

     wait for 1 ns;

     reset_n_t         <= '1';
     call_t            <= '0';
     ret_t             <= '0';
     call_rollback_t   <= '0';
     ret_rollback_t    <= '0';
     cwp_enable_t      <= '0';

     wait for 1 ns;



     wait;
   end process;


END ARCHITECTURE;
