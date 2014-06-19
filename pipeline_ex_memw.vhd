library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.customprocessor.all;

entity EXMEMWRegisters is
	port(
		clk             : std_logic;
		rst             : std_logic;
		pc_in           : in  MEMORY_ADDRESS;
		instruction_in  : in  WORD;
		alu_result_in   : in  WORD;
		swap_result_in  : in  WORD;

		pc_out          : out MEMORY_ADDRESS;
		instruction_out : out WORD;
		alu_result_out  : out WORD;
		swap_result_out : out WORD;

		do_jump_in      : in  std_logic;
		do_jump_out     : out std_logic;

		read            : in  std_logic
	);
end EXMEMWRegisters;

architecture EXMEMWRegistersRTL of EXMEMWRegisters is
	signal pc          : MEMORY_ADDRESS;
	signal instruction : WORD;
	signal alu_result  : WORD;
	signal swap_result : WORD;
	signal do_jump     : std_logic;
begin
	do_jump_out     <= do_jump;
	pc_out          <= pc;
	instruction_out <= instruction;
	alu_result_out  <= alu_result;
	swap_result_out <= swap_result;

	process(clk, rst, read) is
	begin
		if rst = '1' then
			pc          <= (others => '0');
			instruction <= (others => '0');
			alu_result  <= (others => '0');
			swap_result <= (others => '0');
		elsif (rising_edge(clk) and read = '1') then
			do_jump     <= do_jump_in;
			pc          <= pc_in;
			instruction <= instruction_in;
			alu_result  <= alu_result_in;
			swap_result <= swap_result_in;
		end if;
	end process;

end EXMEMWRegistersRTL;