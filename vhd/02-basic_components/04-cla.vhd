LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY CLA IS
  GENERIC(N : integer := 32);
    PORT
        (A   :  IN   std_logic_vector(N-1 downto 0);
         B   :  IN   std_logic_vector(N-1 downto 0);
         Cin :  IN   std_logic;
         S   :  OUT  std_logic_vector(N-1 downto 0);
         Cout :  OUT  STD_LOGIC);
END ENTITY;

ARCHITECTURE behavioral OF CLA IS

  signal h_sum              :    std_logic_vector(N-1 downto 0);
  signal carry_generate     :    std_logic_vector(N-1 downto 0);
  signal carry_propagate    :    std_logic_vector(N-1 downto 0);
  signal carry_in_internal  :    std_logic_vector(N-1 downto 1);

BEGIN
    h_sum <= A xor B;
    carry_generate <= A AND B;
    carry_propagate <= A OR B;
    PROCESS (carry_generate,carry_propagate,carry_in_internal,Cin)
    BEGIN
    carry_in_internal(1) <= carry_generate(0) OR (carry_propagate(0) AND Cin);
        inst: FOR i IN 1 TO N-2 LOOP
              carry_in_internal(i+1) <= carry_generate(i) OR (carry_propagate(i) AND carry_in_internal(i));
              END LOOP;
    Cout <= carry_generate(N-1) OR (carry_propagate(N-1) AND carry_in_internal(N-1));
    END PROCESS;

    S(0) <= h_sum(0) XOR Cin;
    S(N-1 DOWNTO 1) <= h_sum(N-1 DOWNTO 1) XOR carry_in_internal(N-1 DOWNTO 1);
END behavioral;
