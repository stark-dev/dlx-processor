library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY ppg IS
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
END ENTITY;

ARCHITECTURE behavioral OF ppg IS
  --components
  COMPONENT booth_encoder IS
    generic ( N :   integer := 25);
        port( A :   in  std_logic_vector(N-1 downto 0);
              B :   in  std_logic_vector(2 downto 0);
              Z :   out std_logic_vector(N+1 downto 0)
              );
  END COMPONENT;

  --signals
  signal B_ext    : std_logic_vector(26 downto 0);

  signal  out_0   :   std_logic_vector(26 downto 0);
  signal  out_1   :   std_logic_vector(26 downto 0);
  signal  out_2   :   std_logic_vector(28 downto 0);
  signal  out_3   :   std_logic_vector(30 downto 0);
  signal  out_4   :   std_logic_vector(32 downto 0);
  signal  out_5   :   std_logic_vector(34 downto 0);
  signal  out_6   :   std_logic_vector(36 downto 0);
  signal  out_7   :   std_logic_vector(38 downto 0);
  signal  out_8   :   std_logic_vector(40 downto 0);
  signal  out_9   :   std_logic_vector(42 downto 0);
  signal  out_10  :   std_logic_vector(44 downto 0);
  signal  out_11  :   std_logic_vector(46 downto 0);
  signal  out_12  :   std_logic_vector(48 downto 0);

BEGIN
  B_ext <= B(24) & B & '0'; -- extend B on the rigth with a 0 to provide bit -1 to booth enc

  Z0   <= out_0;
  Z1   <= out_1;
  Z2   <= out_2;
  Z3   <= out_3;
  Z4   <= out_4;
  Z5   <= out_5;
  Z6   <= out_6;
  Z7   <= out_7;
  Z8   <= out_8;
  Z9   <= out_9;
  Z10  <= out_10;
  Z11  <= out_11;
  Z12  <= out_12;

  out_2 (1 downto 0)    <= (others => '0');
  out_3 (3 downto 0)    <= (others => '0');
  out_4 (5 downto 0)    <= (others => '0');
  out_5 (7 downto 0)    <= (others => '0');
  out_6 (9 downto 0)    <= (others => '0');
  out_7 (11 downto 0)   <= (others => '0');
  out_8 (13 downto 0)   <= (others => '0');
  out_9 (15 downto 0)   <= (others => '0');
  out_10 (17 downto 0)  <= (others => '0');
  out_11 (19 downto 0)  <= (others => '0');
  out_12 (21 downto 0)  <= (others => '0');

  booth_enc_0 : booth_encoder
  generic map(25)
    port map( A => A,
              B => B_ext(2 downto 0),
              Z => out_0(26 downto 0)
            );
  booth_enc_1 : booth_encoder
  generic map(25)
    port map( A => A,
              B => B_ext(4 downto 2),
              Z => out_1(26 downto 0)
            );
  booth_enc_2 : booth_encoder
  generic map(25)
    port map( A => A,
              B => B_ext(6 downto 4),
              Z => out_2(28 downto 2)
            );
  booth_enc_3 : booth_encoder
  generic map(25)
    port map( A => A,
              B => B_ext(8 downto 6),
              Z => out_3(30 downto 4)
            );
  booth_enc_4 : booth_encoder
  generic map(25)
    port map( A => A,
              B => B_ext(10 downto 8),
              Z => out_4(32 downto 6)
            );
  booth_enc_5 : booth_encoder
  generic map(25)
    port map( A => A,
              B => B_ext(12 downto 10),
              Z => out_5(34 downto 8)
            );
  booth_enc_6 : booth_encoder
  generic map(25)
    port map( A => A,
              B => B_ext(14 downto 12),
              Z => out_6(36 downto 10)
            );
  booth_enc_7 : booth_encoder
  generic map(25)
    port map( A => A,
              B => B_ext(16 downto 14),
              Z => out_7(38 downto 12)
            );
  booth_enc_8 : booth_encoder
  generic map(25)
    port map( A => A,
              B => B_ext(18 downto 16),
              Z => out_8(40 downto 14)
            );
  booth_enc_9 : booth_encoder
  generic map(25)
    port map( A => A,
              B => B_ext(20 downto 18),
              Z => out_9(42 downto 16)
            );
  booth_enc_10 : booth_encoder
  generic map(25)
    port map( A => A,
              B => B_ext(22 downto 20),
              Z => out_10(44 downto 18)
            );
  booth_enc_11 : booth_encoder
  generic map(25)
    port map( A => A,
              B => B_ext(24 downto 22),
              Z => out_11(46 downto 20)
            );
  booth_enc_12 : booth_encoder
  generic map(25)
    port map( A => A,
              B => B_ext(26 downto 24),
              Z => out_12(48 downto 22)
            );
END ARCHITECTURE;
