library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package soc_pkg is

  type peripherals_names is (
    IP_LEDS,
    IP_SWITCHES,
    IP_BRAM1,
    IP_BRAM2,
    IP_SIMJI
  );

  type peripheral_location is record
    address_start   : unsigned(31 downto 0);
    address_end     : unsigned(31 downto 0);
  end record;

  type memory_map_t is array(peripherals_names) of peripheral_location;

  constant MEMORY_MAP : memory_map_t :=(
    IP_LEDS     => (x"00000000", x"00000000"),
    IP_SWITCHES => (x"00000001", x"00000001"),
    IP_BRAM1    => (x"00000002", x"00000101"),
    IP_BRAM2    => (x"00000102", x"00000201"),
    IP_SIMJI    => (x"00000202", x"00000203")
  );

end package;
