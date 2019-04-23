-------------------------------------------------------------------[05.11.2011]
-- ZCSPI SD Card Controller
-------------------------------------------------------------------------------
-- V0.1	05.11.2011	первая версия

-- Порт конфигурации 77h
-- На запись:
-- 	bit 0 	= питание SD-карты (0 – выключено, 1 -включено)
-- 	bit 1 	= управление сигналом CS
-- 	bit 2-7	= не используются
-- На чтение:
-- 	bit 0	= если 0 – SD-карта установлена, 1 – SD-карта отсутствует
-- 	bit 1	= если 1 – то на карте включен режим Read only, если 0 – режим Read only не включен
-- 	bit 2-6	= не используются
--	bit 7	= если 1 - буферный регистр содержит новые данные, если 0 - идет загрузка.
--
-- Порт данных 57h
--	Используется как на запись, так и на чтение для обмена данными по SPI-интерфейсу.
--	Тактирование осуществляется автоматически при записи какого-либо значения в порт 57h. При
--		этом формируются 8 тактовых импульсов на выходе SDCLK, на выход SDDI поступают данные
--		последовательно от старшего бита к младшему с каждым фронтом сигнала SDCLK. Период
--		следования тактовых импульсов составляет 125 нс для оригинального ZC.
--	При чтении из порта 57h также автоматически производится тактирование. Буферный регистр
--		порта 57h, используемый при чтении, заполняется данными со входа SDIN последовательно от
--		старшего бита к младшему с каждым фронтом сигнала SDCLK.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity sdmmc is
	port (
		RESET	: in std_logic;
		CLK     : in std_logic;
		A       : in std_logic;
		DI		: in std_logic_vector(7 downto 0);
		DO		: out std_logic_vector(7 downto 0);
		RD		: in std_logic;
		WR		: in std_logic;
		SDDET	: in std_logic;
		SDPRT	: in std_logic;
		SDCS_n	: out std_logic;
		SCK		: out std_logic;
		MOSI	: out std_logic;
		MISO	: in std_logic );
end;

architecture rtl of sdmmc is
	signal cnt			: std_logic_vector(3 downto 0);
	signal shift_in		: std_logic_vector(7 downto 0);
	signal shift_out	: std_logic_vector(7 downto 0);
	signal cnt_en		: std_logic;
	signal sd_cs		: std_logic;
	
begin

	process (RESET, A, WR, DI)
	begin
		if RESET = '1' then
			sd_cs <= '1';
		elsif (A = '1' and WR = '1') then
			sd_cs <= DI(1);
		end if;		
	end process;

	cnt_en <= not cnt(3) or cnt(2) or cnt(1) or cnt(0);
	
	process (CLK, cnt_en, A, RD, WR, SDPRT)
	begin
		if (A = '0' and (WR = '1' or RD = '1')) then
			cnt <= "1110";
		else 
			if (CLK'event and CLK = '0') then			
				if cnt_en = '1' then
					cnt <= cnt + 1;
				end if;
			end if;
		end if;
	end process;
		
	process (cnt, A, RD, shift_in, SDPRT)
	begin
		if (RD = '1') then
			if (A = '1') then 
				DO <= cnt(3) & "11111" & SDPRT & '0';
			else  
				DO <= shift_in;
			end if;
		end if;
	end process;
			
	process (CLK)
	begin
		if (CLK'event and CLK = '0') then			
			if (A = '0' and WR = '1') then
				shift_out <= DI;
			else
				if cnt(3) = '0' then
					shift_out(7 downto 0) <= shift_out(6 downto 0) & '1';
				end if;
			end if;
		end if;
	end process;
	
	process (CLK)
	begin
		if (CLK'event and CLK = '0') then			
			if cnt(3) = '0' then
				shift_in <= shift_in(6 downto 0) & MISO;
			end if;
		end if;
	end process;
	
	SDCS_n <= sd_cs;
	SCK	  <= CLK and not cnt(3);
	MOSI  <= shift_out(7);

end rtl;

---------------------------------------------------------------------[15.06.2013]
---- ZCSPI SD Card Controller
---------------------------------------------------------------------------------
---- V0.1		05.10.2011	первая версия
---- V0.2 	21.11.2011
---- V0.3 	10.05.2013	добавлен сигнал SDDET
---- V0.4 	24.05.2013	
--
---- Порт конфигурации 77h
---- На запись:
---- 	bit 0 	= питание SD-карты (0 – выключено, 1 -включено)
---- 	bit 1 	= управление сигналом CS
---- 	bit 2-7	= не используются
---- На чтение:
---- 	bit 0	= если 0 – SD-карта установлена, 1 – SD-карта отсутствует
---- 	bit 1	= если 1 – то на карте включен режим Read only, если 0 – режим Read only не включен
---- 	bit 2-6	= не используются
----	bit 7	= если 1 - буферный регистр содержит новые данные, если 0 - идет загрузка.
----
---- Порт данных 57h
----	Используется как на запись, так и на чтение для обмена данными по SPI-интерфейсу.
----	Тактирование осуществляется автоматически при записи какого-либо значения в порт 57h. При
----		этом формируются 8 тактовых импульсов на выходе SDCLK, на выход SDDI поступают данные
----		последовательно от старшего бита к младшему с каждым фронтом сигнала SDCLK. Период
----		следования тактовых импульсов составляет 125 нс для оригинального ZC.
----	При чтении из порта 57h также автоматически производится тактирование. Буферный регистр
----		порта 57h, используемый при чтении, заполняется данными со входа SDIN последовательно от
----		старшего бита к младшему с каждым фронтом сигнала SDCLK.
--
--library IEEE;
--use IEEE.std_logic_1164.all;
--use IEEE.std_logic_unsigned.all;
--
--entity sdmmc is
--	port (
--		RESET	: in std_logic;
--		CLK     : in std_logic;
--		A       : in std_logic;
--		DI		: in std_logic_vector(7 downto 0);
--		DO		: out std_logic_vector(7 downto 0);
--		WR		: in std_logic;
--		RD		: in std_logic;
--		SDPRT	: in std_logic;
--		SDDET	: in std_logic;
--		SDCS_n	: out std_logic;
--		SCK		: out std_logic;
--		MOSI	: out std_logic;
--		MISO	: in std_logic);
--end;
--
--architecture rtl of sdmmc is
--	signal cnt		: std_logic_vector(2 downto 0) := "000";
--	signal shift	: std_logic_vector(7 downto 0) := "11111111";
--	signal sd_cs	: std_logic := '1';
--	signal state	: std_logic := '0';
--
--begin
--	process (CLK, RESET, A, WR, RD, SDPRT, SDDET, DI, state, cnt, shift)
--	begin
--		if RESET = '1' then
--			sd_cs <= '1';
--			cnt   <= (others => '0');
--			state <= '0';
--			shift <= (others => '1');
--		elsif CLK'event and CLK = '0' then
--			if state = '0' then
--				if WR = '1' and A = '1' then
--					sd_cs <= DI(1);
--				end if;
--				if WR = '1' and A = '0' then
--					shift <= DI;
--					cnt <= (others => '0');
--					state <= '1';
--				end if;
--				if RD = '1' and A = '0' then
--					shift <= (others => '1');
--					cnt <= (others => '0');
--					state <= '1';
--				end if;
--			else
--				shift <= shift(6 downto 0) & MISO;
--				if cnt = "111" then
--					state <= '0';
--				end if;
--				cnt <= cnt + 1;
--			end if;
--		end if;	
--	end process;
--
--
--
----	
----	process (CLK, RESET, A, WR, DI, state)
----	begin
----		if RESET = '1' then
----			sd_cs <= '1';
----		elsif CLK'event and CLK = '0' then
----			if state = '0' and WR = '1' and A = '1' then
----				sd_cs <= DI(1);
----			end if;
----		end if;
----	end process;
--	
--	
--	
--	SDCS_n <= sd_cs;
--	SCK <= CLK and state;
--	MOSI <= shift(7) when state = '1' else '1';
--	DO <= shift when A = '0' else not(state) & "11111" & SDPRT & SDDET;
--	
--end rtl;