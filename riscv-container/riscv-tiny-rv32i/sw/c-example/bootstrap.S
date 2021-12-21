.globl _start
.globl main

_start:
jal main

li a7,93
li a0,0
ecall
