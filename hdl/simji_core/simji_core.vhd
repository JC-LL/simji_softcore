------------------------------------------------------------------------------------------------------------
-- SIMJI softcore is copyright (c) 2015-2020 Jean-Christophe Le Lann.
--
-- This program is free software; you can redistribute it and/or modify it under the terms of
-- the GNU General Public License as published by the Free Software Foundation; either version 2 of the License,
-- or (at your option) any later version.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simji_core is
  generic (
    nbits_inst_addr : natural := 10;
    nbits_data_addr : natural := 10
  );
  port (
    reset_n         : in  std_logic;
    clk             : in  std_logic;
    go              : in  std_logic;
    stopped         : out std_logic;
    --
    instr_en        : out std_logic;
    instr_wr        : out std_logic;
    instr_addr      : out std_logic_vector(nbits_inst_addr-1 downto 0);
    instr_in        : in  std_logic_vector(31 downto 0);
    --
    data_en        : out std_logic;
    data_wr        : out std_logic;
    data_addr      : out std_logic_vector(nbits_inst_addr-1 downto 0);
    data_in        : in  std_logic_vector(31 downto 0);
    data_out       : out std_logic_vector(31 downto 0)
  );
end entity;

architecture rtl of simji_core is

  type regs_t is array(0 to 31) of std_logic_vector(31 downto 0);
  signal regs_r,regs_c : regs_t;
  signal stopped_r,stopped_c : std_logic;

  signal pc_r, pc_c : unsigned(nbits_inst_addr-1 downto 0);

  -- STEP 2 : add a new state FINALIZE_LOAD
  type state_t is (IDLE,FETCH,DECODE_EXEC,FINALIZE_LOAD);
  signal state_r,state_c : state_t;

  --STEP 2 :
  signal beta_r,beta_c : integer range 0 to 31;
begin

  full_state: process(reset_n,clk)
  begin
    if reset_n='0' then
      for i in 0 to 31 loop
        regs_r(i) <= (others=> '0');
      end loop;
      stopped_r <= '0';
      pc_r    <= to_unsigned(0,nbits_inst_addr);
      state_r <= idle;
      beta_r  <= 0;
    elsif rising_edge(clk) then
      regs_r     <= regs_c; -- 32 registers updated!
      stopped_r  <= stopped_c;
      state_r    <= state_c;
      pc_r       <= pc_c;
      -- STEP 2 : keep beta (optional ; depends on instr mem implementation)
      beta_r     <= beta_c;
    end if;
  end process;

  stopped <= stopped_r;

  fsm_process: process(beta_r, data_in, go, instr_in, pc_r, regs_r, state_r,
                       stopped_r)
    constant OP_STOP       : std_logic_vector(4 downto 0) := "00000";
    constant OP_ADD        : std_logic_vector(4 downto 0) := "00001";
    constant OP_SUB        : std_logic_vector(4 downto 0) := "00010";
    constant OP_MUL        : std_logic_vector(4 downto 0) := "00011";
    constant OP_DIV        : std_logic_vector(4 downto 0) := "00100";
    constant OP_AND        : std_logic_vector(4 downto 0) := "00101";
    constant OP_OR         : std_logic_vector(4 downto 0) := "00110";
    constant OP_XOR        : std_logic_vector(4 downto 0) := "00111";
    constant OP_SHL        : std_logic_vector(4 downto 0) := "01000";
    constant OP_SHR        : std_logic_vector(4 downto 0) := "01001";
    constant OP_SLT        : std_logic_vector(4 downto 0) := "01010";
    constant OP_SLE        : std_logic_vector(4 downto 0) := "01011";
    constant OP_SEQ        : std_logic_vector(4 downto 0) := "01100";
    constant OP_LOAD       : std_logic_vector(4 downto 0) := "01101";
    constant OP_STORE      : std_logic_vector(4 downto 0) := "01110";
    constant OP_JMP        : std_logic_vector(4 downto 0) := "01111";
    constant OP_BRAZ       : std_logic_vector(4 downto 0) := "10000";
    constant OP_BRANZ      : std_logic_vector(4 downto 0) := "10001";
    constant OP_SCALL      : std_logic_vector(4 downto 0) := "10010";

    variable codeop        : std_logic_vector(4 downto 0);
    variable alpha         : integer range 0 to 31;
    variable beta          : integer range 0 to 31;
    variable imm_o         : signed(15 downto 0);
    variable reg_o         : integer range 0 to 31;
    variable o             : std_logic_vector(31 downto 0);
    variable immo_flag     : std_logic;
    variable immo_jmp_flag : std_logic;
    variable immo_jmp      : unsigned(20 downto 0);--21 bits
    variable addr_jmp      : unsigned(nbits_inst_addr-1 downto 0);
    variable braz_a        : unsigned(21 downto 0);--22 bits
    --
    variable regs_v  : regs_t;
    variable stopped_v  : std_logic;
    variable go_v    : std_logic;
    variable instr_v : std_logic_vector(31 downto 0);
    variable state_v  : state_t;
    -- STEP 1
    variable instr_en_v   : std_logic;
    variable instr_wr_v   : std_logic;
    variable instr_addr_v : unsigned(nbits_inst_addr-1 downto 0);
    -- STEP 2
    variable data_en_v   : std_logic;
    variable data_wr_v   : std_logic;
    variable data_addr_v : unsigned(nbits_data_addr-1 downto 0);
    variable data_out_v  : std_logic_vector(31 downto 0);
    --
    variable pc_v         : unsigned(nbits_inst_addr-1 downto 0);
    -- synthesis off
    variable instr_count : integer := 0;
    variable cycle_count : integer := 0;

    -- synthesis on
  begin
    -- lets work with variables internally !
    go_v       := go;
    instr_v    := instr_in;
    regs_v     := regs_r;
    pc_v       := pc_r;
    stopped_v  := stopped_r;
    state_v    := state_r;
    beta       := beta_r;-- needed to finalize LOAD

    -- STEP 1 :
    instr_en_v := '0';
    instr_wr_v := '0';
    instr_addr_v := pc_r;
    -- STEP 2 :
    data_en_v   := '0';
    data_wr_v   := '0';
    data_addr_v := pc_r;
    data_out_v  := (others=>'0');

    -- default value for bitfields :
    codeop        := "00000";
    immo_flag     := '0';
    imm_o         := (others=>'0');
    reg_o         := 0;
    immo_jmp_flag := '0';
    immo_jmp      := to_unsigned(0,21);
    addr_jmp      := (others=>'0');
    braz_a        := to_unsigned(0,22);
    alpha         := 0;

    case state_v is
      when IDLE =>
        if go_v='1' then
          state_v := FETCH;
        end if;
      when FETCH =>
        instr_en_v   := '1';
        instr_wr_v   := '0';--read
        instr_addr_v := pc_v;-- <<<
        pc_v         := pc_v+1;--increment PC
        state_v      := DECODE_EXEC;
        -- synthesis off
        instr_count := instr_count+1;
        cycle_count := cycle_count+1;
        -- synthesis on
      when DECODE_EXEC =>
        -- synthesis off
        cycle_count := cycle_count+1;
        -- synthesis on
        -- decode bitfields :
        codeop        :=                     instr_v(31 downto 27);
        alpha         := to_integer(unsigned(instr_v(26 downto 22)));
        beta          := to_integer(unsigned(instr_v( 4 downto  0)));
        immo_flag     :=                     instr_v(21);
        imm_o         :=              signed(instr_v(20 downto 5));
        reg_o         := to_integer(unsigned(instr_v(9 downto  5)));
        immo_jmp_flag :=                     instr_v(26);
        immo_jmp      :=            unsigned(instr_v(25 downto 5));--21 bits
        braz_a        :=            unsigned(instr_v(21 downto 0));--22 bits
        if immo_flag='1' then
          o := std_logic_vector(resize(imm_o,32));
        else
          o := regs_v(reg_o);
        end if;
        if immo_jmp_flag='1' then
          addr_jmp := resize(immo_jmp,nbits_inst_addr);
        else
          addr_jmp := resize(unsigned(regs_v(reg_o)),nbits_inst_addr);
        end if;
        -- non pipelined :
        state_v := FETCH;
        case codeop is
          when OP_ADD  =>
            report "ADD R" & integer'image(alpha) & " o R" & integer'image(beta) ;
            regs_v(beta) := std_logic_vector(signed(regs_v(alpha)) + signed(o));
          when OP_SUB  =>
            report "SUB";
            regs_v(beta) := std_logic_vector(signed(regs_v(alpha)) - signed(o));
          when OP_MUL  =>
            report "MUL";
            regs_v(beta) := std_logic_vector(resize(signed(regs_v(alpha)) * signed(o),32));
          when OP_DIV  =>
            report "DIV";
            if o/=x"00000000" then
              regs_v(beta) := std_logic_vector(resize(signed(regs_v(alpha)) / signed(o),32));
            end if;
          when OP_AND  =>
            report "AND";
            regs_v(beta) := regs_v(alpha) and o;
          when OP_OR  =>
            report "OR";
            regs_v(beta) := regs_v(alpha)  or o;
          when OP_XOR  =>
            report "XOR";
            regs_v(beta) := regs_v(alpha) xor o;
          when OP_SHL  =>
            report "SHL";
            regs_v(beta) := std_logic_vector(shift_left(signed(regs_v(alpha)),to_integer(unsigned(o))));
          when OP_SHR  =>
            report "SHR";
            regs_v(beta) := std_logic_vector(shift_right(signed(regs_v(alpha)),to_integer(unsigned(o))));
          when OP_SLT  =>
            report "SLT";
            if signed(regs_v(alpha)) < signed(o) then
              regs_v(beta) := x"00000001";
            else
              regs_v(beta) := x"00000000";
            end if;
          when OP_SLE  =>
            report "SLE";
            if signed(regs_v(alpha)) <= signed(o) then
              regs_v(beta) := x"00000001";
            else
              regs_v(beta) := x"00000000";
            end if;
          when OP_SEQ  =>
            report "SEQ";
            if regs_v(alpha)=o then
              regs_v(beta) := x"00000001";
            else
              regs_v(beta) := x"00000000";
            end if;
          when OP_LOAD  =>
            data_en_v   := '1';
            data_wr_v   := '0';--read
            data_addr_v := resize(unsigned(signed(regs_v(alpha)) + signed(o)),nbits_data_addr);-- warn : choice done for signed.
            state_v := FINALIZE_LOAD;-- !!!!
          when OP_STORE =>
            data_en_v   := '1';
            data_wr_v   := '1';--write
            data_addr_v := resize(unsigned(signed(regs_v(alpha)) + signed(o)),nbits_data_addr);-- warn : choice done for signed.
            data_out_v  := regs_v(beta);
          -- ==================================
          when OP_JMP   =>
            report "JMP";
            regs_v(beta) := std_logic_vector(resize(pc_v,32));-- store next PC @
            pc_v := addr_jmp;
          when OP_BRAZ  =>
            report "BRAZ";
            if regs_v(alpha)=x"00000000" then
              pc_v := resize(braz_a,nbits_inst_addr);
            end if;
          when OP_BRANZ =>
            report "BRANZ";
            if regs_v(alpha)/=x"00000000" then
              pc_v := resize(braz_a,nbits_inst_addr);
            end if;
          when OP_SCALL =>
            report "SCALL";
            null; --NIY
          when OP_STOP =>
            --synthesis off
            report "STOP";
            report "# instructions executed : " & integer'image(instr_count);
            report "# cycles                : " & integer'image(cycle_count);
            -- synthesis on
            stopped_v  := '1';
            state_v := IDLE;
          when others =>
            report "ERROR in DECODE";
            null;
        end case;
      when FINALIZE_LOAD =>
        regs_v(beta) := data_in;
        state_v := FETCH;
      when others =>
        null;
    end case;

    -- don't forget to force R0 to be 0, whichever operation on it :
    regs_v(0) := (others =>'0');
    -- =============== final var to sign assignements/update =================
    -- final update of combinatorial signals
    regs_c     <= regs_v;
    stopped_c  <= stopped_v;
    pc_c       <= pc_v;
    state_c    <= state_v;
    -- STEP 2 :
    beta_c  <= beta;
    -- instr
    instr_en   <= instr_en_v;
    instr_wr   <= instr_wr_v;
    instr_addr <= std_logic_vector(instr_addr_v);
    -- data
    data_en   <= data_en_v;
    data_wr   <= data_wr_v;
    data_addr <= std_logic_vector(data_addr_v);
    data_out  <= data_out_v;
  end process;

end architecture;
