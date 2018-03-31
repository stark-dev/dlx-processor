library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.DLX_package.all;

entity TB_RF is
end TB_RF;

architecture TEST of TB_RF is
    --constants
    constant N     : natural := 32;
    constant N_REG : natural := 32;
    --signals
    signal t_reset_n        : std_logic;
    signal t_clock          : std_logic;
    signal t_enable         : std_logic;
    signal t_rd1            : std_logic;
    signal t_rd2            : std_logic;
    signal t_wr             : std_logic;
    signal t_add_wr         : std_logic_vector(up_int_log2(N_REG)-1 downto 0);
    signal t_add_rd1        : std_logic_vector(up_int_log2(N_REG)-1 downto 0);
    signal t_add_rd2        : std_logic_vector(up_int_log2(N_REG)-1 downto 0);
    signal t_data_in        : std_logic_vector(N-1 downto 0);
    signal t_data_out1      : std_logic_vector(N-1 downto 0);
    signal t_data_out2      : std_logic_vector(N-1 downto 0);
    --components
    component register_file IS
       GENERIC(N : integer := 4; N_REG : integer := 4);
         PORT (  RESET_N: 	IN std_logic;
             CLK :    IN std_logic;
         	 ENABLE: 	IN std_logic;
         	 RD1: 		IN std_logic;
         	 RD2: 		IN std_logic;
         	 WR: 		IN std_logic;
         	 ADD_WR: 	IN std_logic_vector(up_int_log2(N_REG)-1 downto 0);
         	 ADD_RD1: 	IN std_logic_vector(up_int_log2(N_REG)-1 downto 0);
         	 ADD_RD2: 	IN std_logic_vector(up_int_log2(N_REG)-1 downto 0);
         	 DATAIN: 	IN std_logic_vector(N-1 downto 0);
           OUT1: 		OUT std_logic_vector(N-1 downto 0);
         	 OUT2: 		OUT std_logic_vector(N-1 downto 0));
    END component;

    begin
        DUT : register_file
           generic map(N, N_REG)
           port map(t_reset_n, t_clock, t_enable, t_rd1, t_rd2, t_wr, t_add_wr, t_add_rd1, t_add_rd2, t_data_in, t_data_out1, t_data_out2);

     clock_process : process
     begin
        wait for 0.5 ns;
        t_clock <= '1';
        wait for 0.5 ns;
        t_clock <= '0';
end process;


   input_gen : process
   begin
       t_reset_n <= '1';
       t_enable <= '1';
       t_rd1 <= '0';
       t_rd2 <= '0';
       t_wr <= '0';
       t_add_wr <= std_logic_vector(to_unsigned(0, up_int_log2(N_REG)));
       t_add_rd1 <= std_logic_vector(to_unsigned(0, up_int_log2(N_REG)));
       t_add_rd2 <= std_logic_vector(to_unsigned(0, up_int_log2(N_REG)));
       t_data_in <= std_logic_vector(to_unsigned(0, N));

       wait for 1 ns;
       t_reset_n <= '0';

       wait for 1 ns;
       t_reset_n <= '1';
       t_add_wr <= std_logic_vector(to_unsigned(2, up_int_log2(N_REG)));
       t_data_in <= std_logic_vector(to_unsigned(5, N));

       wait for 1 ns;
       t_wr <= '1';

       wait for 1 ns;
       t_wr <= '0';
       t_add_rd1 <= std_logic_vector(to_unsigned(9, up_int_log2(N_REG)));
       t_add_rd2 <= std_logic_vector(to_unsigned(10, up_int_log2(N_REG)));

       wait for 1 ns;
       t_rd1 <= '1';
       t_rd2 <= '1';

       wait for 1 ns;
       t_rd1 <= '0';
       t_rd2 <= '0';
       t_enable <= '1';

       wait for 1 ns;
       t_add_wr <= std_logic_vector(to_unsigned(0, up_int_log2(N_REG)));
       t_data_in <= std_logic_vector(to_unsigned(5, N));

       wait for 1 ns;
       t_wr <= '1';

       wait for 1 ns;
       t_wr <= '0';
       t_add_rd1 <= std_logic_vector(to_unsigned(1, up_int_log2(N_REG)));
       t_add_rd2 <= std_logic_vector(to_unsigned(1, up_int_log2(N_REG)));

       wait for 1 ns;
       t_rd1 <= '1';
       t_rd2 <= '1';

       wait for 1 ns;
       t_rd1 <= '0';
       t_rd2 <= '0';

       wait;
   end process;





end architecture;
