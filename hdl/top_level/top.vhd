library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.seven_seg_controler_pkg.all;

entity top is
  port (
    clk100       : in  std_logic;
    reset_btn    : in  std_logic;
    switches     : in  std_logic_vector(15 downto 0);
    rx           : in  std_logic;
    tx           : out std_logic;
    leds         : out std_logic_vector(15 downto 0);
    segments     : out std_logic_vector(6 downto 0);
    anodes       : out std_logic_vector(7 downto 0)
  );
end entity;

architecture arch of top is

  signal clk                  : std_logic;
  signal reset_n,sreset,reset : std_logic;
  signal slow_clk, slow_tick  : std_logic;

  -- bus
  signal bus_en         : std_logic;
  signal bus_wr         : std_logic;
  signal bus_addr       : std_logic_vector(15 downto 0);
  signal bus_din        : std_logic_vector(31 downto 0);
  signal bus_dout       : std_logic_vector(31 downto 0);

  -- DEBUG on 8 x 7 segs
  signal digits : digits_array;
  signal B0,B1,B2,B3,B4,B5,B6,B7,B8 : digit_type;
  signal debug_addr    : std_logic_vector(15 downto 0);
  signal debug_din_lsb : std_logic_vector(15 downto 0);
begin
  -- board interface
  reset_n <= switches(15);
  sreset  <= '0';
  --clk     <= clk100;
  ---------------------------------------------------------------------
  -- Generated clock : not recommended !
  ---------------------------------------------------------------------
  derived_clock:process(reset_n,clk)
  begin
    if reset_n='0' then
      clk <= '0';
    elsif rising_edge(clk100) then
      clk <= not(clk);
    end if;
  end process;
  ---------------------------------------------------------------------
  -- ticker on LEDs : show something active !
  ---------------------------------------------------------------------
  slow_ticker_1 : entity work.slow_ticker
    generic map ( N => 27)
    port map (
      reset_n   => reset_n,
      fast_clk  => clk,--100Mhz
      slow_clk  => slow_clk,
      slow_tick => slow_tick);
  ---
  leds <= slow_clk & "000" & x"000";
  --------------------------------------------------------------------
  -- UART bus master
  --------------------------------------------------------------------
  uart_master: entity work.uart_bus_master
    generic map(DVSR => 162) --325 for 100 ; 162 for 50Mz
    port map (
      reset_n   => reset_n ,
      clk       => clk     ,
      sreset    => sreset  ,
      rx        => rx      ,
      tx        => tx      ,
      bus_en    => bus_en  ,
      bus_wr    => bus_wr  ,
      bus_addr  => bus_addr,
      bus_din   => bus_din ,
      bus_dout  => bus_dout);
  --------------------------------------------------------------------
  -- Simji SoC
  --------------------------------------------------------------------
  simji_soc_i : entity work.simji_soc
    generic map (
      nbits_inst_addr => 10,
      nbits_data_addr => 10
    )
    port map (
      reset_n  => reset_n ,
      clk      => clk     ,
      bus_en   => bus_en  ,
      bus_wr   => bus_wr  ,
      bus_addr => bus_addr,
      bus_din  => bus_din ,
      bus_dout => bus_dout);
  --------------------------------------------------------------
  -- 7-segments display
  --------------------------------------------------------------
  debug_on_seven_seg:process(reset_n,clk)
  begin
    if reset_n='0' then
      debug_addr    <= x"0000";
      debug_din_lsb <= x"0000";
    elsif rising_edge(clk) then
      if bus_en='1' then
        debug_addr    <= bus_addr;
        debug_din_lsb <=  bus_din(15 downto 0);
      end if;
    end if;
  end process;

  B7 <= to_integer(unsigned(debug_addr(15 downto 12)));
  B6 <= to_integer(unsigned(debug_addr(11 downto  8)));
  B5 <= to_integer(unsigned(debug_addr( 7 downto  4)));
  B4 <= to_integer(unsigned(debug_addr( 3 downto  0)));
  B3 <= to_integer(unsigned(debug_din_lsb(15 downto 12)));
  B2 <= to_integer(unsigned(debug_din_lsb(11 downto  8)));
  B1 <= to_integer(unsigned(debug_din_lsb( 7 downto  4)));
  B0 <= to_integer(unsigned(debug_din_lsb( 3 downto  0)));

  digits <= (B7,B6,B5,B4,B3,B2,B1,B0);

  seven_seg : entity work.seven_seg_controler(RTL)
    port map(
      reset_n  => reset_n,
      clk      => clk,
      digits   => digits,
      segments => segments,
      anodes   => anodes
      );
end arch;
