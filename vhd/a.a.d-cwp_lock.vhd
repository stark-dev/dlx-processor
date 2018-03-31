library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use WORK.DLX_package.all;

ENTITY cwp_lock IS
  PORT( RESET_N               : IN std_logic;
        CLK                   : IN std_logic;
        INT_SR_ENABLE         : IN std_logic_vector(1 to INTEGER_PIPE_LENGTH+1);
        MUL_SR_ENABLE         : IN std_logic_vector(1 to MULT_PIPE_LENGTH+1);
        ADD_SR_ENABLE         : IN std_logic_vector(1 to FP_ADD_PIPE_LENGTH+1);
        CEL_SR_LOAD           : IN std_logic;
        INT_SR_LOAD_VALUE     : IN std_logic_vector(1 to INTEGER_PIPE_LENGTH+1);
        MUL_SR_LOAD_VALUE     : IN std_logic_vector(1 to MULT_PIPE_LENGTH+1);
        ADD_SR_LOAD_VALUE     : IN std_logic_vector(1 to FP_ADD_PIPE_LENGTH+1);
        DATA_OUT              : OUT std_logic
        );
END ENTITY;

ARCHITECTURE Structural OF cwp_lock IS

  component SIPO_shift_register IS
    GENERIC( STAGES : positive := 8);
    PORT( CLK        : IN std_logic;
          RESET_N    : IN std_logic;
          ENABLE     : IN std_logic_vector(1 to STAGES);
          LOAD       : IN std_logic;
          LOAD_VALUE : IN std_logic_vector(1 to STAGES);
          DATA_IN    : IN std_logic;
          DATA_OUT   : OUT std_logic_vector(1 to STAGES)
          );
  end component;

  signal int_out : std_logic_vector(1 to INTEGER_PIPE_LENGTH+1);
  signal mul_out : std_logic_vector(1 to MULT_PIPE_LENGTH+1);
  signal add_out : std_logic_vector(1 to FP_ADD_PIPE_LENGTH+1);

BEGIN

  int_sr : SIPO_shift_register
    generic map(INTEGER_PIPE_LENGTH+1)
    port map(CLK, RESET_N, INT_SR_ENABLE, CEL_SR_LOAD, INT_SR_LOAD_VALUE, '0', int_out);

  mul_sr : SIPO_shift_register
    generic map(MULT_PIPE_LENGTH+1)
    port map(CLK, RESET_N, MUL_SR_ENABLE, CEL_SR_LOAD, MUL_SR_LOAD_VALUE, '0', mul_out);

  add_sr : SIPO_shift_register
    generic map(FP_ADD_PIPE_LENGTH+1)
    port map(CLK, RESET_N, ADD_SR_ENABLE, CEL_SR_LOAD, ADD_SR_LOAD_VALUE, '0', add_out);

  DATA_OUT <= or_reduce(int_out) or or_reduce(mul_out) or or_reduce(add_out);


END ARCHITECTURE;
