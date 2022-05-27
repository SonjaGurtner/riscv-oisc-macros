#!/bin/bash

#.S file to be replaced
MYFILE=$1
filename=$(basename "${MYFILE}")

#copy file and replace all instructions with the macro names, order of instructios matters
cp ${MYFILE} temp.S
sed -i \
-e "/[sS][pP]/b; /[xX]2/b; s/\<addi\>/MYADDI/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<add\>/MYADD/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<ori\>/MYORI/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<or\>/MYOR/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<xori\>/MYXORI/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<xor\>/MYXOR/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<andi\>/MYANDI/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<and\>/MYAND/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<bgeu\>/MYBGEU/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<bge\>/MYBGE/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<bne\>/MYBNE/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<bltu\>/MYBLTU/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<sltiu\>/MYSLTIU/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<slti\>/MYSLTI/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<sltu\>/MYSLTU/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<slt\>/MYSLT/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<slli\>/MYSLLI/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<sll\>/MYSLL/Ig" \
-e "/[sS][pP]/b; /[xX]2/b; s/\<jal\>/MYJAL/Ig" \
temp.S

#copy new instruction macros and replaced program into new file
cat riscv-container/OISC/all_macros/macros.S temp.S > ${filename}-new.S

#cleanup temp file
rm temp.S