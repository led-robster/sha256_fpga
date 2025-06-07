
GHDL = C:\\Users\\fea\\Documents\\PERSONAL_AREA\\ghdl\\GHDL\\bin\\ghdl.exe
PARAMETERS = --std=08
WAVEFORM = test.fst
VHDL_SRCS = pkg_fun.vhd iteration.vhd block_processor.vhd pop_count.vhd sha256_encode.vhd top.vhd tb.vhd 


run: elaborate
	$(GHDL) -r $(PARAMETERS) tb --fst=$(WAVEFORM)
	gtkwave $(WAVEFORM)

elaborate: analyze
	$(GHDL) -e $(PARAMETERS) tb

analyze: clean
	$(GHDL) -a $(PARAMETERS) $(VHDL_SRCS)


# synthesis
# C:\\Users\\fea\\Documents\\PERSONAL_AREA\\ghdl\\GHDL\\bin\\ghdl.exe --synth --std=08 work.sha256_encode > netlist.o



.PHONY:
clean:
	echo "Cleaning..."
	rm -f *.cf *.fst *.vcd *.ghw *.o