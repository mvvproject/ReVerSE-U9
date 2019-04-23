-------------------------------------------------------------------[15.10.2011]
-- MT48LC32M8A2-75 Micron 8 Meg x 8 bit x 4 banks SDRAM Controller
-------------------------------------------------------------------------------
-- V0.1 	15.10.2011	первая версия

-- CLK		= 100 MHz	= 10 ns
-- WR/RD	= 5T		= 50 ns
-- RFSH		= 7T		= 70 ns

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mt48lc32m8a2 is
	port(
		CLK				: in std_logic;
		-- Memory port
		A				: in std_logic_vector(24 downto 0);
		DI				: in std_logic_vector(7 downto 0);
		DO				: out std_logic_vector(7 downto 0);
		DM	 			: in std_logic;
		WR				: in std_logic;
		RD				: in std_logic;
		RFSH			: in std_logic;
		RFSHREQ			: out std_logic;
		IDLE			: out std_logic;
		-- SDRAM Pin
		CK				: out std_logic;
		CKE				: out std_logic;
		RAS_n			: out std_logic;
		CAS_n			: out std_logic;
		WE_n			: out std_logic;
		DQM				: out std_logic;
		BA1				: out std_logic;
		BA0				: out std_logic;
		MA				: out std_logic_vector(12 downto 0);
		DQ				: inout std_logic_vector(7 downto 0) );
end mt48lc32m8a2;

architecture rtl of mt48lc32m8a2 is
	signal state 		: unsigned(4 downto 0) := "00000";
	signal address 		: std_logic_vector(24 downto 0);
	signal rfsh_cnt 	: unsigned(9 downto 0) := "0000000000";
	signal rfsh_req		: std_logic := '0';
	signal data_reg		: std_logic_vector(7 downto 0);
	signal idle1		: std_logic;
	-- SD-RAM control signals
	signal sdr_cmd		: std_logic_vector(2 downto 0);
	signal sdr_ba0		: std_logic;
	signal sdr_ba1		: std_logic;
	signal sdr_dqm		: std_logic;
	signal sdr_a		: std_logic_vector(12 downto 0);
	signal sdr_dq		: std_logic_vector(7 downto 0);

	constant SdrCmd_xx 	: std_logic_vector(2 downto 0) := "111"; -- no operation
	constant SdrCmd_ac 	: std_logic_vector(2 downto 0) := "011"; -- activate
	constant SdrCmd_rd 	: std_logic_vector(2 downto 0) := "101"; -- read
	constant SdrCmd_wr 	: std_logic_vector(2 downto 0) := "100"; -- write		
	constant SdrCmd_pr 	: std_logic_vector(2 downto 0) := "010"; -- precharge all
	constant SdrCmd_re 	: std_logic_vector(2 downto 0) := "001"; -- refresh
	constant SdrCmd_ms 	: std_logic_vector(2 downto 0) := "000"; -- mode regiser set

-- Init-------------------------------------------------------------------		Idle		Read-------		Write------		Refresh----------
-- 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12	13 14 15 16	17		18			19 1A 16 17		1B 1C 16 17		12 13 14 15 16 17
-- pr xx xx re xx xx xx xx xx xx re xx xx xx xx xx xx ms xx xx xx xx xx	xx		xx/ac/re	xx rd xx xx		xx wr xx xx		xx xx xx xx xx xx

begin
	process (CLK)
	begin
		if CLK'event and CLK = '0' then
			case state is
				-- Init
				when "00000" =>						-- s00
					sdr_cmd <= SdrCmd_pr;			-- PRECHARGE
					sdr_a <= "1111111111111";
					sdr_ba1 <= '0';
					sdr_ba0 <= '0';
					sdr_dqm <= '1';
					state <= state + 1;
				when "00011" | "01010" =>			-- s03 s0A
					sdr_cmd <= SdrCmd_re;			-- REFRESH
					state <= state + 1;
				when "10001" =>						-- s11
					sdr_cmd <= SdrCmd_ms;			-- LOAD MODE REGISTER
					sdr_a <= "000" & "1" & "00" & "010" & "0" & "000";				
					state <= state + 1;

				-- Idle
				when "11000" =>						-- s18
					sdr_cmd <= SdrCmd_xx;			-- NOP
					sdr_dq <= (others => 'Z');
					idle1 <= '1';
					if RD = '1' then
						idle1 <= '0';
						address <= A;
						sdr_cmd <= SdrCmd_ac;		-- ACTIVE
						sdr_ba1 <= A(11);
						sdr_ba0 <= A(10);
						sdr_a <= A(24 downto 12);					 
						state <= "11001";			-- s19 Read
					elsif WR = '1' then
						idle1 <= '0';
						address <= A;
						sdr_cmd <= SdrCmd_ac;		-- ACTIVE
						sdr_ba1 <= A(11);
						sdr_ba0 <= A(10);
						sdr_a <= A(24 downto 12);
						state <= "11011";			-- s1B Write
					elsif RFSH = '1' then
						idle1 <= '0';
						rfsh_req <= '0';
						sdr_cmd <= SdrCmd_re;		-- REFRESH
						state <= "10010";			-- s12
					end if;

				-- A24 A23 A22 A21 A20 A19 A18 A17 A16 A15 A14 A13 A12 A11 A10 A9 A8 A7 A6 A5 A4 A3 A2 A1 A0
				-- -----------------------ROW------------------------- BA1 BA0 -----------COLUMN------------		

				-- Single read - with auto precharge
				when "11010" =>						-- s1A
					sdr_cmd <= SdrCmd_rd;			-- READ (A10 = 1 enable auto precharge; A9..0 = column)
					sdr_a <= "001" & address(9 downto 0);
					sdr_dqm <= '0';
					state <= "10110";				-- s16
					
				-- Single write - with auto precharge
				when "11100" =>						-- s1C
					sdr_cmd <= SdrCmd_wr;			-- WRITE (A10 = 1 enable auto precharge; A9..0 = column)
					sdr_a <= "001" & address(9 downto 0); 
					sdr_dq <= DI;
					sdr_dqm <= DM;
					state <= "10110";				-- s16
					
				when others =>
					sdr_dq <= (others => 'Z');
					sdr_cmd <= SdrCmd_xx;			-- NOP
					state <= state + 1;
			end case;

			-- Providing a distributed AUTO REFRESH command every 7.81us
			if rfsh_cnt = "110011010" then	-- (105MHz * 1000 * 64 / 8192) = 820 (410)
				rfsh_cnt <= (others => '0');
				rfsh_req <= '1';
			else
				rfsh_cnt <= rfsh_cnt + 1;
			end if;
			
		end if;
	end process;
	
	process (CLK, state, DQ, data_reg, idle1)
	begin
		if CLK'event and CLK = '1' and idle1 = '0' then
			if state = "11000" then				-- s18
				data_reg <= DQ;
			end if;
		end if;
	end process;
	
	IDLE	<= idle1;
	DO 		<= data_reg;
	RFSHREQ	<= rfsh_req;
	CK 		<= CLK;
	CKE 	<= '1';
	RAS_n 	<= sdr_cmd(2);
	CAS_n 	<= sdr_cmd(1);
	WE_n 	<= sdr_cmd(0);
	DQM 	<= sdr_dqm;
	BA1 	<= sdr_ba1;
	BA0 	<= sdr_ba0;
	MA 		<= sdr_a;
	DQ 		<= sdr_dq;

end rtl;