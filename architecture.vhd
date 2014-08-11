library ieee;

use ieee.std_logic_1164.all;

package CustomProcessor is
	constant WORD_IN_BYTES   : integer := 4;
	constant WORD_IN_BITS    : integer := 8 * WORD_IN_BYTES;
	constant ADDRESS_IN_BITS : integer := WORD_IN_BITS;

	constant REGISTER_FILE_ADDRESS_SIZE : integer := 4;
	constant REGISTER_FILE_SIZE         : integer := 2 ** REGISTER_FILE_ADDRESS_SIZE;

	subtype WORD is std_logic_vector(WORD_IN_BITS - 1 downto 0);
	subtype MEMORY_ADDRESS is WORD;
	subtype REGISTER_SELECT_ADDRESS is std_logic_vector(REGISTER_FILE_ADDRESS_SIZE - 1 downto 0);

	type CPU_STATE is (CPU_RESET, INSTRUCTION_CACHE_STALL, DATA_CACHE_STALL, NORMAL, HALT);

	constant CACHE_BLOCK_ADDRESS_SIZE  : integer := 2;
	constant CACHE_BLOCK_SIZE_IN_WORDS : integer := 2 ** CACHE_BLOCK_ADDRESS_SIZE;

	constant CACHE_SIZE       : integer := 2048;
	constant CACHE_TABLE_SIZE : integer := CACHE_SIZE / 16;

	subtype ALU_OPERATION_SELECT is std_logic_vector(3 downto 0);


end package CustomProcessor;

package body CustomProcessor is
end package body CustomProcessor;
