library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.customprocessor.all;

entity RegisterFile is
	port(
		clk          : in  std_logic;
		rst          : in  std_logic;
		pc_start     : in  WORD;

		select_out_1 : in  REGISTER_SELECT_ADDRESS;
		select_out_2 : in  REGISTER_SELECT_ADDRESS;
		select_out_3 : in  REGISTER_SELECT_ADDRESS;
		data_out_1   : out WORD;
		data_out_2   : out WORD;
		data_out_3   : out WORD;

		select_in_1  : in  REGISTER_SELECT_ADDRESS;
		select_in_2  : in  REGISTER_SELECT_ADDRESS;
		data_in_1    : in  WORD;
		data_in_2    : in  WORD;
		write_1      : in  std_logic;
		write_2      : in  std_logic;

		pc_in        : in  WORD;
		pc_write     : in  std_logic;
		pc_out       : out WORD
	);
end RegisterFile;

architecture RegisterFileImplementation of RegisterFile is
	type REGISTER_FILE_TYPE is array (15 downto 0) of std_logic_vector(31 downto 0);
	signal register_file : REGISTER_FILE_TYPE;

begin
	process(clk, rst, pc_start) is
	begin
		if rst = '1' then
			for i in 0 to REGISTER_FILE_SIZE - 2 loop
				register_file(i) <= (others => '0');
			end loop;
			register_file(15) <= pc_start;
		elsif rising_edge(clk) then
			if write_1 = '1' then
				register_file(to_integer(unsigned(select_in_1))) <= data_in_1;
			end if;
			if write_2 = '1' then
				register_file(to_integer(unsigned(select_in_2))) <= data_in_2;
			end if;
			if pc_write = '1' and select_in_1 /= "1111" and select_in_2 /= "1111" then
				register_file(15) <= pc_in;
			end if;
			data_out_1 <= register_file(to_integer(unsigned(select_out_1)));
			data_out_2 <= register_file(to_integer(unsigned(select_out_2)));
			data_out_3 <= register_file(to_integer(unsigned(select_out_3)));
			pc_out     <= register_file(15);

		end if;
	end process;

end RegisterFileImplementation;
