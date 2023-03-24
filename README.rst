Grain
=====

Hardware implementation for the `Grain family <https://en.wikipedia.org/wiki/Grain_(cipher)>`_ of stream ciphers:

* Grain80 (or Grain-1) from "Grain - A Stream Cipher for Constrained Environments" ( `PDF <http://www.ecrypt.eu.org/stream/p3ciphers/grain/Grain_p3.pdf>`_ )
* Grain128 from "A Stream Cipher Proposal: Grain-128" ( `PDF <http://www.ecrypt.eu.org/stream/p3ciphers/grain/Grain128_p3.pdf>`_ )
* "Grain-128a: a new version of Grain-128 with optional authentication" ( `PDF <http://lup.lub.lu.se/search/ws/files/3454246/2296485.pdf>`_ )

The first two were phase-3 candidates in the `eSTREAM project <http://www.ecrypt.eu.org/stream/grainp3.html>`_ .

The main strength of Grain is its small hardware footprint. For example, Grain80 can be implemented in less than 50 Xilinx slices.


Open source
-----------

I am using this project evaluate free and open-source EDA tools. 
Since verilog is better supported by FOSS EDA tools I will eventually re-write the VHDL code in verilog.

If you are interested in a similar evaluation for a minimal SoC, have a look at my `ARM-FOSS <https://github.com/avahidi/arm-foss>`_ project.

Notes
-----

* This project is very much a work-in-progress.
* Right now, only grain80 and grain128 have been verified in real hardware. 
* These are FPGA implementations. ASIC implementations would look very different. 
* Once qflow is stable, I hope to publish ASIC implementations.



	
