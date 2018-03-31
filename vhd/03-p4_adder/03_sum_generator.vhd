library ieee;
use ieee.std_logic_1164.all;

entity sum_generator is
  generic ( N_BLOCKS : integer := 4;    --number of CSA used
            N_BIT_SINGLE_BLOCK : integer := 4);  --number of bits of each CSA
  port ( A, B : in  std_logic_vector ((N_BIT_SINGLE_BLOCK*N_BLOCKS - 1) downto 0);
         Cin  : in  std_logic_vector (N_BLOCKS - 1 downto 0);
         S    : out std_logic_vector ((N_BIT_SINGLE_BLOCK*N_BLOCKS - 1) downto 0));
end entity;

architecture structural of sum_generator is

component CarrySelectAdder IS
  generic (N  : integer := 8);
  PORT(  A,B  : in  std_logic_vector(N-1 downto 0);
         Cin  : in  std_logic;
         S    : out std_logic_vector(N-1 downto 0);
         Cout : out std_logic);

end component;

--singnals

signal carry : std_logic_vector (N_BLOCKS - 1 downto 0);

begin  -- structural

  csa_gen : for i in 1 to N_BLOCKS generate  --instantiation of the CSA components
    blocks : CarrySelectAdder generic map(N_BIT_SINGLE_BLOCK)
                 port map (A(N_BIT_SINGLE_BLOCK*i -1 downto N_BIT_SINGLE_BLOCK*(i-1)),
                           B(N_BIT_SINGLE_BLOCK*i -1 downto N_BIT_SINGLE_BLOCK*(i-1)),
                           Cin(i-1),
                           S(N_BIT_SINGLE_BLOCK*i -1 downto N_BIT_SINGLE_BLOCK*(i-1)),
                           carry (i - 1));
  end generate csa_gen;
end architecture;
