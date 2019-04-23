-------------------------------------------------------------------[31.01.2011]
-- SPI Master Controller
-------------------------------------------------------------------------------

-- The SPI core provides for four register addresses 
-- that the CPU can read or writen to:

-- Address 0 -> Data Buffer (write/read)
-- Address 1 -> Command/Status Register (write/read)

-- Data Buffer (write/read):
--	bit 7-0	= Stores SPI read/write data

-- Command/Status Register (write):
--	bit 7-3	= Reserved
--	bit 2	= IRQEN 	(Generate IRQ at end of transfer)
--	bit 1	= END   	(Deselect device after transfer/or immediately if START = '0')
--	bit 0	= START		(Start transfer)
-- Command/Status Register (read):
--	bit 6	= DESEL		(Deselect device)
-- 	bit 7	= BUSY		(Currently transmitting data)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity m25p40 is
	port (
		-- CPU Interface Signals
		RESET		: in std_logic;
		CLK			: in std_logic;
		CS			: in std_logic;
		RW			: in std_logic;
		ADDR		: in std_logic;
		DATA_IN		: in std_logic_vector(7 downto 0);
		DATA_OUT	: out std_logic_vector(7 downto 0);
		IRQ			: out std_logic;
		-- SPI Interface Signals
		SPI_MISO	: in std_logic;
		SPI_MOSI	: out std_logic;
		SPI_CLK		: out std_logic;
		SPI_nCS		: out std_logic );
	end;

architecture rtl of m25p40 is

	-- State type of the SPI transfer state machine
	type   state_type is (s_idle, s_running);
	signal state           : state_type;
	signal shift_reg       : std_logic_vector(7 downto 0);	-- Shift register
	signal spi_data_buf    : std_logic_vector(7 downto 0);	-- Buffer to hold data to be sent
	signal start           : std_logic;  					-- Start transmission flag
	signal count           : std_logic_vector(2 downto 0);	-- Number of bits transfered
	signal spi_clk_buf     : std_logic;						-- Buffered SPI clock
	signal spi_clk_out     : std_logic;						-- Buffered SPI clock output
	signal prev_spi_clk    : std_logic;						-- Previous SPI clock state
	signal deselect        : std_logic;						-- Flag to indicate that the SPI slave should be deselected after the current transfer
	signal irq_enable      : std_logic;						-- Flag to indicate that an IRQ should be generated at the end of a transfer
	signal spi_cs          : std_logic;						-- Internal chip select signal, will be demultiplexed through the cs_mux

begin

-- Read CPU bus into internal registers
cpu_write : process (CLK, RESET)
begin
	if RESET = '1' then
		deselect        <= '0';
		irq_enable      <= '0';
		start           <= '0';
		spi_data_buf    <= (others => '0');
	elsif falling_edge (CLK) then
		start <= '0';
		if (CS = '1' and RW = '1') then
			if ADDR = '0' then
				spi_data_buf <= DATA_IN;
				start <= '1';
			else
				irq_enable <= DATA_IN(1);
				deselect   <= DATA_IN(0);
			end if;
		end if;
	end if;
end process;

-- Provide data for the CPU to read
cpu_read : process (shift_reg, ADDR, state, deselect)
begin
	DATA_OUT <= (others => '0');
	if ADDR = '0' then
		DATA_OUT <= shift_reg;
	else
		if state = s_idle then
			DATA_OUT(7) <= '0';
		else
			DATA_OUT(7) <= '1';
		end if;
		DATA_OUT(6) <= deselect;
	end if;
end process;

-- SPI transfer state machine
spi_proc : process (CLK, RESET)
begin
	if RESET = '1' then
		count        <= (others => '0');
		shift_reg    <= (others => '0');
		prev_spi_clk <= '0';
		spi_clk_out  <= '0';
		spi_cs       <= '0';
		state        <= s_idle;
		IRQ          <= '0';
	elsif falling_edge (CLK) then
		prev_spi_clk <= spi_clk_buf;
		IRQ          <= '0';
		case state is
			when s_idle =>
				if start = '1' then
					count     <= (others => '0');
					shift_reg <= spi_data_buf;
					spi_cs    <= '1';
					state     <= s_running;
				elsif deselect = '1' then
					spi_cs <= '0';
				end if;
			when s_running =>
				if (prev_spi_clk = '1' and spi_clk_buf = '0') then
					spi_clk_out <= '0';
					count       <= count + "001";
					shift_reg   <= shift_reg(6 downto 0) & SPI_MISO;
					if count = "111" then
						if deselect = '1' then
							spi_cs <= '0';
						end if;
						if irq_enable = '1' then
							IRQ <= '1';
						end if;
						state <= s_idle;
					end if;
				elsif prev_spi_clk = '0' and spi_clk_buf = '1' then
					spi_clk_out <= '1';
				end if;
			when others => null;
		end case;
	end if;
end process;

-- Generate SPI clock
spi_clock_gen : process (CLK, RESET)
begin
	if RESET = '1' then
		spi_clk_buf <= '0';
	elsif falling_edge (CLK) then
		if state = s_running then
			spi_clk_buf <= not spi_clk_buf;
		else
			spi_clk_buf <= '0';
		end if;
	end if;
end process;

SPI_MOSI <= shift_reg(7);
SPI_CLK  <= spi_clk_out;
SPI_nCS  <= not spi_cs;

end rtl;