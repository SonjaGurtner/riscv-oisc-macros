.globl _start
.equ SYSCALL_ADDR, 0x02010000

.macro SYS_EXIT, exit_code
li   a7, 93
li   a0, \exit_code
li   t0, SYSCALL_ADDR
csrr a6, mhartid
sw   a6, 0(t0)
.endm


# program entry-point
_start:

addi s2, x0, 0		    #fib1 = 0
addi s3, x0, 1          #fib2 = 1
addi a1, x0, 0          #return val
addi t2, x0, 0		    #loop counter
addi t0, x0, 7		    #loop limit

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
# call exit (SYS_EXIT=93) with exit code 0 (argument in a0)
SYS_EXIT 0
