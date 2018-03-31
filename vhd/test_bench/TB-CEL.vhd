library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.DLX_package.all;

entity TB_CEL is
end TB_CEL;

architecture TEST of TB_CEL is
    --signals
    signal t_reset_n               : std_logic;
    signal t_clock                 : std_logic;
    signal t_int_sr_load_value     : std_logic_vector(1 to INTEGER_PIPE_LENGTH+1);
    signal t_mul_sr_load_value     : std_logic_vector(1 to MULT_PIPE_LENGTH+1);
    signal t_add_sr_load_value     : std_logic_vector(1 to FP_ADD_PIPE_LENGTH+1);
    signal t_cel_sr_load           : std_logic;
    signal t_int_sr_enable         : std_logic_vector(1 to INTEGER_PIPE_LENGTH+1);
    signal t_mul_sr_enable         : std_logic_vector(1 to MULT_PIPE_LENGTH+1);
    signal t_add_sr_enable         : std_logic_vector(1 to FP_ADD_PIPE_LENGTH+1);
    signal t_data_out              : std_logic;
    --components
    component cwp_lock IS
      PORT( RESET_N               : IN std_logic;
            CLK                   : IN std_logic;
            INT_SR_ENABLE         : IN std_logic_vector(1 to INTEGER_PIPE_LENGTH+1);
            MUL_SR_ENABLE         : IN std_logic_vector(1 to MULT_PIPE_LENGTH+1);
            ADD_SR_ENABLE         : IN std_logic_vector(1 to FP_ADD_PIPE_LENGTH+1);
            CEL_SR_LOAD           : IN std_logic;
            INT_SR_LOAD_VALUE     : IN std_logic_vector(1 to INTEGER_PIPE_LENGTH+1);
            MUL_SR_LOAD_VALUE     : IN std_logic_vector(1 to MULT_PIPE_LENGTH+1);
            ADD_SR_LOAD_VALUE     : IN std_logic_vector(1 to FP_ADD_PIPE_LENGTH+1);
            DATA_OUT              : OUT std_logic
            );
    end component;


    begin
        DUT : cwp_lock
           port map (t_reset_n, t_clock,
                     t_int_sr_enable, t_mul_sr_enable, t_add_sr_enable,
                     t_cel_sr_load, t_int_sr_load_value, t_mul_sr_load_value, t_add_sr_load_value,
                     t_data_out);

     clock_process : process
     begin
        wait for 0.5 ns;
        t_clock <= '1';
        wait for 0.5 ns;
        t_clock <= '0';
      end process;


   input_gen : process
   begin
     t_reset_n               <= '0';
     t_int_sr_load_value     <= "00";
     t_mul_sr_load_value     <= std_logic_vector(to_unsigned(0, MULT_PIPE_LENGTH+1));
     t_add_sr_load_value     <= std_logic_vector(to_unsigned(0, FP_ADD_PIPE_LENGTH+1));
     t_cel_sr_load           <= '0';
     t_int_sr_enable         <= (others => '0');
     t_mul_sr_enable         <= (others => '0');
     t_add_sr_enable         <= (others => '0');

     wait for 1 ns;

     t_reset_n               <= '1';
     t_int_sr_load_value     <= "00";
     t_mul_sr_load_value     <= std_logic_vector(to_unsigned(0, MULT_PIPE_LENGTH+1));
     t_add_sr_load_value     <= std_logic_vector(to_unsigned(0, FP_ADD_PIPE_LENGTH+1));
     t_cel_sr_load           <= '0';
     t_int_sr_enable         <= (others => '1');
     t_mul_sr_enable         <= (others => '1');
     t_add_sr_enable         <= (others => '1');

     wait for 1 ns;

     t_reset_n               <= '1';
     t_int_sr_load_value     <= "01";
     t_mul_sr_load_value     <= "0101";
     t_add_sr_load_value     <= "01101";
     t_cel_sr_load           <= '1';
     t_int_sr_enable         <= "01";
     t_mul_sr_enable         <= (others => '1');
     t_add_sr_enable         <= (others => '1');

     wait for 1 ns;

     t_reset_n               <= '1';
     t_int_sr_load_value     <= "00";
     t_mul_sr_load_value     <= std_logic_vector(to_unsigned(0, MULT_PIPE_LENGTH+1));
     t_add_sr_load_value     <= std_logic_vector(to_unsigned(0, FP_ADD_PIPE_LENGTH+1));
     t_cel_sr_load           <= '0';
     t_int_sr_enable         <= "01";
     t_mul_sr_enable         <= (others => '1');
     t_add_sr_enable         <= (others => '1');

     wait;
   end process;
end architecture;
