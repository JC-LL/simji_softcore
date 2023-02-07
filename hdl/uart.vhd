library ieee;
use ieee.std_logic_1164.all;

library ip_lib;
library uart_lib;

entity uart is
  port (
    reset_n          : in std_logic;--mapped on Switch 15
    clk100           : in std_logic;
    -- PC interface
    rx               : in std_logic;
    tx               : out std_logic;
    -- ip inferface
    ip_to_uart_pop   : in std_logic;
    ip_to_uart_push  : in std_logic;
    ip_to_uart_data  : in std_logic_vector(7 downto 0);
    uart_to_ip_data  : out std_logic_vector(7 downto 0);
    uart_rcvr_avail  : out std_logic;
    uart_sndr_ready  : out std_logic;
    debug            : out std_logic_vector(7 downto 0)
  );
end entity;

architecture structural of uart is
  signal tick          : std_logic;
  --
  signal tx_empty      : std_logic;
  signal tx_full       : std_logic;
  signal tx_byte       : std_logic_vector(7 downto 0);
  --
  signal rx_empty      : std_logic;
  signal rx_full       : std_logic;
  signal rx_byte       : std_logic_vector(7 downto 0);
  signal rx_byte_valid : std_logic;
  signal send_start    : std_logic;
  signal send_done     : std_logic;

  signal uart_to_ip_avail : std_logic;
  signal uart_to_ip_data_i : std_logic_vector(7 downto 0);

  constant sreset : std_logic := '0'; --not used
  signal tx_almost_full : std_logic;
  signal rx_almost_full : std_logic;
begin
  --------------------------------------------------------
  -- generation of ticks according to baud rate 19200 b/s
  --------------------------------------------------------
  tick_gen_i: entity uart_lib.tick_gen
  port map(
    reset_n => reset_n,
    clk100  => clk100,
    tick    => tick);
  -------------------------------------------------------
  -- receiver
  -------------------------------------------------------
  rcvr_i : entity uart_lib.receiver
    port map (
      reset_n    => reset_n,
      clk100     => clk100,
      tick       => tick,
      rx         => rx,--fifo depth=8
      byte       => rx_byte,
      byte_valid => rx_byte_valid
      );

  rcv_to_ip : entity ip_lib.fifo
    generic map(
      NB_BITS_DATA => 8,
      FIFO_SIZE    => 8)
    port map(
      reset_n      => reset_n,
      clk          => clk100,
      sreset       => sreset,
      push         => rx_byte_valid,
      pop          => ip_to_uart_pop,
      data_i       => rx_byte,
      empty        => rx_empty,
      full         => rx_full,--not used ?
      almost_full  => rx_almost_full,
      data_o       => uart_to_ip_data_i,
      almost_empty => open
    );


  -- end debug
  uart_to_ip_data <= uart_to_ip_data_i;
  uart_rcvr_avail <= not(rx_empty);
  -------------------------------------------------------
  -- sender
  -------------------------------------------------------
  sender_i : entity uart_lib.sender
  port map(
    reset_n      => reset_n,
    clk100       => clk100,
    tick         => tick,
    send_start   => send_start,
    send_done    => send_done,
    byte         => tx_byte,
    tx           => tx
  );

  ip_to_sndr : entity ip_lib.fifo
    generic map(
      NB_BITS_DATA => 8,
      FIFO_SIZE => 8)
    port map(
      reset_n      => reset_n,
      clk          => clk100,
      sreset       => sreset,
      push         => ip_to_uart_push,
      data_i       => ip_to_uart_data,
      pop          => send_done,--sender tries to send another
      empty        => tx_empty,
      full         => tx_full,
      almost_full  => tx_almost_full,
      data_o       => tx_byte,
      almost_empty => open
    );

    send_start      <= not(tx_empty);
    uart_sndr_ready <= not(tx_almost_full);
  ----------------------------operator---------------
  -- Debug process
  -------------------------------------------
  debug_p:process(reset_n,clk100)
    begin
      if reset_n='0' then
        debug <= "00000000";
      elsif rising_edge(clk100) then
        debug <= "00000000";
      end if;
    end process;
end structural;
