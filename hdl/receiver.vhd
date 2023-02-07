library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity receiver is
  port (
    reset_n    : in  std_logic;
    clk100     : in  std_logic;
    tick       : in  std_logic;
    rx         : in  std_logic;
    byte       : out std_logic_vector(7 downto 0);
    byte_valid : out std_logic
    );
end entity;

architecture RTL of receiver is

  constant STOP_BITS_TICKS : natural := 16;

  type state_t is (IDLE, SAMPLE_START_BIT, SAMPLE_DATA_BITS, SAMPLE_STOP_BIT);
  signal state_c, state_r : state_t;

  signal count_c, count_r           : integer range 0 to 15;
  signal idx_c, idx_r               : integer range 0 to 7;
  signal byte_c, byte_r             : std_logic_vector(7 downto 0);
  signal byte_valid_c, byte_valid_r : std_logic;
begin

  registers : process(reset_n, clk100)
  begin
    if reset_n = '0' then
      state_r      <= IDLE;
      count_r      <= 0;
      byte_r       <= "00000000";
      idx_r        <= 0;
      byte_valid_r <= '0';
    elsif rising_edge(clk100) then
      state_r      <= state_c;
      count_r      <= count_c;
      idx_r        <= idx_c;
      byte_r       <= byte_c;
      byte_valid_r <= byte_valid_c;
    end if;
  end process;

  next_state_func : process(byte_r, count_r, idx_r, rx, state_r, tick)
  begin
    --default assignments
    state_c      <= state_r;
    count_c      <= count_r;
    idx_c        <= idx_r;
    byte_c       <= byte_r;
    byte_valid_c <= '0';
    --
    case state_r is
      when IDLE =>
        byte_c       <= "00000000";
        byte_valid_c <= '0';
        if rx = '0' then
          state_c <= SAMPLE_START_BIT;
        end if;
      when SAMPLE_START_BIT =>
        if tick = '1' then
          if count_r = 7 then
            count_c <= 0;
            state_c <= SAMPLE_DATA_BITS;
          else
            count_c <= count_r + 1;
          end if;
        end if;
      when SAMPLE_DATA_BITS =>
        if tick = '1' then
          if count_r = 15 then
            -- sampling
            byte_c <= rx & byte_r(7 downto 1);
            count_c <= 0;
            if idx_r = 7 then
              idx_c   <= 0;
              state_c <= SAMPLE_STOP_BIT;
            else
              idx_c <= idx_r + 1;
            end if;
          else
            count_c <= count_r + 1;
          end if;
        end if;
      when SAMPLE_STOP_BIT =>
        if tick = '1' then
          if count_r = STOP_BITS_TICKS-1 then
            count_c      <= 0;
            byte_valid_c <= '1';
            state_c      <= IDLE;
          else
            count_c <= count_r + 1;
          end if;
        end if;
      when others =>
        null;
    end case;
  end process;

  byte       <= byte_r;
  byte_valid <= byte_valid_r;

end architecture;
