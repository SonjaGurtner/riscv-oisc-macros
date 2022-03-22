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

.macro SUBI rd, r1, imm
addi sp, sp, -8
sw t0, 0(sp)      
MYADDI t0, x0, \imm         #t0 = imm
sub \rd, \r1, t0            #rd = r1 -(-imm)
sw \rd, 4(sp)
lw t0, 0(sp)
lw \rd, 4(sp)
addi sp, sp, 8
.endm

#only replace JAL command as we need to keep jalr to manipulate pc directly
.macro MYJAL, rd, imm
addi sp, sp, -12
sw t0, 0(sp)                #save t0
sw t1, 4(sp)                #will be rd
auipc t0, 0                 #t0 = pc
MYADD t1, x0, t0            #rd = pc
SUBI t0, x0, 4              #t0 = -4
sub t1, t1, t0              #rd = pc + 4
sw t1, 8(sp)
lw t0, 0(sp)                #restore t0
lw t1, 4(sp)
lw \rd, 8(sp)
addi sp, sp, 12
beq x0, x0, \imm            #jump to label
.endm

.macro MYBGE r1, r2, imm
blt \r1, \r2, 10f           #just skip
beq x0, x0, \imm            #jump to label
10:
.endm

.macro MYBNE r1, r2, imm
beq \r1, \r2, 20f           #skip
beq x0, x0, \imm            #jump to label
20:
.endm

.macro MYBLTU r1, r2, imm
addi sp, sp, -8
sw t0, 0(sp)
sw t1, 4(sp)
sub t0, x0, \r1
sub t0, x0, t0              #t0 = -(-r1) = r1
sub t1, x0, \r2
sub t1, x0, t1              #t1 = -(-r2) = r2
#compare upper 31 bits
srli t0, t0, 1              #eliminate LSB, get leading 0
srli t1, t1, 1
beq t0, t1, 30f             #if upper 31 bits are the same
blt t0, t1, 32f             #compare upper 31 bits with less than
beq x0, x0, 31f

#upper 31 bits are the same, compare lower 31 bits
30
sub t0, x0, \r1
sub t0, x0, t0
sub t1, x0, \r2
sub t1, x0, t1
MYSLLI t0, t0, 1            #eliminate MSB
srli t0, t0, 1
MYSLLI t1, t1, 1
srli t1, t1, 1
blt t0, t1, 32f             #r2 < r1, jump to imm

31:                          #just restore registers, do nothing
lw t1, 4(sp)
lw t0, 0(sp)
addi sp, sp, 8
beq x0, x0, 33f

32:
lw t1, 4(sp)
lw t0, 0(sp)
addi sp, sp, 8
beq x0, x0, \imm            #jump to label

33:                         #end
.endm

#branch if r1 >= r2 meaning that r2 < r1
#just call bltu with r2 and r1
.macro MYBGEU r1, r2, imm
MYBLTU \r2, \r1, \imm
.endm

.macro MYSLT rd, r1, r2
sub \rd, \r1, \r2           #rd = r1 - r2
blt \rd, x0, 40f            #if rd < 0 (r1 < r2)
sub \rd, x0, x0             #r1 > r2, rd = 0
beq x0, x0, 41f
40:
MYADDI \rd, x0, 1           #rd = 1
41:                         #end
.endm

.macro MYSLTI rd, r1, imm
SUBI \rd, \r1, \imm         #rd = r1 - imm
blt \rd, x0, 42f            #if rd < 0 (r1 < r2)
sub \rd, x0, x0             #r1 > r2, rd = 0
beq x0, x0, 43f
42:
MYADDI \rd, x0, 1           #rd = 1
43:                         #end
.endm

.macro MYSLTI2 rd, r1, imm
addi sp, sp, -4
sw t0, 0(sp)
MYADDI t0, x0, \imm
MYSLT \rd, \r1, t0
lw t0, 0(sp)
addi sp, sp, 4
.endm

.macro MYSLTU rd, r1, r2
addi sp, sp, -8
sw t0, 0(sp)
sw t1, 4(sp)
MYADD t0, x0, \r1           #t0 = r1
MYADD t1, x0, \r2           #t1 = r2
srli t0, t0, 1              #eliminate LSB and get leading 0
srli t1, t1, 1
beq t0, t1, 50f             #compare lower 31 bits
beq x0, x0, 51f             #else just slt
50:
MYADD t0, x0, \r1
MYADD t1, x0, \r2
MYSLLI t0, t0, 1            #shift left and right to eliminate MSB
srli t0, t0, 1
MYSLLI t1, t1, 1
srli t1, t1, 1
51:
MYSLT \rd, t0, t1
lw t1, 4(sp)
lw t0, 0(sp)
addi sp, sp, 8
.endm

.macro MYSLTIU rd, r1, imm
#first compare the upper 31 bits (srl to eliminate LSB and have leading 0
#when they are != then normal SLT, when equal compare lower 31 bits
#by shifting once left and right to keep lower 31 and eliminate MSB
addi sp, sp, -8
sw t0, 0(sp)
sw t1, 4(sp)
MYADD t0, x0, \r1           #t0 = r1
MYADDI t1, x0, \imm         #t1 = imm
srli t0, t0, 1              #eliminate LSB and get leading 0
srli t1, t1, 1
beq t0, t1, 52f             #compare lower 31 bits
beq x0, x0, 53f             #else just slt
52:
MYADD t0, x0, \r1
MYADDI t1, x0, \imm
MYSLLI t0, t0, 1            #shift left and right to eliminate MSB
srli t0, t0, 1
MYSLLI t1, t1, 1
srli t1, t1, 1
53:
MYSLT \rd, t0, t1
lw t1, 4(sp)
lw t0, 0(sp)
addi sp, sp, 8
.endm

.macro MYSLTIU2 rd, r1, imm
addi sp, sp, -4
sw t0, 0(sp)
MYADDI t0, x0, \imm
MYSLTU \rd, \r1, t0
lw t0, 0(sp)
addi sp, sp, 4
.endm

.macro MYLUI rd, imm
#labels have to be unique so cannot use slli_loop if called multiple times
#need to use 1 and then 1b or 1f which makes it unique
#lui is shift left by 12
MYADDI \rd, x0, \imm        #rd = imm
MYSLLI \rd, \rd, 12
.endm

.macro MYSLLI2, rd, r1, imm
#alternative version, just write imm to register and call MYSLL
addi sp, sp, -4
sw t0, 0(sp)
MYADDI t0, x0, \imm         #t0 = -imm
MYSLL \rd, \r1, t0
lw t0, 0(sp)
addi sp, sp, 4
.endm

.macro MYSLLI, rd, r1, imm
# shift amount should be positive, negativ leads to infinite loop in this macro
# and overflow or smth in real sll
# shift by 1 means * 2 (=add to itself)
addi sp, sp, -20
sw t0, 0(sp)                #save registers
sw t1, 4(sp)
sw t2, 8(sp)
sw t3, 12(sp)

sub t3, x0, \r1             #t3 = r1, will become rd
sub t3, x0, t3
sub t0, x0, t3              #t0 = -rd
MYADDI t1, x0, \imm         #t1 = exit condition
MYADDI t2, x0, 0            #loop variable i

60:
beq t2, t1, 61f             #loop end condition
sub t3, t3, t0              #rd - (-rd) => rd*2
sub t0, x0, t3              #t0 = -rd
addi t2, t2, 1              #i++
beq x0, x0, 60b

61:
sw t3, 16(sp)              
lw t3, 12(sp)
lw t2, 8(sp)                #restore registers
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 16(sp)
addi sp, sp, 20
.endm

.macro MYSLL, rd, r1, r2
addi sp, sp, -12
sw t0, 0(sp)                #save registers
sw t1, 4(sp)
sw t2, 8(sp)
MYADD t1, x0, \r2           #loop boundary
MYADDI t2, x0, 0            #loop variable i
MYADD \rd, x0, \r1          #rd = r1
sub t0, x0, \rd             #t0 = -rd

62:
beq t2, t1, 63f              #loop end condition
sub \rd, \rd, t0            #rd - (-rd) => rd*2
sub t0, x0, \rd             #t0 = -rd
MYADDI t2, t2, 1            #i++
beq x0, x0, 62b

63:
lw t2, 8(sp)                #restore registers
lw t1, 4(sp)
lw t0, 0(sp)
addi sp, sp, 12
.endm

.macro MYOR rd, r1, r2
#iterate through the numbers, each time extract MSBs and compare them
#check special cases, BEFORE overwriting temp registers (one of them may be r1 or r2)
beq \r1, x0, 107f           #r1 = 0, return r2
beq \r2, x0, 108f           #r2 = 0, return r1

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

101:
bgt t1, t2, 106f              #i=33, loop limit reached, compared each bit
MYSLLI s1, s1, 1            #shift rd left by one
MYSLLI t5, t3, 1              
srli t5, t5, 1              #MSB = 0
MYSLLI t6, t4, 1              
srli t6, t6, 1              #MSB = 0
sub t5, t3, t5              #t5 = t3 -t5 (extracted MSB)
bne t5, x0, 102f
110:
sub t6, t4, t6              #extracted MSB of r2
bne t6, x0, 103f
111:
MYADD t5, t5, t6            #MSB of r1 + MSB of r2
bgt t5, x0, 104f              #sum has to be at least 1 (0|1; 1|1)
beq x0, x0, 105f              #if not the case (0|0) shift to left to add 0

102:
MYADDI t5, x0, 1
beq x0, x0, 110b

103:
MYADDI t6, x0, 1
beq x0, x0, 111b

104:
MYADDI s1, s1, 1           #s1+=1

105:
MYADDI t1, t1, 1            #i++
MYSLLI t3, t3, 1            #shift r1 by 1
MYSLLI t4, t4, 1            #shift r2 by 1
beq x0, x0, 101b              #loop again

107:                          #special case r1=0, return r2
MYADD \rd, x0, \r2
beq x0, x0, 109f

108:                          #special case r2=0, return r1
MYADD \rd, x0, \r1
beq x0, x0, 109f

106:                          #end, estore registers
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

109:
.endm

.macro MYXOR rd, r1, r2
#special cases
beq \r1, x0, 127f             #r1 = 0, return r2
beq \r2, x0, 128f             #r2 = 0, return r1

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
MYADD s1, x0, x0            #clean rd for result

121:
bgt t1, t2, 126f            #i=33, loop limit reached, compared each bit
MYSLLI s1, s1, 1            #shift rd left by one
MYSLLI t5, t3, 1              
srli t5, t5, 1              #MSB = 0
MYSLLI t6, t4, 1              
srli t6, t6, 1              #MSB = 0
sub t5, t3, t5              #t5 = t3 -t5 (extracted MSB)
bne t5, x0, 122f
130:
sub t6, t4, t6              #extracted MSB of r2
bne t6, x0, 123f
131:
MYADD t5, t5, t6            #MSB of r1 + MSB of r2
beq t5, x0, 124f            #sum has to be exactly 1 (0|1; 1|0)
beq x0, x0, 125f            #if not the case (0|0, (1|1) shift to left to MYADD 0

122:
MYADDI t5, x0, 1
beq x0, x0, 130b

123:
MYADDI t6, x0, 1
beq x0, x0, 131b

124:
MYADDI s1, s1, 1            #rd+=1

125:
MYADDI t1, t1, 1            #i++
MYSLLI t3, t3, 1            #shift r1 by 1
MYSLLI t4, t4, 1            #shift r2 by 1
beq x0, x0, 121b            #loop again

127:                        #special case r1=0, return r2
MYADD \rd, x0, \r2
beq x0, x0, 129f

128:                        #special case r2=0, return r1
MYADD \rd, x0, \r1
beq x0, x0, 129f

126:                        #end, estore registers
sw s1, 32(sp)
lw s1, 28(sp)
lw t2, 24(sp)              
lw t1, 20(sp)             
lw t0, 16(sp)
lw t6, 12(sp)
lw t5, 8(sp)
lw t4, 4(sp)
lw t3, 0(sp)
lw \rd, 32(sp)
addi sp, sp, 36
129:
.endm

.macro MYAND rd, r1, r2
addi sp, sp, -28
sw t3, 0(sp)                #shifting r1
sw t4, 4(sp)                #shifting r2
sw t5, 8(sp)                #msb eliminated r1 for comparison, also contains MSB sum
sw t6, 12(sp)               #msb eliminated r2 for comparison
sw t0, 16(sp)               #1, for comparing MSBs
sw t1, 20(sp)               #loop variable i
sw t2, 24(sp)               #loop limit = 32   

#check special cases, BEFORE overwriting temp registers (one of them may be r1 or r2)
beq \r1, x0, 147f           #r1 or r2 = 0, return 0
beq \r2, x0, 147f             

MYADD t3, x0, \r1
MYADD t4, x0, \r2
MYADDI t0, x0, 1
MYADDI t1, x0, 1
MYADDI t2, x0, 32
MYADD \rd, x0, x0           #clean rd for result

141:
bgt t1, t2, 146f            #i=33, loop limit reached, compared each bit
MYSLLI \rd, \rd, 1          #shift rd left by one
MYSLLI t5, t3, 1              
srli t5, t5, 1              #MSB = 0
MYSLLI t6, t4, 1              
srli t6, t6, 1              #MSB = 0
sub t5, t3, t5              #t5 = t3 -t5 (extracted MSB)
bne t5, x0, 142f
150:
sub t6, t4, t6              #extracted MSB of r2
bne t6, x0, 143f
151:
MYADD t5, t5, t6            #MSB of r1 + MSB of r2
bgt t5, x0, 144f            #sum has to be at least 1 (0|1; 1|1)
beq x0, x0, 145f            #if not the case (0|0) shift to left to MYADD 0

142:
MYADDI t5, x0, 1
beq x0, x0, 150b

143:
MYADDI t6, x0, 1
beq x0, x0, 151b

144:
MYADDI \rd, \rd, 1          #rd+=1

145:
MYADDI t1, t1, 1            #i++
MYSLLI t3, t3, 1            #shift r1 by 1
MYSLLI t4, t4, 1            #shift r2 by 1
beq x0, x0, 141b            #loop again

147:                         
MYADD \rd, x0, x0
beq x0, x0, 146f

146:                        #end, estore registers
lw t2, 24(sp)              
lw t1, 20(sp)             
lw t0, 16(sp)
lw t6, 12(sp)
lw t5, 8(sp)
lw t4, 4(sp)
lw t3, 0(sp)
addi sp, sp, 28
.endm

.macro MYXORI rd, r1, imm
addi sp, sp, -4
sw t0, 0(sp)
MYADDI t0, x0, \imm
MYXOR \rd, \r1, t0
lw t0, 0(sp)
addi sp, sp, 4
.endm

.macro MYORI rd, r1, imm
addi sp, sp, -4
sw t0, 0(sp)
MYADDI t0, x0, \imm
MYOR \rd, \r1, t0
lw t0, 0(sp)
addi sp, sp, 4
.endm

.macro MYANDI rd, r1, imm
addi sp, sp, -4
sw t0, 0(sp)
MYADDI t0, x0, \imm
MYAND \rd, \r1, t0
lw t0, 0(sp)
addi sp, sp, 4
.endm

############################## PROGRAMM 

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
#ori s2, s3, 0       	#copy value
MYORI s2, s3, 0
MYXORI s3, a1, 0	    #keep value		
addi t2, t2, 1	    	#t2++
j loopstart	        

end:
addi a2, x0, 1
MYSLT a3, a2, x0
addi t1, x0, 5
MYADDI t1, t1, -3
#MYSLLI s4, a1, 1
#MYLUI s5, 4
#sltiu s6, s4, -13      # 4U < -13U
#addi s9, x0, 500
#MYORI s4, x0, 500
# call exit (SYS_EXIT=93) with exit code 0 (argument in a0)
SYS_EXIT 0