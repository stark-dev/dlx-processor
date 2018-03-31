library ieee; 
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all; -- we need a conversion to unsigned 

entity TBP4ADDER is 
end TBP4ADDER; 

architecture TEST of TBP4ADDER is

  component p4_adder IS
     generic( N : integer := 32;
	      C_freq : integer :=4);
     port( A, B : in std_logic_vector(N downto 1);
	   Cin  : in std_logic;
	   S    : out std_logic_vector(N downto 1);
  	   Cout : out std_logic);
   end component;
   
   constant N      : integer := 64;
   constant C_freq : integer := 1;
   signal A, B, S    : std_logic_vector(N downto 1);
   signal Cin, Cout  : std_logic;  

Begin

   DUT : p4_adder
      generic map(N, C_freq)
      port map(A, B, Cin, S, Cout);


   stim_gen : process
   begin
        --sum
	A <= std_logic_vector(to_unsigned( 15,N));
        B <= std_logic_vector(to_unsigned( 10,N));
        Cin <= '0';
        wait for 1 ns;
	A <= std_logic_vector(to_unsigned( 100,N));
        B <= std_logic_vector(to_unsigned( 33,N));
        Cin <= '0';
        wait for 1 ns;
	A <= std_logic_vector(to_unsigned( 50,N));
        B <= std_logic_vector(to_unsigned( 10,N));
        Cin <= '0';
        wait for 1 ns;
	A <=(others => '1');
        B <= std_logic_vector(to_unsigned( 1,N));
        Cin <= '0';
        --subtraction
        wait for 1 ns;
	A <= std_logic_vector(to_unsigned( 10,N));
        B <= std_logic_vector(to_unsigned( 50,N));
        Cin <= '1';
        wait for 1 ns;
	A <= std_logic_vector(to_unsigned( 150,N));
        B <= std_logic_vector(to_unsigned( 30,N));
        Cin <= '1';
        wait;  
   end process;


end TEST;
