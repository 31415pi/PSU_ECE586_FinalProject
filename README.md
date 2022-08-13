# ece586project
MIPS Lite Pipeline Design for ECE586 at Portland State Spring 2022

# ece585project
Design and simulation of a split L1 cache for a new 32-bit processor for ECE585 at Portland State Winter 2022

---
## Project Description
The goal of the project is to model a simplified version of the MIPS ISA called MIPS-lite and the in-order 5-stage
pipeline to be discussed in class. You will write your own simulator in a high-level language of your choice (such as
C, C++, JAVA, Verilog, VHDL, etc.).

The simulator will take the provided memory image as its input and implement two key features: 
 1. A functional simulator which simulates the MIPS-lite ISA and captures the impact of instruction execution on machine state
 2. A timing simulator which models the timing details for the 5-stage pipeline
 
The output of the simulator will include:
 * A breakdown of instruction frequencies in the instruction trace into different instruction types
 * Final machine state (register values, memory contents etc.)
 * Execution time (in cycles) of the instruction trace on the 5-stage pipeline

Note that there is no need to model the internal details of processor hardware, such as pipeline latches or wires. The
goal is NOT to build a simulator that is hardware accurate for each bit of the pipeline. You only need to make
modifications that will capture the changes to machine state and count the total clock cycles a program takes to
execute. You will have to visualize the 5 stage pipeline and the instructions in every stage, and then program your
simulator with that in mind. For example, when there is a data hazard, you will ascertain how many stall cycles
would this kind of hazard cause in a real processor pipeline. Then you have to account for the impact of these stall
cycles on the execution time. 

---
## Resources:
* Lecture Slides provided by Dr Yuchen Huang used in Spring 2022
* Computer Architecture: A Quantitative Approach by Hennessy and Patterson (6th Edition)
* Computer Organization and Design MIPS Edition: The Hardware/Software Interface by Patterson and Hennessy (5th Edition)
