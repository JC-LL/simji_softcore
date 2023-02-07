library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ip_lib;

entity ip_bram is
  generic (
    BRAM_ADDR_SIZE : natural := 8;
    BRAM_DATA_SIZE : natural := 8;
    ADDRESS_START  : unsigned(31 downto 0) := x"00000001";
    ADDRESS_END    : unsigned(31 downto 0) := x"00000101"
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
    proc_to_bram_en   : in std_logic;
    proc_to_bram_we   : in std_logic;
    proc_to_bram_data : in std_logic_vector(31 downto 0);
    proc_to_bram_addr : in std_logic_vector(7  downto 0);
    bram_to_proc_data : out  std_logic_vector(31 downto 0)
  );
end entity;

architecture rtl of ip_bram is
  type state_t is (IDLE,SAMPLE_DATA);
  signal state,state_c : state_t;

  signal master_to_bram_en     : std_logic;
  signal master_to_bram_we     : std_logic;
  signal master_to_bram_addr   : unsigned(BRAM_ADDR_SIZE-1 downto 0);
  signal master_to_bram_data_i : std_logic_vector(BRAM_DATA_SIZE-1 downto 0);
  signal master_to_bram_data_o : std_logic_vector(BRAM_DATA_SIZE-1 downto 0);

  signal bram_we     : std_logic;
  signal bram_addr   : unsigned(BRAM_ADDR_SIZE-1 downto 0);
  signal bram_data_i : std_logic_vector(BRAM_DATA_SIZE-1 downto 0);
  signal bram_data_o : std_logic_vector(BRAM_DATA_SIZE-1 downto 0);

begin

  dff : process(reset_n,clk)
  begin
    if reset_n='0' then
      state <= IDLE;
    elsif rising_edge(clk) then
      state <= state_c;
    end if;
  end process;

  next_state_comb: process(state,bus_to_slave_en,bus_to_slave_addr,bus_to_slave_addr,bus_to_slave_data,bram_data_o)
  begin
    state_c                     <= state;
    master_to_bram_addr         <= to_unsigned(0,BRAM_ADDR_SIZE);
    master_to_bram_en           <= '0';
    master_to_bram_we           <= '0';
    master_to_bram_data_i       <= (others=>'0');
    slave_to_bus_data           <= (others=>'0');
    master_to_bram_addr         <= (others=>'0');
    case state is
      when IDLE =>
        if bus_to_slave_en='1' and bus_to_slave_addr >= ADDRESS_START and bus_to_slave_addr <= ADDRESS_END then
          master_to_bram_en     <= '1';
          if bus_to_slave_wr='1' then
            master_to_bram_addr   <= resize(bus_to_slave_addr - ADDRESS_START,BRAM_ADDR_SIZE);
            master_to_bram_we     <= '1';
            master_to_bram_data_i <= bus_to_slave_data(BRAM_DATA_SIZE-1 downto 0);
          else --read
            master_to_bram_addr   <= resize(bus_to_slave_addr - ADDRESS_START,BRAM_ADDR_SIZE);
            master_to_bram_we     <= '0';
            state_c     <= SAMPLE_DATA;
          end if;
        end if;
      when SAMPLE_DATA =>
        slave_to_bus_data <= bram_data_o;
        state_c           <= IDLE;
      when others =>
        null;
    end case;
  end process;

  ------------------------------------------------
  -- Muxing between Master access and CORE access
  ------------------------------------------------
  bram_we     <= master_to_bram_we or proc_to_bram_we;
  bram_addr   <= master_to_bram_addr when master_to_bram_en='1' else
                 unsigned(proc_to_bram_addr) when proc_to_bram_en='1' else
                 to_unsigned(0,BRAM_ADDR_SIZE);
  bram_data_i <= master_to_bram_data_i when master_to_bram_en='1' else
                 proc_to_bram_data     when proc_to_bram_en='1' else
                 (others =>'0');
                 
  bram_to_proc_data <= bram_data_o;
  ------------------------------------------------
  -- BRAM instance
  ------------------------------------------------
  bram_i : entity ip_lib.bram
    generic map(
      ADDR_SIZE => BRAM_ADDR_SIZE,
      DATA_SIZE => BRAM_DATA_SIZE
    )
    port map(
      clk     => clk,
      we      => bram_we,
      addr    => bram_addr,
      data_i  => bram_data_i,
      data_o  => bram_data_o
    );

end architecture;
