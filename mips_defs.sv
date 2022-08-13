// defs.sv
// definitions file for ece586 pipeline project
//
// Collaborator: Kyle Eichenberger (keich2@pdx.edu)
// Collaborator: Gage Elerding (elerding@pdx.edu)
// Collaborator: Maddie Klementyn (muk2@pdx.edu) 
// Collaborator: John Samwel (samwel@pdx.edu)
//
// Description:
// Package file containing definitions related to the design

package mips_defs;
    parameter instr_width = 32;
    parameter op_width = 6;
    parameter reg_width = 5;
    parameter imm_width = 16;

    parameter pipeline_width = 5;

    typedef enum bit [op_width-1:0] {
        // arithmetic
        ADD = 6'b000000,
        ADDI= 6'b000001,
        SUB = 6'b000010,
        SUBI= 6'b000011,
        MUL = 6'b000100,
        MULI= 6'b000101,
        // logical
        OR  = 6'b000110,
        ORI = 6'b000111,
        AND = 6'b001000,
        ANDI= 6'b001001,
        XOR = 6'b001010,
        XORI= 6'b001011,
        // memory access
        LDW = 6'b001100,
        STW = 6'b001101,
        // control flow
        BZ  = 6'b001110,
        BEQ = 6'b001111,
        JR  = 6'b010000,
        HALT= 6'b010001,
        NOP = 6'b111111
    } operation_t;

    typedef struct {
        logic signed [31:0] data [0:1023];
        logic modified [0:1023];
    } memory_t;

    typedef struct {
        int n_inst;
        int n_arith;
        int n_log;
        int n_mem;
        int n_ctrl;
        int n_stalls;
        int n_hazards;
        int n_mispredicts;
    } stats_t;

    typedef class instruction;

    typedef struct {
        instruction F;
        instruction D;
        instruction E;
        instruction M;
        instruction W;
    } pipeline_t;

    `include "mips_simulator.sv"
    `include "instruction.sv"

endpackage : mips_defs
