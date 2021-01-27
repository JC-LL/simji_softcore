library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_bus_master is
  generic(DVSR: integer := 325);-- for 100Mhz
  port (
    reset_n        : in  std_logic;
    clk            : in  std_logic;
    sreset         : in  std_logic;
    --
    rx             : in  std_logic;
    tx             : out std_logic;
    --
    bus_en         : out std_logic;
    bus_wr         : out std_logic;
    bus_addr       : out std_logic_vector(15 downto 0);
    bus_din        : out std_logic_vector(31 downto 0);
    bus_dout       : in  std_logic_vector(31 downto 0)
    );
end entity;

architecture arch of uart_bus_master is
  signal rd_uart, wr_uart  : std_logic;
  signal w_data            : std_logic_vector(7 downto 0);
  signal count             : unsigned(7 downto 0);
  signal tx_full, rx_empty : std_logic;
  signal r_data            : std_logic_vector(7 downto 0);

  signal data_from_pc_valid_r : std_logic;
  signal data_from_pc_r       : std_logic_vector(7 downto 0);
  --
  signal byte_in_valid,byte_out_valid : std_logic;
  signal byte_in,byte_out : std_logic_vector(7 downto 0);
  signal reset : std_logic;
begin

  reset <= not(reset_n);

  uart_1 : entity work.uart
    generic map (
      DBIT     => 8,
      SB_TICK  => 16,
      DVSR     => DVSR,--325 for 100Mhz
      DVSR_BIT => 9,
      FIFO_W   => 3)
    port map (
      clk      => clk,--100 Mhz
      reset    => reset,
      rd_uart  => byte_in_valid,
      wr_uart  => byte_out_valid,
      rx       => rx,
      w_data   => byte_out,
      tx_full  => tx_full,
      rx_empty => rx_empty,
      r_data   => byte_in,
      tx       => tx);

  -- pump the FIFO systematically
  byte_in_valid <= not(rx_empty);

  controler : entity work.uart_bus_master_controler
    port map (
      reset_n        => reset_n,
      clk            => clk,
      --
      byte_in        => byte_in,
      byte_in_valid  => byte_in_valid,
      byte_out       => byte_out,
      byte_out_valid => byte_out_valid,
      --
      bus_en         => bus_en  ,
      bus_wr         => bus_wr  ,
      bus_addr       => bus_addr,
      bus_din        => bus_din ,
      bus_dout       => bus_dout
    );

end arch;
