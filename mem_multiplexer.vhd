library ieee;
use ieee.std_logic_1164.all;
use work.customprocessor.all;

entity MemMultiplexer is
	port(
		from_mem : in std_logic;
		register_operand : in  WORD;
		memory_operand  : in  WORD;
		operand_out   : out WORD
	);
end entity MemMultiplexer;

architecture MemMultiplexerRTL of MemMultiplexer is
begin
	operand_out <= memory_operand when from_mem = '1' else register_operand;
end architecture MemMultiplexerRTL;
