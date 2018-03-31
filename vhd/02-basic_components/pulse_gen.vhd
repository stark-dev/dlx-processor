library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY pulse_gen IS
	 GENERIC (N : integer := 16);
    	PORT (
				clk			: IN	std_logic;
				rst_n		: IN	std_logic;
				trigger	: IN	std_logic;
				pulse		: OUT std_logic
			);
END ENTITY;


architecture Behavioral of pulse_gen is

	component up_counter IS
		GENERIC(N     	 : integer := 16);
			PORT (CLK      : IN std_logic;
						RESET_N  : IN std_logic;
						EN       : IN std_logic;
						TC_value : IN std_logic_vector(N-1 downto 0);
						Q        : OUT std_logic_vector(N-1 downto 0);
						TC       : OUT std_logic);
	end component;

	constant trigger_counter_tc_value : std_logic_vector(N-1 downto 0) := (others => '1');

	signal trigger_clocked_1 : std_logic;
	signal trigger_clocked_2 : std_logic;
	signal trigger_clocked_d : std_logic; -- difference

	-- counter signals
	signal trigger_counter_en       : std_logic;
	signal trigger_counter_rst      : std_logic;
	signal trigger_counter_tc       : std_logic;
	signal trigger_counter_out      : std_logic_vector(N-1 downto 0);

begin

	trigger_clocked_d   <= trigger_clocked_1 and not(trigger_clocked_2);
	trigger_counter_rst <= rst_n and trigger;

	-- trigger counter control signals

	trigger_clock_p : process(rst_n, clk)
  begin
    if rst_n = '0' then
      trigger_clocked_1 <= '0';
      trigger_clocked_2 <= '0';
    elsif CLk'event and clk = '1' then
      trigger_clocked_1 <= trigger;
      trigger_clocked_2 <= trigger_clocked_1;
    end if;
  end process;

  trigger_counter_en_p : process(rst_n, clk)
  begin
    if clk'event and clk = '1' then
			if trigger_counter_tc = '1' or rst_n = '0' then
				trigger_counter_en <= '0';
    	elsif trigger_clocked_d = '1' then
        trigger_counter_en <= '1';
      end if;
    end if;
  end process;

	-- trigger delay counter

	trigger_counter : up_counter
		generic map(N)
		port map(
			CLK,
			trigger_counter_rst,
			trigger_counter_en,
			trigger_counter_tc_value,
			trigger_counter_out,
			trigger_counter_tc
		);

	pulse <= trigger_counter_tc;

end architecture;
