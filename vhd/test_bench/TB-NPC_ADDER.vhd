library ieee;
use ieee.std_logic_1164.all;
use work.DLX_package.all;
use ieee.numeric_std.all;

entity tb_npc_adder is
end tb_npc_adder;

architecture test of tb_npc_adder is
  component NPC_adder IS
    generic( N : integer := 32);
    port(    D : IN  std_logic_vector(N-1 downto 0);
             O : OUT std_logic_vector(N-1 downto 0));
  end component;
  
  constant N  : integer := Nbit;
  signal D : std_logic_vector(N-1 downto 0);
  signal O : std_logic_vector(N-1 downto 0);
begin  -- test
  
  DUT: NPC_adder
    generic map (N)
    port map (D,O);

  input_gen: process
    begin
      D <= std_logic_vector(to_unsigned( 0,N));
      wait for 1 ns;
      D <= std_logic_vector(to_unsigned( 16,N));
      wait for 1 ns;
      D <= std_logic_vector(to_unsigned( 23,N));
      wait for 1 ns;
      D <= std_logic_vector(to_unsigned( 80,N));
      wait for 1 ns;
      D <= std_logic_vector(to_unsigned( 15,N));
      wait for 1 ns;
      D <= std_logic_vector(to_unsigned( 901,N));
      wait;
  end process;
    

end test;
