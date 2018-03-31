library ieee;
use ieee.std_logic_1164.all;
use work.DLX_package.all;
use ieee.numeric_std.all;

entity tb_ppg is
end tb_ppg;

architecture test of tb_ppg is
  component ppg IS
    port( A   :   in  std_logic_vector(24 downto 0);
          B   :   in  std_logic_vector(24 downto 0);
          Z0  :   out std_logic_vector(26 downto 0);
          Z1  :   out std_logic_vector(26 downto 0);
          Z2  :   out std_logic_vector(28 downto 0);
          Z3  :   out std_logic_vector(30 downto 0);
          Z4  :   out std_logic_vector(32 downto 0);
          Z5  :   out std_logic_vector(34 downto 0);
          Z6  :   out std_logic_vector(36 downto 0);
          Z7  :   out std_logic_vector(38 downto 0);
          Z8  :   out std_logic_vector(40 downto 0);
          Z9  :   out std_logic_vector(42 downto 0);
          Z10 :   out std_logic_vector(44 downto 0);
          Z11 :   out std_logic_vector(46 downto 0);
          Z12 :   out std_logic_vector(48 downto 0)
        );
  end component;

  signal  A_s   : std_logic_vector(24 downto 0);
  signal  B_s   : std_logic_vector(24 downto 0);
  signal  Z0_s  : std_logic_vector(26 downto 0);
  signal  Z1_s  : std_logic_vector(26 downto 0);
  signal  Z2_s  : std_logic_vector(28 downto 0);
  signal  Z3_s  : std_logic_vector(30 downto 0);
  signal  Z4_s  : std_logic_vector(32 downto 0);
  signal  Z5_s  : std_logic_vector(34 downto 0);
  signal  Z6_s  : std_logic_vector(36 downto 0);
  signal  Z7_s  : std_logic_vector(38 downto 0);
  signal  Z8_s  : std_logic_vector(40 downto 0);
  signal  Z9_s  : std_logic_vector(42 downto 0);
  signal  Z10_s : std_logic_vector(44 downto 0);
  signal  Z11_s : std_logic_vector(46 downto 0);
  signal  Z12_s : std_logic_vector(48 downto 0);
begin  -- test

  DUT: ppg
    port map (
    A   =>  A_s,
    B   =>  B_s,
    Z0  =>  Z0_s,
    Z1  =>  Z1_s,
    Z2  =>  Z2_s,
    Z3  =>  Z3_s,
    Z4  =>  Z4_s,
    Z5  =>  Z5_s,
    Z6  =>  Z6_s,
    Z7  =>  Z7_s,
    Z8  =>  Z8_s,
    Z9  =>  Z9_s,
    Z10 =>  Z10_s,
    Z11 =>  Z11_s,
    Z12 =>  Z12_s
    );

  input_gen: process
    begin
      A_s <= std_logic_vector(to_signed(23,25));
      B_s <= std_logic_vector(to_signed(84,25));
      wait;
  end process;


end test;
