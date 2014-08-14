library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.customprocessor.all;

entity Cache is
	port(
		clk          : in  std_logic;   -- clock
		rst          : in  std_logic;
		address      : in  MEMORY_ADDRESS; -- address of the requested location
		miss_address : out MEMORY_ADDRESS;
		data_in      : in  WORD;
		data_out     : out WORD;
		mem_data_in  : in  WORD;
		mem_address  : in  MEMORY_ADDRESS;
		is_read      : in  std_logic;
		is_write     : in  std_logic;
		is_from_mem  : in  std_logic;
		cache_hit    : out std_logic;
		write_back   : out std_logic;
		read0write1  : out std_logic
	);
end Cache;

architecture CacheImplementation of Cache is
	type CACHEMEMORY is array (CACHE_TABLE_SIZE - 1 downto 0, CACHE_BLOCK_SIZE_IN_WORDS - 1 downto 0) of WORD;
	type CACHETABLE is array (CACHE_TABLE_SIZE - 1 downto 0) of std_logic_vector(22 downto 0);
	type VALIDTABLE is array (CACHE_TABLE_SIZE - 1 downto 0) of std_logic;
	type DIRTYTABLE is array (CACHE_TABLE_SIZE - 1 downto 0) of std_logic;

	signal hwcache               : CACHEMEMORY;
	signal cache_table           : CACHETABLE;
	signal dirty                 : DIRTYTABLE;
	signal valid                 : VALIDTABLE;
	signal readwrite             : std_logic;
	signal miss_address_internal : MEMORY_ADDRESS;
	signal writeback             : std_logic;
begin 
	miss_address <= miss_address_internal;
	read0write1  <= readwrite;
	write_back   <= writeback;
	process(clk, is_read, is_write, rst)
	begin
		if rst = '1' then
			for i in 0 to CACHE_TABLE_SIZE - 1 loop
				valid(i)       <= '0';
				cache_table(i) <= (others => '0');
			end loop;
		elsif rising_edge(clk) and ((is_read = '1') or (is_write = '1')) then
			if is_from_mem = '1' and is_write = '1' then
				cache_hit                       <= '0';
				valid(to_integer(unsigned(mem_address(8 downto 2))))           <= '1';
				dirty(to_integer(unsigned(mem_address(8 downto 2))))           <= '0';
				cache_table(to_integer(unsigned(mem_address(8 downto 2))))     <= mem_address(31 downto 9);
				hwcache(to_integer(unsigned(mem_address(8 downto 2))), to_integer(unsigned(mem_address(1 downto 0)))) <= mem_data_in;
			elsif valid(to_integer(unsigned(address(8 downto 2)))) = '1' then
				if (cache_table(to_integer(unsigned(address(8 downto 2)))) = address(31 downto 9)) then
					cache_hit <= '1';
					if is_read = '1' then
						data_out <= hwcache(to_integer(unsigned(address(8 downto 2))), to_integer(unsigned(address(1 downto 0))));
					else
						dirty(to_integer(unsigned(address(8 downto 2))))           <= '1';
						hwcache(to_integer(unsigned(address(8 downto 2))), to_integer(unsigned(address(1 downto 0)))) <= data_in;
					end if;
				else
					cache_hit <= '0';
					writeback <= dirty(to_integer(unsigned(address(8 downto 2))));
					miss_address_internal <= address;
					readwrite <= is_write;
				end if;
			else
				cache_hit             <= '0';
				miss_address_internal <= address;
				readwrite <= is_write;
			end if;
		end if;
	end process;
end CacheImplementation;