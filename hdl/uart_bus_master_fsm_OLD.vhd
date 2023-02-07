library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_bus_master_fsm is
  port (
    reset_n             : in std_logic;
    clk                 : in std_logic;
    -- status
    uart_rcvr_avail     : in std_logic;
    uart_sndr_ready     : in std_logic;
    -- commands
    fsm_to_uart_pop     : out std_logic;
    fsm_to_uart_push    : out std_logic;
    -- data
    uart_to_fsm_data    : in  std_logic_vector(7 downto 0);
    fsm_to_uart_data    : out std_logic_vector(7 downto 0);
    -- bus side
    master_to_bus_en       : out std_logic;
    master_to_bus_wr       : out std_logic;
    master_to_bus_addr     : out unsigned(31 downto 0);
    master_to_bus_data     : out std_logic_vector(31 downto 0);
    bus_to_master_data     : in  std_logic_vector(31 downto 0)
  );
end entity;

architecture RTL of uart_bus_master_fsm is

  type state_type is (IDLE, GET_BYTE,TEMPO_1T, EMIT_BUS_TRANSACTION,
                      WAIT_FOR_PERIPHERAL,
                      SAMPLE_SLAVE_DATA, PUSH_SLAVE_DATA_BYTES);
  signal state : state_type;

  signal regs            : std_logic_vector(9*8-1 downto 0);
  signal count_pop       : integer range 0 to 9;
  signal count_push      : integer range 0 to 4;

  signal addr_bytes      : unsigned(31 downto 0);
  signal data_bytes      : std_logic_vector(31 downto 0);
  signal ctrl_byte       : std_logic_vector(7 downto 0);
  signal data_from_slave : std_logic_vector(31 downto 0);
begin

  data_bytes <= regs(71 downto 40);
  addr_bytes <= unsigned(regs(39 downto 8));
  ctrl_byte  <= regs(7 downto 0);

  fsm: process(reset_n,clk)
    variable byte_in  : std_logic_vector(7 downto 0);
    variable byte_out : std_logic_vector(7 downto 0);
  begin
    if reset_n='0' then
      state              <= IDLE;
      fsm_to_uart_pop    <= '0';
      fsm_to_uart_push   <= '0';
      count_pop          <= 0;
      count_push         <= 0;
      regs               <= (others=>'0');
      data_from_slave    <= (others=>'0');
      fsm_to_uart_data   <= (others=>'0');
    elsif rising_edge(clk) then
      byte_in := uart_to_fsm_data;
      --
      fsm_to_uart_pop    <= '0';
      fsm_to_uart_push   <= '0';
      --
      master_to_bus_en   <= '0';
      master_to_bus_wr   <= '0';
      master_to_bus_addr <= (others=>'0');
      master_to_bus_data <= (others=>'0');
      --
      case state is
      when IDLE =>
        count_pop            <= 0;
        count_push           <= 0;
        fsm_to_uart_data     <= (others=>'0');
        data_from_slave      <= (others=>'0');
        if uart_rcvr_avail='1' then
          regs <= byte_in & regs(71 downto 8);
          fsm_to_uart_pop <= '1';
          count_pop       <= 1;
          state <= TEMPO_1T;--for pop to take effect on uart_rcvr_avail
        end if;
      when TEMPO_1T =>
        state <= GET_BYTE;
      when GET_BYTE =>
        if count_pop < 9 then
          if uart_rcvr_avail='1' then
            regs            <= byte_in & regs(71 downto 8);
            fsm_to_uart_pop <= '1';
            count_pop       <= count_pop + 1;
            if count_pop = 8 then --old value tested
              state <= EMIT_BUS_TRANSACTION;
            else
              state <= TEMPO_1T;
            end if;
          end if;
        end if;
      when EMIT_BUS_TRANSACTION =>
        master_to_bus_en   <= ctrl_byte(0);
        master_to_bus_wr   <= ctrl_byte(1);
        master_to_bus_addr <= addr_bytes;
        master_to_bus_data <= data_bytes;
        if ctrl_byte(1)='1' then --write
          state <= IDLE;
        else --read
          state <= WAIT_FOR_PERIPHERAL;
        end if;
      when WAIT_FOR_PERIPHERAL =>
        state <= SAMPLE_SLAVE_DATA;
      when SAMPLE_SLAVE_DATA =>
        data_from_slave <= bus_to_master_data;--sampling
        state <= PUSH_SLAVE_DATA_BYTES;
      when PUSH_SLAVE_DATA_BYTES =>
        if count_push < 4 then
          byte_out := data_from_slave((count_push+1)*8-1 downto count_push*8);
          fsm_to_uart_data <= byte_out;
          fsm_to_uart_push <= '1';
          count_push       <= count_push + 1;
        else
          state <= IDLE;
        end if;
      when others =>
        null;
      end case;
    end if;
  end process;
end architecture;
