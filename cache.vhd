library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.customprocessor.all;

entity Cache is
	port(
		clk          : in    std_logic; -- clock
		address      : in    MEMORY_ADDRESS; -- address of the requested location
		miss_address : out   MEMORY_ADDRESS;
		data         : inout WORD;
		is_read      : in    std_logic;
		is_write     : in    std_logic;
		cache_hit    : out   std_logic
	);
end Cache;

architecture CacheImplementation of Cache is
	type CACHEMEMORY is array (CACHE_TABLE_SIZE - 1 downto 0, CACHE_BLOCK_ADDRESS_SIZE - 1 downto 0) of WORD;
	type CACHETABLE is array (CACHE_TABLE_SIZE - 1 downto 0) of std_logic_vector(22 downto 0);
	type VALIDTABLE is array (CACHE_TABLE_SIZE - 1 downto 0) of std_logic;
	type DIRTYTABLE is array (CACHE_TABLE_SIZE - 1 downto 0) of std_logic;

	signal hwcache     : CACHEMEMORY;
	signal cache_table : CACHETABLE;
	signal dirty       : DIRTYTABLE;
	signal valid       : VALIDTABLE;

	variable offset              : integer;
	variable segment             : std_logic_vector(22 downto 0);
	signal miss_address_internal : MEMORY_ADDRESS;
begin
	miss_address <= miss_address_internal;
	process(clk, is_read, is_write)
		variable cache_location : integer;
	begin
		if rising_edge(clk) and ((is_read = '1') or (is_write = '1')) then
			offset         := to_integer(unsigned(address(1 downto 0)));
			segment        := address(31 downto 9);
			cache_hit      <= '0';
			cache_location := to_integer(unsigned(address(8 downto 2)));
			if (valid(cache_location) = '1') then
				if (cache_table(cache_location) = segment) then
					cache_hit <= '1';
					if is_read = '1' then
						data <= hwcache(cache_location, offset);
					else
						hwcache(cache_location, offset) <= data;
						dirty(cache_location)           <= '1';
					end if;
				else
					cache_hit             <= '0';
					miss_address_internal <= address(31 downto 2) & "0000";
				end if;
			end if;
		end if;
	end process;
end CacheImplementation;