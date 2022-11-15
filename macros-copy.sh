#!/bin/bash

SCRIPT=$(realpath "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
#file into which macros should be copied
MYFILE=$1

#copy new instruction macros into file
cat ${SCRIPTPATH}/riscv-container/OISC/all_macros/macros.S ${MYFILE} > /tmp/temp2.S
mv /tmp/temp2.S ${MYFILE}