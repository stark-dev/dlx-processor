library ieee;
use ieee.std_logic_1164.all;
use work.DLX_package.all;
use ieee.numeric_std.all;

ENTITY Branch IS
  Generic( N : integer :=32);
  Port( A               : IN std_logic_vector(N-1 downto 0);  --register to be compared
        BRANCH_OP       : IN branchOp;                        --branch or jump
	      BRANCH_OUT      : OUT std_logic);                     --branch taken
END ENTITY;

ARCHITECTURE Behavioral OF Branch IS

BEGIN

  OUT_ASSIGNMENT : process(A, BRANCH_OP)
  begin
    BRANCH_OUT <= '0';

    case BRANCH_OP is
      when BNEZ =>
        if unsigned(A) /= 0 then
          BRANCH_OUT <= '1';
        end if;
      when BEQZ =>
        if unsigned(A) = 0 then
          BRANCH_OUT <= '1';
        end if;
      when J    => BRANCH_OUT <= '1';
      when JAL  => BRANCH_OUT <= '1';
      when JR   => BRANCH_OUT <= '1';
      when JALR => BRANCH_OUT <= '1';
      when RFE  => BRANCH_OUT <= '1';
      when others => BRANCH_OUT <= '0';
    end case;
  end process;

END ARCHITECTURE;
