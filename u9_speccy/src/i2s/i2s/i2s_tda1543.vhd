-----------------------------------------------------------------[Rev.20110130]
-- I2S Master Controller
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
 
entity i2s is
	Port ( 
		RESET	: in std_logic;
		CLK		: in std_logic;
		CS		: in std_logic;
        DATA_L	: in std_logic_vector (15 downto 0);
        DATA_R	: in std_logic_vector (15 downto 0);
		BCK		: out std_logic;
		WS		: out std_logic;
        DATA	: out std_logic );
end i2s;
 
architecture i2s_arch of i2s is
	constant I2S_BIT_WIDTH : integer := 16;
	type states is (start_l,send_l,start_r,send_r);
	signal state : states;
	signal data_l_i : std_logic_vector (15 downto 0);
	signal data_r_i : std_logic_vector (15 downto 0);
begin
	process (RESET, CLK, CS)
	variable bit_cnt : integer range 0 to I2S_BIT_WIDTH - 1;
	begin
		if (RESET = '1' or CS = '0') then
			data_l_i <= (others => '0');
			data_r_i <= (others => '0');
			bit_cnt := 0;
		elsif (CLK'event and CLK = '0') then
			case (state) is
				when start_l =>
					WS <= '0';
					DATA <= data_l_i(15);
					bit_cnt := bit_cnt + 1;
					state <= send_l;
				when send_l =>
					WS <= '0';
					DATA <= data_l_i(15);
					data_l_i <= data_l_i(14 downto 0) & '0';
					if bit_cnt = I2S_BIT_WIDTH - 1 then
						bit_cnt := 0;
						state <= start_r;
					else
						bit_cnt := bit_cnt + 1;
						state <= send_l;						
					end if;
				when start_r =>
					WS <= '1';
					DATA <= data_r_i(15);
					bit_cnt := bit_cnt + 1;
					state <= send_r;				
				when send_r =>
					DATA <= data_r_i(15);
					data_r_i <= data_r_i(14 downto 0) & '0';
					WS <= '1';
					if bit_cnt = I2S_BIT_WIDTH - 1 then
						bit_cnt := 0;
						data_l_i <= DATA_L;
						data_r_i <= DATA_R;
						state <= start_l;
					else
						bit_cnt := bit_cnt + 1;
						state <= send_r;						
					end if;
 				when others => NULL;
			end case;
		end if;
	end process;

	BCK <= CLK when CS = '1' else '1';

end i2s_arch;