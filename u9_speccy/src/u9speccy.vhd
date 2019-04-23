-------------------------------------------------------------------[24.07.2013]
-- u9-Speccy Version 0.8.2 By MVV 
-- DEVBOARD ReVerSE-U9EP3C By MVV
-------------------------------------------------------------------------------
-- V0.1 	12.02.2011	Первая версия
-- V0.5 	01.11.2011	Добавлен GS
-- V0.5.1 	11.12.2011	Сброс GS на клавише F10
-- V0.5.2 	14.12.2011	UART
-- V0.5.3 	20.12.2011	INT, CPU GS @ 84MHz
-- V0.6 	16.12.2012	ROM теперь считывается из M25P40
-- V0.7 	29.05.2013	Обновлен T80CPU, UART. В модуле GS исправлена работа защелок bit7_flag, bit0_flag (синхронный процесс), частота 21МГц, добавленна громкость каналов.
-- V0.8		21.07.2013	Корректная работа модуля ZC при turbo on/off. В модуле GS исправлена работа int_n (синхронный процесс).
-- V0.8.1	23.07.2013	Устранена ошибка переключения видео страниц в vid_wr.
-- V0.8.2	24.07.2013	Установлена частота ZC 28МГц.
-- V0.8.3	10.08.2013	Исправление ticksPerUsec * 3500000 в модулях io_ps2_mouse и io_ps2_keyboard.


-- http://zx.pk.ru/showthread.php?t=13875

-- Copyright (c) 2011-2013 MVV
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- * Redistributions of source code must retain the above copyright notice,
--   this list of conditions and the following disclaimer.
--
-- * Redistributions in synthesized form must reproduce the above copyright
--   notice, this list of conditions and the following disclaimer in the
--   documentation and/or other materials provided with the distribution.
--
-- * Neither the name of the author nor the names of other contributors may
--   be used to endorse or promote products derived from this software without
--   specific prior written agreement from the author.
--
-- * License is granted for non-commercial use only.  A fee may not be charged
--   for redistributions as source code or in synthesized/hardware form without 
--   specific prior written agreement from the author.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

-- M9Ks:	19/46

-- SRAM 512K:
-- 00000-07FFF		General Sound ROM 32K
-- 08000-7FFFF		General Sound RAM 480K

-- SDRAM 32M:
-- 0000000-1FFFFFF

-- FLASH 512K:
-- 00000-5FFFF		Конфигурация Cyclone EP3C10
-- 60000-63FFF		General Sound ROM 32K (16K)
-- 64000-67FFF		General Sound ROM 32K (16K)
-- 68000-6BFFF
-- 6C000-6FFFF
-- 70000-77FFF
-- 78000-7FFFF

entity u9speccy is
port (
	-- Clock (50MHz)
	CLK_50MHZ	: in std_logic;
	-- SRAM (CY7C1049DV33-10)
	SRAM_A		: out std_logic_vector(18 downto 0);
	SRAM_D		: inout std_logic_vector(7 downto 0);
	SRAM_WE_n	: out std_logic;
	SRAM_OE_n	: out std_logic;
	-- SDRAM (MT48LC32M8A2-75)
	DRAM_A		: out std_logic_vector(12 downto 0);
	DRAM_D		: inout std_logic_vector(7 downto 0);
	DRAM_BA		: out std_logic_vector(1 downto 0);
	DRAM_CLK	: out std_logic;
	DRAM_CKE	: out std_logic;
	DRAM_DQM	: out std_logic;
	DRAM_WE_n	: out std_logic;
	DRAM_CAS_n	: out std_logic;
	DRAM_RAS_n	: out std_logic;
	-- RTC (PCF8583)
	RTC_INT_n	: in std_logic;
	RTC_SCL		: inout std_logic;
	RTC_SDA		: inout std_logic;
	-- FLASH (M25P40)
	DATA0		: in std_logic;
	NCSO		: out std_logic;
	DCLK		: out std_logic;
	ASDO		: out std_logic;
	-- DAC (TDA1543)
	DAC_BCK		: out std_logic;
	-- VGA
	VGA_R		: out std_logic_vector(2 downto 0);
	VGA_G		: out std_logic_vector(2 downto 0);
	VGA_B		: out std_logic_vector(2 downto 0);
	VGA_VSYNC	: out std_logic;
	VGA_HSYNC	: out std_logic;
	-- External I/O
	RST_n		: in std_logic;
	GPI			: in std_logic;
	-- PS/2
	PS2_KBCLK	: inout std_logic;
	PS2_KBDAT	: inout std_logic;		
	PS2_MSCLK	: inout std_logic;
	PS2_MSDAT	: inout std_logic;		
	-- USB-UART (FT232RL)
	TXD			: in std_logic;
	RXD			: out std_logic;
	CBUS4		: in std_logic;
	-- SD/MMC Card
	SD_CLK		: out std_logic;
	SD_DAT0		: in std_logic;
	SD_DAT1		: in std_logic;
	SD_DAT2		: in std_logic;
	SD_DAT3		: out std_logic;
	SD_CMD		: out std_logic;
	SD_DETECT	: in std_logic;
	SD_PROT		: in std_logic);		
end u9speccy;

architecture u9speccy_arch of u9speccy is

-- CPU0
signal cpu0_clk			: std_logic;
signal cpu0_a_bus		: std_logic_vector(15 downto 0);
signal cpu0_do_bus		: std_logic_vector(7 downto 0);
signal cpu0_di_bus		: std_logic_vector(7 downto 0);
signal cpu0_mreq_n		: std_logic;
signal cpu0_iorq_n		: std_logic;
signal cpu0_wr_n		: std_logic;
signal cpu0_rd_n		: std_logic;
signal cpu0_int_n		: std_logic;
signal cpu0_inta_n		: std_logic;
signal cpu0_m1_n		: std_logic;
signal cpu0_rfsh_n		: std_logic;
signal cpu0_ena			: std_logic;
signal cpu0_mult		: std_logic_vector(1 downto 0);
signal turbo			: std_logic := '1';
signal cpu0_mem_wr		: std_logic;
signal cpu0_mem_rd		: std_logic;
-- Memory
signal rom_do_bus		: std_logic_vector(7 downto 0);
signal ram_a_bus		: std_logic_vector(10 downto 0);
-- Port
signal port_xxfe_reg	: std_logic_vector(7 downto 0);
signal port_1ffd_reg	: std_logic_vector(7 downto 0);
signal port_7ffd_reg	: std_logic_vector(7 downto 0);
signal port_dffd_reg	: std_logic_vector(7 downto 0);
signal port_xx00_reg	: std_logic_vector(7 downto 0) := "00000000";
signal port_xx01_reg	: std_logic_vector(7 downto 0) := "00000000";
-- PS/2 Keyboard
signal kb_do_bus		: std_logic_vector(4 downto 0);
signal kb_f_bus			: std_logic_vector(12 downto 1);
signal kb_joy_bus		: std_logic_vector(4 downto 0);
signal kb_num			: std_logic;
-- PS/2 Mouse
signal ms_but_bus		: std_logic_vector(7 downto 0);
signal ms_present		: std_logic;
signal ms_left			: std_logic;
signal ms_x_bus			: std_logic_vector(7 downto 0);
signal ms_y_bus			: std_logic_vector(7 downto 0);
signal ms_clk_out		: std_logic;
signal ms_buf_out		: std_logic;
-- Video
signal vid_a_bus		: std_logic_vector(12 downto 0);
signal vid_di_bus		: std_logic_vector(7 downto 0);
signal vid_wr			: std_logic;
signal vid_scr			: std_logic;
signal vid_hsync		: std_logic;
signal vid_hsync1		: std_logic;
signal vid_vsync		: std_logic;
signal vid_mode			: std_logic;
signal vid_hcnt			: std_logic_vector(8 downto 0);
signal vid_int			: std_logic;
-- Scan doubler
signal scan_cnt			: std_logic_vector(8 downto 0);
signal scan_in			: std_logic_vector(5 downto 0);
signal scan_out			: std_logic_vector(5 downto 0);
signal scan_sp			: std_logic_vector(1 downto 0);
-- SDMMC
signal zc_do_bus		: std_logic_vector(7 downto 0);
signal zc_rd			: std_logic;
signal zc_wr			: std_logic;
-- SPI
signal spi_si			: std_logic;
signal spi_clk			: std_logic;
signal spi_wr			: std_logic;
signal spi_cs_n			: std_logic;
signal spi_do_bus		: std_logic_vector(7 downto 0);
-- PCF8583
signal rtc_do_bus		: std_logic_vector(7 downto 0);
signal rtc_wr			: std_logic;
-- MC146818A
signal mc146818a_wr		: std_logic;
signal mc146818a_a_bus	: std_logic_vector(5 downto 0);
signal mc146818a_do_bus	: std_logic_vector(7 downto 0);
signal port_bff7		: std_logic;
signal port_eff7_reg	: std_logic_vector(7 downto 0);
-- TDA1543
signal dac_data			: std_logic;
signal dac_ws			: std_logic;
-- SDRAM
signal sdr_do_bus		: std_logic_vector(7 downto 0);
signal sdr_wr			: std_logic;
signal sdr_rd			: std_logic;
-- TurboSound
signal ssg_sel			: std_logic;
signal ssg_cn0_bus		: std_logic_vector(7 downto 0);
signal ssg_cn0_a		: std_logic_vector(7 downto 0);
signal ssg_cn0_b		: std_logic_vector(7 downto 0);
signal ssg_cn0_c		: std_logic_vector(7 downto 0);
signal ssg_cn1_bus		: std_logic_vector(7 downto 0);
signal ssg_cn1_a		: std_logic_vector(7 downto 0);
signal ssg_cn1_b		: std_logic_vector(7 downto 0);
signal ssg_cn1_c		: std_logic_vector(7 downto 0);
signal audio_l			: std_logic_vector(15 downto 0);
signal audio_r			: std_logic_vector(15 downto 0);
signal sound			: std_logic_vector(7 downto 0);
-- Soundrive
signal covox_a			: std_logic_vector(7 downto 0);
signal covox_b			: std_logic_vector(7 downto 0);
signal covox_c			: std_logic_vector(7 downto 0);
signal covox_d			: std_logic_vector(7 downto 0);
signal covox			: std_logic;
-- General Sound
signal gs_a				: std_logic_vector(13 downto 0);
signal gs_b				: std_logic_vector(13 downto 0);
signal gs_c				: std_logic_vector(13 downto 0);
signal gs_d				: std_logic_vector(13 downto 0);
signal gs_do_bus		: std_logic_vector(7 downto 0);
signal gs_mdo			: std_logic_vector(7 downto 0);
signal gs_ma			: std_logic_vector(18 downto 0);
signal gs_mwe_n			: std_logic;
-- UART
signal uart_do_bus		: std_logic_vector(7 downto 0);
signal uart_wr			: std_logic;
signal uart_rd			: std_logic;
signal uart_tx_busy		: std_logic;
signal uart_rx_avail	: std_logic;
signal uart_rx_error	: std_logic;
-- CLOCK
signal clk_84mhz		: std_logic;
signal clk_28mhz		: std_logic;
signal clk_9_2mhz		: std_logic;
signal clk_21mhz		: std_logic;
------------------------------------
signal ena_14mhz		: std_logic;
signal ena_7mhz			: std_logic;
signal ena_3_5mhz		: std_logic;
signal ena_1_75mhz		: std_logic;
signal ena_0_4375mhz	: std_logic;
signal ena_cnt			: std_logic_vector(5 downto 0);
-- System
signal reset			: std_logic;
signal locked			: std_logic;
signal loader			: std_logic := '1';
signal dos				: std_logic := '1';
signal clk_sd			: std_logic;

begin

-- PLL
U0: entity work.altpll0
port map (
	inclk0	=> CLK_50MHZ,
	locked	=> locked,
	c0		=> clk_84mhz,
	c1		=> clk_28mhz,
	c2		=> clk_9_2mhz,
	c3		=> clk_21mhz);

-- Zilog Z80A CPU
U1: entity work.T80se
generic map (
	Mode		=> 0,	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
	T2Write		=> 1,	-- 0 => WR_n active in T3, 1 => WR_n active in T2
	IOWait		=> 1)	-- 0 => Single cycle I/O, 1 => Std I/O cycle
port map(
	RESET_n		=> not reset,
	CLK_n		=> clk_28mhz,
	ENA			=> cpu0_ena,
	WAIT_n		=> '1',
	INT_n		=> cpu0_int_n,
	NMI_n		=> '1',
	BUSRQ_n		=> '1',
	M1_n		=> cpu0_m1_n,
	MREQ_n		=> cpu0_mreq_n,
	IORQ_n		=> cpu0_iorq_n,
	RD_n		=> cpu0_rd_n,
	WR_n		=> cpu0_wr_n,
	RFSH_n		=> cpu0_rfsh_n,
	HALT_n		=> open,
	BUSAK_n		=> open,
	A			=> cpu0_a_bus,
	DI			=> cpu0_di_bus,
	DO			=> cpu0_do_bus);

-- Video Spectrum/Pentagon
U2: entity work.video
port map (
	CLK			=> clk_28mhz,
	ENA			=> ena_7mhz,
	INTA		=> cpu0_inta_n,
	INT			=> cpu0_int_n,
	BORDER		=> port_xxfe_reg(2 downto 0),	-- Биты D0..D2 порта xxFE определяют цвет бордюра
	A			=> vid_a_bus,
	DI			=> vid_di_bus,
	MODE		=> vid_mode,					-- 0: Spectrum; 1: Pentagon
	HCNT		=> vid_hcnt,
	VCNT		=> open,
	RGB			=> scan_in,
	HSYNC		=> vid_hsync1,
	VSYNC		=> vid_vsync);
	
-- Scan buffer
U3: entity work.scan_buffer
port map (
	clock	 	=> clk_28mhz,
	data	 	=> scan_in,
	rdaddress	=> scan_sp(1) & scan_cnt,
	wraddress	=> not scan_sp(1) & vid_hcnt,
	wren	 	=> '1',
	q	 		=> scan_out);

-- Video memory
U4: entity work.altram1
port map (
	clock_a		=> clk_28mhz,
	clock_b		=> clk_28mhz,
	address_a	=> vid_scr & cpu0_a_bus(12 downto 0),
	address_b	=> port_7ffd_reg(3) & vid_a_bus,
	data_a		=> cpu0_do_bus,
	data_b		=> "11111111",
	q_a			=> open,
	q_b			=> vid_di_bus,
	wren_a		=> vid_wr,
	wren_b		=> '0');

-- Keyboard
U5: entity work.keyboard
generic map (
	ledStatusSupport=> true,	-- Include code for LED status updates
	clockFilter		=> 15,		-- Number of system-cycles used for PS/2 clock filtering
	ticksPerUsec	=> 28)		-- Timer calibration 28Mhz
port map(
	CLK			=>	clk_28mhz,
	RESET		=>	not locked or not RST_n,
	A			=>	cpu0_a_bus(15 downto 8),
	KEYB		=>	kb_do_bus,
	KEYF		=>	kb_f_bus,
	KEYJOY		=>	kb_joy_bus,
	KEYNUMLOCK	=>	kb_num,
	KEYRESET	=>	reset,
	KEYLED		=>  '0' & vid_mode & turbo,
	PS2_KBCLK	=>	PS2_KBCLK,
	PS2_KBDAT	=>	PS2_KBDAT);

-- PS/2 Mouse Controller
U6: entity work.mouse
generic map (
	-- This allows the use of the scroll-wheel on mice that have them.
	intelliMouseSupport => true,	-- Enable support for intelli-mouse mode.
	clockFilter 		=> 15,		-- Number of system-cycles used for PS/2 clock filtering
	ticksPerUsec		=> 28)		-- Timer calibration 28Mhz clock
port map (
	clk				=> clk_28mhz,
	reset			=> reset,
	ps2_clk			=> PS2_MSCLK,
	ps2_dat		 	=> PS2_MSDAT,
	mousePresent 	=> ms_present,
	leftButton 		=> ms_but_bus(1),
	middleButton 	=> ms_but_bus(2),
	rightButton 	=> ms_but_bus(0),
	X 				=> ms_x_bus,
	Y 				=> ms_y_bus,
	Z				=> ms_but_bus(7 downto 4));	

-- ROM 2K
U7: entity work.altram0
port map (
	clock_a		=> clk_28mhz,
	clock_b		=> clk_28mhz,
	address_a	=> cpu0_a_bus(10 downto 0),
	address_b	=> "00000000000",
	data_a	 	=> cpu0_do_bus,
	data_b	 	=> "00000000",
	q_a	 		=> rom_do_bus,
	q_b	 		=> open,
	wren_a	 	=> '0',
	wren_b	 	=> '0');
	
-- SDMMC Card Controller
U8: entity work.sdmmc
port map (
	RESET		=> reset,
	CLK			=> clk_28mhz,
	A			=> cpu0_a_bus(5),
	DI			=> cpu0_do_bus,
	DO			=> zc_do_bus,
	RD			=> zc_rd,
	WR			=> zc_wr,
	SDPRT		=> SD_PROT,
	SDDET		=> SD_DETECT,
	SDCS_n		=> SD_DAT3,
	SCK			=> SD_CLK,
	MOSI		=> SD_CMD,
	MISO		=> SD_DAT0);

-- SPI Controller
U9: entity work.m25p40
port map (
	RESET		=> reset,
	CLK			=> clk_21mhz,
	CS			=> '1',
	RW			=> spi_wr,
	ADDR		=> cpu0_a_bus(0),
	DATA_IN		=> cpu0_do_bus,
	DATA_OUT	=> spi_do_bus,
	SPI_MISO	=> DATA0,
	SPI_MOSI	=> spi_si,
	SPI_CLK		=> spi_clk,
	SPI_nCS		=> spi_cs_n);

-- TurboSound
U10: entity work.turbosound
port map (
	RESET		=> reset,
	CLK			=> clk_28mhz,
	ENA			=> ena_1_75mhz,
	A			=> cpu0_a_bus,
	DI			=> cpu0_do_bus,
	WR_n		=> cpu0_wr_n,
	IORQ_n		=> cpu0_iorq_n,
	M1_n		=> cpu0_m1_n,
	SEL			=> ssg_sel,
	CN0_DO		=> ssg_cn0_bus,
	CN0_A		=> ssg_cn0_a,
	CN0_B		=> ssg_cn0_b,
	CN0_C		=> ssg_cn0_c,
	CN1_DO		=> ssg_cn1_bus,
	CN1_A		=> ssg_cn1_a,
	CN1_B		=> ssg_cn1_b,
	CN1_C		=> ssg_cn1_c);

-- TDA1543 I2S Controller
U11: entity work.tda1543
port map (
	RESET		=> not locked or not RST_n,
	CS			=> not port_xx01_reg(0),
	CLK			=> clk_9_2mhz,
	DATA_L		=> audio_l,
	DATA_R		=> audio_r,
	BCK			=> DAC_BCK,
	WS			=> dac_ws,
	DATA		=> dac_data);

-- SDRAM Controller
U12: entity work.mt48lc32m8a2
port map (
	CLK			=> clk_84mhz,
	A			=> ram_a_bus & cpu0_a_bus(13 downto 0),
	DI			=> cpu0_do_bus,
	DO			=> sdr_do_bus,
	DM	 		=> '0',
	WR			=> sdr_wr,
	RD			=> sdr_rd,
	RFSH		=> not cpu0_rfsh_n,
	RFSHREQ		=> open,
	IDLE		=> open,
	CK			=> DRAM_CLK,
	CKE			=> DRAM_CKE,
	RAS_n		=> DRAM_RAS_n,
	CAS_n		=> DRAM_CAS_n,
	WE_n		=> DRAM_WE_n,
	DQM			=> DRAM_DQM,
	BA1			=> DRAM_BA(1),
	BA0			=> DRAM_BA(0),
	MA			=> DRAM_A,
	DQ			=> DRAM_D);

-- RTC PCF8583 I2C Controller
U13: entity work.pcf8583
port map (
	RESET		=> reset,
	CLK			=> clk_28mhz,
	ENA			=> ena_0_4375mhz,
	A			=> cpu0_a_bus(4),
	DI			=> cpu0_do_bus,
	DO			=> rtc_do_bus,
	WR			=> rtc_wr,
	I2C_SCL		=> RTC_SCL,
	I2C_SDA		=> RTC_SDA);

-- MC146818A
U14: entity work.mc146818a
port map (
	RESET		=> reset,
	CLK			=> clk_28mhz,
	ENA			=> ena_0_4375mhz,
	CS			=> '1',
	WR			=> mc146818a_wr,
	A			=> mc146818a_a_bus,
	DI			=> cpu0_do_bus,
	DO			=> mc146818a_do_bus);

-- Soundrive
U15: entity work.soundrive
port map (
	RESET		=> reset,
	CLK			=> clk_28mhz,
	CS			=> covox,
	WR_n		=> cpu0_wr_n,
	A			=> cpu0_a_bus(7 downto 0),
	DI			=> cpu0_do_bus,
	IORQ_n		=> cpu0_iorq_n,
	DOS			=> dos,
	OUTA		=> covox_a,
	OUTB		=> covox_b,
	OUTC		=> covox_c,
	OUTD		=> covox_d);

-- General Sound
U16: entity work.gs
port map (
	RESET		=> not port_xx01_reg(2) or not kb_f_bus(10),	-- клавиша [F10] reset GS
	CLK			=> clk_28mhz,
	CLKGS		=> clk_21mhz,
	A			=> cpu0_a_bus,
	DI			=> cpu0_do_bus,
	DO			=> gs_do_bus,
	WR_n		=> cpu0_wr_n,
	RD_n		=> cpu0_rd_n,
	IORQ_n		=> cpu0_iorq_n,
	M1_n		=> cpu0_m1_n,
	OUTA		=> gs_a,
	OUTB		=> gs_b,
	OUTC		=> gs_c,
	OUTD		=> gs_d,
	MA			=> gs_ma,
	MDI			=> SRAM_D,
	MDO			=> gs_mdo,
	MWE_n		=> gs_mwe_n);

-- UART
U17: entity work.uart
generic map (
	-- divisor = 28MHz / 115200 Baud = 243
	divisor		=> 243)
port map (
	CLK			=> clk_28mhz,
	RESET		=> reset,
	WR			=> uart_wr,
	RD			=> uart_rd,
	DI			=> cpu0_do_bus,
	DO			=> uart_do_bus,
	TXBUSY		=> uart_tx_busy,
	RXAVAIL		=> uart_rx_avail,
	RXERROR		=> uart_rx_error,
	RXD			=> TXD,
	TXD			=> RXD);

-------------------------------------------------------------------------------
-- Формирование глобальных сигналов
process (clk_28mhz)
begin
	if clk_28mhz'event and clk_28mhz = '0' then
		ena_cnt <= ena_cnt + 1;
		ena_14mhz <= not ena_cnt(0);
		ena_7mhz <= not ena_cnt(1) and ena_cnt(0);
		ena_3_5mhz <= not ena_cnt(2) and ena_cnt(1) and ena_cnt(0);
		ena_1_75mhz <= not ena_cnt(3) and ena_cnt(2) and ena_cnt(1) and ena_cnt(0);
		ena_0_4375mhz <= not ena_cnt(5) and ena_cnt(4) and ena_cnt(3) and ena_cnt(2) and ena_cnt(1) and ena_cnt(0);
	end if;
end process;

-------------------------------------------------------------------------------
-- ULA
process (reset, clk_28mhz, cpu0_a_bus, dos, port_1ffd_reg, port_7ffd_reg, port_dffd_reg, port_xx00_reg, cpu0_mreq_n, cpu0_wr_n, cpu0_do_bus,
		port_xx01_reg, gs_mwe_n, gs_mdo, gs_ma, dac_data, dac_ws, spi_si, spi_clk, spi_cs_n, turbo, cpu0_mult, ena_1_75mhz, ena_3_5mhz,
		ena_7mhz, ena_14mhz)
begin
	if reset = '1' then
--		port_xx00_reg <= "00000000";	-- маска по AND порта #DFFD
--		port_xx01_reg <= "00000000";	-- bit0 = 0: TDA1543, 1: M25P40; bit 2 = loader 0: on, 1: off;
		port_xxfe_reg <= "00000000";
		port_eff7_reg <= "00000000";
		port_1ffd_reg <= "00000000";
		port_7ffd_reg <= "00000000";
		port_dffd_reg <= "00000000";
--		loader <= '1';
		dos <= '1';
	elsif clk_28mhz'event and clk_28mhz = '1' then
		if cpu0_iorq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus(7 downto 0) = "00000000" then port_xx00_reg <= cpu0_do_bus; end if;
		if cpu0_iorq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus(7 downto 0) = "00000001" then port_xx01_reg <= cpu0_do_bus; end if;
		if cpu0_iorq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus(7 downto 0) = "11111110" then port_xxfe_reg <= cpu0_do_bus; end if;
		if cpu0_iorq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus = "1110111111110111" then port_eff7_reg <= cpu0_do_bus; end if;
		if cpu0_iorq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus = "0001111111111101" then port_1ffd_reg <= cpu0_do_bus; end if;
		if cpu0_iorq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus = "0111111111111101" then port_7ffd_reg <= cpu0_do_bus; end if;
		if cpu0_iorq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus = "1101111111111101" then port_dffd_reg <= cpu0_do_bus; end if;
		if cpu0_iorq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus = "1101111111110111" and port_eff7_reg(7) = '1' then mc146818a_a_bus <= cpu0_do_bus(5 downto 0); end if;
			
		if cpu0_m1_n = '0' and cpu0_mreq_n = '0' and cpu0_a_bus = X"0000" and port_xx01_reg(2) = '1' then loader <= '0'; end if;
		if cpu0_m1_n = '0' and cpu0_mreq_n = '0' and cpu0_a_bus(15 downto 8) = "00111101" and port_7ffd_reg(4) = '1' then dos <= '1';
		elsif cpu0_m1_n = '0' and cpu0_mreq_n = '0' and cpu0_a_bus(15 downto 14) /= "00" then dos <= '0'; end if;
	end if;

	-- Селектор
	case cpu0_a_bus(15 downto 14) is
		when "00" => ram_a_bus <= "100000000" & (not(dos) and not(port_1ffd_reg(1))) & (port_7ffd_reg(4) and not(port_1ffd_reg(1)));
		when "01" => ram_a_bus <= "00000000101";
		when "10" => ram_a_bus <= "00000000010"; 
		when "11" => ram_a_bus <= (port_dffd_reg and port_xx00_reg) & port_7ffd_reg(2 downto 0);
		when others => null;
	end case;

	-- SRAM <- GS/SYS
	if port_xx01_reg(2) = '0' then
		if cpu0_mreq_n = '0' and cpu0_wr_n = '0' then
			SRAM_D <= cpu0_do_bus;
		else
			SRAM_D <= "ZZZZZZZZ";
		end if;
		SRAM_A		<= "0000" & cpu0_a_bus(14 downto 0);
		SRAM_WE_n	<= cpu0_mreq_n or cpu0_wr_n or not cpu0_a_bus(15);
	else
		if gs_mwe_n = '0' then
			SRAM_D 	<= gs_mdo;
		else
			SRAM_D 	<= "ZZZZZZZZ";
		end if;
		SRAM_A		<= gs_ma;
		SRAM_WE_n	<= gs_mwe_n;
	end if;

	SRAM_OE_n	<= '0';

	-- TDA1543 <> MP25P40
	if port_xx01_reg(0) = '0' then
		ASDO 		<= dac_data;
		DCLK 		<= dac_ws;
		NCSO		<= '1';
	else
		ASDO 		<= spi_si;
		DCLK 		<= spi_clk;
		NCSO		<= spi_cs_n;
	end if;

	-- Делитель
	cpu0_mult <= turbo & '1';	-- 01 = 3.5MHz; 11 = 14MHz
	case cpu0_mult is
		when "00" => cpu0_ena <= ena_1_75mhz;
		when "01" => cpu0_ena <= ena_3_5mhz;
		when "10" => cpu0_ena <= ena_7mhz;
		when "11" => cpu0_ena <= ena_14mhz;
		when others => null;
	end case;
end process;

-------------------------------------------------------------------------------
-- Audio mixer
audio_l <= ("000" & port_xxfe_reg(4) & "00000000000") + ("000" & ssg_cn0_a & "0000") + ("000" & ssg_cn0_b & "0000") + ("000" & ssg_cn1_a & "0000") + ("000" & ssg_cn1_b & "0000") + ("000" & covox_a & "0000") + ("000" & covox_b & "0000") + ("00" & gs_a) + ("00" & gs_b);
audio_r <= ("000" & port_xxfe_reg(4) & "00000000000") + ("000" & ssg_cn0_c & "0000") + ("000" & ssg_cn0_b & "0000") + ("000" & ssg_cn1_c & "0000") + ("000" & ssg_cn1_b & "0000") + ("000" & covox_c & "0000") + ("000" & covox_d & "0000") + ("00" & gs_c) + ("00" & gs_d);

-------------------------------------------------------------------------------
-- Port I/O
rtc_wr 			<= '1' when (cpu0_a_bus(7 downto 5) = "100" and cpu0_a_bus(3 downto 0) = "1100" and cpu0_wr_n = '0' and cpu0_iorq_n = '0') else '0';	-- Port xx8C/xx9C[xxxxxxxx_100n1100]
mc146818a_wr 	<= '1' when (port_bff7 = '1' and cpu0_wr_n = '0') else '0';
port_bff7 		<= '1' when (cpu0_iorq_n = '0' and cpu0_a_bus = X"BFF7" and cpu0_m1_n = '1' and port_eff7_reg(7) = '1') else '0';
sdr_wr			<= '1' when (cpu0_mreq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus(15 downto 14) /= "00") else '0';
sdr_rd			<= '1' when (cpu0_mreq_n = '0' and cpu0_rd_n = '0') else '0';
spi_wr 			<= '1' when (cpu0_iorq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus(7 downto 1) = "0000001") else '0';
uart_wr 		<= '1' when (cpu0_iorq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus(7 downto 0) = X"BC") else '0';	-- Port xxBC[xxxxxxxx_10111100]
uart_rd 		<= '1' when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(7 downto 0) = X"BC") else '0';	-- Port xxBC[xxxxxxxx_10111100]
turbo 			<= not(turbo) when kb_f_bus(9)'event and kb_f_bus(9) = '0';			-- клавиша [F9] turbo
covox			<= not(covox) when kb_f_bus(11)'event and kb_f_bus(11) = '0';		-- клавиша [F11] soundrive
ms_left 		<= not(ms_left) when (ms_but_bus(1)'event and ms_but_bus(1) = '1' and ms_but_bus(0) = '1');
zc_rd			<= '1' when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(7 downto 6) = "01" and cpu0_a_bus(4 downto 0) = "10111") else '0';
zc_wr			<= '1' when (cpu0_iorq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus(7 downto 6) = "01" and cpu0_a_bus(4 downto 0) = "10111") else '0';

-------------------------------------------------------------------------------
-- Шина данных CPU0
cpu0_di_bus	<= 	rom_do_bus when (cpu0_mreq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(15 downto 14) = "00" and loader = '1') else
				SRAM_D when (cpu0_mreq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(15) = '1' and port_xx01_reg(2) = '0') else
				sdr_do_bus when (cpu0_mreq_n = '0' and cpu0_rd_n = '0') else	-- MT48LC32M82A-75
				---------------------------------------------------------------
				spi_do_bus when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(7 downto 1) = "0000001") else -- M25P40
				rtc_do_bus when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(7 downto 5) = "100" and cpu0_a_bus(3 downto 0) = "1100") else -- PCF8583
				mc146818a_do_bus when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and port_bff7 = '1' and port_eff7_reg(7) = '1') else -- MC146818A
				"111" & kb_do_bus when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(7 downto 0) = "11111110") else -- Клавиатура, порт xxFE
				gs_do_bus when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(7 downto 4) = "1011" and cpu0_a_bus(2 downto 0) = "011") else	-- General Sound
				zc_do_bus when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(7 downto 6) = "01" and cpu0_a_bus(4 downto 0) = "10111") else -- SDMMC
				ms_but_bus(7 downto 4) & '1' & not(ms_but_bus(2) & ms_but_bus(0) & ms_but_bus(1)) when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(15 downto 0) = "1111101011011111" and ms_present = '1' and ms_left = '0') else -- Mouse Port FADF[11111010_11011111] = <Z>1<MB><LB><RB>
				ms_but_bus(7 downto 4) & '1' & not(ms_but_bus(2) & ms_but_bus(1) & ms_but_bus(0)) when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(15 downto 0) = "1111101011011111" and ms_present = '1' and ms_left = '1') else
				ms_x_bus when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(15 downto 0) = "1111101111011111" and ms_present = '1') else	-- Port FBDF[11111011_11011111] = <X>
				ms_y_bus when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(15 downto 0) = "1111111111011111" and ms_present = '1') else	-- Port FFDF[11111111_11011111] = <Y>
				"000" & kb_joy_bus when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(7 downto 0) = "00011111" and dos = '0' and kb_num = '1') else -- Joystick, порт xx1F
				ssg_cn0_bus when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(15 downto 0) = "1111111111111101" and ssg_sel = '0') else -- TurboSound
				ssg_cn1_bus when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(15 downto 0) = "1111111111111101" and ssg_sel = '1') else
				uart_tx_busy & CBUS4 & "1111" & uart_rx_error & uart_rx_avail when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(7 downto 0) = X"AC") else	-- UART
				uart_do_bus when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(7 downto 0) = X"BC") else
				"11111111";

-------------------------------------------------------------------------------
-- VGA
process (reset, clk_28mhz)
begin
	if clk_28mhz'event and clk_28mhz = '1' then
		if ena_14mhz = '1' then
			if scan_cnt = 447 then
				scan_cnt <= (others => '0');
			else
				scan_cnt <= scan_cnt + 1;
			end if;
			-- HSYNC
			if scan_cnt = 328 then
				scan_sp <= scan_sp + 1;
				vid_hsync <= '0';
			elsif scan_cnt = 381 then
				vid_hsync <= '1'; 
			end if;
		end if;
	end if;
end process;

-- INTA
cpu0_inta_n <= cpu0_iorq_n or cpu0_m1_n;

vid_wr		<= '1' when cpu0_mreq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus(13) = '0' and ((ram_a_bus = "00000000101" ) or (ram_a_bus = "00000000111")) else '0';
vid_scr		<= '1' when (ram_a_bus = "00000000111") else '0';
vid_mode 	<= not(vid_mode) when kb_f_bus(12)'event and kb_f_bus(12) = '0';	-- клавиша [F12] видео режим 0: Spectrum; 1: Pentagon;

VGA_R		<= scan_out(5 downto 4) & 'Z' when GPI = '1' else scan_in(5 downto 4) & 'Z';
VGA_G		<= scan_out(3 downto 2) & 'Z' when GPI = '1' else scan_in(3 downto 2) & 'Z';
VGA_B		<= scan_out(1 downto 0) & 'Z' when GPI = '1' else scan_in(1 downto 0) & 'Z';
VGA_HSYNC 	<= vid_hsync when GPI = '1' else not(vid_hsync1 xor vid_vsync);
VGA_VSYNC 	<= vid_vsync;
-------------------------------------------------------------------------------

end u9speccy_arch;