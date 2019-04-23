//PAL coder based on v06cc (https://code.google.com/p/vector06cc/) by Viacheslav Slavinsky, http://sensi.org/~svo


//Based on
//Spetsialist_MX_FPGA  beta version
//31/01/2012
//Fifan, Ewgeny7, HardWareMan
//www.zx.pk.ru
//www.spetsialist-mx.ru

//Ivan Gorodetsky 2014-2015

`default_nettype none

module spec_videoTV(
input clkVid,
input clkPhAcc,
input [15:0] vdata,
output [13:0] vram,
output reg[4:0] tv_cvbs,
output reg[4:0] tv_luma,
output reg[4:0] tv_chroma_o
);

reg hsync,vsync;
reg [8:0] hcnt;
reg [8:0] vcnt;
reg screen_pre;
reg screen;
reg [7:0] vid_bw;
reg [2:0] vid_c;
wire vid_pix=vid_bw[~hcnt[2:0]];
reg [31:0] PhAcc;
wire clkPAL8=PhAcc[31];
reg field;

assign vram={hcnt[8:3],{vcnt[7:0]-8'd41}};

always@(posedge clkPhAcc) PhAcc=PhAcc+595070235;

reg [1:0] clkTV;
always@(posedge clkPAL8) clkTV=clkTV+1;
reg clkVid2;
always@(posedge clkVid) clkVid2=~clkVid2;

always@(posedge clkVid2)
begin
 hcnt<=hcnt+1;

 if(vcnt>=9'd0&&vcnt<=9'd1)
	if((hcnt>=9'd35&&hcnt<=9'd252)||(hcnt>=9'd290&&hcnt<=9'd507))hsync<=1'b0;
	else hsync<=1'b1;
 else if(vcnt==9'd2)
	if((hcnt>=9'd35&&hcnt<=9'd252)||(hcnt>=9'd290&&hcnt<=9'd308))hsync<=1'b0;
	else hsync<=1'b1;
 else if((vcnt>=9'd3&&vcnt<=9'd4)||(vcnt>=9'd309&&vcnt<=9'd311))
	if((hcnt>=9'd35&&hcnt<=9'd53)||(hcnt>=9'd290&&hcnt<=9'd308))hsync<=1'b0;
	else hsync<=1'b1;
 else if(vcnt>=9'd5&&vcnt<=9'd308)
	if(hcnt>=9'd35&&hcnt<=9'd72)hsync<=1'b0;
	else hsync<=1'b1;

 if(hcnt==9'd34)
 	if(vcnt==9'd311) begin
		vcnt<=9'd0;
		field<=~field;
	end
	else vcnt<=vcnt+1;
 if(vcnt>=9'd23&&vcnt<=9'd308)
	if(hcnt>=9'd80&&hcnt<=9'd97) tv_colorburst<=1'b1;
	else tv_colorburst<=1'b0;

 if(hcnt>=9'd128&&hcnt<=9'd511&&(vcnt>=9'd41&&vcnt<=9'd296)) screen_pre<=1'b1;
 else screen_pre<=1'b0;

 if(hcnt[2:0]==3'b111) begin
  vid_bw<=vdata[7:0];
  vid_c<=vdata[10:8];
  screen<=screen_pre;
 end
end

wire r=vid_pix?vid_c[0]:1'b0;
wire g=vid_pix?vid_c[1]:1'b0;
wire b=vid_pix?vid_c[2]:1'b0;

parameter V_SYNC = 0;
wire [3:0] truecolor_R = {r,r,r,1'b0};
wire [3:0] truecolor_G = {g,g,g,1'b0};
wire [3:0] truecolor_B = {b,b,b,1'b0};
reg signed [7:0] tv_chroma;

parameter V_REF  = 8;
wire [5:0] cvbs_unclamped = V_REF + tvY[4:0] + $signed(tv_chroma[4:1]);
wire [4:0] cvbs_clamped = cvbs_unclamped[4:0];
wire tv_sync=hsync;
always @*
    casex ({tv_sync,tv_colorburst,screen})
    3'b0xx: tv_cvbs <= V_SYNC;
	 3'b110:	tv_cvbs <= V_REF-2+(tv_sin>>1);
    3'b101: tv_cvbs <= cvbs_clamped;
    default:tv_cvbs <= V_REF; 
    endcase

wire [4:0] luma_unclamped = V_REF + tvY;
wire [4:0] luma_clamped = luma_unclamped[4:0];

wire [4:0] chroma_clamped;
chroma_shift(.chroma_in(tv_chroma), .chroma_out(chroma_clamped));

always @*
    casex ({tv_sync,screen})
    2'b0x: tv_luma <= V_SYNC;
    2'b11: tv_luma <= luma_clamped; 
    default:  tv_luma <= V_REF;
    endcase

always @*
    casex ({tv_sync,tv_colorburst,screen})
    3'b0xx:tv_chroma_o <= 16;
    3'b110:tv_chroma_o <= 12+tv_sin;
    3'b101:tv_chroma_o <= chroma_clamped;
    default:tv_chroma_o <= 16;
    endcase

always @*
 case (vcnt[0])
  0: tv_chroma <= tvUV[tv_phase45[2:0]];
  1: tv_chroma <= tvUW[tv_phase45[2:0]];
 endcase 

reg [2:0] tv_phase45  = 1;
reg [2:0] tv_phase180 = 4;
reg [2:0] tv_phase270 = 6;

reg tv_colorburst;

always @(posedge clkPAL8) begin
    tv_phase45 <= tv_phase45 + 2;
    tv_phase180 <= tv_phase180 + 2;
    tv_phase270 <= tv_phase270 + 2;
end

wire [7:0] tv_sin180;
wire [7:0] tv_sin270;
wire [7:0] tv_sin = vcnt[0] ? tv_sin270 : tv_sin180;

sinrom sinA(tv_phase180[2:0], tv_sin180);
sinrom sinB(tv_phase270[2:0], tv_sin270);

wire [7:0] tvY;
wire [13:0] tvY1;
wire [13:0] tvY2;
wire [13:0] tvY3;

wire [13:0] tvUV[7:0];
wire [13:0] tvUW[7:0];

assign tvY1 = 8'h18 * truecolor_R; 
assign tvY2 = 8'h2f * truecolor_G; 
assign tvY3 = 8'h09 * truecolor_B; 
wire [13:0] tvY_ = tvY1 + tvY2 + tvY3;
assign tvY = tvY_[12:6]; 
uvsum #(    52,   -89,    37) (truecolor_R, truecolor_G, truecolor_B, tvUV[1]);
uvsum #(   -84,    25,    59) (truecolor_R, truecolor_G, truecolor_B, tvUV[3]);
uvsum #(   -52,    89,   -37) (truecolor_R, truecolor_G, truecolor_B, tvUV[5]);
uvsum #(    84,   -25,   -59) (truecolor_R, truecolor_G, truecolor_B, tvUV[7]);

uvsum #(   -84,    25,    59) (truecolor_R, truecolor_G, truecolor_B, tvUW[1]);
uvsum #(    52,   -89,    37) (truecolor_R, truecolor_G, truecolor_B, tvUW[3]);
uvsum #(    84,   -25,   -59) (truecolor_R, truecolor_G, truecolor_B, tvUW[5]);
uvsum #(   -52,    89,   -37) (truecolor_R, truecolor_G, truecolor_B, tvUW[7]);
endmodule

module uvsum(input signed [7:0] R, input signed [7:0] G, input signed [7:0] B, output signed [7:0] uvsum);
parameter signed c1,c2,c3;
wire signed [13:0] c01 = c1 * R;
wire signed [13:0] c02 = c2 * G;
wire signed [13:0] c03 = c3 * B;
wire signed [13:0] s = c01 + c02 + c03;
assign uvsum = s[13:7];
endmodule

module sinrom(input [2:0] adr, output reg [7:0] s); 
always @*
	case (adr)
0: s <= 4;
1: s <= 6;
2: s <= 8;
3: s <= 6;
4: s <= 4;
5: s <= 2;
6: s <= 0;
7: s <= 2;
	endcase
endmodule

module chroma_shift(input [7:0] chroma_in, output reg [4:0] chroma_out);
    always @*
        chroma_out <= 16 + chroma_in;
endmodule
