library ieee;
use ieee.std_logic_1164.all;
use work.DLX_package.all;
use ieee.numeric_std.all;

entity tb_booth_enc is
end tb_booth_enc;

architecture test of tb_booth_enc is
  component booth_encoder IS
    generic ( N :   integer := 25);
        port( A :   in  std_logic_vector(N-1 downto 0);
              B :   in  std_logic_vector(2 downto 0);
              Z :   out std_logic_vector(N+1 downto 0)
              );
  end component;

  constant N  : integer := 24;

  signal A : std_logic_vector(N-1 downto 0);
  signal B : std_logic_vector(2 downto 0);
  signal Z : std_logic_vector(N+1 downto 0);
begin  -- test

  DUT: booth_encoder
    generic map (N)
    port map (A,B,Z);

  A <= std_logic_vector(to_unsigned( 32,N));

  input_gen: process
    begin
      B <= "000";
      wait for 1 ns;
      B <= "001";
      wait for 1 ns;
      B <= "010";
      wait for 1 ns;
      B <= "011";
      wait for 1 ns;
      B <= "100";
      wait for 1 ns;
      B <= "101";
      wait for 1 ns;
      B <= "110";
      wait for 1 ns;
      B <= "111";
      wait for 1 ns;
      wait;
  end process;


end test;
