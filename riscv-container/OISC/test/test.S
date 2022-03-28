.globl _start
.equ SYSCALL_ADDR, 0x02010000
.data
str:      .ascii "Hello\n"

##################### MACROS

.macro MYADD, rd, r1, r2
addi sp, sp, -12
sw t0, 0(sp)                #save t0
sw t1, 4(sp)
sub t1, x0, \r1
sub t1, x0, t1
sub t0, x0, \r2             #t0 = -a0
sub \rd, t1, t0             #rd = r1 -(-a0)
sw \rd, 8(sp)
lw t0, 0(sp)
lw t1, 4(sp)
lw \rd, 8(sp)
addi sp, sp, 12
.endm

.macro MYADDI, rd, r1, imm
addi sp, sp, -12
sw t0, 0(sp)
sw t1, 4(sp)
sub t1, x0, \r1
sub t1, x0, t1
addi t0, x0, \imm           #t0 = imm
sub t0, x0, t0              #t0 = -imm
sub \rd, t1, t0             #rd = r1-(-imm)
sw \rd, 8(sp)
lw t0, 0(sp)
lw t1, 4(sp)
lw \rd, 8(sp)
addi sp, sp, 12
.endm

.macro MYLUI rd, imm
#lui takes 20 bit but addi has 12
#lui is shift left by 12
MYADDI \rd, x0, \imm        #rd = imm
MYSLLI \rd, \rd, 12
.endm

.macro MYSLLI, rd, r1, imm
# shift amount should be positive, negativ leads to infinite loop in this macro
# and overflow or smth in real sll
# shift by 1 means * 2 (=add to itself)
addi sp, sp, -12
sw t0, 0(sp)                #save registers
sw t1, 4(sp)
sw t2, 8(sp)

sub \rd, x0, \r1            #t3 = r1, will become rd
sub t0, x0, \rd             #t0 = -rd
MYADDI t1, x0, \imm         #t1 = exit condition
MYADDI t2, x0, 0            #loop variable i

1:
beq t2, t1, 2f             #loop end condition
sub \rd, \rd, t0            #rd - (-rd) => rd*2
sub t0, x0, t3              #t0 = -rd
addi t2, t2, 1              #i++
beq x0, x0, 1b

2:
lw t2, 8(sp)                #restore registers
lw t1, 4(sp)
lw t0, 0(sp)
addi sp, sp, 12
.endm

.macro MYOR rd, r1, r2
#iterate through the numbers, each time extract MSBs and compare them
#check special cases, BEFORE overwriting temp registers (one of them may be r1 or r2)
#beq \r1, x0, 7f           #r1 = 0, return r2
#beq \r2, x0, 8f           #r2 = 0, return r1

addi sp, sp, -36
sw t3, 0(sp)                #shifting r1
sw t4, 4(sp)                #shifting r2
sw t5, 8(sp)                #msb eliminated r1 for comparison, also contains MSB sum
sw t6, 12(sp)               #msb eliminated r2 for comparison
sw t0, 16(sp)               #1, for comparing MSBs
sw t1, 20(sp)               #loop variable i
sw t2, 24(sp)               #loop limit = 32   
sw s1, 28(sp)

MYADD t3, x0, \r1
MYADD t4, x0, \r2
MYADDI t0, x0, 1
MYADDI t1, x0, 1
MYADDI t2, x0, 32
MYADD s1, x0, x0           #clean s1 for result, will become value for rd

1:
bgt t1, t2, 6f              #i=33, loop limit reached, compared each bit
MYSLLI s1, s1, 1            #shift rd left by one
MYSLLI t5, t3, 1              
srli t5, t5, 1              #MSB = 0
MYSLLI t6, t4, 1              
srli t6, t6, 1              #MSB = 0
sub t5, t3, t5              #t5 = t3 -t5 (extracted MSB)
bne t5, x0, 2f
10:
sub t6, t4, t6              #extracted MSB of r2
bne t6, x0, 3f
11:
MYADD t5, t5, t6            #MSB of r1 + MSB of r2
bgt t5, x0, 4f              #sum has to be at least 1 (0|1; 1|1)
beq x0, x0, 5f              #if not the case (0|0) shift to left to add 0

2:
MYADDI t5, x0, 1
beq x0, x0, 10b

3:
MYADDI t6, x0, 1
beq x0, x0, 11b

4:
MYADDI s1, s1, 1           #s1+=1

5:
MYADDI t1, t1, 1            #i++
MYSLLI t3, t3, 1            #shift r1 by 1
MYSLLI t4, t4, 1            #shift r2 by 1
beq x0, x0, 1b              #loop again

7:                          #special case r1=0, return r2
MYADD \rd, x0, \r2
beq x0, x0, 9f

8:                          #special case r2=0, return r1
MYADD \rd, x0, \r1
beq x0, x0, 9f

6:                          #end, estore registers
sw s1, 32(sp)               #save return value which will become rd
lw s1, 28(sp)
lw t2, 24(sp)              
lw t1, 20(sp)             
lw t0, 16(sp)
lw t6, 12(sp)
lw t5, 8(sp)
lw t4, 4(sp)
lw t3, 0(sp)
lw \rd, 32(sp)              #restore rd into right register
addi sp, sp, 36

9:
.endm

.macro MYORI rd, r1, imm
addi sp, sp, -4
sw t0, 0(sp)
MYADDI t0, x0, \imm
MYOR \rd, \r1, t0
lw t0, 0(sp)
addi sp, sp, 4
.endm

############################## PROGRAM

.macro SYS_EXIT, exit_code
li   a7, 93
li   a0, \exit_code
li   t0, SYSCALL_ADDR
csrr a6, mhartid
sw   a6, 0(t0)
.endm

_start:

#MYSLLI x17, x20, 8
#MYSLLI x15, x29, 8
#MYADDI x5, x13, 1054
#MYSLLI x7, x0, 13
#MYSLLI x21, x25, 15
#MYSLLI x18, x23, 30
#SYS_EXIT 0

addi s2, x0, 0		    #fib1 = 0
addi s3, x0, 1          #fib2 = 1
addi a1, x0, 0          #return val
addi t2, x0, 0		    #loop counter
addi t0, x0, 1		    #loop limit

loopstart: 				
beq t2, t0, end	        #if t2 <= 0 exit loop
add a1, s2, s3	    	#a1 = fib
MYORI s2, s3, 0         #copy value
xori s3, a1, 0	        #keep value		
addi t2, t2, 1	    	#t2++
j loopstart	        

end:
SYS_EXIT 0