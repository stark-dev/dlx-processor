library ieee;
use ieee.std_logic_1164.all;

ENTITY p4_adder IS
  generic( N : integer := 32;           -- N must be a power of 2
	   C_freq : integer :=4);       -- C_freq must be a power of 2, not
                                        -- greater than N
  port( A, B : in std_logic_vector(N downto 1);
	Cin  : in std_logic;            -- Cin=0  --> S = A + B,
                                        -- Cin=1  --> S = A - B
	S    : out std_logic_vector(N downto 1);  -- result
  	Cout : out std_logic;          -- Carry out
	V    : out std_logic);		-- Overflow detection
END ENTITY;

ARCHITECTURE STRUCTURAL OF p4_adder IS

   component sum_generator
      generic ( N_BLOCKS : integer := 4;
                N_BIT_SINGLE_BLOCK : integer := 4);
      port ( A, B : in  std_logic_vector ((N_BIT_SINGLE_BLOCK*N_BLOCKS - 1) downto 0);
             Cin  : in  std_logic_vector (N_BLOCKS - 1 downto 0);
             S    : out std_logic_vector ((N_BIT_SINGLE_BLOCK*N_BLOCKS - 1) downto 0));
   end component;

   component carry_generator 
      generic (N : integer := 32;
               C_freq : integer := 4);
      port (A, B : in   std_logic_vector(N downto 1);
            Cin  : in   std_logic;
            Cout : out  std_logic_vector((N/C_freq) downto 1));
  end component;
  
  signal Cout_tmp : std_logic_vector((N/C_freq) downto 1);
  signal Cin_tmp  : std_logic_vector((N/C_freq) downto 1);  
  signal B_xor    : std_logic_vector(N downto 1);
  
BEGIN
   
   Cin_tmp <= Cout_tmp((N/C_freq)-1 downto 1) & Cin;
   xor_out:process(B, Cin)              -- B_xor is B after the exor ports,
                                        -- used to perform subtraction
   begin
     for i in N downto 1  loop
       B_xor(i) <= B(i) xor Cin;
     end loop;  -- i in N downto 1
   end process;
   carry_g: carry_generator             -- instantiation of the carry generator
      generic map(N, C_freq)
      port map(A, B_xor, Cin, Cout_tmp);

   sum_g: sum_generator                 -- instantiation of the sum generator
      generic map(N/C_freq, C_freq)
      port map(A, B_xor, Cin_tmp, S);

   Cout <= Cout_tmp(N/C_freq);          -- actual Cout, coming from the carry generator
   V <= Cout_tmp(N/C_freq) xor Cout_tmp((N/C_freq)-1);     -- Overflow signal

END ARCHITECTURE;
