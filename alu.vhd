library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.customprocessor.all;

entity ALU is
	port(
		clk            : in  std_logic; -- clock
		first, second  : in  WORD;      -- input data
		operation      : in  std_logic_vector(3 downto 0); -- operation
		output         : out WORD;      -- output
		carry          : out std_logic; -- carry flag
		zero           : out std_logic; -- zero flag
		negative       : out std_logic; -- negative flag
		overflow       : out std_logic; -- overflow flag
		s              : in  std_logic;
		pass_second_op : in  std_logic;
		instruction    : in  std_logic_vector(2 downto 0)
	);
end ALU;

architecture ALUImplementation of ALU is
	signal first_operand, second_operand, result, extended_c : signed(32 downto 0) := (others => '0');
	signal c, n, o                                           : std_logic           := '0';
	signal z                                                 : std_logic           := '1';
begin
	first_operand  <= signed(first(first'high) & first);
	second_operand <= signed(second(second'high) & second);
	output         <= std_logic_vector(result(31 downto 0));

	carry    <= c;
	zero     <= z;
	negative <= n;
	overflow <= o;

	process(clk)
	begin
		if (rising_edge(clk)) then
			if pass_second_op = '1' then
				result <= second_operand;
			else
				case operation is
					when "0100" =>      -- add
						result <= first_operand + second_operand;
					when "0010" =>      -- sub
						result <= first_operand - second_operand;
					when "1010" =>      -- cmp
						result <= first_operand - second_operand;
					when "0101" =>      -- addc
						result <= first_operand + second_operand + extended_c; -- + carry;
					when "0110" =>      -- subc
						result <= first_operand - second_operand - extended_c; -- - carry;
					when "0000" =>      -- and
						result <= first_operand and second_operand;
					when "1111" =>      -- not
						result <= not first_operand;
					when others =>
						NULL;
				end case;
			end if;
		end if;
	end process;

	process(result, s, instruction)
	begin
		if instruction = "000" or instruction = "001" or instruction = "011" then
			z <= '1' when result = 0 else '0';
			o <= '1' when result(32) /= result(31) and s = '1' else '0';
			n <= result(31);
			c <= result(32) when s = '0' else '0';
		end if;

	end process;

	process(c)
	begin
		extended_c(0) <= c;
	end process;

end ALUImplementation;
