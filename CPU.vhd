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
		is_write : out   std_logic;
		pc_start : in    WORD
	);
end CPU;

architecture CPUImplemetation of CPU is
	signal cpu_state                                             : CPU_STATE := CPU_RESET;
	signal instruction_cache_data_in, instruction_cache_data_out : WORD;
	signal instruction_cache_address                             : MEMORY_ADDRESS;
	signal data_cache_data_in, data_cache_data_out               : WORD;
	signal data_cache_address                                    : MEMORY_ADDRESS;
	signal instruction_cache_is_read, data_cache_is_read         : std_logic;
	signal instruction_cache_is_write, data_cache_is_write       : std_logic;
	signal instruction_cache_hit, data_cache_hit                 : std_logic;

	component Cache is
		port(
			clk          : in  std_logic; -- clock
			rst          : std_logic;
			address      : in  MEMORY_ADDRESS; -- address of the requested location
			miss_address : out MEMORY_ADDRESS;
			data_in      : in  WORD;
			data_out     : out WORD;
			mem_data_in  : in  WORD;
			mem_address  : in  MEMORY_ADDRESS;
			is_read      : in  std_logic;
			is_write     : in  std_logic;
			is_from_mem  : in  std_logic;
			cache_hit    : out std_logic;
			write_back   : out std_logic;
			read0write1  : out std_logic
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
			rn_address_in   : in  WORD;
			rn_address_out  : out WORD;
			op1_in          : in  WORD;
			op2_in          : in  WORD;

			pc_out          : out MEMORY_ADDRESS;
			instruction_out : out WORD;
			op1_out         : out WORD;
			op2_out         : out WORD;

			read            : in  std_logic
		);
	end component MEMREXRegisters;

	--	component EXMEMWRegisters is
	--		port(
	--			clk             : std_logic;
	--			rst             : std_logic;
	--			pc_in           : in  MEMORY_ADDRESS;
	--			instruction_in  : in  WORD;
	--			alu_result_in   : in  WORD;
	--			swap_result_in  : in  WORD;
	--
	--			pc_out          : out MEMORY_ADDRESS;
	--			instruction_out : out WORD;
	--			alu_result_out  : out WORD;
	--			swap_result_out : out WORD;
	--
	--			do_jump_in      : in  std_logic;
	--			do_jump_out     : out std_logic;
	--
	--			read            : in  std_logic
	--		);
	--	end component EXMEMWRegisters;

	component WBRegisters is
		port(
			clk             : std_logic;
			rst             : std_logic;
			pc_in           : in  MEMORY_ADDRESS;
			instruction_in  : in  WORD;
			alu_result_in   : in  WORD;
			swap_result_in  : in  WORD;

			stop_out        : out std_logic;

			rn_address_in   : in  WORD;

			pc_out          : out MEMORY_ADDRESS;
			alu_result_out  : out WORD;
			swap_result_out : out WORD;

			data_sel_1      : out REGISTER_SELECT_ADDRESS;
			data_sel_2      : out REGISTER_SELECT_ADDRESS;

			data_write_1    : out std_logic;
			data_write_2    : out std_logic;

			do_jump_in      : in  std_logic;
			do_jump_out     : out std_logic;

			mem_address_out : out WORD;
			mem_data_out    : out WORD;
			mem_write_out   : out std_logic;

			read            : in  std_logic
		);
	end component WBRegisters;

	component ALU is
		port(
			clk           : in  std_logic; -- clock
			rst           : std_logic;
			first, second : in  WORD;   -- input data
			operation     : in  std_logic_vector(3 downto 0); -- operation
			output        : out WORD;   -- output
			carry         : out std_logic; -- carry flag
			zero          : out std_logic; -- zero flag
			negative      : out std_logic; -- negative flag
			overflow      : out std_logic; -- overflow flag
			instruction   : in  WORD;
			save_result   : in  std_logic
		);
	end component ALU;

	component JumpLink is
		port(
			op_in         : in  std_logic_vector(3 downto 0);
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

	component RegisterFile is
		port(
			clk          : in  std_logic;
			rst          : in  std_logic;
			pc_start     : in  WORD;

			select_out_1 : in  REGISTER_SELECT_ADDRESS;
			select_out_2 : in  REGISTER_SELECT_ADDRESS;
			select_out_3 : in  REGISTER_SELECT_ADDRESS;
			data_out_1   : out WORD;
			data_out_2   : out WORD;
			data_out_3   : out WORD;

			select_in_1  : in  REGISTER_SELECT_ADDRESS;
			select_in_2  : in  REGISTER_SELECT_ADDRESS;
			data_in_1    : in  WORD;
			data_in_2    : in  WORD;
			write_1      : in  std_logic;
			write_2      : in  std_logic;

			pc_in        : in  WORD;
			pc_write     : in  std_logic;
			pc_out       : out WORD
		);
	end component RegisterFile;

	component RegisterSelector is
		port(
			data_in_1   : in  WORD;
			data_in_2   : in  WORD;
			data_in_3   : in  WORD;
			data_out_1  : out WORD;
			data_out_2  : out WORD;
			instruction : in  WORD
		);
	end component RegisterSelector;

	component OperandSelect is
		port(
			instruction : in  WORD;
			sel_1_out   : out REGISTER_SELECT_ADDRESS;
			sel_2_out   : out REGISTER_SELECT_ADDRESS
		);
	end component OperandSelect;

	component DataCacheAddressMultiplexer is
		port(
			read_write    : in  std_logic;
			write_address : in  WORD;
			read_address  : in  WORD;
			out_address   : out WORD
		);
	end component DataCacheAddressMultiplexer;

	component MemMultiplexer is
		port(
			from_mem         : in  std_logic;
			register_operand : in  WORD;
			memory_operand   : in  WORD;
			operand_out      : out WORD
		);
	end component MemMultiplexer;

	component PcSelect is
		port(
			do_jump_in : in  std_logic;
			pc_in      : in  WORD;
			pc_jump    : in  WORD;
			pc_out     : out WORD
		);
	end component PcSelect;

	signal ifid_pc_out                        : MEMORY_ADDRESS;
	signal ifid_instruction_out               : WORD;
	signal ifid_read                          : std_logic;
	signal id_memr_pc_out                     : MEMORY_ADDRESS;
	signal id_memr_instruction_out            : WORD;
	signal id_memr_op1_out                    : WORD;
	signal id_memr_op2_out                    : WORD;
	signal id_memr_read                       : std_logic;
	signal mem_multiplex_operand_out          : WORD;
	signal memr_ex_pc_out                     : MEMORY_ADDRESS;
	signal memr_ex_instruction_out            : WORD;
	signal memr_ex_op1_out                    : WORD;
	signal memr_ex_op2_out                    : WORD;
	signal memr_ex_read                       : std_logic;
	signal alu_result_out                     : WORD;
	--	signal ex_memw_pc_out            : MEMORY_ADDRESS;
	--	signal ex_memw_instruction_out   : WORD;
	--	signal ex_memw_alu_result_out    : WORD;
	--	signal ex_memw_swap_result_out   : WORD;
	--	signal ex_memw_read              : std_logic;
	--	signal ex_memw_do_jump_out       : std_logic;
	signal wb_pc_out                          : MEMORY_ADDRESS;
	signal wb_alu_result_out                  : WORD;
	signal wb_swap_result_out                 : WORD;
	signal wb_read                            : std_logic;
	signal jump_calc_c_in                     : std_logic;
	signal jump_calc_z_in                     : std_logic;
	signal jump_calc_n_in                     : std_logic;
	signal jump_calc_o_in                     : std_logic;
	signal jump_link_out                      : WORD;
	signal jump_calc_do_jump_out              : std_logic;
	signal wb_data_sel_1                      : REGISTER_SELECT_ADDRESS;
	signal wb_data_sel_2                      : REGISTER_SELECT_ADDRESS;
	signal wb_data_write_1                    : std_logic;
	signal wb_data_write_2                    : std_logic;
	signal wb_do_jump_out                     : std_logic;
	signal jump_calc_pc_out                   : MEMORY_ADDRESS;
	signal reg_file_pc_out                    : MEMORY_ADDRESS;
	signal pc_select_out                      : WORD;
	signal reg_file_data_out_1                : WORD;
	signal reg_file_data_out_2                : WORD;
	signal reg_file_data_out_3                : WORD;
	signal pc_write                           : std_logic;
	signal reg_sel_data_out_1                 : WORD;
	signal reg_sel_data_out_2                 : WORD;
	signal instruction_cache_is_from_mem      : std_logic;
	signal data_cache_is_from_mem             : std_logic;
	signal instruction_cache_was_write        : std_logic;
	signal data_cache_was_write               : std_logic;
	signal instruction_cache_write_back       : std_logic;
	signal data_cache_write_back              : std_logic;
	signal op_select_1_out                    : REGISTER_SELECT_ADDRESS;
	signal op_select_2_out                    : REGISTER_SELECT_ADDRESS;
	signal mem_ex_rn_address_out              : WORD;
	signal data_cache_address_multiplexer_out : MEMORY_ADDRESS;
	signal wb_mem_address_out                 : WORD;
	signal wb_mem_data_out                    : WORD;
	signal wb_mem_write_out                   : std_logic;
	signal data_cache_read_write_in           : std_logic;
	signal mem_multiplexer_from_mem_in        : std_logic;
	signal alu_save_result_in                 : std_logic;
	signal instruction_cache_miss_address     : MEMORY_ADDRESS;
	signal data_cache_miss_address            : MEMORY_ADDRESS;
	signal wb_stop_out                        : std_logic;

begin
	instruction_cache : Cache
		port map(clk          => clk,
			     rst          => rst,
			     address      => instruction_cache_address,
			     miss_address => instruction_cache_miss_address,
			     data_in      => instruction_cache_data_in,
			     data_out     => instruction_cache_data_out,
			     mem_data_in  => data,
			     mem_address  => address,
			     is_read      => instruction_cache_is_read,
			     is_write     => instruction_cache_is_write,
			     is_from_mem  => instruction_cache_is_from_mem,
			     cache_hit    => instruction_cache_hit,
			     write_back   => instruction_cache_write_back,
			     read0write1  => instruction_cache_was_write);

	data_cache : Cache
		port map(clk          => clk,
			     rst          => rst,
			     address      => data_cache_address, -- data_cache_address_multiplexer_out, 
			     miss_address => data_cache_miss_address,
			     data_in      => data_cache_data_in, --wb_mem_address_out,
			     data_out     => data_cache_data_out,
			     mem_data_in  => data,
			     mem_address  => address,
			     is_read      => data_cache_is_read,
			     is_write     => data_cache_is_write,
			     is_from_mem  => data_cache_is_from_mem,
			     cache_hit    => data_cache_hit,
			     write_back   => data_cache_write_back,
			     read0write1  => data_cache_was_write);

	pipeline_if_id_registers : IFIDRegisters
		port map(clk             => clk,
			     rst             => rst,
			     pc_in           => reg_file_pc_out,
			     instruction_in  => instruction_cache_data_out,
			     pc_out          => ifid_pc_out,
			     instruction_out => ifid_instruction_out,
			     read            => ifid_read);

	pipeline_id_memr_registers : IDMEMRRegisters
		port map(clk             => clk,
			     rst             => rst,
			     pc_in           => ifid_pc_out,
			     instruction_in  => ifid_instruction_out,
			     op1_in          => reg_sel_data_out_1,
			     op2_in          => reg_sel_data_out_2,
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
			     rn_address_in   => id_memr_op1_out,
			     rn_address_out  => mem_ex_rn_address_out,
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
			     rn_address_in   => mem_ex_rn_address_out,
			     stop_out        => wb_stop_out,
			     swap_result_in  => memr_ex_op1_out,
			     pc_out          => wb_pc_out,
			     alu_result_out  => wb_alu_result_out,
			     swap_result_out => wb_swap_result_out,
			     do_jump_in      => jump_calc_do_jump_out,
			     do_jump_out     => wb_do_jump_out,
			     data_sel_1      => wb_data_sel_1,
			     data_sel_2      => wb_data_sel_2,
			     data_write_1    => wb_data_write_1,
			     data_write_2    => wb_data_write_2,
			     mem_address_out => wb_mem_address_out,
			     mem_data_out    => wb_mem_data_out,
			     mem_write_out   => wb_mem_write_out,
			     read            => wb_read);

	alunit : ALU
		port map(clk         => clk,
			     rst         => rst,
			     first       => memr_ex_op1_out,
			     second      => memr_ex_op2_out,
			     operation   => memr_ex_instruction_out(28 downto 25),
			     output      => alu_result_out,
			     carry       => jump_calc_c_in,
			     zero        => jump_calc_z_in,
			     negative    => jump_calc_n_in,
			     overflow    => jump_calc_o_in,
			     instruction => memr_ex_instruction_out,
			     save_result => alu_save_result_in
		);

	jump_link : JumpLink
		port map(op_in         => memr_ex_instruction_out(31 downto 29) & memr_ex_instruction_out(26),
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

	register_file : RegisterFile
		port map(clk          => clk,
			     rst          => rst,
			     pc_start     => pc_start,
			     select_out_1 => op_select_1_out,
			     select_out_2 => op_select_2_out,
			     select_out_3 => ifid_instruction_out(11 downto 8),
			     data_out_1   => reg_file_data_out_1,
			     data_out_2   => reg_file_data_out_2,
			     data_out_3   => reg_file_data_out_3,
			     select_in_1  => wb_data_sel_1,
			     select_in_2  => wb_data_sel_2,
			     data_in_1    => wb_alu_result_out,
			     data_in_2    => wb_swap_result_out,
			     write_1      => wb_data_write_1,
			     write_2      => wb_data_write_2,
			     pc_in        => pc_select_out,
			     pc_write     => pc_write,
			     pc_out       => reg_file_pc_out);

	register_select : RegisterSelector
		port map(data_in_1   => reg_file_data_out_1,
			     data_in_2   => reg_file_data_out_2,
			     data_in_3   => reg_file_data_out_3,
			     data_out_1  => reg_sel_data_out_1,
			     data_out_2  => reg_sel_data_out_2,
			     instruction => ifid_instruction_out);

	operand_select : OperandSelect
		port map(instruction => ifid_instruction_out,
			     sel_1_out   => op_select_1_out,
			     sel_2_out   => op_select_2_out);

	data_cache_address_multiplexer : DataCacheAddressMultiplexer
		port map(read_write    => data_cache_read_write_in,
			     write_address => wb_mem_address_out,
			     read_address  => id_memr_op1_out,
			     out_address   => data_cache_address_multiplexer_out);

	mem_multiplexer : MemMultiplexer
		port map(from_mem         => mem_multiplexer_from_mem_in,
			     register_operand => id_memr_op1_out,
			     memory_operand   => data_cache_data_out,
			     operand_out      => mem_multiplex_operand_out);

	pc_selector : PcSelect
		port map(do_jump_in => wb_do_jump_out,
			     pc_in      => reg_file_pc_out,
			     pc_jump    => wb_pc_out,
			     pc_out     => pc_select_out);

	reset_process : process(rst, instruction_cache_hit, data_cache_hit, wb_stop_out)
	begin
		if rst = '1' then
			cpu_state <= CPU_RESET;
		elsif rst = '0' then
			cpu_state <= NORMAL;
			if instruction_cache_hit = '0' then
				cpu_state <= INSTRUCTION_CACHE_STALL;
			elsif data_cache_hit = '0' then
				cpu_state <= DATA_CACHE_STALL;
			elsif wb_stop_out = '1' then
				cpu_state <= HALT;
			end if;
		end if;
	end process reset_process;

	cache_miss_process : process(clk)
		variable count              : integer := 0;
		variable cache_miss_address : MEMORY_ADDRESS;
		variable cache_was_write    : integer := 0;
		variable current            : integer := 0;
		variable address_segment    : unsigned(WORD_IN_BITS - 1 downto CACHE_BLOCK_ADDRESS_SIZE);
		variable address_offset     : unsigned(CACHE_BLOCK_ADDRESS_SIZE - 1 downto 0);
		variable current_pipe_clock : integer := 0;
	begin
		if rising_edge(clk) then
			if cpu_state = NORMAL then
				instruction_cache_data_in     <= (others => '0');
				data_cache_data_in            <= wb_mem_data_out;
				instruction_cache_address     <= reg_file_pc_out;
				data_cache_address            <= data_cache_address_multiplexer_out;
				instruction_cache_is_from_mem <= '0';
				data_cache_is_from_mem        <= '0';

				if current_pipe_clock = 0 then
					ifid_read                   <= '0';
					id_memr_read                <= '0';
					memr_ex_read                <= '0';
					wb_read                     <= '0';
					mem_multiplexer_from_mem_in <= '0';
					pc_write                    <= '0';
					data_cache_read_write_in    <= '1';
					data_cache_is_read          <= '0';
					alu_save_result_in          <= '0';
					if wb_mem_write_out = '1' then
						data_cache_is_write <= '1';
					else
						data_cache_is_write <= '0';
					end if;
					instruction_cache_is_read <= '0';
				elsif current_pipe_clock = 1 then
					pc_write                  <= '0';
					instruction_cache_is_read <= '1';
					data_cache_read_write_in  <= '0';
					data_cache_is_write       <= '0';
					if id_memr_instruction_out(31 downto 28) = "0101" or id_memr_instruction_out(31 downto 29) = "011" then
						data_cache_is_read <= '1';
					else
						data_cache_is_read <= '0';
					end if;
				else
					instruction_cache_is_read <= '0';
					if instruction_cache_hit = '1' then
					pc_write <= '1';
					ifid_read <= '1';
					if count > 0 then
						id_memr_read <= '1';
					end if;
					if count > 1 then
						memr_ex_read <= '1';
					end if;
					if count > 2 then
						wb_read <= '1';
					end if;
					if count < 3 then
						count := count + 1;
					end if;
					if id_memr_instruction_out(31 downto 28) = "0101" or id_memr_instruction_out(31 downto 29) = "011" then
						mem_multiplexer_from_mem_in <= '1';
					else
						mem_multiplexer_from_mem_in <= '0';
					end if;
					alu_save_result_in <= '1';
					end if;
				end if;
				current := 0;
				current_pipe_clock := current_pipe_clock + 1;
				if current_pipe_clock = 3 then
					current_pipe_clock := 0;
				end if;

			elsif ((cpu_state = INSTRUCTION_CACHE_STALL) or (cpu_state = DATA_CACHE_STALL)) then
				ifid_read <= '0';
				pc_write <= '0';
				current_pipe_clock := 2;
				if current = 0 then
					if cpu_state = INSTRUCTION_CACHE_STALL then
						address_segment    := unsigned(instruction_cache_miss_address(WORD_IN_BITS - 1 downto CACHE_BLOCK_ADDRESS_SIZE));
						cache_miss_address := instruction_cache_miss_address;
						if instruction_cache_was_write = '1' then
							cache_was_write := 1;
						else
							cache_was_write := 0;
						end if;
					else
						address_segment    := unsigned(data_cache_miss_address(WORD_IN_BITS - 1 downto CACHE_BLOCK_ADDRESS_SIZE));
						cache_miss_address := data_cache_miss_address;
						if data_cache_was_write = '1' then
							cache_was_write := 1;
						else
							cache_was_write := 0;
						end if;
					end if;
					address_offset := "00";
				end if;
				if current < 4 then
					is_read        <= '1';
					is_write       <= '0';
					address        <= std_logic_vector(address_segment) & std_logic_vector(address_offset);
					address_offset := address_offset + 1;
					current        := current + 1;
					if current = 4 then
						address_offset := "00";
						if cpu_state = INSTRUCTION_CACHE_STALL and instruction_cache_write_back = '1' then
							instruction_cache_address <= std_logic_vector(address_segment) & std_logic_vector(address_offset);
							instruction_cache_is_read <= '1';
						elsif cpu_state = DATA_CACHE_STALL and data_cache_write_back = '1' then
							data_cache_address <= std_logic_vector(address_segment) & std_logic_vector(address_offset);
							data_cache_is_read <= '1';
						end if;
					end if;
				elsif current < 8 then
					is_read <= '0';
					if (cpu_state = INSTRUCTION_CACHE_STALL and instruction_cache_write_back = '1') or (cpu_state = DATA_CACHE_STALL and data_cache_write_back = '1') then
						is_write <= '1';
					else
						is_write <= '0';
					end if;
					address        <= std_logic_vector(address_segment) & std_logic_vector(address_offset);
					data           <= (others => 'Z');
					address_offset := address_offset + 1;
					current        := current + 1;
					if cpu_state = INSTRUCTION_CACHE_STALL and instruction_cache_write_back = '1' then
						if current < 8 then
							instruction_cache_address  <= std_logic_vector(address_segment) & std_logic_vector(address_offset);
							instruction_cache_is_read  <= '1';
							instruction_cache_is_write <= '0';
						end if;
						data <= instruction_cache_data_out;
					elsif cpu_state = DATA_CACHE_STALL and data_cache_write_back = '1' then
						if current < 8 then
							data_cache_address  <= std_logic_vector(address_segment) & std_logic_vector(address_offset);
							data_cache_is_read  <= '1';
							data_cache_is_write <= '0';
						end if;
						data <= data_cache_data_out;
					end if;

				elsif current <= 13 then
					is_read  <= '0';
					is_write <= '0';
					data     <= (others => 'Z');
					address  <= (others => 'Z');
					current  := current + 1;
				elsif current <= 17 then
					is_read  <= '0';
					is_write <= '0';
					data     <= (others => 'Z');
					address  <= (others => 'Z');
					current  := current + 1;
					if cpu_state = INSTRUCTION_CACHE_STALL then
						instruction_cache_is_read     <= '0';
						instruction_cache_is_write    <= '1';
						instruction_cache_is_from_mem <= '1';
					else
						data_cache_is_read     <= '0';
						data_cache_is_write    <= '1';
						data_cache_is_from_mem <= '1';
					end if;
				elsif current = 18 then
					current := current + 1;
					if cpu_state = INSTRUCTION_CACHE_STALL then
						if cache_was_write = 0 then
							instruction_cache_is_read  <= '1';
							instruction_cache_is_write <= '0';
						else
							instruction_cache_is_read  <= '0';
							instruction_cache_is_write <= '1';
						end if;
						instruction_cache_address     <= cache_miss_address;
						instruction_cache_is_from_mem <= '0';
					else
						if cache_was_write = 0 then
							data_cache_is_read  <= '1';
							data_cache_is_write <= '0';
						else
							data_cache_is_read  <= '1';
							data_cache_is_write <= '0';
						end if;
						data_cache_address     <= cache_miss_address;
						data_cache_is_from_mem <= '0';
					end if;
				elsif current = 19 then
					instruction_cache_is_read  <= '0';
					instruction_cache_is_write <= '0';
					data_cache_is_read  <= '0';
					data_cache_is_write <= '0';
				end if;
			end if;
		end if;
	end process cache_miss_process;
end architecture CPUImplemetation;
