library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customprocessor.all;

entity PcSelect is
	port(
		do_jump_in : in  std_logic;
		pc_in      : in  WORD;
		pc_jump    : in  WORD;
		pc_out     : out WORD
	);
end entity PcSelect;

architecture PcSelectRTL of PcSelect is
begin
	pc_out <= pc_jump when do_jump_in = '1' else std_logic_vector(unsigned(pc_in) + 1);
end architecture PcSelectRTL;
