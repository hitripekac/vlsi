LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY alu_testbench IS
END alu_testbench;

ARCHITECTURE ALUTestbenchImplementation of alu_testbench IS 

   signal clk : std_logic := '0';
   signal first, second, result: std_logic_vector(31 downto 0) := (others => '0');
   signal operation : std_logic_vector(3 downto 0) := (others => '0');
	signal carry, zero, negative, overflow: std_logic; 
   
	constant clk_period : time := 10 ns;
	
BEGIN

    -- Instantiate the Unit Under Test (UUT)
   uut: entity work.ALU PORT MAP (
		 clk => clk,
		 first => first,
		 second => second,
		 operation => operation,
		 output => result,
		 carry => carry,
		 zero => zero,
		 negative => negative,
		 overflow => overflow
	);

   clk_process: process
   begin
        clk <= '0'; wait for clk_period / 2;
        clk <= '1'; wait for clk_period / 2;
   end process;
    
   -- Stimulus process
   stim_proc: process
   begin        
	wait for clk_period * 1;
	first <= "10000000000000000000000000010010"; -- 18 in decimal
	second <= "10000000000000000000000000010010"; -- 10 in decimal
	operation <= "0100"; wait for clk_period;
	operation <= "0010"; wait for clk_period;
	operation <= "0101"; wait for clk_period;
	operation <= "0110"; wait for clk_period;
	operation <= "0000"; wait for clk_period;
	operation <= "1111"; wait for clk_period;
	wait;
	end process;

END ALUTestbenchImplementation;