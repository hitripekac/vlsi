library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customprocessor.all;

entity JumpCalc is
	port(
		pc_in   : in  MEMORY_ADDRESS;
		pc_out  : out MEMORY_ADDRESS;
		do_jump : out std_logic;
		offset  : in  WORD;
		c_in    : in  std_logic;
		z_in    : in  std_logic;
		o_in    : in  std_logic;
		n_in    : in  std_logic;
		brinstr : in  std_logic_vector(2 downto 0);
		cond    : in  std_logic_vector(1 downto 0)
	);
end entity JumpCalc;

architecture JumpCalcRTL of JumpCalc is
begin
	pc_out <= std_logic_vector(signed(pc_in) + signed(offset) + 1);

	do_jump <= '1' when (cond = "00" and z_in = '1' and brinstr = "100") else '1' when (cond = "01" and n_in = '0' and o_in = '0' and brinstr = "100") else '1' when (cond = "10" and n_in = '0' and c_in = '0' and brinstr = "100") else '1' when (cond = "11" and brinstr = "100") else '0';
end architecture JumpCalcRTL;
