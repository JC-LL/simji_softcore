# Simji softcore

Simji softcore is a simple 32-bits softcore written in VHDL.

Its instruction set is reduced and simple to understand: less than 20 instructions.

It features a _Harvard-style_ architecture, where instruction and data memories are physically separated in two block-rams on FPGA, allowing simultaneous access to both. It runs at 50Mhz on a Xilinx Artix-7 (Digilent Nexys A7 boards), but _do not_ depend on any proprietary library.

A companion project allows to play with Simji ISS (instruction set simulator), that also allows to assemble and disassemble programs.

Today Simji has no C compiler, but I am not far from something usable (stay tuned !).

## Instruction set
TBC

## System-on-chip Architecture and design
- The architecture of the system is depicted here. A component named Bus master allows a computer to interact with the system through USB/Serial. This component acts a master of a simple bus : this required to design a simple protocol. The UART we are relying on is borrowed from excellent Pr Pong Chu books. Thanks to him !

- The core is not pipelined today and each instruction takes two cycles to complete : its performance is 25M instructions per seconds.

- The VHDL design style of the core is deliberately **not** structural : the core acts as a command/instruction interpreter, similar to the ISS, which is easier to understand for students.

### Memory map
TBC

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
