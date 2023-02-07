library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ip_lib;

entity fifo is
  generic (
    NB_BITS_DATA : natural := 8;
    FIFO_SIZE    : natural := 16
    );
  port (
    reset_n     : in  std_logic;
    clk         : in  std_logic;
    sreset      : in  std_logic;
    push        : in  std_logic;
    pop         : in  std_logic;
    data_i      : in  std_logic_vector(NB_BITS_DATA-1 downto 0);
    data_o      : out std_logic_vector(NB_BITS_DATA-1 downto 0);
    full        : out std_logic;
    almost_full : out std_logic;
    empty       : out std_logic;
    almost_empty: out std_logic
    );
end entity;

architecture rtl of fifo is
  type regs_type is array(0 to FIFO_SIZE-1) of std_logic_vector(NB_BITS_DATA-1 downto 0);
  signal nb_data_c, nb_data_r : integer range 0 to FIFO_SIZE;
  signal regs_c, regs_r       : regs_type;
  signal empty_c, empty_r     : std_logic;
  signal full_c, full_r       : std_logic;
begin

  regs_p : process(reset_n, clk)
  begin
    if reset_n = '0' then
      regs_r    <= (others => (others => '0'));
      nb_data_r <= 0;
      empty_r   <= '1';
      full_r    <= '0';
    elsif rising_edge(clk) then
      if sreset = '1' then
        regs_r    <= (others => (others => '0'));
        nb_data_r <= 0;
        empty_r   <= '1';
        full_r    <= '0';
      else
        nb_data_r <= nb_data_c;
        regs_r    <= regs_c;
        empty_r   <= empty_c;
        full_r    <= full_c;
      end if;
    end if;
  end process;

  update_p : process(data_i, empty_r, full_r, nb_data_r, pop, push, regs_r)
    variable cmd             : std_logic_vector(1 downto 0);
    variable empty_v, full_v : std_logic;
    variable nb_data_v       : integer range 0 to FIFO_SIZE;
    variable regs_v          : regs_type;
  begin
    regs_v    := regs_r;
    nb_data_v := nb_data_r;
    full_v    := full_r;
    empty_v   := empty_r;

    cmd := push & pop;
    case cmd is
      when "10" =>                      -- push
        if nb_data_v /= FIFO_SIZE then
          regs_v(nb_data_v) := data_i;
          nb_data_v         := nb_data_v + 1;
        end if;
      when "01" =>                      -- pop
        if nb_data_v /= 0 then
          --shift downwards
          for i in 1 to FIFO_SIZE-1 loop
            regs_v(i-1) := regs_v(i);
          end loop;
          nb_data_v := nb_data_v-1;
        end if;
      when "11" =>                      -- push pop
        regs_v(nb_data_v) := data_i;
        for i in 1 to fifo_size-1 loop
          regs_v(i-1) := regs_v(i);
        end loop;
      when others =>
        null;
    end case;

    if nb_data_v = fifo_size then
      full_v := '1';
    else
      full_v := '0';
    end if;

    if nb_data_v = 0 then
      empty_v := '1';
    else
      empty_v := '0';
    end if;

    -- final signals update
    empty_c   <= empty_v;
    regs_c    <= regs_v;
    nb_data_c <= nb_data_v;
    full_c    <= full_v;
    empty_c   <= empty_v;
  end process;

  data_o      <= regs_r(0);
  empty       <= empty_r;
  full        <= full_r;
  almost_full <= '1' when nb_data_r >= fifo_size-1 else '0';
  almost_empty <= '1' when nb_data_r < 2 else '0';
end architecture;
