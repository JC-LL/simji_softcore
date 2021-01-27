-------------------------------------------------------------------------------
-- Title      : CHIMERA
-- Project    :
-------------------------------------------------------------------------------
-- File       : seven_seg_controler.vhd
-- Author     : jcll  <jcll@jcll-probook>
-- Company    : ENSTA Bretagne
-- Created    : 2017-09-07
-- Last update: 2017-09-07
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-09-07  1.0      jcll	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.seven_seg_controler_pkg.all;

-- generic seven seg controler !
-- used together with its package, where generic parameters are located.

entity seven_seg_controler is
  port(
    reset_n  : in  std_logic;
    clk      : in  std_logic;
    digits   : in  digits_array;
    segments : out std_logic_vector(6 downto 0);
    anodes   : out std_logic_vector(NUMBER_OF_DIGITS-1 downto 0)
    );
end entity;

architecture rtl of seven_seg_controler is
  -----------------------------------------------------------------------
  -- let's refresh every 16 ms (Digilent says between 3 and 16)
  -- for 4 7-segments leds :
  -- digit period : refresh_period / 4 : every 4 ms
  -- with 100Mhz input clock : 4ms is (100e6 cyc/c)*4e-3 = 400 000
  -- with  50Mhz input clock : 4ms is ( 50e6 cyc/c)*4e-3 = 200 000
  -- 2^19 = 524288
  -- 2^20 = 1048576
  -----------------------------------------------------------------------
  constant N      : natural := 19;

  signal anodes_r : std_logic_vector(NUMBER_OF_DIGITS-1 downto 0);

  subtype anode_id_type is integer range 0 to NUMBER_OF_DIGITS-1;

  signal anode_id    : anode_id_type;
  signal counter     : unsigned(N-1 downto 0);
  signal top_synchro : std_logic;

begin


  digit_period_gen : process(reset_n, clk)
  begin
    if reset_n = '0' then
      counter <= to_unsigned(0, N);
    elsif rising_edge(clk) then
      if counter = 100_000 then
        counter <= to_unsigned(0, N);
      else
        counter <= counter + 1;
      end if;
    end if;
  end process;

  top_synchro <= '1' when counter = to_unsigned(0, N) else '0';

  anode_token_propagation : process(reset_n, clk)
  begin
    if reset_n = '0' then
      anodes_r(0) <= '0';               -- start with 1110
      for i in 1 to NUMBER_OF_DIGITS-1 loop
        anodes_r(i) <= '1';
      end loop;
    elsif rising_edge(clk) then
      if top_synchro = '1' then
        anodes_r(0) <= anodes_r(NUMBER_OF_DIGITS-1);
        for i in 1 to NUMBER_OF_DIGITS-1 loop
          anodes_r(i) <= anodes_r(i-1);
        end loop;
      end if;
    end if;
  end process;

  anodes <= anodes_r;

  detect_active_anode : process(reset_n, clk)
  begin
    if reset_n = '0' then
      anode_id <= 0;
    elsif rising_edge(clk) then
      for i in 0 to NUMBER_OF_DIGITS-1 loop
        if anodes_r(i) = '0' then
          anode_id <= i;
        end if;
      end loop;
    end if;
  end process;


  seg_handling : process(reset_n, clk)
  begin
    if reset_n = '0' then
      segments <= (others => '0');
    elsif rising_edge(clk) then
      segments <= convert(digits(anode_id));
    end if;
  end process;


end rtl;
