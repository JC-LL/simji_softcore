--------------------------------------------------------------------------------
-- this file was generated automatically by Vertigo Ruby utility
-- date : (d/m/y h:m) 12/01/2021 13:33
-- author : Jean-Christophe Le Lann - 2014
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simji_core_tb is
end entity;

architecture bhv of simji_core_tb is

  constant nbits_inst_addr : natural := 10;
  constant nbits_data_addr : natural := 10;

  constant HALF_PERIOD : time :=5 ns;

  signal clk : std_logic := '0';
  signal reset_n : std_logic := '0';

  signal running : boolean := true;

  procedure wait_cycles(n : natural) is
  begin
    for i in 0 to n loop
      wait until rising_edge(clk);
    end loop;
  end procedure;

  signal go            : std_logic;
  signal stopped       : std_logic;
  signal instr_en      : std_logic;
  signal instr_wr      : std_logic;
  signal instr_addr    : std_logic_vector(nbits_inst_addr - 1 downto 0);
  signal instr         : std_logic_vector(31 downto 0);
  signal data_en       : std_logic;
  signal data_wr       : std_logic;
  signal data_addr     : std_logic_vector(nbits_inst_addr - 1 downto 0);
  -- STEP 2 : notice :
  signal data_to_core  : std_logic_vector(31 downto 0);
  signal core_to_data  : std_logic_vector(31 downto 0);
  --

  subtype instruction_t is std_logic_vector(31 downto 0);

  type program_t is array(0 to 1023) of instruction_t;

  -- chenillard
  signal program : program_t;

  subtype data_t is std_logic_vector(31 downto 0);

  type datamem_t is array(0 to 1023) of data_t;

  signal data_mem : datamem_t := (others=> x"00000000");

  signal out_of_instr_memory_bounds,out_of_data_memory_bounds : boolean := false;
  signal end_of_stim_process : boolean := false;
begin
  --------------------------------------------------------------------------------
  -- clock and reset
  --------------------------------------------------------------------------------
  reset_n <= '0','1' after 123 ns;

  clk <= not(clk) after HALF_PERIOD when running else clk;

  running <= not(out_of_instr_memory_bounds or out_of_data_memory_bounds or end_of_stim_process);
  --------------------------------------------------------------------------------
  -- Design Under Test
  --------------------------------------------------------------------------------

  --------------------------------------------------------------------------------
  -- sequential stimuli
  --------------------------------------------------------------------------------
  stim : process
    file F : text;
    variable L: line;
    variable status : file_open_status;
    variable data : integer;
    variable nb_samples : natural := 0;
  begin
    report "running testbench for simji_core(step_1)";
    go <='0';
    report "waiting for asynchronous reset";
    wait until reset_n='1';
    FILE_OPEN(status,F,"program.bin",read_mode);
    if status/=open_ok then
      report "problem to open stimulus file program.bin" severity error;
    else
      report "loading program...";
      while not(ENDFILE(f)) loop
        nb_line:=nb_line+1;
        wait until rising_edge(clk);
        readline(F,l);
        read(l,data);
        address <= to_signed(data,sample_width);
        data <= '1';
      end loop;
      sample_valid <= '0';
      report "end of simulation";
      report integer'image(nb_samples) & " samples processed.";
    end if;
    report "end of simulation";
    end_of_stim_process <= true;
    wait;
  end process;
end bhv;
