.globl _start
.equ SYSCALL_ADDR, 0x02010000
.data
str:      .ascii "Hello\n"

.macro SYS_EXIT, exit_code
li   a7, 93
li   a0, \exit_code
li   t0, SYSCALL_ADDR
csrr a6, mhartid
sw   a6, 0(t0)
.endm

#only replace JAL command as we need to keep jalr to manipulate pc directly
.macro MYJAL, rd, imm
sw t3, -4(sp)               #save t3
auipc t3, 0                 #t3 = pc
sub t3, x0, t3              #t3 = -pc
sub \rd, x0, t3             #rd = pc
addi t3, x0, 4              #t3 = 4
sub t3, x0, t3              #t3 = -4
sub \rd, \rd,t3             #rd = pc + 4
lw t3, -4(sp)               #restore t3
beq x0, x0, \imm            #jump to label
.endm

.macro MYBGE r1, r2, imm
blt \r1, \r2, 1f
beq x0, x0, \imm            #jump to label
1:
.endm

.macro MYBNE r1, r2, imm
beq \r1, \r2, 1f
beq x0, x0, \imm            #jump to label
1:
.endm

.macro MYBLTU r1, r2, imm
addi sp, sp, -8
sw t0, 0(sp)
sw t1, 4(sp)
add t0, x0, \r1
add t1, x0, \r2
#compare upper 31 bits
srli t0, t0, 1              #eliminate LSB, get leading 0
srli t1, t1, 1
beq t0, t1, 1f              #if upper 31 bits are the same
blt t0, t1, 3f              #compare upper 31 bits with less than
j 2f

#upper 31 bits are the same, compare lower 31 bits
1:
add t0, x0, \r1
add t1, x0, \r2
slli t0, t0, 1              #eliminate MSB
srli t0, t0, 1
slli t1, t1, 1
srli t1, t1, 1
blt t0, t1, 3f              #r2 < r1, jump to imm

2:                          #just restore registers, do nothing
lw t1, 4(sp)
lw t0, 0(sp)
addi sp, sp, 8
j 4f

3:
lw t1, 4(sp)
lw t0, 0(sp)
addi sp, sp, 8
j \imm                      #jump to label

4:
#end
.endm


# program entry-point
_start:
    addi    sp, sp, -16
    sw      ra, 0(sp)
    la      a1, str
    call    solve1
    mv      a0, zero
    lw      ra, 0(sp)
    addi    sp, sp, 16
# call exit (SYS_EXIT=93) with exit code 0 (argument in a0)
    SYS_EXIT 0   

solve1:
    addi s6, x0, -5
    addi s7, x0, 10
    MYBLTU s7, s6, case1
    j case2

    case1:
    addi s11, x0, 4
    j 1f

    case2:
    addi s11, x0, 7

1:
    jalr    zero, 0(ra)     # Return back via the return address


solve:
loop:
    lb      t0, 0(a1)       # Load a char from the src
    sb      t0, 0(a0)       # Store the value of the src
    beq     t0, zero, end   # Check if it's 0
    addi    a0, a0, 1       # Advance destination one byte
    addi    a1, a1, 1       # Advance source one byte
    MYJAL   x0, loop        # Go back to the start of the loop
end:
    jalr    zero, 0(ra)     # Return back via the return address