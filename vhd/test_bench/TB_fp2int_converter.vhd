library ieee;
use ieee.std_logic_1164.all;
use work.DLX_package.all;
use ieee.numeric_std.all;

entity tb_fp2i is
end tb_fp2i;

architecture test of tb_fp2i is

  component FP2INT_CONVERTER
    PORT( DATA_IN       : IN std_logic_vector(31 downto 0);
          ROUNDING_MODE : IN std_logic_vector(1 downto 0);
          DATA_OUT      : OUT std_logic_vector(31 downto 0);
          OVERFLOW      : OUT std_logic;
          INVALID       : OUT std_logic
    );
  end component;

  signal t_data_in    : std_logic_vector(31 downto 0);
  signal t_data_out   : std_logic_vector(31 downto 0);
  signal t_round_mode : std_logic_vector(1 downto 0);
  signal t_overflow   : std_logic;
  signal t_invalid    : std_logic;

begin  -- test

  DUT: FP2INT_CONVERTER
    port map (t_data_in, t_round_mode, t_data_out, t_overflow, t_invalid);
  input_gen: process
    begin
      t_data_in <= (others => '0');
      t_round_mode <= "10";

      wait for 1 ns;

      assert t_data_out = "00000000000000000000000000000000" report "Error 0";

      wait for 1 ns;

      t_data_in <= "11111111100010000000000000000000";
      t_round_mode <= "10";

      wait for 1 ns;

      assert t_data_out = "10000000000000000000000000000000" report "Error NaN";
      assert t_invalid = '1' report "Error invalid flag";

      wait for 1 ns;

      t_data_in <= "01110000000000000000000000000000";
      t_round_mode <= "10";

      wait for 1 ns;

      assert t_data_out = "01111111111111111111111111111111" report "Error overflow";
      assert t_overflow = '1' report "Error overflow flag";

      wait for 1 ns;

      t_data_in <= "01000001110000000000000000000000";
      t_round_mode <= "10";

      wait for 1 ns;

      assert t_data_out = std_logic_vector(to_unsigned(24,32)) report "Error 24";

      wait for 1 ns;

      t_data_in <= "11001001110101110000000000000000";
      t_round_mode <= "10";

      wait for 1 ns;

      assert t_data_out = std_logic_vector(to_signed(-1761280,32)) report "Error -1761280";

      wait for 1 ns;

      t_data_in <= "01000100010011000000000000000000";
      t_round_mode <= "10";

      wait for 1 ns;

      assert t_data_out = std_logic_vector(to_signed(816,32)) report "Error 816";

      wait for 1 ns;

      t_data_in <= "00011000010011000000000000000000";
      t_round_mode <= "10";

      wait for 1 ns;

      assert t_data_out = std_logic_vector(to_signed(0,32)) report "Error Underflow";

      wait for 1 ns;

      wait;
  end process;


end test;
