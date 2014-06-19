library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.customprocessor.all;

entity MEMREXRegisters is
	port(
		clk             : std_logic;
		rst             : std_logic;
		pc_in           : in  MEMORY_ADDRESS;
		instruction_in  : in  WORD;
		op1_in          : in  WORD;
		op2_in          : in  WORD;

		pc_out          : out MEMORY_ADDRESS;
		instruction_out : out WORD;
		op1_out         : out WORD;
		op2_out         : out WORD;

		read            : in  std_logic
	);
end MEMREXRegisters;

architecture MEMREXRegistersRTL of MEMREXRegisters is
	signal pc          : MEMORY_ADDRESS;
	signal instruction : WORD;
	signal op1         : WORD;
	signal op2         : WORD;
begin
	pc_out          <= pc;
	instruction_out <= instruction;
	op1_out         <= op1;
	op2_out         <= op2;

	process(clk, rst, read) is
	begin
		if rst = '1' then
			pc          <= (others => '0');
			instruction <= (others => '0');
			op1         <= (others => '0');
			op2         <= (others => '0');
		elsif (rising_edge(clk) and read = '1') then
			pc          <= pc_in;
			instruction <= instruction_in;
			op1         <= op1_in;
			op2         <= op2_in;
		end if;
	end process;

end MEMREXRegistersRTL;