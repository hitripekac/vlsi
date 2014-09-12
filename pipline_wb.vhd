library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.customprocessor.all;

entity WBRegisters is
	port(
		clk             : std_logic;
		rst             : std_logic;

		pc_in           : in  WORD;
		pc_out          : out WORD;

		stop_out        : out std_logic;

		instruction_in  : in  WORD;
		alu_result_in   : in  WORD;
		swap_result_in  : in  WORD;

		rn_address_in   : in  WORD;

		alu_result_out  : out WORD;
		swap_result_out : out WORD;

		data_sel_1      : out REGISTER_SELECT_ADDRESS;
		data_sel_2      : out REGISTER_SELECT_ADDRESS;

		data_write_1    : out std_logic;
		data_write_2    : out std_logic;

		do_jump_in      : in  std_logic;
		do_jump_out     : out std_logic;

		mem_address_out : out WORD;
		mem_data_out    : out WORD;
		mem_write_out   : out std_logic;

		read            : in  std_logic
	);
end WBRegisters;

architecture WBRegistersRTL of WBRegisters is
	signal pc          : MEMORY_ADDRESS;
	signal instruction : WORD;
	signal alu_result  : WORD;
	signal swap_result : WORD;
	signal do_jump     : std_logic;
	signal rn_address  : WORD;
	signal stop        : std_logic;
begin
	pc_out          <= pc;
	alu_result_out  <= alu_result;
	swap_result_out <= swap_result;

	do_jump_out <= do_jump;
	stop_out    <= stop;

	process(clk, rst, read) is
	begin
		if rst = '1' then
			pc          <= (others => '0');
			instruction <= (others => '0');
			alu_result  <= (others => '0');
			swap_result <= (others => '0');
			stop        <= '0';
			data_sel_1  <= (others => '0');
			data_sel_2  <= (others => '0');

			data_write_1 <= '0';
			data_write_2 <= '0';

			mem_address_out <= (others => '0');
			mem_data_out    <= (others => '0');
			mem_write_out   <= '0';
		elsif (rising_edge(clk) and read = '1') then
			pc          <= pc_in;
			instruction <= instruction_in;
			alu_result  <= alu_result_in;
			swap_result <= swap_result_in;
			do_jump     <= do_jump_in;
			rn_address  <= rn_address_in;

			data_sel_1  <= (others => '0');
			data_sel_2  <= (others => '0');

			data_write_1 <= '0';
			data_write_2 <= '0';

			mem_address_out <= (others => '0');
			mem_data_out    <= (others => '0');
			mem_write_out   <= '0';

			if instruction_in(31 downto 29) = "100" then
				data_sel_1 <= "1110";
			else
				data_sel_1 <= instruction_in(20 downto 17);
			end if;
			data_sel_2 <= instruction_in(15 downto 12);

			case instruction_in(31 downto 29) is
				when "000" => if (instruction_in(28 downto 25) = "1010") then
						data_write_1 <= '0';
					else
						data_write_1 <= '1';
					end if;
				when "001" => if (instruction_in(28 downto 25) = "1010") then
						data_write_1 <= '0';
					else
						data_write_1 <= '1';
					end if;
				when "010" => if instruction_in(28) = '1' then
						data_write_1 <= '1';
					else
						data_write_1 <= '0';
					end if;
				when "100" => if (instruction_in(26) = '1') then
						data_write_1 <= '1';
					else
						data_write_1 <= '0';
					end if;
				when others => NULL;
			end case;

			if instruction_in(31 downto 25) = "0001000" then
				data_write_2 <= '1';
			else
				data_write_2 <= '0';
			end if;

			if instruction_in(31 downto 28) = "0100" then
				mem_write_out   <= '1';
				mem_address_out <= swap_result_in;
				mem_data_out    <= alu_result_in;
			end if;

			if instruction_in(31 downto 29) = "101" then
				stop <= '1';
			end if;
		elsif (rising_edge(clk) and read = '0') then
			do_jump <= '0';
		end if;
	end process;

end WBRegistersRTL;