-------------------------------------------------------------------[06.05.2013]
-- UART Controller for FT232R
-------------------------------------------------------------------------------
-- Engineer: 	MVV
-- Description: 
--
-- Versions:
-- V1.0		05.05.2013	Initial release.
-- V1.1		06.05.2013
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity uart is
	generic (
		divisor	: integer := 303 );	-- divisor = 28MHz / 115200 Baud = 243
	port (
		CLK		: in  std_logic;
		RESET		: in  std_logic;
		WR			: in  std_logic;
		RD			: in  std_logic;
		DI			: in  std_logic_vector(7 downto 0);
		DO			: out std_logic_vector(7 downto 0);
		TX_EMPTY	      : out std_logic;
		TX_FIFO_EMPTY	: out std_logic;
		RXAVAIL	: out std_logic;
		RXERROR	: out std_logic;
		RXD		: in  std_logic;
		TXD		: out std_logic);
end uart;

architecture rtl of uart is
	constant halfbit 		: integer := divisor / 2; 

	signal tx_count		: integer range 0 to divisor;
	signal tx_shift_reg	: std_logic_vector(10 downto 0);
	signal tx_busy			: std_logic := '0';
	
--	signal rx_buffer		: std_logic_vector(7 downto 0);
	signal rx_bit_count	: integer range 0 to 10;
	signal rx_count		: integer range 0 to divisor;
--	signal rx_avail		: std_logic;
	signal rx_error		: std_logic;
	signal rx_shift_reg	: std_logic_vector(7 downto 0);
	signal rx_bit			: std_logic;
	--//=======================================================
	signal TX_head_cnt	: unsigned(7 downto 0) := "00000000";	
	signal TX_tail_cnt	: unsigned(7 downto 0) := "00000000";
	signal TX_fifo_out	: std_logic_vector(7 downto 0);
	signal WR_r				: std_logic_vector(1 downto 0);
	signal RD_r				: std_logic_vector(1 downto 0);
	signal tx_fifo_empty_s	: std_logic := '1';
--	signal tx_fifo_full		: std_logic := '0';
	signal wait_clk	   : std_logic := '0';
	--//==RX BUFF =============================================
	signal RX_head_cnt	: unsigned(7 downto 0) := "00000000";	
	signal RX_tail_cnt	: unsigned(7 downto 0) := "00000000";
	signal RX_fifo_out	: std_logic_vector(7 downto 0);
	signal WR_RX_BUFF    : std_logic := '0';
	signal rx_fifo_notempty : std_logic := '0'; 
--	signal rx_fifo_full	: std_logic := '0';
begin

 
process(CLK, RESET) is
begin
	if RESET = '1' then
		tx_shift_reg <= (others => '1');
		tx_count <= 0 ;
		tx_busy <= '0';
--		rx_buffer <= (others => '0');
		rx_bit_count <= 0;
		rx_count <= 0    ;
		rx_error <= '0'  ;
--		rx_avail <= '0'  ;
		----------------------------
		TX_head_cnt <= X"00";
		TX_tail_cnt <= X"00";
		----------------------------
		RX_head_cnt <= X"00";
		RX_tail_cnt <= X"00";
		WR_RX_BUFF  <= '0';
		----------------------------		
		tx_fifo_empty_s <= '1';		
	elsif CLK'event and CLK = '1' then
---------------FIFO--------------------
------TX ==============================
--WR--
		WR_r(0) <= WR;
		WR_r(1) <= WR_r(0);
		if WR_r = "10" then --__ SYNCRO--
			TX_head_cnt <= TX_head_cnt + 1;
		end if;	
		------
--		if (TX_head_cnt = TX_tail_cnt - 1) or ((TX_head_cnt = X"FF") and  (TX_tail_cnt =  X"00")) then
--			tx_fifo_full 	<= '1'; -- TX FIFO - FULL
--		else
--			tx_fifo_full 	<= '0'; -- TX FIFO - not fill
--		end if;	
		
------RX ==============================
		if  WR_RX_BUFF  = '1' then --new byte
			WR_RX_BUFF  <= '0';
			RX_head_cnt <= RX_head_cnt + 1;
		end if;
	   --RD--
		RD_r(0) <= RD;
		RD_r(1) <= RD_r(0);
		if RD_r = "10" then --__ SYNCRO--
			RX_tail_cnt <= RX_tail_cnt + 1;	
		end if;
		
		-------rx_fifo_notempty-----------------
		if (RX_head_cnt = RX_tail_cnt) then
			rx_fifo_notempty <= '0';
		else
			rx_fifo_notempty <= '1'; -- not empty
		end if;
	------
--		if (RX_head_cnt = RX_tail_cnt - 1) or ((RX_head_cnt = X"FF") and  (RX_tail_cnt = X"00")) then
--			rx_fifo_full 	<= '1'; -- TX FIFO - FULL
--		else
--			rx_fifo_full 	<= '0'; -- TX FIFO - not fill
--		end if;		
-----------------------------------------------	
-- Transmitter			
		if tx_busy = '0' then ----------- TX DRIVER NOT BUSY 
			if (TX_head_cnt = TX_tail_cnt) then -- TX FIFO  empty
				tx_fifo_empty_s <= '1'; -- empty
			else
			   tx_fifo_empty_s <= '0'; -- not empty				
				wait_clk <= '1';
				if (wait_clk = '1') then
					tx_busy 			<= '1';
					tx_count 		<= divisor;
					tx_shift_reg	<= "01" & TX_fifo_out & '0';	-- STOP, MSB...LSB, START
				end if;	
			end if;
		else --tx_busy = 1
			if tx_count = 0 then 
				if tx_shift_reg = "11111111101" then
					tx_busy  <= '0';
					wait_clk <= '0';
					TX_tail_cnt <= TX_tail_cnt + 1;
				else
					tx_shift_reg <= '1' & tx_shift_reg(10 downto 1);
				end if;
				tx_count <= divisor;
			else
				tx_count <= tx_count - 1;
			end if;
		end if;
		
-- Receiver	 ======================================================
		if RD = '1' then 
			rx_error <= '0';
--			rx_avail <= '0';
		end if;

		if rx_count /= 0 then 
			rx_count <= rx_count - 1;
      --===============START BIT=========================================
		else                          	
			if rx_bit_count = 0 then   -- wait for startbit
				if rx_bit = '0' then		-- FOUND
					rx_count <= halfbit; -- set interval
					rx_bit_count <= rx_bit_count + 1;                                               
				end if;
			elsif rx_bit_count = 1 then		-- sample mid of startbit
				if rx_bit = '0' then		-- OK
					rx_count <= divisor; -- set interval
					rx_bit_count <= rx_bit_count + 1;
					rx_shift_reg <= "00000000";
				else						-- ERROR
					rx_error <= '1';
					rx_bit_count <= 0; --=============WAIT START BIT!!!!!!!!!!!!
				end if;
			--===============STOP BIT=========================================
			elsif rx_bit_count = 10 then	-- stopbit
				if rx_bit = '1' then		   -- stop bit found				
					rx_count <= 0;
					rx_bit_count <= 0;
					---NEW DATA----------------------------
					--rx_buffer <= rx_shift_reg;
					WR_RX_BUFF  <= '1';
					---------------------------------------
--					rx_avail <= '1';
				else						-- ERROR
					rx_count <= divisor;
					rx_bit_count <= 0;
					rx_error <= '1';
				end if;
			--=============== Asqusition =====================================
			else
				rx_shift_reg(6 downto 0) <= rx_shift_reg(7 downto 1);
				rx_shift_reg(7)	<= rx_bit;
				rx_count <= divisor;
				rx_bit_count <= rx_bit_count + 1;
			end if;
        end if;
     end if;
end process;

-- Sync incoming RXD (anti metastable)
syncproc: process (RESET, CLK) is
begin
	if RESET = '1' then
		rx_bit <= '1';
	elsif CLK'event and CLK = '0' then
		rx_bit <= RXD;
	end if;
end process;

RXERROR <= rx_error;
RXAVAIL <= rx_fifo_notempty;-- rx_avail;
--TXBUSY	<= tx_busy;
TX_EMPTY			<= (not tx_busy) and tx_fifo_empty_s;
TX_FIFO_EMPTY 	<= tx_fifo_empty_s;
TXD		<= tx_shift_reg(0);
--DO		<= rx_buffer;




TX_FIFO: entity work.RAM_256B
port map (
	clock			=> CLK, 
	data	 	   => DI,               --<===INPUT  
	wraddress	=> std_logic_vector(TX_head_cnt),
	rdaddress	=> std_logic_vector(TX_tail_cnt),
 	wren	 	   => WR,
	q	   		=> TX_fifo_out      --===>OUTPUT
	);
	
RX_FIFO: entity work.RAM_256B
port map (
	clock			=> CLK, 
	data	 	   => rx_shift_reg,      --<===INPUT  
	wraddress	=> std_logic_vector(RX_head_cnt),
	rdaddress	=> std_logic_vector(RX_tail_cnt),
 	wren	 	   => WR_RX_BUFF,
	q	 		   => DO                --===>OUTPUT
	);
	
end rtl;