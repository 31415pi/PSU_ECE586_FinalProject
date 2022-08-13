// mips_simulator.sv
// Class that holds current architectural state
//
// Collaborator: Kyle Eichenberger (keich2@pdx.edu)
// Collaborator: Gage Elerding (elerding@pdx.edu)
// Collaborator: Maddie Klementyn (muk2@pdx.edu) 
// Collaborator: John Samwel (samwel@pdx.edu)
//
// Detailed Description:
// Includes methods for each inst, which are called via the execute_inst function
// Timing details handled in the handle_pipeline function

class mips_simulator;
    // architectural state data
    logic signed [31:0] pc;
    logic [31:0] current_inst;
    logic signed [31:0] gpr [31:0];

    // instruction object to hold data for current inst. used primarily for timing info
    instruction current_inst_obj;

    // included R0, which is hardcoded to 0 at all times
    // halt flag
    logic halt;
    // hazard flags
    int fwd, dbg, timing;

    // 4kB mem image
    memory_t mem;

    // holds stats regarding isntruction counts, cycles, etc
    stats_t stats;

    // holds current opcode
    operation_t op;

    // unpacked array of instruction handles
    // FETCH / DECODE / EXE / MEM / WRITEBACK
    pipeline_t pipeline;

    // holds inst format ("r" or "i", or "n" for our nop/stall instruction)
    string fmt;

    // num cycles for timing sim
    int cycles;
    
    // file variables
    string filename;
    string line;

    // tmp / iterators
    int tmp,j,fd;

    // stall tracks num stalls needed for a given instruction, flush indicates whether a given branch will mispredict
    int stall, flush;

    // placeholders for src/dest regs, immediates in instruction exec
    logic [reg_width-1:0] rs, rt, rd;
    logic signed [imm_width-1:0] imm;
    logic [instr_width-1-3*reg_width-op_width:0] unused;

    // take in arguments to modify behavior, initialize values
    function new(string filename, int fwd_in, dbg_in, timing_in);

        // Set Plusarg values
        this.fwd = fwd_in;
        this.dbg = dbg_in;
        this.timing = timing_in;

        // Init Arch State
        this.pc = '0;
       
        // Init mem to 0
        for (int i = 0; i < 1024; i++) begin
            this.mem.data[i] = '0;
            this.mem.modified[i] = 0;
        end
        
        // init gpr's to 0
        for (int i = 0; i < 32; i++) begin
            this.gpr[i] = '0;
        end

        // init stats
        stats.n_inst = 0;
        stats.n_arith = 0;
        stats.n_log = 0;
        stats.n_mem = 0;
        stats.n_ctrl = 0;
        stats.n_stalls = 0;
        stats.n_hazards = 0;
        stats.n_mispredicts = 0;

        // Set halt / stall flags to 0
        halt = 1'b0;
        stall = 0;

        // open mem image file
        fd = $fopen(filename, "r");

        if (!fd) $fatal("File not opened successfully! Check filename/path");

        j = 0;

        // read mem image into simulator mem
        while (!$feof(fd)) begin
            $fgets(line, fd);
            line[line.len() - 1] = "\0";
            if (dbg) $display("LINE: %s", line);
            // consider // a comment in the memory images
            if (line[0:1] != "//" && line.len() > 1) begin
                if (dbg) $display("NO COMMENT, WRITE TO MEM");
                tmp = $sscanf(line, "%h", mem.data[j]);
                j++;
            end
        end

        // place nops in all pipeline stages
        this.pipeline.F = new(32'hFC000000, "n");
        this.pipeline.D = new(32'hFC000000, "n");
        this.pipeline.E = new(32'hFC000000, "n");
        this.pipeline.M = new(32'hFC000000, "n");
        this.pipeline.W = new(32'hFC000000, "n");

        // init some bookkeeping variables
        this.cycles = 0;
        this.fmt = "";
        this.op = NOP;

    endfunction : new

    // Run fxn - fetches / executes instructions until end of file
    function void run();
        // max address is 1024, or stop when a halt has been fetched
        while (halt == 1'b0 && pc <1024) begin
            fetch_inst();
            // important that this increments BEFORE execute
            // increment is overwritten if branch taken
            pc = pc + 4;
            execute_inst();
            if (timing) handle_pipeline();
        end

        // need to account for remaining 4 cycles of halt inst after it is fetched
        if (timing) cycles = cycles + 4;
    endfunction : run

    // This function will fetch the next inst from our inst mem based on current PC
    function void fetch_inst();
        current_inst = mem.data[int'(pc / 4)];
        stats.n_inst++;
    endfunction : fetch_inst

    // decodes a given inst into rs/rt/rd/imm and calls appropriate function
    function void execute_inst();

        {op, rs, rt, rd, unused} = current_inst;
        imm = current_inst[imm_width-1:0];

        // mega case for operation routing
        // .* notation wasn't working? Using regular dot notation instead
        case (op)
            ADD : add(.rs(rs), .rt(rt), .rd(rd));
            ADDI : addi(.rs(rs), .rt(rt), .imm(imm));
            SUB : sub(.rs(rs), .rt(rt), .rd(rd));
            SUBI : subi(.rs(rs), .rt(rt), .imm(imm));
            MUL : mul(.rs(rs), .rt(rt), .rd(rd));
            MULI : muli(.rs(rs), .rt(rt), .imm(imm));
            OR : or_op(.rs(rs), .rt(rt), .rd(rd));
            ORI : ori(.rs(rs), .rt(rt), .imm(imm));
            AND : and_op(.rs(rs), .rt(rt), .rd(rd));
            ANDI : andi(.rs(rs), .rt(rt), .imm(imm));
            XOR : xor_op(.rs(rs), .rt(rt), .rd(rd));
            XORI : xori(.rs(rs), .rt(rt), .imm(imm));
            LDW : ldw(.rs(rs), .rt(rt), .imm(imm));
            STW : stw(.rs(rs), .rt(rt), .imm(imm));
            BZ : bz(.rs(rs), .imm(imm));
            BEQ : beq(.rs(rs), .rt(rt), .imm(imm));
            JR : jr(.rs(rs));
            HALT : hlt();
        endcase

    endfunction : execute_inst

    // ARITHMETIC
    function void add(logic[reg_width-1:0] rs, rt, rd);

        gpr[rd] = gpr[rs] + gpr[rt];
        stats.n_arith++;
    
    endfunction : add

    function void addi(logic[reg_width-1:0] rs, rt, logic signed [imm_width-1:0] imm);
        if (dbg)
            $display("Adding %d + %d = %d (R%d)", gpr[rs], imm, gpr[rs]+imm, rt);
        gpr[rt] = gpr[rs] + imm;
        stats.n_arith++;
    
    endfunction : addi

    function void sub(logic[reg_width-1:0] rs, rt, rd);

        gpr[rd] = gpr[rs] - gpr[rt];
        stats.n_arith++;
    
    endfunction : sub

    function void subi(logic[reg_width-1:0] rs, rt, logic signed [imm_width-1:0] imm);

        gpr[rt] = gpr[rs] - imm;
        stats.n_arith++;
    
    endfunction : subi

    function void mul(logic[reg_width-1:0] rs, rt, rd);

        gpr[rd] = gpr[rs] * gpr[rt];
        stats.n_arith++;
    
    endfunction : mul

    function void muli(logic[reg_width-1:0] rs, rt, logic signed [imm_width-1:0] imm);

        gpr[rt] = gpr[rs] * imm;
        stats.n_arith++;
    
    endfunction : muli

    // LOGICAL
    function void or_op(logic[reg_width:0] rs, rt, rd);

        gpr[rd] = gpr[rs] | gpr[rt];
        stats.n_log++;
    
    endfunction : or_op

    function void ori(logic[reg_width-1:0] rs, rt, logic signed [imm_width-1:0] imm);

        gpr[rt] = gpr[rs] | imm;
        stats.n_log++;
    
    endfunction : ori

    function void and_op(logic[reg_width:0] rs, rt, rd);

        gpr[rd] = gpr[rs] & gpr[rt];
        stats.n_log++;
    
    endfunction : and_op

    function void andi(logic[reg_width-1:0] rs, rt, logic signed [imm_width-1:0] imm);

        gpr[rt] = gpr[rs] & imm;
        stats.n_log++;
    
    endfunction : andi

    function void xor_op(logic[reg_width:0] rs, rt, rd);

        gpr[rd] = gpr[rs] ^ gpr[rt];
        stats.n_log++;
    
    endfunction : xor_op

    function void xori(logic[reg_width-1:0] rs, rt, logic signed [imm_width-1:0] imm);

        gpr[rt] = gpr[rs] ^ imm;
        stats.n_log++;
    
    endfunction : xori

    // DATA
    function void ldw(logic[reg_width-1:0] rs, rt, logic signed [imm_width-1:0] imm);

        if (dbg)
            $display("LOAD from MEM[%d] (%d) into R%d", (gpr[rs]+imm)/4, mem.data[(gpr[rs]+imm)/4], rt);
        gpr[rt] = mem.data[(gpr[rs] + imm)/4];
        stats.n_mem++;

    endfunction : ldw

    function void stw(logic[reg_width-1:0] rs, rt, logic signed [imm_width-1:0] imm);

        if (dbg)
            $display("STORE to MEM: %d = %d", (gpr[rs]+imm), gpr[rt]);
        mem.data[(gpr[rs] + imm)/4] = gpr[rt];
        mem.modified[(gpr[rs] + imm)/4] = 1'b1;
        stats.n_mem++;

    endfunction : stw

    // CONTROL
    function void bz(logic[reg_width-1:0] rs, logic signed [imm_width-1:0] imm);
        if (gpr[rs] == 0) begin
            pc = pc + imm*4 - 4;
        end
        stats.n_ctrl++;
    endfunction : bz

    function void beq(logic[reg_width-1:0] rs, rt, logic signed [imm_width-1:0] imm);
        if (gpr[rs] == gpr[rt]) begin
            pc = pc + imm*4 - 4;
        end
        stats.n_ctrl++;
    endfunction : beq

    function void jr(logic[reg_width-1:0] rs);

        pc = gpr[rs];
        stats.n_ctrl++;

    endfunction : jr

    function void hlt();
        // Set halt flag to end program
        halt = 1'b1;
        stats.n_ctrl++;
    endfunction : hlt

    // Models pipeline, inserts stalls as needed
    // Since this is entirely separate from functional sim, does not need to perfectly reflect 'true' behavior
    // ie: all stall counts AND branch flushes are calculated upon fetching the given inst. NOPs inserted
    // as appropriate
    function void handle_pipeline();

        cycles = cycles + 1;

        stall = 0;

        if (op inside {ADD, SUB, MUL, OR, AND, XOR}) fmt = "r";
        else  fmt = "i";

        current_inst_obj = new(current_inst, fmt);

        // move pipeline
        pipeline.W = pipeline.M;
        pipeline.M = pipeline.E;
        pipeline.E = pipeline.D;
        pipeline.D = pipeline.F;
        pipeline.F = current_inst_obj;

        if (dbg) begin
            $display("Handle Pipeline Began");
            $display("Cycle %6d Pipeline State:", cycles);

            $display("FETCH");
            pipeline.F.display_short();
            $display("DECODE");
            pipeline.D.display_short();
            $display("EXEC");
            pipeline.E.display_short();
            $display("MEM");
            pipeline.M.display_short();
            $display("WRITE");
            pipeline.W.display_short();
        end


        // check for hazard, trigger stall, or forward results

        // if nop or halt, no dependencies possible, move on
        if (pipeline.F.opcode == NOP || pipeline.F.opcode == HALT) stall = 0;

        // if 'r' type then check for dependences in D or E stages. Reads Rs and Rt
        else if (pipeline.F.fmt == "r") begin : r_type

            // if E inst is r type then rd will be written
            if (pipeline.E.fmt == "r") begin
                if ((pipeline.F.rs == pipeline.E.rd && pipeline.F.rs != 0) || (pipeline.F.rt == pipeline.E.rd && pipeline.F.rt != 0)) begin
                   if (fwd) stall = 0;
                   else stall = 1;
                end
            end

            // LDW and all arith/logical immediate inst use rt as destination
            else if (pipeline.E.fmt == "i" && pipeline.E.opcode inside {ADDI, SUBI, MULI, ORI, ANDI, XORI, LDW} ) begin

                // check if either src reg for fetch inst matches rt
                if ((pipeline.F.rs == pipeline.E.rt && pipeline.F.rs != 0) || (pipeline.F.rt == pipeline.E.rt && pipeline.F.rt != 0)) begin
                    // if not LDW fwding can eliminate need for stall
                    if (pipeline.E.opcode != LDW) begin
                        if (fwd) stall = 0;
                        else stall = 1;
                    end

                    // LDW does not need stall if inst in E stage
                    else begin
                        if (fwd) stall = 0;
                        else stall = 1;
                    end

                end
            end

            // if D inst is r type then rd will be written
            if (pipeline.D.fmt == "r") begin
                if ((pipeline.F.rs == pipeline.D.rd && pipeline.F.rs != 0) || (pipeline.F.rt == pipeline.D.rd && pipeline.F.rt != 0)) begin
                   if (fwd) stall = 0;
                   else stall = 2;
                end
            end

            // LDW and all arith/logical immediate inst use rt as destination
            else if (pipeline.D.fmt == "i" && pipeline.D.opcode inside {ADDI, SUBI, MULI, ORI, ANDI, XORI, LDW} ) begin

                // check if either src reg for fetch inst matches rt
                if ((pipeline.F.rs == pipeline.D.rt && pipeline.F.rs != 0) || (pipeline.F.rt == pipeline.D.rt && pipeline.F.rt != 0)) begin
                    // if not LDW fwding can eliminate need for stall
                    if (pipeline.D.opcode != LDW) begin
                        if (fwd) stall = 0;
                        else stall = 2;
                    end

                    // if LDW still need 1 cycle stall
                    else begin
                        if (fwd) stall = 1;
                        else stall = 2;
                    end

                end
            end


        end : r_type

        // currently fetched inst is i type
        else if (pipeline.F.fmt == "i") begin : i_type

            if (pipeline.E.fmt == "r") begin
                
                // i type reads rs, EXCEPT BEQ and STW which also read rt!
                if ((pipeline.F.rs == pipeline.E.rd && pipeline.F.rs != 0) || (pipeline.F.rt == pipeline.E.rd && pipeline.F.opcode inside {BEQ, STW} && pipeline.F.rt != 0)) begin
                    
                    if (fwd) stall = 0;
                    else stall = 1;

                end

            end
            
            // inst in decode is i type, check for match with rt
            else if (pipeline.E.fmt == "i") begin
                if ((pipeline.F.rs == pipeline.E.rt && pipeline.F.rs != 0) || (pipeline.F.rt == pipeline.E.rt && pipeline.F.opcode inside {BEQ, STW} && pipeline.F.rt != 0)) begin
                    if (pipeline.E.opcode != LDW) begin
                        if (fwd) stall = 0;
                        else stall = 1;
                    end

                    else begin
                        if (fwd) stall = 0;
                        else stall = 1;
                    end

                end
            end
            // if inst in decode is r type, check for match with rd
            if (pipeline.D.fmt == "r") begin
                
                // i type reads rs, EXCEPT BEQ and STW which also read rt!
                if ((pipeline.F.rs == pipeline.D.rd && pipeline.F.rs != 0) || (pipeline.F.rt == pipeline.D.rd && pipeline.F.opcode inside {BEQ, STW} && pipeline.F.rt != 0)) begin
                    
                    if (fwd) stall = 0;
                    else stall = 2;

                end

            end
            
            // inst in decode is i type, check for match with rt
            else if (pipeline.D.fmt == "i") begin
                if ((pipeline.F.rs == pipeline.D.rt && pipeline.F.rs != 0) || (pipeline.F.rt == pipeline.D.rt && pipeline.F.opcode inside {BEQ, STW} && pipeline.F.rt != 0)) begin
                    if (pipeline.D.opcode != LDW) begin
                        if (fwd) stall = 0;
                        else stall = 2;
                    end

                    else begin
                        if (fwd) stall = 1;
                        else stall = 2;
                    end

                end
            end


        end : i_type

        if (dbg) $display("Inst: %6s would need %1d stall cycles", current_inst_obj.opcode, stall);

        if (stall > 0) stats.n_hazards++;

        //move pipleline, insert N stalls
        while (stall > 0) begin
            pipeline.W = pipeline.M;
            pipeline.M = pipeline.E;
            pipeline.E = pipeline.D;
            pipeline.D = new(32'hFC000000, "n");
            pipeline.F = pipeline.F;
            stats.n_stalls++;
            stall--;
            cycles++;
            if (dbg) begin
                $display("Cycle %6d Pipeline State:", cycles);

                $display("FETCH");
                pipeline.F.display_short();
                $display("DECODE");
                pipeline.D.display_short();
                $display("EXEC");
                pipeline.E.display_short();
                $display("MEM");
                pipeline.M.display_short();
                $display("WRITE");
                pipeline.W.display_short();
            end
        end

        flush = 0;

        // Check for branch misprediction
        case (pipeline.F.opcode)
            BZ : if(gpr[pipeline.F.rs] == 0) flush = 1;
                 else flush = 0;
            BEQ : if(gpr[pipeline.F.rs] == gpr[pipeline.F.rt]) flush = 1;
                  else flush = 0;
            JR : flush = 1;
        endcase

        // if flush insert 2 nop after branch inst
        if (flush) begin
            if (dbg) $display("BRANCH MISPREDICT, flushing");
            stats.n_mispredicts++;
            
            pipeline.W = pipeline.E;
            pipeline.M = pipeline.D;
            pipeline.E = pipeline.F;
            pipeline.D = new(32'hFC000000, "n");
            pipeline.F = new(32'hFC000000, "n");
            // NOTE: appears she did not count branch mispredict penalty as 'stall'
            //stats.n_stalls++;
            //stats.n_stalls++;
            cycles++;
            cycles++;

            if (dbg) begin
                $display("Cycle %6d Pipeline State:", cycles);

                $display("FETCH");
                pipeline.F.display_short();
                $display("DECODE");
                pipeline.D.display_short();
                $display("EXEC");
                pipeline.E.display_short();
                $display("MEM");
                pipeline.M.display_short();
                $display("WRITE");
                pipeline.W.display_short();
            end
        end

    endfunction : handle_pipeline

    // UTILITY
    function void display();

        $display("\n-----CURRENT STATE-----");
        $display("PC  : 0x%8h /  %d", pc, pc);
        for (int i = 0; i < 32; i++) begin
            $display("R%02d : 0x%8h /  %d", i, gpr[i], gpr[i]);
        end

    endfunction : display

    function void displayStats();
        $display("\n------INSTR COUNT------");
        $display("Total Inst: %d (%2.2f)", stats.n_inst, real'(stats.n_inst)/real'(stats.n_inst));
        $display("Arith Inst: %d (%2.2f)", stats.n_arith, real'(stats.n_arith)/real'(stats.n_inst));
        $display("Logic Inst: %d (%2.2f)", stats.n_log, real'(stats.n_log)/real'(stats.n_inst));
        $display("Mem Inst  : %d (%2.2f)", stats.n_mem, real'(stats.n_mem)/real'(stats.n_inst));
        $display("Ctrl Inst : %d (%2.2f)", stats.n_ctrl, real'(stats.n_ctrl)/real'(stats.n_inst));
        if (timing) begin
            $display("\n--------TIMING---------");
            $display("Cycles    : %d", cycles);
            $display("Stalls    : %d", stats.n_stalls);
            $display("Hazards   : %d", stats.n_hazards);
            $display("Branch Mispredicts   : %d", stats.n_mispredicts);
        end
    endfunction : displayStats

    // Write memory image to file
    function void memPrint();
        //$writememh("test_mem_out.txt", mem.data);
    endfunction : memPrint

    function void memDisplay();
        $display("\n------MEMORY STATE------");
        for(int i = 0; i < 1024; i++) begin
            if (mem.modified[i] != 0) begin
                $display("Address: %04d, Contents: %d", i*4, mem.data[i]);
            end
        end
    endfunction : memDisplay
    
endclass : mips_simulator 
