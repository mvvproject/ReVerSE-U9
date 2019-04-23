-------------------------------------------------------------------[20.07.2013]
-- VIDEO Pentagon or Spectrum mode
-------------------------------------------------------------------------------
-- V0.1 	05.10.2011	перва€ верси€
-- V0.2 	11.10.2011	RGB, CLKEN
-- V0.3 	19.12.2011	INT
-- V0.4 	20.05.2013	изменены параметры растра дл€ режима Video 15 √ц
-- V0.5 	20.07.2013	изменено формирование сигнала INT, FLASH

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity video is
	port (
		CLK		: in std_logic;							-- системна€ частота
		ENA		: in std_logic;							-- частота вывода точек 7MHz
		BORDER	: in std_logic_vector(2 downto 0);		-- цвет бордюра (порт #xxFE)
		A		: out std_logic_vector(12 downto 0);
		DI		: in std_logic_vector(7 downto 0);
		MODE	: in std_logic;							-- ZX видео режим 0: Spectrum; 1: Pentagon
		INTA	: in std_logic;
		INT		: out std_logic;
		HCNT	: out std_logic_vector(8 downto 0);
		VCNT	: out std_logic_vector(8 downto 0);
		RGB		: out std_logic_vector(5 downto 0);		-- RRGGBB
		HSYNC	: out std_logic;
		VSYNC	: out std_logic);
end entity;

architecture rtl of video is

	constant h_end_count		: natural := 447;
	constant h_sync_on			: natural := 329;
	constant h_sync_off			: natural := 382;
	constant h_blank_on			: natural := 302;
	constant h_blank_off		: natural := 419;
	constant h_int_on			: natural := 316;
	
	constant v_end_count_pent	: natural := 319;
	constant v_end_count_spec	: natural := 311;
	constant v_sync_on			: natural := 256;
	constant v_sync_off			: natural := 260;
	constant V_BLANK_LO			: natural := 224;
	constant V_BLANK_HI			: natural := 286;
	constant v_int_on_pent		: natural := 239;
	constant v_int_on_spec		: natural := 247;
--
--	-- Horizontal timing (line)
--	constant h_visible_area		: integer := 256;
--	constant h_front_porch		: integer := 16;
--	constant h_sync_pulse		: integer := 96;
--	constant h_back_porch		: integer := 48;
--	constant h_whole_line		: integer := 800;
--	constant h_int_on			: integer := 316;
--	constant h_blank_on			: integer := 302;
--	constant h_blank_off		: integer := 419;	
--	-- Vertical timing (frame)	
--	constant v_visible_area		: integer := 192;
--	constant v_front_porch		: integer := 10;
--	constant v_sync_pulse		: integer := 2;
--	constant v_back_porch		: integer := 33;
--	constant v_whole_frame		: integer := 525;
--	constant v_int_on_pent		: integer := 239;
--	constant v_int_on_spec		: integer := 247;
--	-- Horizontal Timing constants  
--	constant h_pixels_across	: integer := h_visible_area - 1;
--	constant h_sync_on			: integer := h_visible_area + h_front_porch - 1;
--	constant h_sync_off			: integer := h_visible_area + h_front_porch + h_sync_pulse - 2;
--	constant h_end_count		: integer := h_whole_line - 1;
--	-- Vertical Timing constants
--	constant v_pixels_down		: integer := v_visible_area - 1;
--	constant v_sync_on			: integer := v_visible_area + v_front_porch - 1;
--	constant v_sync_off			: integer := v_visible_area + v_front_porch + v_sync_pulse - 2;
--	constant v_end_count_pent	: integer := v_whole_frame - 1;
--	constant v_end_count_spec	: integer := v_whole_frame - 1;
	

	
	
	
	
	signal h_cnt			: unsigned(8 downto 0) := "000000000";
	signal v_cnt			: unsigned(8 downto 0) := "000000000";
	signal paper			: std_logic;
	signal paper1			: std_logic;
	signal flash			: unsigned(4 downto 0) := "00000";
	signal vid_reg			: std_logic_vector(7 downto 0);
	signal vid_b_reg		: std_logic_vector(7 downto 0);
	signal vid_c_reg		: std_logic_vector(7 downto 0);

begin

process (CLK)
begin
	if CLK'event and CLK = '1' then
		if ENA = '1' then		-- 7MHz
-- X count
			if h_cnt = h_end_count then
				h_cnt <= "000000000";
			else
				h_cnt <= h_cnt + 1;
			end if;
-- HSYNC  
			if h_cnt = h_sync_on then
-- Y count		
				if (v_cnt = v_end_count_spec and MODE = '0') or (v_cnt = v_end_count_pent and MODE = '1') then
					v_cnt <= "000000000";
				else
					v_cnt <= v_cnt + 1;
				end if;
				HSYNC <= '0';
			elsif h_cnt = h_sync_off then
				HSYNC <= '1'; 
			end if;
-- VSYNC
			if v_cnt > v_sync_on and v_cnt < v_sync_off then
				VSYNC <= '0';
			else
				VSYNC <= '1';
			end if;
-- PAPER
			if h_cnt < 256 and v_cnt < 192 then
				paper <= '1';
			else
				paper <= '0';
			end if;
-- BLANC
			if (h_cnt > h_blank_on and h_cnt < h_blank_off) or (v_cnt > V_BLANK_LO and v_cnt < V_BLANK_HI) then
				RGB <= "000000";
			else
				if paper1 = '1' and (vid_b_reg(7 - to_integer(h_cnt(2 downto 0))) xor (flash(4) and vid_c_reg(7))) = '0' then
					RGB <= vid_c_reg(4) & (vid_c_reg(4) and vid_c_reg(6)) & vid_c_reg(5) & (vid_c_reg(5) and vid_c_reg(6)) & vid_c_reg(3) & (vid_c_reg(3) and vid_c_reg(6));
				elsif paper1 = '1' and (vid_b_reg(7 - to_integer(h_cnt(2 downto 0))) xor (flash(4) and vid_c_reg(7))) = '1' then
					RGB <= vid_c_reg(1) & (vid_c_reg(1) and vid_c_reg(6)) & vid_c_reg(2) & (vid_c_reg(2) and vid_c_reg(6)) & vid_c_reg(0) & (vid_c_reg(0) and vid_c_reg(6));
				else
-- BORDER
					RGB <= BORDER(1) & '0' & BORDER(2) & '0' & BORDER(0) & '0';
				end if;
			end if;
			case h_cnt(2 downto 0) is
				when "100" => 
					A <= std_logic_vector(v_cnt(7 downto 6)) & std_logic_vector(v_cnt(2 downto 0)) & std_logic_vector(v_cnt(5 downto 3)) & std_logic_vector(h_cnt(7 downto 3));
				when "101" =>
					vid_reg <= DI;
				when "110" =>
					A <= "110" & std_logic_vector(v_cnt(7 downto 3)) & std_logic_vector(h_cnt(7 downto 3));
				when "111" =>
					vid_b_reg <= vid_reg;
					vid_c_reg <= DI;
					paper1 <= paper;
				when others => null;
			end case;
		end if;
	end if;
end process;

-- INT
process (CLK, ENA, INTA, h_cnt, v_cnt, MODE)
begin
	if INTA = '0' then
		INT <= '1';
	elsif CLK'event and CLK = '1' then
		if ENA = '1' then		-- 7MHz
			if h_cnt = h_int_on and ((v_cnt = v_int_on_spec and MODE = '0') or (v_cnt = v_int_on_pent and MODE = '1')) then
-- FLASH
				flash <= flash + 1;
				INT <= '0';
			end if;
		end if;
	end if;
end process;

HCNT 	<= std_logic_vector(h_cnt);
VCNT 	<= std_logic_vector(v_cnt);

end architecture;