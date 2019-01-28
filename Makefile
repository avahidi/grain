

all: sim80 sim128

.PHONY: sim80 sim128 sim128a
sim80: build/tb_grain80.vcd
sim128: build/tb_grain128.vcd

.PHONY: show80 show128 show128a
show80: build/tb_grain80.vcd
	gtkwave build/tb_grain80.vcd

show128: build/tb_grain128.vcd
	gtkwave build/tb_grain128.vcd


build/tb_grain80.vcd: build src/grain80/*.vhdl
	ghdl -a --workdir=build src/grain80/grain80_datapath_*.vhdl
	ghdl -a --workdir=build src/grain80/grain80.vhdl
	ghdl -a --workdir=build src/grain80/tb_*.vhdl

	ghdl -e --workdir=build tb_grain80
	ghdl -r --workdir=build tb_grain80 test --vcd=build/tb_grain80.vcd --stop-time=150us 


build/tb_grain128.vcd: build src/grain128/*.vhdl
	ghdl -a --workdir=build src/grain128/grain128_datapath_*.vhdl
	ghdl -a --workdir=build src/grain128/grain128.vhdl
	ghdl -a --workdir=build src/grain128/tb_*.vhdl

	ghdl -e --workdir=build tb_grain128
	ghdl -r --workdir=build tb_grain128 test --vcd=build/tb_grain128.vcd --stop-time=150us 


clean:
	rm -rf build

build:
	mkdir build
