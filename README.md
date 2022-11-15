# RISC-V OISC Macros

Master Thesis at the Institute for Complex Systems @JKU Linz ([ICS](https://www.ics.jku.at/), [GitHub](https://github.com/ics-jku)).

This work researches whether there are redundancies in the RISC-V RV32I ISA, and eliminate them by replacing as many instructions as possible (with some exceptions like e.g. load/store) with sequences of three RISC-V base instructions: sub, blt and beq.
The goal is that the execution of the replaced instructions (macros) results in the same architectural state (register values) as the execution of the original instructions.

This repository contains the new instruction macros, which are the first part of the thesis.
The second part of the Thesis was to formally verify their correctness in [Rosette](https://github.com/SonjaGurtner/riscv-oisc-verifier) which proves the equivalence of the RISC-V instructions and the new instructions with a SMT Solver.

The script macros-replace.sh can be used to replace the RISC-V instruction names in an existing assembly file with the new macro names (addi x3, x0, 3 -> MYADDI x3. x0. 3). The second script macros-copy.sh can then copy the macro definitions into the file with the replaced instructions. The order is relevant, as the instrucion names have to be replaced first, otherwise the script would also overwrite instructions inside of the macro definitions.
