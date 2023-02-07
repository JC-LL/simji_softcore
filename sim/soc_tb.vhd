--------------------------------------------
-- (c) Jean-Christophe Le Lann - 2022
---------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uart_lib;
use uart_lib.uart_cst.all;
use uart_lib.uart_api.all;

library soc_lib;
use soc_lib.soc_pkg.all;

entity soc_tb is
end entity;

architecture bhv of soc_tb is

  signal reset_n : std_logic := '0';
  signal running : boolean := true;

  -- WARNING : clock is definied in uart_api

  signal leds     : std_logic_vector(15 downto 0);
  signal switches : std_logic_vector( 7 downto 0);

  signal debug     : std_logic_vector(15 downto 0);
  signal data_back : std_logic_vector(31 downto 0);

  constant transactions_test : bus_transactions_t :=(
    --           ADDR        DATA
    (BUS_WR, x"00000000",x"00000005"),--wr LED
    (BUS_RD, x"00000001",x"--------"),--rd SWITCHES
    -- writing to BRAM1
    (BUS_WR, x"00000002",x"000000AA"),
    (BUS_WR, x"00000003",x"000000AA"),
    (BUS_WR, x"00000004",x"000000AA"),
    (BUS_WR, x"00000005",x"000000AA"),
    (BUS_WR, x"00000006",x"000000AA"),
    (BUS_WR, x"00000101",x"000000AA"),
    -- WRITING to BRAM2
    (BUS_WR, x"00000102",x"00000001"),
    (BUS_WR, x"00000103",x"00000002"),
    (BUS_WR, x"00000104",x"00000003"),
    (BUS_WR, x"00000105",x"00000004"),
    (BUS_WR, x"00000106",x"00000005"),
    (BUS_WR, x"00000201",x"00000006"),
    -- READING from BRAM2
    (BUS_RD, x"00000102",x"--------"),
    (BUS_RD, x"00000103",x"--------"),
    (BUS_RD, x"00000104",x"--------"),
    (BUS_RD, x"00000105",x"--------"),
    (BUS_RD, x"00000106",x"--------"),
    (BUS_RD, x"00000201",x"--------"),
    -- READING from BRAM1
    (BUS_RD, x"00000002",x"--------"),
    (BUS_RD, x"00000003",x"--------"),
    (BUS_RD, x"00000004",x"--------"),
    (BUS_RD, x"00000005",x"--------"),
    (BUS_RD, x"00000006",x"--------"),
    (BUS_RD, x"00000101",x"--------"),
    --
    (BUS_WR, x"00000042",x"deadbeef"),
    (BUS_RD, x"00000042",x"--------"),
    (BUS_WR, x"00000002",x"08200543"),-- ADD R0,42,R3 00001 00000 1 0000000000101010 00011 = 08200543
    (BUS_WR, x"00000202",x"00000001")
  );

  constant test_instructions : bus_transactions_t :=(
    --           ADDR        DATA
    (BUS_WR, x"00000000",x"00000005"),-- wr LED
    (BUS_RD, x"00000001",x"--------"),-- rd SWITCHES
    -- writing to BRAM2 DATA
    (BUS_WR, x"00000106",x"0000babe"),-- 0x4 : 0xbabe. will be read via LOAD
    -- writing to BRAM1 PROG
    (BUS_WR, x"00000002",x"08200543"),-- 0x00 ADD R0,42,R3   00001 00000 1 0000000000101010 00011 = 08200543 R3=42
    (BUS_WR, x"00000003",x"10e00024"),-- 0x01 SUB R3, 1,R4   00010 00011 1 0000000000000001 00100 = 10e00024 r4=41
    (BUS_WR, x"00000004",x"19000065"),-- 0x02 MUL R4,R3,R5   00011 00100 0 0000000000000011 00101 = 19000065 r5=41*42
    (BUS_WR, x"00000005",x"68200087"),-- 0x03 LOAD R0,4,R7   01101 00000 1 0000000000000100 00111 = 68200087 r7=babe
    (BUS_WR, x"00000006",x"11e141c8"),-- 0x04 SUB  R7,a0e,R8 00010 00111 1 0000101000001110 01000 = 11e141c8 r8=b0b0
    (BUS_WR, x"00000007",x"70200068"),-- 0x05 STORE R0,3,R8  01110 00000 1 0000000000000011 01000 = 70200068  @3=0000b0b0
    (BUS_WR, x"00000008",x"11200024"),-- 0x06 SUB R4,1,R4    00010 00100 1 0000000000000001 00100 = 11200024 r4=40
    (BUS_WR, x"00000009",x"6260014a"),-- 0x07 SEQ R9,a,R10   01100 01001 1 0000000000001010 01010 = 6260014a r10=1 si r9==a
    (BUS_WR, x"0000000a",x"8a80000a"),-- 0x08 BRANZ r10,0x0a 10001 01010 0000000000000000001010   = 8a80000a @pc=a si r10!=0
    (BUS_WR, x"0000000b",x"7c000009"),-- 0x09 JMP 0,r9       01111 1 000000000000000000000 01001  = 7c000009 r9=9
    (BUS_WR, x"0000000c",x"00000000"),-- 0x0a STOP

    (BUS_WR, x"0000000d",x"00000000"),-- STOP
    -- starting processor (go!)
    (BUS_WR, x"00000202",x"00000001")
  );

  constant transactions : bus_transactions_t :=(
    --           ADDR        DATA
    -- writing to BRAM1 PROG
    (BUS_WR, std_logic_vector(to_unsigned( 0+2,32)), x"08200022"),
    (BUS_WR, std_logic_vector(to_unsigned( 1+2,32)), x"08200023"),
    (BUS_WR, std_logic_vector(to_unsigned( 2+2,32)), x"60e00024"),
    (BUS_WR, std_logic_vector(to_unsigned( 3+2,32)), x"81000005"),
    (BUS_WR, std_logic_vector(to_unsigned( 4+2,32)), x"7c000180"),
    (BUS_WR, std_logic_vector(to_unsigned( 5+2,32)), x"48a00022"),
    (BUS_WR, std_logic_vector(to_unsigned( 6+2,32)), x"60a00026"),
    (BUS_WR, std_logic_vector(to_unsigned( 7+2,32)), x"8180000a"),
    (BUS_WR, std_logic_vector(to_unsigned( 8+2,32)), x"38e00023"),
    (BUS_WR, std_logic_vector(to_unsigned( 9+2,32)), x"7c000140"),
    (BUS_WR, std_logic_vector(to_unsigned(10+2,32)), x"7c000225"),
    (BUS_WR, std_logic_vector(to_unsigned(11+2,32)), x"7c000040"),
    (BUS_WR, std_logic_vector(to_unsigned(12+2,32)), x"40a00022"),
    (BUS_WR, std_logic_vector(to_unsigned(13+2,32)), x"60a80006"),
    (BUS_WR, std_logic_vector(to_unsigned(14+2,32)), x"8180000a"),
    (BUS_WR, std_logic_vector(to_unsigned(15+2,32)), x"38e00023"),
    (BUS_WR, std_logic_vector(to_unsigned(16+2,32)), x"7c000140"),
    (BUS_WR, std_logic_vector(to_unsigned(17+2,32)), x"082fffe1"),
    (BUS_WR, std_logic_vector(to_unsigned(18+2,32)), x"88400014"),
    (BUS_WR, std_logic_vector(to_unsigned(19+2,32)), x"780000a0"),
    (BUS_WR, std_logic_vector(to_unsigned(20+2,32)), x"10600021"),
    (BUS_WR, std_logic_vector(to_unsigned(21+2,32)), x"7c000240"),
    -- starting processor (go!)
    (BUS_WR, x"00000202",x"00000001")
  );

begin
  --------------------------------------------------------------------------------
  -- clock and reset
  --------------------------------------------------------------------------------
  reset_n <= '0','1' after 123 ns;

  clk100 <= not(clk100) after HALF_PERIOD when running else clk100;
  --------------------------------------------------------------------------------
  -- Design Under Test
  --------------------------------------------------------------------------------
  dut : entity soc_lib.soc(rtl)
    port map (
      reset_n  => reset_n ,
      clk100   => clk100  ,
      rx       => tx      ,
      tx       => rx      ,
      leds     => leds    ,
      switches => switches
    );
  -------------------------------
  -- User switches
  -------------------------------
  switches <= x"cd";
  --------------------------------------------------------------------------------
  -- sequential stimuli
  --------------------------------------------------------------------------------
  serial_sending : process
    type array_bytes is array(3 downto 0) of std_logic_vector(7 downto 0);
    variable bytes : array_bytes;
    variable transaction : bus_cmd;
  begin
    report "running testbench for soc(rtl)";
    report "waiting for asynchronous reset";
    wait until reset_n='1';
    wait_cycles(100);
    report "executing bus master instructions sequence";
    for i in transactions'range loop
      transaction := transactions(i);
      send_byte(tx,transaction.ctrl);--bus control
      send_word(transaction.addr,tx);--bus address
      if transaction.ctrl(1 downto 0)="01" then
        report "RD " & to_hstring(transaction.addr);
      else
        send_word(transaction.data,tx);--bus data
        report "WR " & to_hstring(transaction.addr) & " " & to_hstring(transaction.data);
      end if;
      wait_cycles(10);
    end loop;
    wait_cycles(1000000);
    report "end of simulation";
    running <= false;
    wait;
  end process;

  old_rx : process
  begin
    wait until rising_edge(clk100);
    rx_1t <= rx;
  end process;

  serial_receiving:process
  begin
    receive_word(data_back);
    report "received " & to_hstring(data_back);
  end process;
end bhv;
