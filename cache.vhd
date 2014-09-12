library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.customprocessor.all;

entity Cache is
	port(
		clk                : in  std_logic; -- clock
		rst                : in  std_logic;
		address            : in  MEMORY_ADDRESS; -- address of the requested location
		miss_address       : out MEMORY_ADDRESS;
		data_in            : in  WORD;
		data_out           : out WORD;
		mem_data_in        : in  WORD;
		mem_address        : in  MEMORY_ADDRESS;
		is_read            : in  std_logic;
		is_write           : in  std_logic;
		is_from_mem        : in  std_logic;
		cache_hit          : out std_logic;
		write_back         : out std_logic;
		read0write1        : out std_logic;

		finished_wb        : out std_logic;
		is_halt            : in  std_logic;
		mem_write          : out std_logic;
		write_back_address : out MEMORY_ADDRESS
	);
end Cache;

architecture CacheImplementation of Cache is
	type CACHEMEMORY is array (CACHE_TABLE_SIZE - 1 downto 0, CACHE_BLOCK_SIZE_IN_WORDS - 1 downto 0) of WORD;
	type CACHETABLE is array (CACHE_TABLE_SIZE - 1 downto 0) of std_logic_vector(22 downto 0);
	type VALIDTABLE is array (CACHE_TABLE_SIZE - 1 downto 0) of std_logic;
	type DIRTYTABLE is array (CACHE_TABLE_SIZE - 1 downto 0) of std_logic;

	signal hwcache                     : CACHEMEMORY;
	signal cache_table                 : CACHETABLE;
	signal dirty                       : DIRTYTABLE;
	signal valid                       : VALIDTABLE;
	signal readwrite                   : std_logic;
	signal miss_address_internal       : MEMORY_ADDRESS;
	signal write_back_address_internal : MEMORY_ADDRESS;
	signal writeback                   : std_logic;
begin
	miss_address       <= miss_address_internal;
	write_back_address <= write_back_address_internal;
	read0write1        <= readwrite;
	write_back         <= writeback;
	process(clk, is_read, is_write, rst, is_halt)
		variable current_block    : integer := 0;
		variable current_offset   : integer := 0;
		variable current_clock    : integer := 0;
		variable current_is_write : boolean := false;
		variable current_address  : MEMORY_ADDRESS;
		variable current_data     : WORD;
	begin
		if rst = '1' then
			for i in 0 to CACHE_TABLE_SIZE - 1 loop
				valid(i)       <= '0';
				cache_table(i) <= (others => '0');
				cache_hit <= '1';
			end loop;
		elsif rising_edge(clk) and is_halt = '1' then
			current_is_write := false;
			if current_clock < 12 then
				if current_block < CACHE_TABLE_SIZE then
					if valid(current_block) = '1' and dirty(current_block) = '1' then
						current_address  := cache_table(current_block) & std_logic_vector(to_unsigned(current_block, 7)) & std_logic_vector(to_unsigned(current_offset, 2));
						current_data     := hwcache(current_block, current_offset);
						current_offset   := current_offset + 1;
						current_is_write := true;
						if current_offset = 4 then
							current_offset := 0;
							current_block  := current_block + 1;
						end if;
					else
						current_block := current_block + 1;
					end if;
				else
				end if;
			else
				if current_clock > 32 then
					current_clock := 0;
				end if;
			end if;

			if current_block >= CACHE_TABLE_SIZE then
				finished_wb <= '1';
			end if;

			if current_is_write then
				miss_address_internal <= current_address;
				data_out              <= current_data;
				mem_write             <= '1';
			else
				mem_write <= '0';
			end if;
			current_clock := current_clock + 1;
		elsif rising_edge(clk) and ((is_read = '1') or (is_write = '1')) then
			if is_from_mem = '1' and is_write = '1' then
				cache_hit                                                                                             <= '0';
				valid(to_integer(unsigned(mem_address(8 downto 2))))                                                  <= '1';
				dirty(to_integer(unsigned(mem_address(8 downto 2))))                                                  <= '0';
				cache_table(to_integer(unsigned(mem_address(8 downto 2))))                                            <= mem_address(31 downto 9);
				hwcache(to_integer(unsigned(mem_address(8 downto 2))), to_integer(unsigned(mem_address(1 downto 0)))) <= mem_data_in;
			elsif is_from_mem = '1' and is_read = '1' then
				cache_hit <= '0';
				data_out  <= hwcache(to_integer(unsigned(address(8 downto 2))), to_integer(unsigned(address(1 downto 0))));
			elsif valid(to_integer(unsigned(address(8 downto 2)))) = '1' then
				if (cache_table(to_integer(unsigned(address(8 downto 2)))) = address(31 downto 9)) then
					cache_hit <= '1';
					writeback <= '0';
					if is_read = '1' then
						data_out <= hwcache(to_integer(unsigned(address(8 downto 2))), to_integer(unsigned(address(1 downto 0))));
					else
						dirty(to_integer(unsigned(address(8 downto 2))))                                              <= '1';
						hwcache(to_integer(unsigned(address(8 downto 2))), to_integer(unsigned(address(1 downto 0)))) <= data_in;
					end if;
				else
					cache_hit                   <= '0';
					writeback                   <= dirty(to_integer(unsigned(address(8 downto 2))));
					miss_address_internal       <= address;
					write_back_address_internal <= cache_table(to_integer(unsigned(address(8 downto 2)))) & address(8 downto 2) & "00";
					readwrite                   <= is_write;
				end if;
			else
				cache_hit             <= '0';
				miss_address_internal <= address;
				readwrite             <= is_write;
			end if;
		end if;
	end process;
end CacheImplementation;