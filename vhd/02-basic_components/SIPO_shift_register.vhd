library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY SIPO_shift_register IS
  GENERIC( STAGES : positive := 8);
  PORT( CLK        : IN std_logic;
        RESET_N    : IN std_logic;
        ENABLE     : IN std_logic_vector(1 to STAGES);
        LOAD       : IN std_logic;
        LOAD_VALUE : IN std_logic_vector(1 to STAGES);
        DATA_IN    : IN std_logic;
        DATA_OUT   : OUT std_logic_vector(1 to STAGES)
        );
END ENTITY;

ARCHITECTURE Structural OF SIPO_shift_register IS

component flip_flop_load is
	Port (	D       :	In	std_logic;
		      CK      :	In	std_logic;
		      RESET   :	In	std_logic;
          LD_EN   : in  std_logic;
          LD_VAL  : in  std_logic;
          EN      : in  std_logic;
		      Q       :	Out	std_logic);
end component;

signal data_out_s : std_logic_vector(1 to STAGES);

BEGIN

  ff_gen: for i in 1 to STAGES generate
    first_stage : if i = 1 generate
      ff_1 : flip_flop_load
        port map(DATA_IN, CLK, RESET_N, LOAD, LOAD_VALUE(i), ENABLE(i), data_out_s(1));
      end generate first_stage;

    next_stages : if i > 1 generate
      ff_x : flip_flop_load
        port map(data_out_s(i-1), CLK, RESET_N, LOAD, LOAD_VALUE(i), ENABLE(i), data_out_s(i));
    end generate next_stages;
   end generate ff_gen;

  DATA_OUT <= data_out_s;

END ARCHITECTURE;
