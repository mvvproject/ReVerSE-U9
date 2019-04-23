-------------------------------------------------------------------------------
--  SOC u9 POST v1.04 By MVV 26.06.2011
--	PCB u9ep3c By MVV
-------------------------------------------------------------------------------
--  This program is free software, you can redistribute it and/or modify
--  it under the terms of the GNU General Public License.

-- 08 KB Internal ROM	Read		(0x0000h - 0x3FFFh) A15=0 A14=0
-- 16 KB Internal VRAM	Read/Write	(0x4000h - 0x7FFFh) A15=0 A14=1
-- 16 KB Internal SDRAM	Read/Write	(0x8000h - 0xBFFFh) A15=1 A14=0
-- 16 KB External SRAM	Read/Write	(0xC000h - 0xFFFFh) A15=1 A14=1 

-- 01 PS/2 keyboard	In		(Port 0x80h)
-- 01 Video write port  In/Out		(Port 0x90h)
-- 01 Cursor_X          In/Out		(Port 0x91h)
-- 01 Cursor_Y		In/Out		(Port 0x92h)
-- 01 Memory Page	In/Out		(Port 0x70h)
-- 01 Port Test1	In		(Port 0x71h)
-- 01 Port Test2	In		(Port 0x72h)
-- 01 Port Test3	In		(Port 0x73h)
-- 01 mem21a14		In/Out		(Port 0x60h)
-- 01 mem24a22		In/Out		(Port 0x61h)

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity TOP_U9 is
	port(
	-- Clocks
	CLOCK_50 		: in std_logic;		-- 50 MHz
	-- Buttons and switches
	KEY 			: in std_logic;		-- Push buttons
	-- PS/2
	PS2_MSDAT,
	PS2_MSCLK,
	PS2_KBDAT,
	PS2_KBCLK 		: inout std_logic;
	-- SRAM
	SRAM_DQ			: inout std_logic_vector(7 downto 0);	-- Data bus 8 Bits
	SRAM_ADDR		: inout std_logic_vector(18 downto 0);	-- Address bus 18 Bits
	SRAM_nOE		: out std_logic;			-- Output Enable
	SRAM_nWE		: out std_logic;			-- Write Enable
	-- VGA
	VGA_R,								-- Red  [2:0]
	VGA_G,								-- Green[2:0]
	VGA_B  			: out std_logic_vector(2 downto 0);  	-- Blue [2:0]
	VGA_HS,								-- H_SYNC
	VGA_VS 			: out std_logic;			-- SYNC
	-- SDRAM
	DRAM_CLK 		: out std_logic;
	DRAM_CKE 		: out std_logic;
	DRAM_RAS_n 		: out std_logic;
	DRAM_CAS_n 		: out std_logic;
	DRAM_WE_n 		: out std_logic;
	DRAM_DQM		: out std_logic;
	DRAM_BA1		: out std_logic;
	DRAM_BA0		: out std_logic;
	DRAM_A			: out std_logic_vector(12 downto 0);
	DRAM_D			: inout std_logic_vector(7 downto 0);
	-- SD card interface
	SD_DAT0 		: in std_logic;
	SD_DAT1 		: in std_logic;
	SD_DAT2 		: in std_logic;
	SD_DAT3 		: in std_logic;
	SD_CMD  		: in std_logic;
	SD_CLK  		: in std_logic;
	SD_PROT 		: in std_logic;
	SD_DETECT 		: in std_logic;
	-- I2C bus
	SDA 			: in std_logic;
	SCL 			: in std_logic;
    
	RTC_INTn 		: in std_logic;
	GPI 			: in std_logic;
	CBUS4 			: in std_logic;
	TXD 			: in std_logic;
	RXD 			: in std_logic;
	ASDO 			: in std_logic;
	DAC_BCK			: in std_logic;
	NCSO 			: in std_logic;
	DCLK 			: in std_logic;
	DATA0 			: in std_logic
	
	-- USB JTAG link
--	TDI,						-- CPLD -> FPGA (data in)
--	TCK,						-- CPLD -> FPGA (clk)
--	TCS 			: in std_logic;		-- CPLD -> FPGA (CS)
--	TDO 			: out std_logic;	-- FPGA -> CPLD (data out)

	-- RS-232 interface
--	UART_TXD 		: out std_logic;	-- UART transmitter   
--	UART_RXD 		: in std_logic;		-- UART receiver
	);
end TOP_U9;

architecture rtl of TOP_U9 is
	component T80se
	generic(
		Mode 		: integer := 0;		-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
		T2Write 	: integer := 1;		-- 0 => cpu_wr_n active in T3, 1 => cpu_wr_n active in T2
		IOWait 		: integer := 0);	-- 0 => Single cycle I/O, 1 => Std I/O cycle
	port(
		RESET_n         : in  std_logic;
		CLK_n           : in  std_logic;
		CLKEN           : in  std_logic;
		WAIT_n          : in  std_logic;
		INT_n           : in  std_logic;
		NMI_n           : in  std_logic;
		BUSRQ_n         : in  std_logic;
		M1_n            : out std_logic;
		MREQ_n          : out std_logic;
		IORQ_n          : out std_logic;
		RD_n            : out std_logic;
		WR_n            : out std_logic;
		RFSH_n          : out std_logic;
		HALT_n          : out std_logic;
		BUSAK_n         : out std_logic;
		A               : out std_logic_vector(15 downto 0);
		DI              : in  std_logic_vector(7 downto 0);
		DO              : out std_logic_vector(7 downto 0));
	end component;
	
	component sram
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
	end component;

	component sdram
	PORT(
		CLK		: in std_logic;	
		-- Memory port
		A		: in std_logic_vector(24 downto 0);
		DI		: in std_logic_vector(7 downto 0);
		DO		: out std_logic_vector(7 downto 0);
		DM	 	: in std_logic;
		WR		: in std_logic;
		RD		: in std_logic;
		RFSH		: in std_logic;
		RFSHREQ		: out std_logic;
		IDLE		: out std_logic;
		-- SDRAM Pin
		CK		: out std_logic;
		CKE		: out std_logic;
		RAS_n		: out std_logic;
		CAS_n		: out std_logic;
		WE_n		: out std_logic;
		DQM		: out std_logic;
		BA1		: out std_logic;
		BA0		: out std_logic;
		MA		: out std_logic_vector(12 downto 0);
		DQ		: inout std_logic_vector(7 downto 0) );
	end component;
	
	component rom
	port (
		clock		: in std_logic;
		address		: in std_logic_vector(12 downto 0);
		q		: out std_logic_vector(7 downto 0));
	end component;

	component Clock_357Mhz
	PORT (
		clock_50Mhz	: IN STD_LOGIC;
		clock_357Mhz	: OUT STD_LOGIC);
	end component;
	
	component clk_div
	PORT
	(
		clock_25Mhz	: IN STD_LOGIC;
		clock_1MHz	: OUT STD_LOGIC;
		clock_100KHz	: OUT STD_LOGIC;
		clock_10KHz	: OUT STD_LOGIC;
		clock_1KHz	: OUT STD_LOGIC;
		clock_100Hz	: OUT STD_LOGIC;
		clock_10Hz	: OUT STD_LOGIC;
		clock_1Hz	: OUT STD_LOGIC);
	end component;

	component ps2kbd
	port (	
		keyboard_clk	: inout std_logic;
		keyboard_data	: inout std_logic;
		clock		: in std_logic;
		clkdelay	: in std_logic;
		reset		: in std_logic;
		read		: in std_logic;
		scan_ready	: out std_logic;
		ps2_ascii_code	: out std_logic_vector(7 downto 0));
	end component;
	
	component vram3200x8
	port
	(
		rdaddress	: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		wraddress	: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		rdclock		: IN STD_LOGIC;
		wrclock		: IN STD_LOGIC;
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren		: IN STD_LOGIC;
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0));
	end component;

	component charram2k
	port (
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		rdaddress	: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		rdclock		: IN STD_LOGIC ;
		wraddress	: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		wrclock		: IN STD_LOGIC;
		wren		: IN STD_LOGIC;
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
	end component;
	
	COMPONENT video
	PORT (		
		CLOCK_25	: IN STD_LOGIC;
		VRAM_DATA	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		VRAM_ADDR	: OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		VRAM_WREN	: OUT STD_LOGIC;
		CRAM_DATA	: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		CRAM_ADDR	: OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		CRAM_WEB	: OUT STD_LOGIC;
		VGA_R		: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		VGA_G		: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		VGA_B		: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		VGA_HS,
		VGA_VS		: OUT STD_LOGIC);
	END COMPONENT;
	
	COMPONENT altpll0
	PORT
	(
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC; 
		c1		: OUT STD_LOGIC;
		c2		: OUT STD_LOGIC);
	END COMPONENT;

	-- CPU signals
	signal cpu_mreq_n	: std_logic;
	signal cpu_iorq_n	: std_logic;
	signal cpu_rd_n		: std_logic;
	signal cpu_wr_n		: std_logic;
	signal cpu_reset_n	: std_logic;
	signal cpu_clk_n	: std_logic;
	signal cpu_data_in	: std_logic_vector(7 downto 0);
	signal cpu_data_out	: std_logic_vector(7 downto 0);
	signal cpu_addr		: std_logic_vector(15 downto 0);
	signal D_ROM		: std_logic_vector(7 downto 0);
	signal cpu_clken	: std_logic;
	signal cpu_rfsh_n	: std_logic;
	signal cpu_m1_n		: std_logic;
	signal cpu_wait_n	: std_logic;
	signal wr_latch		: std_logic;
	signal rd_latch		: std_logic;
	-- ram signals
	signal ram_addr		: std_logic_vector(13 downto 0);
	signal ram_din		: std_logic_vector(7 downto 0);
	signal ram_dout		: std_logic_vector(7 downto 0);
	signal ram_wea		: std_logic;
	
	signal clk25mhz		: std_logic;
	signal clk100hz		: std_logic;
	signal clk10hz		: std_logic;
	signal clk1hz		: std_logic;
	signal clk_x_mhz	: std_logic;
	
	signal vram_address	: std_logic_vector(15 downto 0);
	signal vram_addrb	: std_logic_vector(11 downto 0);
	signal vram_dina	: std_logic_vector(7 downto 0);
	signal vram_dinb	: std_logic_vector(7 downto 0);
	signal vram_douta	: std_logic_vector(7 downto 0);
	signal vram_doutb	: std_logic_vector(15 downto 0);
	signal vram_wea		: std_logic;
	signal vram_web		: std_logic;
	signal vram_clka	: std_logic;
	
	signal vram_douta_reg	: std_logic_vector(7 downto 0);	
	signal VID_CURSOR	: std_logic_vector(15 downto 0);
	signal CURSOR_X		: std_logic_vector(6 downto 0);
	signal CURSOR_Y		: std_logic_vector(5 downto 0);

	signal cram_address	: std_logic_vector(15 downto 0);
	signal cram_addrb	: std_logic_vector(15 downto 0);
	signal cram_dina	: std_logic_vector(7 downto 0);
	signal cram_dinb	: std_logic_vector(7 downto 0);
	signal cram_douta	: std_logic_vector(7 downto 0);
	signal cram_doutb	: std_logic_vector(7 downto 0);
	signal cram_wea		: std_logic;
	signal cram_web		: std_logic;
	signal cram_clka	: std_logic;
	signal cram_clkb	: std_logic;
	
	-- PS/2 Keyboard
	signal ps2_read		: std_logic;
	signal ps2_scan_ready	: std_logic;
	signal ps2_ascii_sig	: std_logic_vector(7 downto 0);
	signal ps2_ascii_reg1	: std_logic_vector(7 downto 0);
	signal ps2_ascii_reg	: std_logic_vector(7 downto 0);
 	
 	-- Port
 	signal page_reg	 	: std_logic_vector (7 downto 0);
 	signal page1_reg 	: std_logic_vector (7 downto 0);
 	signal page2_reg 	: std_logic_vector (7 downto 0);
 	signal mem_reg	 	: std_logic_vector (31 downto 0);
 	
 	signal port1_reg 	: std_logic_vector (7 downto 0);
 	signal port2_reg 	: std_logic_vector (7 downto 0);
 	signal port3_reg 	: std_logic_vector (7 downto 0);
 	signal port4_reg 	: std_logic_vector (7 downto 0);
 	signal port5_reg 	: std_logic_vector (7 downto 0); 	 	
	
	-- SDRAM
	signal mem_clk 		: std_logic;
	signal memAddress  	: std_logic_vector(24 downto 0);
	signal memDataIn   	: std_logic_vector(7 downto 0);
	signal memDataOut  	: std_logic_vector(7 downto 0);
	signal memDataMask 	: std_logic;
	signal memWr     	: std_logic;
	signal memRd      	: std_logic;
	signal memIdle		: std_logic;
	signal memRC		: std_logic;
	signal memRFSH		: std_logic;
	signal memRFSHREQ	: std_logic;

	
begin
	
	--	Write into VRAM
	vram_address <= VID_CURSOR when (cpu_iorq_n = '0' and cpu_mreq_n = '1' and cpu_addr(7 downto 0) = x"90") else
					cpu_addr - x"4000" when (cpu_addr >= x"4000" and cpu_addr < x"52C0");
	vram_wea <= '0' when ((cpu_addr >= x"4000" and cpu_addr < x"52C0" and cpu_wr_n = '0' and cpu_mreq_n = '0') or (cpu_wr_n = '0' and cpu_iorq_n = '0' and cpu_addr(7 downto 0) = x"90")) else '1';
	vram_dina <= cpu_data_out;
	
	-- Write into char ram
--	cram_address <= cpu_addr - x"4C80";
--	cram_dina <= cpu_data_out;
--	cram_wea <= '0' when (cpu_addr >= x"4C80" and cpu_addr < x"5480" and cpu_wr_n = '0' and cpu_mreq_n = '0') else '1';
	
	-- Write into RAM
	ram_addr	<= cpu_addr(13 downto 0);
	ram_din 	<= cpu_data_out;
	ram_wea 	<= cpu_wr_n or cpu_mreq_n or cpu_addr(15) or not cpu_addr(14);
		
	-- SRAM control signals
	
-- Truth Table:
-- CE OE WE I/O0–I/O7
-- H  X  X  High-Z
-- L  L  H  Data Out Read
-- L  X  L  Data In Write
-- L  H  H  High-Z Selected, Outputs Disabled

	SRAM_ADDR 	<= page_reg(4 downto 0) & cpu_addr(13 downto 0);
	SRAM_nWE 	<= cpu_wr_n or cpu_mreq_n or not cpu_addr(15) or not cpu_addr(14);
	SRAM_nOE 	<= '0';
	SRAM_DQ		<= cpu_data_out when cpu_rd_n = '1' else (others => 'Z'); -- async wait data for sram

	-- Port registers
	port1_reg 	<= SD_PROT & SD_DETECT & SD_DAT2 & SD_DAT3 & SD_CMD & SD_CLK & SD_DAT0 & SD_DAT1; 
	port2_reg 	<= SRAM_DQ(7 downto 0);
	port3_reg 	<= DRAM_D(7 downto 0); 
	port4_reg 	<= SCL & SDA & RTC_INTn & ASDO & DAC_BCK & NCSO & DCLK & DATA0; 
	port5_reg 	<= PS2_MSDAT & PS2_KBDAT & TXD & GPI & PS2_MSCLK & PS2_KBCLK & RXD & CBUS4;
		
	-- DRAM controll signals
	memDataMask 	<= '0';
	memDataIn 	<= cpu_data_out;
	memAddress	<= page2_reg(2 downto 0) & page1_reg(7 downto 0) & cpu_addr(13 downto 0);
	memWr		<= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and cpu_addr(15 downto 14) = "10" else '0';
	memRd 		<= '1' when cpu_mreq_n = '0' and cpu_rd_n = '0' and cpu_addr(15 downto 14) = "10" else '0';
	memRFSH		<= '1' when memRFSHREQ = '1' else '0';

	cpu_reset_n 	<= KEY;
	cpu_clken	<= '0' when memIdle = '0' else '1';
		
	cpu_data_in <= 	SRAM_DQ when 	cpu_rd_n = '0' and cpu_mreq_n = '0' and cpu_addr(15 downto 14) = "11" else
					memDataOut when cpu_rd_n = '0' and cpu_mreq_n = '0' and cpu_addr(15 downto 14) = "10" else
					ram_dout when cpu_rd_n = '0' and cpu_mreq_n = '0' and cpu_addr(15 downto 14) = "01" else
					D_ROM when cpu_rd_n = '0' and cpu_mreq_n = '0' and cpu_addr(15 downto 14) = "00" else
					page1_reg when cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_addr(7 downto 0) = x"60" else
					page2_reg when cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_addr(7 downto 0) = x"61" else
					page_reg when cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_addr(7 downto 0) = x"70" else
					port1_reg when cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_addr(7 downto 0) = x"71" else
					port2_reg when cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_addr(7 downto 0) = x"72" else
					port3_reg when cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_addr(7 downto 0) = x"73" else
					port4_reg when cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_addr(7 downto 0) = x"74" else
					port5_reg when cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_addr(7 downto 0) = x"75" else
					ps2_ascii_reg when cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_addr(7 downto 0) = x"80" else
					("0" & CURSOR_X) when cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_addr(7 downto 0) = x"91" else
					("00" & CURSOR_Y) when cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_addr(7 downto 0) = x"92" else
					"11111111";
		
	-- the following three processes deals with different clock domain signals
	ps2_process1: process(CLOCK_50)
	begin
		if CLOCK_50'event and CLOCK_50 = '1' then
			if ps2_read = '1' then
				if ps2_ascii_sig /= x"FF" then
					ps2_read <= '0';
					ps2_ascii_reg1 <= "00000000";
				end if;
			elsif ps2_scan_ready = '1' then
				if ps2_ascii_sig = x"FF" then
					ps2_read <= '1';
				else
					ps2_ascii_reg1 <= ps2_ascii_sig;
				end if;
			end if;
		end if;
	end process;
	
	ps2_process2: process(cpu_clk_n)
	begin
		if cpu_clk_n'event and cpu_clk_n = '1' then
			ps2_ascii_reg <= ps2_ascii_reg1;
		end if;
	end process;
	
	port_process: process(cpu_clk_n)
	begin
		if cpu_clk_n'event and cpu_clk_n = '1' then
			-- reg pages
			if (cpu_addr(7 downto 0) = x"70" and cpu_iorq_n = '0' and cpu_wr_n = '0') then
				page_reg <= cpu_data_out;	
			elsif (cpu_addr(7 downto 0) = x"60" and cpu_iorq_n = '0' and cpu_wr_n = '0') then
				page1_reg <= cpu_data_out;	
			elsif (cpu_addr(7 downto 0) = x"61" and cpu_iorq_n = '0' and cpu_wr_n = '0') then
				page2_reg <= cpu_data_out;	
			end if;
		end if;	
	end process;

	
	cursorxy: process (cpu_clk_n)
	variable VID_X	: std_logic_vector(6 downto 0);
	variable VID_Y	: std_logic_vector(5 downto 0);
	begin
		if cpu_clk_n'event and cpu_clk_n = '1' then
			if (cpu_iorq_n = '0' and cpu_mreq_n = '1' and cpu_wr_n = '0' and cpu_addr(7 downto 0) = x"91") then
				VID_X := cpu_data_out(6 downto 0);
			elsif (cpu_iorq_n = '0' and cpu_mreq_n = '1' and cpu_wr_n = '0' and cpu_addr(7 downto 0) = x"92") then
				VID_Y := cpu_data_out(5 downto 0);
			elsif (cpu_iorq_n = '0' and cpu_mreq_n = '1' and cpu_wr_n = '0' and cpu_addr(7 downto 0) = x"90") then
				if VID_X = 80 - 1 then
					VID_X := "0000000";
					if VID_Y = 30 - 1 then
						VID_Y := "000000";
					else
						VID_Y := VID_Y + 1;
					end if;
				else
					VID_X := VID_X + 1;
				end if;
			end if;
		end if;
		VID_CURSOR <= x"4000" + (( VID_X + ( VID_Y * conv_std_logic_vector(80,7))) * conv_std_logic_vector(2,2));
		CURSOR_X <= VID_X;
		CURSOR_Y <= VID_Y;
	end process;
		
	z80_inst: T80se
		port map (
		RESET_n 	=> cpu_reset_n,
		CLK_n 		=> cpu_clk_n,
		CLKEN 		=> cpu_clken,
		WAIT_n 		=> '1',
		INT_n 		=> '1',
		NMI_n 		=> '1',
		BUSRQ_n 	=> '1',
		M1_n 		=> cpu_m1_n,
		MREQ_n 		=> cpu_mreq_n,
		IORQ_n 		=> cpu_iorq_n,
		RD_n 		=> cpu_rd_n,
		WR_n 		=> cpu_wr_n,
		RFSH_n 		=> cpu_rfsh_n,
		HALT_n 		=> open,
		BUSAK_n 	=> open,
		A		=> cpu_addr,
		DI 		=> cpu_data_in,
		DO 		=> cpu_data_out);

	video_inst: video
		port map (
		CLOCK_25	=> clk25mhz,
		VRAM_DATA	=> vram_doutb,
		VRAM_ADDR	=> vram_addrb(11 downto 0),
		VRAM_WREN	=> vram_web,
		CRAM_DATA	=> cram_doutb,
		CRAM_ADDR	=> cram_addrb(11 downto 0),
		CRAM_WEB	=> cram_web,
		VGA_R		=> VGA_R,
		VGA_G		=> VGA_G,
		VGA_B		=> VGA_B,
		VGA_HS		=> VGA_HS,
		VGA_VS		=> VGA_VS);

	vram : vram3200x8
	port map (
		rdclock	 	=> clk25mhz,
		wrclock 	=> cpu_clk_n,	
		wren	 	=> not vram_wea,
		wraddress	=> vram_address(12 downto 0),
		rdaddress	=> vram_addrb(11 downto 0),
		data	 	=> vram_dina,
		q	 	=> vram_doutb);

	cram: charram2k
	port map (	
		rdaddress	=> cram_addrb(11 downto 0),
		wraddress	=> cram_address(11 downto 0),
		wrclock		=> cpu_clk_n,
		rdclock		=> clk25mhz,
		data		=> cram_dina,
		q		=> cram_doutb,
		wren		=> NOT cram_wea);
	
	ram : sram
	port map (
		clock 		=> cpu_clk_n,
		data 		=> ram_din,
		address 	=> ram_addr(13 downto 0),
		wren 		=> NOT ram_wea,
		q 		=> ram_dout);
	
	mem : sdram
	port map (
		CLK		=> mem_clk,		
		-- Memory port
		A	  	=> memAddress,
		DI		=> memDataIn,
		DO		=> memDataOut,
		DM		=> memDataMask,
		WR       	=> memWr,
		RD      	=> memRd,
		IDLE		=> memIdle,
		RFSH		=> memRFSH,
		RFSHREQ		=> memRFSHREQ,
		-- SDRAM Pin
		CK 		=> DRAM_CLK,
		CKE		=> DRAM_CKE,
		RAS_n		=> DRAM_RAS_n,
		CAS_n		=> DRAM_CAS_n,
		WE_n 		=> DRAM_WE_n,
		DQM		=> DRAM_DQM,
		BA1    		=> DRAM_BA1,
		BA0    		=> DRAM_BA0,
		MA		=> DRAM_A,
		DQ		=> DRAM_D );

	rom_inst: rom
	port map (
		clock		=> cpu_clk_n,
		address		=> cpu_addr(12 downto 0),
		q	 	=> D_ROM);

	-- PLL below is used to generate the pixel clock frequency
	-- Uses 50Mhz clock for PLL's input clock
	video_PLL_inst: altpll0
	port map (
		inclk0		=> CLOCK_50,
		c0		=> clk25mhz,
		c1		=> cpu_clk_n,
		c2		=> mem_clk);

	clkdiv_inst: clk_div
	port map (
		clock_25Mhz	=> clk25mhz,
		clock_1MHz	=> open,
		clock_100KHz	=> open,
		clock_10KHz	=> open,
		clock_1KHz	=> open,
		clock_100Hz	=> clk100hz,
		clock_10Hz	=> clk10hz,
		clock_1Hz	=> clk1hz);
		
	clock_z80_inst : Clock_357Mhz
	port map (
		clock_50Mhz	=> CLOCK_50,
		clock_357Mhz	=> clk_x_mhz); --cpu_clk_n

	ps2_kbd_inst : ps2kbd
	PORT MAP (
		keyboard_clk	=> PS2_KBCLK,
		keyboard_data	=> PS2_KBDAT,
		clock		=> CLOCK_50,
		clkdelay	=> clk100hz,
		reset		=> cpu_reset_n,
		read		=> ps2_read,
		scan_ready	=> ps2_scan_ready,
		ps2_ascii_code	=> ps2_ascii_sig);

end;