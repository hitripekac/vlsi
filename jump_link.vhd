library ieee;
use ieee.std_logic_1164.all;
use work.customprocessor.all;

entity JumpLink is
	port(
		op_in         : in  std_logic_vector(3 downto 0);
		pc_in         : in  WORD;
		alu_result_in : in  WORD;
		link_out      : out WORD
	);
end entity JumpLink;

architecture JumpLinkRTL of JumpLink is
begin
	link_out <= pc_in when op_in = "1001" else alu_result_in;
end architecture JumpLinkRTL;
