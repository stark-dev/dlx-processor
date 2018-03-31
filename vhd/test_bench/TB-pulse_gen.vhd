library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_pulse_gen is
end tb_pulse_gen;

architecture test of tb_pulse_gen is
  component pulse_gen IS
  	 GENERIC (N : integer := 16);
      	PORT (
  				clk			: IN	std_logic;
  				rst_n		: IN	std_logic;
  				trigger	: IN	std_logic;
  				pulse		: OUT std_logic
  			);
  END component;

  constant N  : integer := 4;

  signal clk_t      : std_logic;
  signal rst_n_t    : std_logic;
  signal trigger_t  : std_logic;
  signal pulse_t    : std_logic;

begin  -- test

  DUT: pulse_gen
    generic map (N)
       port map (clk_t, rst_n_t, trigger_t, pulse_t);

  clk_p : process
  begin
    wait for 0.5 ns;
    clk_t <= '1';
    wait for 0.5 ns;
    clk_t <= '0';
  end process;

  input_gen: process
    begin
      rst_n_t   <= '0';
      trigger_t <= '0';
      wait for 2 ns;
      rst_n_t   <= '1';
      trigger_t <= '0';
      wait for 2 ns;
      rst_n_t   <= '1';
      trigger_t <= '1';
      wait for 2 ns;
      rst_n_t   <= '1';
      trigger_t <= '0';
      wait for 2 ns;
      rst_n_t   <= '1';
      trigger_t <= '1';
      wait for 4 ns;
      rst_n_t   <= '1';
      trigger_t <= '0';
      wait for 2 ns;
      rst_n_t   <= '1';
      trigger_t <= '1';
      wait for 8 ns;
      rst_n_t   <= '1';
      trigger_t <= '0';
      wait for 2 ns;
      rst_n_t   <= '1';
      trigger_t <= '1';
      wait for 20 ns;
      rst_n_t   <= '1';
      trigger_t <= '0';
      wait for 2 ns;
      rst_n_t   <= '1';
      trigger_t <= '1';
      wait for 20 ns;
      rst_n_t   <= '1';
      trigger_t <= '0';
      wait;
  end process;

end test;
