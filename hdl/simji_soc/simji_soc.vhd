library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simji_soc is
  generic(
    nbits_inst_addr : natural :=10;
    nbits_data_addr : natural :=10
  );
  port (
    reset_n  : in  std_logic;
    clk      : in  std_logic;
    bus_en   : in  std_logic;
    bus_wr   : in  std_logic;
    bus_addr : in  std_logic_vector(15 downto 0);
    bus_din  : in  std_logic_vector(31 downto 0);
    bus_dout : out std_logic_vector(31 downto 0)
    );
end entity;

architecture arch of simji_soc is

  -- memory map description :
  constant ADDR_REG_INFO     : std_logic_vector(15 downto 0) := x"0000";
  constant ADDR_REG_DUMMY    : std_logic_vector(15 downto 0) := x"0001";
  constant ADDR_CORE_CONTROL : std_logic_vector(15 downto 0) := x"0002";
  constant ADDR_CORE_STATUS  : std_logic_vector(15 downto 0) := x"0003";

  constant ADDR_BASE_CODE    : std_logic_vector(15 downto 0) := x"1000";
  constant ADDR_LAST_CODE    : std_logic_vector(15 downto 0) := x"13ff";
  constant ADDR_BASE_DATA    : std_logic_vector(15 downto 0) := x"2400";
  constant ADDR_LAST_DATA    : std_logic_vector(15 downto 0) := x"27ff";

  -- memory-mapped reg signals :
  signal reg_info         : std_logic_vector(31 downto 0);
  signal reg_dummy        : std_logic_vector(31 downto 0);
  signal reg_core_control : std_logic_vector(2 downto 0);
  signal reg_core_status  : std_logic_vector(31 downto 0);

  -- DFF enables
  signal reg_info_en           : std_logic;
  signal reg_dummy_en          : std_logic;
  signal reg_core_control_en   : std_logic;
  signal reg_core_status_en    : std_logic;

  -- bit map description
  constant BIT_GO : natural := 2;

  -- RAM control signals
  signal code_en        : std_logic;
  signal code_wr        : std_logic;
  signal code_addr      : std_logic_vector(nbits_inst_addr-1 downto 0);
  signal code_din       : std_logic_vector(31 downto 0);
  signal code_dout      : std_logic_vector(31 downto 0);

  --
  signal data_en        : std_logic;
  signal data_wr        : std_logic;
  signal data_addr      : std_logic_vector(nbits_data_addr-1 downto 0);
  signal data_din       : std_logic_vector(31 downto 0);
  signal data_dout      : std_logic_vector(31 downto 0);
  --
  signal bus_dout_comb      : std_logic_vector(31 downto 0);
  signal bus_dout_from_regs : std_logic_vector(31 downto 0);
  --
  signal code_rd_1t     : std_logic;
  signal data_rd_1t     : std_logic;


  signal  code_en_from_bus   : std_logic;
  signal  code_wr_from_bus   : std_logic;
  signal  code_addr_from_bus : std_logic_vector(nbits_inst_addr-1 downto 0);
  signal  code_din_from_bus  : std_logic_vector(31 downto 0);
  --
  signal  data_en_from_bus   : std_logic;
  signal  data_wr_from_bus   : std_logic;
  signal  data_addr_from_bus : std_logic_vector(nbits_inst_addr-1 downto 0);
  signal  data_din_from_bus  : std_logic_vector(31 downto 0);
  --

  -- simji core interface
  signal  code_en_from_core    : std_logic;
  signal  code_wr_from_core    : std_logic;
  signal  code_addr_from_core  : std_logic_vector(nbits_inst_addr-1 downto 0);
  signal  code_mem_to_core     : std_logic_vector(31 downto 0);
  --
  signal  data_en_from_core    : std_logic;
  signal  data_wr_from_core    : std_logic;
  signal  data_addr_from_core  : std_logic_vector(nbits_data_addr-1 downto 0);
  signal  data_mem_to_core     : std_logic_vector(31 downto 0);
  signal  data_core_to_mem     : std_logic_vector(31 downto 0);

  -- bits signals
  signal   go : std_logic;
  signal  stopped              : std_logic;

begin

  address_decoding_comb : process(bus_addr, bus_din, bus_en, bus_wr,
                                  reg_core_control, reg_dummy,reg_info,reg_core_control)
  begin
    reg_info_en              <= '0';
    reg_dummy_en             <= '0';
    reg_core_control_en      <= '0';
    reg_core_status_en       <= '0';
    --
    code_en_from_bus         <= '0';
    code_wr_from_bus         <= '0';
    code_addr_from_bus       <= (others => '0');
    code_din_from_bus        <= (others => '0');

    data_en_from_bus         <= '0';
    data_wr_from_bus         <= '0';
    data_addr_from_bus       <= (others => '0');
    data_din_from_bus        <= (others => '0');
    --
    bus_dout_comb       <= (others => '0');

    -- or keep previous data ? --modify sensitivity
    -- bus_dout_comb       <= bus_dout_from_regs;
    --
    if bus_en = '1' then
      if bus_wr = '1' then
        case bus_addr is
          when ADDR_REG_INFO =>
            reg_info_en  <= '1';
          when ADDR_REG_DUMMY =>
            reg_dummy_en <= '1';
          when ADDR_CORE_CONTROL =>
            reg_core_control_en <= '1';
          when ADDR_CORE_STATUS =>
            reg_core_status_en <= '1';
          when others =>
            if unsigned(bus_addr) >= unsigned(ADDR_BASE_CODE) and
               unsigned(bus_addr) <= unsigned(ADDR_LAST_CODE) then
              code_en_from_bus   <= '1';
              code_wr_from_bus   <= '1';
              code_addr_from_bus <= std_logic_vector(resize(unsigned(bus_addr),nbits_inst_addr));
              code_din_from_bus  <= bus_din;
            elsif unsigned(bus_addr) >= unsigned(ADDR_BASE_DATA) and
                  unsigned(bus_addr) <= unsigned(ADDR_LAST_DATA) then
              data_en_from_bus   <= '1';
              data_wr_from_bus   <= '1';
              data_addr_from_bus <= std_logic_vector(resize(unsigned(bus_addr),nbits_inst_addr));
              data_din_from_bus  <= bus_din;
            end if;
        end case;
      else  -- read bus transaction
        case bus_addr is
          when ADDR_REG_INFO =>
            bus_dout_comb <= reg_info;
          when ADDR_REG_DUMMY =>
            bus_dout_comb <= reg_dummy;
          when ADDR_CORE_CONTROL =>
            bus_dout_comb <= x"0000000" & '0' & reg_core_control;
          when ADDR_CORE_STATUS =>
            bus_dout_comb <= reg_core_status;-- I am rich
          when others =>
            -- warn : for synchronous memory, we get their output one cycle after the commands have been issued.
            if unsigned(bus_addr) >= unsigned(ADDR_BASE_CODE) and
               unsigned(bus_addr) <= unsigned(ADDR_LAST_CODE) then
              code_en_from_bus   <= '1';
              code_wr_from_bus   <= '0';
              code_addr_from_bus <= std_logic_vector(resize(unsigned(bus_addr),nbits_inst_addr));
            elsif unsigned(bus_addr) >= unsigned(ADDR_BASE_DATA) and
                  unsigned(bus_addr) <= unsigned(ADDR_LAST_DATA) then
              data_en_from_bus   <= '1';
              data_wr_from_bus   <= '0';
              data_addr_from_bus <= std_logic_vector(resize(unsigned(bus_addr),nbits_inst_addr));
            end if;
        end case;
      end if;
    end if;
  end process;
  --------------------------------------------------------
  -- Memory-mapped registers
  --------------------------------------------------------
  memory_mapped_regs : process(reset_n, clk)
  begin
    if reset_n = '0' then
      reg_info         <= x"000000" & "10101011";--remarquable pattern at reset
      reg_dummy        <= (others => '0');
      reg_core_control <= (others => '0');
      reg_core_status  <= (others => '0');
    elsif rising_edge(clk) then
      if reg_info_en = '1' then
        reg_info <= bus_din;
      end if;
      if reg_dummy_en = '1' then
        reg_dummy <= bus_din;
      end if;
      if reg_core_control_en = '1' then
        reg_core_control <= bus_din(2 downto 0);
      else
        reg_core_control(BIT_GO) <='0';--auto reset for toggling
      end if;
      if reg_core_status_en = '1' then
        reg_core_status <= bus_din;
      else
        reg_core_status(0) <= stopped;
      end if;
    end if;
  end process;

  -- signals extracted from MM registers :
  go <= reg_core_control(BIT_GO);
  --------------------------------------------------------
  -- instanciation of the Simji core
  --------------------------------------------------------
  simji_core : entity work.simji_core(rtl)
  generic map (
    nbits_inst_addr => nbits_inst_addr,
    nbits_data_addr => nbits_data_addr
  )
  port map (
    reset_n         => reset_n,
    clk             => clk,
    go              => go,
    stopped         => stopped,
    --
    instr_en        => code_en_from_core  ,
    instr_wr        => code_wr_from_core  ,
    instr_addr      => code_addr_from_core,
    instr_in        => code_mem_to_core    ,
    --
    data_en         => data_en_from_core  ,
    data_wr         => data_wr_from_core  ,
    data_addr       => data_addr_from_core,
    data_in         => data_mem_to_core   ,
    data_out        => data_core_to_mem
  );
  --------------------------------------------------------
  -- Memory-mapped RAM
  --------------------------------------------------------

  --------------------------------------------------------
  -- code memory
  ---------------------------------------------------------
  code_en   <= code_en_from_bus or  code_en_from_core;
  code_wr   <= code_wr_from_bus or  code_wr_from_core;
  code_addr <= code_addr_from_bus when code_en_from_bus='1' else
                   code_addr_from_core;
  code_din  <= code_din_from_bus when code_en_from_bus='1' else
                   (others=>'0');-- no writing from processor.

  code_ram_inst : entity work.bram
    generic map(
      nbits_addr => nbits_inst_addr,
      nbits_data => 32
      )
    port map(
      clk     => clk,
      en      => code_en,
      we      => code_wr,
      address => code_addr,
      datain  => code_din,
      dataout => code_mem_to_core
    );
  --------------------------------------------------------
  -- data memory
  --------------------------------------------------------
  data_en   <= data_en_from_bus or data_en_from_core;
  data_wr   <= data_wr_from_bus or data_wr_from_core;
  data_addr <= data_addr_from_bus when data_en_from_bus='1' else
                   data_addr_from_core;
  data_din  <= data_din_from_bus when data_en_from_bus='1' else
                   data_core_to_mem;

  data_ram_inst : entity work.bram
    generic map(
      nbits_addr => nbits_data_addr,
      nbits_data => 32
      )
    port map(
      clk     => clk,
      en      => data_en,
      we      => data_wr,
      address => data_addr,
      datain  => data_din,
      dataout => data_mem_to_core
      );
  ---------------------------------------------------------------
  -- Bus output : 1 cycle delay for resynchronization from REGS
  ---------------------------------------------------------------
  output_reg : process(clk, reset_n)
  begin
    if reset_n = '0' then
      bus_dout_from_regs <= (others => '0');
    elsif rising_edge(clk) then
      bus_dout_from_regs <= bus_dout_comb;
    end if;
  end process;

  ---------------------------------------------------------
  -- these two signals will allow to multiplex bus_dout
  -- from various sources : REGS, CODE RAM and DATA RAM
  ---------------------------------------------------------
  rams_read_delay : process(clk, reset_n)
  begin
    if reset_n = '0' then
      code_rd_1t <= '0';
      data_rd_1t <= '0';
    elsif rising_edge(clk) then
      if code_en_from_bus = '1' and code_wr_from_bus = '0' then  --read
        code_rd_1t <= '1';
      else
        code_rd_1t <= '0';
      end if;
      if data_en_from_bus = '1' and data_wr_from_bus = '0' then  --read
        data_rd_1t <= '1';
      else
        data_rd_1t <= '0';
      end if;
    end if;
  end process;

-------------------------------------------------------------
-- Multiplex dout
-------------------------------------------------------------
  bus_dout <= code_mem_to_core when code_rd_1t = '1' else
              data_mem_to_core when data_rd_1t = '1' else
              bus_dout_from_regs;

end architecture;
