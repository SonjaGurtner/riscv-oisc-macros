#!/bin/bash

#.S file into which macros should be copied
MYFILE=$1

#copy new instruction macros into file
cat /home/sonja/GitHub/riscv-oisc-macros/riscv-container/OISC/all_macros/macros.S ${MYFILE} > /tmp/temp2.S
mv /tmp/temp2.S ${MYFILE}