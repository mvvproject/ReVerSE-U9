-------------------------------------------------------------------[2013-04-24]
-- PS/2 interface (input only)
-- Based loosely on ps2_ctrl.vhd (c) ALSE. http://www.alse-fr.com
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- This is input-only for the time being
entity ps2_intf is
generic (filter_length : positive := 8);
port(
	CLK			: in std_logic;
	RESET		: in std_logic;
	-- PS/2 interface (could be bi-dir)
	PS2_CLK		: in std_logic;
	PS2_DATA	: in std_logic;
	-- Byte-wide data interface - only valid for one clock
	-- so must be latched externally if required
	DATA		: out std_logic_vector(7 downto 0);
	VALID		: out std_logic;
	ERROR		: out std_logic
	);
end ps2_intf;

architecture ps2_intf_arch of ps2_intf is
subtype filter_t is std_logic_vector(filter_length-1 downto 0);
signal	clk_filter	: filter_t;

signal	ps2_clk_in	: std_logic;
signal	ps2_dat_in	: std_logic;
-- Goes high when a clock falling edge is detected
signal	clk_edge	: std_logic;
signal	bit_count	: unsigned (3 downto 0);
signal	shiftreg	: std_logic_vector(8 downto 0);
signal	parity		: std_logic;
begin
	-- Register input signals
	process (RESET, CLK)
	begin
		if RESET = '1' then
			ps2_clk_in <= '1';
			ps2_dat_in <= '1';
			clk_filter <= (others => '1');
			clk_edge <= '0';
		elsif rising_edge(CLK) then
			-- Register inputs (and filter clock)
			ps2_dat_in <= PS2_DATA;
			clk_filter <= PS2_CLK & clk_filter(clk_filter'high downto 1);
			clk_edge <= '0';
			
			if clk_filter = filter_t'(others => '1') then
				-- Filtered clock is high
				ps2_clk_in <= '1';
			elsif clk_filter = filter_t'(others => '0') then
				-- Filter clock is low, check for edge
				if ps2_clk_in = '1' then
					clk_edge <= '1';
				end if;
				ps2_clk_in <= '0';
			end if;	
		end if;
	end process;
	
	-- Shift in keyboard data
	process (RESET, CLK)
	begin
		if RESET = '1' then
			bit_count <= (others => '0');
			shiftreg <= (others => '0');
			parity <= '0';
			DATA <= (others => '0');
			VALID <= '0';
			ERROR <= '0';
		elsif rising_edge(CLK) then
			-- Clear flags
			VALID <= '0';
			ERROR <= '0';
		
			if clk_edge = '1' then
				-- We have a new bit from the keyboard for processing
				if bit_count = 0 then
					-- Idle state, check for start bit (0) only and don't
					-- start counting bits until we get it
					parity <= '0';

					if ps2_dat_in = '0' then
						-- This is a start bit
						bit_count <= bit_count + 1;
					end if;
				else
					-- Running.  8-bit data comes in LSb first followed by
					-- a single stop bit (1)
					if bit_count < 10 then
						-- Shift in data and parity (9 bits)
						bit_count <= bit_count + 1;
						shiftreg <= ps2_dat_in & shiftreg(shiftreg'high downto 1);
						parity <= parity xor ps2_dat_in; -- Calculate parity
					elsif ps2_dat_in = '1' then
						-- Valid stop bit received
						bit_count <= (others => '0'); -- back to idle
						if parity = '1' then
							-- Parity correct, submit data to host
							DATA <= shiftreg(7 downto 0);
							VALID <= '1';
						else
							-- Error
							ERROR <= '1';
						end if;
					else
						-- Invalid stop bit
						bit_count <= (others => '0'); -- back to idle
						ERROR <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;
end ps2_intf_arch;
