library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uart_lib;
use uart_lib.uart_cst.NB_100HZ_CLOCK_CYCLES_FOR_TICK;

entity tick_gen is
  port (
    reset_n    : in std_logic;
    clk100     : in std_logic;
    tick       : out std_logic
  );
end entity;

architecture arch of tick_gen is
  constant NBITS     : natural := 9;
  signal counter     : unsigned(NBITS-1 downto 0);
  constant NB_CYCLES : natural := NB_100HZ_CLOCK_CYCLES_FOR_TICK;
begin

  counting:process(reset_n,clk100)
  begin
    if reset_n='0' then
      counter <= to_unsigned(0,NBITS);
      tick <= '0';
    elsif rising_edge(clk100) then
      if counter=NB_CYCLES-1 then
        counter <= to_unsigned(0,NBITS);
        tick <= '1';
      else
        counter <= counter + 1;
        tick <= '0';
      end if;
    end if;
  end process;

end architecture;
