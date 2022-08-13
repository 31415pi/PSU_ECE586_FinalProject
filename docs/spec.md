# ECE 586 Project Spec

##Instruction Set:
* 000000 ADD  Rd Rs Rt  (Rd = Rs+Rt)
* 000001 ADDI Rt Rs Imm (Rt = Rs + Imm)
* 000010 SUB  Rd Rs Rt  (Rd = Rs - Rt)
* 000011 SUBI Rt Rs Imm (Rt = Rs - Imm)
* 000100 MUL  Rd Rs Rt  (Rd = Rs * Rt)
* 000101 MULI Rt Rs Imm (Rt = Rs * Imm)
* 000110 OR   Rd Rs Rt  (Rd = Rs | Rt)
* 000111 ORI  Rt Rs Imm (Rt = Rs | Imm)
* 001000 AND  Rd Rs Rt  (Rd = Rs & Rt)
* 001001 ANDI Rt Rs Imm (Rt = Rs & Imm)
* 001010 XOR  Rd Rs Rt  (Rd = Rs ^ Rt)
* 001011 XORI Rt Rs Imm (Rt = Rs ^ Imm)
* 001100 LDW  Rt Rs Imm (<Rs + Imm> = Rt)
* 001101 STW  Rt Rs Imm (Rt = <Rs + Imm>)
* 001110 BZ   Rs x      (Rs==0, branch relative x) [x is given by the IMM field]
* 001111 BEQ  Rs Rt x   (Rs==Rt, branch relative x) [x is given by the IMM field]
* 010000 JR   Rs        (PC = Rs)
* 010001 HALT           (Terminate Program)

Arithmetic computations are signed integers, 2's complement arithmetic

## Instruction Format:
* R-Type: ADD, SUB, MUL, OR, AND, XOR
* I-Type: The rest of them

## Memory Image:
* Addresses start at 0 and increment by 4
* Data is Big Endian
* MIPS-lite is limited to a 4kB memory (1024 lines)

## Functional Simulator:
Components:
1. Program Counter (PC)
2. General Purpose Register (R1-R31)
3. Memory

Initial memory state in image
Assume registers are initial 0


## Timing Simulator:
* 1 Instruction per clock cycle (except on hazards or branch)

1. RAW Hazard:
    * Match source operands of recent instructions with upcoming destination instructions
    * All instructions take 5 cycles (WAR/WAW will be absent)
    * Read/Write occur in same cycle (write is written in first half, new register read on second)
2. Mispredicted Branches
    * Assume always-not-taken
    * Target and condition gets figured out at the end of Ex regardless
    * Need to flush pipeline from incorrect path

Implementation Ideas:
1. Clock Counter
2. Array of length 5
3. Queue of 5 entries (for pipeline)
4. If taken branch or jump: need to update NOPs upstream, update PC
