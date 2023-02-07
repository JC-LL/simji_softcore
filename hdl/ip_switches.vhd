library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ip_switches is
  generic (
    address_start : unsigned(31 downto 0) := x"00000001";
    address_end   : unsigned(31 downto 0) := x"00000001"
  );
  port (
    reset_n : in std_logic;
    clk     : in std_logic;
    -- bus side
    bus_to_slave_en   : in  std_logic;
    bus_to_slave_wr   : in  std_logic;
    bus_to_slave_addr : in  unsigned(31 downto 0);
    bus_to_slave_data : in  std_logic_vector(31 downto 0);
    slave_to_bus_data : out std_logic_vector(31 downto 0);
    --
    switches          : in  std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of ip_switches is
  signal regs : std_logic_vector(7 downto 0);
begin

  decode_p:process(reset_n,clk)
  begin
    if reset_n='0' then
      regs <= x"00";
      slave_to_bus_data <=  x"00000000";
    elsif rising_edge(clk) then
      slave_to_bus_data <=  x"00000000";
      -- permanent sampling :
      regs <= switches;
      --
      if bus_to_slave_en='1' then
        if bus_to_slave_wr='0' then--READ ONLY
          if bus_to_slave_addr >= address_start and bus_to_slave_addr <= address_end then
            slave_to_bus_data <= x"000000" & regs;
          end if;
        end if;
      end if;
    end if;
  end process;

end architecture;
