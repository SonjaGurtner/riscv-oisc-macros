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

# program entry-point
_start:
    addi    sp, sp, -16
    sw      ra, 0(sp)
    la      a1, str
    call    solve
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