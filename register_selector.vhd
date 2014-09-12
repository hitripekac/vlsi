library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customprocessor.all;

entity RegisterSelector is
	port(
		data_in_1           : in  WORD;
		data_in_2           : in  WORD;
		data_in_3           : in  WORD;

		forward_data_1      : in  WORD;
		forward_data_2      : in  WORD;

		forward_instruction : in  WORD;

		stall_instruction   : in  WORD;
		stall_out           : out std_logic;
		stall_can_happen    : in  std_logic;

		data_out_1          : out WORD;
		data_out_2          : out WORD;
		instruction         : in  WORD
	);
end entity RegisterSelector;

architecture RegisterSelectorRTL of RegisterSelector is
begin
	process(instruction, stall_instruction, stall_can_happen, forward_instruction)
		variable stall                         : std_logic;
		variable take_from_forward_destination : boolean;
	begin
		stall                         := '0';
		take_from_forward_destination := (stall_instruction(31 downto 29) = "000" and stall_instruction(28 downto 25) /= "1010") or (stall_instruction(31 downto 29) = "001" and stall_instruction(28 downto 25) /= "1010") or stall_instruction(31 downto 28) = "0101";
		if instruction(31 downto 28) = "0101" and (forward_instruction(31 downto 28) = "0100" or stall_instruction(31 downto 28) = "0100") then
			stall := '1';
		end if;
		if instruction(31 downto 25) = "0001000" then
			if stall_instruction(31 downto 25) = "0001000" then
				if instruction(20 downto 17) = stall_instruction(20 downto 17) then
					stall := '1';
				elsif instruction(20 downto 17) = stall_instruction(15 downto 12) then
					stall := '1';
				end if;
			else
				if instruction(20 downto 17) = stall_instruction(20 downto 17) and (
					take_from_forward_destination
				) then
					stall := '1';
				end if;
			end if;
		elsif instruction(31 downto 29) = "000" or instruction(31 downto 29) = "001" or instruction(31 downto 29) = "010" then
			if stall_instruction(31 downto 25) = "0001000" then
				if instruction(24 downto 21) = stall_instruction(20 downto 17) then
					stall := '1';
				elsif instruction(24 downto 21) = stall_instruction(15 downto 12) then
					stall := '1';
				end if;
			else
				if instruction(24 downto 21) = stall_instruction(20 downto 17) and (
					take_from_forward_destination
				) then
					stall := '1';
				end if;
			end if;
		end if;

		if instruction(31 downto 29) = "010" then
			if stall_instruction(31 downto 25) = "0001000" then
				if instruction(20 downto 17) = stall_instruction(20 downto 17) then
					stall := '1';
				elsif instruction(20 downto 17) = stall_instruction(15 downto 12) then
					stall := '1';
				end if;
			else
				if instruction(20 downto 17) = stall_instruction(20 downto 17) and (
					take_from_forward_destination
				) then
					stall := '1';
				end if;
			end if;
		elsif instruction(31 downto 29) = "000" then
			if stall_instruction(31 downto 25) = "0001000" then
				if instruction(15 downto 12) = stall_instruction(20 downto 17) then
					stall := '1';
				elsif instruction(15 downto 12) = stall_instruction(15 downto 12) then
					stall := '1';
				end if;
			else
				if instruction(15 downto 12) = stall_instruction(20 downto 17) and (
					take_from_forward_destination
				) then
					stall := '1';
				end if;
			end if;
		end if;

		if instruction(31 downto 28) = "0000" and instruction(6 downto 5) /= "11" then
			if stall_instruction(31 downto 25) = "0001000" then
				if instruction(11 downto 8) = stall_instruction(20 downto 17) then
					stall := '1';
				elsif instruction(11 downto 8) = stall_instruction(15 downto 12) then
					stall := '1';
				end if;
			else
				if instruction(11 downto 8) = stall_instruction(20 downto 17) and (
					take_from_forward_destination
				) then
					stall := '1';
				end if;
			end if;
		end if;
		if stall_can_happen = '1' then
			stall_out <= stall;
		else
			stall_out <= '0';
		end if;
	end process;

	process(data_in_1, data_in_2, data_in_3, instruction, forward_instruction, forward_data_1, forward_data_2)
		variable hazard_data_in_1              : WORD;
		variable hazard_data_in_2              : WORD;
		variable hazard_data_in_3              : WORD;
		variable take_from_forward_destination : boolean;
	begin

		-- hazard_data_1
		take_from_forward_destination := (forward_instruction(31 downto 29) = "000" and forward_instruction(28 downto 25) /= "1010") or (forward_instruction(31 downto 29) = "001" and forward_instruction(28 downto 25) /= "1010") or forward_instruction(31 downto 28) = "0101";
		hazard_data_in_1              := data_in_1;
		if instruction(31 downto 25) = "0001000" then
			if forward_instruction(31 downto 25) = "0001000" then
				if instruction(20 downto 17) = forward_instruction(20 downto 17) then
					hazard_data_in_1 := forward_data_1;
				elsif instruction(20 downto 17) = forward_instruction(15 downto 12) then
					hazard_data_in_1 := forward_data_2;
				end if;
			else
				if instruction(20 downto 17) = forward_instruction(20 downto 17) and (
					take_from_forward_destination
				) then
					hazard_data_in_1 := forward_data_1;
				end if;
			end if;
		elsif instruction(31 downto 29) = "000" or instruction(31 downto 29) = "001" or instruction(31 downto 29) = "010" then
			if forward_instruction(31 downto 25) = "0001000" then
				if instruction(24 downto 21) = forward_instruction(20 downto 17) then
					hazard_data_in_1 := forward_data_1;
				elsif instruction(24 downto 21) = forward_instruction(15 downto 12) then
					hazard_data_in_1 := forward_data_2;
				end if;
			else
				if instruction(24 downto 21) = forward_instruction(20 downto 17) and (
					take_from_forward_destination
				) then
					hazard_data_in_1 := forward_data_1;
				end if;
			end if;
		end if;

		hazard_data_in_2 := data_in_2;
		if instruction(31 downto 29) = "010" then
			if forward_instruction(31 downto 25) = "0001000" then
				if instruction(20 downto 17) = forward_instruction(20 downto 17) then
					hazard_data_in_2 := forward_data_1;
				elsif instruction(20 downto 17) = forward_instruction(15 downto 12) then
					hazard_data_in_2 := forward_data_2;
				end if;
			else
				if instruction(20 downto 17) = forward_instruction(20 downto 17) and (
					take_from_forward_destination
				) then
					hazard_data_in_2 := forward_data_1;
				end if;
			end if;
		elsif instruction(31 downto 29) = "000" then
			if forward_instruction(31 downto 25) = "0001000" then
				if instruction(15 downto 12) = forward_instruction(20 downto 17) then
					hazard_data_in_2 := forward_data_1;
				elsif instruction(15 downto 12) = forward_instruction(15 downto 12) then
					hazard_data_in_2 := forward_data_2;
				end if;
			else
				if instruction(15 downto 12) = forward_instruction(20 downto 17) and (
					take_from_forward_destination
				) then
					hazard_data_in_2 := forward_data_1;
				end if;
			end if;
		end if;

		hazard_data_in_3 := data_in_3;

		if instruction(31 downto 28) = "0000" and instruction(6 downto 5) /= "11" then
			if forward_instruction(31 downto 25) = "0001000" then
				if instruction(11 downto 8) = forward_instruction(20 downto 17) then
					hazard_data_in_3 := forward_data_1;
				elsif instruction(11 downto 8) = forward_instruction(15 downto 12) then
					hazard_data_in_3 := forward_data_2;
				end if;
			else
				if instruction(11 downto 8) = forward_instruction(20 downto 17) and (
					take_from_forward_destination
				) then
					hazard_data_in_3 := forward_data_1;
				end if;
			end if;
		end if;

		if instruction(31 downto 29) = "000" and instruction(28 downto 25) /= "1000" and instruction(28 downto 25) /= "1101" and instruction(7 downto 5) = "000" then
			data_out_1 <= std_logic_vector(shift_left(unsigned(hazard_data_in_1), to_integer(unsigned(hazard_data_in_3))));
		elsif instruction(31 downto 29) = "000" and instruction(28 downto 25) /= "1000" and instruction(28 downto 25) /= "1101" and instruction(7 downto 5) = "100" then
			data_out_1 <= std_logic_vector(rotate_left(unsigned(hazard_data_in_1), to_integer(unsigned(hazard_data_in_3))));
		elsif instruction(31 downto 29) = "000" and instruction(28 downto 25) /= "1000" and instruction(28 downto 25) /= "1101" and instruction(7 downto 5) = "001" then
			data_out_1 <= std_logic_vector(shift_right(unsigned(hazard_data_in_1), to_integer(unsigned(hazard_data_in_3))));
		elsif instruction(31 downto 29) = "000" and instruction(28 downto 25) /= "1000" and instruction(28 downto 25) /= "1101" and instruction(7 downto 5) = "101" then
			data_out_1 <= std_logic_vector(rotate_right(unsigned(hazard_data_in_1), to_integer(unsigned(hazard_data_in_3))));
		elsif instruction(31 downto 29) = "000" and instruction(28 downto 25) /= "1000" and instruction(28 downto 25) /= "1101" and instruction(7 downto 5) = "010" then
			data_out_1 <= std_logic_vector(shift_right(signed(hazard_data_in_1), to_integer(unsigned(hazard_data_in_3))));
		elsif instruction(31 downto 29) = "000" and instruction(28 downto 25) /= "1000" and instruction(28 downto 25) /= "1101" and instruction(7 downto 5) = "110" then
			data_out_1 <= std_logic_vector(rotate_right(signed(hazard_data_in_1), to_integer(unsigned(hazard_data_in_3))));
		else
			data_out_1 <= hazard_data_in_1;
		end if;

		if instruction(31 downto 29) = "001" and instruction(16) = '1' then
			data_out_2 <= std_logic_vector(resize(signed(instruction(15 downto 0)), 32));
		elsif instruction(31 downto 29) = "001" and instruction(16) = '0' then
			data_out_2 <= "0000000000000000" & instruction(15 downto 0);
		elsif instruction(31 downto 29) = "100" then
			data_out_2 <= std_logic_vector(resize(signed(instruction(25 downto 0)), 32));
		else
			data_out_2 <= hazard_data_in_2;
		end if;

	end process;

end architecture RegisterSelectorRTL;
