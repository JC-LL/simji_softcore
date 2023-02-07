--------------------------------------------------------------------------------
-- this file was generated automatically by Vertigo Ruby utility
-- date : (d/m/y h:m) 16/01/2022  0:52
-- author : Jean-Christophe Le Lann - 2014
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uart_lib;
use uart_lib.uart_cst.all;

package uart_api is

  constant HALF_PERIOD : time :=5 ns;

  signal clk100    : std_logic := '0';
  signal rx,rx_1t  : std_logic;
  signal tx        : std_logic :='1';
  signal rx_byte   : std_logic_vector( 7 downto 0) :="UUUUUUUU";

  type bus_cmd is record
    ctrl : std_logic_vector(7 downto 0);
    addr : std_logic_vector(31 downto 0);
    data : std_logic_vector(31 downto 0);
  end record;

  constant SIGNATURE : std_logic_vector(5 downto 0) := "011011";
  constant BUS_RD    : std_logic_vector(7 downto 0) := SIGNATURE & "01";
  constant BUS_WR    : std_logic_vector(7 downto 0) := SIGNATURE & "11";

  type bus_transactions_t is array(natural range <>) of bus_cmd;

  procedure wait_cycles(n : natural);

  procedure toggle(signal s : inout std_logic);

  procedure emit(signal s : inout std_logic; val : std_logic);

  procedure send_byte(signal s : inout std_logic; byte: std_logic_vector(7 downto 0));

  procedure retreive(variable v : inout std_logic);

  procedure receive_byte(signal byte: inout std_logic_vector(7 downto 0));

  procedure receive_byte_var(variable byte: inout std_logic_vector(7 downto 0));

  procedure receive_word(signal word : inout std_logic_vector(31 downto 0));

  procedure send_word( word : in std_logic_vector(31 downto 0) ;signal tx_s : inout std_logic);

end package;


package body uart_api is

  procedure wait_cycles(n : natural) is
  begin
    for i in 0 to n-1 loop
      wait until rising_edge(clk100);
    end loop;
  end procedure;

  procedure toggle(signal s : inout std_logic) is
  begin
    wait until rising_edge(clk100);
    s <=not(s);
    wait until rising_edge(clk100);
    s <=not(s);
  end procedure;

  procedure emit(signal s : inout std_logic; val : std_logic) is
  begin
    s <= val;
    wait_cycles(16*NB_100HZ_CLOCK_CYCLES_FOR_TICK);--21*
  end procedure;

  procedure send_byte(signal s : inout std_logic; byte: std_logic_vector(7 downto 0)) is
  begin
    emit(s, '0');--start bit
    for i in 0 to 7 loop
      emit(s, byte(i));
    end loop;
    emit(s, '1');--stop bit
  end procedure;

  procedure retreive(variable v : inout std_logic) is
  begin
    wait_cycles(16*NB_100HZ_CLOCK_CYCLES_FOR_TICK);
    v := rx;
  end procedure;

  procedure receive_byte(signal byte: inout std_logic_vector(7 downto 0)) is
    variable start_b_v,stop_b_v : std_logic;
    variable byte_v : std_logic_vector(7 downto 0);
  begin
    -- mind that stop bit sampling requires only 8 ticks
    wait_cycles(8*NB_100HZ_CLOCK_CYCLES_FOR_TICK);
    start_b_v:= rx;
    report "start bit is : " & to_string(start_b_v);
    -- for actual data bits, iterate with 16 ticks each
    for i in 0 to 7 loop
      retreive(byte_v(i));--lsb first
      --report "bit " & to_string(i) & " is : " & to_string(byte_v(i));
    end loop;
    retreive(stop_b_v);
    byte <= byte_v;
    wait_cycles(1);
  end procedure;

  procedure receive_byte_var(variable byte: inout std_logic_vector(7 downto 0)) is
    variable start_b_v,stop_b_v : std_logic;
    variable byte_v : std_logic_vector(7 downto 0);
  begin
    -- mind that stop bit sampling requires only 8 ticks
    wait_cycles(8*NB_100HZ_CLOCK_CYCLES_FOR_TICK);
    start_b_v:= rx;
    --report "start bit is : " & to_string(start_b_v);
    -- for actual data bits, iterate with 16 ticks each
    for i in 0 to 7 loop
      retreive(byte_v(i));--lsb first
      --report "bit " & to_string(i) & " is : " & to_string(byte_v(i));
    end loop;
    retreive(stop_b_v);
    byte := byte_v;
    wait_cycles(1);
  end procedure;

  procedure receive_word(signal word : inout std_logic_vector(31 downto 0)) is
    variable byte0_v,byte1_v,byte2_v,byte3_v : std_logic_vector(7 downto 0);
  begin
    wait until rx='0' and rx_1t='1';
    receive_byte_var(byte0_v);

    wait until rx='0' and rx_1t='1';
    receive_byte_var(byte1_v);

    wait until rx='0' and rx_1t='1';
    receive_byte_var(byte2_v);

    wait until rx='0' and rx_1t='1';
    receive_byte_var(byte3_v);

    word <= byte3_v & byte2_v & byte1_v & byte0_v;
    wait_cycles(1);
  end procedure;

  procedure send_word(
           word : in std_logic_vector(31 downto 0);
    signal tx_s : inout std_logic
    ) is

    type array_bytes is array(3 downto 0) of std_logic_vector(7 downto 0);
    variable bytes : array_bytes;
  begin
    bytes(0) := std_logic_vector(word( 7 downto  0));
    bytes(1) := std_logic_vector(word(15 downto  8));
    bytes(2) := std_logic_vector(word(23 downto 16));
    bytes(3) := std_logic_vector(word(31 downto 24));
    for idx in 0 to 3 loop
      send_byte(tx_s,bytes(idx));
    end loop;
  end procedure;

end package body;
