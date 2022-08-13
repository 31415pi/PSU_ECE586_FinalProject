// MipsLite_top.sv
// Top module that instantiates simulator test and modifies based on plusargs
//
// Collaborator: Kyle Eichenberger (keich2@pdx.edu)
// Collaborator: Gage Elerding (elerding@pdx.edu)
// Collaborator: Maddie Klementyn (muk2@pdx.edu) 
// Collaborator: John Samwel (samwel@pdx.edu)

import mips_defs::*;


module MipsLite_top();

    string filename;
    int fwd, dbg, timing;
    mips_simulator mipsLite;

    initial begin : test

        if ( $value$plusargs("MEM=%s", filename) );
        else $display("Error on file read or open");
            
        if ( $value$plusargs("FWD=%d", fwd ) );
        else fwd = 0;

        if ( $value$plusargs("DBG=%d", dbg ) );
        else dbg = 0;

        if ( $value$plusargs("TIMING=%d", timing) );
        else timing = 0;

        mipsLite = new(.filename(filename), .fwd_in(fwd), .dbg_in(dbg), .timing_in(timing));
        mipsLite.run();

        $display("-----DONE-----");
        mipsLite.displayStats();
        mipsLite.display();
        mipsLite.memDisplay();
    end : test

endmodule : MipsLite_top
