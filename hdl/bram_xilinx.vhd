library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bram_xilinx is
  generic (
    nbits_addr : natural :=8;
    nbits_data : natural :=32
  );
port (
  clk     : in std_logic;
  sreset  : in std_logic;
  en      : in std_logic;
  we      : in std_logic;
  address : in std_logic_vector(nbits_addr-1 downto 0);
  datain  : in std_logic_vector(nbits_data-1 downto 0);
  dataout : out std_logic_vector(nbits_data-1 downto 0)
  );
end bram_xilinx;

architecture syn of bram_xilinx is
  type ram_type is array (0 to 2**nbits_addr-1) of std_logic_vector (nbits_data-1 downto 0);
  signal RAM: ram_type;
  signal address_s : std_logic_vector(nbits_addr-1 downto 0);
begin

  process (clk)
  begin
    if rising_edge(clk) then
      if en = '1' then
        if we = '1' then
          RAM(to_integer(unsigned(address))) <= datain;
        end if;
      end if;
      address_s <= address;
    end if;
  end process;

  dataout <= RAM(to_integer(unsigned(address_s)));

end syn;
