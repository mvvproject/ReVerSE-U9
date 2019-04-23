-----------------------------------------------------------------[Rev.20120410]
-- VECTOR-06C Version 0.02
-------------------------------------------------------------------------------
-- Version 0.01	Adaptation for DevBoard Reverse - U9EP3C By MVV
-- Version 0.02	

-- Copyright (c) 2007-2009 Viacheslav Slavinsky
-- Copyright (c) 2012 MVV
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
-- * License is granted for non-commercial use only. A fee may not be charged
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
use IEEE.numeric_std.ALL; 

-- M9K 46K:
-- 0000-B7FF

-- SRAM 512K:
-- 00000-7FFFF

-- SDRAM 32M:
-- 0000000-1FFFFFF

-- FLASH 512K:
-- 00000-5FFFF		Конфигурация Cyclone EP3C10
-- 60000-7FFFF

-- DevBoard ReVerSE - U9EP3C
entity vector06cc is
port (
	-- Clock (50MHz)
	CLK			: in std_logic;
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
	-- VGA RGB(3:3:3)
	VGA_R		: out std_logic_vector(2 downto 0);
	VGA_G		: out std_logic_vector(2 downto 0);
	VGA_B		: out std_logic_vector(2 downto 0);
	VGA_VS		: out std_logic;
	VGA_HS		: out std_logic;
	-- External I/O
	RST_n		: in std_logic;
	GPI			: in std_logic;
	-- PS/2 Keyboard
	PS2_KBCLK	: inout std_logic;
	PS2_KBDAT	: inout std_logic;
	-- PS/2 Mouse
	PS2_MSCLK	: inout std_logic;
	PS2_MSDAT	: inout std_logic;
	-- USB-UART (FT232RL)
	UART_TXD	: in std_logic;
	UART_RXD	: out std_logic;
	CBUS4		: in std_logic;
	-- SD/MMC Card
	SD_CLK		: out std_logic;	-- SCK
	SD_DAT0		: in std_logic;		-- MISO
	SD_DAT1		: in std_logic;
	SD_DAT2		: in std_logic;
	SD_DAT3		: out std_logic;	-- CSn
	SD_CMD		: out std_logic;	-- MOSI
	SD_DETECT	: in std_logic;
	SD_PROT		: in std_logic);		
end vector06cc;

architecture rtl of vector06cc is
    
    signal GPIO_0                     : std_logic_vector(12 downto 0);
    signal GPIO_1                     : std_logic_vector(35 downto 0);
    
    -- CLOCK SETUP
    signal mreset_n                   : std_logic;
    signal mreset                     : std_logic;
    signal clk24                      : std_logic;
    signal clk14                      : std_logic;
    signal clkpal4FSC                 : std_logic;
    signal ce12                       : std_logic;
    signal ce6                        : std_logic;
    signal ce6x                       : std_logic;
    signal ce3                        : std_logic;
    signal vi53_timer_ce              : std_logic;
    signal video_slice                : std_logic;
    signal pipe_ab                    : std_logic;
    signal clkdac						: std_logic;
    signal tape_input                 : std_logic;
    signal out_L                      : std_logic_vector(15 downto 0);
    signal out_R                      : std_logic_vector(15 downto 0);

    signal ctr                      : std_logic_vector(5 downto 0);
    signal daccs                      : std_logic;
    
    -----------------------------------------
    signal slowclock                  : std_logic_vector(15 downto 0);
    signal SW                         : std_logic_vector(9 downto 0);
    
    signal breakpoint_condition       : std_logic;
    
    signal slowclock_enabled          : std_logic;
    signal singleclock_enabled        : std_logic;
    signal warpclock_enabled          : std_logic;
    
    signal regular_clock_enabled      : std_logic;
    signal singleclock                : std_logic;
    
    signal cpu_ce                     : std_logic;
    
    signal clock_counter              : std_logic_vector(15 downto 0);
    
    -- WAIT STATES
    -- a very special waitstate generator
    signal ws_counter                 : std_logic_vector(4 downto 0) := "00000";
    signal ws_latch                   : std_logic;
    
    signal ws_rom                     : std_logic_vector(3 downto 0);
    signal ws_cpu_time                : std_logic;
    signal ws_req_n                   : std_logic;		-- 0 when cpu wants cock
    
    -- if this is not a cpu slice (ws_rom[2]) and cpu wants access, latch the ws flag
    -- reset the latch when it's time
    
    -- CPU SECTION
    signal READY                      : std_logic;
    signal HOLD                       : std_logic;
    signal INT                        : std_logic;
    signal INTE                       : std_logic;
    signal DBIN                       : std_logic;
    signal SYNC                       : std_logic;
    signal VAIT                       : std_logic;
    signal HLDA                       : std_logic;
    signal WR_n                       : std_logic;
    
    signal VIDEO_A                    : std_logic_vector(15 downto 0);
    signal A                          : std_logic_vector(15 downto 0);
    signal DI                         : std_logic_vector(7 downto 0);
    signal DO                         : std_logic_vector(7 downto 0);
    
    signal status_word                : std_logic_vector(7 downto 0);
    signal gledreg                    : std_logic_vector(9 downto 0);
    signal kbd_keystatus              : std_logic_vector(7 downto 0);
 
    signal address_bus				  : std_logic_vector(7 downto 0);   
    signal ram_read                   : std_logic;
    signal ram_write_n                : std_logic;
    signal io_write                   : std_logic;
    signal io_stack                   : std_logic;
    signal io_read                    : std_logic;
    signal interrupt_ack              : std_logic;
    signal halt_ack                   : std_logic;
    signal WRN_CPUCE                  : std_logic;
    
    -- MEMORIES
    signal ROM_DO                     : std_logic_vector(7 downto 0);
    signal address_bus_r              : std_logic_vector(7 downto 0);		-- registered address for i/o
    signal sram_data_in               : std_logic_vector(7 downto 0);
    signal ramdisk_page               : std_logic_vector(2 downto 0);
    signal kvaz_debug                 : std_logic_vector(7 downto 0);
    signal ramdisk_control_write      : std_logic;
    
    -- VIDEO //
    signal video_scroll_reg           : std_logic_vector(7 downto 0);
    signal video_palette_value        : std_logic_vector(7 downto 0);
    signal video_border_index         : std_logic_vector(3 downto 0);
    signal video_palette_wren         : std_logic;
    signal video_mode512              : std_logic;
    signal coloridx                   : std_logic_vector(3 downto 0);
    signal retrace                    : std_logic;
    signal tv_mode                    : std_logic_vector(1 downto 0);
    signal tv_sync                    : std_logic;
    signal tv_luma                    : std_logic_vector(7 downto 0);
    signal tv_chroma                  : std_logic_vector(7 downto 0);
    signal tv_test                    : std_logic_vector(7 downto 0);
 
    -- On-Screen Display
    signal osd_hsync                  : std_logic;
    signal osd_vsync                  : std_logic;
    signal osd_fg                     : std_logic;
    signal osd_bg                     : std_logic;
    signal osd_active                 : std_logic;
    signal osd_command                : std_logic_vector(7 downto 0);
    signal osd_command_f12            : std_logic;
    signal osd_address                : std_logic_vector(7 downto 0);
    signal osd_data                   : std_logic_vector(7 downto 0);
    signal osd_wren                   : std_logic;
    signal osd_q                      : std_logic;
    signal osd_colour                 : std_logic_vector(7 downto 0);
    signal osd_rq                     : std_logic_vector(7 downto 0);
    signal osd_command_bushold        : std_logic;

    signal realcolor2buf              : std_logic_vector(7 downto 0);
    signal realcolor                  : std_logic_vector(7 downto 0);
    -- slightly greenish tint hopefully
    signal paletteram_adr             : std_logic_vector(3 downto 0);
    signal video_palette_wren_delayed : std_logic;
    signal video_r                    : std_logic_vector(2 downto 0);
    signal video_g                    : std_logic_vector(2 downto 0);
    signal video_b                    : std_logic_vector(2 downto 0);

    signal lowcolor_b                 : std_logic_vector(1 downto 0);
    signal lowcolor_g                 : std_logic;
    signal lowcolor_r                 : std_logic;
    signal overlayed_colour           : std_logic_vector(7 downto 0);

    signal int_delay                  : std_logic;
    signal int_request                : std_logic;
    signal int_rq_tick                : std_logic;
    signal int_rq_hist                : std_logic;

    signal kbd_mod_rus                : std_logic;
    signal kbd_rowselect              : std_logic_vector(7 downto 0);
    signal kbd_rowbits                : std_logic_vector(7 downto 0);
    signal kbd_key_shift              : std_logic;
    signal kbd_key_ctrl               : std_logic;
    signal kbd_key_rus                : std_logic;
    signal kbd_key_blksbr             : std_logic;
    signal kbd_key_blkvvod_phy        : std_logic;
    signal kbd_key_scrolllock         : std_logic;
    signal kbd_keys_osd               : std_logic_vector(5 downto 0);
    
    signal scrollock_osd              : std_logic;
    signal peripheral_data_in         : std_logic_vector(7 downto 0);
    signal portmap_device             : std_logic_vector(5 downto 0);
    signal vv55int_sel                : std_logic;
    signal vv55int_addr               : std_logic_vector(1 downto 0);
    signal vv55int_idata              : std_logic_vector(7 downto 0);
    signal vv55int_odata              : std_logic_vector(7 downto 0);
    signal vv55int_oe_n               : std_logic;
    signal vv55int_cs_n               : std_logic;
    signal vv55int_rd_n               : std_logic;
    signal vv55int_wr_n               : std_logic;
    signal vv55int_pa_in              : std_logic_vector(7 downto 0);
    signal vv55int_pb_in              : std_logic_vector(7 downto 0);
    signal vv55int_pc_in              : std_logic_vector(7 downto 0);
    signal vv55int_pa_out             : std_logic_vector(7 downto 0);
    signal vv55int_pb_out             : std_logic_vector(7 downto 0);
    signal vv55int_pc_out             : std_logic_vector(7 downto 0);
    signal vv55int_pa_oe_n            : std_logic_vector(7 downto 0);
    signal vv55int_pb_oe_n            : std_logic_vector(7 downto 0);
    signal vv55int_pc_oe_n            : std_logic_vector(7 downto 0);
    signal vv55pu_sel                 : std_logic;
    signal vv55pu_addr                : std_logic_vector(1 downto 0);
    signal vv55pu_idata               : std_logic_vector(7 downto 0);
    signal vv55pu_odata               : std_logic_vector(7 downto 0);
    signal vv55pu_wren                : std_logic;
    signal vi53_sel                   : std_logic;
    signal vi53_wren                  : std_logic;
    signal vi53_out                   : std_logic_vector(2 downto 0);
    signal vi53_odata                 : std_logic_vector(7 downto 0);
    signal vi53_testpin               : std_logic_vector(9 downto 0);
    signal iports_sel                 : std_logic;
    signal iports_write               : std_logic;
    signal iports_palette_sel         : std_logic;
    signal palette_wr_sim             : std_logic_vector(3 downto 0);
    signal video_palette_wren_buf     : std_logic_vector(7 downto 0);

    signal floppy_leds                : std_logic_vector(7 downto 0);
    signal floppy_sel                 : std_logic;
    signal floppy_wren                : std_logic;
    signal floppy_death_by_floppy     : std_logic;
    signal floppy_odata               : std_logic_vector(7 downto 0);
    signal floppy_status              : std_logic_vector(7 downto 0);

    signal ay_odata                   : std_logic_vector(7 downto 0);
    signal ay_sel                     : std_logic;
    signal ay_wren                    : std_logic;
    signal aycectr                    : std_logic_vector(2 downto 0);

    signal KEY	 	                  : std_logic_vector(3 downto 0);
    signal RESET_n	 	                  : std_logic;

    signal blksbr_reset_pulse         : std_logic;
    signal disable_rom                : std_logic;
    signal kbd_key_blkvvod			  : std_logic;
    signal rom_access				: std_logic;
    signal jHOLD                      : std_logic;
    -- X-HDL generated signals
    signal xhdl9 : std_logic;
    signal xhdl10 : std_logic_vector(1 downto 0);
    signal xhdl11 : std_logic_vector(2 downto 0);
    signal xhdl12 : std_logic_vector(2 downto 0);
    signal xhdl13 : std_logic_vector(2 downto 0);
    signal xhdl14 : std_logic_vector(2 downto 0);
    signal xhdl15 : std_logic_vector(2 downto 0);
    signal xhdl16 : std_logic;
    signal xhdl17 : std_logic;
    signal xhdl18 : std_logic;
    signal xhdl19 : std_logic;
    signal xhdl20 : std_logic_vector(4 downto 0);
    signal xhdl21 : std_logic_vector(1 downto 0);
    signal xhdl22 : std_logic_vector(2 downto 0);
    signal xhdl23 : std_logic_vector(7 downto 0);
    signal xhdl24 : std_logic_vector(7 downto 0);
    signal xhdl25 : std_logic_vector(2 downto 0);
    signal xhdl26 : std_logic;
    signal xhdl27 : std_logic;
    signal xhdl28 : std_logic;   

    -- Declare intermediate signals for referenced outputs
    signal SRAM_A_xhdl6            : std_logic_vector(18 downto 0);
    signal SRAM_WE_N_xhdl7            : std_logic;
    signal DAC_BCK_xhdl1              : std_logic;
    signal DCLK_xhdl2                 : std_logic;
    signal ASDO_xhdl0                 : std_logic;
    signal SD_DAT3_xhdl5              : std_logic;
    signal SD_CMD_xhdl4               : std_logic;
    signal SD_CLK_xhdl3               : std_logic;
    signal UART_RXD_xhdl8             : std_logic;
begin
    -- Drive referenced outputs
    DAC_BCK <= DAC_BCK_xhdl1;
    DCLK <= DCLK_xhdl2;
    ASDO <= ASDO_xhdl0;
    SD_DAT3 <= SD_DAT3_xhdl5;
    SD_CMD <= SD_CMD_xhdl4;
    SD_CLK <= SD_CLK_xhdl3;
    UART_RXD <= UART_RXD_xhdl8;
    mreset_n <= KEY(0) and not(kbd_key_blkvvod);
    mreset <= not(mreset_n);
 
-- PLL
U0: entity work.altpll0
port map (
	inclk0	=> CLK,
	c0		=> clk24,
	c1		=> clk14,
	c2		=> clkdac);

process (clk24)
begin
	if clk24'event and clk24 = '1' then
		pipe_ab <= ctr(5); 				-- pipe a/b 2x slower
		ce12 <= ctr(0); 					-- pixel push @12mhz
		ce6 <= ctr(1) and ctr(0);			-- pixel push @6mhz
		ce6x <= ctr(1) and not ctr(0);     -- pre-pixel push @6mhz
		ce3 <= ctr(2) and ctr(1) and not ctr(0);
		video_slice <= not ctr(2);
--		ce1m5 <= not ctr(3) and ctr(2) and ctr(1) and not ctr(0); 
		ctr <= ctr + 1;
	end if;
end process;

clkpal4FSC <= '1';

    daccs <= '1';
    
    
    xhdl9 <= not(mreset_n);
    i2s : entity work.tda1543
        port map (
            reset   => xhdl9,
            clk     => clkdac,
            cs      => daccs,
            data_l  => out_L,
            data_r  => out_R,
            bck     => DAC_BCK_xhdl1,
            ws      => DCLK_xhdl2,
            data    => ASDO_xhdl0
        );
    KEY <= "1111";
    SW <= "1100000000";
    process (clk24)
    begin
        if (clk24'event and clk24 = '1') then
            if (ce3 = '1') then
                slowclock <= slowclock + "0000000000000001";
            end if;
        end if;
    end process;
    
    xhdl10 <= SW(9) & SW(8);
    xhdl11 <= "100";
    xhdl12 <= "000";
    xhdl13 <= "001";
    xhdl14 <= "010";
    process (clk24)
    begin
        if (clk24'event and clk24 = '1') then
            case xhdl10 is
                when "00" =>
                    (singleclock_enabled, slowclock_enabled, warpclock_enabled) <= xhdl11;
                when "11" =>
                    (singleclock_enabled, slowclock_enabled, warpclock_enabled) <= xhdl12;
                when "01" =>
                    (singleclock_enabled, slowclock_enabled, warpclock_enabled) <= xhdl13;
                when "10" =>
                    (singleclock_enabled, slowclock_enabled, warpclock_enabled) <= xhdl14;
                when others =>
                    null;
            end case;
        end if;
    end process;
    
    regular_clock_enabled <= not(slowclock_enabled) and not(singleclock_enabled) and not(breakpoint_condition);
    
    
    keytapclock : entity work.singleclockster
        port map (
            clk24,
            singleclock_enabled,
            KEY(1),
            singleclock
        );
    xhdl15 <= singleclock_enabled & slowclock_enabled & warpclock_enabled;

	xhdl28 <= '1' when slowclock = "0000000000000000" else '0';

    process (singleclock_enabled, slowclock_enabled, warpclock_enabled, singleclock, slowclock, ce3, ce12, video_slice)
    begin
        case xhdl15 is
            when "1XX" =>
                cpu_ce <= singleclock;
            when "X1X" =>
                cpu_ce <= xhdl28 and ce3;
            when "XX1" =>
                cpu_ce <= ce12 and not(video_slice);
            when "000" =>
                cpu_ce <= ce3;
            when others =>
                null;
        end case;
    end process;
    
    process (clk24)
    begin
        if (clk24'event and clk24 = '1') then
            if ((not(RESET_n)) = '1') then
                clock_counter <= "0000000000000000";
            elsif ((cpu_ce and not(halt_ack)) = '1') then
                clock_counter <= clock_counter + "0000000000000001";
            end if;
        end if;
    end process;
    
    process (clk24)
    begin
        if (clk24'event and clk24 = '1') then
            ws_counter <= ws_counter + "00001";
        end if;
    end process;
    
    ws_rom <= ws_counter(4 downto 1);
	ws_cpu_time <= '1' when ws_rom(3 downto 1) = "101" else '0';
    ws_req_n <= not((DO(7) or not(DO(1)))) or DO(4) or DO(6);
    process (clk24)
    begin
        if (clk24'event and clk24 = '1') then
            if (cpu_ce = '1') then
                if ((SYNC and not(warpclock_enabled)) = '1') then
                    if ((not(ws_req_n) and not(ws_cpu_time)) = '1') then
                        READY <= '0';
                    end if;
                    breakpoint_condition <= '0';
                end if;
            end if;
            if (ws_cpu_time = '1') then
                READY <= '1';
            end if;
        end if;
    end process;
    
    RESET_n <= mreset_n and not(blksbr_reset_pulse);
    HOLD <= jHOLD or SW(7) or osd_command_bushold or floppy_death_by_floppy;
    INT <= int_request;
    kbd_keystatus <= ("000" & (kbd_mod_rus & kbd_key_shift & kbd_key_ctrl & kbd_key_rus & kbd_key_blksbr));
    WRN_CPUCE <= WR_n or not(cpu_ce);
    
    
    CPU : entity work.T8080se
        port map (
            RESET_n,
            clk24,
            cpu_ce,
            READY,
            HOLD,
            INT,
            INTE,
            DBIN,
            SYNC,
            VAIT,
            HLDA,
            WR_n,
            A,
            DI,
            DO
        );
    ram_read <= status_word(7);
    ram_write_n <= status_word(1);
    io_write <= status_word(4);
    io_stack <= status_word(2);
    io_read <= status_word(6);
    halt_ack <= status_word(3);
    interrupt_ack <= status_word(0);
    process (clk24)
    begin
        if (clk24'event and clk24 = '1') then
            if (cpu_ce = '1') then
                if (WR_n = '0') then
                    gledreg(7 downto 0) <= DO;
                end if;
                if (SYNC = '1') then
                    status_word <= DO;
                end if;
                address_bus_r <= address_bus(7 downto 0);
            end if;
        end if;
    end process;
    
    
    
    bootrom : entity work.lpm_rom0
        port map (
            A(11 downto 0),
            clk24,
            ROM_DO
        );

    address_bus <= VIDEO_A when (video_slice = '1' and regular_clock_enabled = '1') else A;
    rom_access <= '1' when A < "0000100000000000" and disable_rom = '1' else '0';




    DI <= "11111111" when (interrupt_ack = '1') else
          peripheral_data_in when (io_read = '1') else
          ROM_DO when (rom_access = '1') else
          sram_data_in;
    
    
	SRAM_A <= "000" & address_bus(15 downto 0) when video_slice = '1' else ramdisk_page & address_bus(15 downto 0);
	xhdl16 <= WRN_CPUCE or ram_write_n or io_write;
	SRAM_WE_n <= xhdl16;
	SRAM_OE_n <= rom_access and ram_write_n and video_slice;

	SRAM_D <= DO when xhdl16 = '0' else "ZZZZZZZZ";
    ramdisk_control_write <= '1' when address_bus_r = "00010000" and io_write = '1' and WR_n = '1' else '0';
    
    
    xhdl17 <= not(ram_write_n);
    ramdisk : entity work.kvaz
        port map (
            clk          => clk24,
            clke         => cpu_ce,
            reset        => mreset,
            address      => address_bus,
            sel		     => ramdisk_control_write,
            data_in      => DO,
            stack        => io_stack,
            memwr        => xhdl17,
            memrd        => ram_read,
            bigram_addr  => ramdisk_page,
            debug        => kvaz_debug
        );
    video_scroll_reg <= vv55int_pa_out;
    tv_mode <= (SW(4) & SW(5));
    
    
    vidi : entity work.video
        port map (
            clk24             => clk24,
            ce12              => ce12,
            ce6               => ce6,
            ce6x              => ce6x,
            clk4fsc           => clkpal4FSC,
            video_slice       => video_slice,
            pipe_ab           => pipe_ab,
            mode512           => video_mode512,
            sram_dq           => sram_data_in,
            sram_addr         => VIDEO_A,
            hsync             => vga_hs,
            vsync             => vga_vs,
            osd_hsync         => osd_hsync,
            osd_vsync         => osd_vsync,
            coloridx          => coloridx,
            realcolor_in      => realcolor2buf,
            realcolor_out     => realcolor,
            retrace           => retrace,
            video_scroll_reg  => video_scroll_reg,
            border_idx        => video_border_index,
            tv_sync           => tv_sync,
            tv_luma           => tv_luma,
            tv_chroma         => tv_chroma,
            tv_test           => tv_test,
            tv_mode           => tv_mode,
            tv_osd_fg         => osd_fg,
            tv_osd_bg         => osd_bg,
            tv_osd_on         => osd_active
        );
    paletteram_adr <= video_border_index when (retrace = '1') else
                      coloridx;
    
    
    paletteram : entity work.palette_ram
        port map (
            address   => paletteram_adr,
            data      => video_palette_value,
            inclock   => clk24,
            outclock  => clk24,
            wren      => video_palette_wren_delayed,
            q         => realcolor2buf
        );
    VGA_R <= tv_luma(3 downto 0)(2 downto 0) when ((tv_mode(0)) = '1') else
             video_r;
    VGA_G <= tv_luma(3 downto 0)(2 downto 0) when ((tv_mode(0)) = '1') else
             video_g;
    VGA_B <= tv_luma(3 downto 0)(2 downto 0) when ((tv_mode(0)) = '1') else
             video_b;
    VGA_VS <= vga_vs;
    VGA_HS <= vga_hs;
    lowcolor_b <= osd_active & osd_active and (realcolor(7) & '0');
    lowcolor_g <= osd_active and realcolor(5);
    lowcolor_r <= osd_active and realcolor(2);
    overlayed_colour <= osd_colour when (osd_active = '1') else
                        realcolor;
    process (clk24)
    begin
        if (clk24'event and clk24 = '1') then
            video_r <= (overlayed_colour(2 downto 1) & lowcolor_r);
            video_g <= (overlayed_colour(5 downto 4) & lowcolor_g);
            video_b <= (overlayed_colour(7 downto 6) & lowcolor_b);
        end if;
    end process;
    
    
    
    retrace_delay : entity work.oneshot
        generic map (
            "0000011100"
        )
        port map (
            clk24,
            cpu_ce,
            retrace,
            int_delay
        );
    
    
    xhdl18 <= not(int_delay);
    retrace_irq : entity work.oneshot
        generic map (
            "0010111111"
        )
        port map (
            clk24,
            cpu_ce,
            xhdl18,
            int_rq_tick
        );
    process (clk24)
    begin
        if (clk24'event and clk24 = '1') then
            int_rq_hist <= int_rq_tick;
            if ((not(int_rq_hist) and int_rq_tick and INTE) = '1') then
                int_request <= '1';
            end if;
            if (interrupt_ack = '1') then
                int_request <= '0';
            end if;
        end if;
    end process;
    
    kbd_rowselect <= not(vv55int_pa_out);
    kbd_key_blkvvod <= kbd_key_blkvvod_phy or osd_command_f11;
    
    
    xhdl19 <= not(KEY(0));
    kbdmatrix : entity work.vectorkeys
        port map (
            clkk         => clk24,
            reset        => xhdl19,
            ps2_clk      => PS2_KBCLK,
            ps2_dat      => PS2_KBDAT,
            mod_rus      => kbd_mod_rus,
            rowselect    => kbd_rowselect,
            rowbits      => kbd_rowbits,
            key_shift    => kbd_key_shift,
            key_ctrl     => kbd_key_ctrl,
            key_rus      => kbd_key_rus,
            key_blksbr   => kbd_key_blksbr,
            key_blkvvod  => kbd_key_blkvvod_phy,
            key_bushold  => kbd_key_scrolllock,
            key_osd      => kbd_keys_osd,
            osd_active   => scrollock_osd
        );
    xhdl20 <= ay_rden & not(vv55int_oe_n) & vi53_rden & floppy_rden & vv55pu_rden;
    process 
    begin
        case xhdl20 is
            when "10000" =>
                peripheral_data_in <= ay_odata;
            when "01000" =>
                peripheral_data_in <= vv55int_odata;
            when "00100" =>
                peripheral_data_in <= vi53_odata;
            when "00010" =>
                peripheral_data_in <= floppy_odata;
            when "00001" =>
                peripheral_data_in <= vv55pu_odata;
            when others =>
                peripheral_data_in <= "11111111";
        end case;
    end process;
    
    process 
    begin
        portmap_device <= address_bus_r(7 downto 2);
    end process;
    
    vv55int_sel <= to_stdlogic(portmap_device = "000000");
    vv55int_addr <= not(address_bus_r(1 downto 0));
    vv55int_idata <= DO;
    vv55int_cs_n <= not(((io_read or io_write) and vv55int_sel));
    vv55int_rd_n <= not(io_read);
    vv55int_wr_n <= WR_n or not(cpu_ce);
    
    
    vv55int : entity work.I82C55
        port map (
            vv55int_addr,
            vv55int_idata,
            vv55int_odata,
            vv55int_oe_n,
            vv55int_cs_n,
            vv55int_rd_n,
            vv55int_wr_n,
            vv55int_pa_in,
            vv55int_pa_out,
            vv55int_pa_oe_n,
            vv55int_pb_in,
            vv55int_pb_out,
            vv55int_pb_oe_n,
            vv55int_pc_in,
            vv55int_pc_out,
            vv55int_pc_oe_n,
            mreset,
            cpu_ce,
            clk24
        );
    process (clk24)
    begin
        if (clk24'event and clk24 = '1') then
            video_border_index <= vv55int_pb_out(3 downto 0);
            video_mode512 <= vv55int_pb_out(4);
            gledreg(9) <= vv55int_pc_out(3);
        end if;
    end process;
    
    process (kbd_rowbits)
    begin
        vv55int_pb_in <= not(kbd_rowbits);
    end process;
    
    process (kbd_key_shift, kbd_key_ctrl, kbd_key_rus)
    begin
        vv55int_pc_in(5) <= not(kbd_key_shift);
        vv55int_pc_in(6) <= not(kbd_key_ctrl);
        vv55int_pc_in(7) <= not(kbd_key_rus);
    end process;
    
    process (tape_input, SW)
    begin
        vv55int_pc_in(4) <= not(SW(6)) and tape_input;
    end process;
    

    vv55int_pc_in(3 downto 0) <= "1111";
    vv55pu_sel <= to_stdlogic(portmap_device = "000001");
    vv55pu_addr <= not(address_bus_r(1 downto 0));
    vv55pu_idata <= DO;
    vv55pu_rden <= io_read and vv55pu_sel;
    vv55pu_wren <= not(WR_n) and io_write and vv55pu_sel;
    
    
    fakepaw0 : entity work.fake8255
        port map (
            clk    => clk24,
            ce     => cpu_ce,
            addr   => vv55pu_addr,
            idata  => DO,
            odata  => vv55pu_odata,
            wren   => vv55pu_wren,
            rden   => vv55pu_rden
        );
    vi53_sel <= to_stdlogic(portmap_device = "000010");
    vi53_wren <= not(WR_n) and io_write and vi53_sel;
    vi53_rden <= io_read and vi53_sel;
    
    
    xhdl21 <= not(address_bus_r(1 downto 0));
    vi53 : entity work.pit8253
        port map (
            clk24,
            cpu_ce,
            vi53_timer_ce,
            xhdl21,
            vi53_wren,
            vi53_rden,
            DO,
            vi53_odata,
            "111",
            vi53_out,
            vi53_testpin
        );
    iports_sel <= to_stdlogic(portmap_device = "000011");
    iports_write <= io_write and iports_sel;
    iports_palette_sel <= to_stdlogic(address_bus(1 downto 0) = "00");
    process (clk24)
    begin
        if (clk24'event and clk24 = '1') then
            if ((iports_write and not(WR_n) and cpu_ce) = '1') then
                video_palette_value <= DO;
                palette_wr_sim <= "0011";
            end if;
            if (ce6 and or_br(palette_wr_sim)) then
                palette_wr_sim <= palette_wr_sim - "0001";
            end if;
        end if;
    end process;
    
    process (palette_wr_sim)
    begin
        video_palette_wren <= or_br(palette_wr_sim);
    end process;
    
    video_palette_wren_delayed <= video_palette_wren_buf(7);
    process (clk24)
    begin
        if (clk24'event and clk24 = '1') then
            if (ce12 = '1') then
                video_palette_wren_buf <= (video_palette_wren_buf(6 downto 0) & video_palette_wren);
            end if;
        end if;
    end process;
    
    osd_command_bushold <= osd_command(0);
    osd_command_f12 <= osd_command(1);
    osd_command_f11 <= osd_command(2);
    floppy_sel <= to_stdlogic(portmap_device(2 downto 1) = "11");
    floppy_wren <= not(WR_n) and io_write and floppy_sel;
    floppy_rden <= io_read and floppy_sel;
    
    
    xhdl22 <= (address_bus_r(2) & not(address_bus_r(1 downto 0)));
    flappy : entity work.floppy
        port map (
            clk            => clk24,
            ce             => cpu_ce,
            reset_n        => KEY(0),
            sd_dat         => SD_DAT0,
            sd_dat3        => SD_DAT3_xhdl5,
            sd_cmd         => SD_CMD_xhdl4,
            sd_clk         => SD_CLK_xhdl3,
            uart_txd       => UART_RXD_xhdl8,
            hostio_addr    => xhdl22,
            hostio_idata   => DO,
            hostio_odata   => floppy_odata,
            hostio_rd      => floppy_rden,
            hostio_wr      => floppy_wren,
            display_addr   => osd_address,
            display_data   => osd_data,
            display_wren   => osd_wren,
            display_idata  => osd_q,
            keyboard_keys  => kbd_keys_osd,
            osd_command    => osd_command,
            green_leds     => floppy_leds,
            debug          => floppy_status,
            host_hold      => floppy_death_by_floppy
        );
    xhdl23 <= "11111110" when (osd_fg = '1') else "01011001";
    process (clk24)
    begin
        if (clk24'event and clk24 = '1') then
            if ((scrollock_osd and osd_bg) = '1') then
                osd_active <= '1';
                osd_colour <= xhdl23;
            else
                osd_active <= '0';
            end if;
        end if;
    end process;
    
    osd_q <= osd_rq + "00100000"(0);
    
    
    xhdl24 <= osd_data - "00100000";
	xhdl27 <= ce6 when ((tv_mode(0)) = '1') else '1';

    osd : entity work.textmode
        port map (
            clk         => clk24,
            ce          => xhdl27,
            vsync       => osd_vsync,
            hsync       => osd_hsync,
            pixel       => osd_fg,
            background  => osd_bg,
            address     => osd_address,
            data        => xhdl24,
            wren        => osd_wren,
            q           => osd_rq
        );
    ay_sel <= to_stdlogic(portmap_device = "000101" and address_bus_r(1) = '0');
    ay_wren <= not(WR_n) and io_write and ay_sel;
    ay_rden <= io_read and ay_sel;
    process (clk14)
    begin
        if (clk14'event and clk14 = '1') then
            aycectr <= aycectr + "001";
        end if;
    end process;
    
    
    
    xhdl25 <= to_stdlogicvector(aycectr = "000", 3);
    shrieker : entity work.ayglue
        port map (
            clk      => clk14,
            ce       => xhdl25,
            reset_n  => mreset_n,
            address  => address_bus_r(0),
            data     => DO,
            q        => ay_odata,
            wren     => ay_wren,
            rden     => ay_rden,
            outl     => out_L,
            outr     => out_R
        );
    
    
    xhdl26 <= to_stdlogic(KEY(3) = '0' or kbd_key_blksbr = '1' or osd_command_f12 = '1');
    skeys : entity work.specialkeys
        port map (
            clk             => clk24,
            cpu_ce          => cpu_ce,
            reset_n         => mreset_n,
            key_blksbr      => xhdl26,
            key_osd         => kbd_key_scrolllock,
            o_disable_rom   => disable_rom,
            o_blksbr_reset  => blksbr_reset_pulse,
            o_osd           => scrollock_osd
        );
    process 
    begin
        gledreg(8) <= disable_rom;
    end process;
    
    
end rtl;


