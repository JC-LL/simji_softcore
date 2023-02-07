library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sender is
  port (
    reset_n    : in  std_logic;
    clk100     : in  std_logic;
    tick       : in  std_logic;
    send_start : in  std_logic;
    send_done  : out std_logic;
    byte       : in  std_logic_vector(7 downto 0);
    tx         : out std_logic
    );
end entity;

architecture RTL of sender is

  type state_t is (IDLE, SEND_START_BIT, SEND_DATA_BITS, SEND_STOP_BIT, WAIT_STATE);
  signal state_c, state_r         : state_t;
  signal count_c, count_r         : integer range 0 to 15;
  signal idx_c, idx_r             : integer range 0 to 7;
  signal byte_c, byte_r           : std_logic_vector(7 downto 0);
  signal tx_c, tx_r               : std_logic;
  signal send_done_c, send_done_r : std_logic;
begin

  registers : process(reset_n, clk100)
  begin
    if reset_n = '0' then
      state_r     <= IDLE;
      count_r     <= 0;
      byte_r      <= "00000000";
      idx_r       <= 0;
      tx_r        <= '1';
      send_done_r <= '0';
    elsif rising_edge(clk100) then
      state_r     <= state_c;
      count_r     <= count_c;
      byte_r      <= byte_c;
      idx_r       <= idx_c;
      tx_r        <= tx_c;
      send_done_r <= send_done_c;
    end if;
  end process;

  next_state_func : process(byte, byte_r, count_r, idx_r, send_start, state_r,
                            tick, tx_r)
  begin
    --default assignments
    state_c     <= state_r;
    count_c     <= count_r;
    idx_c       <= idx_r;
    byte_c      <= byte_r;
    send_done_c <= '0';
    tx_c        <= tx_r;
    --
    case state_r is
      when IDLE =>
        tx_c <= '1';
        if send_start = '1' then
          state_c <= SEND_START_BIT;
          byte_c  <= byte;
        end if;
      when SEND_START_BIT =>
        tx_c <= '0';
        if tick = '1' then
          if count_r = 15 then
            count_c <= 0;
            state_c <= SEND_DATA_BITS;
          else
            count_c <= count_r + 1;
          end if;
        end if;
      when SEND_DATA_BITS =>
        tx_c <= byte_r(0);              -- LSB first
        if tick = '1' then
          if count_r = 15 then
            count_c <= 0;
            byte_c  <= '0' & byte_r(7 downto 1);
            if idx_r = 8-1 then
              state_c <= SEND_STOP_BIT;
              idx_c   <= 0;
            else
              idx_c <= idx_r + 1;       --count bits
            end if;
          else
            count_c <= count_r + 1;     --count ticks
          end if;
        end if;
      when SEND_STOP_BIT =>
        tx_c <= '1';
        if tick = '1' then
          if count_r = 15 then
            count_c     <= 0;
            state_c     <= WAIT_STATE;
            send_done_c <= '1';
          else
            count_c <= count_r + 1;
          end if;
        end if;
      when WAIT_STATE =>
        --needed to make the FIFO update according to send_done_c
        state_c <= IDLE;
      when others =>
        null;
    end case;
  end process;

  tx        <= tx_r;
  send_done <= send_done_r;
end architecture;
