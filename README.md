# Simji softcore

Simji softcore is a simple 32-bits softcore written in VHDL.

Its instruction set is reduced and simple to understand: less than 20 instructions.

It features a _Harvard-style_ architecture, where instruction and data memories are physically separated in two block-rams on FPGA, allowing simultaneous access to both. It runs at 50Mhz on a Xilinx Artix-7 (Digilent Nexys A7 boards), but _do not_ depend on any proprietary library.

A  [companion project](https://github.com/JC-LL/simji) provides Simji ISS (instruction set simulator), that also allows to assemble and disassemble programs.

Today Simji has no C compiler, but I am not far from something usable (stay tuned !).

## Instruction set
The instruction set resembles MIPS-like ISA.

- r0 always contains 0.

- o and a can either be an immediate signed value or a register

| instruction   | description | note |
| ------------- | ----------- |------|
| add   r1,o,r2   | r2:=r1 + o   |      |
| sub   r1,o,r2   | r2:=r1 - o   |      |
| mul   r1,o,r2   | r2:=r1 * o   |      |
| div   r1,o,r2   | r2:=r1 / o   |      |
| or    r1,o,r2   | r2:=r1 \| o  |      |
| and   r1,o,r2   | r2:=r1 & o   |      |
| xor   r1,o,r2   | r2:=r1 ^ o   |      |
| shr   r1,o,r2   | r2:=r1 << o  |      |
| shl   r1,o,r2   | r2:=r1 >> o  |      |
| slt   r1,o,r2   | r2:=r1 < o   |      |
| sle   r1,o,r2   | r2:=r1 <= o  |      |
| seq   r1,o,r2   | r2:=r1 == o  |      |
| load  r1,o,r2   | r2:=M[r1+o]  |      |
| store r1,o,r2   | M[r1+o]:=r2  |      |
| jmp   o,r       | r=PC+1;PC=o  |      |
| braz  r,a       | PC=a if r==0 |      |
| branz r,a       | PC=a if r!=0 |      |
| scall n         | system call |      |
| stop            |             |      |

### Binary format
TBC

## System-on-chip Architecture and design
- The architecture of the system is depicted here. A component named Bus master allows a computer to interact with the system through USB/Serial. This component acts a master of a simple bus : this required to design a simple protocol. The UART we are relying on is borrowed from excellent Pr Pong Chu [books](https://academic.csuohio.edu/chu_p/rtl/index.html). Thanks to him !

- The core is not pipelined today and each instruction takes two cycles to complete : its performance is 25 Mips on Artix7 clocked at 100Mhz.

- The VHDL design style of the core is deliberately **not** structural : the core acts as a command/instruction interpreter, similar to the ISS, which is easier to understand for students. It underlines the power of RTL _inference_.

### Memory map
```vhdl
-- memory map description :
constant ADDR_REG_INFO     : std_logic_vector(15 downto 0) := x"0000";
constant ADDR_REG_DUMMY    : std_logic_vector(15 downto 0) := x"0001";
constant ADDR_CORE_CONTROL : std_logic_vector(15 downto 0) := x"0002";
constant ADDR_CORE_STATUS  : std_logic_vector(15 downto 0) := x"0003";

constant ADDR_BASE_CODE    : std_logic_vector(15 downto 0) := x"1000";
constant ADDR_LAST_CODE    : std_logic_vector(15 downto 0) := x"13ff";
constant ADDR_BASE_DATA    : std_logic_vector(15 downto 0) := x"2400";
constant ADDR_LAST_DATA    : std_logic_vector(15 downto 0) := x"27ff";
```
Note : Nothing in the REG_INFO so far.

**REG_CONTROL** : address **0x0002**
- bit 2 : start

**REG_STATUS** : address **0x0003**
- bit 0 : stopped

**RAM code** : addresses **0x1000...0x13ff*

**RAM data** : addresses **0x2400...0x27ff*


## How to synthesize ?

```bash
cd syn
vivado -mode tcl -source script.tcl
```

## How to program the FPGA ?

```bash
cd syn
djtgcfg -d NexysA7 prog -i 0 -f ../syn/SYNTH_OUTPUTS/top.bit
```

## How to interact with Simji softcore ?
A simple Ruby script is provided to show how to :
- read and write a program in Simji memories
- start the processor
- inspect its status

The Embedded software compute the square of 3x3 matrix and checks against the know result. This demonstrates a full observability of the system through the serial bus, from your laptop.

```bash
cd esw
ruby squared_matrix.rb
```

## Contact
Simji by itself is a support tool for Digital Design Courses at ENSTA Bretagne, Brest France.

Don't hesitate to drop me an email if you find this project interesting.

email : jean-christophe.le_lann at ensta-bretagne.fr
