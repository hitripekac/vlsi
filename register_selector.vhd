library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customprocessor.all;

entity RegisterSelector is
	port(
		data_in_1   : in  WORD;
		data_in_2   : in  WORD;
		data_in_3   : in  WORD;
		data_out_1  : out WORD;
		data_out_2  : out WORD;
		instruction : in  WORD
	);
end entity RegisterSelector;

architecture RegisterSelectorRTL of RegisterSelector is
begin
	data_out_1 <= std_logic_vector(shift_left(unsigned(data_in_1), to_integer(unsigned(data_in_3)))) when instruction(31 downto 29) = "000" and instruction(7 downto 5) = "000" else --
		std_logic_vector(rotate_left(unsigned(data_in_1), to_integer(unsigned(data_in_3)))) when instruction(31 downto 29) = "000" and instruction(7 downto 5) = "100" else --
		std_logic_vector(shift_right(unsigned(data_in_1), to_integer(unsigned(data_in_3)))) when instruction(31 downto 29) = "000" and instruction(7 downto 5) = "001" else --
		std_logic_vector(rotate_right(unsigned(data_in_1), to_integer(unsigned(data_in_3)))) when instruction(31 downto 29) = "000" and instruction(7 downto 5) = "101" else --
		std_logic_vector(shift_right(signed(data_in_1), to_integer(unsigned(data_in_3)))) when instruction(31 downto 29) = "000" and instruction(7 downto 5) = "010" else --
		std_logic_vector(rotate_right(signed(data_in_1), to_integer(unsigned(data_in_3)))) when instruction(31 downto 29) = "000" and instruction(7 downto 5) = "110" else --
		data_in_1;
	data_out_2 <= std_logic_vector(resize(unsigned(instruction(15 downto 0)), 32)) when instruction(31 downto 29) = "001" and instruction(16) = '1' else --
		"0000000000000000" & instruction(15 downto 0) when instruction(31 downto 29) = "001" and instruction(16) = '0' else --
		std_logic_vector(resize(unsigned(instruction(25 downto 0)), 32)) when instruction(31 downto 29) = "100" else --
		data_in_2;
end architecture RegisterSelectorRTL;
