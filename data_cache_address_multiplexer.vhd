library ieee;
use ieee.std_logic_1164.all;
use work.customprocessor.all;

entity DataCacheAddressMultiplexer is
	port(
		read_write    : in  std_logic;
		write_address : in  WORD;
		read_address  : in  WORD;
		out_address   : out WORD
	);
end entity DataCacheAddressMultiplexer;

architecture DataCacheAddressMultiplexerRTL of DataCacheAddressMultiplexer is
begin
	out_address <= write_address when read_write = '1' else read_address;
end architecture DataCacheAddressMultiplexerRTL;
