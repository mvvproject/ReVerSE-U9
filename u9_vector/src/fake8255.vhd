library ieee;
    use ieee.std_logic_1164.all;


--jtag_top	tigertiger(
--				.clk24(clk24),
--				.reset_n(mreset_n),
--				.oHOLD(jHOLD),
--				.iHLDA(HLDA),
--				.iTCK(TCK),
--				.oTDO(TDO),
--				.iTDI(TDI),
--				.iTCS(TCS),
--				.oJTAG_ADDR(mJTAG_ADDR),
--				.iJTAG_DATA_TO_HOST(mJTAG_DATA_TO_HOST),
--				.oJTAG_DATA_FROM_HOST(mJTAG_DATA_FROM_HOST),
--				.oJTAG_SRAM_WR_N(mJTAG_SRAM_WR_N),
--				.oJTAG_SELECT(mJTAG_SELECT)
--				);

--/////////////////////
-- Fake 8255 for PPI //
--/////////////////////
entity fake8255 is
    port (
        clk        : in std_logic;
        ce         : in std_logic;
        addr       : in std_logic_vector(1 downto 0);
        idata      : in std_logic_vector(7 downto 0);
        odata      : out std_logic_vector(7 downto 0);
        wren       : in std_logic;
        rden       : in std_logic
    );
end fake8255;

architecture trans of fake8255 is
begin
    
    odata <= "00000000";
    
end trans;


