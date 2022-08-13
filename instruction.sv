// instruction.sv
// base instruction class
//
// Collaborator: Kyle Eichenberger (keich2@pdx.edu)
// Collaborator: Gage Elerding (elerding@pdx.edu)
// Collaborator: Maddie Klementyn (muk2@pdx.edu) 
// Collaborator: John Samwel (samwel@pdx.edu)
//
// Description:
// defines base instruction type to be inherited by R / I types

class instruction;

    operation_t opcode;
    logic [reg_width-1:0] rs, rt, rd;
    logic [instr_width-1:0] rs_val, rt_val, rd_val;
    logic signed [imm_width-1:0] imm;
    string fmt;

     function new(logic [instr_width-1:0] inst, string format);

        logic [instr_width-1-3*reg_width-op_width:0] unused;
        {this.opcode, this.rs, this.rt, this.rd, unused} = inst;
        this.imm = inst[imm_width-1:0];

        this.fmt = format;
        // display_inst();

     endfunction : new

    function void display_inst();
        case (fmt)
            "r" : begin
                $display("---INST OBJECT---");
                $display("Op: %6s", opcode.name);
                $display("rs: %2d | Value: 0x%0h", rs, rs_val);
                $display("rt: %2d | Value: 0x%0h", rt, rt_val);
                $display("rd: %2d | Value: 0x%0h", rd, rd_val);
            end

            "i" : begin
                $display("---INST OBJECT---");
                $display("Op: %6s", opcode.name);
                $display("rs: %2d | Value: 0x%0h", rs, rs_val);
                $display("rt: %2d | Value: 0x%0h", rt, rt_val);
                $display("Imm: 0x%0h", imm);
            end
        endcase
    endfunction : display_inst

    function void display_short();
        case (fmt)
            "r" : begin
                $display("    %6s rs=%2d rt=%2d rd=%2d", opcode, rs, rt, rd);
            end

            "i" : begin
                $display("    %6s rs=%2d rt=%2d", opcode, rs, rt);
            end
        endcase
        
    endfunction : display_short

endclass : instruction
