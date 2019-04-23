-------------------------------------------------------------------[09.09.2014]
-- IDE Video-DAC 3bpp
-------------------------------------------------------------------------------
-- V0.1 	25.08.2014	первая версия
-- V0.2		09.09.2014	палитра 5bpp -> 3bpp

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all; 

entity lut is
port (
	mode	: in std_logic;
	data	: in std_logic_vector(4 downto 0);
	q	: out std_logic_vector(2 downto 0));
end lut;

architecture rtl of lut is

signal sig 	: std_logic_vector(2 downto 0);

begin
	q <= data(2 downto 0) when mode = '0' else sig;

	process (data)
	begin
		case data is
			when b"00000"	=> sig <= b"000";
			when b"00001"	=> sig <= b"000";
			when b"00010"	=> sig <= b"000";
			when b"00011"	=> sig <= b"000";
			when b"00100"	=> sig <= b"001";
			when b"00101"	=> sig <= b"001";
			when b"00110"	=> sig <= b"001";
			when b"00111"	=> sig <= b"001";

			when b"01000"	=> sig <= b"010";
			when b"01001"	=> sig <= b"010";
			when b"01010"	=> sig <= b"010";
			when b"01011"	=> sig <= b"010";
			when b"01100"	=> sig <= b"011";
			when b"01101"	=> sig <= b"011";
			when b"01110"	=> sig <= b"011";
			when b"01111"	=> sig <= b"011";

			when b"10000"	=> sig <= b"100";
			when b"10001"	=> sig <= b"100";
			when b"10010"	=> sig <= b"100";
			when b"10011"	=> sig <= b"100";
			when b"10100"	=> sig <= b"101";
			when b"10101"	=> sig <= b"101";
			when b"10110"	=> sig <= b"101";
			when b"10111"	=> sig <= b"101";

			when b"11000"	=> sig <= b"110";
			when b"11001"	=> sig <= b"110";
			when b"11010"	=> sig <= b"110";
			when b"11011"	=> sig <= b"110";
			when b"11100"	=> sig <= b"111";
			when b"11101"	=> sig <= b"111";
			when b"11110"	=> sig <= b"111";
			when b"11111"	=> sig <= b"111";

			when others 	=> null;
		end case;
	end process;
end rtl;