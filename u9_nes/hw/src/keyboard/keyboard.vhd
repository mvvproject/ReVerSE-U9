-------------------------------------------------------------------[06.10.2013]
-- PS/2 scancode
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

entity keyboard is
port (
	CLK				: in std_logic;
	RESET			: in std_logic;
	JOYPAD_DATA1	: out std_logic;
    JOYPAD_DATA2	: out std_logic;
    JOYPAD_CLK		: in std_logic;
    JOYPAD_LATCH	: in std_logic;
	key_reset		: out std_logic;
	key_cart		: out std_logic;
	PS2_CLK			: in std_logic;
	PS2_DATA		: in std_logic;
	JOY				: out std_logic
	);
end keyboard;

architecture rtl of keyboard is

component ps2_intf is
generic (filter_length : positive := 8);
port(
	CLK			: in std_logic;
	RESET		: in std_logic;
	PS2_CLK		: in std_logic;
	PS2_DATA	: in std_logic;
	DATA		: out std_logic_vector(7 downto 0);
	VALID		: out std_logic;
	ERROR		: out std_logic
	);
end component;

signal keyb_data	: std_logic_vector(7 downto 0);
signal keyb_valid	: std_logic;
signal release		: std_logic;
signal key			: std_logic_vector(15 downto 0) := "1111111111111111";
signal cnt			: std_logic_vector(2 downto 0);
signal res			: std_logic := '0';
signal cart			: std_logic := '0';
--signal extended	: std_logic;

begin	

ps2 : ps2_intf port map (
	CLK,
	RESET,
	PS2_CLK,
	PS2_DATA,
	keyb_data,
	keyb_valid,
 	open
	);

	process (JOYPAD_CLK, JOYPAD_LATCH)
	begin
		if (JOYPAD_LATCH = '1') then
			cnt <= (others => '0');
		elsif (JOYPAD_CLK'event and JOYPAD_CLK = '1') then
			cnt <= cnt + 1;
		end if;
	end process;

	process (cnt, key)
	begin
		case cnt is
			when "001" => JOYPAD_DATA1 <= key(0);	-- A
						  JOYPAD_DATA2 <= key(8);
			when "010" => JOYPAD_DATA1 <= key(1);	-- B
						  JOYPAD_DATA2 <= key(9);
			when "011" => JOYPAD_DATA1 <= key(2);	-- Select
						  JOYPAD_DATA2 <= key(10);
			when "100" => JOYPAD_DATA1 <= key(3);	-- Start
						  JOYPAD_DATA2 <= key(11);
			when "101" => JOYPAD_DATA1 <= key(4);	-- Up
						  JOYPAD_DATA2 <= key(12);
			when "110" => JOYPAD_DATA1 <= key(5);	-- Down
						  JOYPAD_DATA2 <= key(13);
			when "111" => JOYPAD_DATA1 <= key(6);	-- Left
						  JOYPAD_DATA2 <= key(14);
			when "000" => JOYPAD_DATA1 <= key(7);	-- Right
						  JOYPAD_DATA2 <= key(15);
			when others => null;
		end case;
	end process;

	key_reset <= res;
	key_cart <= cart;
	
	process(RESET, CLK)
	begin
		if RESET = '1' then
			release <= '0';
--			extended <= '0';
		elsif rising_edge(CLK) then
			if keyb_valid = '1' then
				if keyb_data = X"e0" then
					-- Extended key code follows
--					extended <= '1';
				elsif keyb_data = X"f0" then
					-- Release code follows
					release <= '1';
				else
					-- Cancel extended/release flags for next time
					release <= '0';
--					extended <= '0';
					case keyb_data is	
						-- JOY 1
						when X"3A" => key(0) <= release;	-- [M] 		(A)
						when X"29" => key(1) <= release;	-- [SPACE]	(B)
						when X"59" => key(2) <= release;	-- [SHIFT]	(Select)
						when X"5A" => key(3) <= release;	-- [ENTER]	(Start)
						when X"15" => key(4) <= release;	-- [Q] 		(Up)
						when X"1C" => key(5) <= release;	-- [A] 		(Down)
						when X"44" => key(6) <= release;	-- [O] 		(Left)
						when X"4D" => key(7) <= release;	-- [P] 		(Right)
						-- JOY 2
						when X"16" => key(8) <= release;	-- [1]	 	(A)
						when X"1E" => key(9) <= release;	-- [2]		(B)
						when X"26" => key(10) <= release;	-- [3]		(Select)
						when X"25" => key(11) <= release;	-- [4]		(Start)
						when X"75" => key(12) <= release;	-- [up]		(Up)
						when X"72" => key(13) <= release;	-- [down]	(Down)
						when X"6B" => key(14) <= release;	-- [left]	(Left)
						when X"74" => key(15) <= release;	-- [right]	(Right)

						when X"76" => res <= not release;	-- Esc
						when X"7E" => cart <= not release;  -- Scroll Lock
						when others => null;
					end case;
				end if;
			end if;
		end if;
	end process;

end architecture;
