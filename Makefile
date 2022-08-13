SRCLOC = .
PKG = $(SRCLOC)/mips_defs.sv
SRC = $(SRCLOC)/MipsLite_top.sv

VLOGOPTS = -mfcu -cuname top

PLUSARGS = +MEM=$(MEMPATH) +FWD=$(FWD) +TIMING=$(TIMING) +DBG=$(DBG)

MEM = sample_canvas.txt
MEMPATH = $(SRCLOC)/mem_images/$(MEM)
TIMING = 0
FWD = 0
DBG = 0


help:
	@echo "Valid Targets: clean | build | sim | run | simgui | rungui | help"
	@echo "To specify plusargs - when calling make run or make sim add PLUSARGNAME=VALUE. Note that the '+' is NOT included!"
	@echo "PlusArgs Options are:"
	@echo "     +MEM=FILENAME       | Name of input memory trace"
	@echo "     +TIMING=0|1         | Timing Sim Enabled / Disabled"
	@echo "     +FWD=0|1            | Forwarding Enabled / Disabled"
	@echo "     +DBG=0|1            | Debug Msgs Enabled / Disabled"


run: clean build sim

rungui: clean build simgui

build:
	vlib work
	vmap work work
	vlog $(VLOGOPTS) $(PKG) $(SRC)
	vopt +acc MipsLite_top -o mips_opt

sim:
	vsim -c $(PLUSARGS) work.mips_opt -do "run -all; exit" 
simgui:
	vsim $(PLUSARGS) work.mips_opt 

# make commands for demo day
demofunc:
	make sim MEM=final_proj_trace.txt FWD=0 TIMING=0
demotime:
	make sim MEM=final_proj_trace.txt FWD=0 TIMING=1
demofwd:
	make sim MEM=final_proj_trace.txt FWD=1 TIMING=1

# various tests
samplesim:
	make sim MEM=sample_canvas.txt FWD=$(FWD) TIMING=$(TIMING)
add: 
	make sim MEM=arithmetic.txt FWD=$(FWD) TIMING=$(TIMING)
mem:
	make sim MEM=memory.txt FWD=$(FWD) TIMING=$(TIMING)
backB:
	make sim MEM=BZ_back.txt FWD=$(FWD) TIMING=$(TIMING)

clean:
	rm -rf work/ modelsim.ini transcript
