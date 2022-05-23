##################### MACROS

.macro MYADD, rd, r1, r2
addi sp, sp, -24
sw t0, 0(sp)
sw t1, 4(sp)
sw t2, 8(sp)
sw \r1, 12(sp)
sw \r2, 16(sp)
lw t1, 12(sp)               #t1 = r1
lw t0, 16(sp)
sub t0, x0, t0              #t0 = -r2
sub t2, t1, t0              #rd = r1 -(-r2) = r1 + r2
sw t2, 20(sp)
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 20(sp)
addi sp, sp, 24
.endm

.macro MYADDI, rd, r1, imm
addi sp, sp, -20
sw t0, 0(sp)
sw t1, 4(sp)
sw t2, 8(sp)
sw \r1, 12(sp)
lw t1, 12(sp)               #t1 = r1
addi t0, x0, \imm           #t0 = imm
sub t0, x0, t0              #t0 = -imm
sub t2, t1, t0              #rd = r1-(-imm)
sw t2, 16(sp)
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 16(sp)
addi sp, sp, 20
.endm

#only replace JAL command as we need to keep jalr to manipulate pc directly
.macro MYJAL, rd, imm
addi sp, sp, -12
sw t0, 0(sp)                #save t0
sw t1, 4(sp)                #save t1, will become return value for rd
auipc t1, 0                 #t1 = pc
MYADDI t0, x0, 4            #t0 = 4
sub t0, x0, t0              #t0 = -t0 (=-4)
sub t1, t1, t0              #rd = pc + 4
sw t1, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)                #restore t0
lw \rd, 8(sp)               #restore rd
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
addi sp, sp, -16
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
sw \r2, 12(sp)
lw t0, 8(sp)                #t0 = r1
lw t1, 12(sp)               #t1 = r2
#compare upper 31 bits
MYSRLI_SAFE t0, t0, 1       #eliminate LSB, get leading 0
MYSRLI_SAFE t1, t1, 1
beq t0, t1, 30f             #if upper 31 bits are the same
blt t0, t1, 32f             #compare upper 31 bits with less than
beq x0, x0, 31f

#upper 31 bits are the same, compare lower 31 bits
30:
lw t0, 8(sp)
lw t1, 12(sp)
MYSLLI_SAFE t0, t0, 1       #eliminate MSB
MYSRLI_SAFE t0, t0, 1
MYSLLI_SAFE t1, t1, 1
MYSRLI_SAFE t1, t1, 1
blt t0, t1, 32f             #r2 < r1, jump to imm

31:                         #just restore registers, do nothing
lw t1, 4(sp)
lw t0, 0(sp)
addi sp, sp, 16
beq x0, x0, 33f

32:
lw t1, 4(sp)
lw t0, 0(sp)
addi sp, sp, 16
beq x0, x0, \imm            #jump to label

33:                         #end
.endm

.macro MYBGEU r1, r2, imm
addi sp, sp, -16
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
sw \r2, 12(sp)
lw t0, 8(sp)                #t0 = r1
lw t1, 12(sp)               #t1 = r2
#compare upper 31 bits
MYSRLI_SAFE t0, t0, 1              #eliminate LSB, get leading 0
MYSRLI_SAFE t1, t1, 1
beq t0, t1, 40f             #if upper 31 bits are the same
MYBGE t0, t1, 42f           #compare upper 31 bits with greater equal
beq x0, x0, 41f

#upper 31 bits are the same, compare lower 31 bits
40:
lw t0, 8(sp)
lw t1, 12(sp)
MYSLLI_SAFE t0, t0, 1       #eliminate MSB
MYSRLI_SAFE t0, t0, 1
MYSLLI_SAFE t1, t1, 1
MYSRLI_SAFE t1, t1, 1
MYBGE t0, t1, 42f           #r2 < r1, jump to imm

41:                         #just restore registers, do nothing
lw t1, 4(sp)
lw t0, 0(sp)
addi sp, sp, 16
beq x0, x0, 43f

42:
lw t1, 4(sp)
lw t0, 0(sp)
addi sp, sp, 16
beq x0, x0, \imm            #jump to label

43:                         #end
.endm

.macro MYSLT rd, r1, r2
blt \r1, \r2, 50f
sub \rd, x0, x0
beq x0, x0, 51f

50:
MYADDI \rd, x0, 1           #rd = 1

51:
.endm

.macro MYSLTI rd, r1, imm
addi sp, sp, -16
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
lw t1, 8(sp)
MYADDI t0, x0, \imm         #t0 = imm
MYSLT \rd, t1, t0
sw \rd, 12(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 12(sp)
addi sp, sp, 16
.endm

.macro MYSLTU rd, r1, r2
addi sp, sp, -24
sw t0, 0(sp)
sw t1, 4(sp)
sw t2, 8(sp)                #will become rd
sw \r1, 12(sp)
sw \r2, 16(sp)
lw t0, 12(sp)               #t0 = r1
lw t1, 16(sp)               #t1 = r2
MYSRLI_SAFE t0, t0, 1              #eliminate LSB and get leading 0
MYSRLI_SAFE t1, t1, 1
beq t0, t1, 60f             #compare lower 31 bits
beq x0, x0, 61f             #else just slt
60:
lw t0, 12(sp)               #t0 = r1
lw t1, 16(sp)               #t1 = r2
MYSLLI_SAFE t0, t0, 1       #shift left and right to eliminate MSB
MYSRLI_SAFE t0, t0, 1
MYSLLI_SAFE t1, t1, 1
MYSRLI_SAFE t1, t1, 1
61:
MYSLT t2, t0, t1
sw t2, 20(sp)               #save rd on stack
lw t2, 8(sp)                #restore other registers
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 20(sp)              #restore rd
addi sp, sp, 24
.endm

.macro MYSLTIU rd, r1, imm
#first compare the upper 31 bits (srl to eliminate LSB and have leading 0
#when they are != then normal SLT, when equal compare lower 31 bits
#by shifting once left and right to keep lower 31 and eliminate MSB
addi sp, sp, -20
sw t0, 0(sp)
sw t1, 4(sp)
sw t2, 8(sp)                #will become rd
sw \r1, 12(sp)
lw t0, 12(sp)               #t0 = r1
MYADDI t1, x0, \imm         #t1 = imm
MYSRLI_SAFE t0, t0, 1              #eliminate LSB and get leading 0
MYSRLI_SAFE t1, t1, 1
beq t0, t1, 70f             #compare lower 31 bits
beq x0, x0, 71f             #else just slt
70:
lw t0, 12(sp)
MYADDI t1, x0, \imm
MYSLLI_SAFE t0, t0, 1       #shift left and right to eliminate MSB
MYSRLI_SAFE t0, t0, 1
MYSLLI_SAFE t1, t1, 1
MYSRLI_SAFE t1, t1, 1
71:
MYSLT t2, t0, t1
sw t2, 16(sp)
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 16(sp)              #restore rd
addi sp, sp, 20
.endm

.macro MYSRLI rd, r1, imm
addi sp, sp, -16
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
lw t1, 8(sp)
MYADDI t0, x0, \imm
MYANDI t0, t0, 31
beq t0, x0, 80f
MYSRL_SAFE \rd, t1, t0
beq x0, x0, 81f
80:
MYADD \rd, x0, t1
81:
sw \rd, 12(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 12(sp)
addi sp, sp, 16
.endm

.macro MYSRAI rd, r1, imm
addi sp, sp, -16
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
lw t1, 8(sp)
MYADDI t0, x0, \imm
MYANDI t0, t0, 31
beq t0, x0, 90f
MYSRA_SAFE \rd, t1, t0
beq x0, x0, 91f
90:
MYADD \rd, x0, t1
91:
sw \rd, 12(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 12(sp)
addi sp, sp, 16
.endm

.macro MYSLLI rd, r1, imm
addi sp, sp, -16
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
lw t1, 8(sp)
MYADDI t0, x0, \imm
MYANDI t0, t0, 31
beq t0, x0, 100f
MYSLL_SAFE \rd, t1, t0
beq x0, x0, 101f
100:
MYADD \rd, x0, t1
101:
sw \rd, 12(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 12(sp)
addi sp, sp, 16
.endm

.macro MYSLL rd, r1, r2
#shift uses only the lower 5 bit as shift amount, extract via and 31
addi sp, sp, -20
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
sw \r2, 12(sp)
lw t1, 8(sp)
lw t0, 12(sp)
MYANDI t0, t0, 31
beq t0, x0, 110f
MYSLL_SAFE \rd, t1, t0
beq x0, x0, 111f
110:
MYADD \rd, x0, t1
111:
sw \rd, 16(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 16(sp)
addi sp, sp, 20
.endm

.macro MYSRL rd, r1, r2
#shift uses only the lower 5 bit as shift amount, extract via and 31
addi sp, sp, -20
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
sw \r2, 12(sp)
lw t1, 8(sp)
lw t0, 12(sp)
MYANDI t0, t0, 31
beq t0, x0, 120f
MYSRL_SAFE \rd, t1, t0
beq x0, x0, 121f
120:
MYADD \rd, x0, t1
121:
sw \rd, 16(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 16(sp)
addi sp, sp, 20
.endm

.macro MYSRA rd, r1, r2
#shift uses only the lower 5 bit as shift amount, extract via and 31
addi sp, sp, -20
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
sw \r2, 12(sp)
lw t1, 8(sp)
lw t0, 12(sp)
MYANDI t0, t0, 31
beq t0, x0, 130f
MYSRA_SAFE \rd, t1, t0
beq x0, x0, 131f
130:
MYADD \rd, x0, t1
131:
sw \rd, 16(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 16(sp)
addi sp, sp, 20
.endm

.macro MYSLLI_SAFE rd, r1, imm
# shift by 1 means * 2 (=add to itself)
#safe version for use in macro (does not need to extract lowest 5 bit first)
addi sp, sp, -24
sw t0, 0(sp)                #save registers
sw t1, 4(sp)
sw t2, 8(sp)
sw t3, 12(sp)
sw \r1, 16(sp)

lw t3, 16(sp)               #t3 = r1, will become rd
sub t0, x0, t3              #t0 = -rd
MYADDI t1, x0, \imm         #t1 = exit condition
MYADDI t2, x0, 0            #loop variable i

140:
beq t2, t1, 141f             #loop end condition
sub t3, t3, t0              #rd - (-rd) => rd*2
sub t0, x0, t3              #t0 = -rd
addi t2, t2, 1              #i++
beq x0, x0, 140b

141:
sw t3, 20(sp)              
lw t3, 12(sp)
lw t2, 8(sp)                #restore registers
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 20(sp)
addi sp, sp, 24
.endm

.macro MYSLL_SAFE rd, r1, r2
addi sp, sp, -28
sw t0, 0(sp)                #save registers
sw t1, 4(sp)
sw t2, 8(sp)
sw t3, 12(sp)               #t3 will become rd
sw \r1, 16(sp)
sw \r2, 20(sp)
lw t1, 20(sp)               #t1=t2, loop boundary
MYADDI t2, x0, 0            #loop variable i
lw t3, 16(sp)               #t3 = r1
sub t0, x0, t3              #t0 = -rd

150:
beq t2, t1, 151f             #loop end condition
sub t3, t3, t0              #rd - (-rd) => rd*2
sub t0, x0, t3              #t0 = -rd
MYADDI t2, t2, 1            #i++
beq x0, x0, 150b

151:
sw t3, 24(sp)               #save t3
lw t3, 12(sp)               #restore registers
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 24(sp)
addi sp, sp, 28
.endm

.macro MYSRLI_SAFE rd, r1, imm
#safe version for use in macro (does not need to extract lowest 5 bit first)
addi sp, sp, -32
sw t0, 0(sp)                #shifting r1
sw t1, 4(sp)                #loop bound
sw t2, 8(sp)                #loop variable i
sw t3, 12(sp)               #t3 will become rd
sw t4, 16(sp)               #msb eliminated r1
sw t5, 20(sp)               #msb of r1
sw \r1, 24(sp)
MYADDI t2, x0, \imm         #t2=imm
MYADDI t1, x0, 32           #t1 = 32-shift amount (imm), loop boundary
sub t1, t1, t2              
sub t2, x0, x0              #loop variable i
lw t0, 24(sp)               #t0 = r1
sub t3, t3, t3              #clear rd
lw t4, 24(sp)               #t4=rs1
MYSLLI_SAFE t4, t4, 1
srli t4, t4, 1              #msb eliminated

160:
beq t2, t1, 162f            #loop end condition
MYSLLI_SAFE t4, t4, 1
srli t4, t4, 1              #msb eliminated
MYSLLI_SAFE t3, t3, 1
sub t5, t0, t4              #t5 = msb
beq t5, x0, 161f            #msb = 0, don't do anything
MYADDI t3, t3, 1

161:
MYADDI t2, t2, 1            #i++
MYSLLI_SAFE t0, t0, 1
MYSLLI_SAFE t4, t4, 1
beq x0, x0, 160b

162:
sw t3, 28(sp)               #save t3
lw t5, 20(sp)               
lw t4, 16(sp)               
lw t3, 12(sp)               #restore registers
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 28(sp)
addi sp, sp, 32
.endm

#shift right by 1 is the same as a circular shift left by 31
.macro MYSRL_SAFE rd, r1, r2
addi sp, sp, -32
sw t0, 0(sp)                #shifting r1
sw t1, 4(sp)                #loop bound
sw t2, 8(sp)                #loop variable i
sw t3, 12(sp)               #t3 will become rd
sw t4, 16(sp)               #msb eliminated r1
sw t5, 20(sp)               #msb of r1
sw \r1, 24(sp)
sw \r2, 28(sp)
lw t0, 24(sp)               #t0 = r1
lw t4, 24(sp)               #t4 = r1
lw t2, 28(sp)               #t2 = r2
MYADDI t1, x0, 32           #t1 = 32
sub t1, t1, t2              #t1 = 32-shift amount, loop boundary
sub t2, t2, t2              #loop variable i
sub t3, t3, t3              #clear rd

170:
beq t2, t1, 172f             #loop end condition
MYSLLI_SAFE t4, t4, 1
MYSRLI_SAFE t4, t4, 1       #msb eliminated
MYSLLI_SAFE t3, t3, 1
sub t5, t0, t4              #t5 = msb
beq t5, x0, 171f            #msb = 0, don't do anything
MYADDI t3, t3, 1

171:
MYADDI t2, t2, 1            #i++
MYSLLI_SAFE t0, t0, 1
MYSLLI_SAFE t4, t4, 1
beq x0, x0, 170b

172:
sw t3, 28(sp)               #save t3
lw t5, 20(sp)               
lw t4, 16(sp) 
lw t3, 12(sp)               #restore registers
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 28(sp)
addi sp, sp, 32
.endm

.macro MYSRAI_SAFE rd, r1, imm
#safe version for use in macro (does not need to extract lowest 5 bit first)
#first copy the msb for imm times
#then copy the remaining number 32-imm times like in slli
addi sp, sp, -32
sw t0, 0(sp)                #shifting r1
sw t1, 4(sp)                #loop bound
sw t2, 8(sp)                #loop variable i
sw t3, 12(sp)               #t3 will become rd
sw t4, 16(sp)               #msb eliminated r1
sw t5, 20(sp)               #msb of r1
sw \r1, 24(sp)
MYADDI t1, x0, \imm         #t1 = imm          
lw t0, 24(sp)               #t0 = r1
lw t4, 24(sp)               #t4 = r1
sub t2, x0, x0              #loop variable i
sub t3, x0, x0              #clear rd
MYSLLI_SAFE t4, t4, 1
MYSRLI_SAFE t4, t4, 1       #msb eliminated
sub t5, t0, t4
lw t4, 24(sp)               #t4 = r1
beq t5, x0, 180f            #if msb == 0, add 0
MYADDI t5, x0, 1            #else add 1

#first loop, copy msb
180:
beq t2, t1, 181f            #loop end condition
MYSLLI_SAFE t3, t3, 1
MYADD t3, t3, t5            #add msb to result
MYADDI t2, t2, 1
beq x0, x0, 180b

181:
#prepare right loop ending condition
MYADDI t2, x0, 32
sub t1, t2, t1              #32 - imm
sub t2, t2, t2              #t2 = 0, new loop counter

#second loop, copy content
182:
beq t2, t1, 184f             #loop end condition
MYSLLI_SAFE t4, t4, 1
MYSRLI_SAFE t4, t4, 1       #msb eliminated
MYSLLI_SAFE t3, t3, 1
sub t5, t0, t4              #t5 = msb
beq t5, x0, 183f            #msb == 0, don't do anything
MYADDI t3, t3, 1

183:
MYADDI t2, t2, 1            #i++
MYSLLI_SAFE t0, t0, 1
MYSLLI_SAFE t4, t4, 1
beq x0, x0, 182b

184:
sw t3, 28(sp)               #save t3
lw t5, 20(sp)               
lw t4, 16(sp) 
lw t3, 12(sp)               #restore registers
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 28(sp)
addi sp, sp, 32
.endm

#shift right by 1 is the same as a circular shift left by 31
.macro MYSRA_SAFE rd, r1, r2
addi sp, sp, -36
sw t0, 0(sp)                #shifting r1
sw t1, 4(sp)                #loop bound
sw t2, 8(sp)                #loop variable i
sw t3, 12(sp)               #t3 will become rd
sw t4, 16(sp)               #msb eliminated r1
sw t5, 20(sp)               #msb of r1
sw \r1, 24(sp)
sw \r2, 28(sp)
lw t1, 28(sp)               #t1 = rs2
lw t0, 24(sp)               #t0 = r1
lw t4, 24(sp)               #t4 = rs1
sub t2, x0, x0              #loop variable i
sub t3, x0, x0              #clear rd
MYSLLI_SAFE t4, t4, 1
MYSRLI_SAFE t4, t4, 1       #msb eliminated
sub t5, t0, t4              #msb
lw t4, 24(sp)               #t4 = r1
beq t5, x0, 190f            #if msb == 0, add 0
MYADDI t5, x0, 1            #else add 1

#first loop, copy msb
190:
beq t2, t1, 191f            #loop end condition
MYSLLI_SAFE t3, t3, 1
MYADD t3, t3, t5            #add msb to result
MYADDI t2, t2, 1
beq x0, x0, 190b

191:
#prepare right loop ending condition
MYADDI t2, x0, 32
sub t1, t2, t1              #32 - rs2
sub t2, t2, t2              #t2 = 0, new loop counter

192:
beq t2, t1, 194f             #loop end condition
MYSLLI_SAFE t4, t4, 1
MYSRLI_SAFE t4, t4, 1       #msb eliminated
MYSLLI_SAFE t3, t3, 1
sub t5, t0, t4              #t5 = msb
beq t5, x0, 193f             #msb = 0, don't do anything
MYADDI t3, t3, 1

193:
MYADDI t2, t2, 1            #i++
MYSLLI_SAFE t0, t0, 1
MYSLLI_SAFE t4, t4, 1
beq x0, x0, 192b

194:
sw t3, 32(sp)               #save t3
lw t5, 20(sp)               
lw t4, 16(sp) 
lw t3, 12(sp)               #restore registers
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 32(sp)
addi sp, sp, 36
.endm

.macro MYOR rd, r1, r2
#iterate through the numbers, each time extract MSBs and compare them
#check special cases, BEFORE overwriting temp registers (one of them may be r1 or r2)
beq \r1, x0, 207f           #r1 = 0, return r2
beq \r2, x0, 208f           #r2 = 0, return r1

addi sp, sp, -44
sw t3, 0(sp)                #shifting r1
sw t4, 4(sp)                #shifting r2
sw t5, 8(sp)                #msb eliminated r1 for comparison, also contains MSB sum
sw t6, 12(sp)               #msb eliminated r2 for comparison
sw t0, 16(sp)               #1, for comparing MSBs
sw t1, 20(sp)               #loop variable i
sw t2, 24(sp)               #loop limit = 32   
sw s1, 28(sp)               #will be value for rd
sw \r1, 32(sp)
sw \r2, 36(sp)

lw t3, 32(sp)
lw t4, 36(sp)
MYADDI t0, x0, 1
sub t1, x0, x0
MYADDI t2, x0, 32
sub s1, x0, x0              #clean s1 for result, will become value for rd

200:
beq t1, t2, 209f            #i=33, loop limit reached, compared each bit
MYSLLI_SAFE s1, s1, 1       #shift rd left by one
MYSLLI_SAFE t5, t3, 1              
MYSRLI_SAFE t5, t5, 1       #MSB = 0
MYSLLI_SAFE t6, t4, 1              
MYSRLI_SAFE t6, t6, 1       #MSB = 0
sub t5, t3, t5              #t5 = t3 -t5 (extracted MSB)
MYBNE t5, x0, 203f
201:
sub t6, t4, t6              #extracted MSB of r2
MYBNE t6, x0, 204f
202:
MYADD t5, t5, t6            #MSB of r1 + MSB of r2
blt x0, t5, 205f            #sum has to be at least 1 (0|1; 1|1)
beq x0, x0, 206f            #if not the case (0|0) shift to left to add 0

203:
MYADDI t5, x0, 1
beq x0, x0, 201b

204:
MYADDI t6, x0, 1
beq x0, x0, 202b

205:
MYADDI s1, s1, 1            #s1+=1

206:
MYADDI t1, t1, 1            #i++
MYSLLI_SAFE t3, t3, 1       #shift r1 by 1
MYSLLI_SAFE t4, t4, 1       #shift r2 by 1
beq x0, x0, 200b            #loop again

207:                        #special case r1=0, return r2
sub \rd, x0, \r2
sub \rd, x0, \rd
beq x0, x0, 210f

208:                        #special case r2=0, return r1
sub \rd, x0, \r1
sub \rd, x0, \rd
beq x0, x0, 210f

209:                        #end, estore registers
sw s1, 40(sp)               #save return value which will become rd
lw s1, 28(sp)
lw t2, 24(sp)              
lw t1, 20(sp)             
lw t0, 16(sp)
lw t6, 12(sp)
lw t5, 8(sp)
lw t4, 4(sp)
lw t3, 0(sp)
lw \rd, 40(sp)              #restore rd into right register
addi sp, sp, 44

210:
.endm

.macro MYXOR rd, r1, r2
#special cases
beq \r1, x0, 307f           #r1 = 0, return r2
beq \r2, x0, 308f           #r2 = 0, return r1

addi sp, sp, -44
sw t3, 0(sp)                #shifting r1
sw t4, 4(sp)                #shifting r2
sw t5, 8(sp)                #msb eliminated r1 for comparison, also contains MSB sum
sw t6, 12(sp)               #msb eliminated r2 for comparison
sw t0, 16(sp)               #1, for comparing MSBs
sw t1, 20(sp)               #loop variable i
sw t2, 24(sp)               #loop limit = 32   
sw s1, 28(sp)               #will be value for rd
sw \r1, 32(sp)
sw \r2, 36(sp)

lw t3, 32(sp)
lw t4, 36(sp)
MYADDI t0, x0, 1
sub t1, x0, x0
MYADDI t2, x0, 32
sub s1, x0, x0              #clean rd for result

300:
beq t1, t2, 309f            #i=33, loop limit reached, compared each bit
MYSLLI_SAFE s1, s1, 1       #shift rd left by one
MYSLLI_SAFE t5, t3, 1              
MYSRLI_SAFE t5, t5, 1       #MSB = 0
MYSLLI_SAFE t6, t4, 1              
MYSRLI_SAFE t6, t6, 1       #MSB = 0
sub t5, t3, t5              #t5 = t3 -t5 (extracted MSB)
MYBNE t5, x0, 303f
301:
sub t6, t4, t6              #extracted MSB of r2
MYBNE t6, x0, 304f
302:
MYADD t5, t5, t6            #MSB of r1 + MSB of r2
beq t5, t0, 305f            #sum has to be exactly 1 (0^1; 1^0)
beq x0, x0, 306f            #if not the case (0^0; 1^1) shift to left to MYADD 0

303:
MYADDI t5, x0, 1
beq x0, x0, 301b

304:
MYADDI t6, x0, 1
beq x0, x0, 302b

305:
MYADDI s1, s1, 1            #rd+=1

306:
MYADDI t1, t1, 1            #i++
MYSLLI_SAFE t3, t3, 1       #shift r1 by 1
MYSLLI_SAFE t4, t4, 1       #shift r2 by 1
beq x0, x0, 300b            #loop again

307:                        #special case r1=0, return r2
sub \rd, x0, \r2
sub \rd, x0, \rd
beq x0, x0, 310f

308:                        #special case r2=0, return r1
sub \rd, x0, \r1
sub \rd, x0, \rd
beq x0, x0, 310f

309:                        #end, estore registers
sw s1, 40(sp)
lw s1, 28(sp)
lw t2, 24(sp)              
lw t1, 20(sp)             
lw t0, 16(sp)
lw t6, 12(sp)
lw t5, 8(sp)
lw t4, 4(sp)
lw t3, 0(sp)
lw \rd, 40(sp)
addi sp, sp, 44

310:
.endm

.macro MYAND rd, r1, r2
#check special cases, BEFORE overwriting temp registers (one of them may be r1 or r2)
beq \r1, x0, 407f           #r1 or r2 = 0, return 0
beq \r2, x0, 407f

addi sp, sp, -44
sw t3, 0(sp)                #shifting r1
sw t4, 4(sp)                #shifting r2
sw t5, 8(sp)                #msb eliminated r1 for comparison, also contains MSB sum
sw t6, 12(sp)               #msb eliminated r2 for comparison
sw t0, 16(sp)               #1, for comparing MSBs
sw t1, 20(sp)               #loop variable i
sw t2, 24(sp)               #loop limit = 32   
sw s1, 28(sp)               #will be value for rd     
sw \r1, 32(sp)
sw \r2, 36(sp)
lw t3, 32(sp)
lw t4, 36(sp)
MYADDI t0, x0, 2
sub t1, x0, x0
MYADDI t2, x0, 32
sub s1, x0, x0              #clean rd for result

400:
beq t1, t2, 408f            #i=33, loop limit reached, compared each bit
MYSLLI_SAFE s1, s1, 1       #shift rd left by one
MYSLLI_SAFE t5, t3, 1              
MYSRLI_SAFE t5, t5, 1       #MSB = 0
MYSLLI_SAFE t6, t4, 1
MYSRLI_SAFE t6, t6, 1       #MSB = 0
sub t5, t3, t5              #t5 = t3 -t5 (extracted MSB)
MYBNE t5, x0, 403f
401:
sub t6, t4, t6              #extracted MSB of r2
MYBNE t6, x0, 404f
402:
MYADD t5, t5, t6            #MSB of r1 + MSB of r2
beq t5, t0, 405f            #sum has to be exactly 2 (1&1)
beq x0, x0, 406f            #if not the case (0&0; 0&1) shift to left to MYADD 0

403:
MYADDI t5, x0, 1
beq x0, x0, 401b

404:
MYADDI t6, x0, 1
beq x0, x0, 402b

405:
MYADDI s1, s1, 1            #rd+=1

406:
MYADDI t1, t1, 1            #i++
MYSLLI_SAFE t3, t3, 1       #shift r1 by 1
MYSLLI_SAFE t4, t4, 1       #shift r2 by 1
beq x0, x0, 400b            #loop again

407:                         
sub \rd, x0, x0             #return 0
beq x0, x0, 409f

408:                        #end, restore registers
sw s1, 40(sp)
lw s1, 28(sp)
lw t2, 24(sp)              
lw t1, 20(sp)             
lw t0, 16(sp)
lw t6, 12(sp)
lw t5, 8(sp)
lw t4, 4(sp)
lw t3, 0(sp)
lw \rd, 40(sp)
addi sp, sp, 44

409:
.endm

.macro MYXORI rd, r1, imm
addi sp, sp, -12
sw t0, 0(sp)
sw t1, 4(sp)
sub t1, x0, \r1
sub t1, x0, t1
MYADDI t0, x0, \imm
MYXOR \rd, t1, t0
sw \rd, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 8(sp)
addi sp, sp, 12
.endm

.macro MYORI rd, r1, imm
addi sp, sp, -12
sw t0, 0(sp)
sw t1, 4(sp)
sub t1, x0, \r1
sub t1, x0, t1
MYADDI t0, x0, \imm
MYOR \rd, t1, t0
sw \rd, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 8(sp)
addi sp, sp, 12
.endm

.macro MYANDI rd, r1, imm
addi sp, sp, -12
sw t0, 0(sp)
sw t1, 4(sp)
sub t1, x0, \r1
sub t1, x0, t1
MYADDI t0, x0, \imm
MYAND \rd, t1, t0
sw \rd, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 8(sp)
addi sp, sp, 12
.endm

############################## PROGRAMM 

.macro SYS_EXIT, exit_code
li   a7, 93
li   a0, \exit_code
li   t6, SYSCALL_ADDR
csrr a6, mhartid
sw   a6, 0(t6)
.endm

.globl _start
.equ SYSCALL_ADDR, 0x02010000
.data
str:      .ascii "Hello\n"

_start:
##
MYSRL x8, x9, x19
MYSRA x20, x16, x26
MYSRA x29, x14, x13
MYXORI x30, x24, 421
MYXORI x28, x0, -522
MYADDI x4, x19, -988
MYSLT x23, x12, x27
MYSLT x5, x19, x13
MYSLLI x15, x26, 2
lui x19, 434419
MYBNE x28, x17, neLbl
MYSLTI x30, x12, -11
MYSRL x10, x10, x26
MYADDI x1, x7, 1849
MYSLT x14, x10, x21
MYSLTIU x28, x19, 516
MYANDI x3, x13, -886
MYSLL x14, x25, x23
MYSLTIU x13, x30, -1416
lui x28, 305168
MYADDI x23, x21, -1999
MYSRL x22, x21, x27
MYADD x17, x21, x9
MYSRAI x24, x4, 29
MYAND x9, x5, x29
MYSRA x7, x19, x14
MYBLTU x26, x14, ltuLbl
MYSRA x16, x1, x0
MYADD x1, x0, x30
MYSRA x12, x17, x9
MYSLLI x26, x3, 0
MYSRLI x27, x19, 7
MYBNE x11, x18, neLbl
MYBGEU x20, x21, geuLbl
MYBGEU x1, x30, geuLbl
MYBNE x27, x16, neLbl
MYAND x18, x16, x19
MYSLTIU x14, x30, -383
MYADDI x11, x17, 1528
MYBLTU x1, x10, ltuLbl
MYBNE x3, x12, neLbl
jal x0, neLbl
MYANDI x1, x7, 1562
MYSLLI x15, x6, 21
lui x4, 539374
MYSLTI x13, x7, 526
MYSLL x6, x19, x30
MYSLTIU x20, x22, -1788
MYADD x3, x13, x19
MYSLL x19, x16, x18
MYORI x8, x24, -1132
MYSLLI x22, x15, 8
MYXOR x27, x9, x11
MYSRAI x18, x3, 2
MYSLT x12, x3, x0
MYORI x11, x11, 884
MYSRL x14, x4, x17
MYBGEU x12, x13, geuLbl
MYSLTU x20, x11, x30
MYSLTU x20, x13, x13
MYXORI x10, x5, -1267
MYBNE x29, x1, neLbl
MYADD x30, x23, x7
MYSLTIU x24, x1, 1334
lui x26, 982727
MYSLTIU x3, x3, -896
MYSLTU x21, x21, x0
MYSLTU x3, x22, x8
MYAND x28, x26, x29
MYXORI x27, x14, -932
MYSRLI x3, x15, 23
MYSRLI x3, x19, 27
MYBGE x27, x4, geLbl
MYSRA x14, x12, x19
MYSRAI x5, x3, 20
MYSRL x24, x19, x0
MYBLTU x7, x21, ltuLbl
jal x0, neLbl
MYBNE x18, x23, neLbl
MYAND x10, x17, x5
MYSLTIU x9, x8, -669
MYSRL x23, x28, x11
jal x0, neLbl
MYANDI x19, x28, 1414
MYSRL x6, x13, x9
jal x0, neLbl
MYSLTIU x14, x21, -1943
MYBGEU x26, x25, geuLbl
MYBLTU x20, x3, ltuLbl
MYSRA x25, x13, x11
neLbl:
geLbl:
ltuLbl:
geuLbl:
SYS_EXIT 0
###
addi s2, x0, 0		    #fib1 = 0
addi s3, x0, 1          #fib2 = 1
addi a1, x0, 0          #return val
addi t2, x0, 0		    #loop counter
addi t0, x0, 1		    #loop limit

loopstart: 				
beq t2, t0, end	        #if t2 <= 0 exit loop
add a1, s2, s3	    	#a1 = fib
MYORI s2, s3, 0
MYXORI s3, a1, 0	    #keep value		
addi t2, t2, 1	    	#t2++
j loopstart	        

end:
addi a2, x0, 12
srli s4, a2, 31
MYSRLI s5, a2, 31
#addi t1, x0, 5
#MYAND s4, t1, x0
#MYADDI t1, t1, -3
#MYSLLI s4, a1, 1
#MYLUI s5, 4
#sltiu s6, s4, -13      # 4U < -13U
#addi s9, x0, 500
#MYORI s4, x0, 500
# call exit (SYS_EXIT=93) with exit code 0 (argument in a0)
SYS_EXIT 0