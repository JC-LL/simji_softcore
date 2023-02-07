library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ip_simji is
  generic (
    address_start : unsigned(31 downto 0) := x"00000000";
    address_end   : unsigned(31 downto 0) := x"00000000"
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
    bus_to_master_data: in  std_logic_vector(31 downto 0);
    --
    debug             : out std_logic_vector( 7 downto 0)
  );
end entity;

architecture rtl of ip_simji is
  signal control_reg : std_logic_vector(7 downto 0);
  signal status_reg : std_logic_vector(7 downto 0);
  signal go : std_logic;
  signal stopped : std_logic;
begin

  decode_p:process(reset_n,clk)
  begin
    if reset_n='0' then
      control_reg <= (others=>'0');
      status_reg <= (others=>'0');
      slave_to_bus_data <= x"00000000";
    elsif rising_edge(clk) then
      slave_to_bus_data <= x"00000000";
      status_reg(0) <= stopped;

      if bus_to_slave_en='1' then
        if bus_to_slave_addr=x"00000202" then
          if bus_to_slave_wr='1' then
            control_reg <= bus_to_master_data(7 downto 0);
          else
            slave_to_bus_data <= x"00000" & control_reg;
          end if;
        elsif bus_to_slave_addr=x"00000203" then
          if bus_to_slave_wr='1' then
             status_reg <= bus_to_master_data(7 downto 0);
          else
            slave_to_bus_data <= x"00000" & status_reg;
          end if;
        end if;
      end if;
    end if;
  end process;

  go <= control_reg(0);

end architecture;
