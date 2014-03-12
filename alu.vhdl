library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
port (
	clk: in std_logic;										-- clock
	first, second: std_logic_vector(31 downto 0);	-- input data
	operation: in std_logic_vector(3 downto 0);		-- operation
	output: out std_logic_vector(31 downto 0);		-- output
	carry: out std_logic;									-- carry flag
	zero: out std_logic;										-- zero flag
	negative: out std_logic;								-- negative flag
	overflow: out std_logic;								-- overflow flag
	result_write: in std_logic								-- should save result
);
end ALU;

architecture ALUImplementation of ALU is 
	signal first_operand, second_operand, result, extended_c: signed(32 downto 0) := (others => '0');
	signal c, n, o: std_logic := '0';
	signal z: std_logic := '1';
begin
	first_operand <= signed(first(first'high) & first);
	second_operand <= signed(second(second'high) & second);
	output <= std_logic_vector(result(31 downto 0));

	carry <= c;
	zero <= z;
	negative <= n;
	overflow <= o;
	
	process(clk, result_write)
	begin
		if (rising_edge(clk) and result_write = '1') then
			case operation is 
				when "0100" => -- add
					result <= first_operand + second_operand; 
				when "0010" => -- sub
					result <= first_operand - second_operand;
				when "0101" => -- addc
					result <= first_operand + second_operand + extended_c; -- + carry;
				when "0110" => -- subc
					result <= first_operand - second_operand - extended_c; -- - carry;
				when "0000" => -- and
					result <= first_operand and second_operand;
				when "1111" => -- not
					result <= not first_operand;
				when others =>
					NULL;
			end case;

		end if;
	end process;
	
	process(result)
	begin
		if result = 0 then z <= '1'; else z <= '0'; end if;
		if result(32) /= result(31) then o <= '1'; else o <= '0'; end if;
		n <= result(31);		
		c <= result(32);
	end process;
	
	process(c)
	begin
		extended_c(0) <= c;
	end process;
	
end ALUImplementation;
