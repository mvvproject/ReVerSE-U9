library ieee;
    use ieee.std_logic_1164.all;


entity nes_top is
    port (
        
        --  input  wire       CLK_100MHZ,        // 100MHz system clock signal	[V0.1.0 MVV]
        --  input  wire       BTN_SOUTH,         // reset push button
        --  input  wire       BTN_EAST,          // console reset
        RXD        : in std_logic;		-- rs-232 rx signal
        --  input  wire [3:0] SW,                // switches
        --  input  wire       NES_JOYPAD_DATA1,  // joypad 1 input signal
        --  input  wire       NES_JOYPAD_DATA2,  // joypad 2 input signal
        --  output wire       NES_JOYPAD_CLK,    // joypad output clk signal
        --  output wire       NES_JOYPAD_LATCH,  // joypad output latch signal
        
        TXD        : out std_logic;		-- rs-232 tx signal
        VGA_HSYNC  : out std_logic;		-- vga hsync signal
        VGA_VSYNC  : out std_logic;		-- vga vsync signal
        VGA_RED    : out std_logic_vector(2 downto 0);		-- vga red signal
        VGA_GREEN  : out std_logic_vector(2 downto 0);		-- vga green signal
        VGA_BLUE   : out std_logic_vector(2 downto 0);		-- vga blue signal
        --  output wire       AUDIO,             // pwm output audio channel
        
        -- DAC 
        ASDO       : out std_logic;
        DCLK       : out std_logic;
        NCSO       : out std_logic;
        DAC_BCK    : out std_logic;
        
        PS2_KBCLK  : inout std_logic;
        PS2_KBDAT  : inout std_logic;
        
        --[V0.1.0 MVV]
        CLK_50MHZ  : in std_logic;		-- 50MHz system clock signal
        BTN_S      : in std_logic;		-- reset push button
        -- console reset
        
        BTN_E      : in std_logic
    );
end nes_top;

architecture rtl of nes_top is
    
    --[V0.1.0 MVV]
    signal SW                 : std_logic_vector(3 downto 0);		-- switches 
    signal CLK_100MHZ         : std_logic;
    signal BTN_SOUTH          : std_logic;		-- reset push button
    signal BTN_EAST           : std_logic;		-- console reset
    signal AUDIO              : std_logic_vector(5 downto 0);
    signal clk_9_2mhz         : std_logic;
    signal audio_l            : std_logic_vector(15 downto 0);
    signal audio_r            : std_logic_vector(15 downto 0);
    signal audio              : std_logic_vector(5 downto 0);
    signal audio1             : std_logic;
    signal key                : std_logic_vector(8 downto 0);
    signal NES_JOYPAD_DATA1   : std_logic;		-- joypad 1 input signal
    signal NES_JOYPAD_DATA2   : std_logic;		-- joypad 2 input signal
    signal NES_JOYPAD_CLK     : std_logic;		-- joypad output clk signal
    signal NES_JOYPAD_LATCH   : std_logic;		-- joypad output latch signal
    
    --
    
    --
    -- System Memory Buses
    --
    signal cpumc_din          : std_logic_vector(7 downto 0);
    signal cpumc_a            : std_logic_vector(15 downto 0);
    signal cpumc_r_nw         : std_logic;
    
    signal ppumc_din          : std_logic_vector(7 downto 0);
    signal ppumc_a            : std_logic_vector(13 downto 0);
    signal ppumc_wr           : std_logic;
    
    --
    -- RP2A03: Main processing chip including CPU, APU, joypad control, and sprite DMA control.
    --
    signal rp2a03_rdy         : std_logic;
    signal rp2a03_din         : std_logic_vector(7 downto 0);
    signal rp2a03_nnmi        : std_logic;
    signal rp2a03_dout        : std_logic_vector(7 downto 0);
    signal rp2a03_a           : std_logic_vector(15 downto 0);
    signal rp2a03_r_nw        : std_logic;
    signal rp2a03_brk         : std_logic;
    signal rp2a03_dbgreg_sel  : std_logic_vector(3 downto 0);
    signal rp2a03_dbgreg_din  : std_logic_vector(7 downto 0);
    signal rp2a03_dbgreg_wr   : std_logic;
    signal rp2a03_dbgreg_dout : std_logic_vector(7 downto 0);
    
    signal AUDIO1             : std_logic;
    
    -- DAC
    
    -- KEY
    
    --
    -- CART: cartridge emulator
    --
    signal cart_prg_nce       : std_logic;
    signal cart_prg_dout      : std_logic_vector(7 downto 0);
    signal cart_chr_dout      : std_logic_vector(7 downto 0);
    signal cart_ciram_nce     : std_logic;
    signal cart_ciram_a10     : std_logic;
    signal cart_cfg           : std_logic_vector(39 downto 0);
    signal cart_cfg_upd       : std_logic;
    
    --
    -- WRAM: internal work ram
    --
    signal wram_en            : std_logic;
    signal wram_dout          : std_logic_vector(7 downto 0);
    
    --
    -- VRAM: internal video ram
    --
    signal vram_a             : std_logic_vector(10 downto 0);
    signal vram_dout          : std_logic_vector(7 downto 0);
    
    --
    -- PPU: picture processing unit block.
    --
    signal ppu_ri_sel         : std_logic_vector(2 downto 0);		-- ppu register interface reg select
    signal ppu_ri_ncs         : std_logic;		-- ppu register interface enable
    signal ppu_ri_r_nw        : std_logic;		-- ppu register interface read/write select
    signal ppu_ri_din         : std_logic_vector(7 downto 0);		-- ppu register interface data input
    signal ppu_ri_dout        : std_logic_vector(7 downto 0);		-- ppu register interface data output
    
    signal ppu_vram_a         : std_logic_vector(13 downto 0);		-- ppu video ram address bus
    signal ppu_vram_wr        : std_logic;		-- ppu video ram read/write select
    signal ppu_vram_din       : std_logic_vector(7 downto 0);		-- ppu video ram data bus (input)
    signal ppu_vram_dout      : std_logic_vector(7 downto 0);		-- ppu video ram data bus (output)
    
    signal ppu_nvbl           : std_logic;		-- ppu /VBL signal.
    
    -- PPU snoops the CPU address bus for register reads/writes.  Addresses 0x2000-0x2007
    -- are mapped to the PPU register space, with every 8 bytes mirrored through 0x3FFF.
    
    --
    -- HCI: host communication interface block.  Interacts with NesDbg software through serial port.
    --
    signal hci_active         : std_logic;
    signal hci_cpu_din        : std_logic_vector(7 downto 0);
    signal hci_cpu_dout       : std_logic_vector(7 downto 0);
    signal hci_cpu_a          : std_logic_vector(15 downto 0);
    signal hci_cpu_r_nw       : std_logic;
    signal hci_ppu_vram_din   : std_logic_vector(7 downto 0);
    signal hci_ppu_vram_dout  : std_logic_vector(7 downto 0);
    signal hci_ppu_vram_a     : std_logic_vector(15 downto 0);
    signal hci_ppu_vram_wr    : std_logic;
    -- X-HDL generated signals

    signal xhdl9 : std_logic;
    signal xhdl10 : std_logic;
    signal xhdl11 : std_logic;
    signal xhdl12 : std_logic;
    
    -- Declare intermediate signals for referenced outputs
    signal TXD_xhdl3          : std_logic;
    signal VGA_HSYNC_xhdl6    : std_logic;
    signal VGA_VSYNC_xhdl8    : std_logic;
    signal VGA_RED_xhdl7      : std_logic_vector(2 downto 0);
    signal VGA_GREEN_xhdl5    : std_logic_vector(2 downto 0);
    signal VGA_BLUE_xhdl4     : std_logic_vector(2 downto 0);
    signal ASDO_xhdl0         : std_logic;
    signal DCLK_xhdl2         : std_logic;
    signal DAC_BCK_xhdl1      : std_logic;
begin
    -- Drive referenced outputs
    TXD <= TXD_xhdl3;
    VGA_HSYNC <= VGA_HSYNC_xhdl6;
    VGA_VSYNC <= VGA_VSYNC_xhdl8;
    VGA_RED <= VGA_RED_xhdl7;
    VGA_GREEN <= VGA_GREEN_xhdl5;
    VGA_BLUE <= VGA_BLUE_xhdl4;
    ASDO <= ASDO_xhdl0;
    DCLK <= DCLK_xhdl2;
    DAC_BCK <= DAC_BCK_xhdl1;
    SW <= "0000";
    NES_JOYPAD_DATA2 <= '1';
    audio_l <= ("00" & (audio & "00000000"));
    audio_r <= ("00" & (audio & "00000000"));
    NES_JOYPAD_DATA1 <= key(8);
    BTN_SOUTH <= not(BTN_S);
    BTN_EAST <= not(BTN_E);
    
    
    altpll0_inst : altpll0
        port map (
            inclk0  => CLK_50MHZ,
            c0      => CLK_100MHZ,
            c1      => clk_9_2mhz
        );
    
    
    xhdl9 <= not(BTN_EAST);
    rp2a03_blk : rp2a03
        port map (
            clk_in         => CLK_100MHZ,
            rst_in         => BTN_SOUTH,
            rdy_in         => rp2a03_rdy,
            d_in           => rp2a03_din,
            nnmi_in        => rp2a03_nnmi,
            nres_in        => xhdl9,
            d_out          => rp2a03_dout,
            a_out          => rp2a03_a,
            r_nw_out       => rp2a03_r_nw,
            brk_out        => rp2a03_brk,
            jp_data1_in    => NES_JOYPAD_DATA1,
            jp_data2_in    => NES_JOYPAD_DATA2,
            jp_clk         => NES_JOYPAD_CLK,
            jp_latch       => NES_JOYPAD_LATCH,
            mute_in        => SW,
            audio          => audio,
            audio_out      => AUDIO1,
            dbgreg_sel_in  => rp2a03_dbgreg_sel,
            dbgreg_d_in    => rp2a03_dbgreg_din,
            dbgreg_wr_in   => rp2a03_dbgreg_wr,
            dbgreg_d_out   => rp2a03_dbgreg_dout
        );
    
    
    dac : tda1543
        port map (
            reset   => BTN_SOUTH,
            cs      => '1',
            clk     => clk_9_2mhz,
            data_l  => audio_l,
            data_r  => audio_r,
            bck     => DAC_BCK_xhdl1,
            ws      => DCLK_xhdl2,
            data    => ASDO_xhdl0
        );
    
    
    joy : keyboard
        port map (
            clk       => CLK_50MHZ,
            reset     => BTN_SOUTH,
            ps2_clk   => PS2_KBCLK,
            ps2_data  => PS2_KBDAT,
            joy       => key
        );
    
    
    xhdl10 <= not(ppumc_wr);
    cart_blk : cart
        port map (
            clk_in         => CLK_100MHZ,
            cfg_in         => cart_cfg,
            cfg_upd_in     => cart_cfg_upd,
            prg_nce_in     => cart_prg_nce,
            prg_a_in       => cpumc_a(14 downto 0),
            prg_r_nw_in    => cpumc_r_nw,
            prg_d_in       => cpumc_din,
            prg_d_out      => cart_prg_dout,
            chr_a_in       => ppumc_a,
            chr_r_nw_in    => xhdl10,
            chr_d_in       => ppumc_din,
            chr_d_out      => cart_chr_dout,
            ciram_nce_out  => cart_ciram_nce,
            ciram_a10_out  => cart_ciram_a10
        );
    cart_prg_nce <= not(cpumc_a(15));
    
    
    wram_blk : wram
        port map (
            clk_in   => CLK_100MHZ,
            en_in    => wram_en,
            r_nw_in  => cpumc_r_nw,
            a_in     => cpumc_a(10 downto 0),
            d_in     => cpumc_din,
            d_out    => wram_dout
        );
    wram_en <= to_stdlogic((cpumc_a(15 downto 13) = "000"));
    
    
    xhdl11 <= not(cart_ciram_nce);
    xhdl12 <= not(ppumc_wr);
    vram_blk : vram
        port map (
            clk_in   => CLK_100MHZ,
            en_in    => xhdl11,
            r_nw_in  => xhdl12,
            a_in     => vram_a,
            d_in     => ppumc_din,
            d_out    => vram_dout
        );
    ppu_ri_sel <= cpumc_a(2 downto 0);
    ppu_ri_ncs <= '0' when (cpumc_a(15 downto 13) = "001") else
                  '1';
    ppu_ri_r_nw <= cpumc_r_nw;
    ppu_ri_din <= cpumc_din;
    
    
    ppu_blk : ppu
        port map (
            clk_in       => CLK_100MHZ,
            rst_in       => BTN_SOUTH,
            ri_sel_in    => ppu_ri_sel,
            ri_ncs_in    => ppu_ri_ncs,
            ri_r_nw_in   => ppu_ri_r_nw,
            ri_d_in      => ppu_ri_din,
            vram_d_in    => ppu_vram_din,
            hsync_out    => VGA_HSYNC_xhdl6,
            vsync_out    => VGA_VSYNC_xhdl8,
            r_out        => VGA_RED_xhdl7,
            g_out        => VGA_GREEN_xhdl5,
            b_out        => VGA_BLUE_xhdl4,
            ri_d_out     => ppu_ri_dout,
            nvbl_out     => ppu_nvbl,
            vram_a_out   => ppu_vram_a,
            vram_d_out   => ppu_vram_dout,
            vram_wr_out  => ppu_vram_wr
        );
    vram_a <= (cart_ciram_a10 & ppumc_a(9 downto 0));
    
    
    
    hci_blk : hci
        port map (
            clk             => CLK_100MHZ,
            rst             => BTN_SOUTH,
            rx              => RXD,
            brk             => rp2a03_brk,
            cpu_din         => hci_cpu_din,
            cpu_dbgreg_in   => rp2a03_dbgreg_dout,
            ppu_vram_din    => hci_ppu_vram_din,
            tx              => TXD_xhdl3,
            active          => hci_active,
            cpu_r_nw        => hci_cpu_r_nw,
            cpu_a           => hci_cpu_a,
            cpu_dout        => hci_cpu_dout,
            cpu_dbgreg_sel  => rp2a03_dbgreg_sel,
            cpu_dbgreg_out  => rp2a03_dbgreg_din,
            cpu_dbgreg_wr   => rp2a03_dbgreg_wr,
            ppu_vram_wr     => hci_ppu_vram_wr,
            ppu_vram_a      => hci_ppu_vram_a,
            ppu_vram_dout   => hci_ppu_vram_dout,
            cart_cfg        => cart_cfg,
            cart_cfg_upd    => cart_cfg_upd
        );
    
    -- Mux cpumc signals from rp2a03 or hci blk, depending on debug break state (hci_active).
    rp2a03_rdy <= '0' when (hci_active = '1') else
                  '1';
    cpumc_a <= hci_cpu_a when (hci_active = '1') else
               rp2a03_a;
    cpumc_r_nw <= hci_cpu_r_nw when (hci_active = '1') else
                  rp2a03_r_nw;
    cpumc_din <= hci_cpu_dout when (hci_active = '1') else
                 rp2a03_dout;
    
    rp2a03_din <= cart_prg_dout or wram_dout or ppu_ri_dout;
    hci_cpu_din <= cart_prg_dout or wram_dout or ppu_ri_dout;
    
    -- Mux ppumc signals from ppu or hci blk, depending on debug break state (hci_active).
    ppumc_a <= hci_ppu_vram_a(13 downto 0) when (hci_active = '1') else
               ppu_vram_a;
    ppumc_wr <= hci_ppu_vram_wr when (hci_active = '1') else
                ppu_vram_wr;
    ppumc_din <= hci_ppu_vram_dout when (hci_active = '1') else
                 ppu_vram_dout;
    
    ppu_vram_din <= cart_chr_dout or vram_dout;
    hci_ppu_vram_din <= cart_chr_dout or vram_dout;
    
    -- Issue NMI interupt on PPU vertical blank.
    rp2a03_nnmi <= ppu_nvbl;
    
end rtl;