library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity testbech is 
	generic(stim_file: string := "d:\javni_test_in.txt");
end entity testbech;


architecture testbech_arch of testbech is
	signal is_read, is_write : std_logic; 
  
	signal clock :std_logic := '1';
	signal reset :std_logic;
	
	signal data2: std_logic_vector(31 downto 0);
	signal data_test: std_logic_vector(31 downto 0);
	signal address: std_logic_vector(31 downto 0);
	
	signal pc_start_sta_god : std_logic_vector(31 downto 0);
	type mem is array(4095 downto 0) of std_logic_vector(31 downto 0);
	shared variable memory : mem;
	file stimulus: TEXT open read_mode is stim_file;
	
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
		pc_start => pc_start_sta_god);
		
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
		variable i: integer;
		variable j: bit_vector(31 downto 0);
	begin
		readline(stimulus, l);
		read(l, s);
		report to_string(s);
		pc_start_sta_god <= std_logic_vector(to_unsigned(s, 32));
		
		for i in 0 to 11 loop
		    reqest_list(i).count := -1;
		end loop;
		while not endfile(stimulus) loop
			readline(stimulus, l);
			read(l, i);
			read(l, j);
			memory(i) := to_stdlogicvector(j);
      end loop;

		reset <= '1';
		wait for 40ns;
		reset <= '0';
		wait;
	end process;
	
end architecture testbech_arch;