library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package uart_cst is
  -- define number of sampling ticks for a single transmitted bit
  --constant NB_100HZ_CLOCK_CYCLES_FOR_TICK : natural := 325;
  -- 10^8/(19200*16) = 325
  -- each bit sampled 16 times

  -- ============================================================
  --                 WARNING : for simulation only
  -- ============================================================
  constant NB_100HZ_CLOCK_CYCLES_FOR_TICK : natural := 3;
end package;
