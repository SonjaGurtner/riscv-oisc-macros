1) Build this RISC-V (Tiny RV32I) ISA Simulator:
------------------------------------------------

In *isa* folder (requires the *boost* C++ library):
 
```bash
mkdir build
cd build
cmake ..
make
```


2) Compile and run some Software:
---------------------------------

In *sw*:

```bash
cd basic-c                                # can be replaced with different example
make                                      # (requires RISC-V GNU toolchain in PATH)
../../isa/build/lib/riscv-tiny-isa main   # shows final simulation time as well as register and pc contents
```

Add the *riscv-tiny-isa* executable to PATH to simplify execution of SW examples.
