-------------------------------------------------------------------[21.09.2014]
-- u9-TSConf Version 0.2.2 By MVV
-- DEVBOARD ReVerSE-U9
-------------------------------------------------------------------------------
-- V0.1.0	27.07.2014	: первая версия
-- V0.2.1	03.07.2014	: перенос с U16
-- V0.2.2	05.07.2014	: доработка keyboard.vhd для работы с WC, I2S, Mouse
-- V0.2.6	09.09.2014	: добавлена поддержка IDE Video DAC (3:3:3) (zports.v, video_out.v, lut.vhd)
-- V0.2.7	21.09.2014	: tv80s вместо t80

-- http://tslabs.info/forum/viewtopic.php?f=31&t=401
-- http://zx-pk.ru/showthread.php?t=23528

-- Copyright (c) 2014 TS-Labs, dsp, MVV
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


entity tsconf is
port (
	-- Clock (50MHz)
	CLK			: in std_logic;
	-- SDRAM
	SDRAM_DQ		: inout std_logic_vector(7 downto 0);
	SDRAM_A			: out std_logic_vector(12 downto 0);
	SDRAM_BA		: out std_logic_vector(1 downto 0);
	SDRAM_CLK		: out std_logic;
	SDRAM_CKE		: out std_logic;
	SDRAM_DQML		: out std_logic;
	SDRAM_WE_N		: out std_logic;
	SDRAM_CAS_N		: out std_logic;
	SDRAM_RAS_N		: out std_logic;
	-- SRAM (CY7C1049DV33-10)
	SRAM_A			: out std_logic_vector(18 downto 0);
	SRAM_D			: inout std_logic_vector(7 downto 0);
	SRAM_WE_n		: out std_logic;
	SRAM_OE_n		: out std_logic;
	-- I2C 
	SCL			: inout std_logic;
	SDA			: inout std_logic;
	-- USB-UART (FT232RL)
	TXD			  : out std_logic;
	RXD			  : in std_logic;
	-- RTC (PCF8583)
	RTC_INT_n		: in std_logic;
	-- SPI FLASH
	DATA0			: in std_logic;
	NCSO			: out std_logic;
	DCLK			: out std_logic;
	ASDO			: out std_logic;
	-- DAC (TDA1543)
	DAC_BCK			: out std_logic;
	-- VGA
	R			: out std_logic_vector(2 downto 0);
	G			: out std_logic_vector(2 downto 0);
	B			: out std_logic_vector(2 downto 0);
	HS			: out std_logic;
	VS			: out std_logic;
	-- SD/MMC Memory Card
--	SD_DET_N		: in std_logic;
	SD_MISO			: in std_logic;
	SD_MOSI			: out std_logic;
	SD_CLK			: out std_logic;
	SD_CS_N			: out std_logic;
	-- PS/2
	KB_DAT			: inout std_logic;
	KB_CLK			: inout std_logic;
	MS_DAT			: inout std_logic;
	MS_CLK			: inout std_logic;
	-- GPIO
	RESET_N			: in std_logic);
end tsconf;

architecture rtl of tsconf is
-- CLOCK
signal clk_84mhz		: std_logic;
signal clk_28mhz		: std_logic;
-- CPU0
signal cpu_a_bus		: std_logic_vector(15 downto 0);
signal cpu_do_bus		: std_logic_vector(7 downto 0);
signal cpu_di_bus		: std_logic_vector(7 downto 0);
signal cpu_mreq_n		: std_logic;
signal cpu_iorq_n		: std_logic;
signal cpu_wr_n			: std_logic;
signal cpu_rd_n			: std_logic;
signal cpu_int_n_TS		: std_logic;
signal cpu_m1_n			: std_logic;
signal cpu_rfsh_n		: std_logic;
signal turbo			: std_logic_vector(1 downto 0);
signal im2vect			: std_logic_vector(7 downto 0);
-- zsignal
signal cpu_stall		: std_logic; -- zmem -> zclock
signal cpu_req			: std_logic; -- zmem -> arbiter
signal cpu_wrbsel		: std_logic; -- zmem -> arbiter
signal cpu_next			: std_logic; -- arbiter -> zmem
signal cpu_current		: std_logic; -- arbiter -> zmem
signal cpu_strobe		: std_logic; -- arbiter -> zmem
signal cpu_latch		: std_logic; -- arbiter -> zmem
signal cpu_addr      		: std_logic_vector(23 downto 0);
signal cpu_addr_20   		: std_logic_vector(20 downto 0);
signal cpu_addr_ext  		: std_logic_vector(2 downto 0);
signal csvrom        		: std_logic;
signal curr_cpu      		: std_logic;
-- Memory
signal rom_do_bus		: std_logic_vector(7 downto 0);
signal cacheconf		: std_logic_vector(3 downto 0);
-- SDRAM
signal sdr_do_bus		: std_logic_vector(7 downto 0);
signal sdr_do_bus_16		: std_logic_vector(15 downto 0);
signal sdr2cpu_do_bus_16	: std_logic_vector(15 downto 0);
signal sdr_wr			: std_logic;
signal sdr_rd			: std_logic;
signal req           		: std_logic;
signal rnw           		: std_logic;
signal dram_addr		: std_logic_vector(23 downto 0);
signal dram_bsel		: std_logic_vector(1 downto 0);
signal dram_wrdata  		: std_logic_vector(15 downto 0);
signal dram_req			: std_logic;
signal dram_rnw			: std_logic;
-- Port
signal port_xxfe_reg		: std_logic_vector(7 downto 0);
signal port_xx01_reg		: std_logic_vector(7 downto 0) := "00000000";
signal ena_1_75mhz		: std_logic;
signal ena_cnt			: std_logic_vector(5 downto 0);
-- System
signal reset			: std_logic;
signal areset			: std_logic;
--signal key_reset		: std_logic;
signal locked			: std_logic;
signal loader			: std_logic := '1';
signal dos			: std_logic := '1';
--signal xtpage_0     	 	: std_logic_vector(7 downto 0);
-- PS/2 Keyboard
signal kb_do_bus		: std_logic_vector(4 downto 0);
signal kb_f_bus			: std_logic_vector(4 downto 0);
signal kb_joy_bus		: std_logic_vector(4 downto 0);
signal key_scancode  		: std_logic_vector(7 downto 0);
-- UART
signal uart_do_bus		: std_logic_vector(7 downto 0);
signal uart_wr			: std_logic;
signal uart_rd			: std_logic;
signal uart_tx_empty	      	: std_logic;
signal uart_tx_fifo_empty	: std_logic;
signal uart_rx_avail		: std_logic;
--signal uart_rx_error		: std_logic;
signal uart_LCR_wr		: std_logic;
signal uart_LCR	   		: std_logic_vector(7 downto 0);
-- MC146818A
signal mc146818a_wr		: std_logic;
--signal mc146818a_rd		: std_logic;
signal mc146818a_do_bus		: std_logic_vector(7 downto 0);
signal port_bff7		: std_logic;
signal port_eff7_reg		: std_logic_vector(7 downto 0);
signal ena_0_4375mhz		: std_logic;
signal gluclock_addr		: std_logic_vector(7 downto 0);
-- Soundrive
signal covox_a			: std_logic_vector(7 downto 0);
signal covox_b			: std_logic_vector(7 downto 0);
signal covox_c			: std_logic_vector(7 downto 0);
signal covox_d			: std_logic_vector(7 downto 0);
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
-- AUDIO
signal audio_l			: std_logic_vector(15 downto 0);
signal audio_r			: std_logic_vector(15 downto 0);
signal clk_codec		: std_logic;
-- clock
signal f0 			: std_logic;
signal f1 			: std_logic;
signal h0 			: std_logic;
signal h1 			: std_logic;
signal c0 			: std_logic;
signal c1 			: std_logic;
signal c2 			: std_logic;
signal c3 			: std_logic;
signal ay_clk        	   	: std_logic;
signal zclk           		: std_logic;
signal zpos           		: std_logic;
signal zneg	        	: std_logic;
--signal dos_on			: std_logic;
--signal dos_off		: std_logic;
signal vdos			: std_logic;
signal pre_vdos			: std_logic;
signal vdos_off			: std_logic;
signal vdos_on			: std_logic;
signal dos_change		: std_logic;
--signal dos_stall		: std_logic;
-- out zsignals
signal m1			: std_logic;
--signal rfsh			: std_logic;
signal rd			: std_logic;
signal wr			: std_logic;
signal iorq			: std_logic;
signal mreq			: std_logic;
signal rdwr			: std_logic;
signal iord			: std_logic;
signal iowr			: std_logic;
signal iorw			: std_logic;
signal memrd			: std_logic;
signal memwr			: std_logic;
--signal memrw			: std_logic;
signal opfetch			: std_logic;
signal intack			: std_logic;
-- strobre
signal iorq_s			: std_logic;
--signal mreq_s			: std_logic;
signal iord_s			: std_logic;
signal iowr_s			: std_logic;
signal iorw_s			: std_logic;
--signal memrd_s		: std_logic;
signal memwr_s			: std_logic;
--signal memrw_s		: std_logic;
signal opfetch_s		: std_logic;
-- zports OUT
signal dout_ports  		: std_logic_vector(7 downto 0);
signal ena_ports		: std_logic;
signal xt_page	  		: std_logic_vector(31 downto 0);
signal fmaddr			: std_logic_vector(4 downto 0);
signal sysconf			: std_logic_vector(7 downto 0);
signal memconf			: std_logic_vector(7 downto 0);
--signal fddvirt		: std_logic_vector(3 downto 0);
--signal im2v_frm		: std_logic_vector(2 downto 0);
--signal im2v_lin		: std_logic_vector(2 downto 0);
--signal im2v_dma		: std_logic_vector(2 downto 0);
signal intmask			: std_logic_vector(7 downto 0);
signal dmaport_wr		: std_logic_vector(8 downto 0);
--signal mus_in_TS   		: std_logic_vector(7 downto 0);
-- VIDEO_TS
signal go			: std_logic;
signal go_arbiter 		: std_logic;
-- z80
signal zmd			: std_logic_vector(15 downto 0);
signal zma			: std_logic_vector(7 downto 0);
signal cram_we			: std_logic;
signal sfile_we 		: std_logic;
signal zborder_wr		: std_logic; 
signal border_wr		: std_logic;
signal zvpage_wr		: std_logic;
signal vpage_wr			: std_logic;
signal vconf_wr			: std_logic;
signal gx_offsl_wr		: std_logic;
signal gx_offsh_wr		: std_logic;
signal gy_offsl_wr		: std_logic;
signal gy_offsh_wr		: std_logic;
signal t0x_offsl_wr		: std_logic;
signal t0x_offsh_wr		: std_logic;
signal t0y_offsl_wr		: std_logic;
signal t0y_offsh_wr		: std_logic;
signal t1x_offsl_wr		: std_logic;
signal t1x_offsh_wr		: std_logic;
signal t1y_offsl_wr		: std_logic;
signal t1y_offsh_wr		: std_logic;
signal tsconf_wr		: std_logic;
signal palsel_wr		: std_logic;
signal tmpage_wr		: std_logic;
signal t0gpage_wr		: std_logic;
signal t1gpage_wr		: std_logic;
signal sgpage_wr		: std_logic;
signal hint_beg_wr 		: std_logic;
signal vint_begl_wr		: std_logic;
signal vint_begh_wr		: std_logic;
-- ZX controls
signal res			: std_logic;
signal int_start_frm		: std_logic;
signal int_start_lin		: std_logic;
-- DRAM interface
signal video_addr		: std_logic_vector(20 downto 0);
signal video_bw			: std_logic_vector(4 downto 0);
signal video_go			: std_logic;
signal dram_rdata     		: std_logic_vector(15 downto 0);  -- raw, should be latched by c2 (video_next)
signal video_next		: std_logic;
signal video_pre_next		: std_logic; 
signal next_video		: std_logic;
signal video_strobe		: std_logic;
signal video_next_strobe 	: std_logic;
-- TS
signal ts_addr			: std_logic_vector(20 downto 0);
signal ts_req			: std_logic;
signal ts_z80_lp		: std_logic;
-- IN
signal ts_pre_next		: std_logic;
signal ts_next			: std_logic;
-- TM
signal tm_addr			: std_logic_vector(20 downto 0);
signal tm_req			: std_logic;
-- Video
signal tm_next			: std_logic;
signal vred_ts			: std_logic_vector(2 downto 0);
signal vgrn_ts			: std_logic_vector(2 downto 0);
signal vblu_ts			: std_logic_vector(2 downto 0);	
signal hsync_ts 		: std_logic;
signal vsync_ts 		: std_logic;
-- DMA
signal dma_rnw			: std_logic;
signal dma_req			: std_logic;
signal dma_z80_lp		: std_logic;
signal dma_wrdata		: std_logic_vector(15 downto 0);
signal dma_addr			: std_logic_vector(20 downto 0);	
signal dma_next			: std_logic;
signal dma_act			: std_logic;
signal dma_cram_we		: std_logic;
signal dma_sfile_we		: std_logic;
-- zmap
signal dma_data			: std_logic_vector(15 downto 0);
signal dma_wraddr		: std_logic_vector(7 downto 0);
signal int_start_dma		: std_logic;
-- SPI
signal spi_stb			: std_logic;
signal spi_start		: std_logic;
signal dma_spi_req		: std_logic;
signal dma_spi_din 		: std_logic_vector(7 downto 0);	
signal cpu_spi_req		: std_logic;
signal cpu_spi_din		: std_logic_vector(7 downto 0);
signal spi_dout			: std_logic_vector(7 downto 0);
-- Keys
signal key_f			: std_logic_vector(4 downto 0);
signal key			: std_logic_vector(4 downto 0) := "00000";
-- SPI
signal spi_wr			: std_logic;
signal spi_do_bus		: std_logic_vector(7 downto 0);
signal spi_busy			: std_logic;
-- GS
signal clk_21mhz		: std_logic;
-- I2C
signal i2c_do_bus		: std_logic_vector(7 downto 0);
signal i2c_wr			: std_logic;
-- Z-Controller
signal zc_rd			: std_logic;
signal zc_wr			: std_logic;
signal zc_do_bus		: std_logic_vector(7 downto 0);
signal zc_mosi			: std_logic;
signal zc_clk			: std_logic;
signal zc_cs_n			: std_logic;
-- TS SD
signal sd_si_ts			: std_logic;
signal sd_clk_ts		: std_logic;
signal sd_cs_n_ts		: std_logic;

signal spi_si			: std_logic;
signal spi_clk			: std_logic;
signal spi_cs_n			: std_logic;
signal dac_data			: std_logic;
signal dac_ws			: std_logic;
-- General Sound
signal gs_a			: std_logic_vector(13 downto 0);
signal gs_b			: std_logic_vector(13 downto 0);
signal gs_c			: std_logic_vector(13 downto 0);
signal gs_d			: std_logic_vector(13 downto 0);
signal gs_do_bus		: std_logic_vector(7 downto 0);
signal gs_mdo			: std_logic_vector(7 downto 0);
signal gs_ma			: std_logic_vector(18 downto 0);
signal gs_mwe_n			: std_logic;
-- PCF8583
signal rtc_do_bus		: std_logic_vector(7 downto 0);
signal rtc_wr			: std_logic;
-- PS/2 Mouse
signal ms_but_bus		: std_logic_vector(7 downto 0);
signal ms_present		: std_logic;
signal ms_left			: std_logic;
signal ms_x_bus			: std_logic_vector(7 downto 0);
signal ms_y_bus			: std_logic_vector(7 downto 0);
signal ms_clk_out		: std_logic;
signal ms_buf_out		: std_logic;

-------------------------------------------------------------------------------
-- COMPONENTS TS Lab
-------------------------------------------------------------------------------
component clock is
port (
	clk 			: in std_logic;
	ay_mod   		: in std_logic_vector(1 downto 0);
	f0       		: out std_logic; 
	f1      		: out std_logic; 
	h0     	 		: out std_logic; 
	h1     			: out std_logic;
	c0       		: out std_logic;
	c1       		: out std_logic; 
	c2       		: out std_logic; 
	c3       		: out std_logic;
	ay_clk   		: out std_logic);
end component;

component zclock is
port (
	clk 			: in std_logic;
	zclk_out 		: out std_logic;
	c1       		: in std_logic;
	c3       		: in std_logic; 
	c14Mhz         		: in std_logic; 
	iorq_s 			: in std_logic;
	external_port		: in std_logic;
	zpos 			: out std_logic;
	zneg 			: out std_logic;
	dos_stall_o		: out std_logic;
	cpu_stall		: in std_logic;
	ide_stall		: in std_logic;
	dos_on			: in std_logic;
	vdos_off  		: in std_logic;
	turbo			: in std_logic_vector(1 downto 0));	-- input [1:0] turbo  2'b00 -  3.5 MHz, 2'b01 -  7.0 MHz, 2'b1x - 14.0 MHz
end component;

component tv80s is
port (
	reset_n 		: in std_logic;
	clk			: in std_logic;
	wait_n 			: in std_logic;
	int_n			: in std_logic;
	nmi_n			: in std_logic;
	busrq_n			: in std_logic;
	m1_n			: out std_logic;
	mreq_n			: out std_logic;
	iorq_n			: out std_logic;
	rd_n			: out std_logic;
	wr_n			: out std_logic;
	rfsh_n			: out std_logic;
	halt_n			: out std_logic;
	busak_n			: out std_logic;
	A			: out std_logic_vector(15 downto 0);
	di			: in  std_logic_vector(7 downto 0);
	dout			: out std_logic_vector(7 downto 0));
end component;

component zsignals is
port (
	clk			: in std_logic;
	zpos			: in std_logic;
	iorq_n			: in std_logic;
	mreq_n			: in std_logic;
	m1_n			: in std_logic;
	rfsh_n			: in std_logic;
	rd_n			: in std_logic;
	wr_n			: in std_logic;
	m1			: out std_logic;
	rfsh			: out std_logic;
	rd			: out std_logic;
	wr			: out std_logic;
	iorq			: out std_logic;
	mreq			: out std_logic;
	rdwr			: out std_logic;
	iord			: out std_logic;
	iowr			: out std_logic;
	iorw			: out std_logic;
	memrd			: out std_logic;
	memwr			: out std_logic;
	memrw			: out std_logic;
	opfetch			: out std_logic;
	intack			: out std_logic;
	iorq_s			: out std_logic;
	mreq_s			: out std_logic;
	iord_s			: out std_logic;
	iowr_s			: out std_logic;
	iorw_s			: out std_logic;
	memrd_s			: out std_logic;
	memwr_s			: out std_logic;
	memrw_s			: out std_logic;
	opfetch_s		: out std_logic);
end component;

component zports is
port (
	zclk    		: in std_logic;
	clk			: in std_logic;
	din			: in std_logic_vector(7 downto 0);
	dout			: out std_logic_vector(7 downto 0);
	dataout			: out std_logic;
	a			: in std_logic_vector(15 downto 0);
	rst			: in std_logic;
	loader			: in std_logic;
	opfetch			: in std_logic;
	rd			: in std_logic;
	wr			: in std_logic;
	rdwr			: in std_logic;
	iorq			: in std_logic;
	iorq_s			: in std_logic;
	iord			: in std_logic;
	iord_s			: in std_logic;
	iowr			: in std_logic;
	iowr_s			: in std_logic;
	iorw			: in std_logic;
	iorw_s			: in std_logic;
	porthit			: out std_logic; -- when internal port hit occurs, this is 1, else 0; used for iorq1_n iorq2_n on zxbus
	external_port		: out std_logic; -- asserts for AY and VG93 accesses
	zborder_wr  		: out std_logic;
	border_wr		: out std_logic;
	zvpage_wr		: out std_logic;
	vpage_wr		: out std_logic;
	vconf_wr		: out std_logic;	
	gx_offsl_wr		: out std_logic;	
	gx_offsh_wr		: out std_logic;	
	gy_offsl_wr		: out std_logic;	
	gy_offsh_wr		: out std_logic;	
	t0x_offsl_wr		: out std_logic;
	t0x_offsh_wr		: out std_logic;
	t0y_offsl_wr		: out std_logic;
	t0y_offsh_wr		: out std_logic;
	t1x_offsl_wr		: out std_logic;
	t1x_offsh_wr		: out std_logic;
	t1y_offsl_wr		: out std_logic;
	t1y_offsh_wr		: out std_logic;
	tsconf_wr		: out std_logic;	
	palsel_wr		: out std_logic;	
	tmpage_wr		: out std_logic;	
	t0gpage_wr		: out std_logic;	
	t1gpage_wr		: out std_logic;	
	sgpage_wr		: out std_logic;	
	hint_beg_wr		: out std_logic; 
	vint_begl_wr		: out std_logic;
	vint_begh_wr		: out std_logic;
	xt_page 		: out std_logic_vector(31 downto 0);
	fmaddr			: out std_logic_vector(4 downto 0);
	sysconf			: out std_logic_vector(7 downto 0);
	memconf			: out std_logic_vector(7 downto 0);
	cacheconf  		: out std_logic_vector(3 downto 0);
	fddvirt			: out std_logic_vector(3 downto 0);
	--im2v_frm		: out std_logic_vector(2 downto 0);
	--im2v_lin		: out std_logic_vector(2 downto 0);
	--im2v_dma		: out std_logic_vector(2 downto 0);
	intmask			: out std_logic_vector(7 downto 0);
	dmaport_wr		: out std_logic_vector(8 downto 0);
	dma_act			: in std_logic;
	dos			: in std_logic;
	vdos			: in std_logic;
	vdos_on  		: out std_logic;
	vdos_off		: out std_logic;
	ay_bdir			: out std_logic;
	ay_bc1			: out std_logic;
	covox_wr		: out std_logic;
	beeper_wr		: out std_logic; 
	rstrom			: in std_logic_vector(1 downto 0);
	tape_read		: in std_logic;
	ide_in			: in std_logic_vector(15 downto 0);
	ide_out			: out std_logic_vector(15 downto 0);
	ide_cs0_n		: out std_logic;
	ide_cs1_n 		: out std_logic;
	ide_req			: out std_logic;
	ide_stb			: in std_logic;
	ide_ready		: in std_logic;
	ide_stall		: out std_logic;
	keys_in			: in std_logic_vector(4 downto 0);	-- keys (port FE)
	mus_in			: in std_logic_vector(7 downto 0); 	-- mouse (xxDF)
	kj_in			: in std_logic_vector(4 downto 0);
	vg_intrq		: in std_logic;
	vg_drq			: in std_logic;  			-- from vg93 module - drq + irq read
	vg_cs_n			: out std_logic;
	vg_wrFF			: out std_logic;
	drive_sel		: out std_logic_vector(1 downto 0); 	-- disk drive selection
	sdcs_n			: out std_logic;
	sd_start		: out std_logic;
	sd_datain		: out std_logic_vector(7 downto 0);
	sd_dataout		: in std_logic_vector(7 downto 0);
	gluclock_addr		: out std_logic_vector(7 downto 0);
	comport_addr		: out std_logic_vector(2 downto 0);
	wait_start_gluclock	: out std_logic; 			-- begin wait from some ports
	wait_start_comport	: out std_logic;  
	wait_write		: out std_logic_vector(7 downto 0);
	wait_read		: in std_logic_vector(7 downto 0) ;
	com_data_rx 		: in std_logic_vector(7 downto 0);
	com_status		: in std_logic_vector(7 downto 0);
	TST			: out std_logic_vector(7 downto 0);
	lock_conf   		: in std_logic);
end component;

component zmem is
port (
	clk			: in std_logic;
	c0			: in std_logic;
	c1 			: in std_logic;
	c2 			: in std_logic;
	c3			: in std_logic;
	zneg			: in std_logic;
	zpos			: in std_logic;
	rst			: in std_logic;
	za			: in std_logic_vector(15 downto 0);
	zd_out			: out std_logic_vector(7 downto 0); 	-- output to Z80 bus
	zd_ena			: out std_logic; 			-- output to Z80 bus enable
	opfetch			: in std_logic;
	opfetch_s		: in std_logic; 
	mreq			: in std_logic; 
	memrd 			: in std_logic; 
	memwr			: in std_logic; 
	memwr_s			: in std_logic; 
	turbo			: in std_logic_vector(1 downto 0);
	cache_en		: in std_logic_vector(3 downto 0);		
	memconf			: in std_logic_vector(3 downto 0);
	xt_page			: in std_logic_vector(31 downto 0);
	xtpage_0		: out std_logic_vector(7 downto 0);
	rompg			: out std_logic_vector(4 downto 0);	-- 32page = 512kB
	csrom			: out std_logic;
	romoe_n			: out std_logic;
	romwe_n			: out std_logic;
	csvrom			: out std_logic;
	dos			: out std_logic; 			-- DOS
	dos_on			: out std_logic;
	dos_off			: out std_logic;
	dos_change  		: out std_logic; 			-- state is shanging
	vdos			: out std_logic; 			-- Virtual DOS
	pre_vdos		: out std_logic; 			-- Virtual DOS
	vdos_on 		: in std_logic;
	vdos_off		: in std_logic;
	cpu_req			: out std_logic; 
	cpu_addr		: out std_logic_vector(20 downto 0);
	cpu_wrbsel		: out std_logic; 			-- for 16bit data
	cpu_rddata		: in std_logic_vector(15 downto 0); 	-- RD
	cpu_next		: in std_logic;
	cpu_strobe		: in std_logic;				-- from ARBITER
	cpu_latch		: in std_logic;				-- from ARBITER
	cpu_stall		: out std_logic; 			-- for Zclock if HI-> SRALL (ZCLK)
	loader			: in std_logic;	
	testkey			: in std_logic;
	intt			: in std_logic;
	tst			: out std_logic_vector(3 downto 0));
end component;

component arbiter is
port (
	clk			: in std_logic;
	c0			: in std_logic;
	c1 			: in std_logic;
	c2 			: in std_logic;
	c3			: in std_logic;
	dram_addr 		: out std_logic_vector(23 downto 0); -- address for dram access
	dram_req		: out std_logic; -- dram request
	dram_rnw		: out std_logic; -- Read-NotWrite
	dram_bsel		: out std_logic_vector(1 downto 0); -- byte select: bsel[1] for wrdata[15:8], bsel[0] for wrdata[7:0]
	dram_wrdata 		: out std_logic_vector(15 downto 0); -- data to be written
	video_addr		: in std_logic_vector(23 downto 0); -- during access block, only when video_strobe==1
	go			: in std_logic; -- start video access blocks
	video_bw		: in std_logic_vector(4 downto 0);  -- [4:3] -total cycles: 11 = 8 / 01 = 4 / 00 = 2
	video_pre_next		: out std_logic; -- (c1)
	video_next		: out std_logic; -- (c2) at this signal video_addr may be changed; it is one clock leading the video_strobe
	video_strobe		: out std_logic; -- (c3) one-cycle strobe meaning that video_data is available
	video_next_strobe	: out std_logic; -- OUT
	next_vid		: out std_logic; -- used for TM prefetch
	cpu_addr		: in std_logic_vector(23 downto 0);
	cpu_wrdata		: in std_logic_vector(7 downto 0);
	cpu_req			: in std_logic;
	cpu_rnw			: in std_logic;
	cpu_wrbsel		: in std_logic;
	cpu_next		: out std_logic; -- next cycle is allowed to be used by CPU
	cpu_strobe		: out std_logic; -- c2 strobe
	cpu_latch      		: out std_logic; -- c2-c3 strobe
	curr_cpu_o		: out std_logic; -- c0,c1,c2 strobe
	dma_addr		: in std_logic_vector(23 downto 0);
	dma_wrdata		: in std_logic_vector(15 downto 0);
	dma_req			: in std_logic;
	dma_z80_lp		: in std_logic;
	dma_rnw			: in std_logic;
	dma_next		: out std_logic;
	ts_addr			: in std_logic_vector(23 downto 0);
	ts_req			: in std_logic; 
	ts_z80_lp		: in std_logic; 
	ts_pre_next		: out std_logic;
	ts_next			: out std_logic;
	tm_addr			: in std_logic_vector(23 downto 0); 
	tm_req			: in std_logic; 
	tm_next			: out std_logic;
	TST             	: out std_logic_vector(7 downto 0));
end component;

component video_top is
port (
	clk			: in std_logic;
	f0			: in std_logic;
	f1 			: in std_logic;
	h0 			: in std_logic;
	h1			: in std_logic;
	c0			: in std_logic;
	c1 			: in std_logic;
	c2 			: in std_logic;
	c3			: in std_logic;
	vred			: out std_logic_vector(2 downto 0); 
	vgrn			: out std_logic_vector(2 downto 0);
	vblu			: out std_logic_vector(2 downto 0);
	hsync 			: out std_logic;
	vsync 			: out std_logic;
	csync			: out std_logic;
	vga_blank 		: out std_logic;
	a 			: in std_logic_vector(15 downto 0);
	d			: in std_logic_vector(7 downto 0);		
	zmd			: in std_logic_vector(15 downto 0);
	zma			: in std_logic_vector(7 downto 0);
	cram_we			: in std_logic;
	sfile_we 		: in std_logic;
	zborder_wr		: in std_logic; 
	border_wr		: in std_logic;
	zvpage_wr		: in std_logic;
	vpage_wr		: in std_logic;
	vconf_wr		: in std_logic;
	gx_offsl_wr		: in std_logic;
	gx_offsh_wr		: in std_logic;
	gy_offsl_wr		: in std_logic;
	gy_offsh_wr		: in std_logic;
	t0x_offsl_wr		: in std_logic;
	t0x_offsh_wr		: in std_logic;
	t0y_offsl_wr		: in std_logic;
	t0y_offsh_wr		: in std_logic;
	t1x_offsl_wr		: in std_logic;
	t1x_offsh_wr		: in std_logic;
	t1y_offsl_wr		: in std_logic;
	t1y_offsh_wr		: in std_logic;
	tsconf_wr		: in std_logic;
	palsel_wr		: in std_logic;
	tmpage_wr		: in std_logic;
	t0gpage_wr		: in std_logic;
	t1gpage_wr		: in std_logic;
	sgpage_wr		: in std_logic;
	hint_beg_wr 		: in std_logic;
	vint_begl_wr		: in std_logic;
	vint_begh_wr		: in std_logic;
	res			: in std_logic;
	int_start		: out std_logic;
	line_start_s		: out std_logic;
	video_addr		: out std_logic_vector(20 downto 0);
	video_bw		: out std_logic_vector(4 downto 0);
	video_go		: out std_logic;
	dram_rdata		: in std_logic_vector(15 downto 0);  -- raw, should be latched by c2 (video_next)
	video_next		: in std_logic;
	video_pre_next		: in std_logic; 
	next_video		: in std_logic;
	video_strobe		: in std_logic;
	video_next_strobe 	: in std_logic; -- INPUT
	ts_addr			: out std_logic_vector(20 downto 0);
	ts_req			: out std_logic;
	ts_z80_lp		: out std_logic;
	ts_pre_next		: in std_logic;
	ts_next			: in std_logic;
	tm_addr			: out std_logic_vector(20 downto 0);
	tm_req			: out std_logic;
	tm_next			: in std_logic;
	cfg_60hz		: in std_logic;
	sync_pol		: in std_logic;
	vga_on			: in std_logic;
	tst            		: out std_logic_vector(3 downto 0));
end component;

component dma is
port (
	clk 			: in std_logic;
	c2			: in std_logic;
	reset			: in std_logic;
	dmaport_wr 		: in std_logic_vector(8 downto 0);
	dma_act 		: out std_logic;
	data 			: out std_logic_vector(15 downto 0);
	wraddr 			: out std_logic_vector(7 downto 0);
	int_start		: out std_logic;
	zdata 			: in std_logic_vector(7 downto 0);
	dram_addr		: out std_logic_vector(20 downto 0);
	dram_rddata		: in std_logic_vector(15 downto 0);
	dram_wrdata		: out std_logic_vector(15 downto 0);
	dram_req		: out std_logic;
	dma_z80_lp		: out std_logic;
	dram_rnw		: out std_logic;
	dram_next		: in std_logic;
	spi_rddata 		: in std_logic_vector(7 downto 0);
	spi_wrdata		: out std_logic_vector(7 downto 0);
	spi_req			: out std_logic;
	spi_stb			: in std_logic;
	spi_start		: in std_logic;
	ide_in 			: in std_logic_vector(15 downto 0);
	ide_out 		: out std_logic_vector(15 downto 0);
	ide_req			: out std_logic;
	ide_rnw			: out std_logic;
	ide_stb			: in std_logic;
	cram_we			: out std_logic;
	sfile_we		: out std_logic;
	TST			: out std_logic_vector(3 downto 0));
end component;

component zmaps is
port (
	clk			: in std_logic;
	memwr_s			: in std_logic;
	a			: in std_logic_vector(15 downto 0);
	d			: in std_logic_vector(7 downto 0);
	fmaddr			: in std_logic_vector(4 downto 0);
	zmd			: out std_logic_vector(15 downto 0);
	zma			: out std_logic_vector(7 downto 0);
	dma_data		: in std_logic_vector(15 downto 0);
	dma_wraddr 		: in std_logic_vector(7 downto 0);
	dma_cram_we		: in std_logic;
	dma_sfile_we		: in std_logic;
	cram_we			: out std_logic;
	sfile_we		: out std_logic);
end component;

component spi is
port (
	clk			: in std_logic; -- system clk
	sck      		: out std_logic; -- SPI bus pins...
	sdo			: out std_logic; 
	sdi			: in std_logic; 
	stb			: out std_logic; -- ready strobe, 1 clock length
	start			: out std_logic; -- start strobe, 1 clock length
	bsync			: out std_logic; -- for vs1001	
	dma_req			: in std_logic; 
	dma_din 		: in std_logic_vector(7 downto 0);
	cpu_req			: in std_logic; 
	cpu_din			: in std_logic_vector(7 downto 0);
	dout			: out std_logic_vector(7 downto 0);	
	speed			: in std_logic_vector(1 downto 0);   
	tst 			: out std_logic_vector(2 downto 0));
end component;

component zint is
port (
	clk 			: in std_logic; 
	zclk 			: in std_logic; 
	res 			: in std_logic; 
	int_start_frm 		: in std_logic;
	int_start_lin 		: in std_logic;
	int_start_dma 		: in std_logic;
	vdos			: in std_logic; 
	intack			: in std_logic; 
	--im2v_frm		: in std_logic_vector(2 downto 0);
	--im2v_lin		: in std_logic_vector(2 downto 0);
	--im2v_dma		: in std_logic_vector(2 downto 0); 
	intmask			: in std_logic_vector(7 downto 0);  
	im2vect			: out std_logic_vector(7 downto 0); 	
	int_n			: out std_logic);
end component;

-------------------------------------------------------------------------------

begin

-- PLL
SE0: entity work.altpll0
port map (
	areset			=> areset,
	inclk0			=> CLK, -- 50Mhz
	locked			=> locked,
	c0			=> clk_84mhz,
	c1			=> clk_28mhz,
	c2			=> clk_21mhz,
	c3			=> clk_codec);

TS01: clock
port map (
	clk			=> clk_28mhz,
	ay_mod 			=> "00",
	f0			=> f0,
	f1			=> f1,
	h0			=> h0,
	h1			=> h1,
	c0			=> c0,
	c1			=> c1,
	c2			=> c2,
	c3			=> c3,
	ay_clk			=> open);	

TS02: zclock
port map (
	clk			=> clk_28mhz,
	c1			=> c1,
	c3			=> c3,
	c14Mhz			=> c1,
	zclk_out		=> zclk,
	zpos			=> zpos,
	zneg			=> zneg,
	dos_stall_o 		=> open,
	iorq_s			=> iorq_s,
	dos_on  		=> dos_change,
	vdos_off 		=> vdos_off,
	cpu_stall		=> cpu_stall,
	ide_stall		=> '0',
	external_port 		=> '0',
	turbo			=> turbo);

-- Zilog Z80A CPU
TS03: tv80s
port map (
	reset_n			=> not reset,
	clk			=> zclk,
	wait_n			=> '1',
	int_n			=> cpu_int_n_TS,
	nmi_n			=> '1',
	busrq_n			=> '1',
	m1_n			=> cpu_m1_n,
	mreq_n			=> cpu_mreq_n,
	iorq_n			=> cpu_iorq_n,
   	rd_n			=> cpu_rd_n,
	wr_n			=> cpu_wr_n,
	rfsh_n			=> cpu_rfsh_n,
	halt_n			=> open,
	busak_n			=> open,
	A			=> cpu_a_bus,
	DI			=> cpu_di_bus,
	DOUT			=> cpu_do_bus);

--z80_unit: entity work.T80s
--generic map (
--	Mode			=> 0,	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
--	T2Write			=> 1,	-- 0 => WR_n active in T3, 1 => WR_n active in T2
--	IOWait			=> 1)	-- 0 => Single cycle I/O, 1 => Std I/O cycle
--port map (
--	RESET_n			=> not reset,
--	CLK_n			=> zclk,
--	WAIT_n			=> '1',
--	INT_n			=> cpu_int_n_TS or (dram_req and key_f(4)),
--	NMI_n			=> '1',
--	BUSRQ_n			=> '1',
--	M1_n			=> cpu_m1_n,
--	MREQ_n			=> cpu_mreq_n,
--	IORQ_n			=> cpu_iorq_n,
--	RD_n			=> cpu_rd_n,
--	WR_n			=> cpu_wr_n,
--	RFSH_n			=> cpu_rfsh_n,
--	HALT_n			=> open,
--	BUSAK_n			=> open,
--	A			=> cpu_a_bus,
--	DI			=> cpu_di_bus,
--	DO			=> cpu_do_bus,
--	SavePC      		=> open,
--	SaveINT     		=> open,
--	RestorePC   		=> (others => '1'),
--	RestoreINT  		=> (others => '1'),
--	RestorePC_n 		=> '1');

TS04: zsignals
port map (
	clk			=> clk_28mhz,
	zpos			=> zpos,
	iorq_n			=> cpu_iorq_n,
	mreq_n			=> cpu_mreq_n,
	m1_n			=> cpu_m1_n,
	rfsh_n			=> cpu_rfsh_n,
	rd_n			=> cpu_rd_n,
	wr_n			=> cpu_wr_n,
	m1			=> open,
	rfsh			=> open,
	rd			=> rd,
	wr			=> wr,
	iorq			=> iorq,
	mreq			=> mreq,
	rdwr			=> rdwr,
	iord			=> iord,
	iowr			=> iowr,
	iorw			=> iorw,
	memrd			=> memrd,
	memwr			=> memwr,
	memrw			=> open,
	opfetch			=> opfetch,
	intack			=> intack,
	iorq_s			=> iorq_s,
	mreq_s			=> open,
	iord_s			=> iord_s,
	iowr_s			=> iowr_s,
	iorw_s			=> iorw_s,
	memrd_s			=> open,
	memwr_s			=> memwr_s,
	memrw_s			=> open,
	opfetch_s		=> opfetch_s);

TS05: zports
port map (
	zclk    		=> zclk,
	clk			=> clk_28mhz,
	din			=> cpu_do_bus,
	dout			=> dout_ports,
	dataout			=> ena_ports,
	a			=> cpu_a_bus,
	rst			=> reset,
	loader   		=> loader, 		-- for load ROM, SPI should be enable 
	opfetch			=> opfetch, 		-- from zsignals
	rd			=> rd,
	wr			=> wr,
	rdwr			=> rdwr,
	iorq			=> iorq,
	iorq_s			=> iorq_s,
	iord			=> iord,
	iord_s			=> iord_s,
	iowr			=> iowr,
	iowr_s			=> iowr_s,
	iorw			=> iorw,
	iorw_s			=> iorw_s,
	porthit			=> open,		-- when internal port hit occurs, this is 1, else 0; used for iorq1_n iorq2_n on zxbus
	external_port		=> open, 		-- asserts for AY and VG93 accesses
	zborder_wr  		=> zborder_wr,  
	border_wr   		=> border_wr,   
	zvpage_wr		=> zvpage_wr,   
	vpage_wr		=> vpage_wr,    
	vconf_wr		=> vconf_wr,    
	gx_offsl_wr		=> gx_offsl_wr, 
	gx_offsh_wr		=> gx_offsh_wr, 
	gy_offsl_wr		=> gy_offsl_wr, 
	gy_offsh_wr		=> gy_offsh_wr,  
	t0x_offsl_wr		=> t0x_offsl_wr, 
	t0x_offsh_wr		=> t0x_offsh_wr, 
	t0y_offsl_wr		=> t0y_offsl_wr, 
	t0y_offsh_wr		=> t0y_offsh_wr, 
	t1x_offsl_wr		=> t1x_offsl_wr, 
	t1x_offsh_wr		=> t1x_offsh_wr, 
	t1y_offsl_wr		=> t1y_offsl_wr, 
	t1y_offsh_wr		=> t1y_offsh_wr, 
	tsconf_wr		=> tsconf_wr, 
	palsel_wr		=> palsel_wr, 
	tmpage_wr		=> tmpage_wr, 
	t0gpage_wr		=> t0gpage_wr, 
	t1gpage_wr		=> t1gpage_wr, 
	sgpage_wr		=> sgpage_wr, 
	hint_beg_wr		=> hint_beg_wr, 
	vint_begl_wr		=> vint_begl_wr, 
	vint_begh_wr		=> vint_begh_wr, 
	xt_page 		=> xt_page,
	fmaddr			=> fmaddr,
	sysconf			=> sysconf,
	memconf			=> memconf,
	cacheconf     		=> cacheconf,
	fddvirt			=> open,
	--im2v_frm		=> im2v_frm,
	--im2v_lin		=> im2v_lin,
	--im2v_dma		=> im2v_dma,
	intmask			=> intmask,
	dmaport_wr		=> dmaport_wr, 		-- dmaport_wr
	dma_act			=> dma_act, 		-- from DMA (status of DMA) 
	dos			=> dos,
	vdos			=> vdos,
	vdos_on  		=> vdos_on,
	vdos_off		=> vdos_off,
	ay_bdir			=> open,
	ay_bc1			=> open,
	covox_wr		=> open,
	beeper_wr		=> open,
	rstrom			=> "11",
	tape_read		=> '1',
	ide_in			=> "0000000000000000",
	ide_out			=> open,
	ide_cs0_n		=> open,
	ide_cs1_n 		=> open,
	ide_req			=> open,
	ide_stb			=> '0',
	ide_ready		=> '0',
	ide_stall		=> open,
	keys_in			=> kb_do_bus,  		-- keys (port FE)
	mus_in			=> "00000000",		-- mouse (xxDF)
	kj_in			=> kb_joy_bus,
	vg_intrq		=> '0',
	vg_drq			=> '0',			-- from vg93 module - drq + irq read
	vg_cs_n			=> open,
	vg_wrFF			=> open,
	drive_sel		=> open,		-- disk drive selection
	sdcs_n			=> sd_cs_n_ts,   	-- to SD card
	sd_start		=> cpu_spi_req, 	-- to SPI
	sd_datain		=> cpu_spi_din,	 	-- to SPI(7 downto 0);
	sd_dataout		=> spi_dout, 		-- from SPI(7 downto 0); 
	gluclock_addr		=> gluclock_addr,
	comport_addr		=> open,
	wait_start_gluclock	=> open, 		-- begin wait from some ports
	wait_start_comport	=> open,
	wait_write		=> open,
	wait_read		=> mc146818a_do_bus,
	com_data_rx		=> uart_do_bus,
	com_status		=> '1' & uart_tx_empty & uart_tx_fifo_empty & "1000" & uart_rx_avail,
	--com_status		=> '0' & uart_tx_empty & uart_tx_fifo_empty & "0000" & '1',
	TST  			=> open,
	lock_conf 		=> '1');

TS06: zmem
port map (
	clk			=> clk_28mhz,
	c0			=> c0,
	c1 			=> c1,
	c2 			=> c2,
	c3			=> c3,
	zneg			=> zneg,
	zpos			=> zpos,
	rst			=> reset,     		-- PLL locked
	za			=> cpu_a_bus,		-- from CPU
	zd_out 			=> sdr_do_bus,		-- output to Z80 bus 8bit ==>
	zd_ena			=> open,      		-- output to Z80 bus enable
	opfetch			=> opfetch,   		-- from zsignals
	opfetch_s		=> opfetch_s, 		-- from zsignals
	mreq			=> mreq,      		-- from zsignals
	memrd 			=> memrd,     		-- from zsignals
	memwr			=> memwr,     		-- from zsignals
	memwr_s			=> memwr_s,   		-- from zsignals 
	turbo			=> turbo,
	cache_en		=> cacheconf,  		-- from zport
	memconf			=> memconf(3 downto 0),
	xt_page			=> xt_page,
	xtpage_0    		=> open,
	rompg			=> open, 		-- 32page = 512kB
	csrom			=> open,
	romoe_n			=> open,
	romwe_n			=> open,
	csvrom			=> csvrom,
	dos			=> dos,
	dos_on			=> open,
	dos_off			=> open,
	dos_change  		=> dos_change,
	vdos			=> vdos,
	pre_vdos	   	=> pre_vdos,
	vdos_on 		=> vdos_on,
	vdos_off		=> vdos_off,
	cpu_req			=> cpu_req,
	cpu_addr		=> cpu_addr_20,
	cpu_wrbsel		=> cpu_wrbsel,		-- for 16bit data
	--cpu_rddata		=> sdr_do_bus_16, 	-- RD from SDRAM (cpu_strobe=HI and clk)
	cpu_rddata		=> sdr2cpu_do_bus_16,
	cpu_next		=> cpu_next,
	cpu_strobe		=> cpu_strobe,		-- from ARBITER ACTIVE=HI 	
	cpu_latch		=> cpu_latch,
	cpu_stall		=> cpu_stall, 		-- for Zclock if HI-> STALL (ZCLK)
	loader			=> loader, 		-- ROM for loader active
	testkey			=> '1',
	intt			=> '0',
	tst			=> open);

TS07: arbiter
port map (
	clk			=> clk_28mhz,
	c0			=> c0,
	c1 			=> c1,
	c2 			=> c2,
	c3			=> c3,
	dram_addr 		=> dram_addr,
	dram_req	 	=> dram_req,
	dram_rnw	 	=> dram_rnw,
	dram_bsel 		=> dram_bsel,
	dram_wrdata 		=> dram_wrdata,		-- data to be written
	video_addr		=> "000" & video_addr,	-- during access block, only when video_strobe==1
	go			=> go_arbiter,		-- start video access blocks
	video_bw		=> video_bw, 		-- ZX="11001", [4:3] -total cycles: 11 = 8 / 01 = 4 / 00 = 2
	video_pre_next		=> video_pre_next,
	video_next		=> video_next, 		-- (c2) at this signal video_addr may be changed; it is one clock leading the video_strobe
	video_strobe		=> video_strobe, 	-- (c3) one-cycle strobe meaning that video_data is available
	video_next_strobe 	=> video_next_strobe,
	next_vid		=> next_video, 		-- used for TM prefetch
	--cpu_addr		=> cpu_addr,
	cpu_addr		=> cpu_addr_ext & cpu_addr_20,
	cpu_wrdata		=> cpu_do_bus,
	cpu_req			=> cpu_req,
	cpu_rnw			=> rd,
	cpu_wrbsel		=> cpu_wrbsel,
	cpu_next		=> cpu_next, 		-- next cycle is allowed to be used by CPU
	cpu_strobe		=> cpu_strobe, 		-- c2 strobe
	cpu_latch   		=> cpu_latch, 		-- c2-c3 strobe
	curr_cpu_o		=> curr_cpu,
	dma_addr		=> "000" & dma_addr,
	dma_wrdata		=> dma_wrdata,
	dma_req			=> dma_req,
	dma_z80_lp		=> dma_z80_lp,
	dma_rnw			=> dma_rnw,
	dma_next		=> dma_next,
	ts_addr			=> "000" & ts_addr,
	ts_req			=> ts_req,
	ts_z80_lp		=> ts_z80_lp,
	ts_pre_next		=> ts_pre_next,
	ts_next			=> ts_next,
	tm_addr			=> "000" & tm_addr,
	tm_req			=> tm_req,
	tm_next			=> tm_next,
	TST 			=> open);

TS08: video_top
port map (
	clk			=> clk_28mhz,
	f0			=> f0,
	f1 			=> f1,
	h0 			=> h0,
	h1			=> h1,
	c0			=> c0,
	c1 			=> c1,
	c2 			=> c2,
	c3			=> c3,
	vred			=> vred_ts,
	vgrn			=> vgrn_ts,
	vblu			=> vblu_ts,
	hsync			=> hsync_ts,
	vsync 			=> vsync_ts,
	csync			=> open,
	vga_blank 		=> open, 
	a 			=> cpu_a_bus,
	d			=> cpu_do_bus,
	zmd			=> zmd,
	zma			=> zma,
	cram_we			=> cram_we,
	sfile_we 		=> sfile_we,
	zborder_wr 		=> zborder_wr,
	border_wr 		=> border_wr,
	zvpage_wr 		=> zvpage_wr,
	vpage_wr 		=> vpage_wr,
	vconf_wr 		=> vconf_wr,
	gx_offsl_wr 		=> gx_offsl_wr,
	gx_offsh_wr 		=> gx_offsh_wr,
	gy_offsl_wr 		=> gy_offsl_wr,
	gy_offsh_wr	 	=> gy_offsh_wr,
	t0x_offsl_wr 		=> t0x_offsl_wr,
	t0x_offsh_wr 		=> t0x_offsh_wr,
	t0y_offsl_wr 		=> t0y_offsl_wr,
	t0y_offsh_wr 		=> t0y_offsh_wr,
	t1x_offsl_wr 		=> t1x_offsl_wr,
	t1x_offsh_wr 		=> t1x_offsh_wr,
	t1y_offsl_wr 		=> t1y_offsl_wr,
	t1y_offsh_wr 		=> t1y_offsh_wr,
	tsconf_wr	 	=> tsconf_wr,
	palsel_wr	 	=> palsel_wr,
	tmpage_wr	 	=> tmpage_wr,
	t0gpage_wr	 	=> t0gpage_wr,
	t1gpage_wr	 	=> t1gpage_wr,
	sgpage_wr	 	=> sgpage_wr,
	hint_beg_wr  		=> hint_beg_wr,
	vint_begl_wr 		=> vint_begl_wr,
	vint_begh_wr 		=> vint_begh_wr,
	res			=> reset,
	int_start		=> int_start_frm,
	line_start_s		=> int_start_lin,
	video_addr		=> video_addr,
	video_bw		=> video_bw,
	video_go		=> go,
	dram_rdata     		=> dram_rdata,  -- raw, should be latched by c2 (video_next)
	video_next		=> video_next,
	video_pre_next		=> video_pre_next, 
	next_video		=> next_video,
	video_strobe		=> video_strobe,
	video_next_strobe	=> video_next_strobe,
	ts_addr			=> ts_addr,
	ts_req			=> ts_req,
	ts_z80_lp		=> ts_z80_lp,
	ts_pre_next		=> ts_pre_next,
	ts_next			=> ts_next,
	tm_addr			=> tm_addr,
	tm_req			=> tm_req,
	tm_next			=> tm_next, 
	cfg_60hz		=> key_f(2),	-- 0-60Hz, 1-48Hz
	sync_pol		=> '1',		-- 0-positive, 1-negative
	vga_on			=> '1',         -- 1-31kHZ
	tst            		=> open);

TS09: dma
port map (
	clk 			=> clk_28mhz, 
	c2			=> c2,
	reset			=> reset,
	dmaport_wr 		=> dmaport_wr,
	dma_act 		=> dma_act,
	data 			=> dma_data,
	wraddr 			=> dma_wraddr,
	int_start		=> int_start_dma,
	zdata 			=> cpu_do_bus,
	dram_addr		=> dma_addr,
	dram_rddata		=> sdr_do_bus_16,
	dram_wrdata		=> dma_wrdata,
	dram_req		=> dma_req,
	dma_z80_lp		=> dma_z80_lp,
	dram_rnw		=> dma_rnw,
	dram_next		=> dma_next,
	spi_rddata 		=> spi_dout,
	spi_wrdata		=> dma_spi_din,
	spi_req			=> dma_spi_req,
	spi_stb			=> spi_stb,
	spi_start		=> spi_start,
	ide_in 			=> "0000000000000000",
	ide_out 		=> open,
	ide_req			=> open,
	ide_rnw			=> open,
	ide_stb			=> '0',
	cram_we			=> dma_cram_we,
	sfile_we		=> dma_sfile_we, 
	TST 			=> open);

TS10: zmaps
port map (
	clk			=> clk_28mhz,
	memwr_s			=> memwr_s,
	a			=> cpu_a_bus,
	d			=> cpu_do_bus,
	fmaddr			=> fmaddr,
	zmd			=> zmd,
	zma			=> zma,
	dma_data		=> dma_data,
	dma_wraddr 		=> dma_wraddr,
	dma_cram_we		=> dma_cram_we,
	dma_sfile_we		=> dma_sfile_we,
	cram_we			=> cram_we,
	sfile_we		=> sfile_we);

TS11: spi
port map (
	clk			=> clk_28mhz,
	sck   			=> sd_clk_ts,
	sdo			=> sd_si_ts,
	sdi			=> SD_MISO,
	stb			=> spi_stb,
	start			=> spi_start,
	bsync			=> open,
	dma_req			=> dma_spi_req,
	dma_din 		=> dma_spi_din,
	cpu_req			=> cpu_spi_req,
	cpu_din			=> cpu_spi_din,
	dout			=> spi_dout,
	speed			=> "00",
	tst 			=> open);

TS13: zint
port map (
	clk 			=> clk_28mhz,
	zclk 			=> zclk, 
	res 			=> reset,
	int_start_frm 		=> int_start_frm,	--< N1 VIDEO
	int_start_lin 		=> int_start_lin,	--< N2 VIDEO
	int_start_dma 		=> int_start_dma,	--< N3 DMA
	vdos			=> pre_vdos, 		-- vdos,--pre_vdos
	intack			=> intack, 		--< zsignals  === (intack ? im2vect : 8'hFF)));
	--im2v_frm		=> im2v_frm, 		--< ZPORT (2 downto 0); 
	--im2v_lin		=> im2v_lin, 		--< ZPORT (2 downto 0);
	--im2v_dma		=> im2v_dma, 		--< ZPORT (2 downto 0);
	intmask			=> intmask, 		--< ZPORT (7 downto 0);
	im2vect			=> im2vect, 		--> CPU Din (2 downto 0); 	
	int_n			=> cpu_int_n_TS);
	 
-- ROM
SE1: entity work.rom
port map (
	address	 		=> cpu_a_bus(12 downto 0),
	clock	 		=> clk_28mhz,
	q	 		=> rom_do_bus);

-- SDRAM Controller
SE4: entity work.sdram
port map (
	CLK		 	=> clk_84mhz,
	clk_28MHz 		=> clk_28mhz,	
	c0			=> c0,
	c1 			=> c1,
	c2 			=> c2,
	c3			=> c3,
	curr_cpu 		=> curr_cpu,  -- from arbiter for luch DO_cpu
	loader  		=> loader,    -- loader = 1: wr to ROM 
	bsel     		=> dram_bsel,
	A			=> dram_addr,
	DI			=> dram_wrdata,
	DO			=> sdr_do_bus_16,
	DO_cpu   		=> sdr2cpu_do_bus_16,
	REQ      		=> dram_req,
	RNW			=> dram_rnw,
	RFSH			=> not cpu_rfsh_n,
	RFSHREQ			=> open,
	IDLE			=> open,
	CK			=> SDRAM_CLK,
	CKE			=> SDRAM_CKE,
	RAS_n			=> SDRAM_RAS_N,
	CAS_n			=> SDRAM_CAS_N,
	WE_n			=> SDRAM_WE_N,
	BA1			=> SDRAM_BA(1),
	BA0			=> SDRAM_BA(0),
	MA			=> SDRAM_A,
	DQ			=> SDRAM_DQ,
	DQML     		=> SDRAM_DQML);

SE5: entity work.keyboard
port map(
	CLK			=> clk_28mhz,
	RESET			=> areset,
	A			=> cpu_a_bus(15 downto 8),
	KEYB			=> kb_do_bus,
	KEYF			=> kb_f_bus,
	KEYJOY			=> kb_joy_bus,
	KEYLED			=> "000",
	SCANCODE		=> key_scancode,
	PS2_KBCLK		=> KB_CLK,
	PS2_KBDAT		=> KB_DAT);

SE9: entity work.mc146818a
port map (
	RESET			=> reset,
	CLK			=> clk_28mhz,
	ENA			=> ena_0_4375mhz,
	CS			=> '1',
	KEYSCANCODE 		=> key_scancode,
	WR			=> mc146818a_wr,
	A			=> gluclock_addr(7 downto 0),
	DI			=> cpu_do_bus,
	DO			=> mc146818a_do_bus);

-- Soundrive
SE10: entity work.soundrive
port map (
	RESET			=> reset,
	CLK			=> clk_28mhz,
	CS			=> '1',
	WR_n			=> cpu_wr_n,
	A			=> cpu_a_bus(7 downto 0),
	DI			=> cpu_do_bus,
	IORQ_n			=> cpu_iorq_n,
	DOS			=> dos,
	OUTA			=> covox_a,
	OUTB			=> covox_b,
	OUTC			=> covox_c,
	OUTD			=> covox_d);
		
-- TurboSound (ay8910)
SE12: entity work.turbosound
port map (
	RESET			=> reset,
	CLK			=> clk_28mhz,
	ENA			=> ena_1_75mhz,
	A			=> cpu_a_bus,
	DI			=> cpu_do_bus,
	WR_n			=> cpu_wr_n,
	IORQ_n			=> cpu_iorq_n,
	M1_n			=> cpu_m1_n,
	SEL			=> ssg_sel,
	CN0_DO			=> ssg_cn0_bus,
	CN0_A			=> ssg_cn0_a,
	CN0_B			=> ssg_cn0_b,
	CN0_C			=> ssg_cn0_c,
	CN1_DO			=> ssg_cn1_bus,
	CN1_A			=> ssg_cn1_a,
	CN1_B			=> ssg_cn1_b,
	CN1_C			=> ssg_cn1_c);

-- SPI FLASH 25MHz Max SCK
U8: entity work.spi_flash
port map (
	RESET			=> reset,
	CLK			=> clk_28mhz,
	SCK			=> clk_21mhz,
	A			=> cpu_a_bus(0),
	DI			=> cpu_do_bus,
	DO			=> spi_do_bus,
	WR			=> spi_wr,
	BUSY			=> spi_busy,
	CS_n			=> spi_cs_n,
	SCLK			=> spi_clk,
	MOSI			=> spi_si,
	MISO			=> DATA0);

-- I2C Controller
U12: entity work.i2c
port map (
	RESET			=> reset,
	CLK			=> clk_28mhz,
	ENA			=> ena_0_4375mhz,
	A			=> cpu_a_bus(4),
	DI			=> cpu_do_bus,
	DO			=> i2c_do_bus,
	WR			=> i2c_wr,
	I2C_SCL			=> SCL,
	I2C_SDA			=> SDA);

-- Z-Controller
SE8: entity work.zcontroller
port map (
	RESET			=> reset,
	CLK			=> clk_28mhz,
	A			=> cpu_a_bus(5),
	DI			=> cpu_do_bus,
	DO			=> zc_do_bus,
	RD			=> zc_rd,
	WR			=> zc_wr,
	SDDET			=> '0',
	SDPROT			=> '0',
	CS_n			=> zc_cs_n,
	SCLK			=> zc_clk,
	MOSI			=> zc_mosi,
	MISO			=> SD_MISO);

-- TDA1543 I2S Controller
U10: entity work.tda1543
--U10: entity work.tda1543a
port map (
	RESET			=> areset,
	CS			=> not port_xx01_reg(0),
	CLK			=> clk_codec,
	DATA_L			=> audio_l,
	DATA_R			=> audio_r,
	BCK			=> DAC_BCK,
	WS			=> dac_ws,
	DATA			=> dac_data);

-- PS/2 Mouse Controller
U5: entity work.mouse
generic map (
	-- This allows the use of the scroll-wheel on mice that have them.
	intelliMouseSupport => true,	-- Enable support for intelli-mouse mode.
	clockFilter 		=> 15,		-- Number of system-cycles used for PS/2 clock filtering
	ticksPerUsec		=> 28)		-- Timer calibration 28Mhz clock
port map (
	clk			=> clk_28mhz,
	reset			=> reset,
	ps2_clk			=> MS_CLK,
	ps2_dat		 	=> MS_DAT,
	mousePresent 		=> ms_present,
	leftButton 		=> ms_but_bus(1),
	middleButton 		=> ms_but_bus(2),
	rightButton 		=> ms_but_bus(0),
	X 			=> ms_x_bus,
	Y 			=> ms_y_bus,
	Z			=> ms_but_bus(7 downto 4));

-- General Sound
U15: entity work.gs
port map (
	RESET			=> not port_xx01_reg(1) or reset,
	CLK			=> clk_28mhz,
	CLKGS			=> clk_21mhz,
	A			=> cpu_a_bus,
	DI			=> cpu_do_bus,
	DO			=> gs_do_bus,
	WR_n			=> cpu_wr_n,
	RD_n			=> cpu_rd_n,
	IORQ_n			=> cpu_iorq_n,
	M1_n			=> cpu_m1_n,
	OUTA			=> gs_a,
	OUTB			=> gs_b,
	OUTC			=> gs_c,
	OUTD			=> gs_d,
	MA			=> gs_ma,
	MDI			=> SRAM_D,
	MDO			=> gs_mdo,
	MWE_n			=> gs_mwe_n);

-- UART
SE7: entity work.uart
generic map (
	-- divisor = 28MHz / 115200 Baud = 243
	divisor	=> 243)   --/38400 Baud --729  == 9600: 2916(7)
port map (
	CLK			=> clk_28mhz,
	RESET			=> reset, 
	RD			=> uart_rd,
	WR			=> uart_wr and not uart_LCR(7),
	DI			=> cpu_do_bus,
	DO			=> uart_do_bus, 
	TX_EMPTY	     	=> uart_tx_empty, 
	TX_FIFO_EMPTY		=> uart_tx_fifo_empty,
	RXAVAIL			=> uart_rx_avail,
	RXERROR			=> open, --uart_rx_error,
	RXD			=> RXD,
	TXD			=> TXD);

-------------------------------------------------------------------------------
-- Global
-------------------------------------------------------------------------------
areset <= not RESET_N;
reset <= areset or not locked or (kb_f_bus(0));
go_arbiter <= go;

process (clk_28mhz)
begin
	if clk_28mhz' event and clk_28mhz = '0' then
		ena_cnt <= ena_cnt + 1;
		ena_1_75mhz <= not ena_cnt(3) and ena_cnt(2) and ena_cnt(1) and ena_cnt(0);
		ena_0_4375mhz <= not ena_cnt(5) and ena_cnt(4) and ena_cnt(3) and ena_cnt(2) and ena_cnt(1) and ena_cnt(0);
	end if;
end process;

-- CPU interface
cpu_addr_ext <= "100" when (loader = '1' and cpu_a_bus(15 downto 14) = "11") else csvrom & "00"; --- ROM csrom (only for BANK0)
dram_rdata <= sdr_do_bus_16;

cpu_di_bus <=	rom_do_bus when (loader = '1' and cpu_mreq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(15 downto 14) = "00") else
		sdr_do_bus when (cpu_mreq_n = '0' and cpu_rd_n = '0') else 	-- SDRAM
		im2vect	when intack = '1' else
		zc_do_bus when (loader = '1' and cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(7 downto 6) = "01" and cpu_a_bus(4 downto 0) = "10111") else 
		spi_do_bus when (loader = '1' and cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 0) = X"02") else
		spi_busy & "1111111" when (loader = '1' and cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 0) = X"03") else
		mc146818a_do_bus when (cpu_iorq_n = '0' and cpu_rd_n = '0' and port_bff7 = '1' and port_eff7_reg(7) = '1') else -- MC146818A
		gs_do_bus when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 4) = "1011" and cpu_a_bus(2 downto 0) = "011") else -- General Sound
		ssg_cn0_bus when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(15 downto 0) = "1111111111111101" and ssg_sel = '0') else -- TurboSound
		ssg_cn1_bus when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(15 downto 0) = "1111111111111101" and ssg_sel = '1') else
		i2c_do_bus when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus( 7 downto 5) = "100" and cpu_a_bus(3 downto 0) = "1100") else -- RTC
		ms_but_bus(7 downto 4) & '1' & not(ms_but_bus(2) & ms_but_bus(0) & ms_but_bus(1)) when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(15 downto 0) = X"FADF" and ms_present = '1' and ms_left = '0') else 	-- Mouse Port FADF[11111010_11011111] = <Z>1<MB><LB><RB>
		ms_but_bus(7 downto 4) & '1' & not(ms_but_bus(2) & ms_but_bus(1) & ms_but_bus(0)) when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(15 downto 0) = X"FADF" and ms_present = '1' and ms_left = '1') else
		ms_x_bus when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(15 downto 0) = X"FBDF" and ms_present = '1') else -- Port FBDF[11111011_11011111] = <X>
		ms_y_bus when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(15 downto 0) = X"FFDF" and ms_present = '1') else -- Port FFDF[11111111_11011111] = <Y>
		key_scancode when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus = X"0001") else
		dout_ports when ena_ports = '1' else
		"11111111";

process (areset, clk_28mhz, cpu_a_bus, cpu_mreq_n, cpu_wr_n, cpu_do_bus, port_xx01_reg)
begin
	if areset = '1' then
		port_xx01_reg <= "00000000";	-- bit2 = 0:Loader ON, 1:Loader OFF
		loader <= '1';
	elsif clk_28mhz'event and clk_28mhz = '1' then
		if cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(7 downto 0) = "00000001" then port_xx01_reg <= cpu_do_bus; end if;
		if cpu_m1_n = '0' and cpu_mreq_n = '0' and cpu_a_bus = X"0000" and port_xx01_reg(2) = '1' then loader <= '0'; end if;
	end if;
end process;

process (reset, clk_28mhz)
begin
	if reset = '1' then
		port_xxfe_reg <= "00000000";
		port_eff7_reg <= "00000000";
	elsif clk_28mhz'event and clk_28mhz = '1' then
		if cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(7 downto 0) = "11111110" then port_xxfe_reg <= cpu_do_bus; end if;
		if cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus = "1110111111110111" then port_eff7_reg <= cpu_do_bus; end if; --for RTC
	end if;	
end process;
				
-- TURBO
turbo <= "11" when loader = '1' else sysconf(1 downto 0); 

-- Fx Keys
process (clk_28mhz, key, kb_f_bus, key_f)
begin
	if (clk_28mhz'event and clk_28mhz = '1') then
		key <= kb_f_bus;
		if (kb_f_bus /= key) then
			key_f <= key_f xor key;
		end if;
	end if;
end process;

-- RTC
mc146818a_wr <= '1' when (port_bff7 = '1' and cpu_wr_n = '0') else '0';
--mc146818a_rd <= '1' when (port_bff7 = '1' and cpu_rd_n = '0') else '0';
port_bff7 <= '1' when (cpu_iorq_n = '0' and cpu_a_bus = X"BFF7" and cpu_m1_n = '1' and port_eff7_reg(7) = '1') else '0';

-- SPI
spi_wr <= '1' when (cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(7 downto 1) = "0000001") else '0';

-- I2C
i2c_wr <= '1' when (cpu_a_bus(7 downto 5) = "100" and cpu_a_bus(3 downto 0) = "1100" and cpu_wr_n = '0' and cpu_iorq_n = '0') else '0';	-- Port xx8C/xx9C[xxxxxxxx_100n1100]

-- Audio mixer
audio_l <= ("0000" & port_xxfe_reg(4) & "0000000000") + ("0000" & ssg_cn0_a & "000") + ("0000" & ssg_cn0_b & "000") + ("0000" & ssg_cn1_a & "000") + ("0000" & ssg_cn1_b & "000") + ("0000" & covox_a & "000") + ("0000" & covox_b & "000") + ("00" & gs_a) + ("00" & gs_b);
audio_r <= ("0000" & port_xxfe_reg(4) & "0000000000") + ("0000" & ssg_cn0_c & "000") + ("0000" & ssg_cn0_b & "000") + ("0000" & ssg_cn1_c & "000") + ("0000" & ssg_cn1_b & "000") + ("0000" & covox_c & "000") + ("0000" & covox_d & "000") + ("00" & gs_c) + ("00" & gs_d);

-- VGA
R <= vred_ts;
G <= vgrn_ts;
B <= vblu_ts;

HS <= hsync_ts;
VS <= vsync_ts;

-- Z-Controller
zc_wr <= '1' when (cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(7 downto 6) = "01" and cpu_a_bus(4 downto 0) = "10111") else '0';
zc_rd <= '1' when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(7 downto 6) = "01" and cpu_a_bus(4 downto 0) = "10111") else '0';

-- SD/MMC Z-Controller/SD TS
SD_MOSI <= sd_si_ts when loader = '0' else zc_mosi;
SD_CLK <= sd_clk_ts when loader = '0' else zc_clk;
SD_CS_N <= sd_cs_n_ts when loader = '0' else zc_cs_n;

-- TDA1543 <> MP25P40
process (port_xx01_reg, spi_si, spi_clk, spi_cs_n, dac_data, dac_ws)
begin
	if port_xx01_reg(0) = '0' then
		ASDO <= dac_data;
		DCLK <= dac_ws;
		NCSO <= '1';
	else
		ASDO <= spi_si;
		DCLK <= spi_clk;
		NCSO <= spi_cs_n;
	end if;
end process;

-- Mouse
ms_left <= not(ms_left) when (ms_but_bus(1)'event and ms_but_bus(1) = '1' and ms_but_bus(0) = '1');

-- SRAM <- GS/SYS
process (cpu_a_bus, port_xx01_reg, cpu_mreq_n, cpu_wr_n, cpu_do_bus, gs_mwe_n, gs_mdo, gs_ma)
begin
	if port_xx01_reg(1) = '0' then
		if cpu_mreq_n = '0' and cpu_wr_n = '0' then
			SRAM_D <= cpu_do_bus;
		else
			SRAM_D <= (others => 'Z');
		end if;
		SRAM_A <= "0000" & cpu_a_bus(14 downto 0);
		SRAM_WE_n <= cpu_mreq_n or cpu_wr_n or not cpu_a_bus(15);
	else
		if gs_mwe_n = '0' then
			SRAM_D <= gs_mdo;
		else
			SRAM_D <= (others => 'Z');
		end if;
		SRAM_A <= gs_ma;
		SRAM_WE_n <= gs_mwe_n;
	end if;
end process;

SRAM_OE_n	<= '0';

-- UART
uart_wr <= '1' when (cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(15 downto 0) = X"F8EF") else '0';	
uart_rd <= '1' when (cpu_iorq_n = '0' and cpu_rd_n = '0' and cpu_a_bus(15 downto 0) = X"F8EF") else '0';	
uart_LCR_wr <= '1' when (cpu_iorq_n = '0' and cpu_wr_n = '0' and cpu_a_bus(15 downto 0) = X"FBEF") else '0'; 

process (clk_28mhz, uart_LCR_wr, reset)
begin
	if (reset = '1') then
		uart_LCR <= X"00" ;
	elsif clk_28mhz'event and clk_28mhz = '1' then
		if (uart_LCR_wr = '1') then
			uart_LCR <= cpu_do_bus;
		end if;
	end if;
end process;



end rtl;