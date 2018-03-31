library ieee;
use ieee.std_logic_1164.all;

ENTITY Shifter IS
	generic(N : integer := 32);
	port( 	R	       : IN std_logic_vector(N-1 downto 0);
		arith_logicaln : IN std_logic;
		right_leftn    : IN std_logic;
		count	       : IN std_logic_vector(4 downto 0);
		R_OUT	       : OUT std_logic_vector(N-1 downto 0));
END ENTITY;

ARCHITECTURE Structural OF Shifter IS
	type mask_array is array(3 downto 0) of std_logic_vector(N-1+7 downto 0);
	signal mask : mask_array; 
	signal shifted_data : std_logic_vector(N-1+7 downto 0);
	signal count_sel : std_logic_vector(2 downto 0);
	signal right_leftn_ext : std_logic_vector(2 downto 0);

	component Mux2to1
   	 generic (N:integer := 16);
    	 Port (
	   A:	In	std_logic_vector (N-1 downto 0);
       	   B:	In	std_logic_vector (N-1 downto 0);
	   S:	In	std_logic;
	   Y:	Out	std_logic_vector (N-1 downto 0));
  	end component;

	component Mux8to1
	 generic (N:integer := 16);
    	 Port (
	   In1:	In	std_logic_vector (N-1 downto 0);
       	   IN2:	In	std_logic_vector (N-1 downto 0);
       	   IN3:	In	std_logic_vector (N-1 downto 0);
       	   IN4:	In	std_logic_vector (N-1 downto 0);
	   In5:	In	std_logic_vector (N-1 downto 0);
       	   IN6:	In	std_logic_vector (N-1 downto 0);
       	   IN7:	In	std_logic_vector (N-1 downto 0);
       	   IN8:	In	std_logic_vector (N-1 downto 0);
	   S:	In	std_logic_vector(2 downto 0);
	   Y:	Out	std_logic_vector (N-1 downto 0));
  	end component;

	component Mux4to1
	 generic (N:integer := 16);
    	 Port (
	   In1:	In	std_logic_vector (N-1 downto 0);
       	   IN2:	In	std_logic_vector (N-1 downto 0);
       	   IN3:	In	std_logic_vector (N-1 downto 0);
       	   IN4:	In	std_logic_vector (N-1 downto 0);
	   S:	In	std_logic_vector(1 downto 0);
	   Y:	Out	std_logic_vector (N-1 downto 0));
  	end component;
BEGIN
	level1 : for i in 0 to 3 generate
		signal sh_left, sh_right : std_logic_vector(N-1+7 downto 0);
	begin
		sh_left(8*(i+1)-2 downto 0)<= (others => '0');
		sh_left(N-1+7 downto 8*(i+1)-1) <= R(N-1-(8*i) downto 0);
		sh_right(N-1+7 downto N-(8*i)) <= (others => arith_logicaln and R(N-1));
		sh_right(N-1-(8*i) downto 0) <= R(N-1 downto 8*i);

		mux : mux2to1
		  generic map(N+7)
		  port map(sh_left, sh_right, right_leftn, mask(i));

	end generate;

	level2 : mux4to1
	  generic map(N+7)
	  port map(mask(0), mask(1), mask(2), mask(3), count(4 downto 3), shifted_data);
	
	right_leftn_ext <= (others => right_leftn);
	count_sel <= count(2 downto 0) xnor right_leftn_ext;

	level3 : mux8to1
	  generic map(N)
	  port map(shifted_data(N-1 downto 0), shifted_data(N downto 1), shifted_data(N+1 downto 2), shifted_data(N+2 downto 3),
		   shifted_data(N+3 downto 4), shifted_data(N+4 downto 5), shifted_data(N+5 downto 6), shifted_data(N+6 downto 7), 
		   count_sel, R_OUT);
	
END ARCHITECTURE;
		