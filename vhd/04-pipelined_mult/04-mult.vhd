library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY multiplier IS
  generic ( N :         integer := 24);
      port( CLK : IN std_logic;
            RST_N : IN std_logic;
            PIPELINE_EN : IN std_logic;
            A :     in  std_logic_vector(N-1 downto 0);
            B :     in  std_logic_vector(N-1 downto 0);
            S_Un :  in  std_logic;    -- 0 -> unsigned; 1 -> signed
            Z :     out std_logic_vector(2*N-1 downto 0)
            );
END ENTITY;

ARCHITECTURE behavioral OF multiplier IS

--components
  COMPONENT sign_extension IS
    generic ( N    :      integer := 24);
    port    ( IN1  : in   std_logic_vector(N-1 downto 0);
              IN2  : in   std_logic_vector(N-1 downto 0);
              S_Un : in   std_logic;        -- 1 -> signed; 0 -> unsigned
              OUT1 : out  std_logic_vector(N downto 0);
              OUT2 : out  std_logic_vector(N downto 0)
            );
  END COMPONENT;

  COMPONENT ppg IS
    port( A   :   in  std_logic_vector(24 downto 0);
          B   :   in  std_logic_vector(24 downto 0);
          Z0  :   out std_logic_vector(26 downto 0);
          Z1  :   out std_logic_vector(26 downto 0);
          Z2  :   out std_logic_vector(28 downto 0);
          Z3  :   out std_logic_vector(30 downto 0);
          Z4  :   out std_logic_vector(32 downto 0);
          Z5  :   out std_logic_vector(34 downto 0);
          Z6  :   out std_logic_vector(36 downto 0);
          Z7  :   out std_logic_vector(38 downto 0);
          Z8  :   out std_logic_vector(40 downto 0);
          Z9  :   out std_logic_vector(42 downto 0);
          Z10 :   out std_logic_vector(44 downto 0);
          Z11 :   out std_logic_vector(46 downto 0);
          Z12 :   out std_logic_vector(48 downto 0)
        );
  END COMPONENT;

  COMPONENT WallaceTree IS
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
  END COMPONENT;

--signals
  signal  ext_A   : std_logic_vector(N downto 0);
  signal  ext_B   : std_logic_vector(N downto 0);

--ppg out
  signal  Z0_s      : std_logic_vector(26 downto 0);
  signal  Z1_s      : std_logic_vector(26 downto 0);
  signal  Z2_s      : std_logic_vector(28 downto 0);
  signal  Z3_s      : std_logic_vector(30 downto 0);
  signal  Z4_s      : std_logic_vector(32 downto 0);
  signal  Z5_s      : std_logic_vector(34 downto 0);
  signal  Z6_s      : std_logic_vector(36 downto 0);
  signal  Z7_s      : std_logic_vector(38 downto 0);
  signal  Z8_s      : std_logic_vector(40 downto 0);
  signal  Z9_s      : std_logic_vector(42 downto 0);
  signal  Z10_s     : std_logic_vector(44 downto 0);
  signal  Z11_s     : std_logic_vector(46 downto 0);
  signal  Z12_s     : std_logic_vector(48 downto 0);


BEGIN
--components instantiation
  sign_ext : sign_extension
  generic map ( N )
     port map ( IN1   => A,
                IN2   => B,
                S_Un  => S_Un,
                OUT1  => ext_A,
                OUT2  => ext_B
              );

  ppgen : ppg
  port map( A   => ext_A,
            B   => ext_B,
            Z0  =>  Z0_s,
            Z1  =>  Z1_s,
            Z2  =>  Z2_s,
            Z3  =>  Z3_s,
            Z4  =>  Z4_s,
            Z5  =>  Z5_s,
            Z6  =>  Z6_s,
            Z7  =>  Z7_s,
            Z8  =>  Z8_s,
            Z9  =>  Z9_s,
            Z10 =>  Z10_s,
            Z11 =>  Z11_s,
            Z12 =>  Z12_s
          );

  wallace : WallaceTree
  port map( CLK  => CLK,
            RST_N => RST_N,
            PIPELINE_EN => PIPELINE_EN,
            PP1  =>  Z0_s,
            PP2  =>  Z1_s,
            PP3  =>  Z2_s,
            PP4  =>  Z3_s,
            PP5  =>  Z4_s,
            PP6  =>  Z5_s,
            PP7  =>  Z6_s,
            PP8  =>  Z7_s,
            PP9  =>  Z8_s,
            PP10 =>  Z9_s,
            PP11 =>  Z10_s,
            PP12 =>  Z11_s,
            PP13 =>  Z12_s,
            SUM  =>  Z
          );

END ARCHITECTURE;
