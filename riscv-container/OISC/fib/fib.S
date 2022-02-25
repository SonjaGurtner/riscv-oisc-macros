.globl _start
.equ SYSCALL_ADDR, 0x02010000

.macro SYS_EXIT, exit_code
li   a7, 93
li   a0, \exit_code
li   t0, SYSCALL_ADDR
csrr a6, mhartid
sw   a6, 0(t0)
.endm

.macro SUBI rd, r1, imm
sw t3, -4(sp)               
li t3, \imm                 #t3 = imm
sub \rd, \r1, t3            #rd = r1 -(-imm)
lw t3, -4(sp)
.endm

.macro MYSLT rd, r1, r2
sub \rd, \r1, \r2           #rd = r1 - r2
blt \rd, x0, 1f             #if rd < 0 (r1 < r2)
sub \rd, x0, x0             #r1 > r2, rd = 0
j 2f
1:
SUBI \rd, x0, 1             #rd = -1
sub \rd, x0, \rd            #rd = 1
2:                          #end
.endm

.macro MYLUI rd, imm
#labels have to be unique so cannot use slli_loop if called multiple times
#need to use 1 and then 1b or 1f which makes it unique
#lui is shift left by 12
SUBI \rd, x0, \imm          #rd = -imm
sub \rd, x0, \rd            #rd = imm
MYSLLI \rd, \rd, 12
.endm

.macro MYSLLI2, rd, r1, imm
#alternative version, just write imm to register and cal MYSLL
sw t6, -16(sp)
SUBI t6, x0, \imm           #t6 = -imm
sub t6, x0, t6              #t6 = imm
MYSLL \rd, \r1, t6
lw t6, -16(sp)
.endm

.macro MYSLLI, rd, r1, imm
# shift amount should be positive, negativ leads to infinite loop in this macro
# and overflow or smth in real sll
# shift by 1 means * 2 (=add to itself)
sw t3, -4(sp)               #save registers
sw t4, -8(sp)
sw t5, -12(sp)
addi t4, x0, \imm           #t4 = exit condition
addi t5, x0, 0              #loop variable i
add \rd, x0, \r1            #rd = r1
sub t3, x0, \rd             #t3 = -rd

1:
beq t5, t4, 2f              #loop end condition
sub \rd, \rd, t3            #rd - (-rd) => rd*2
sub t3, x0, \rd             #t3 = -rd
addi t5, t5, 1              #i++
j 1b

2:
lw t5, -12(sp)              #restore registers
lw t4, -8(sp)
lw t3, -4(sp)
.endm

.macro MYSLL, rd, r1, r2
sw t3, -4(sp)               #save registers
sw t4, -8(sp)
sw t5, -12(sp)
add t4, x0, \r2             #loop boundary
addi t5, x0, 0              #loop variable i
add \rd, x0, \r1            #rd = r1
sub t3, x0, \rd             #t3 = -rd

1:
beq t5, t4, 2f              #loop end condition
sub \rd, \rd, t3            #rd - (-rd) => rd*2
sub t3, x0, \rd             #t3 = -rd
addi t5, t5, 1              #i++
j 1b

2:
lw t5, -12(sp)              #restore registers
lw t4, -8(sp)
lw t3, -4(sp)
.endm

.macro MYXOR
.endm

.macro MYOR
.endm

.macro MYAND
.endm

.macro MYXORI
.endm

.macro MYORI
.endm

.macro MYANDI
.endm

# program entry-point
_start:

addi s2, x0, 0		    #fib1 = 0
addi s3, x0, 1          #fib2 = 1
addi a1, x0, 0          #return val
addi t2, x0, 0		    #loop counter
addi t0, x0, 2		    #loop limit

loopstart: 				
beq t2, t0, end	        #if t2 <= 0 exit loop
add  a1, s2, s3	    	#a1 = fib
ori s2, s3, 0       	#copy value
xori s3, a1, 0	    	#keep value		
addi t2, t2, 1	    	#t2++
j loopstart	        

end:
addi a2, x0, 1
MYSLLI s4, a1, 1
MYLUI s5, 4
MYSLT s6, s3, s4
# call exit (SYS_EXIT=93) with exit code 0 (argument in a0)
SYS_EXIT 0