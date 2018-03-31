library ieee;
use ieee.std_logic_1164.all;

ENTITY WallaceTree IS
  PORT(  CLK  : IN std_logic;
         RST_N: IN std_logic;
         PIPELINE_EN : IN std_logic;
         PP1  : IN std_logic_vector(26 downto 0);
         PP2  : IN std_logic_vector(26 downto 0);
         PP3  : IN std_logic_vector(28 downto 0);
         PP4  : IN std_logic_vector(30 downto 0);
         PP5  : IN std_logic_vector(32 downto 0);
         PP6  : IN std_logic_vector(34 downto 0);
         PP7  : IN std_logic_vector(36 downto 0);
         PP8  : IN std_logic_vector(38 downto 0);
         PP9  : IN std_logic_vector(40 downto 0);
         PP10 : IN std_logic_vector(42 downto 0);
         PP11 : IN std_logic_vector(44 downto 0);
         PP12 : IN std_logic_vector(46 downto 0);
         PP13 : IN std_logic_vector(48 downto 0);
         SUM  : OUT std_logic_vector(47 downto 0));
END ENTITY;

ARCHITECTURE Structural OF WallaceTree IS

  component reg
    generic(N : integer := 1;
            RESET_VALUE : integer := 0);
    Port (	D:	In	std_logic_vector(N-1 downto 0);
            CK:	In	std_logic;
            RESET:	In	std_logic;
            EN:     in      std_logic;
            Q:	Out	std_logic_vector(N-1 downto 0));
  end component ;

  component  CSA
    generic (N  : integer := 8);
    PORT(  A,B, C  : in  std_logic_vector(N-1 downto 0);
           S    : out std_logic_vector(N-1 downto 0);
           Cout : out std_logic_vector(N-1 downto 0));
  end component;

  component CLA
    generic(N : integer := 32);
    port  (A   :  IN   std_logic_vector(N-1 downto 0);
           B   :  IN   std_logic_vector(N-1 downto 0);
           Cin :  IN   std_logic;
           S   :  OUT  std_logic_vector(N-1 downto 0);
           Cout :  OUT  STD_LOGIC);
    end component;



  signal PP1_ext : std_logic_vector(28 downto 0);
  signal PP2_ext : std_logic_vector(28 downto 0);
  signal PP4_ext : std_logic_vector(34 downto 0);
  signal PP5_ext : std_logic_vector(34 downto 0);
  signal PP7_ext : std_logic_vector(40 downto 0);
  signal PP8_ext : std_logic_vector(40 downto 0);
  signal PP10_ext : std_logic_vector(46 downto 0);
  signal PP11_ext : std_logic_vector(46 downto 0);

  signal PP1_delayed : std_logic_vector(1 downto 0);

  signal sum1 : std_logic_vector(34 downto 0);
  signal sum2 : std_logic_vector(34 downto 0);
  signal sum3 : std_logic_vector(41 downto 0);
  signal sum4 : std_logic_vector(48 downto 0);
  signal sum5 : std_logic_vector(41 downto 0);
  signal sum6 : std_logic_vector(41 downto 0);
  signal sum7 : std_logic_vector(49 downto 0);
  signal sum8 : std_logic_vector(49 downto 0);
  signal sum9 : std_logic_vector(49 downto 0);
  signal sum10 : std_logic_vector(50 downto 0);
  signal sum11 : std_logic_vector(51 downto 0);
  signal sum11_delayed : std_logic_vector(51 downto 0);

  signal carry1 : std_logic_vector(34 downto 0);
  signal carry2 : std_logic_vector(41 downto 0);
  signal carry3 : std_logic_vector(41 downto 0);
  signal carry4 : std_logic_vector(48 downto 0);
  signal carry5 : std_logic_vector(41 downto 0);
  signal carry6 : std_logic_vector(49 downto 0);
  signal carry7 : std_logic_vector(49 downto 0);
  signal carry8 : std_logic_vector(49 downto 0);
  signal carry9 : std_logic_vector(50 downto 0);
  signal carry10 : std_logic_vector(50 downto 0);
  signal carry11 : std_logic_vector(51 downto 0);
  signal carry11_delayed : std_logic_vector(51 downto 0);

  signal sum_cla : std_logic_vector(51 downto 0);
  signal C_out : std_logic;



BEGIN

  csa1 : CSA
    generic map(29)
    port map(PP1_ext, PP2_ext, PP3, sum1(28 downto 0), carry1(29 downto 1));

  csa2 : CSA
    generic map(35)
    port map(PP4_ext, PP5_ext, PP6, sum2, carry2(35 downto 1));

  csa3 : CSA
    generic map(41)
    port map(PP7_ext, PP8_ext, PP9, sum3(40 downto 0), carry3(41 downto 1));

  csa4 : CSA
    generic map(47)
    port map(PP10_ext, PP11_ext, PP12, sum4(46 downto 0), carry4(47 downto 1));

  csa5 : CSA
    generic map(35)
    port map(sum1, carry1, sum2, sum5(34 downto 0), carry5(35 downto 1));

  csa6 : CSA
    generic map(42)
    port map(carry2, sum3, carry3, sum6, carry6(42 downto 1));

  csa7 : CSA
    generic map(49)
    port map(sum4, carry4, PP13, sum7(48 downto 0), carry7(49 downto 1));

  csa8 : CSA
    generic map(42)
    port map(sum5, carry5, sum6, sum8(41 downto 0), carry8(42 downto 1));

  csa9 : CSA
    generic map(50)
    port map(carry6, sum7, carry7, sum9, carry9(50 downto 1));

  csa10 : CSA
    generic map(50)
    port map(sum8, carry8, sum9, sum10(49 downto 0), carry10(50 downto 1));

  csa11 : CSA
    generic map(51)
    port map(sum10, carry10, carry9, sum11(50 downto 0), carry11(51 downto 1));

  pipeline_reg_1 : REG
    generic map(52)
    port map(sum11, CLK, RST_N, PIPELINE_EN, sum11_delayed);

  pipeline_reg_2 : REG
    generic map(52)
    port map(carry11, CLK, RST_N, PIPELINE_EN, carry11_delayed);

  carryLookAhead: CLA
    generic map(52)
    port map(sum11_delayed, carry11_delayed, '0', sum_cla, C_out);

  pipeline_reg_3 : REG
    generic map(2)
    port map(PP1(1 downto 0), CLK, RST_N, PIPELINE_EN, PP1_delayed);

  carry1(0) <= '0';
  carry2(0) <= '0';
  carry3(0) <= '0';
  carry4(0) <= '0';
  carry5(0) <= '0';
  carry6(0) <= '0';
  carry7(0) <= '0';
  carry8(0) <= '0';
  carry9(0) <= '0';
  carry10(0) <= '0';
  carry11(0) <= '0';

  PP1_ext(28 downto 25) <= (others => PP1(26));
  PP1_ext(24 downto 0)  <= PP1(26 downto 2);

  PP2_ext(28 downto 27) <= (others => PP2(26));
  PP2_ext(26 downto 0)  <= PP2;

  PP4_ext(34 downto 31) <= (others => PP4(30));
  PP4_ext(30 downto 0)  <= PP4;

  PP5_ext(34 downto 33) <= (others => PP5(32));
  PP5_ext(32 downto 0)  <= PP5;

  PP7_ext(40 downto 37) <= (others => PP7(36));
  PP7_ext(36 downto 0)  <= PP7;

  PP8_ext(40 downto 39) <= (others => PP8(38));
  PP8_ext(38 downto 0)  <= PP8;

  PP10_ext(46 downto 43) <= (others => PP10(42));
  PP10_ext(42 downto 0)  <= PP10;

  PP11_ext(46 downto 45) <= (others => PP11(44));
  PP11_ext(44 downto 0)  <= PP11;


  sum1(34 downto 29) <= (others => sum1(28));
  sum3(41) <= sum3(40);
  sum4(48 downto 47) <= (others => sum4(46));
  sum5(41 downto 35) <= (others => sum5(34));
  sum7(49) <= sum7(48);
  sum8(49 downto 42) <= (others => sum8(41));
  sum10(50) <= sum10(49);
  sum11(51) <= sum11(50);


  carry1(34 downto 30) <= (others => carry1(29));
  carry2(41 downto 36) <= (others => carry2(35));
  carry4(48) <= carry4(47);
  carry5(41 downto 36) <= (others => carry5(35));
  carry6(49 downto 43) <= (others => carry6(42));
  carry8(49 downto 43) <= (others => carry8(42));

  SUM(0) <= PP1_delayed(0);
  SUM(1) <= PP1_delayed(1);
  SUM(47 downto 2) <= sum_cla(45 downto 0);

END ARCHITECTURE;
