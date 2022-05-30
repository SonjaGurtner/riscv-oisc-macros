# RISC-V OISC Macros

Master Thesis at the Institute of Complex Systems @JKU Linz [ICS](https://www.ics.jku.at/).

This work takes the RISC-V RV32I Base Integer Instructions and replaces every instruction (with some exceptions like e.g. load/store) with just three RISC-V instructions: sub, blt and beq. Therefore it follows the principle of the OISC instruction SUBLEQ.
The goal is that if an existing program gets replaced with the new instructions, executing both results in the same architectural states (i.e. the same register values).

This repository contains the new instruction macros, which were first fuzzed with a small handwritten [Fuzzer](https://github.com/SonjaGurtner/riscv-oisc-fuzzer) in Java.
The second part of the Thesis was to formally verify their correctness by writing an Interpretor in [Rosette](https://github.com/SonjaGurtner/riscv-oisc-verifier) which proves the equivalence of the RISC-V instructions and the new instructions (i.e. the architectural state of register values and the stack after executing two programs) with a SMT Solver.

The script macros-replace.sh can be used to replace the RISC-V instruction names in an existing assembly file with the new macro names (addi x3, x0, 3 -> MYADDI x3. x0. 3). The second script macros-copy.sh can then copy the macro definitions into the file with the replaced instructions.
