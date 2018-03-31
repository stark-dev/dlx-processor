library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.DLX_package.all;

entity TB_WRF is
end TB_WRF;

architecture TEST of TB_WRF is
    --constants
    constant N         : natural := in_local_out_width;
    constant F         : natural := N_windows;
    constant M         : natural := N_globals;
    --signals
    signal t_reset_n        : std_logic;
    signal t_clock          : std_logic;
    signal t_enable         : std_logic;
    signal t_wr             : std_logic;
    signal t_wr_sp          : std_logic;
    signal t_wr_sr          : std_logic;
    signal t_add_wr         : std_logic_vector(up_int_log2(3*N+M)-1 downto 0);
    signal t_add_rd1        : std_logic_vector(up_int_log2(3*N+M)-1 downto 0);
    signal t_add_rd2        : std_logic_vector(up_int_log2(3*N+M)-1 downto 0);
    signal t_data_in        : std_logic_vector(Nbit-1 downto 0);
    signal t_data_in_sp     : std_logic_vector(Nbit-1 downto 0);
    signal t_data_in_sr     : std_logic_vector(Nbit-1 downto 0);
    signal t_out1           : std_logic_vector(Nbit-1 downto 0);
    signal t_out2           : std_logic_vector(Nbit-1 downto 0);
    signal t_out_sr         : std_logic_vector(Nbit-1 downto 0);
    signal t_out_cr         : std_logic_vector(Nbit-1 downto 0);
    signal t_fp_intn_rd1    : std_logic;
    signal t_fp_intn_rd2    : std_logic;
    signal t_fp_intn_wr     : std_logic;
    signal t_cwp            : unsigned(up_int_log2(F)-1 downto 0);
    --components
    component register_file
     GENERIC( N_bit : integer := 32;
              N : integer := 8;             -- Number of registers in each IN, OUT and LOCALS
              F : integer := 4;             -- Number of windows
              M : integer := 8);            -- Number of global registers
     PORT (  RESET_N: 	IN std_logic;
       CLK :    IN std_logic;
    	 ENABLE: 	IN std_logic;
    	 WR: 		  IN std_logic;
       WR_SP:   IN std_logic;
       WR_SR:   IN std_logic;
       FP_INTn_RD1 :IN std_logic;
       FP_INTn_RD2 :IN std_logic;
       FP_INTn_WR :IN std_logic;
    	 ADD_WR: 	IN std_logic_vector(up_int_log2(3*N+M)-1 downto 0);
    	 ADD_RD1: IN std_logic_vector(up_int_log2(3*N+M)-1 downto 0);
    	 ADD_RD2: IN std_logic_vector(up_int_log2(3*N+M)-1 downto 0);
    	 DATAIN: 	IN std_logic_vector(N_bit-1 downto 0);
       DATAIN_SP: IN std_logic_vector(N_bit-1 downto 0);
       DATAIN_SR : IN std_logic_vector(N_bit-1 downto 0);
       CWP:     IN unsigned(up_int_log2(F)-1 downto 0);
       OUT1: 		OUT std_logic_vector(N_bit-1 downto 0);
       OUT2: 		OUT std_logic_vector(N_bit-1 downto 0);
       OUT_SR  : OUT std_logic_vector(N_bit-1 downto 0);
       OUT_CR  : OUT std_logic_vector(N_bit-1 downto 0));
    end component;


    begin
        DUT : register_file
           generic map(Nbit, N, F, M)
           port map(t_reset_n, t_clock, t_enable, t_wr, t_wr_sp, t_wr_sr, t_fp_intn_rd1, t_fp_intn_rd2, t_fp_intn_wr,
            t_add_wr, t_add_rd1, t_add_rd2, t_data_in, t_data_in_sp, t_data_in_sr, t_cwp, t_out1,
            t_out2, t_out_sr, t_out_cr);

     clock_process : process
     begin
        wait for 0.5 ns;
        t_clock <= '1';
        wait for 0.5 ns;
        t_clock <= '0';
      end process;


   input_gen : process
   begin

     t_reset_n        <= '0';
     t_enable         <= '1';
     t_wr             <= '0';
     t_wr_sp          <= '0';
     t_wr_sr          <= '0';
     t_add_wr         <= std_logic_vector(to_unsigned(0, up_int_log2(3*N+M)));
     t_add_rd1        <= std_logic_vector(to_unsigned(0, up_int_log2(3*N+M)));
     t_add_rd2        <= std_logic_vector(to_unsigned(0, up_int_log2(3*N+M)));
     t_data_in        <= std_logic_vector(to_unsigned(0, Nbit));
     t_data_in_sp     <= std_logic_vector(to_unsigned(0, Nbit));
     t_data_in_sr     <= std_logic_vector(to_unsigned(0, Nbit));
     t_fp_intn_rd1    <= '0';
     t_fp_intn_rd2    <= '0';
     t_fp_intn_wr     <= '0';
     t_cwp            <= to_unsigned(0, up_int_log2(F));

     wait for 1 ns;


     t_reset_n        <= '1';

     wait for 1 ns;

     t_wr             <= '1';
     t_wr_sp          <= '0';
     t_wr_sr          <= '0';
     t_add_wr         <= std_logic_vector(to_unsigned(16, up_int_log2(3*N+M)));
     t_add_rd1        <= std_logic_vector(to_unsigned(0, up_int_log2(3*N+M)));
     t_add_rd2        <= std_logic_vector(to_unsigned(0, up_int_log2(3*N+M)));
     t_data_in        <= std_logic_vector(to_unsigned(10, Nbit));
     t_data_in_sp     <= std_logic_vector(to_unsigned(0, Nbit));
     t_data_in_sr     <= std_logic_vector(to_unsigned(0, Nbit));
     t_fp_intn_rd1    <= '0';
     t_fp_intn_rd2    <= '0';
     t_fp_intn_wr     <= '0';
     t_cwp            <= to_unsigned(0, up_int_log2(F));

     wait for 1 ns;

     t_wr             <= '1';
     t_wr_sp          <= '0';
     t_wr_sr          <= '0';
     t_add_wr         <= std_logic_vector(to_unsigned(30, up_int_log2(3*N+M)));
     t_add_rd1        <= std_logic_vector(to_unsigned(0, up_int_log2(3*N+M)));
     t_add_rd2        <= std_logic_vector(to_unsigned(0, up_int_log2(3*N+M)));
     t_data_in        <= std_logic_vector(to_unsigned(12, Nbit));
     t_data_in_sp     <= std_logic_vector(to_unsigned(0, Nbit));
     t_data_in_sr     <= std_logic_vector(to_unsigned(0, Nbit));
     t_fp_intn_rd1    <= '0';
     t_fp_intn_rd2    <= '0';
     t_fp_intn_wr     <= '0';
     t_cwp            <= to_unsigned(0, up_int_log2(F));

     wait for 1 ns;

     t_wr             <= '0';
     t_wr_sp          <= '0';
     t_wr_sr          <= '0';
     t_add_wr         <= std_logic_vector(to_unsigned(2, up_int_log2(3*N+M)));
     t_add_rd1        <= std_logic_vector(to_unsigned(1, up_int_log2(3*N+M)));
     t_add_rd2        <= std_logic_vector(to_unsigned(30, up_int_log2(3*N+M)));
     t_data_in        <= std_logic_vector(to_unsigned(10, Nbit));
     t_data_in_sp     <= std_logic_vector(to_unsigned(0, Nbit));
     t_data_in_sr     <= std_logic_vector(to_unsigned(0, Nbit));
     t_fp_intn_rd1    <= '0';
     t_fp_intn_rd2    <= '0';
     t_fp_intn_wr     <= '0';
     t_cwp            <= to_unsigned(0, up_int_log2(F));

     wait for 1 ns;

     t_wr             <= '0';
     t_wr_sp          <= '1';
     t_wr_sr          <= '1';
     t_add_wr         <= std_logic_vector(to_unsigned(2, up_int_log2(3*N+M)));
     t_add_rd1        <= std_logic_vector(to_unsigned(0, up_int_log2(3*N+M)));
     t_add_rd2        <= std_logic_vector(to_unsigned(0, up_int_log2(3*N+M)));
     t_data_in        <= std_logic_vector(to_unsigned(10, Nbit));
     t_data_in_sp     <= std_logic_vector(to_unsigned(5, Nbit));
     t_data_in_sr     <= std_logic_vector(to_unsigned(9, Nbit));
     t_fp_intn_rd1    <= '0';
     t_fp_intn_rd2    <= '0';
     t_fp_intn_wr     <= '0';
     t_cwp            <= to_unsigned(0, up_int_log2(F));

     wait for 1 ns;

     t_cwp            <= to_unsigned(1, up_int_log2(F));

     wait for 1 ns;

     t_wr             <= '0';
     t_wr_sp          <= '0';
     t_wr_sr          <= '0';
     t_add_wr         <= std_logic_vector(to_unsigned(2, up_int_log2(3*N+M)));
     t_add_rd1        <= std_logic_vector(to_unsigned(1, up_int_log2(3*N+M)));
     t_add_rd2        <= std_logic_vector(to_unsigned(0, up_int_log2(3*N+M)));
     t_data_in        <= std_logic_vector(to_unsigned(10, Nbit));
     t_data_in_sp     <= std_logic_vector(to_unsigned(5, Nbit));
     t_data_in_sr     <= std_logic_vector(to_unsigned(9, Nbit));
     t_fp_intn_rd1    <= '0';
     t_fp_intn_rd2    <= '0';
     t_fp_intn_wr     <= '0';

     wait;
   end process;
end architecture;
