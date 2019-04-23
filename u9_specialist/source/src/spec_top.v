//Modified for ReVerSE-U9 By MVV (build 20160114)
// 20160103	ReVerSE-U9 Port
// 20160114	BIOS-SD Corrected By ivagor

//Ivan Gorodetsky 2014-2015
//SD Card "hard" and soft - Dmitry Tselikov (b2m) http://bashkiria-2m.narod.ru/

module spec_top(
			////////////////////	Clock Input	 	////////////////////	 
		clk48mhz,						//	50 MHz
		////////////////////	Push Button		////////////////////
		KEY,							//	Pushbutton
		/////////////////////	SDRAM Interface		////////////////
		DRAM_DQ,						//	SDRAM Data bus
		DRAM_ADDR,						//	SDRAM Address bus
		DRAM_LDQM,						//	SDRAM Low-byte Data Mask 
//		DRAM_UDQM,						//	SDRAM High-byte Data Mask
		DRAM_WE_N,						//	SDRAM Write Enable
		DRAM_CAS_N,						//	SDRAM Column Address Strobe
		DRAM_RAS_N,						//	SDRAM Row Address Strobe
//		DRAM_CS_N,						//	SDRAM Chip Select
		DRAM_BA_0,						//	SDRAM Bank Address 0
		DRAM_BA_1,						//	SDRAM Bank Address 0
		DRAM_CLK,						//	SDRAM Clock
		DRAM_CKE,						//	SDRAM Clock Enable
		////////////////////	SD_Card Interface	////////////////
		SD_DAT,							//	SD Card Data
		SD_DAT3,						//	SD Card Data 3
		SD_CMD,							//	SD Card Command Signal
		SD_CLK,							//	SD Card Clock
		////////////////////	PS2		////////////////////////////
		PS2_DAT,						//	PS2 Data
		PS2_CLK,						//	PS2 Clock
		////////////////////	VGA		////////////////////////////
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_R,   						//	VGA Red
		VGA_G,	 						//	VGA Green
		VGA_B,  						//	VGA Blue

		TAPEIN,
		
		DAC_BCK,
		DAC_WS,
		DAC_DATA
//		BEEP							// BEEPER
	);

////////////////////////	Clock Input	 	////////////////////////
input			clk48mhz;				//	50 MHz
////////////////////////	Push Button		////////////////////////
//input	[3:0]	KEY;					//	Pushbutton[3:0]
input		KEY;					//	Pushbutton[3:0]
////////////////////////	DPDT Switch		////////////////////////
reg	[9:0]	SW;						//	Toggle Switch[9:0]
///////////////////////		SDRAM Interface	////////////////////////
//inout	[15:0]	DRAM_DQ;				//	SDRAM Data bus 16 Bits
//output	[11:0]	DRAM_ADDR;				//	SDRAM Address bus 12 Bits
inout	[7:0]	DRAM_DQ;				//	SDRAM Data bus 16 Bits
output	[12:0]	DRAM_ADDR;				//	SDRAM Address bus 12 Bits
output		DRAM_LDQM;				//	SDRAM Low-byte Data Mask 
//output	DRAM_UDQM;				//	SDRAM High-byte Data Mask
output		DRAM_WE_N;				//	SDRAM Write Enable
output		DRAM_CAS_N;				//	SDRAM Column Address Strobe
output		DRAM_RAS_N;				//	SDRAM Row Address Strobe
//output		DRAM_CS_N;				//	SDRAM Chip Select
output		DRAM_BA_0;				//	SDRAM Bank Address 0
output		DRAM_BA_1;				//	SDRAM Bank Address 0
output		DRAM_CLK;				//	SDRAM Clock
output		DRAM_CKE;				//	SDRAM Clock Enable
////////////////////	SD Card Interface	////////////////////////
inout		SD_DAT;					//	SD Card Data
inout		SD_DAT3;				//	SD Card Data 3
inout		SD_CMD;					//	SD Card Command Signal
output		SD_CLK;					//	SD Card Clock
////////////////////////	PS2		////////////////////////////////
inout		PS2_DAT;				//	PS2 Data
inout		PS2_CLK;				//	PS2 Clock
////////////////////////	VGA			////////////////////////////
output		VGA_HS;					//	VGA H_SYNC
output		VGA_VS;					//	VGA V_SYNC
//output	[4:0]	VGA_R;   				//	VGA Red[3:0]
//output	[5:0]	VGA_G;	 				//	VGA Green[3:0]
//output	[4:0]	VGA_B;   				//	VGA Blue[3:0]
output	[2:0]	VGA_R;   				//	VGA Red[3:0]
output	[2:0]	VGA_G;	 				//	VGA Green[3:0]
output	[2:0]	VGA_B;   				//	VGA Blue[3:0]

input		TAPEIN;

output		DAC_BCK;
output		DAC_WS;
output		DAC_DATA;

//output		BEEP;						// buzzer

`default_nettype none 


wire clk64;
wire clk24;
wire clk128;
wire rdvid;

// altpll here
altpll0 (
        .inclk0(clk48mhz),
	.c0(clk24),
	.c1(clk_dac)
    );

altpll1 (
	.inclk0(clk24),
	.c0(clk128),
	.c1(clk64)
);
	 
spec(
	.clock_48(clk48mhz),
	.clock_64(clk64),
	.clock_128(clk128),
        .ps2_clk(PS2_CLK),
        .ps2_data(PS2_DAT),

//	.hardware_keys(KEY),
	.hardware_keys({KEY,3'b11}),
		  
        .hsync(hsync),
        .vsync(vsync),
        .red(red),
        .green(green),
        .blue(blue),
        .tv_Y(tv_Y),
        .tv_Pb(tv_Pb),
        .tv_Pr(tv_Pr),
	.tv_cvbs(tv_cvbs),
	.tv_luma(tv_luma),
	.tv_chroma_o(tv_chroma_o),

	.vadr(vadr),
	.vadrTV(vadrTV),
	.rdvid(rdvid),

        .sound(sound),
	.tapein(TAPEIN),
                    
        .dataWr(data),
        .dataRd(dataR),
	.vdataRd(vdata),
	.vdataWr(vdataw),
        .adr(adr),
        .ram_oe(oe_n),
        .ram_we(we_n),
	.sdRd(sd_o),

//	.led_red(LEDR[0]),
//      .led_green(LEDG[0]),
	.reset_n(reset_n)
);

wire reset_n;
wire reset=~reset_n;
wire we_n,oe_n;
wire [15:0] adr;
wire [13:0] vadr,vadrTV;
wire [13:0] vramadr=tvmode[0]?vadrTV:vadr;
wire [7:0] data;
wire [7:0] vdataw;
wire [15:0] sdramout;
reg [7:0] dataR;
reg [15:0] vdata;
wire memcpubusy,memvidbusy;

assign DRAM_CLK=clk64;
assign DRAM_CKE=1;
SDRAM_Controller (
	.clk(clk64),
	.reset(~reset_n),
	.DRAM_DQ(DRAM_DQ),
	.DRAM_ADDR(DRAM_ADDR),
	.DRAM_LDQM(DRAM_LDQM),
//	.DRAM_UDQM(DRAM_UDQM),
	.DRAM_UDQM(),
	.DRAM_WE_N(DRAM_WE_N),
	.DRAM_CAS_N(DRAM_CAS_N),
	.DRAM_RAS_N(DRAM_RAS_N),
//	.DRAM_CS_N(DRAM_CS_N),
	.DRAM_CS_N(),
	.DRAM_BA_0(DRAM_BA_0),
	.DRAM_BA_1(DRAM_BA_1),
	.iaddr(rdvid?{2'b10,vramadr[13:0]}:adr),
	.idata({vdataw,data}),
	.rd(~oe_n),
	.we_n(rdvid?1'b1:we_n),
	.odata(sdramout),
	.memcpubusy(memcpubusy),
	.memvidbusy(memvidbusy),
	.rdv(rdvid)
);
always@(negedge memcpubusy) dataR<=sdramout[7:0];
always@(negedge memvidbusy) vdata<=sdramout;

wire vsync,hsync;
wire [4:0] red;
wire [5:0] green;
wire [4:0] blue;
wire [3:0] tv_Y,tv_Pb,tv_Pr;
wire [4:0] tv_cvbs,tv_luma,tv_chroma_o;
assign VGA_HS=hsync;
assign VGA_VS=vsync;
wire [1:0] tvmode=SW[1:0];
//assign VGA_R=tvmode[0]?tv_cvbs[4:1]:tvmode[1]?tv_Pr:red;
//assign VGA_G=tvmode[0]?tv_luma[4:1]:tvmode[1]?tv_Y:green;
//assign VGA_B=tvmode[0]?tv_chroma_o[4:1]:tvmode[1]?tv_Pb:blue;
assign VGA_R=red[2:0];
assign VGA_G=green[2:0];
assign VGA_B=blue[2:0];


////////////////////   SD CARD   ////////////////////
reg sdcs;
reg sdclk;
reg sdcmd;
reg[6:0] sddata;
wire[7:0] sd_o = {sddata, SD_DAT};

assign SD_DAT3 = ~sdcs;
assign SD_CMD = sdcmd;
assign SD_CLK = sdclk;

always @(posedge clk64 or posedge reset) begin
	if (reset) begin
		sdcs <= 1'b0;
		sdclk <= 1'b0;
		sdcmd <= 1'h1;
	end else begin
		if (adr[15:0]==16'hF700 && ~we_n) sdcs <= data[0];
		if (adr[15:0]==16'hF701 && ~we_n) begin
			if (sdclk) sddata <= {sddata[5:0],SD_DAT};
			sdcmd <= data[7];
			sdclk <= 1'b0;
		end
		if (~oe_n) sdclk <= 1'b1;
	end
end

////////////////////   SOUND   ////////////////////
wire sound,tapein;

//soundcodec snd(
//	.clk(clk64),
//	.pulse(sound),
//	.reset_n(reset),
//	.o_pwm(BEEP)
//);
wire clk_dac;
tda1543 (
	.RESET	(~reset_n),
	.CLK	(clk_dac),
	.CS	(1'b1),
	.DATA_L	({sound,15'b0}),
	.DATA_R	({sound,15'b0}),
	.BCK	(DAC_BCK),
	.WS	(DAC_WS),
	.DATA	(DAC_DATA)
);

endmodule
