library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_bus_master_controler is
  port (
    reset_n        : in  std_logic;
    clk            : in  std_logic;
    --
    byte_in        : in  std_logic_vector(7 downto 0);
    byte_in_valid  : in  std_logic;
    byte_out       : out std_logic_vector(7 downto 0);
    byte_out_valid : out std_logic;
    --
    bus_en         : out std_logic;
    bus_wr         : out std_logic;
    bus_addr       : out std_logic_vector(15 downto 0);
    bus_din        : out std_logic_vector(31 downto 0);
    bus_dout       : in  std_logic_vector(31 downto 0)
    );
end entity;

architecture arch of uart_bus_master_controler is

  type state_t is (
    IDLE, RECEIVING_WRITE_CMD,
    RECEIVING_READ_CMD,WAIT_STATE_1,WAIT_STATE_2,WAIT_STATE_3,SAMPLE_BUS_DOUT, 
    DEALING_WITH_READBACK);
  signal state_r, state_c         : state_t;

  signal count_r, count_c         : integer range 0 to 7;
  signal valid_cmd_r, valid_cmd_c : std_logic;
  type array_bytes is array(0 to 6) of std_logic_vector(7 downto 0);
  signal bytes_r, bytes_c         : array_bytes;
  signal bus_control_en_r,bus_control_en_c     : std_logic;
  signal bus_control_wr_r,bus_control_wr_c     : std_logic;
  signal bus_control_addr_r,bus_control_addr_c : std_logic_vector(15 downto 0);
  signal bus_control_din_r,bus_control_din_c   : std_logic_vector(31 downto 0);

  signal byte_out_r,byte_out_c                 : std_logic_vector(7 downto 0);
  signal byte_out_valid_r,byte_out_valid_c     : std_logic;
  signal dout_r,dout_c                         : std_logic_vector(31 downto 0);
  signal nb_bytes_r,nb_bytes_c                 : integer range 0 to 7;

begin

  tick : process(reset_n, clk)
  begin
    if reset_n = '0' then
      state_r     <= IDLE;
      count_r     <= 0;
      valid_cmd_r <= '0';

      for i in 0 to 6 loop
        bytes_r <= (others=>(others => '0'));
      end loop;
      nb_bytes_r  <= 0;
      dout_r      <= (others=>'0');
      byte_out_r  <= (others=>'0');
    elsif rising_edge(clk) then
      state_r          <= state_c;
      count_r          <= count_c;
      valid_cmd_r      <= valid_cmd_c;

      bytes_r          <= bytes_c;
      nb_bytes_r       <= nb_bytes_c;
      dout_r           <= dout_c;
      byte_out_r       <= byte_out_c;
      byte_out_valid_r <= byte_out_valid_c;
    end if;
  end process;

  byte_out <= byte_out_r;
  byte_out_valid <= byte_out_valid_r;


  next_state : process(byte_in, byte_in_valid, bytes_r,
                       count_r, state_r,byte_out_r,dout_r,
                       byte_out_valid_r,nb_bytes_r,bus_dout)
    variable ctrl_start : std_logic;
    variable write_cmd : std_logic;

  begin
    state_c     <= state_r;
    bytes_c     <= bytes_r;
    count_c     <= count_r;

    dout_c      <= dout_r;
    nb_bytes_c  <= nb_bytes_r;
    valid_cmd_c <= '0';
    byte_out_c  <= byte_out_r;
    byte_out_valid_c  <= '0';

    ctrl_start := '0';
    write_cmd :='0';
    case state_r is
      when IDLE =>
        if byte_in_valid = '1' then
          ctrl_start := byte_in(1);--1x
          write_cmd  := byte_in(1) and byte_in(0);--11
          if ctrl_start = '1' then
            bytes_c(0)(1 downto 0) <= byte_in(1 downto 0);
            count_c                <= 1;
            if write_cmd='1' then
              state_c                <= RECEIVING_WRITE_CMD;
              nb_bytes_c             <= 7;
            else
              state_c                <= RECEIVING_READ_CMD;
              nb_bytes_c             <= 3;
            end if;
          end if;
        end if;
      when RECEIVING_WRITE_CMD =>
        if count_r < nb_bytes_r   then
          if byte_in_valid = '1' then
            bytes_c(count_r) <= byte_in;
            count_c          <= count_r + 1;
          end if;
        else
          valid_cmd_c <= '1';
          count_c     <= 0;
          state_c <= IDLE;
        end if;
      when RECEIVING_READ_CMD =>
        if count_r < nb_bytes_r  then
          if byte_in_valid = '1' then
            bytes_c(count_r) <= byte_in;
            count_c          <= count_r + 1;
          end if;
        else
          valid_cmd_c <= '1';--addressed reg with react in a single cycle
          count_c     <= 0;
          state_c <= WAIT_STATE_1;
        end if;

      when WAIT_STATE_1 =>
        state_c <= WAIT_STATE_2;
      when WAIT_STATE_2 =>
        state_c <= WAIT_STATE_3;
      when WAIT_STATE_3 =>
        dout_c  <= bus_dout;
        state_c <= DEALING_WITH_READBACK;
        count_c <= 4;
      when DEALING_WITH_READBACK =>
        if count_r > 0 then
          count_c    <= count_r - 1;
          byte_out_c <= dout_r((count_r)*8-1 downto (count_r-1)*8);
          -- we hope the UART can absorb 1 byte at each cycle
          byte_out_valid_c <= '1';
        else
          byte_out_c <= "00101010";--42 ~ debug
          count_c     <= 0;
          state_c <= IDLE;
        end if;
      when others =>
        null;
    end case;

  end process;

  cmd_to_bus : process(reset_n, clk)
  begin
    if reset_n = '0' then
      bus_control_en_r   <= '0';
      bus_control_wr_r   <= '0';
      bus_control_addr_r <= (others => '0');
      bus_control_din_r  <= (others => '0');
    elsif rising_edge(clk) then
      bus_control_en_r   <= '0';
      bus_control_wr_r   <= '0';
      bus_control_addr_r <= (others => '0');
      bus_control_din_r  <= (others => '0');
      if valid_cmd_r = '1' then
        bus_control_en_r   <= bytes_r(0)(1);
        bus_control_wr_r   <= bytes_r(0)(0);
        bus_control_addr_r <= bytes_r(1) & bytes_r(2);
        bus_control_din_r  <= bytes_r(3) & bytes_r(4) & bytes_r(5) & bytes_r(6);
      end if;
    end if;
  end process;

  bus_en   <= bus_control_en_r  ;
  bus_wr   <= bus_control_wr_r  ;
  bus_addr <= bus_control_addr_r;
  bus_din  <= bus_control_din_r ;


end architecture;
