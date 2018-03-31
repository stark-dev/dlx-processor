library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.DLX_package.all;

ENTITY register_file IS
 GENERIC( N_bit : integer := 32;
          N : integer := 8;             -- Number of registers in each IN, OUT and LOCALS
          F : integer := 4;             -- Number of windows
          M : integer := 8);            -- Number of global registers
 PORT (  RESET_N: 	IN std_logic;
   CLK :    IN std_logic;
	 ENABLE: 	IN std_logic;
	 WR: 		  IN std_logic;
   WR_SP:   IN std_logic;
   WR_SR:   IN std_logic;
   FP_INTn_RD1 :IN std_logic;
   FP_INTn_RD2 :IN std_logic;
   FP_INTn_WR :IN std_logic;
	 ADD_WR: 	IN std_logic_vector(up_int_log2(3*N+M)-1 downto 0);
	 ADD_RD1: IN std_logic_vector(up_int_log2(3*N+M)-1 downto 0);
	 ADD_RD2: IN std_logic_vector(up_int_log2(3*N+M)-1 downto 0);
	 DATAIN: 	IN std_logic_vector(N_bit-1 downto 0);
   DATAIN_SP: IN std_logic_vector(N_bit-1 downto 0);
   DATAIN_SR : IN std_logic_vector(N_bit-1 downto 0);

   CWP:     IN unsigned(up_int_log2(F)-1 downto 0);

   OUT1: 		OUT std_logic_vector(N_bit-1 downto 0);
   OUT2: 		OUT std_logic_vector(N_bit-1 downto 0);
   OUT_SR  : OUT std_logic_vector(N_bit-1 downto 0);
   OUT_CR  : OUT std_logic_vector(N_bit-1 downto 0));
END register_file;

ARCHITECTURE Behavioral OF register_file IS

   -- suggested structures
  subtype REG_ADDR is natural range 0 to 2*N*F+M-1;
	type REG_ARRAY is array(REG_ADDR) of std_logic_vector(N_bit-1 downto 0);
	signal REGISTERS_INT : REG_ARRAY;
  signal REGISTERS_FP  : REG_ARRAY;
  signal  add_wr_ph, add_rd1_ph, add_rd2_ph : std_logic_vector(up_int_log2(2*N*F+M)-1 downto 0);

BEGIN

  Physical_Address: process(ADD_WR, ADD_RD1, ADD_RD2, CWP)
  begin

    if and_reduce(ADD_WR(up_int_log2(3*N+M)-1 downto up_int_log2(M))) = '1' then  --checks if the all elements of the array are
                                                                            --one (it means that the address points to a global
                                                                            --variable
      add_wr_ph(up_int_log2(2*N*F+M)-1) <= '1';  -- MSB = 1
      add_wr_ph(up_int_log2(2*N*F+M)-2 downto up_int_log2(M)) <= (others => '0');
      add_wr_ph(up_int_log2(M)-1 downto 0) <= ADD_WR(up_int_log2(M)-1 downto 0);
    else                        -- the address refers to a IN, LOC, or OUT
      add_wr_ph(up_int_log2(2*N*F+M)-1) <= '0';  -- MSB = 0
      add_wr_ph(up_int_log2(2*N*F+M)-2 downto up_int_log2(2*N)) <= std_logic_vector(CWP + resize(unsigned(ADD_WR(up_int_log2(2*N) downto up_int_log2(2*N) )), up_int_log2(F)));
      add_wr_ph(up_int_log2(2*N)-1 downto 0) <= ADD_WR(up_int_log2(2*N)-1 downto 0);
    end if;

    if and_reduce(ADD_RD1(up_int_log2(3*N+M)-1 downto up_int_log2(M))) = '1' then  --checks if the all elements of the array are one
      add_rd1_ph(up_int_log2(2*N*F+M)-1) <= '1';  -- MSB = 1
      add_rd1_ph(up_int_log2(2*N*F+M)-2 downto up_int_log2(M)) <= (others => '0');
      add_rd1_ph(up_int_log2(M)-1 downto 0) <= ADD_RD1(up_int_log2(M)-1 downto 0);
    else
      add_rd1_ph(up_int_log2(2*N*F+M)-1) <= '0';  -- MSB = 0
      add_rd1_ph(up_int_log2(2*N*F+M)-2 downto up_int_log2(2*N)) <= std_logic_vector(CWP + resize(unsigned(ADD_RD1(up_int_log2(2*N) downto up_int_log2(2*N) )), up_int_log2(F)));
      add_rd1_ph(up_int_log2(2*N)-1 downto 0) <= ADD_RD1(up_int_log2(2*N)-1 downto 0);
    end if;

    if and_reduce(ADD_RD2(up_int_log2(3*N+M)-1 downto up_int_log2(M))) = '1' then  --checks if the all elements of the array are one
      add_rd2_ph(up_int_log2(2*N*F+M)-1) <= '1';  -- MSB = 1
      add_rd2_ph(up_int_log2(2*N*F+M)-2 downto up_int_log2(M)) <= (others => '0');
      add_rd2_ph(up_int_log2(M)-1 downto 0) <= ADD_RD2(up_int_log2(M)-1 downto 0);
    else
      add_rd2_ph(up_int_log2(2*N*F+M)-1) <= '0';  -- MSB = 0
      add_rd2_ph(up_int_log2(2*N*F+M)-2 downto up_int_log2(2*N)) <= std_logic_vector(CWP + resize(unsigned(ADD_RD2(up_int_log2(2*N) downto up_int_log2(2*N) )), up_int_log2(F)));
      add_rd2_ph(up_int_log2(2*N)-1 downto 0) <= ADD_RD2(up_int_log2(2*N)-1 downto 0);
    end if;

  end process Physical_Address;


  RF: process (RESET_N, CLK)
  begin  -- process RF

    if RESET_N='0' then
      REGISTERS_INT <= (others => (others => '0'));
      REGISTERS_FP <= (others => (others => '0'));

      REGISTERS_INT(SP_index) <= (std_logic_vector(to_unsigned(DRAM_DEPTH-4, N_bit)));  --stack pointer starts from highest address
      REGISTERS_INT(CR_index) <= "00000000000000001111111100000011";                    --control register default value
      -- TODO REMOVE
      reset_loop : for i in 0 to 63 loop
        REGISTERS_INT(i) <= std_logic_vector((to_unsigned(i, Nbit)));
        REGISTERS_FP(i) <= std_logic_vector((to_unsigned(i+64, Nbit)));
      end loop;
      -- REGISTERS_INT(1) <= (std_logic_vector(to_unsigned(1, Nbit)));
      -- REGISTERS_INT(2) <= (std_logic_vector(to_unsigned(255, Nbit)));
      -- REGISTERS_INT(3) <= "10000000000000000000000000101010";
      -- REGISTERS_INT(4) <= (std_logic_vector(to_unsigned(1145340458, Nbit)));
    elsif CLK'event and CLK='0' then
      if ENABLE='1' then
        if WR='1' then
          if FP_INTn_WR = '0' and to_integer(unsigned(add_wr_ph)) /= SR_index then
            REGISTERS_INT(to_integer(unsigned(add_wr_ph))) <= DATAIN;
          else
            REGISTERS_FP(to_integer(unsigned(add_wr_ph))) <= DATAIN;
          end if;
        end if;

        if WR_SP='1' then
          REGISTERS_INT(SP_index) <= DATAIN_SP;
        end if;
        if WR_SR = '1' then
          REGISTERS_INT(SR_index) <= DATAIN_SR;
        end if;
      end if;
    end if;
    REGISTERS_INT((2*F-3)*N+24) <= (others => '0'); --R24 = 0
    REGISTERS_FP((2*F-3)*N+24) <= (others => '0');  --F24 = 0
  end process RF;

    OUT1        <= REGISTERS_INT(to_integer(unsigned(add_rd1_ph))) when FP_INTn_RD1='0' else
                   REGISTERS_FP(to_integer(unsigned(add_rd1_ph)));
    OUT2        <= REGISTERS_INT(to_integer(unsigned(add_rd2_ph))) when FP_INTn_RD2='0' else
                   REGISTERS_FP(to_integer(unsigned(add_rd2_ph)));
    OUT_SR      <= REGISTERS_INT(SR_index);
    OUT_CR      <= REGISTERS_INT(CR_index);

END Behavioral;

----


configuration CFG_RF_BEH of register_file is
  for Behavioral
  end for;
end configuration;
