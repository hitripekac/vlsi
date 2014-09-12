library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use std.textio.all;

entity testbench is 
	generic(
		stim_file: string := "d:\javni_test_in.txt";
		result_file: string := "d:\javni_test_out.txt");
end entity testbench;


architecture testbench_arch of testbench is
	signal is_read, is_write : std_logic; 
  
	signal clock :std_logic := '1';
	signal reset :std_logic;
	
	signal data2: std_logic_vector(31 downto 0);
	signal data_test: std_logic_vector(31 downto 0);
	signal address: std_logic_vector(31 downto 0);
	
	signal is_finished : std_logic;
	signal pc_start_sta_god : std_logic_vector(31 downto 0);
	type mem is array(65535 downto 0) of std_logic_vector(31 downto 0);
	shared variable memory : mem;
	shared variable memory_copy : mem;
	file stimulus: TEXT open read_mode is stim_file;
	file result: TEXT open write_mode is result_file;
	
	type request is record
		address: std_logic_vector(31 downto 0);
		data: std_logic_vector(31 downto 0);
		is_read: std_logic;
		count: integer;
	end record;

	type requests is array(11 downto 0) of request;
	shared variable reqest_list: requests;
	
begin
	processor  : entity work.CPU port map (
		clk=>clock, 
		rst=>reset,
		data =>data_test,
		address=>address,
		is_read  =>is_read,		
		is_write => is_write,
		pc_start => pc_start_sta_god,
		is_finished => is_finished);
		
	clock <= not (clock) after 10 ns;    --clock with time period 2 ns
	
	mem_proc: process(clock)

	variable memout: integer := 0;

   begin        
		
		if rising_edge(clock) then
			if is_read = '1' or is_write = '1' then
				for i in 0 to 11 loop
					if reqest_list(i).count = -1 then
						reqest_list(i).is_read := is_read;
						reqest_list(i).count := 14;
						reqest_list(i).address := address;
						reqest_list(i).data := data_test;
						exit;
					end if;
				end loop;
			end if;
			
			memout := 0;
			
			for i in 0 to 11 loop
				if reqest_list(i).count /= -1 then 
					reqest_list(i).count := reqest_list(i).count - 1;
					if reqest_list(i).count = 0 then 
						if reqest_list(i).is_read = '1' then
							memout := 1;
							data_test <= memory(to_integer(unsigned(reqest_list(i).address)));
							address <= reqest_list(i).address;
						else
							memory(to_integer(unsigned(reqest_list(i).address))) := reqest_list(i).data;
						end if;
					end if;
				end if;
			end loop;
			
			if memout = 0 then data_test <= (others => 'Z'); address <= (others => 'Z'); end if;
			
			
		end if;
	end process;
	
	
	stim: process
		variable l: line;
		variable s: integer;
		variable h: std_logic_vector(31 downto 0);
		variable i: integer;
		variable j: bit_vector(31 downto 0);
	begin
		readline(stimulus, l);
		hread(l, h);
		pc_start_sta_god <= h;

		for i in 0 to 11 loop
		    reqest_list(i).count := -1;
		end loop;

		for i in 0 to 65535 loop
			memory(i) := (others => '0');
			memory_copy(i) := (others => '0');
		end loop;
		
		while not endfile(stimulus) loop
			readline(stimulus, l);
			hread(l, h);
			i := to_integer(unsigned(h));
			read(l, j);
			memory(i) := to_stdlogicvector(j);
			memory_copy(i) := to_stdlogicvector(j);
		end loop;

		reset <= '1';
		wait for 40ns;
		reset <= '0';
		wait until is_finished = '1';
		for i in 0 to 65535 loop
			if memory(i) /= memory_copy(i) then 
				hwrite(l, std_logic_vector(to_unsigned(i, 32)));
				write(l, string'(" "));
				write(l, memory(i));
				writeline(result, l);
			end if;
		end loop;
		wait;
	end process;
	
end architecture testbench_arch;