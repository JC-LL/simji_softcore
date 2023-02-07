library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ip_lib;
library uart_bus_master_lib;

library soc_lib;
use soc_lib.soc_pkg.all;

entity soc is
  port (
    reset_n  : in std_logic;
    clk100   : in std_logic;
    rx       : in std_logic;
    tx       : out std_logic;
    leds     : out std_logic_vector(15 downto 0);
    switches : in  std_logic_vector( 7 downto 0)
  );
end entity;

architecture rtl of soc is

  signal master_to_bus_en              : std_logic;
  signal master_to_bus_wr              : std_logic;
  signal master_to_bus_addr            : unsigned(31 downto 0);
  signal master_to_bus_data            : std_logic_vector(31 downto 0);
  signal bus_to_master_data            : std_logic_vector(31 downto 0);
  --
  signal bus_to_slave_en               : std_logic;
  signal bus_to_slave_wr               : std_logic;
  signal bus_to_slave_addr             : unsigned(31 downto 0);
  signal bus_to_slave_data             : std_logic_vector(31 downto 0);
  --
  signal slave_to_bus_data_IP_LEDS     : std_logic_vector(31 downto 0);
  signal slave_to_bus_data_IP_SWITCHES : std_logic_vector(31 downto 0);
  signal slave_to_bus_data_IP_BRAM_1   : std_logic_vector(31 downto 0);
  signal slave_to_bus_data_IP_BRAM_2   : std_logic_vector(31 downto 0);
  signal slave_to_bus_data_IP_SIMJI    : std_logic_vector(31 downto 0);
  --
  signal leds_from_ip : std_logic_vector(15 downto 0);
  signal leds_from_simji : std_logic_vector(15 downto 0);
  --
  signal debug_uart_bus_master : std_logic_vector(7 downto 0);
  signal debug_ip_leds         : std_logic_vector(7 downto 0);
  --
  signal proc_to_bram_i_en   : std_logic;
  signal proc_to_bram_i_we   : std_logic;
  signal proc_to_bram_i_data : std_logic_vector(31 downto 0);
  signal proc_to_bram_i_addr : std_logic_vector(7  downto 0);
  signal bram_to_proc_i_data : std_logic_vector(31 downto 0);
  --
  signal proc_to_bram_d_en   : std_logic;
  signal proc_to_bram_d_we   : std_logic;
  signal proc_to_bram_d_data : std_logic_vector(31 downto 0);
  signal proc_to_bram_d_addr : std_logic_vector(7  downto 0);
  signal bram_to_proc_d_data : std_logic_vector(31 downto 0);
begin

  ---------------------------------------------
  -- DEBUG LEDS
  ---------------------------------------------
  --leds <= debug_ip_leds & debug_uart_bus_master;
  leds <= leds_from_ip or leds_from_simji;
  ---------------------------------------------
  -- UART Bus master
  ---------------------------------------------
  uart_bus_master_i : entity uart_bus_master_lib.uart_bus_master
  port map (
    reset_n        => reset_n,
    clk100         => clk100,
    -- uart side
    rx             => rx,
    tx             => tx,
    -- bus side
    master_to_bus_en    => master_to_bus_en,
    master_to_bus_wr    => master_to_bus_wr,
    master_to_bus_addr  => master_to_bus_addr,
    master_to_bus_data  => master_to_bus_data,
    bus_to_master_data  => bus_to_master_data,
    debug               => debug_uart_bus_master
  );
  ------------------------------------------------
  -- BUS wiring
  ------------------------------------------------
  bus_to_slave_en    <= master_to_bus_en;
  bus_to_slave_wr    <= master_to_bus_wr;
  bus_to_slave_addr  <= master_to_bus_addr;
  bus_to_slave_data  <= master_to_bus_data;
  bus_to_master_data <= slave_to_bus_data_IP_LEDS     or
                        slave_to_bus_data_IP_SWITCHES or
                        slave_to_bus_data_IP_BRAM_1   or
                        slave_to_bus_data_IP_BRAM_2;
  ----------------------------------PERIPH--------------
  --
  -------------------------------------------------
  IP_LEDS_i : entity ip_lib.ip_leds
  generic map(
    address_start => MEMORY_MAP(IP_LEDS).address_start,
    address_end   => MEMORY_MAP(IP_LEDS).address_end
  )
  port map(
    reset_n        => reset_n,
    clk            => clk100,
    -- bus side
    bus_to_slave_en    => bus_to_slave_en,
    bus_to_slave_wr    => bus_to_slave_wr,
    bus_to_slave_addr  => bus_to_slave_addr,
    bus_to_slave_data  => bus_to_slave_data,
    slave_to_bus_data  => slave_to_bus_data_IP_LEDS,
    --
    leds               => leds_from_ip,
    debug              => debug_ip_leds
  );
  ------------------------------------------------
  --
  -------------------------------------------------
  IP_SWITCHES_i : entity ip_lib.ip_switches
  generic map(
    address_start => MEMORY_MAP(IP_SWITCHES).address_start,
    address_end   => MEMORY_MAP(IP_SWITCHES).address_end
  )
  port map(
    reset_n        => reset_n,
    clk            => clk100,
    -- bus side
    bus_to_slave_en    => bus_to_slave_en,
    bus_to_slave_wr    => bus_to_slave_wr,
    bus_to_slave_addr  => bus_to_slave_addr,
    bus_to_slave_data  => bus_to_slave_data,
    slave_to_bus_data  => slave_to_bus_data_IP_SWITCHES,
    --
    switches           => switches
  );
  ------------------------------------------------
  --
  -------------------------------------------------
  IP_BRAM_1_i : entity ip_lib.ip_bram
  generic map(
    BRAM_ADDR_SIZE => 8,
    BRAM_DATA_SIZE => 32,
    ADDRESS_START  => MEMORY_MAP(IP_BRAM1).address_start,
    ADDRESS_END    => MEMORY_MAP(IP_BRAM1).address_end
  )
  port map(
    reset_n        => reset_n,
    clk            => clk100,
    -- bus side
    bus_to_slave_en    => bus_to_slave_en,
    bus_to_slave_wr    => bus_to_slave_wr,
    bus_to_slave_addr  => bus_to_slave_addr,
    bus_to_slave_data  => bus_to_slave_data,
    slave_to_bus_data  => slave_to_bus_data_IP_BRAM_1,
    proc_to_bram_en    => proc_to_bram_i_en,
    proc_to_bram_we    => proc_to_bram_i_we,
    proc_to_bram_data  => proc_to_bram_i_data,
    proc_to_bram_addr  => proc_to_bram_i_addr,
    bram_to_proc_data  => bram_to_proc_i_data
  );
  ------------------------------------------------
  --
  ------------------------------------------------
  ip_simji_1: entity ip_lib.ip_simji
    generic map (
      address_start => MEMORY_MAP(IP_SIMJI).address_start,
      address_end   => MEMORY_MAP(IP_SIMJI).address_end)
    port map (
      reset_n           => reset_n,
      clk               => clk100,
      bus_to_slave_en   => bus_to_slave_en,
      bus_to_slave_wr   => bus_to_slave_wr,
      bus_to_slave_addr => bus_to_slave_addr,
      bus_to_slave_data => bus_to_slave_data,
      slave_to_bus_data => slave_to_bus_data_IP_SIMJI,
      --
      proc_to_bram_i_en   => proc_to_bram_i_en  ,
      proc_to_bram_i_we   => proc_to_bram_i_we  ,
      proc_to_bram_i_data => proc_to_bram_i_data,
      proc_to_bram_i_addr => proc_to_bram_i_addr,
      bram_to_proc_i_data => bram_to_proc_i_data,
      --
      proc_to_bram_d_en   => proc_to_bram_d_en  ,
      proc_to_bram_d_we   => proc_to_bram_d_we  ,
      proc_to_bram_d_data => proc_to_bram_d_data,
      proc_to_bram_d_addr => proc_to_bram_d_addr,
      bram_to_proc_d_data => bram_to_proc_d_data,
      leds => leds_from_simji
    );
  ------------------------------------------------
  --
  -------------------------------------------------
  IP_BRAM_2_i : entity ip_lib.ip_bram
  generic map(
    BRAM_ADDR_SIZE => 8,
    BRAM_DATA_SIZE => 32,
    ADDRESS_START  => MEMORY_MAP(IP_BRAM2).address_start,
    ADDRESS_END    => MEMORY_MAP(IP_BRAM2).address_end
  )
  port map(
    reset_n        => reset_n,
    clk            => clk100,
    -- bus side
    bus_to_slave_en    => bus_to_slave_en,
    bus_to_slave_wr    => bus_to_slave_wr,
    bus_to_slave_addr  => bus_to_slave_addr,
    bus_to_slave_data  => bus_to_slave_data,
    slave_to_bus_data  => slave_to_bus_data_IP_BRAM_2,
    proc_to_bram_en    => proc_to_bram_d_en,
    proc_to_bram_we    => proc_to_bram_d_we,
    proc_to_bram_data  => proc_to_bram_d_data,
    proc_to_bram_addr  => proc_to_bram_d_addr,
    bram_to_proc_data  => bram_to_proc_d_data
  );

end architecture;
