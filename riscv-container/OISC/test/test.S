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