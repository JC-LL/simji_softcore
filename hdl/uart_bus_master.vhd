library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uart_lib;
library uart_bus_master_lib;

entity uart_bus_master is
  port (
    reset_n             : in std_logic;
    clk100              : in std_logic;
    -- uart side
    rx                  : in std_logic;
    tx                  : out std_logic;
    -- bus side
    master_to_bus_en    : out std_logic;
    master_to_bus_wr    : out std_logic;
    master_to_bus_addr  : out unsigned(31 downto 0);
    master_to_bus_data  : out std_logic_vector(31 downto 0);
    bus_to_master_data  : in  std_logic_vector(31 downto 0);
    debug               : out std_logic_vector( 7 downto 0)
  );
end entity;

architecture rtl of uart_bus_master is
    -- commands
    signal fsm_to_uart_pop     : std_logic;
    signal fsm_to_uart_push    : std_logic;
    -- data
    signal uart_to_fsm_data    : std_logic_vector(7 downto 0);
    signal fsm_to_uart_data    : std_logic_vector(7 downto 0);
    --
    signal uart_to_ip_data     : std_logic_vector(7 downto 0);
    signal uart_rcvr_avail     : std_logic;
    signal uart_sndr_ready     : std_logic;
    --signal debug               : std_logic_vector(7 downto 0);
begin

  uart_i : entity uart_lib.uart
  port map(
    reset_n             => reset_n,
    clk100              => clk100,
    -- PC interface
    rx                  => rx,
    tx                  => tx,
    -- ip inferface
    ip_to_uart_pop      => fsm_to_uart_pop,
    ip_to_uart_push     => fsm_to_uart_push,
    ip_to_uart_data     => fsm_to_uart_data,
    uart_to_ip_data     => uart_to_fsm_data,
    uart_rcvr_avail     => uart_rcvr_avail,
    uart_sndr_ready     => uart_sndr_ready,
    debug               => debug
  );

  controller_i : entity uart_bus_master_lib.uart_bus_master_fsm
  port map(
    reset_n             => reset_n,
    clk                 => clk100,
    -- status
    uart_rcvr_avail     => uart_rcvr_avail,
    uart_sndr_ready     => uart_sndr_ready,
    -- commands
    fsm_to_uart_pop     => fsm_to_uart_pop,
    fsm_to_uart_push    => fsm_to_uart_push,
    -- data
    uart_to_fsm_data    => uart_to_fsm_data,
    fsm_to_uart_data    => fsm_to_uart_data,
    -- bus side
    master_to_bus_en    => master_to_bus_en,
    master_to_bus_wr    => master_to_bus_wr,
    master_to_bus_addr  => master_to_bus_addr,
    master_to_bus_data  => master_to_bus_data,
    bus_to_master_data  => bus_to_master_data
  );
end rtl;
