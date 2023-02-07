library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simji_core is
  port(
    reset_n : in std_logic;
    clk     : in std_logic;
    go      : in std_logic;
    stopped : out std_logic;
    --
    instruction_en   : out std_logic;
    instruction_addr : out std_logic_vector(7 downto 0);
    instruction_data : in std_logic_vector(31 downto 0);
    --
    data_en          : out std_logic;
    data_wr          : out std_logic;
    data_addr        : out std_logic_vector(7 downto 0);
    data_in          : in std_logic_vector(31 downto 0);
    data_out         : out std_logic_vector(31 downto 0);
    leds             : out std_logic_vector(15 downto 0)
  );
end entity;

architecture rtl of simji_core is

  type state_t is (IDLE, FETCH,WAIT_INSTRUCTION,DECODE_EXEC,WAIT_DATA,FINALIZE_LOAD);
  signal state : state_t;

  type regs_type is array(0 to 31) of std_logic_vector(31 downto 0);
  signal reg : regs_type;
  signal pc  : unsigned(7 downto 0);
  signal ir  : std_logic_vector(31 downto 0);

  constant OP_STOP  : std_logic_vector(4 downto 0) := "00000";
  constant OP_ADD   : std_logic_vector(4 downto 0) := "00001";
  constant OP_SUB   : std_logic_vector(4 downto 0) := "00010";
  constant OP_MUL   : std_logic_vector(4 downto 0) := "00011";
  constant OP_DIV   : std_logic_vector(4 downto 0) := "00100";
  constant OP_AND   : std_logic_vector(4 downto 0) := "00101";
  constant OP_OR    : std_logic_vector(4 downto 0) := "00110";
  constant OP_XOR   : std_logic_vector(4 downto 0) := "00111";
  constant OP_SHL   : std_logic_vector(4 downto 0) := "01000";
  constant OP_SHR   : std_logic_vector(4 downto 0) := "01001";
  constant OP_SLT   : std_logic_vector(4 downto 0) := "01010";
  constant OP_SLE   : std_logic_vector(4 downto 0) := "01011";
  constant OP_SEQ   : std_logic_vector(4 downto 0) := "01100";
  constant OP_LOAD  : std_logic_vector(4 downto 0) := "01101";
  constant OP_STORE : std_logic_vector(4 downto 0) := "01110";
  constant OP_JMP   : std_logic_vector(4 downto 0) := "01111";
  constant OP_BRAZ  : std_logic_vector(4 downto 0) := "10000";
  constant OP_BRANZ : std_logic_vector(4 downto 0) := "10001";
  constant OP_SCALL : std_logic_vector(4 downto 0) := "10010";

begin

  non_pipelined_processor : process(reset_n,clk)
    variable opcode : std_logic_vector(4 downto 0);
    variable rs1,rs2,rd,jmp_reg : integer range 0 to 31;
    variable imm : signed(15 downto 0);
    variable flag : std_logic;
    variable jmp_imm_flag :  std_logic;
    variable jmp_addr :  unsigned(20 downto 0);
    variable addr : unsigned(21 downto 0);
    constant IMMEDIATE : std_logic := '1';
    -- synthesis off
    function opcode_to_string(code : std_logic_vector(4 downto 0)) return string is
      begin
        case code is
        when OP_STOP  => return "STOP ";
        when OP_ADD   => return "ADD  ";
        when OP_SUB   => return "SUB  ";
        when OP_MUL   => return "MUL  ";
        when OP_DIV   => return "DIV  ";
        when OP_AND   => return "AND  ";
        when OP_OR    => return "OR   ";
        when OP_XOR   => return "XOR  ";
        when OP_SHL   => return "SHL  ";
        when OP_SHR   => return "SHR  ";
        when OP_SLT   => return "SLT  ";
        when OP_SLE   => return "SLE  ";
        when OP_SEQ   => return "SEQ  ";
        when OP_LOAD  => return "LOAD ";
        when OP_STORE => return "STORE";
        when OP_JMP   => return "JMP  ";
        when OP_BRAZ  => return "BRAZ ";
        when OP_BRANZ => return "BRANZ";
        when OP_SCALL => return "SCALL";
        when others   => return "?????";
        end case;
      end function;
    -- synthesis on
  begin
    if reset_n='0' then
      state <= IDLE;
      for i in 0 to 31 loop
        reg(i) <= (others=>'0');
      end loop;
      ir    <= (others=>'0');
      pc    <= to_unsigned(0,8);
    elsif rising_edge(clk) then

      data_en <= '0';
      data_wr <= '0';

      case state is

      when IDLE =>
        if go='1' then
          state <= FETCH;
        end if;

      when FETCH =>
        state <= WAIT_INSTRUCTION; --1 cycle for BRAM to respond
        pc    <= pc+1;-- *next* address prepared

      when WAIT_INSTRUCTION =>
        ir    <= instruction_data;--instruction sampling from BRAM
        state <= DECODE_EXEC;

      when DECODE_EXEC =>
        opcode := ir(31 downto 27);
        rs1    := to_integer(unsigned(ir(26 downto 22)));
        rs2    := to_integer(unsigned(ir( 9 downto  5)));
        rd     := to_integer(unsigned(ir( 4 downto  0)));
        imm    := signed(ir(20 downto 5));
        flag   := ir(21);
        addr   := unsigned(ir(21 downto 0));
        jmp_imm_flag := ir(26);
        jmp_addr := unsigned(ir(25 downto  5));
        -- synthesis off
        report to_hstring(ir) & " executing a "     & opcode_to_string(opcode);
        -- synthesis on
        case opcode is
        when OP_ADD =>
          if flag=IMMEDIATE then
            reg(rd) <= std_logic_vector(signed(reg(rs1)) + resize(imm,32));
          else
            reg(rd) <= std_logic_vector(signed(reg(rs1)) + signed(reg(rs2)));
          end if;
          state <= FETCH;
        when OP_SUB =>
          if flag=IMMEDIATE then
            reg(rd) <= std_logic_vector(signed(reg(rs1)) - resize(imm,32));
          else
            reg(rd) <= std_logic_vector(signed(reg(rs1)) - signed(reg(rs2)));
          end if;
          state <= FETCH;
        when OP_MUL =>
          if flag=IMMEDIATE then
            reg(rd) <= std_logic_vector(resize(signed(reg(rs1)) * resize(imm,32),32));
          else
            reg(rd) <= std_logic_vector(resize(signed(reg(rs1)) * signed(reg(rs2)),32));
          end if;
          state <= FETCH;
        when OP_DIV =>
          if flag=IMMEDIATE then
            reg(rd) <= std_logic_vector(resize(signed(reg(rs1)) / resize(imm,32),32));
          else
            reg(rd) <= std_logic_vector(resize(signed(reg(rs1)) / signed(reg(rs2)),32));
          end if;
          state <= FETCH;
        when OP_AND =>
          if flag=IMMEDIATE then
            reg(rd) <= reg(rs1) and (x"0000" & std_logic_vector(imm));
          else
            reg(rd) <= reg(rs1) and reg(rs2);
          end if;
          state <= FETCH;
        when OP_OR =>
          if flag=IMMEDIATE then
            reg(rd) <= reg(rs1) or (x"0000" & std_logic_vector(imm));
          else
            reg(rd) <= reg(rs1) or reg(rs2);
          end if;
          state <= FETCH;
        when OP_XOR =>
          if flag=IMMEDIATE then
            reg(rd) <= reg(rs1) xor (x"0000" & std_logic_vector(imm));
          else
            reg(rd) <= reg(rs1) xor reg(rs2);
          end if;
          state <= FETCH;
        when OP_SHL =>
          if flag=IMMEDIATE then
            reg(rd) <= std_logic_vector(shift_left(signed(reg(rs1)),to_integer(unsigned(imm))));
          else
            reg(rd) <= std_logic_vector(shift_left(signed(reg(rs1)),to_integer(unsigned(reg(rs2)))));
          end if;
          state <= FETCH;
        when OP_SHR =>
          if flag=IMMEDIATE then
            reg(rd) <= std_logic_vector(shift_right(signed(reg(rs1)),to_integer(unsigned(imm))));
          else
            reg(rd) <= std_logic_vector(shift_right(signed(reg(rs1)),to_integer(unsigned(reg(rs2)))));
          end if;
          state <= FETCH;
        when OP_SLT =>
          reg(rd) <= x"00000000";
          if flag=IMMEDIATE then
            if resize(signed(reg(rs1)),16) < imm then
              reg(rd) <= x"00000001";
            end if;
          else
            if signed(reg(rs1)) < signed(reg(rs2)) then
              reg(rd) <= x"00000001";
            end if;
          end if;
          state <= FETCH;
        when OP_SLE =>
          reg(rd) <= x"00000000";
          if flag=IMMEDIATE then
            if resize(signed(reg(rs1)),16) <= imm then
              reg(rd) <= x"00000001";
            end if;
          else
            if signed(reg(rs1)) <= signed(reg(rs2)) then
              reg(rd) <= x"00000001";
            end if;
          end if;
          state <= FETCH;
        when OP_SEQ =>
          reg(rd) <= x"00000000";
          if flag=IMMEDIATE then
            if signed(reg(rs1)) = resize(imm,32) then
              reg(rd) <= x"00000001";
            end if;
          else
            if reg(rs1) = reg(rs2) then
              reg(rd) <= x"00000001";
            end if;
          end if;
          state <= FETCH;
        when OP_LOAD =>
          data_en <= '1';
          if flag=IMMEDIATE then
            data_addr <= std_logic_vector(resize(signed(reg(rs1)) + resize(imm,32),8));
          else
            data_addr <= std_logic_vector(resize(signed(reg(rs1)) + signed(reg(rs2)),8));
          end if;
          state <= WAIT_DATA;
        when OP_STORE =>
          data_en <= '1';
          data_wr <= '1';
          if flag=IMMEDIATE then
            data_addr <= std_logic_vector(resize(signed(reg(rs1)) + resize(imm,32),8));
          else
            data_addr <= std_logic_vector(resize(signed(reg(rs1)) + signed(reg(rs2)),8));
          end if;
          data_out <= reg(rd); --wrong naming
          state <= FETCH;--store should have finished
        when OP_JMP =>
          if jmp_imm_flag='1' then
            pc <= resize(jmp_addr,8);
          else
            jmp_reg := to_integer(unsigned(ir(9 downto 5)));
            pc <= resize(unsigned(reg(jmp_reg)),8);
          end if;
          reg(rd) <= std_logic_vector(resize(pc,32));--a verifier
          state <= FETCH;
        when OP_BRAZ =>
          if reg(rs1)=x"00000000" then
            pc <= resize(addr,8);
          end if;
          state <= FETCH;
        when OP_BRANZ =>
          if reg(rs1)/=x"00000000" then
            pc <= resize(addr,8);
          end if;
          state <= FETCH;
        when OP_SCALL =>
          state <= FETCH;
        when OP_STOP =>
          report "====STOP====" severity failure;
          state <= IDLE;
        when others =>
          null;
        end case;
      when WAIT_DATA =>
        state <= FINALIZE_LOAD;
      when FINALIZE_LOAD =>
        reg(rd) <= data_in;
        state <= FETCH;
      when others =>
        null;
      end case;
    end if;
  end process;

  instruction_en <= '1' when state= FETCH else '0';
  instruction_addr <= std_logic_vector(pc);
  stopped <= '1' when ir=x"00000000" else '0';
  leds <= reg(2)(15 downto 0);
end rtl;
