
Using the Grain IP
==================

(this currently only covers grain80 and grain128, but grain128a should work similarly).

To use the Grain IP, first instantiate the VHDL entity in your design::

	grain0: entity work.grain80
	generic map ( 
		DEBUG => false,
		FAST  => false
	)
	port map (
		CLK_I    => clk,
		CLKEN_I  => clken,
		ARESET_I => areset,
	
		KEY_I  => key_in,
		IV_I   => iv_in,
		INIT_I => init,
		
		KEYSTREAM_O       => keystream,
		KEYSTREAM_VALID_O => keystream_valid
	);

	
Notice that this entity requires a clock, an asynchronous reset and an (optional)
clock enable. You also need to add the grain implementation files to your project:

  - "grain80.vhd" 
  - "grain80_datapath_fast.vhd"
  - "grain80_datapath_slow.vhd"

Notice that only one of the datapath files will be used (depending 
on the value of the "FAST" generic parameter).





2. INITIALIZATION:
------------------

To start the stream cipher, you must supply it with a key and an IV. In the case
of Grain-1, these are 80 and 64 bits respectively.

The key and IV are feed to the cipher one bit each (enabled) clock,  after that
the [INIT_I] signal has been asserted for one (enabled) clock cycle::



    CLK_I      /--\__/--\__/--\__/--\__/--\__/--\__/--\__/--\__
    CLKEN_I    /-----\_____/-----\_____/-----\_____/-----\_____
    
    INIT_I     /------\________________________________________
    
    KEY_I      --------< K0      >< K1       >< K2     ....
    IV_I       --------< IV0     >< IV1      >< IV2    ....

(here we assume that clock is enabled every other cycle)



After 64 (enabled) clock cycles, the IV has been fed to the cipher.
16 clock cycles later, the key has also been fed to the cipher. 
At this point, the user should simply wait for the output.





3. OUTPUT:
----------

At some point after initialization, the keystream will start to appear
on the [KEYSTREAM_O] output at the same time the signal
[KEYSTREAM_VALID_O] will be asserted. 

This output sequence works as following::


    CLK_I              /--\__/--\__/--\__/--\_...._/--\__/--\__/--\__/--\__
    CLKEN_I            /-----\_____/-----\____...._/-----\_____/-----\_____
    
    INIT_I             /------\_______________...._________________________
    
    
    KEYSTREAM_O        ##################################< KS0       >< KS1 ...
    KEYSTREAM_VALID_O  ###################\___...._______/-------------- ...

The module will generate one bit of key stream for each enabled clock cycle.
(here we assume every other clock is enabled)






4. RE-INITIALIZATION:
---------------------

To change the key and/or IV, simply repeat the initialization procedure.

Beware however that the keystream from the old key/IV pair will be 
produced up to one clock cycle after [INIT_I] has been re-asserted.

Notice also that you are not allowed to re-start the initialization
sequence before it has finished. The initialization sequence is finished
when [KEYSTREAM_VALID_O] is asserted.


5. GRAIN-128:
-------------

The Grain-128 IP works in the same way. The only difference is that key size 
is increased to 128 bits and IV size is increased to 96 bits.





6. TESTBENCHES
--------------

The testbenches use testvectors from the Grain papers.


7. SYNTHESIS:
-------------

Synthesis is straightforward. Just add the three (two) required files 
to your project and push the "synthesis" button :)

Beyond that, a couple of things that more advanced users may be 
interested in are:

* Clock-enable: The clock enable signal is a high-fan out signal, may require logic duplication
* Register balancing: The feedback term used in the NFSR and the H function are large. The fast datapath attempts to move them back one clock, although your synthesis tools probably can do a better job.
* Architecture-specific elements: There are no SRL16 and alike in this code. Let the tool decide!

