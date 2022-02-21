.globl _start
.equ SYSCALL_ADDR, 0x02010000

.macro SYS_EXIT, exit_code
li   a7, 93
li   a0, \exit_code
li   t0, SYSCALL_ADDR
csrr a6, mhartid
sw   a6, 0(t0)
.endm

.macro MYADD, rd, r1, r2
sw t3, 0x0(sp)              #save t3
sub t3, x0, \r2             #t3 = -a0
sub \rd, \r1, t3            #rd = r1 -(-a0)
lw t3, 0x0(sp)              #restore t3
.endm

.macro MYADDI, rd, r1, imm
sw t3, 0x0(sp)
li t3, \imm
sub t3, x0, t3
sub \rd, \r1, t3
lw t3, 0x0(sp)
.endm

.macro SUBI rd, r1, imm
sw t3, 0x0(sp)
li t3, \imm
sub rd, r1, t3
lw t3, 0x0(sp)
.endm

# program entry-point
_start:

li a0,50
li a1,100

li a2,0
loop:
bgt a0,a1,end
MYADD a2,a2,a0
MYADDI a0,a0,1
j loop
end:

# call exit (SYS_EXIT=93) with exit code 0 (argument in a0)
SYS_EXIT 0
