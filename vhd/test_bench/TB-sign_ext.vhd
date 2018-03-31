library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sign_ext is
end tb_sign_ext;

architecture test of tb_sign_ext is
  component sign_extension IS
    generic ( N    :      integer := 24);
    port    ( IN1  : in   std_logic_vector(N-1 downto 0);
              IN2  : in   std_logic_vector(N-1 downto 0);
              S_Un : in   std_logic;        -- 1 -> signed; 0 -> unsigned
              OUT1 : out  std_logic_vector(N downto 0);
              OUT2 : out  std_logic_vector(N downto 0)
            );
  end component;

  constant N  : integer := 24;

  signal A : std_logic_vector(N-1 downto 0);
  signal B : std_logic_vector(N-1 downto 0);
  signal S : std_logic;
  signal Y : std_logic_vector(N downto 0);
  signal Z : std_logic_vector(N downto 0);


begin  -- test

  DUT: sign_extension
    generic map ( N )
       port map ( A, B, S, Y, Z);

  input_gen: process
    begin
      S <= '1';
      A <= (others => '0');
      B <= (others => '1');
      wait for 1 ns;
      S <= '1';
      A <= (others => '1');
      B <= (others => '0');
      wait for 1 ns;
      S <= '0';
      A <= (others => '0');
      B <= (others => '1');
      wait for 1 ns;
      S <= '0';
      A <= (others => '1');
      B <= (others => '0');
      wait;
  end process;

end test;
