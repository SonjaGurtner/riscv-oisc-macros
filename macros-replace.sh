#!/bin/bash

#.S file to be replaced
MYFILE=$1
filename=$(basename "${MYFILE}")

#copy file and replace all instructions with the macro names, order of instructios matters
cp ${MYFILE} temp.S
sed -i \
-e "s/\<addi\>/MYADDI/Ig" \
-e "s/\<add\>/MYADD/Ig" \
-e "s/\<ori\>/MYORI/Ig" \
-e "s/\<or\>/MYOR/Ig" \
-e "s/\<xori\>/MYXORI/Ig" \
-e "s/\<xor\>/MYXOR/Ig" \
-e "s/\<andi\>/MYANDI/Ig" \
-e "s/\<and\>/MYAND/Ig" \
-e "s/\<bgeu\>/MYBGEU/Ig" \
-e "s/\<bge\>/MYBGE/Ig" \
-e "s/\<bne\>/MYBNE/Ig" \
-e "s/\<bltu\>/MYBLTU/Ig" \
-e "s/\<sltiu\>/MYSLTIU/Ig" \
-e "s/\<slti\>/MYSLTI/Ig" \
-e "s/\<sltu\>/MYSLTU/Ig" \
-e "s/\<slt\>/MYSLT/Ig" \
-e "s/\<slli\>/MYSLLI/Ig" \
-e "s/\<sll\>/MYSLL/Ig" \
-e "s/\<jal\>/MYJAL/Ig" \
temp.S

#copy new instruction macros and replaced program into new file
cat riscv-container/OISC/all_macros/macros.S temp.S > ${filename}-new.S

#cleanup temp file
rm temp.S