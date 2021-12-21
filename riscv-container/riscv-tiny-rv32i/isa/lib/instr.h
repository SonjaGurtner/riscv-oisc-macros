#ifndef RISCV_ISA_INSTR_H
#define RISCV_ISA_INSTR_H

#include <stdint.h>


#define BIT_RANGE(instr,upper,lower) (instr & (((1 << (upper-lower+1)) - 1) << lower))
#define BIT_SINGLE(instr,pos) (instr & (1 << pos))


struct Instruction {
    Instruction(uint32_t instr)
            : instr(instr) {
    }

    inline uint32_t csr() {
        return BIT_RANGE(instr, 31, 20) >> 20;
    }

    inline uint32_t zimm() {
        return BIT_RANGE(instr, 19, 15) >> 15;
    }

    inline uint32_t shamt() {
        return (BIT_RANGE(instr, 24, 20) >> 20);
    }

    inline int32_t funct3() {
        return (BIT_RANGE(instr, 14, 12) >> 12);
    }

    inline int32_t funct12() {
        // cast to unsigned to avoid sign extension when shifting
        return (BIT_RANGE((uint32_t)instr, 31, 20) >> 20);
    }

    inline int32_t funct7() {
        // cast to unsigned to avoid sign extension when shifting
        return (BIT_RANGE((uint32_t)instr, 31, 25) >> 25);
    }

    inline int32_t funct5() {
        // cast to unsigned to avoid sign extension when shifting
        return (BIT_RANGE((uint32_t)instr, 31, 27) >> 27);
    }

    inline bool aq() {
        return BIT_SINGLE(instr, 26);
    }

    inline bool rl() {
        return BIT_SINGLE(instr, 25);
    }

    inline int32_t opcode() {
        return BIT_RANGE(instr, 6, 0);
    }


    inline int32_t J_imm() {
        return (BIT_SINGLE(instr,31) >> 11) | BIT_RANGE(instr,19,12) | (BIT_SINGLE(instr,20) >> 9) | (BIT_RANGE(instr,30,21) >> 20);
    }

    inline int32_t I_imm() {
        return BIT_RANGE(instr,31,20) >> 20;
    }

    inline int32_t S_imm() {
        return (BIT_RANGE(instr,31,25) >> 20) | (BIT_RANGE(instr,11,7) >> 7);
    }

    inline int32_t B_imm() {
        return (BIT_SINGLE(instr,31) >> 19) | (BIT_SINGLE(instr,7) << 4) | (BIT_RANGE(instr,30,25) >> 20) | (BIT_RANGE(instr,11,8) >> 7);
    }

    inline int32_t U_imm() {
        return BIT_RANGE(instr,31,12);
    }


    inline uint32_t rs1() {
        return (instr & (((1 << 5) - 1) << 15)) >> 15;
    }

    inline uint32_t rs2() {
        return (instr & (((1 << 5) - 1) << 20)) >> 20;
    }

    inline uint32_t rd() {
        return (instr & (((1 << 5) - 1) << 7)) >> 7;
    }

private:
    // use signed variable to have correct sign extension in immediates
    int32_t instr;
};


#endif //RISCV_ISA_INSTR_H
