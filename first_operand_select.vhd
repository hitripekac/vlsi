library ieee;
use ieee.std_logic_1164.all;
use work.customprocessor.all;

entity OperandSelect is
	port(
		instruction : in  WORD;
		sel_1_out   : out REGISTER_SELECT_ADDRESS;
		sel_2_out   : out REGISTER_SELECT_ADDRESS
	);
end entity OperandSelect;

architecture OperandSelectRTL of OperandSelect is
begin
	sel_1_out <= instruction(20 downto 17) when instruction(31 downto 25) = "0001000" else instruction(24 downto 21);
	sel_2_out <= instruction(20 downto 17) when instruction(31 downto 29) = "010" else instruction(15 downto 12);
end architecture OperandSelectRTL;
