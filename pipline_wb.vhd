library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.customprocessor.all;

entity WBRegisters is
	port(
		clk             : std_logic;
		rst             : std_logic;
		instruction_in  : in  WORD;
		alu_result_in   : in  WORD;
		swap_result_in  : in  WORD;

		alu_result_out  : out WORD;
		swap_result_out : out WORD;

		data_sel_1      : out REGISTER_SELECT_ADDRESS;
		data_sel_2      : out REGISTER_SELECT_ADDRESS;

		data_write_1    : out std_logic;
		data_write_2    : out std_logic;

		do_jump_in      : in  std_logic;
		do_jump_out     : out std_logic;

		read            : in  std_logic
	);
end WBRegisters;

architecture WBRegistersRTL of WBRegisters is
	signal pc          : MEMORY_ADDRESS;
	signal instruction : WORD;
	signal alu_result  : WORD;
	signal swap_result : WORD;
	signal do_jump     : std_logic;
begin
	pc_out          <= pc;
	alu_result_out  <= alu_result;
	swap_result_out <= swap_result;

	do_jump_out <= do_jump;

	process(clk, rst, read) is
	begin
		if rst = '1' then
			pc          <= (others => '0');
			instruction <= (others => '0');
			alu_result  <= (others => '0');
			swap_result <= (others => '0');
		elsif (rising_edge(clk) and read = '1') then
			pc          <= pc_in;
			instruction <= instruction_in;
			alu_result  <= alu_result_in;
			swap_result <= swap_result_in;
			do_jump     <= do_jump_in;

			data_sel_1 <= "1110" when instruction(31 downto 29) = "100" else instruction(20 downto 17);
			data_sel_2 <= instruction(15 downto 12);

			case instruction(31 downto 29) is
				when "000" => data_write_1 <= '1';
				when "001" => data_write_1 <= '1';
				when "010" => data_write_1 <= '1' when instruction(28) = '0' else '0';
				when "011" => data_write_1 <= '1';
				when "100" => data_write_1 <= '1' when instruction(26) = '1' else '0';
			end case;

			data_write_2 <= '1' when instruction(31 downto 25) = "0001000" else '0';
		end if;
	end process;

end WBRegistersRTL;