VERILATOR_FLAGS = 
VERILATOR_FLAGS += -cc --exe
VERILATOR_FLAGS += -O2 -x-assign 0
VERILATOR_FLAGS += --trace --trace-structs
VERILATOR_FLAGS += --top-module sparq_top
VERILATOR_FLAGS += --threads 4
VERILATOR_FLAGS += -Wno-CMPCONST
VERILATOR_FLAGS += -Wno-WIDTH
VERILATOR_FLAGS +=  -CFLAGS "-g -std=c++11"

output=obj_dir/V$(TOP_MODULE)


default: $(output)

SOURCE_FILES = \
	intf.sv \
	buffer_ram.sv \
	float_multiplier.sv \
	float_adder.sv \
	pe.sv \
	inter_pe_buffer.sv \
	controller.sv \
	fifo.sv \
	controller_loader.sv \
	controller_store.sv \
	controller_gemm.sv \
	data_skew.sv \
	accumulator.sv \
	sparq_top.sv \
	testbench.cc \
	sparq_testbench.cc \
	sparq_testbench_host.cc 

$(output):
	verilator $(VERILATOR_FLAGS) -f input.vc $(SOURCE_FILES)
	$(MAKE) -j -C obj_dir -f Vsparq_top.mk

run:
	@mkdir -p logs
	time obj_dir/Vsparq_top 

run_trace:
	@mkdir -p logs
	time obj_dir/Vsparq_top +trace

clean:
	-rm -rf obj_dir logs *.log *.dmp *.vpd core
