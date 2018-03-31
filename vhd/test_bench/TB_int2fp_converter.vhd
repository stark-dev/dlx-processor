library ieee;
use ieee.std_logic_1164.all;
use work.DLX_package.all;
use ieee.numeric_std.all;

entity tb_i2fp is
end tb_i2fp;

architecture test of tb_i2fp is

  component INT2FP_CONVERTER
    PORT( DATA_IN       : IN std_logic_vector(31 downto 0);
          ROUNDING_MODE : IN std_logic_vector(1 downto 0);
          DATA_OUT      : OUT std_logic_vector(31 downto 0)
    );
  end component;

  signal t_data_in    : std_logic_vector(31 downto 0);
  signal t_data_out   : std_logic_vector(31 downto 0);
  signal t_round_mode : std_logic_vector(1 downto 0);

begin  -- test

  DUT: INT2FP_CONVERTER
    port map (t_data_in, t_round_mode, t_data_out);
  input_gen: process
    begin
      t_data_in <= (others => '0');
      t_round_mode <= "10";

      wait for 1 ns;

      assert t_data_out = "00000000000000000000000000000000" report "Error all 0";

      wait for 1 ns;

      t_data_in <= std_logic_vector(to_signed(-1,32));
      t_round_mode <= "10";

      wait for 1 ns;

      assert t_data_out = "10111111100000000000000000000000" report "Error -1";

      wait for 1 ns;

      t_data_in <= std_logic_vector(to_unsigned(10,32));
      t_round_mode <= "10";

      wait for 1 ns;

      assert t_data_out = "01000001001000000000000000000000" report "Error 10";

      wait for 1 ns;

      t_data_in <= std_logic_vector(to_signed(-25,32));
      t_round_mode <= "10";

      wait for 1 ns;

      assert t_data_out = "11000001110010000000000000000000" report "Error -25";

      wait for 1 ns;

      t_data_in <= std_logic_vector(to_unsigned(257,32));
      t_round_mode <= "10";

      wait for 1 ns;

      assert t_data_out = "01000011100000001000000000000000" report "Error 257";

      wait for 1 ns;

      t_data_in <= std_logic_vector(to_signed(255,32));
      t_round_mode <= "10";

      wait for 1 ns;

      assert t_data_out = "01000011011111110000000000000000" report "Error 255";

      wait for 1 ns;

      t_data_in <= std_logic_vector(to_signed(-99999999,32));
      t_round_mode <= "10";

      wait for 1 ns;

      assert t_data_out = "11001100101111101011110000100000" report "Error -99999999";

      wait for 1 ns;

      wait;
  end process;


end test;
