cmake_minimum_required(VERSION 2.8.12)
project(riscv-tiny-isa)

ADD_DEFINITIONS(-std=c++14 -g3)

find_package( Boost REQUIRED COMPONENTS iostreams )

subdirs(lib)
