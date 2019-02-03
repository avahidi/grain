

# tools
IVERILOG = iverilog -Wall -g2001
GTKWAVE=gtkwave
LINT = verilator -Wall --lint-only --bbox-sys --bbox-unsup -Wno-STMTDLY

SYNTH = yosys -Q -v 1
PNR=nextpnr-ice40


all: sim80 sim128 sim128a

lint: lint80 lint128 lint128a



# grain80:
.PHONY: sim80 show80

sim80: build/tb_grain80.vcd

show80: build/tb_grain80.vcd
	$(GTKWAVE) build/tb_grain80.vcd

lint80:
# TODO

build/tb_grain80.vcd: build src/grain80/*.vhdl
	ghdl -a --workdir=build src/grain80/grain80_datapath_*.vhdl
	ghdl -a --workdir=build src/grain80/grain80.vhdl
	ghdl -a --workdir=build src/grain80/tb_*.vhdl

	ghdl -e --workdir=build tb_grain80
	ghdl -r --workdir=build tb_grain80 test --vcd=build/tb_grain80.vcd --stop-time=150us



# grain128
.PHONY: sim128 show128

sim128: build/tb_grain128.vcd

show128: build/tb_grain128.vcd
	$(GTKWAVE) build/tb_grain128.vcd

lint128:
# TODO

build/tb_grain128.vcd: build src/grain128/*.vhdl
	ghdl -a --workdir=build src/grain128/grain128_datapath_*.vhdl
	ghdl -a --workdir=build src/grain128/grain128.vhdl
	ghdl -a --workdir=build src/grain128/tb_*.vhdl

	ghdl -e --workdir=build tb_grain128
	ghdl -r --workdir=build tb_grain128 test --vcd=build/tb_grain128.vcd --stop-time=150us

# grain128a
.PHONY: sim128a show128a

sim128a: build/tb_grain128a.vcd

show128a: build/tb_grain128a.vcd
	$(GTKWAVE) build/tb_grain128a.vcd

lint128a: src/grain128a/*
	$(LINT) -Isrc/grain128a/ src/grain128a/grain128a.v --top-module grain128a
	-$(LINT) -Isrc/grain128a/ src/grain128a/*.v --top-module tb_grain128a

build/tb_grain128a.vcd: build src/grain128a/*
	$(IVERILOG) -Wall -g2001 -Isrc/grain128a src/grain128a/grain128a.v src/grain128a/tb_grain128a.v -o build/tb_grain128a.exe
	build/tb_grain128a.exe -h

build/grain128a.json: build src/grain128a/*
	$(SYNTH)  -p 'read_verilog -Isrc/grain128a src/grain128a/grain128a.v' -p 'synth_ice40 -top grain128a -retime -json build/grain128a.json' -l build/grain128a.synth.log -o build/grain128a.v
	-grep  -i -A 40 "Printing statistics" build/grain128a.synth.log


clean:
	rm -rf build

build:
	mkdir build
