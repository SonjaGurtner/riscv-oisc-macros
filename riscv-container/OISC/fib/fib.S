.globl _start
.equ SYSCALL_ADDR, 0x02010000

.macro SYS_EXIT, exit_code
li   a7, 93
li   a0, \exit_code
li   t0, SYSCALL_ADDR
csrr a6, mhartid
sw   a6, 0(t0)
.endm

.macro MYSSLI, rd, r1, imm
# shift by 1 means * 2 (=add to itself)
#save t3, used for storing -rd for the multiplication
#save t4, t4 will be loop counter
#save t5, loop variable i
addi t4, x0, \imm
addi t5, x0, 0              # loop variable i
add \rd, x0, \r1            # rd = r1
sub t3, x0, \rd             #t3 = -rd

slli_loop:
beq t5, t4, slli_end        #loop end condition
sub \rd, \rd, t3            #rd - (-rd) => rd*2
sub t3, x0, \rd             #t3 = -rd
addi t5, t5, 1              #i++
j slli_loop

slli_end:
#restore t3
#restore t4
#restore t5
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
#mv s2, s3
#mv s3, a1
ori s2, s3, 0       	#copy value
xori s3, a1, 0	    	#keep value		
addi t2, t2, 1	    	#t2++
j loopstart	        

end:
MYSSLI s4, a1, 1          # shift by 1 => ai * 2, for testing purposes
# call exit (SYS_EXIT=93) with exit code 0 (argument in a0)
SYS_EXIT 0
