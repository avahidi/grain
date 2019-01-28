
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity tb_grain80 is
generic (
	DEBUG : boolean := false
);
end entity;


architecture test of tb_grain80 is

-- some testvectors:
constant GRAIN_KEY1 : unsigned(79 downto 0) := (others => '0');
constant GRAIN_IV1  : unsigned(63 downto 0) := (others => '0');
constant GRAIN_KS1  : unsigned(79 downto 0) := x"7b978cf36846e5f4ee0b";

constant GRAIN_KEY2 : unsigned(79 downto 0) := x"0123456789abcdef1234";
constant GRAIN_IV2  : unsigned(63 downto 0) := x"0123456789abcdef";
constant GRAIN_KS2  : unsigned(79 downto 0) := x"42b567ccc65317680225";


-- DUT signal
signal clk, clken, areset : std_logic;
signal init, key_in, iv_in : std_logic;
signal key : unsigned(79 downto 0);
signal iv : unsigned(63 downto 0);


-- monitor the output:
signal key_memory : unsigned(79 downto 0);
signal key_count : integer := 0;

signal keystream_fast, keystream_slow : std_logic;
signal keystream_valid_fast, keystream_valid_slow : std_logic;

begin
	
	
	-- fast DUT
	DUT0: entity work.grain80
	generic map ( 
		DEBUG => DEBUG,
		FAST  => true
	)
	port map (
		CLK_I    => clk,
		CLKEN_I  => clken,
		ARESET_I => areset,
	
		KEY_I  => key_in,
		IV_I   => iv_in,
		INIT_I => init,
		
		KEYSTREAM_O => keystream_fast,
		KEYSTREAM_VALID_O => keystream_valid_fast
	);

	-- slow DUT
	DUT1: entity work.grain80
	generic map ( 
		DEBUG => DEBUG,
		FAST  => false
	)
	port map (
		CLK_I    => clk,
		CLKEN_I  => clken,
		ARESET_I => areset,
	
		KEY_I  => key_in,
		IV_I   => iv_in,
		INIT_I => init,
		
		KEYSTREAM_O => keystream_slow,
		KEYSTREAM_VALID_O => keystream_valid_slow
	);


	-- clock generator:
	clkgen_proc: process
	begin
		clk <= '0'; wait for 10 ns;
		clk <= '1'; wait for 10 ns;
	end process;
	
	-- dummy clock enable: every fourth cycle
	clken_proc: process
	begin
		clken <= '0';
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		
		clken <= '1';		
		wait until rising_edge(clk);	
	end process;
		
	
	-- output monitor:
	mon_proc: process(clk, areset)
	begin
		if areset = '1' then
			key_memory <= (others => 'X');
			key_count <= 0;
		elsif rising_edge(clk) then
			if clken = '1' then
				if keystream_valid_fast = '1' then
					key_count <= key_count + 1;					
					key_memory <= key_memory(key_memory'high-1 downto 0) & keystream_fast;
				else				
					key_memory <= (others => 'X');
					key_count <= 0;
				end if;
				
			end if;
		end if;
	end process;
		
	

	-- equality monitor: fast and slow should have same output
	equal_proc: process(clk, areset)
	begin
		if areset = '1' then
			-- empty
		elsif rising_edge(clk) then
			assert keystream_fast = keystream_slow
				report "fast and slow datapaths have different key streams"
				severity failure;

			assert keystream_valid_fast = keystream_valid_slow
				report "fast and slow datapaths have different valid signals"
				severity failure;
		end if;
	end process;
	
	
	-- this process will do all the testing
	tester_proc: process
	
		-- reset everything
		procedure do_reset is
		begin	  
			key_in <= 'X';
			iv_in <= 'X';
			init <= '0';
			
			areset <= '1';
			wait for 100 ns;
			
			areset <= '0';			
		end procedure;
		
		
		-- initialize grain with key and IV
		procedure do_init is
		begin
			wait until rising_edge(clk) and clken = '1';
			init <= '1';
			
			wait until rising_edge(clk) and clken = '1';
			init <= '0';
			
			for i in key'range loop
				key_in <= key(key'high);
				iv_in  <= iv(iv'high);
				key <= key rol 1;
				iv  <= iv rol 1;				
				wait until rising_edge(clk) and clken = '1';				
			end loop;		
			
			key_in <= 'X';
			iv_in  <= 'X';
		end procedure;			
		
	begin
	
		-- 1. start with a reset:
		do_reset;
		
		-- 2. inject key and IV
		key <= GRAIN_KEY1;
		iv  <= GRAIN_IV1;
		do_init;
		
		
		-- 3. verify output:
		wait on clk until key_count = 80;
		assert key_memory = GRAIN_KS1
			report "incorrect output with IV = 0 and KEY = 0"
			severity failure;
			
			
			
		-- 4. try the other testvector
		key <= GRAIN_KEY2;
		iv  <= GRAIN_IV2;
		do_init;
		
		wait on clk until key_count = 80;
		assert 
			key_memory = GRAIN_KS2
			report "incorrect output with IV = 0123.. and KEY = 0123.."
			severity failure;


		
		-- done:
		report "ALL DONE" severity note;
		wait;
	end process;
	


end test;

-- asim -g/FAST=false tb_grain ; wave /DUT/* ; run 100 us
-- asim -g/FAST=true tb_grain ; wave /DUT/* ; run 100 us
