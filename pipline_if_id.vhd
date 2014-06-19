library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.customprocessor.all;

entity IFIDRegisters is
	port(
		clk             : in  std_logic;
		rst             : in  std_logic;
		pc_in           : in  MEMORY_ADDRESS;
		instruction_in  : in  WORD;
		pc_out          : out MEMORY_ADDRESS;
		instruction_out : out WORD;
		read            : in  std_logic
	);
end IFIDRegisters;

architecture IFIDRegistersRTL of IFIDRegisters is
	signal pc          : MEMORY_ADDRESS;
	signal instruction : WORD;
begin
	pc_out          <= pc;
	instruction_out <= instruction;

	process(clk, rst, read) is
	begin
		if rst = '1' then
			pc          <= (others => '0');
			instruction <= (others => '0');
		elsif (rising_edge(clk) and read = '1') then
			pc          <= pc_in;
			instruction <= instruction_in;
		end if;
	end process;

end IFIDRegistersRTL;
