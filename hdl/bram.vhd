library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity bram is
  generic (
    ADDR_SIZE : natural :=8;
    DATA_SIZE : natural :=32
  );
  port (
    clk     : in  std_logic;
    we      : in  std_logic;
    addr    : in  unsigned(ADDR_SIZE-1 downto 0);
    data_i  : in  std_logic_vector(DATA_SIZE-1 downto 0);
    data_o  : out std_logic_vector(DATA_SIZE-1 downto 0)
  );
end entity;

architecture rtl of bram is
  type ram_type is array(0 to 2**ADDR_SIZE-1) of std_logic_vector(DATA_SIZE-1 downto 0);
  signal ram : ram_type;
  signal addr_1t : unsigned(ADDR_SIZE-1 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if we='1' then
        ram(to_integer(addr)) <= data_i;
      end if;
      addr_1t <= addr;
    end if;
  end process;

  data_o <= ram(to_integer(addr_1t));

end architecture;
