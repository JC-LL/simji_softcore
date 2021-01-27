library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity slow_ticker is
  generic(N : natural := 27);
  port(
    reset_n   : in  std_logic;
    fast_clk  : in  std_logic;
    slow_clk  : out std_logic; --50% high/low
    slow_tick : out std_logic  --single pulse on positive edge
    );
end entity;

architecture rtl of slow_ticker is
  signal counter : unsigned(N-1 downto 0);
  signal slow_clk_r,slow_clk_c : std_logic;
begin

  counting : process(reset_n,fast_clk)
  begin
    if reset_n = '0' then
      counter <= to_unsigned(0, N);
      slow_clk_r <= '0';
    elsif rising_edge(fast_clk) then
      counter <= counter + 1;
      slow_clk_r <= slow_clk_c;
    end if;
  end process;
 
  slow_clk_c <= counter(N-1);
  slow_clk <= slow_clk_r;
  
  tick : process(reset_n,fast_clk)
  begin
    if reset_n = '0' then
      slow_tick <= '0';
    elsif rising_edge(fast_clk) then
      if slow_clk_r='0' then
        slow_tick <= slow_clk_c xor slow_clk_r;
      else
        slow_tick <= '0';
      end if;
    end if;
  end process;

end rtl;


