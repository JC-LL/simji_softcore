--------------------------------------------------------------------------------
-- this file was generated automatically by Vertigo Ruby utility
-- date : (d/m/y h:m) 22/01/2021 23:33
-- author : Jean-Christophe Le Lann - 2014
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_bus_master_controler_tb is
end entity;

architecture bhv of uart_bus_master_controler_tb is
  constant HALF_PERIOD : time :=5 ns;

  signal clk : std_logic := '0';
  signal reset_n : std_logic := '0';

  signal running : boolean := true;

  procedure wait_cycles(n : natural) is
  begin
    for i in 0 to n-1 loop
      wait until rising_edge(clk);
    end loop;
  end procedure;
  signal byte_in        : std_logic_vector(7 downto 0);
  signal byte_in_valid  : std_logic;
  signal byte_out       : std_logic_vector(7 downto 0);
  signal byte_out_valid : std_logic;
  signal bus_en         : std_logic;
  signal bus_wr         : std_logic;
  signal bus_addr       : std_logic_vector(15 downto 0);
  signal bus_din        : std_logic_vector(31 downto 0);
  signal bus_dout       : std_logic_vector(31 downto 0);

  -- dummy peripheral :
  constant ADDR_REG_A : std_logic_vector(15 downto 0) := x"abcd";
  constant ADDR_REG_B : std_logic_vector(15 downto 0) := x"feed";
  signal reg_a,reg_b : std_logic_vector(31 downto 0)  := x"00000000";
begin
  --------------------------------------------------------------------------------
  -- clock and reset
  --------------------------------------------------------------------------------
  reset_n <= '0','1' after 123 ns;

  clk <= not(clk) after HALF_PERIOD when running else clk;
  --------------------------------------------------------------------------------
  -- Design Under Test
  --------------------------------------------------------------------------------
  dut : entity work.uart_bus_master_controler(arch)
    port map (
      reset_n        => reset_n       ,
      clk            => clk           ,
      byte_in        => byte_in       ,
      byte_in_valid  => byte_in_valid ,
      byte_out       => byte_out      ,
      byte_out_valid => byte_out_valid,
      bus_en         => bus_en        ,
      bus_wr         => bus_wr        ,
      bus_addr       => bus_addr      ,
      bus_din        => bus_din       ,
      bus_dout       => bus_dout      );

  ---------------------------------------------------------------------
  -- Simple device that reacts to the bus
  ---------------------------------------------------------------------
  regs : process(reset_n,clk)
  begin
    if reset_n='0' then
      reg_a <= (others =>'0');
      bus_dout <= (others =>'0');
    elsif rising_edge(clk) then
      if bus_en='1' then
        if  bus_wr='1' then
          case bus_addr is
            when ADDR_REG_A =>
              reg_a <= bus_din;
            when ADDR_REG_B =>
              reg_b <= bus_din;
            when others =>
              null;
          end case;
        else
          case bus_addr is
            when ADDR_REG_A =>
              bus_dout <= reg_a;
            when ADDR_REG_B =>
              bus_dout <= reg_b;
            when others =>
              bus_dout <= x"f0f0f0f0";
          end case;
        end if;
      end if;
    end if;
  end process;
  --------------------------------------------------------------------------------
  -- sequential stimuli
  --------------------------------------------------------------------------------
  stim : process
    subtype byte is std_logic_vector(7 downto 0);
    --type bytes_from_uart_t is array(0 to 100) of byte;
    type bytes_from_uart_t is array(natural range <>) of byte;
    constant bytes_from_uart : bytes_from_uart_t :=(
     --.......cmd.......address...........din..............
     "00000011",x"ab",x"cd", x"de",x"ad",x"be",x"ef", --WR @abcd 0xdeadbeef
     "00000011",x"fe",x"ed", x"ca",x"fe",x"ba",x"be", --WR @feed 0xcafebabe
     "00000010",x"ab",x"cd", x"00",x"00",x"00",x"00"  --RD @abcd 
    );
  begin
    byte_in       <= x"00";
    byte_in_valid <= '0';
    report "running testbench for uart_bus_master(arch)";
    report "waiting for asynchronous reset";
    wait until reset_n='1';
    wait_cycles(10);
    --for i in 0 to 100 loop
    report "length=" & integer'image(bytes_from_uart'length);
    for i in 0 to bytes_from_uart'length-1 loop
      report "i=" & integer'image(i);
      wait_cycles(20);
      byte_in_valid <='1';
      byte_in <= bytes_from_uart(i);
      wait_cycles(1);
      byte_in_valid <='0';
    end loop;
    report "end of simulation";
    wait_cycles(4);
    running <= false;
    wait;
  end process;
end bhv;
