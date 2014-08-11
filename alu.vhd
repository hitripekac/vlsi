library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.customprocessor.all;

entity ALU is
	port(
		clk           : in  std_logic;  -- clock
		rst           : in  std_logic;
		first, second : in  WORD;       -- input data
		operation     : in  std_logic_vector(3 downto 0); -- operation
		output        : out WORD;       -- output
		carry         : out std_logic;  -- carry flag
		zero          : out std_logic;  -- zero flag
		negative      : out std_logic;  -- negative flag
		overflow      : out std_logic;  -- overflow flag
		instruction   : in  WORD;
		save_result   : in  std_logic);
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

	process(clk, rst)
	begin
		if rst = '1' then
			result <= (others => '0');
		elsif (rising_edge(clk)) then
			if instruction(31 downto 25) = "0001101" or instruction(31 downto 25) = "0011101" or instruction(31 downto 25) = "0001000" or instruction(31 downto 25) = "0111101" then
				result <= second_operand;
			elsif instruction(31 downto 29) = "010" then
				result <= first_operand;
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

	process(rst, result, instruction, save_result)
	begin
		if rst = '1' then
			c <= '0';
			n <= '0';
			o <= '0';
			z <= '0';
		elsif (instruction(31 downto 29) = "000" and not (instruction(28 downto 25) = "1101" or instruction(28 downto 25) = "1000")) or (instruction(31 downto 29) = "001" and not instruction(28 downto 25) = "1101") or (instruction(31 downto 29) = "011" and not instruction(28 downto 25
			) = "1101") then
			if save_result = '1' then
				if result = 0 then
					z <= '1';
				else
					z <= '0';
				end if;
				if (result(32) /= result(31)) and (instruction(16) = '1') then
					o <= '1';
				else
					o <= '0';
				end if;
				n <= result(31);
				if instruction(16) = '0' then
					c <= result(32);
				else
					c <= '0';
				end if;
			end if;
		end if;

	end process;

	process(c)
	begin
		extended_c(0) <= c;
	end process;

end ALUImplementation;
