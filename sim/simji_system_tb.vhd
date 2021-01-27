--------------------------------------------------------------------------------
-- this file was generated automatically by Vertigo Ruby utility
-- date : (d/m/y h:m) 19/01/2021 15:32
-- author : Jean-Christophe Le Lann - 2021
--------------------------------------------------------------------------------

-- WARN : compile this with VHDL 08
-- ghdl -a --std=08

library ieee,std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;

entity simji_system_tb is
end entity;

architecture bhv of simji_system_tb is
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
  signal bus_en   : std_logic;
  signal bus_wr   : std_logic;
  signal bus_addr : std_logic_vector(15 downto 0);
  signal bus_din  : std_logic_vector(31 downto 0);
  signal bus_dout : std_logic_vector(31 downto 0);
begin
  --------------------------------------------------------------------------------
  -- clock and reset
  --------------------------------------------------------------------------------
  reset_n <= '0','1' after 123 ns;

  clk <= not(clk) after HALF_PERIOD when running else clk;
  --------------------------------------------------------------------------------
  -- Design Under Test
  --------------------------------------------------------------------------------
   dut : entity work.simji_system(arch)
     port map (
       reset_n  => reset_n ,
       clk      => clk     ,
       bus_en   => bus_en  ,
       bus_wr   => bus_wr  ,
       bus_addr => bus_addr,
       bus_din  => bus_din ,
       bus_dout => bus_dout);
  --------------------------------------------------------------------------------
  -- sequential stimuli
  --------------------------------------------------------------------------------
  stim : process
    file F : text;
    variable L: line;
    variable status : file_open_status;
    variable en_v   : std_logic;
    variable wr_v   : std_logic;
    variable addr_v : std_logic_vector(15 downto 0);
    variable data_v : std_logic_vector(31 downto 0);
    --
    variable nb_bus_trans : natural := 0;

    function to_std_logic(i : in bit) return std_logic is
      begin
        if i = '0' then
          return '0';
        end if;
        return '1';
      end function;

    function str_command(en,wr : std_logic; addr : std_logic_vector; data : std_logic_vector) return String is
      variable ret : String(1 to 17);
    begin
      ret:="-----------------";
      if en='1' then
        ret(1):='*';
        if wr='1' then
          ret(3):='w';
        else
          ret(3):='r';
        end if;
        ret(5 to 8) := to_hstring(addr);
        ret(10 to ret'length) := to_hstring(data);
      end if;
      return ret;
    end function;
    --
    variable stopped : std_logic;

  begin
    report "running testbench for simji_system(arch)";
    report "waiting for asynchronous reset";
    FILE_OPEN(status,F,"commands.bfm",read_mode);
    if status/=open_ok then
      report "problem to open stimulus file commands.bfm" severity error;
    else
      bus_en   <= '0';
      bus_wr   <= '0';
      bus_addr <= (others =>'0');
      bus_din  <= (others =>'0');
      wait until reset_n='1';
      report "starting bus transactions...";
      while not(ENDFILE(f)) loop
        wait_cycles(20); -- une transaction tous les 20 cycles
        nb_bus_trans:=nb_bus_trans+1;
        readline(F,l);
        read(l,en_v);
        read(l,wr_v);
        hread(l,addr_v);
        hread(l,data_v);
        bus_en  <= en_v;
        bus_wr   <= wr_v;
        bus_addr <= addr_v;
        bus_din  <= data_v;
        report "bfm command : " & str_command(en_v,wr_v,addr_v,data_v);
        wait_cycles(1);
        bus_en  <= '0';
        bus_wr  <= '0';
      end loop;
      report integer'image(nb_bus_trans) & " bus commands processed.";
    end if;

    report "end of bfm transactions";

    report "now polling end of SIMJI processing...";

    stopped:='0';

    while stopped='0' loop
      wait_cycles(1);
      bus_en   <= '1';
      bus_wr   <= '0'; --read
      bus_addr <= x"1001";-- STATUS
      wait_cycles(1);
      bus_en   <= '0';
      bus_wr   <= '0';
      bus_addr <= x"0000";
      wait_cycles(1);
      stopped := bus_dout(0);-- bit position of 'stop' information.
    end loop;

    report "reached a STOP in Simji program.";
    wait_cycles(20);
    running <= false;
    wait;
  end process;
end bhv;
