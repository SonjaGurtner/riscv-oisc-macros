FROM ubuntu

LABEL description="Container for SystemC RISC-V VP"

ENV TZ=Europe/Vienna
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN useradd -s /bin/bash -d /home/jku/ -m -G sudo jku

# install c++ and systemc
RUN apt-get update && apt-get install -y build-essential zip make cmake git wget
RUN apt-get -y install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo libgoogle-perftools-dev libtool patchutils bc zlib1g-dev libexpat-dev libboost-iostreams-dev libboost-program-options-dev libboost-log-dev qt5-default
#libsystemc libsystemc-dev git

# build and install systemc
# RUN wget https://www.accellera.org/images/downloads/standards/systemc/systemc-2.3.3.zip \
#     && unzip systemc-2.3.3.zip \
#     && cd systemc-2.3.3 \
#     && mkdir build \
#     && cd build \
#     && cmake ..  -DCMAKE_CXX_STANDARD=14 \
#     && make \
#     && make install

# install RISC-V toolchain dependencies
RUN git clone https://github.com/riscv/riscv-gnu-toolchain
#RUN apt-get -y install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
# build toolchain
RUN cd riscv-gnu-toolchain \
    && ./configure --prefix=/opt/riscv --with-arch=rv32imac --with-abi=ilp32 \
    && make -j$(nproc) \
    && echo "PATH=$PATH:/opt/riscv/bin" >> ~/.bashrc
