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
sw t3, -16(sp)               
li t3, \imm                 #t3 = imm
sub \rd, \r1, t3            #rd = r1 -(-imm)
lw t3, -16(sp)
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

.macro MYSLTI rd, r1, imm
SUBI \rd, \r1, \imm         #rd = r1 - imm
blt \rd, x0, 1f             #if rd < 0 (r1 < r2)
sub \rd, x0, x0             #r1 > r2, rd = 0
j 2f
1:
SUBI \rd, x0, 1             #rd = -1
sub \rd, x0, \rd            #rd = 1
2:                          #end
.endm

.macro MYSLTI2 rd, r1, imm
sw t3, -4(sp)
addi t3, x0, \imm
MYSLT \rd, \r1, t3
lw t3, -4(sp)
.endm

.macro MYSLTU rd, r1, r2
sw t3, -20(sp)      
sw t4, -24(sp)          
add t3, x0, \r1             #t3 = r1
add t4, x0, \r2             #t4 = r2
srli t3, t3, 1              #eliminate LSB and get leading 0
srli t4, t4, 1
beq t3, t4, 1f              #compare lower 31 bits
j 2f                        #else just slt
1:
add t3, x0, \r1
add t4, x0, \r2
slli t3, t3, 1              #shift left and right to eliminate MSB
srli t3, t3, 1
slli t4, t4, 1
srli t4, t4, 1
2:
slt \rd, t3, t4
lw t4, -24(sp)
lw t3, -20(sp)
.endm

.macro MYSLTIU rd, r1, imm
#first compare the upper 31 bits (srl to eliminate LSB and have leading 0
#when they are != then normal SLT, when equal compare lower 31 bits
#by shifting once left and right to keep lower 31 and eliminate MSB
sw t3, -20(sp)      
sw t4, -24(sp)          
add t3, x0, \r1             #t3 = r1
addi t4, x0, \imm           #t4 = imm
srli t3, t3, 1              #eliminate LSB and get leading 0
srli t4, t4, 1
beq t3, t4, 1f              #compare lower 31 bits
j 2f                        #else just slt
1:
add t3, x0, \r1
addi t4, x0, \imm
slli t3, t3, 1              #shift left and right to eliminate MSB
srli t3, t3, 1
slli t4, t4, 1
srli t4, t4, 1
2:
slt \rd, t3, t4
lw t4, -24(sp)
lw t3, -20(sp)
.endm

.macro MYSLTIU2 rd, r1, imm
sw t5, -28(sp)
addi t5, x0, \imm
MYSLTIU \rd, \r1, t5
lw t5, -28(sp)
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
sw t6, -20(sp)
SUBI t6, x0, \imm           #t6 = -imm
sub t6, x0, t6              #t6 = imm
MYSLL \rd, \r1, t6
lw t6, -20(sp)
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

.macro MYOR rd, r1, r2
#iterate through the numbers, each time extract MSBs and compare them
sw t3, -20(sp)              #shifting r1
sw t4, -24(sp)              #shifting r2
sw t5, -28(sp)              #msb eliminated r1 for comparison, also contains MSB sum
sw t6, -32(sp)              #msb eliminated r2 for comparison
sw t0, -36(sp)              #1, for comparing MSBs
sw t1, -40(sp)              #loop variable i
sw t2, -44(sp)              #loop limit = 32   

#check special cases, BEFORE overwriting temp registers (one of them may be r1 or r2)
beq \r1, x0, 7f             #r1 = 0, return r2
beq \r2, x0, 8f             #r2 = 0, return r1

add t3, x0, \r1
add t4, x0, \r2
addi t0, x0, 1
addi t1, x0, 1
addi t2, x0, 32
add \rd, x0, x0             #clean rd for result

1:
bgt t1, t2, 6f              #i=33, loop limit reached, compared each bit
slli \rd, \rd, 1            #shift rd left by one
slli t5, t3, 1              
srli t5, t5, 1              #MSB = 0
slli t6, t4, 1              
srli t6, t6, 1              #MSB = 0
sub t5, t3, t5              #t5 = t3 -t5 (extracted MSB)
bne t5, x0, 2f
10:
sub t6, t4, t6              #extracted MSB of r2
bne t6, x0, 3f
11:
add t5, t5, t6              #MSB of r1 + MSB of r2
bgt t5, x0, 4f              #sum has to be at least 1 (0|1; 1|1)
j 5f                        #if not the case (0|0) shift to left to add 0

2:
addi t5, x0, 1
j 10b

3:
addi t6, x0, 1
j 11b

4:
addi \rd, \rd, 1            #rd+=1

5:
addi t1, t1, 1              #i++
slli t3, t3, 1              #shift r1 by 1
slli t4, t4, 1              #shift r2 by 1
j 1b                        #loop again

7:                          #special case r1=0, return r2
add \rd, x0, \r2
j 6f

8:                          #special case r2=0, return r1
add \rd, x0, \r1
j 6f

6:                          #end, estore registers
lw t2, -44(sp)              
lw t1, -40(sp)             
lw t0, -36(sp)
lw t6, -32(sp)
lw t5, -28(sp)
lw t4, -24(sp)
lw t3, -20(sp)
.endm

.macro MYXOR rd, r1, r2
sw t3, -20(sp)              #shifting r1
sw t4, -24(sp)              #shifting r2
sw t5, -28(sp)              #msb eliminated r1 for comparison, also contains MSB sum
sw t6, -32(sp)              #msb eliminated r2 for comparison
sw t0, -36(sp)              #1, for comparing MSBs
sw t1, -40(sp)              #loop variable i
sw t2, -44(sp)              #loop limit = 32   

beq \r1, x0, 7f             #r1 = 0, return r2
beq \r2, x0, 8f             #r2 = 0, return r1

add t3, x0, \r1
add t4, x0, \r2
addi t0, x0, 1
addi t1, x0, 1
addi t2, x0, 32
add \rd, x0, x0             #clean rd for result

1:
bgt t1, t2, 6f              #i=33, loop limit reached, compared each bit
slli \rd, \rd, 1            #shift rd left by one
slli t5, t3, 1              
srli t5, t5, 1              #MSB = 0
slli t6, t4, 1              
srli t6, t6, 1              #MSB = 0
sub t5, t3, t5              #t5 = t3 -t5 (extracted MSB)
bne t5, x0, 2f
10:
sub t6, t4, t6              #extracted MSB of r2
bne t6, x0, 3f
11:
add t5, t5, t6              #MSB of r1 + MSB of r2
beq t5, x0, 4f              #sum has to be exactly 1 (0|1; 1|0)
j 5f                        #if not the case (0|0, (1|1) shift to left to add 0

2:
addi t5, x0, 1
j 10b

3:
addi t6, x0, 1
j 11b

4:
addi \rd, \rd, 1            #rd+=1

5:
addi t1, t1, 1              #i++
slli t3, t3, 1              #shift r1 by 1
slli t4, t4, 1              #shift r2 by 1
j 1b                        #loop again

7:                          #special case r1=0, return r2
add \rd, x0, \r2
j 6f

8:                          #special case r2=0, return r1
add \rd, x0, \r1
j 6f

6:                          #end, estore registers
lw t2, -44(sp)              
lw t1, -40(sp)             
lw t0, -36(sp)
lw t6, -32(sp)
lw t5, -28(sp)
lw t4, -24(sp)
lw t3, -20(sp)
.endm

.macro MYAND rd, r1, r2
sw t3, -20(sp)              #shifting r1
sw t4, -24(sp)              #shifting r2
sw t5, -28(sp)              #msb eliminated r1 for comparison, also contains MSB sum
sw t6, -32(sp)              #msb eliminated r2 for comparison
sw t0, -36(sp)              #1, for comparing MSBs
sw t1, -40(sp)              #loop variable i
sw t2, -44(sp)              #loop limit = 32   

#check special cases, BEFORE overwriting temp registers (one of them may be r1 or r2)
beq \r1, x0, 7f             #r1 or r2 = 0, return 0
beq \r2, x0, 7f             

add t3, x0, \r1
add t4, x0, \r2
addi t0, x0, 1
addi t1, x0, 1
addi t2, x0, 32
add \rd, x0, x0             #clean rd for result

1:
bgt t1, t2, 6f              #i=33, loop limit reached, compared each bit
slli \rd, \rd, 1            #shift rd left by one
slli t5, t3, 1              
srli t5, t5, 1              #MSB = 0
slli t6, t4, 1              
srli t6, t6, 1              #MSB = 0
sub t5, t3, t5              #t5 = t3 -t5 (extracted MSB)
bne t5, x0, 2f
10:
sub t6, t4, t6              #extracted MSB of r2
bne t6, x0, 3f
11:
add t5, t5, t6              #MSB of r1 + MSB of r2
bgt t5, x0, 4f              #sum has to be at least 1 (0|1; 1|1)
j 5f                        #if not the case (0|0) shift to left to add 0

2:
addi t5, x0, 1
j 10b

3:
addi t6, x0, 1
j 11b

4:
addi \rd, \rd, 1            #rd+=1

5:
addi t1, t1, 1              #i++
slli t3, t3, 1              #shift r1 by 1
slli t4, t4, 1              #shift r2 by 1
j 1b                        #loop again

7:                         
add \rd, x0, x0
j 6f

6:                          #end, estore registers
lw t2, -44(sp)              
lw t1, -40(sp)             
lw t0, -36(sp)
lw t6, -32(sp)
lw t5, -28(sp)
lw t4, -24(sp)
lw t3, -20(sp)
.endm

.macro MYXORI rd, r1, imm
sw t0, -48(sp)
addi t0, x0, \imm
MYXOR \rd, \r1, t0
lw t0, -48(sp)
.endm

.macro MYORI rd, r1, imm
sw t0, -48(sp)
addi t0, x0, \imm
MYOR \rd, \r1, t0
lw t0, -48(sp)
.endm

.macro MYANDI rd, r1, imm
sw t0, -48(sp)
addi t0, x0, \imm
MYAND \rd, \r1, t0
lw t0, -48(sp)
.endm

# program entry-point
_start:

addi s2, x0, 0		    #fib1 = 0
addi s3, x0, 1          #fib2 = 1
addi a1, x0, 0          #return val
addi t2, x0, 0		    #loop counter
addi t0, x0, 3		    #loop limit

loopstart: 				
beq t2, t0, end	        #if t2 <= 0 exit loop
add a1, s2, s3	    	#a1 = fib
#ori s2, s3, 0       	#copy value
or s2, s3, x0
xori s3, a1, 0	    	#keep value		
addi t2, t2, 1	    	#t2++
j loopstart	        

end:
addi a2, x0, 1
#MYSLLI s4, a1, 1
#MYLUI s5, 4
#sltiu s6, s4, -13      # 4U < -13U
#addi s9, x0, 500
#MYORI s4, x0, 500
# call exit (SYS_EXIT=93) with exit code 0 (argument in a0)
SYS_EXIT 0