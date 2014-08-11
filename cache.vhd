library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.customprocessor.all;

entity Cache is
	port(
		clk          : in    std_logic; -- clock
		rst          : in    std_logic;
		address      : in    MEMORY_ADDRESS; -- address of the requested location
		miss_address : out   MEMORY_ADDRESS;
		data_in      : inout WORD;
		data_out     : inout WORD;
		is_read      : in    std_logic;
		is_write     : in    std_logic;
		is_from_mem  : in    std_logic;
		cache_hit    : out   std_logic;
		write_back   : out   std_logic;
		read0write1  : out   std_logic
	);
end Cache;

architecture CacheImplementation of Cache is
	type CACHEMEMORY is array (CACHE_TABLE_SIZE - 1 downto 0, CACHE_BLOCK_ADDRESS_SIZE - 1 downto 0) of WORD;
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
		variable offset         : integer;
		variable cache_location : integer;
		variable segment        : std_logic_vector(22 downto 0);
	begin
		if rst = '1' then
			for i in 0 to CACHE_TABLE_SIZE - 1 loop
				valid(i)       <= '0';
				cache_table(i) <= (others => '0');
			end loop;
		elsif rising_edge(clk) and ((is_read = '1') or (is_write = '1')) then
			offset         := to_integer(unsigned(address(1 downto 0)));
			segment        := address(31 downto 9);
			cache_hit      <= '0';
			cache_location := to_integer(unsigned(address(8 downto 2)));
			writeback      <= '0';
			if (valid(cache_location) = '1' or is_from_mem = '1') then
				if (cache_table(cache_location) = segment) then
					cache_hit <= '1';
					if is_read = '1' then
						data_out <= hwcache(cache_location, offset);
					else
						dirty(cache_location) <= '1';
						if is_from_mem = '1' then
							valid(cache_location)       <= '1';
							dirty(cache_location)       <= '0';
							cache_table(cache_location) <= address(31 downto 9);
						end if;
						hwcache(cache_location, offset) <= data_in;
					end if;
				else
					cache_hit <= '0';
					if dirty(cache_location) = '1' then
						writeback <= '1';
					end if;
					miss_address_internal <= address;
					if is_read = '1' then
						readwrite <= '0';
					else
						readwrite <= '1';
					end if;
				end if;
			else
				cache_hit             <= '0';
				miss_address_internal <= address;
				if is_read = '1' then
					readwrite <= '0';
				else
					readwrite <= '1';
				end if;
			end if;
		end if;
	end process;
end CacheImplementation;