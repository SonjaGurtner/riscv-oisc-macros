git clone https://github.com/agra-uni-bremen/riscv-vp.git
cd riscv-vp
git submodule update --init vp/src/core/common/gdb-mc/libgdb/mpc
cd vp/dependencies
./build_systemc_233.sh
./build_softfloat.sh

cd ..
mkdir build
cd build
cmake ..
make install
cd ../../..

export PATH=$PATH:/workspaces/riscv-oisc-macros/riscv-container/riscv-vp/vp/build/bin

echo "PATH=$PATH:/workspaces/riscv-oisc-macros/riscv-container/riscv-vp/vp/build/bin" >> ~/.bashrc
