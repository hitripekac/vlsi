library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.customprocessor.all;
use std.textio.all;

entity MEMREXRegisters is
	port(
		clk             : std_logic;
		rst             : std_logic;
		pc_in           : in  MEMORY_ADDRESS;
		instruction_in  : in  WORD;
		op1_in          : in  WORD;
		op2_in          : in  WORD;

		rn_address_in   : in  WORD;
		rn_address_out  : out WORD;

		pc_out          : out MEMORY_ADDRESS;
		instruction_out : out WORD;
		op1_out         : out WORD;
		op2_out         : out WORD;

		read            : in  std_logic;
		clear           : in  std_logic
	);
end MEMREXRegisters;

architecture MEMREXRegistersRTL of MEMREXRegisters is
	signal pc          : MEMORY_ADDRESS;
	signal instruction : WORD;
	signal op1         : WORD;
	signal op2         : WORD;
	signal rn_address  : WORD;
begin
	pc_out          <= pc;
	instruction_out <= instruction;
	op1_out         <= op1;
	op2_out         <= op2;
	rn_address_out  <= rn_address;

	process(clk, rst, read, clear) is
	begin
		if rst = '1' then
			pc          <= (others => '0');
			instruction <= (others => '0');
			op1         <= (others => '0');
			op2         <= (others => '0');
		elsif rising_edge(clk) and clear = '1' then
			instruction <= "11100000000000000000000000000000";
		elsif rising_edge(clk) and read = '1' then
			pc          <= pc_in;
			instruction <= instruction_in;
			op1         <= op1_in;
			op2         <= op2_in;
			rn_address  <= rn_address_in;
		end if;
	end process;

end MEMREXRegistersRTL;