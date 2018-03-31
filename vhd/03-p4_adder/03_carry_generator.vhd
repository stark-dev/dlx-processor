library ieee;
use ieee.std_logic_1164.all;
use work.DLX_package.all;

ENTITY carry_generator IS
  generic (N : integer := 32;								--number of bits for inputs A and B
           C_freq : integer := 4);							--difference between the indexes of two consecutive carries
  port (A, B : in   std_logic_vector(N downto 1);			--inputs
        Cin  : in   std_logic;								--carry in (C0)
        Cout : out  std_logic_vector((N/C_freq) downto 1));	--carry out array

END ENTITY;


ARCHITECTURE STRUCTURAL OF carry_generator is

  constant level : integer := log2(N) + 1;			--levels of the whole structure
  constant ratio : integer := N / C_freq;			--defines the number of carry outs
  constant lv_add : integer := log2(ratio) - 1;		--number of levels that include the additional strucure

  -- TYPES

  type lv_mat is array (0 to level) of integer;		--stores the index of the last element in the previous level

-------------------------------------------------------------------------------

  -- FUNCTIONS

  function index_g return lv_mat is					--returns an lv_mat for the g signals array
    variable tot : integer;
    variable retVal : lv_mat;
  begin

    tot := N;
    retVal(0) := 0;
    retVal(1) := N;
    for i in 2 to level - lv_add loop				--each level has half elements compared to the previous level
      tot := tot / 2;								--up to the level where additional blocks begin.
      retVal(i) := retVal(i-1)+ tot;
    end loop;

    for i in level - lv_add + 1 to level loop		--successive levels have the same number of elements
      retVal(i) := retVal(i-1)+ tot;
    end loop;

    return retVal;
  end index_g;

  function index_p return lv_mat is					--returns an lv_mat for the p signals indexes
    variable tot : integer;
    variable retVal : lv_mat;
  begin

    tot := N;
    retVal(0) := 0;									--p signals follow the same pattern
    retVal(1) := N-1;
    for i in 2 to level - lv_add loop				--at each level there is a p signal less
      tot := tot / 2;
      retVal(i) := retVal(i-1)+ tot -1;
    end loop;

    for i in level - lv_add + 1 to level loop		--the same as before, but p signals are decreased by the number of g blocks at that level
      retVal(i) := retVal(i-1)+ tot - 2**(i - level + lv_add);
    end loop;

    return retVal;
  end index_p;

  function is_one_1_0(X : integer) return integer is	--this function returns 1 when X is equal to 1, 0 otherwise
  begin						        --it is useful to make a distinction between the special case k=1 and the other values of k
    if X = 1 then
      return 1;
    else
      return 0;
    end if;
  end is_one_1_0;


  function is_one_0_log(X : integer) return integer is	--this function returns 0 when X is equal to 1, (k-(2**(log2(k-1))+1)) otherwise
  begin						        --it is useful to make a distinction between the special case k=1 and the other values of k
    if X = 1 then
      return 0;
    else
      return X-(2**(log2(X-1))+1);
    end if;
  end is_one_0_log;

  function is_one_1_log(X : integer) return integer is
  begin
     if X = 1 then
         return 1;
     else
         return 2**(up_int_log2(X)-1);
     end if;
  end is_one_1_log;
------------------------------------------------------------------------------



-- COMPONENTS

COMPONENT G_block
  port (Pik, Gik, Gk_1j : in   std_logic;
        Gij             : out  std_logic);
END COMPONENT;

COMPONENT PG_block
  port (Pik, Gik, Pk_1j,Gk_1j : in   std_logic;
        Pij, Gij              : out  std_logic);
END COMPONENT;

COMPONENT PG_network
  generic (N : integer := 32);
  port (A, B : in   std_logic_vector(N downto 1);
        Cin  : in   std_logic;
        P    : out  std_logic_vector(N-1 downto 1);
        G    : out  std_logic_vector(N downto 1));
END COMPONENT;

-------------------------------------------------------------------------------

-- CONSTANTS

constant g_index : lv_mat := index_g;		--actual indexes of g signals at each level
constant p_index : lv_mat := index_p;		--actual indexes of p signals at each level

constant g_dim : integer := index_g(level);	--dimension of the g signals array
constant p_dim : integer := index_p(level);	--dimension of the p signals array


-------------------------------------------------------------------------------

-- SIGNALS

signal G_sig : std_logic_vector(g_dim downto 1);	--g signals array
signal P_sig : std_logic_vector(p_dim downto 1);	--p signals array

-------------------------------------------------------------------------------


BEGIN

   pg_net: PG_network								--pg network declaration
    generic map(N)
    port map(A, B, Cin, P_sig(p_index(1) downto 1), G_sig(g_index(1) downto 1));

   level_index : for i in 2 to level-lv_add generate		--basic structure (each level halves the number of blocks)
   G_first : G_block							--in the basic structure only the first block is a G block
	 PORT MAP (P_sig(p_index(i-2)+1),  G_sig(g_index(i-2)+2), G_sig(g_index(i-2)+1), G_sig(g_index(i-1)+1));

	   PG_all : for j in 2 to N/(2**(i-1)) generate
		 PG_b : PG_block							--the remainings blocks are pg blocks
		   port map (P_sig(p_index(i-2)+(j*2)-1), G_sig(g_index(i-2)+(j*2)), P_sig(p_index(i-2)+(j*2)-2), G_sig(g_index(i-2)+(j*2)-1),
					 P_sig(p_index(i-1)+j-1), G_sig(g_index(i-1)+j));
	   end generate PG_all;
   end generate level_index;

   add_level_index : for i in level-lv_add+1 to level generate		--additional structure (each level has the same number of blocks)

       --i,j and k are used to generate the additional structure.
       --i refers to the current level in the structure
       --j is the index of the group of contiguous elements
       --k is the index of an element in the current group
       --the offset referred to the current level is evaluated by adding three terms to the index stored into p_index and g_index arrays

       G_first_spec :  for k in 1 to 2**(i-(level - lv_add)) generate	--in this for loop j is implicitly set to 1 (there is only
        G_spec : G_block
          PORT MAP (P_sig(p_index(level-lv_add-2+up_int_log2(k)) + 2**(i-1-(level-lv_add)+is_one_1_0(k))+1+ is_one_0_log(k) - is_one_1_log(k)),
                    G_sig(g_index(level-lv_add-2+up_int_log2(k)) + 2**(i-1-(level-lv_add)+is_one_1_0(k))+1+ is_one_0_log(k)),
                    G_sig(g_index(i-2) + 2**(i-(level-lv_add)-1)),
                    G_sig(g_index(i-1) + k));
      end generate G_first_spec;

      spec : for j in 2 to N/(2**(i-1)) generate						--other groups are composed by pg blocks
        PG_all_spec :  for k in 1 to 2**(i-(level - lv_add)) generate
          PG_spec : PG_block
            PORT MAP (
		    P_sig(p_index(level-lv_add-2+up_int_log2(k)) + 2**(i-1-(level-lv_add)+is_one_1_0(k))+1 + is_one_0_log(k) + (j-1)*2**(i-(level-lv_add)+is_one_1_0(k)) - 1),
                    G_sig(g_index(level-lv_add-2+up_int_log2(k)) + 2**(i-1-(level-lv_add)+is_one_1_0(k))+1 + is_one_0_log(k) + (j-1)*2**(i-(level-lv_add)+is_one_1_0(k))),
                    P_sig(p_index(i-2) + 2**(i-(level-lv_add)-1) + (j-1)*2**(i-(level-lv_add))  - 1),
                    G_sig(g_index(i-2) + 2**(i-(level-lv_add)-1) + (j-1)*2**(i-(level-lv_add))),
                    P_sig(p_index(i-1) + (j-1)*2**(i-(level-lv_add))+k - 2**(i-(level-lv_add))),
                    G_sig(g_index(i-1) + (j-1)*2**(i-(level-lv_add))+k));
        end generate PG_all_spec;
      end generate spec;
   end generate add_level_index;

   carry: process (G_sig)			--carry out signals are connected to g blocks of the structure
   begin
      for i in lv_add downto 1 loop
        for j in 2**i downto 1 loop
           Cout((2**i)+j) <= G_sig(g_index(level - lv_add -1 + i) + j);
        end loop;
      end loop;

      if ratio > 1 then				--if only one carry out is needed, this element doesn't exist
         Cout(2) <= G_sig(g_index(level - lv_add - 1) + 1);
      end if;

      Cout(1) <= G_sig(g_index(level - lv_add - 2) + 1);	--first carry out (always connected)
   end process;


END ARCHITECTURE;
