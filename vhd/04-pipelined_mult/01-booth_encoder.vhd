library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY booth_encoder IS
  generic ( N :   integer := 25);
      port( A :   in  std_logic_vector(N-1 downto 0);
            B :   in  std_logic_vector(2 downto 0);
            Z :   out std_logic_vector(N+1 downto 0)
            );
END ENTITY;

ARCHITECTURE behavioral OF booth_encoder IS

signal  A_neg   : std_logic_vector(N-1 downto 0);
signal  ones    : std_logic_vector(N-1 downto 0) := (others => '1');

BEGIN

   A_neg <= std_logic_vector(unsigned(A XOR ones) + 1);

   enc: process(A,A_neg,B)
   begin
      case B is
         when "000" => Z <= (others => '0');                -- +0
         when "001" => Z <= A(N-1) & A(N-1) & A;            -- +A
         when "010" => Z <= A(N-1) & A(N-1) & A;            -- +A
         when "011" => Z <= A(N-1) & A & '0';               -- +2A
         when "100" => Z <= A_neg(N-1) & A_neg & '0';       -- -2A
         when "101" => Z <= A_neg(N-1) & A_neg(N-1) & A_neg;-- -A
         when "110" => Z <= A_neg(N-1) & A_neg(N-1) & A_neg;-- -A
         when "111" => Z <= (others => '0');                -- +0
         when others => Z <= (others => '0');
      end case;
   end process;

END ARCHITECTURE;
