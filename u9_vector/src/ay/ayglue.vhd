--module ayglue(clk, ce, reset_n, address, data, wren, rden, q, sound,odataoe);
--input 			clk;
--input			ce;
--input			reset_n;
--input 			address;		// port 14 (00) = data; port 15 (01) = address
--input [7:0]		data;
--input			wren;
--input			rden;
--output reg[7:0]	q;
--output			odataoe;
--
--output[7:0]	sound;
--
--wire [7:0] 	odata;
--wire 		odataoe;
--
--always @(odata, odataoe) if (~odataoe) q <= odata;
--
--reg [2:0] ctl;	// {I_BDIR,I_BC2,I_BC1}
--always begin
--		case ({address,wren,rden}) 
--			3'b110:		ctl <= 3'b001;	// write addr
--			3'b010:		ctl <= 3'b110;	// wr data
--			3'b001:		ctl <= 3'b011;	// rd data
--			default:	ctl <= 3'b000;
--		endcase
--end
--
--
--YM2149 digeridoo(
--  .I_DA(data),
--  .O_DA(odata),
--  .O_DA_OE_L(odataoe),
--
--  .I_A9_L(1'b0),
--  .I_A8(1'b1),
--  .I_BDIR(ctl[2]), 
--  .I_BC2(ctl[1]),
--  .I_BC1(ctl[0]),
--  .I_SEL_L(1'b1), // something /16?
--
--  .O_AUDIO(sound),
--
--  .ENA(ce),
--  .RESET_L(reset_n),
--  .CLK(clk)
--  );
--
--
--endmodule

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.ALL; 

entity ayglue is
	port (
	clk		: in std_logic;
	ce		: in std_logic;
	reset_n	: in std_logic;
	address	: in std_logic;
	data	: in std_logic_vector(7 downto 0);
	wren	: in std_logic;
	rden	: in std_logic;
	q		: out std_logic_vector(7 downto 0);
	outL	: out std_logic_vector(15 downto 0);
	outR	: out std_logic_vector(15 downto 0);
	odataoe	: out std_logic );
end entity;

architecture RTL of ayglue is
	signal odata	: std_logic_vector(7 downto 0);
	signal ctl		: std_logic_vector(2 downto 0);
	signal audio_l	: std_logic_vector(15 downto 0);
	signal audio_r	: std_logic_vector(15 downto 0);
	signal outA		: std_logic_vector(7 downto 0);
	signal outB		: std_logic_vector(7 downto 0);
	signal outC		: std_logic_vector(7 downto 0);
	signal qodataoe	: std_logic;
	signal ensel	: std_logic_vector(2 downto 0);

begin

U0: entity work.YM2149
port map (
	I_DA		=> data,
	O_DA		=> odata,
	O_DA_OE_L	=> qodataoe,

	I_A9_L		=> '0',
	I_A8		=> '1',
	I_BDIR		=> ctl(2),
	I_BC2		=> ctl(1),
	I_BC1		=> ctl(0),
	I_SEL_L		=> '1',

--	O_AUDIO
  
	O_AUDIO_A	=> outA,
	O_AUDIO_B	=> outB,
	O_AUDIO_C	=> outC,

	I_IOA		=> (others => '0'),
--	O_IOA
--	O_IOA_OE_L

	I_IOB		=> (others => '0'),
--	O_IOB
--	O_IOB_OE_L

	ENA			=> '1',
	RESET_L 	=> reset_n,
	CLK			=> clk );

process (qodataoe)
begin
	if qodataoe'event and qodataoe = '0' then
		q <= odata;
	end if;
end process;

odataoe <= qodataoe;
audio_l <= std_logic_vector ( unsigned ("000" & outA(7 downto 0) & "00000")
							+ unsigned ("000" & outB(7 downto 0) & "00000"));
audio_r <= std_logic_vector ( unsigned ("000" & outC(7 downto 0) & "00000")
							+ unsigned ("000" & outB(7 downto 0) & "00000"));

ensel <= address & wren & rden;
process (ensel, ctl)
begin
	case ensel is
		when "110" => ctl <= "001";	-- write addr
		when "010" => ctl <= "110";
		when "001" => ctl <= "011";
		when others => ctl <= "000";
	end case;
end process;

outL <= audio_l;
outR <= audio_r;

end architecture;
