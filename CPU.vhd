library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.customprocessor.all;

entity CPU is
	port(
		clk      : in    std_logic;     -- clock
		rst      : in    std_logic;
		address  : inout MEMORY_ADDRESS; -- address of the requested location
		data     : inout WORD;
		is_read  : out   std_logic;
		is_write : out   std_logic
	);
end CPU;

architecture CPUImplemetation of CPU is
	signal pc                                              : MEMORY_ADDRESS;
	signal cpu_state                                       : CPU_STATE := CPU_RESET;
	signal instruction_cache_data                          : WORD;
	signal instruction_cache_address                       : MEMORY_ADDRESS;
	signal data_cache_data                                 : WORD;
	signal data_cache_address                              : MEMORY_ADDRESS;
	signal instruction_cache_is_read, data_cache_is_read   : std_logic;
	signal instruction_cache_is_write, data_cache_is_write : std_logic;
	signal instruction_cache_hit, data_cache_hit           : std_logic;

	component Cache is
		port(
			clk          : in    std_logic; -- clock
			address      : in    MEMORY_ADDRESS; -- address of the requested location
			miss_address : out   MEMORY_ADDRESS;
			data         : inout WORD;
			is_read      : in    std_logic;
			is_write     : in    std_logic;
			cache_hit    : out   std_logic
		);
	end component Cache;

	component IFIDRegisters is
		port(
			clk             : in  std_logic;
			rst             : in  std_logic;
			pc_in           : in  MEMORY_ADDRESS;
			instruction_in  : in  WORD;
			pc_out          : out MEMORY_ADDRESS;
			instruction_out : out WORD;
			read            : in  std_logic
		);
	end component IFIDRegisters;

	component IDMEMRRegisters is
		port(
			clk             : std_logic;
			rst             : std_logic;
			pc_in           : in  MEMORY_ADDRESS;
			instruction_in  : in  WORD;
			op1_in          : in  WORD;
			op2_in          : in  WORD;

			pc_out          : out MEMORY_ADDRESS;
			instruction_out : out WORD;
			op1_out         : out WORD;
			op2_out         : out WORD;

			read            : in  std_logic
		);
	end component IDMEMRRegisters;

	component MEMREXRegisters is
		port(
			clk             : std_logic;
			rst             : std_logic;
			pc_in           : in  MEMORY_ADDRESS;
			instruction_in  : in  WORD;
			op1_in          : in  WORD;
			op2_in          : in  WORD;

			pc_out          : out MEMORY_ADDRESS;
			instruction_out : out WORD;
			op1_out         : out WORD;
			op2_out         : out WORD;

			read            : in  std_logic
		);
	end component MEMREXRegisters;

	component EXMEMWRegisters is
		port(
			clk             : std_logic;
			rst             : std_logic;
			pc_in           : in  MEMORY_ADDRESS;
			instruction_in  : in  WORD;
			alu_result_in   : in  WORD;
			swap_result_in  : in  WORD;

			pc_out          : out MEMORY_ADDRESS;
			instruction_out : out WORD;
			alu_result_out  : out WORD;
			swap_result_out : out WORD;

			do_jump_in      : in  std_logic;
			do_jump_out     : out std_logic;

			read            : in  std_logic
		);
	end component EXMEMWRegisters;

	component WBRegisters is
		port(
			clk             : std_logic;
			rst             : std_logic;
			pc_in           : in  MEMORY_ADDRESS;
			instruction_in  : in  WORD;
			alu_result_in   : in  WORD;
			swap_result_in  : in  WORD;

			pc_out          : out MEMORY_ADDRESS;
			alu_result_out  : out WORD;
			swap_result_out : out WORD;

			data_sel_1      : out REGISTER_SELECT_ADDRESS;
			data_sel_2      : out REGISTER_SELECT_ADDRESS;

			data_write_1    : out std_logic;
			data_write_2    : out std_logic;

			do_jump_in      : in  std_logic;
			do_jump_out     : out std_logic;

			read            : in  std_logic
		);
	end component WBRegisters;

	component ALU is
		port(
			clk           : in  std_logic; -- clock
			first, second : in  WORD;   -- input data
			operation     : in  std_logic_vector(3 downto 0); -- operation
			output        : out WORD;   -- output
			carry         : out std_logic; -- carry flag
			zero          : out std_logic; -- zero flag
			negative      : out std_logic; -- negative flag
			overflow      : out std_logic; -- overflow flag
			instruction   : in  std_logic_vector(2 downto 0)
		);
	end component ALU;

	component JumpLink is
		port(
			l_in          : in  std_logic;
			pc_in         : in  WORD;
			alu_result_in : in  WORD;
			link_out      : out WORD
		);
	end component JumpLink;

	component JumpCalc is
		port(
			pc_in   : in  MEMORY_ADDRESS;
			pc_out  : out MEMORY_ADDRESS;
			do_jump : out std_logic;
			offset  : in  WORD;
			c_in    : in  std_logic;
			z_in    : in  std_logic;
			o_in    : in  std_logic;
			n_in    : in  std_logic;
			cond    : in  std_logic_vector(1 downto 0)
		);
	end component JumpCalc;

	signal pc_added                  : MEMORY_ADDRESS;
	signal reg_data_out_1            : WORD;
	signal reg_multi_out             : WORD;
	signal ifid_pc_out               : MEMORY_ADDRESS;
	signal ifid_instruction_out      : WORD;
	signal ifid_read                 : std_logic;
	signal id_memr_pc_out            : MEMORY_ADDRESS;
	signal id_memr_instruction_out   : WORD;
	signal id_memr_op1_out           : WORD;
	signal id_memr_op2_out           : WORD;
	signal id_memr_read              : std_logic;
	signal mem_multiplex_operand_out : WORD;
	signal memr_ex_pc_out            : MEMORY_ADDRESS;
	signal memr_ex_instruction_out   : WORD;
	signal memr_ex_op1_out           : WORD;
	signal memr_ex_op2_out           : WORD;
	signal memr_ex_read              : std_logic;
	signal alu_result_out            : WORD;
	--	signal ex_memw_pc_out            : MEMORY_ADDRESS;
	--	signal ex_memw_instruction_out   : WORD;
	--	signal ex_memw_alu_result_out    : WORD;
	--	signal ex_memw_swap_result_out   : WORD;
	--	signal ex_memw_read              : std_logic;
	--	signal ex_memw_do_jump_out       : std_logic;
	signal wb_pc_out                 : MEMORY_ADDRESS;
	signal wb_alu_result_out         : WORD;
	signal wb_swap_result_out        : WORD;
	signal wb_read                   : std_logic;
	signal jump_calc_c_in            : std_logic;
	signal jump_calc_z_in            : std_logic;
	signal jump_calc_n_in            : std_logic;
	signal jump_calc_o_in            : std_logic;
	signal jump_link_out             : WORD;
	signal jump_calc_do_jump_out     : std_logic;
	signal wb_data_sel_1             : REGISTER_SELECT_ADDRESS;
	signal wb_data_sel_2             : REGISTER_SELECT_ADDRESS;
	signal wb_data_write_1           : std_logic;
	signal wb_data_write_2           : std_logic;
	signal wb_do_jump_out            : std_logic;
	signal jump_calc_pc_out          : MEMORY_ADDRESS;

begin
	instruction_cache : Cache
		port map(clk          => clk,
			     address      => pc,
			     miss_address => instruction_cache_address,
			     data         => instruction_cache_data,
			     is_read      => instruction_cache_is_read,
			     is_write     => instruction_cache_is_write,
			     cache_hit    => instruction_cache_hit);

	data_cache : Cache
		port map(clk          => clk,
			     address      => pc,
			     miss_address => data_cache_address,
			     data         => data_cache_data,
			     is_read      => data_cache_is_read,
			     is_write     => data_cache_is_write,
			     cache_hit    => data_cache_hit);

	pipeline_if_id_registers : IFIDRegisters
		port map(clk             => clk,
			     rst             => rst,
			     pc_in           => pc_added,
			     instruction_in  => instruction_cache_data,
			     pc_out          => ifid_pc_out,
			     instruction_out => ifid_instruction_out,
			     read            => ifid_read);

	pipeline_id_memr_registers : IDMEMRRegisters
		port map(clk             => clk,
			     rst             => rst,
			     pc_in           => ifid_pc_out,
			     instruction_in  => ifid_instruction_out,
			     op1_in          => reg_data_out_1,
			     op2_in          => reg_multi_out,
			     pc_out          => id_memr_pc_out,
			     instruction_out => id_memr_instruction_out,
			     op1_out         => id_memr_op1_out,
			     op2_out         => id_memr_op2_out,
			     read            => id_memr_read);

	pipeline_memr_ex_registers : MEMREXRegisters
		port map(clk             => clk,
			     rst             => rst,
			     pc_in           => id_memr_pc_out,
			     instruction_in  => id_memr_instruction_out,
			     op1_in          => mem_multiplex_operand_out,
			     op2_in          => id_memr_op2_out,
			     pc_out          => memr_ex_pc_out,
			     instruction_out => memr_ex_instruction_out,
			     op1_out         => memr_ex_op1_out,
			     op2_out         => memr_ex_op2_out,
			     read            => memr_ex_read);

	--	pipline_ex_memw_registers : EXMEMWRegisters
	--		port map(clk             => clk,
	--			     rst             => rst,
	--			     pc_in           => jump_calc_pc_out,
	--			     instruction_in  => memr_ex_instruction_out,
	--			     alu_result_in   => jump_link_out,
	--			     swap_result_in  => memr_ex_op2_out,
	--			     pc_out          => ex_memw_pc_out,
	--			     instruction_out => ex_memw_instruction_out,
	--			     alu_result_out  => ex_memw_alu_result_out,
	--			     swap_result_out => ex_memw_swap_result_out,
	--			     do_jump_in      => jump_calc_do_jump_out,
	--			     do_jump_out     => ex_memw_do_jump_out,
	--			     read            => ex_memw_read);

	pipeline_wb_registers : WBRegisters
		port map(clk             => clk,
			     rst             => rst,
			     pc_in           => jump_calc_pc_out,
			     instruction_in  => memr_ex_instruction_out,
			     alu_result_in   => jump_link_out,
			     swap_result_in  => memr_ex_op2_out,
			     pc_out          => wb_pc_out,
			     alu_result_out  => wb_alu_result_out,
			     swap_result_out => wb_swap_result_out,
			     do_jump_in      => jump_calc_do_jump_out,
			     do_jump_out     => wb_do_jump_out,
			     data_sel_1      => wb_data_sel_1,
			     data_sel_2      => wb_data_sel_2,
			     data_write_1    => wb_data_write_1,
			     data_write_2    => wb_data_write_2,
			     read            => wb_read);

	alunit : ALU
		port map(clk         => clk,
			     first       => memr_ex_op1_out,
			     second      => memr_ex_op2_out,
			     operation   => memr_ex_instruction_out(28 downto 25),
			     output      => alu_result_out,
			     carry       => jump_calc_c_in,
			     zero        => jump_calc_z_in,
			     negative    => jump_calc_n_in,
			     overflow    => jump_calc_o_in,
			     instruction => memr_ex_instruction_out(31 downto 29)
		);

	jump_link : JumpLink
		port map(l_in          => memr_ex_instruction_out(31 downto 29) & memr_ex_instruction_out(26),
			     pc_in         => memr_ex_pc_out,
			     alu_result_in => alu_result_out,
			     link_out      => jump_link_out);

	jump_calc : JumpCalc
		port map(pc_in   => memr_ex_pc_out,
			     pc_out  => jump_calc_pc_out,
			     do_jump => jump_calc_do_jump_out,
			     offset  => memr_ex_op2_out,
			     c_in    => jump_calc_c_in,
			     z_in    => jump_calc_z_in,
			     o_in    => jump_calc_o_in,
			     n_in    => jump_calc_n_in,
			     cond    => memr_ex_instruction_out(28 downto 27));

	reset_process : process(rst, instruction_cache_hit, data_cache_hit)
	begin
		if rst = '1' then
			cpu_state <= CPU_RESET;
		elsif rst = '0' then
			cpu_state <= NORMAL;
			if instruction_cache_hit = '0' then
				cpu_state <= INSTRUCTION_CACHE_STALL;
			elsif data_cache_hit = '0' then
				cpu_state <= DATA_CACHE_STALL;
			end if;
		end if;
	end process reset_process;

	cache_miss_process : process(clk)
		variable current            : integer := 0;
		variable address_segment    : unsigned(WORD_IN_BITS - 1 downto CACHE_BLOCK_ADDRESS_SIZE);
		variable address_offset     : unsigned(CACHE_BLOCK_ADDRESS_SIZE - 1 downto 0);
		variable current_pipe_clock : integer := 0;
	begin
		if rising_edge(clk) then
			if cpu_state = NORMAL then
			elsif ((cpu_state = INSTRUCTION_CACHE_STALL) or (cpu_state = DATA_CACHE_STALL)) then
				if current = 0 then
					if cpu_state = INSTRUCTION_CACHE_STALL then
						address_segment := unsigned(pc(WORD_IN_BITS - 1 downto CACHE_BLOCK_ADDRESS_SIZE));
					else
						address_segment := unsigned(pc(WORD_IN_BITS - 1 downto CACHE_BLOCK_ADDRESS_SIZE));
					end if;
				end if;
				if current < 4 then
					is_read        <= '1';
					is_write       <= '0';
					address        <= std_logic_vector(address_segment) & std_logic_vector(address_offset);
					address_offset := address_offset + 1;
					current        := current + 1;
					if current = 3 then
						if cpu_state = INSTRUCTION_CACHE_STALL then
							instruction_cache_address <= std_logic_vector(address_segment) & std_logic_vector(address_offset);
							instruction_cache_is_read <= '1';
						else
							data_cache_address <= std_logic_vector(address_segment) & std_logic_vector(address_offset);
							data_cache_is_read <= '1';
						end if;
					end if;
				elsif current < 8 then
					is_read        <= '1';
					is_write       <= '0';
					address_offset := address_offset + 1;
					current        := current + 1;
					if cpu_state = INSTRUCTION_CACHE_STALL then
						instruction_cache_address  <= std_logic_vector(address_segment) & std_logic_vector(address_offset);
						instruction_cache_is_read  <= '1';
						instruction_cache_is_write <= '0';
						data                       <= instruction_cache_data;
					else
						data_cache_address  <= std_logic_vector(address_segment) & std_logic_vector(address_offset);
						data_cache_is_read  <= '1';
						data_cache_is_write <= '0';
						data                <= data_cache_data;
					end if;
				elsif current <= 12 then
					is_read  <= '0';
					is_write <= '0';
				elsif current > 12 then
					is_read        <= '0';
					is_write       <= '0';
					address_offset := address_offset + 1;
					current        := current + 1;
					if cpu_state = INSTRUCTION_CACHE_STALL then
						instruction_cache_address  <= std_logic_vector(address_segment) & std_logic_vector(address_offset);
						data_cache_is_read         <= '0';
						instruction_cache_is_write <= '1';
						data                       <= instruction_cache_data;
					else
						data_cache_address  <= std_logic_vector(address_segment) & std_logic_vector(address_offset);
						data_cache_is_read  <= '0';
						data_cache_is_write <= '1';
						data                <= data_cache_data;
					end if;
				end if;
			else
				current := 0;
			end if;

		end if;
	end process cache_miss_process;
end architecture CPUImplemetation;
