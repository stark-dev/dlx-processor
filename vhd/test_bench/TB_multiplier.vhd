library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity MULTIPLIER_tb is
end MULTIPLIER_tb;


architecture TEST of MULTIPLIER_tb is


  constant N : integer := 24;    -- :=8  --:=16

  --  input
  signal A_mp_i : std_logic_vector(N-1 downto 0) := std_logic_vector(to_unsigned(75, N));
  signal B_mp_i : std_logic_vector(N-1 downto 0) := (others => '0');

  -- output
  signal Y_mp_i : std_logic_vector(2*N-1 downto 0);
  signal S_Un_i : std_logic;

  signal error : std_logic;

  component multiplier IS
    generic ( N :         integer := 24);
        port( A :     in  std_logic_vector(N-1 downto 0);
              B :     in  std_logic_vector(N-1 downto 0);
              S_Un :  in  std_logic;    -- 0 -> unsigned; 1 -> signed
              Z :     out std_logic_vector(2*N-1 downto 0)
              );
  end component;


begin

  DUT : multiplier
    generic map (N)
    port map (A_mp_i, B_mp_i, S_Un_i, Y_mp_i);

   S_Un_i <= '0';

-- PROCESS FOR TESTING TEST - COMLETE CYCLE ---------
  test: process
  begin
  
  A_mp_i <= "111000010010100000000000";
  B_mp_i <= "101011101011001010101010";
  wait for 20 ns;
    
    -- cycle for operand A
    NumROW : for i in 0 to 2**(N)-1 loop
	
        -- cycle for operand B
    	NumCOL : for i in 0 to 2**(N)-1 loop
	    wait for 1 ns;
	    B_mp_i <= B_mp_i + '1';
	end loop NumCOL ;

	A_mp_i <= A_mp_i + '1'; 	
    end loop NumROW ;

    wait;
  end process test;

  test_error : process(Y_mp_i)
  variable product : integer;
  begin
      if S_Un_i = '0' then
         product := To_Integer(Unsigned(A_mp_i) * Unsigned(B_mp_I) - Unsigned(Y_mp_i));
      else
         product := To_Integer(Signed(A_mp_i) * Signed(B_mp_I) - Signed(Y_mp_i));
      end if;
      if(product = 0) then
         error <= '0';
      else
         error <= '1';
      end if;
  end process;

end TEST;
