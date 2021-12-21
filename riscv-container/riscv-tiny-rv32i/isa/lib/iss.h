#ifndef RISCV_ISA_ISS_H
#define RISCV_ISA_ISS_H

#include <stdint.h>
#include <string.h>
#include <assert.h>

#include <iostream>
#include <iomanip>
#include <stdexcept>

#include "instr.h"


#define SYS_exit 93


struct RegFile {
    enum {
        NUM_REGS = 32
    };

    int32_t regs[NUM_REGS];

    RegFile() {
        memset(regs, 0, sizeof(regs));
    }

    RegFile(const RegFile &other) {
        memcpy(regs, other.regs, sizeof(regs));
    }

    void write(uint32_t index, int32_t value) {
        assert (index <= x31);
        assert (index != x0);
        regs[index] = value;
    }

    int32_t read(uint32_t index) {
        assert (index <= x31);
        return regs[index];
    }

    uint32_t shamt(uint32_t index) {
        assert (index <= x31);
        return BIT_RANGE(regs[index], 4, 0);
    }

    int32_t &operator [](const uint32_t idx) {
        return regs[idx];
    }

    void show() {
        for (int i=0; i<NUM_REGS; ++i) {
            std::cout << "r[" << i << "] = " << regs[i] << std::endl;
        }
    }

    enum e {
        x0 = 0,
        x1,
        x2,
        x3,
        x4,
        x5,
        x6,
        x7,
        x8,
        x9,
        x10,
        x11,
        x12,
        x13,
        x14,
        x15,
        x16,
        x17,
        x18,
        x19,
        x20,
        x21,
        x22,
        x23,
        x24,
        x25,
        x26,
        x27,
        x28,
        x29,
        x30,
        x31,

        zero = x0,
        ra = x1,
        sp = x2,
        gp = x3,
        tp = x4,
        t0 = x5,
        t1 = x6,
        t2 = x7,
        s0 = x8,
        fp = x8,
        s1 = x9,
        a0 = x10,
        a1 = x11,
        a2 = x12,
        a3 = x13,
        a4 = x14,
        a5 = x15,
        a6 = x16,
        a7 = x17,
        s2 = x18,
        s3 = x19,
        s4 = x20,
        s5 = x21,
        s6 = x22,
        s7 = x23,
        s8 = x24,
        s9 = x25,
        s10 = x26,
        s11 = x27,
        t3 = x28,
        t4 = x29,
        t5 = x30,
        t6 = x31,
    };
};



struct Memory {
    uint8_t *data;
    uint32_t size;

    Memory(uint32_t size)
            : data(new uint8_t[size]()), size(size) {
    }

    ~Memory() {
        delete[] data;
        data = 0;
    }


    void load(uint32_t addr, uint8_t *bytes, size_t len) {
        assert (addr + len <= size && "memory out of bounds");
        memcpy(bytes, data+addr, len);
    }

    void store(uint32_t addr, const uint8_t *bytes, size_t len) {
        assert (addr + len <= size && "memory out of bounds");
        memcpy(data+addr, bytes, len);
    }

    template <typename T>
    inline T _load_data(uint32_t addr) {
        T ans;
        load(addr, (uint8_t*)&ans, sizeof(T));
        return ans;
    }

    template <typename T>
    inline void _store_data(uint32_t addr, T value) {
        store(addr, reinterpret_cast<uint8_t *>(&value), sizeof(T));
    }

    /*  interface to the ISS */

    int32_t load_word(uint32_t addr) { return _load_data<int32_t>(addr); }
    int32_t load_half(uint32_t addr) { return _load_data<int16_t>(addr); }
    int32_t load_byte(uint32_t addr) { return _load_data<int8_t>(addr); }
    uint32_t load_uhalf(uint32_t addr) { return _load_data<uint16_t>(addr); }
    uint32_t load_ubyte(uint32_t addr) { return _load_data<uint8_t>(addr); }

    void store_word(uint32_t addr, uint32_t value) { _store_data(addr, value); }
    void store_half(uint32_t addr, uint16_t value) { _store_data(addr, value); }
    void store_byte(uint32_t addr, uint8_t value) { _store_data(addr, value); }
};



namespace Opcode {
    enum parts {
        OP_LUI    = 0b0110111,
        OP_AUIPC  = 0b0010111,
        OP_JAL    = 0b1101111,
        OP_JALR   = 0b1100111,
        F3_JALR   = 0b000,

        OP_LB     = 0b0000011,
        F3_LB     = 0b000,
        F3_LH     = 0b001,
        F3_LW     = 0b010,
        F3_LBU    = 0b100,
        F3_LHU    = 0b101,

        OP_SB     = 0b0100011,
        F3_SB     = 0b000,
        F3_SH     = 0b001,
        F3_SW     = 0b010,

        OP_BEQ    = 0b1100011,
        F3_BEQ    = 0b000,
        F3_BNE    = 0b001,
        F3_BLT    = 0b100,
        F3_BGE    = 0b101,
        F3_BLTU   = 0b110,
        F3_BGEU   = 0b111,

        OP_ADDI   = 0b0010011,
        F3_ADDI   = 0b000,
        F3_SLTI   = 0b010,
        F3_SLTIU  = 0b011,
        F3_XORI   = 0b100,
        F3_ORI    = 0b110,
        F3_ANDI   = 0b111,
        F3_SLLI   = 0b001,
        F3_SRLI   = 0b101,
        F7_SRLI   = 0b0000000,
        F7_SRAI   = 0b0100000,

        OP_ADD    = 0b0110011,
        F7_ADD    = 0b0000000,
        F7_SUB    = 0b0100000,
        F3_ADD    = 0b000,
        F3_SUB    = 0b000,
        F3_SLL    = 0b001,
        F3_SLT    = 0b010,
        F3_SLTU   = 0b011,
        F3_XOR    = 0b100,
        F3_SRL    = 0b101,
        F3_SRA    = 0b101,
        F3_OR     = 0b110,
        F3_AND    = 0b111,

        F7_MUL    = 0b0000001,
        F3_MUL    = 0b000,
        F3_MULH   = 0b001,
        F3_MULHSU = 0b010,
        F3_MULHU  = 0b011,
        F3_DIV    = 0b100,
        F3_DIVU   = 0b101,
        F3_REM    = 0b110,
        F3_REMU   = 0b111,

        OP_ECALL   = 0b1110011,
        F3_SYS     = 0b000,
        F12_ECALL  = 0b000000000000,
        F12_EBREAK = 0b000000000001,
        //begin:privileged-instructions
        F12_URET   = 0b000000000010,
        F12_SRET   = 0b000100000010,
        F12_MRET   = 0b001100000010,
        F12_WFI    = 0b000100000101,
        F7_SFENCE_VMA = 0b0001001,
        //end:privileged-instructions
        F3_CSRRW   = 0b001,
        F3_CSRRS   = 0b010,
        F3_CSRRC   = 0b011,
        F3_CSRRWI  = 0b101,
        F3_CSRRSI  = 0b110,
        F3_CSRRCI  = 0b111,

        OP_AMO        = 0b0101111,
        F5_LR_W       = 0b00010,
        F5_SC_W       = 0b00011,
        F5_AMOSWAP_W  = 0b00001,
        F5_AMOADD_W   = 0b00000,
        F5_AMOXOR_W   = 0b00100,
        F5_AMOAND_W   = 0b01100,
        F5_AMOOR_W    = 0b01000,
        F5_AMOMIN_W   = 0b10000,
        F5_AMOMAX_W   = 0b10100,
        F5_AMOMINU_W  = 0b11000,
        F5_AMOMAXU_W  = 0b11100,
    };

    enum mapping {
        UNDEF = 0,

        // RV32I Base Instruction Set
        LUI = 1,
        AUIPC,
        JAL,
        JALR,
        BEQ,
        BNE,
        BLT,
        BGE,
        BLTU,
        BGEU,
        LB,
        LH,
        LW,
        LBU,
        LHU,
        SB,
        SH,
        SW,
        ADDI,
        SLTI,
        SLTIU,
        XORI,
        ORI,
        ANDI,
        SLLI,
        SRLI,
        SRAI,
        ADD,
        SUB,
        SLL,
        SLT,
        SLTU,
        XOR,
        SRL,
        SRA,
        OR,
        AND,
        ECALL,
        EBREAK,
        CSRRW,
        CSRRS,
        CSRRC,
        CSRRWI,
        CSRRSI,
        CSRRCI,

        // RV32M Standard Extension
        MUL,
        MULH,
        MULHSU,
        MULHU,
        DIV,
        DIVU,
        REM,
        REMU,
    };
}



struct ISS {
    Memory *mem = 0;
    RegFile regs;
    uint32_t pc;
    uint32_t last_pc;
    bool shall_exit = false;

    enum {
        REG_MIN = INT32_MIN,
    };


    Opcode::mapping decode(Instruction &instr) {
        using namespace Opcode;

        switch (instr.opcode()) {
            case OP_LUI:
                return Opcode::LUI;

            case OP_AUIPC:
                return Opcode::AUIPC;

            case OP_JAL:
                return Opcode::JAL;

            case OP_JALR: {
                assert (instr.funct3() == F3_JALR);
                return Opcode::JALR;
            }

            case OP_BEQ: {
                switch (instr.funct3()) {
                    case F3_BEQ:
                        return BEQ;
                    case F3_BNE:
                        return BNE;
                    case F3_BLT:
                        return BLT;
                    case F3_BGE:
                        return BGE;
                    case F3_BLTU:
                        return BLTU;
                    case F3_BGEU:
                        return BGEU;
                }
                break;
            }

            case OP_LB: {
                switch (instr.funct3()) {
                    case F3_LB:
                        return LB;
                    case F3_LH:
                        return LH;
                    case F3_LW:
                        return LW;
                    case F3_LBU:
                        return LBU;
                    case F3_LHU:
                        return LHU;
                }
                break;
            }

            case OP_SB: {
                switch (instr.funct3()) {
                    case F3_SB:
                        return SB;
                    case F3_SH:
                        return SH;
                    case F3_SW:
                        return SW;
                }
                break;
            }

            case OP_ADDI: {
                switch (instr.funct3()) {
                    case F3_ADDI:
                        return ADDI;
                    case F3_SLTI:
                        return SLTI;
                    case F3_SLTIU:
                        return SLTIU;
                    case F3_XORI:
                        return XORI;
                    case F3_ORI:
                        return ORI;
                    case F3_ANDI:
                        return ANDI;
                    case F3_SLLI:
                        return SLLI;
                    case F3_SRLI: {
                        switch (instr.funct7()) {
                            case F7_SRLI:
                                return SRLI;
                            case F7_SRAI:
                                return SRAI;
                        }
                    }
                }
                break;
            }

            case OP_ADD: {
                switch (instr.funct7()) {
                    case F7_ADD:
                        switch (instr.funct3()) {
                            case F3_ADD:
                                return ADD;
                            case F3_SLL:
                                return SLL;
                            case F3_SLT:
                                return SLT;
                            case F3_SLTU:
                                return SLTU;
                            case F3_XOR:
                                return XOR;
                            case F3_SRL:
                                return SRL;
                            case F3_OR:
                                return OR;
                            case F3_AND:
                                return AND;
                        }
                        break;

                    case F7_SUB:
                        switch (instr.funct3()) {
                            case F3_SUB:
                                return SUB;
                            case F3_SRA:
                                return SRA;
                        }
                        break;

                    case F7_MUL:
                        switch (instr.funct3()) {
                            case F3_MUL:
                                return MUL;
                            case F3_MULH:
                                return MULH;
                            case F3_MULHSU:
                                return MULHSU;
                            case F3_MULHU:
                                return MULHU;
                            case F3_DIV:
                                return DIV;
                            case F3_DIVU:
                                return DIVU;
                            case F3_REM:
                                return REM;
                            case F3_REMU:
                                return REMU;
                        }
                        break;
                }
                break;
            }

            case OP_ECALL: {
                switch (instr.funct3()) {
                    case F3_SYS: {
                        switch (instr.funct12()) {
                            case F12_ECALL:
                                return ECALL;
                            case F12_EBREAK:
                                return EBREAK;
                        }
                        break;
                    }
                    case F3_CSRRW:
                        return CSRRW;
                    case F3_CSRRS:
                        return CSRRS;
                    case F3_CSRRC:
                        return CSRRC;
                    case F3_CSRRWI:
                        return CSRRWI;
                    case F3_CSRRSI:
                        return CSRRSI;
                    case F3_CSRRCI:
                        return CSRRCI;
                }
                break;
            }
        }

        throw std::runtime_error("unknown instruction");
    }

    void run_step() {
        auto mem_word = mem->load_word(pc);
        Instruction instr(mem_word);
        auto op = decode(instr);
        pc += 4;

        switch (op) {
            case Opcode::ADDI:
                regs[instr.rd()] = regs[instr.rs1()] + instr.I_imm();
                break;

            case Opcode::ADD:
                regs[instr.rd()] = regs[instr.rs1()] + regs[instr.rs2()];
                break;

            case Opcode::LUI:
                regs[instr.rd()] = instr.U_imm();
                break;
                
            case Opcode::AUIPC:
                regs[instr.rd()] = last_pc + instr.U_imm();
                break;

            case Opcode::JAL:
                if (instr.rd() != RegFile::zero)
                    regs[instr.rd()] = pc;
                pc = last_pc + instr.J_imm();
                break;

            case Opcode::JALR: {
                uint32_t link = pc;
                pc = (regs[instr.rs1()] + instr.I_imm()) & ~1;
                if (instr.rd() != RegFile::zero)
                    regs[instr.rd()] = link;
            }
                break;

            case Opcode::SW: {
                uint32_t addr = regs[instr.rs1()] + instr.S_imm();
                mem->store_word(addr, regs[instr.rs2()]);
            }
                break;

            case Opcode::LW: {
                uint32_t addr = regs[instr.rs1()] + instr.I_imm();
                regs[instr.rd()] = mem->load_word(addr);
            }
                break;

            case Opcode::BLT:
                if (regs[instr.rs1()] < regs[instr.rs2()])
                    pc = last_pc + instr.B_imm();
                break;
                
            case Opcode::ECALL: {
            	auto syscall = regs[RegFile::a7];
            	switch (syscall) {
            		case SYS_exit:
            			std::cout << "syscall exit(" << regs[RegFile::a0] << ")" << std::endl;
            			shall_exit = true;
            			break;
            			
            		default:
            			throw std::runtime_error("unknown syscall " + std::to_string(syscall));
            	}
            	break;
            }

            default:
            	throw std::runtime_error("unknown (or unimplemented) opcode " + std::to_string(op));
        }
        
        // zero register is hardwired to zero value
        regs[RegFile::zero] = 0;
    }


    void init(Memory *mem, uint32_t entrypoint, uint32_t sp) {
        this->mem = mem;
        regs[RegFile::sp] = sp;
        pc = entrypoint;
    }

    void run() {
        assert(mem); // check that memory has been provided

        do {
            last_pc = pc;
            run_step();
        } while (!shall_exit);
    }

    void show() {
        regs.show();
        std::cout << "pc = 0x" << std::hex << pc << std::endl;
    }
};


#endif //RISCV_ISA_ISS_H
