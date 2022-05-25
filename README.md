# RISCV-OISC

Master Thesis at the Institute of Complex Systems @JKU Linz [ICS](https://www.jku.at/institut-fuer-complex-systems/).

This work takes the RISC-V RV32I Base Integer Instructions and replaces every instruction (with some exceptions like e.g. load/store) with just three RISC-V instructions: sub, blt and beq. Therefore it follows the principle of the OISC instruction SUBLEQ.
The goal is that if an existing program gets replaced with the new instructions, executing both results in the same architectural states (i.e. the same register values).

This repository contains the new instruction macros, which were first fuzzed with a small handwritten [Fuzzer](https://github.com/SonjaGurtner/riscv-oisc-fuzzer) in Java.
The second part of the Thesis was to formally verify their correctness by writing an Interpretor in [Rosette](https://github.com/SonjaGurtner/RISCV-OISC-Rosette) which proves the equivalence of the RISC-V instructions and the new instructions (i.e. the architectural state of register values and the stack after executing two programs) with a SMT Solver.
