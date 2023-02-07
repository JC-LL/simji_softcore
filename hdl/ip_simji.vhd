library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ip_lib;
entity ip_simji is
  generic (
    address_start : unsigned(31 downto 0) := x"00000000";
    address_end   : unsigned(31 downto 0) := x"00000000"
  );
  port (
    reset_n : in std_logic;
    clk     : in std_logic;
    -- bus side
    bus_to_slave_en     : in  std_logic;
    bus_to_slave_wr     : in  std_logic;
    bus_to_slave_addr   : in  unsigned(31 downto 0);
    bus_to_slave_data   : in  std_logic_vector(31 downto 0);
    slave_to_bus_data   : out std_logic_vector(31 downto 0);
    --
    proc_to_bram_i_en   : out std_logic;
    proc_to_bram_i_we   : out std_logic;
    proc_to_bram_i_data : out std_logic_vector(31 downto 0);
    proc_to_bram_i_addr : out std_logic_vector(7  downto 0);
    bram_to_proc_i_data : in  std_logic_vector(31 downto 0);

    --
    proc_to_bram_d_en   : out std_logic;
    proc_to_bram_d_we   : out std_logic;
    proc_to_bram_d_data : out std_logic_vector(31 downto 0);
    proc_to_bram_d_addr : out std_logic_vector(7  downto 0);
    bram_to_proc_d_data : in  std_logic_vector(31 downto 0);
    leds                : out std_logic_vector(15 downto 0)
  );
end entity;

architecture rtl of ip_simji is

  signal control_reg : std_logic_vector(7 downto 0);
  signal status_reg : std_logic_vector(7 downto 0);
  signal stopped : std_logic;
  signal go : std_logic;
  constant BIT_STOPPED : natural := 0;
  constant BIT_GO : natural :=0;
begin

  decode_p:process(reset_n,clk)
  begin
    if reset_n='0' then
      control_reg <= (others=>'0');
      status_reg  <= (others=>'0');
      slave_to_bus_data <= x"00000000";
    elsif rising_edge(clk) then

      slave_to_bus_data <= x"00000000";
      status_reg(BIT_STOPPED) <= stopped;

      if bus_to_slave_en='1' then
        case bus_to_slave_addr is
        when x"00000202" =>
          if bus_to_slave_wr='1' then
            control_reg <= bus_to_slave_data(7 downto 0);
          else
            slave_to_bus_data <= x"000000" & control_reg;
          end if;
        when x"00000203" =>
          if bus_to_slave_wr='1' then
            status_reg <= bus_to_slave_data(7 downto 0);
          else
            slave_to_bus_data <= x"000000" & status_reg;
          end if;
        when others =>
          null;
        end case;
      end if;
    end if;
  end process;

  go <= control_reg(BIT_GO);

  --------------------------------------------------------------
  -- Simji core instance
  --------------------------------------------------------------
  simji_core_i: entity ip_lib.simji_core
  port map (
    reset_n          => reset_n,
    clk              => clk,
    go               => go,
    stopped          => stopped,
    instruction_en   => proc_to_bram_i_en,
    instruction_addr => proc_to_bram_i_addr,
    instruction_data => bram_to_proc_i_data,
    data_en          => proc_to_bram_d_en,
    data_wr          => proc_to_bram_d_we,
    data_addr        => proc_to_bram_d_addr,
    data_in          => bram_to_proc_d_data,
    data_out         => proc_to_bram_d_data,
    leds             => leds
  );

  proc_to_bram_i_we <= '0';--processor cannot access its instruction memory for WRITE.

end architecture;
