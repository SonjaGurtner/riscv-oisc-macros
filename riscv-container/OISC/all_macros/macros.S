##################### MACROS

# Addition can be replaced by two subtractions, a + b = a-(-b)
.macro MYADD, rd, r1, r2
addi sp, sp, -20
sw t0, 0(sp)
sw t1, 4(sp)
sw t2, 8(sp)
sw \r1, 12(sp)
sw \r2, 16(sp)
lw t1, 12(sp)               # t1 = r1
lw t0, 16(sp)               # ts = r2
sub t0, x0, t0              # t0 = -r2
sub t2, t1, t0              # rd = r1-(-r2) = r1 + r2
sw t2, 16(sp)
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 16(sp)
addi sp, sp, 20
.endm

.macro MYADDI, rd, r1, imm
addi sp, sp, -16
sw t0, 0(sp)
sw t1, 4(sp)
sw t2, 8(sp)
#sw \r1, 12(sp)
#lw t1, 12(sp)               # t1 = r1
sub t1, x0, \r1             # t1 = -r1
sub t1, x0, t1              #t1 = r1
addi t0, x0, \imm           # t0 = imm
sub t0, x0, t0              # t0 = -imm
sub t2, t1, t0              # rd = r1-(-imm)
sw t2, 12(sp)
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 12(sp)
addi sp, sp, 16
.endm

# only replace JAL command as we need to keep jalr to manipulate pc directly
.macro MYJAL, rd, imm
addi sp, sp, -12
sw t0, 0(sp)
sw t1, 4(sp)                # save t1, will become return value for rd
auipc t1, 0                 # t1 = pc
MYADDI t0, x0, 4            # t0 = 4
sub t0, x0, t0              # t0 = -t0 (= -4)
sub t1, t1, t0              # rd = pc + 4
sw t1, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 8(sp)
addi sp, sp, 12
beq x0, x0, \imm            # jump to label
.endm

.macro MYBGE r1, r2, imm
blt \r1, \r2, 10f           # if r2 < r1 just and go to next instruction
beq x0, x0, \imm            # jump to label
10:
.endm

.macro MYBNE r1, r2, imm
beq \r1, \r2, 20f           # if equal just skip
beq x0, x0, \imm            # jump to label
20:
.endm

.macro MYBLTU r1, r2, imm
addi sp, sp, -16
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
sw \r2, 12(sp)
lw t0, 8(sp)                # t0 = r1
lw t1, 12(sp)               # t1 = r2
# compare upper 31 bits
MYSRLI_SAFE t0, t0, 1       # eliminate LSB, get leading 0
MYSRLI_SAFE t1, t1, 1
beq t0, t1, 30f             # if upper 31 bits are the same
blt t0, t1, 32f             # compare upper 31 bits with less than
beq x0, x0, 31f

# upper 31 bits are the same, compare lower 31 bits
30:
lw t0, 8(sp)
lw t1, 12(sp)
MYSLLI_SAFE t0, t0, 1       # eliminate MSB
MYSRLI_SAFE t0, t0, 1
MYSLLI_SAFE t1, t1, 1
MYSRLI_SAFE t1, t1, 1
blt t0, t1, 32f             # r1 < r2, jump to imm

31:                         # else do nothing
lw t1, 4(sp)
lw t0, 0(sp)
addi sp, sp, 16
beq x0, x0, 33f

32:
lw t1, 4(sp)
lw t0, 0(sp)
addi sp, sp, 16
beq x0, x0, \imm            # jump to label

33:
.endm

.macro MYBGEU r1, r2, imm
MYBLTU \r1, \r2, 40f
beq x0, x0, \imm

40:
.endm

.macro MYSLT rd, r1, r2
blt \r1, \r2, 50f
sub \rd, x0, x0
beq x0, x0, 51f             # r2 > r1, rd = 0

50:
MYADDI \rd, x0, 1           # rd = 1

51:
.endm

.macro MYSLTI rd, r1, imm
addi sp, sp, -12
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
lw t1, 8(sp)                # t1 = r1
MYADDI t0, x0, \imm         # t0 = imm
MYSLT \rd, t1, t0           # r1 < imm ?
sw \rd, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 8(sp)
addi sp, sp, 12
.endm

# first compare the upper 31 bits (srl to eliminate LSB and have leading 0)
# when they are != then normal SLT, when equal compare lower 31 bits
# by shifting once left and right to keep lower 31 bits and eliminate MSB
.macro MYSLTU rd, r1, r2
addi sp, sp, -20
sw t0, 0(sp)
sw t1, 4(sp)
sw t2, 8(sp)                # t2 will become rd
sw \r1, 12(sp)
sw \r2, 16(sp)
lw t0, 12(sp)               # t0 = r1
lw t1, 16(sp)               # t1 = r2
MYSRLI_SAFE t0, t0, 1       # eliminate LSB and get leading 0
MYSRLI_SAFE t1, t1, 1
beq t0, t1, 60f             # if equal compare lower 31 bits
beq x0, x0, 61f             # else just slt

# compare lower 31 bits
60:
lw t0, 12(sp)               # t0 = r1
lw t1, 16(sp)               # t1 = r2
MYSLLI_SAFE t0, t0, 1       # shift left and right to eliminate MSB
MYSRLI_SAFE t0, t0, 1
MYSLLI_SAFE t1, t1, 1
MYSRLI_SAFE t1, t1, 1

# compare
61:
MYSLT t2, t0, t1
sw t2, 16(sp)
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 16(sp)
addi sp, sp, 20
.endm

.macro MYSLTIU rd, r1, imm
addi sp, sp, -16
sw t0, 0(sp)
sw t1, 4(sp)
sw t2, 8(sp)                # t2 will become rd
sw \r1, 12(sp)
lw t0, 12(sp)               # t0 = r1
MYADDI t1, x0, \imm         # t0 = imm
MYSRLI_SAFE t0, t0, 1       # eliminate LSB
MYSRLI_SAFE t1, t1, 1
beq t0, t1, 70f             # compare lower 31 bits
beq x0, x0, 71f             # compare upper

# lower bits same, compare upper bits
70:
lw t0, 12(sp)
MYADDI t1, x0, \imm
MYSLLI_SAFE t0, t0, 1       # eliminate MSB
MYSRLI_SAFE t0, t0, 1
MYSLLI_SAFE t1, t1, 1
MYSRLI_SAFE t1, t1, 1

# compare
71:
MYSLT t2, t0, t1
sw t2, 12(sp)
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 12(sp)
addi sp, sp, 16
.endm

.macro MYSRLI rd, r1, imm
addi sp, sp, -12
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
lw t1, 8(sp)                # t1 = r1
MYADDI t0, x0, \imm         # t0 = imm
MYANDI t0, t0, 31           # shift amount is 5 bits long
beq t0, x0, 80f             # if shift amount == 0 skip and return r1
MYSRL_SAFE \rd, t1, t0      # else shift right
beq x0, x0, 81f

80:
MYADD \rd, x0, t1

81:
sw \rd, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 8(sp)
addi sp, sp, 12
.endm

.macro MYSRAI rd, r1, imm
addi sp, sp, -12
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
lw t1, 8(sp)                # t1 = r1
MYADDI t0, x0, \imm         # t0 = imm
MYANDI t0, t0, 31           # extract lowest 5 bits
beq t0, x0, 90f             # if shift amount == 0 return r1
MYSRA_SAFE \rd, t1, t0
beq x0, x0, 91f

90:
MYADD \rd, x0, t1

91:
sw \rd, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 8(sp)
addi sp, sp, 12
.endm

.macro MYSLLI rd, r1, imm
addi sp, sp, -12
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
lw t1, 8(sp)                # t1 = r1
MYADDI t0, x0, \imm         # t0 = imm
MYANDI t0, t0, 31           # extract lowest 5 bits
beq t0, x0, 100f            # if shift amount == 0 return r1
MYSLL_SAFE \rd, t1, t0
beq x0, x0, 101f

100:
MYADD \rd, x0, t1

101:
sw \rd, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 8(sp)
addi sp, sp, 12
.endm

.macro MYSLL rd, r1, r2
addi sp, sp, -16
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
sw \r2, 12(sp)
lw t1, 8(sp)                # t1 = r1
lw t0, 12(sp)               # t0 = r2
MYANDI t0, t0, 31           # extract shift amount
beq t0, x0, 110f            # if shift by 0 rturn r1
MYSLL_SAFE \rd, t1, t0
beq x0, x0, 111f

110:
MYADD \rd, x0, t1

111:
sw \rd, 12(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 12(sp)
addi sp, sp, 16
.endm

.macro MYSRL rd, r1, r2
addi sp, sp, -16
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
sw \r2, 12(sp)
lw t1, 8(sp)                # t1 = r1
lw t0, 12(sp)               # t0 = r2
MYANDI t0, t0, 31           # extract shift amount
beq t0, x0, 120f            # if shift by 0 rturn r1
MYSRL_SAFE \rd, t1, t0
beq x0, x0, 121f

120:
MYADD \rd, x0, t1

121:
sw \rd, 12(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 12(sp)
addi sp, sp, 16
.endm

.macro MYSRA rd, r1, r2
addi sp, sp, -16
sw t0, 0(sp)
sw t1, 4(sp)
sw \r1, 8(sp)
sw \r2, 12(sp)
lw t1, 8(sp)                # t1 = r1
lw t0, 12(sp)               # t0 = r2
MYANDI t0, t0, 31           # extract shift amount
beq t0, x0, 130f            # if shift by 0 rturn r1
MYSRA_SAFE \rd, t1, t0
beq x0, x0, 131f

130:
MYADD \rd, x0, t1

131:
sw \rd, 12(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 12(sp)
addi sp, sp, 16
.endm

# r1 shift left by 1 is the same as r1 * 2 (= r1 + r1)
# safe version for use in macro (does not need to extract lowest 5 bit first)
.macro MYSLLI_SAFE rd, r1, imm
addi sp, sp, -20
sw t0, 0(sp)
sw t1, 4(sp)                # t1 = loop exit condition
sw t2, 8(sp)                # t2 = loop variable i
sw t3, 12(sp)
sw \r1, 16(sp)
lw t3, 16(sp)               # t3 = r1, will become rd
sub t0, x0, t3              # t0 = -rd
MYADDI t1, x0, \imm         # t1 = imm
sub t2, x0, x0              # clear loop counter

140:
beq t2, t1, 141f            # loop end reached
sub t3, t3, t0              # rd-(-rd) => rd * 2
sub t0, x0, t3              # t0 = -rd, update value
MYADDI t2, t2, 1            # i++
beq x0, x0, 140b

141:
sw t3, 16(sp)              
lw t3, 12(sp)
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 16(sp)
addi sp, sp, 20
.endm

.macro MYSLL_SAFE rd, r1, r2
addi sp, sp, -24
sw t0, 0(sp)
sw t1, 4(sp)                # t1 = loop exit condition
sw t2, 8(sp)                # t2 = loop counter
sw t3, 12(sp)
sw \r1, 16(sp)
sw \r2, 20(sp)
lw t3, 16(sp)               # t3 = r1, will become rd
lw t1, 20(sp)               # t1 = r2
sub t2, x0, x0              # clear loop counter
sub t0, x0, t3              # t0 = -rd

150:
beq t2, t1, 151f
sub t3, t3, t0              # t3-(-t0)
sub t0, x0, t3              # update value of t0
MYADDI t2, t2, 1            # i++
beq x0, x0, 150b

151:
sw t3, 20(sp)
lw t3, 12(sp)
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 20(sp)
addi sp, sp, 24
.endm

# shift right by 1 is the same as a circular left shift by 31 (32 - 1)
.macro MYSRLI_SAFE rd, r1, imm
addi sp, sp, -28
sw t0, 0(sp)                # shifting r1
sw t1, 4(sp)                # loop bound
sw t2, 8(sp)                # loop variable i
sw t3, 12(sp)               # t3 will become rd
sw t4, 16(sp)               # msb eliminated r1
sw t5, 20(sp)               # msb of r1
sw \r1, 24(sp)
MYADDI t2, x0, \imm         # t2 = imm
MYADDI t1, x0, 32           # t1 = 32 - shift amount (imm)
sub t1, t1, t2              
sub t2, x0, x0              #clear loop variable
lw t0, 24(sp)               # t0 = r1
sub t3, x0, x0              # clear rd
lw t4, 24(sp)               # t4 = r1
MYSLLI_SAFE t4, t4, 1
srli t4, t4, 1              # msb eliminated

160:
beq t2, t1, 162f            # loop end condition
MYSLLI_SAFE t4, t4, 1
srli t4, t4, 1              # msb eliminated
MYSLLI_SAFE t3, t3, 1
sub t5, t0, t4              # t5 = msb
beq t5, x0, 161f            # msb = 0, don't do anything
MYADDI t3, t3, 1            # else add 1 to result

161:
MYADDI t2, t2, 1            # i++
MYSLLI_SAFE t0, t0, 1       # shift r1 by 1
MYSLLI_SAFE t4, t4, 1
beq x0, x0, 160b

162:
sw t3, 24(sp)
lw t5, 20(sp)               
lw t4, 16(sp)               
lw t3, 12(sp)
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 24(sp)
addi sp, sp, 28
.endm

.macro MYSRL_SAFE rd, r1, r2
addi sp, sp, -32
sw t0, 0(sp)                # shifting r1
sw t1, 4(sp)                # loop bound
sw t2, 8(sp)                # loop variable i
sw t3, 12(sp)               # t3 will become rd
sw t4, 16(sp)               # msb eliminated r1
sw t5, 20(sp)               # msb of r1
sw \r1, 24(sp)
sw \r2, 28(sp)
lw t0, 24(sp)               # t0 = r1
lw t4, 24(sp)               # t4 = r1
lw t2, 28(sp)               # t2 = r2
MYADDI t1, x0, 32           # t1 = 32
sub t1, t1, t2              # t1 = 32 - shift amount (r2)
sub t2, x0, x0              # clear loop variable
sub t3, x0, x0              # clear rd

170:
beq t2, t1, 172f            # loop end condition
MYSLLI_SAFE t4, t4, 1
MYSRLI_SAFE t4, t4, 1       # msb eliminated
MYSLLI_SAFE t3, t3, 1
sub t5, t0, t4              # t5 = msb
beq t5, x0, 171f            # msb = 0, don't do anything
MYADDI t3, t3, 1            # else add 1 to result

171:
MYADDI t2, t2, 1            # i++
MYSLLI_SAFE t0, t0, 1       # shift r1 by 1
MYSLLI_SAFE t4, t4, 1
beq x0, x0, 170b

172:
sw t3, 28(sp)
lw t5, 20(sp)               
lw t4, 16(sp) 
lw t3, 12(sp)
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 28(sp)
addi sp, sp, 32
.endm

# shift right arithmetic by 1 is also a left shift by 31 (32 - 1) but:
# first copy the msb for imm times
# then copy the remaining number (32-imm) times like in srli
.macro MYSRAI_SAFE rd, r1, imm
addi sp, sp, -28
sw t0, 0(sp)                # shifting r1
sw t1, 4(sp)                # loop bound
sw t2, 8(sp)                # loop variable i
sw t3, 12(sp)               # t3 will become rd
sw t4, 16(sp)               # msb eliminated r1
sw t5, 20(sp)               # msb of r1
sw \r1, 24(sp)
MYADDI t1, x0, \imm         # t1 = imm          
lw t0, 24(sp)               # t0 = r1
lw t4, 24(sp)               # t4 = r1
sub t2, x0, x0              # clear loop variable
sub t3, x0, x0              # clear rd
MYSLLI_SAFE t4, t4, 1
MYSRLI_SAFE t4, t4, 1       # msb eliminated
sub t5, t0, t4
lw t4, 24(sp)               # t4 = r1
beq t5, x0, 180f            # if msb == 0, add 0
MYADDI t5, x0, 1            # else add 1

# first loop, copy msb
180:
beq t2, t1, 181f            # loop end condition
MYSLLI_SAFE t3, t3, 1
MYADD t3, t3, t5            # add msb to result
MYADDI t2, t2, 1
beq x0, x0, 180b

181:
# prepare right loop ending condition
MYADDI t2, x0, 32
sub t1, t2, t1              # 32 - imm
sub t2, x0, x0              # t2 = 0, new loop counter

# second loop, copy content of r1
182:
beq t2, t1, 184f            # loop end condition
MYSLLI_SAFE t4, t4, 1
MYSRLI_SAFE t4, t4, 1       # msb eliminated
MYSLLI_SAFE t3, t3, 1
sub t5, t0, t4              # t5 = msb
beq t5, x0, 183f            # msb == 0, don't do anything
MYADDI t3, t3, 1            # else add 1

183:
MYADDI t2, t2, 1            # i++
MYSLLI_SAFE t0, t0, 1       # shift r1 by 1
MYSLLI_SAFE t4, t4, 1
beq x0, x0, 182b

184:
sw t3, 24(sp)
lw t5, 20(sp)               
lw t4, 16(sp) 
lw t3, 12(sp)
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 24(sp)
addi sp, sp, 28
.endm

.macro MYSRA_SAFE rd, r1, r2
addi sp, sp, -32
sw t0, 0(sp)                # shifting r1
sw t1, 4(sp)                # loop bound
sw t2, 8(sp)                # loop variable i
sw t3, 12(sp)               # t3 will become rd
sw t4, 16(sp)               # msb eliminated r1
sw t5, 20(sp)               # msb of r1
sw \r1, 24(sp)
sw \r2, 28(sp)
lw t1, 28(sp)               # t1 = r2
lw t0, 24(sp)               # t0 = r1
lw t4, 24(sp)               # t4 = r1
sub t2, x0, x0              # loop variable i
sub t3, x0, x0              # clear rd
MYSLLI_SAFE t4, t4, 1
MYSRLI_SAFE t4, t4, 1       # msb eliminated
sub t5, t0, t4              # msb
lw t4, 24(sp)               # t4 = r1
beq t5, x0, 190f            # if msb == 0, add 0
MYADDI t5, x0, 1            # else add 1

# first loop, copy msb
190:
beq t2, t1, 191f            #loop end condition
MYSLLI_SAFE t3, t3, 1
MYADD t3, t3, t5            # add msb to result
MYADDI t2, t2, 1
beq x0, x0, 190b

191:
# prepare right loop ending condition
MYADDI t2, x0, 32
sub t1, t2, t1              # 32 - r2
sub t2, x0, x0              # t2 = 0, new loop counter

# second loop, copy content of r1
192:
beq t2, t1, 194f            #loop end condition
MYSLLI_SAFE t4, t4, 1
MYSRLI_SAFE t4, t4, 1       # msb eliminated
MYSLLI_SAFE t3, t3, 1
sub t5, t0, t4              # t5 = msb
beq t5, x0, 193f            # msb = 0, don't do anything
MYADDI t3, t3, 1            # else add 1

193:
MYADDI t2, t2, 1            # i++
MYSLLI_SAFE t0, t0, 1       # shift r1 by 1
MYSLLI_SAFE t4, t4, 1
beq x0, x0, 192b

194:
sw t3, 28(sp)
lw t5, 20(sp)               
lw t4, 16(sp) 
lw t3, 12(sp)
lw t2, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 28(sp)
addi sp, sp, 32
.endm

# iterate through every bit of the numbers, extract MSBs and compare them
# check special cases, BEFORE overwriting temp registers (one of them may be r1 or r2)
.macro MYOR rd, r1, r2
beq \r1, x0, 207f           #r1 == 0, return r2
beq \r2, x0, 208f           #r2 == 0, return r1

addi sp, sp, -40
sw t3, 0(sp)                # shifting r1
sw t4, 4(sp)                # shifting r2
sw t5, 8(sp)                # msb eliminated r1 for comparison, also contains MSB sum
sw t6, 12(sp)               # msb eliminated r2 for comparison
sw t0, 16(sp)               # 1, for comparing MSBs
sw t1, 20(sp)               # loop variable i
sw t2, 24(sp)               # loop limit = 32   
sw s1, 28(sp)               # will be value for rd
sw \r1, 32(sp)
sw \r2, 36(sp)
lw t3, 32(sp)               # t3 = r1
lw t4, 36(sp)               # t4 = r2
MYADDI t0, x0, 1
sub t1, x0, x0
MYADDI t2, x0, 32
sub s1, x0, x0              # clean s1

200:
beq t1, t2, 209f            # loop limit reached when every bit compared
MYSLLI_SAFE s1, s1, 1       # shift rd left by one
MYSLLI_SAFE t5, t3, 1              
MYSRLI_SAFE t5, t5, 1       # MSB == 0
MYSLLI_SAFE t6, t4, 1              
MYSRLI_SAFE t6, t6, 1       # MSB == 0
sub t5, t3, t5              # extracted MSB of r1
MYBNE t5, x0, 203f
201:
sub t6, t4, t6              # extracted MSB of r2
MYBNE t6, x0, 204f
202:
MYADD t5, t5, t6            # MSB of r1 + MSB of r2
blt x0, t5, 205f            # sum has to be at least 1 (0|1; 1|0; 1|1)
beq x0, x0, 206f            # if not the case (0|0) shift to left to add 0

203:
MYADDI t5, x0, 1
beq x0, x0, 201b

204:
MYADDI t6, x0, 1
beq x0, x0, 202b

205:
MYADDI s1, s1, 1            # rd += 1

206:
MYADDI t1, t1, 1            # i++
MYSLLI_SAFE t3, t3, 1       # shift r1 by 1
MYSLLI_SAFE t4, t4, 1       # shift r2 by 1
beq x0, x0, 200b

207:                        # special case r1 == 0, return r2
sub \rd, x0, \r2
sub \rd, x0, \rd
beq x0, x0, 210f

208:                        # special case r2 == 0, return r1
sub \rd, x0, \r1
sub \rd, x0, \rd
beq x0, x0, 210f

209:
sw s1, 36(sp)
lw s1, 28(sp)
lw t2, 24(sp)              
lw t1, 20(sp)             
lw t0, 16(sp)
lw t6, 12(sp)
lw t5, 8(sp)
lw t4, 4(sp)
lw t3, 0(sp)
lw \rd, 36(sp)
addi sp, sp, 40

210:
.endm

.macro MYXOR rd, r1, r2
beq \r1, x0, 307f           #r1 == 0, return r2
beq \r2, x0, 308f           #r2 == 0, return r1

addi sp, sp, -40
sw t3, 0(sp)                # shifting r1
sw t4, 4(sp)                # shifting r2
sw t5, 8(sp)                # msb eliminated r1 for comparison, also contains MSB sum
sw t6, 12(sp)               # msb eliminated r2 for comparison
sw t0, 16(sp)               # 1, for comparing MSBs
sw t1, 20(sp)               # loop variable i
sw t2, 24(sp)               # loop limit = 32   
sw s1, 28(sp)               # will be value for rd
sw \r1, 32(sp)
sw \r2, 36(sp)
lw t3, 32(sp)               # t3 = r1
lw t4, 36(sp)               # t4 = r2
MYADDI t0, x0, 1
sub t1, x0, x0
MYADDI t2, x0, 32
sub s1, x0, x0              # clean rd for result

300:
beq t1, t2, 309f            # loop limit reached when each bit compared
MYSLLI_SAFE s1, s1, 1       # shift rd left by one
MYSLLI_SAFE t5, t3, 1              
MYSRLI_SAFE t5, t5, 1       # MSB == 0
MYSLLI_SAFE t6, t4, 1              
MYSRLI_SAFE t6, t6, 1       # MSB == 0
sub t5, t3, t5              # extracted MSB of r1
MYBNE t5, x0, 303f
301:
sub t6, t4, t6              # extracted MSB of r2
MYBNE t6, x0, 304f
302:
MYADD t5, t5, t6            # MSB of r1 + MSB of r2
beq t5, t0, 305f            # sum has to be exactly 1 (0^1; 1^0)
beq x0, x0, 306f            # if not the case (0^0; 1^1) shift to left to MYADD 0

303:
MYADDI t5, x0, 1
beq x0, x0, 301b

304:
MYADDI t6, x0, 1
beq x0, x0, 302b

305:
MYADDI s1, s1, 1            # rd += 1

306:
MYADDI t1, t1, 1            # i++
MYSLLI_SAFE t3, t3, 1       # shift r1 by 1
MYSLLI_SAFE t4, t4, 1       # shift r2 by 1
beq x0, x0, 300b            # loop again

307:                        # special case r1 == 0, return r2
sub \rd, x0, \r2
sub \rd, x0, \rd
beq x0, x0, 310f

308:                        # special case r2 == 0, return r1
sub \rd, x0, \r1
sub \rd, x0, \rd
beq x0, x0, 310f

309:
sw s1, 36(sp)
lw s1, 28(sp)
lw t2, 24(sp)              
lw t1, 20(sp)             
lw t0, 16(sp)
lw t6, 12(sp)
lw t5, 8(sp)
lw t4, 4(sp)
lw t3, 0(sp)
lw \rd, 36(sp)
addi sp, sp, 40

310:
.endm

.macro MYAND rd, r1, r2
beq \r1, x0, 407f           #r1 or r2 == 0, return 0
beq \r2, x0, 407f

addi sp, sp, -40
sw t3, 0(sp)                # shifting r1
sw t4, 4(sp)                # shifting r2
sw t5, 8(sp)                # msb eliminated r1 for comparison, also contains MSB sum
sw t6, 12(sp)               # msb eliminated r2 for comparison
sw t0, 16(sp)               # 1, for comparing MSBs
sw t1, 20(sp)               # loop variable i
sw t2, 24(sp)               # loop limit = 32   
sw s1, 28(sp)               # will be value for rd     
sw \r1, 32(sp)
sw \r2, 36(sp)
lw t3, 32(sp)               # t3 = r1
lw t4, 36(sp)               # t4 = r2
MYADDI t0, x0, 2
sub t1, x0, x0
MYADDI t2, x0, 32
sub s1, x0, x0

400:
beq t1, t2, 408f            # loop limit reached, compared each bit
MYSLLI_SAFE s1, s1, 1       # shift rd left by one
MYSLLI_SAFE t5, t3, 1              
MYSRLI_SAFE t5, t5, 1       # MSB = 0
MYSLLI_SAFE t6, t4, 1
MYSRLI_SAFE t6, t6, 1       # MSB = 0
sub t5, t3, t5              # extracted MSB of r1
MYBNE t5, x0, 403f
401:
sub t6, t4, t6              # extracted MSB of r2
MYBNE t6, x0, 404f
402:
MYADD t5, t5, t6            # MSB of r1 + MSB of r2
beq t5, t0, 405f            # sum has to be exactly 2 (1&1)
beq x0, x0, 406f            # if not the case (0&0; 0&1; 1&0) shift left to MYADD 0

403:
MYADDI t5, x0, 1
beq x0, x0, 401b

404:
MYADDI t6, x0, 1
beq x0, x0, 402b

405:
MYADDI s1, s1, 1

406:
MYADDI t1, t1, 1
MYSLLI_SAFE t3, t3, 1 
MYSLLI_SAFE t4, t4, 1
beq x0, x0, 400b

407:                         
sub \rd, x0, x0             # return 0
beq x0, x0, 409f

408:
sw s1, 36(sp)
lw s1, 28(sp)
lw t2, 24(sp)              
lw t1, 20(sp)             
lw t0, 16(sp)
lw t6, 12(sp)
lw t5, 8(sp)
lw t4, 4(sp)
lw t3, 0(sp)
lw \rd, 36(sp)
addi sp, sp, 40

409:
.endm

.macro MYXORI rd, r1, imm
addi sp, sp, -12
sw t0, 0(sp)
sw t1, 4(sp)
sub t1, x0, \r1             # t1 = -r1
sub t1, x0, t1              # t1 = r1
MYADDI t0, x0, \imm         # t0 = imm
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
sub t1, x0, \r1             # t1 = -r1
sub t1, x0, t1              # t1 = r1
MYADDI t0, x0, \imm         # t0 = imm
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
sub t1, x0, \r1             # t1 = -r1
sub t1, x0, t1              # t1 = r1
MYADDI t0, x0, \imm         # t0 = imm
MYAND \rd, t1, t0
sw \rd, 8(sp)
lw t1, 4(sp)
lw t0, 0(sp)
lw \rd, 8(sp)
addi sp, sp, 12
.endm