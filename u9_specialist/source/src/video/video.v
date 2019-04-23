//Based on
//Spetsialist_MX_FPGA  beta version
//31/01/2012
//Fifan, Ewgeny7, HardWareMan
//www.zx.pk.ru
//www.spetsialist-mx.ru

//Ivan Gorodetsky 2014-2015

`default_nettype none

module spec_video(
input clkVid,
input [15:0] vdata,
output [13:0] vram,
output reg hsync,
output reg vsync,
output reg[4:0] red,
output reg[5:0] green,
output reg[4:0] blue,
output reg[3:0] tv_Y,
output reg[3:0] tv_Pb,
output reg[3:0] tv_Pr,
output reg rdvid
);

reg [8:0] hcnt;
reg [9:0] vcnt;
reg screen_pre;
reg screen;
reg [7:0] vid_bw;
reg [2:0] vid_c;
wire vid_pix=vid_bw[~hcnt[2:0]];
reg r,g,b;

assign vram={hcnt[8:3],vcnt[8:1]};

always@(posedge clkVid)
begin
 hcnt<=hcnt+1;

 if(hcnt==9'd29) hsync<=1'b0;
 else if(hcnt==9'd87) hsync<=1'b1;

 if(vcnt[9:1]==9'd278) vsync<=1'b0;
 else if(vcnt[9:1]==9'd282) vsync<=1'b1;

 if(hcnt>=9'd128&&hcnt<=9'd511&&vcnt[9]==1'b0) screen_pre<=1'b1;
 else screen_pre<=1'b0;

 if(hcnt[2:0]==3'b000) rdvid<=1'b1;
 else rdvid<=1'b0;

 if(hcnt[2:0]==3'b111) begin
  vid_bw<=vdata[7:0];
  vid_c<=vdata[10:8];
  screen<=screen_pre;
 end

 if(hcnt==9'd0)
 if(vcnt[9:1]==10'd311) vcnt<=10'd0;
 else vcnt<=vcnt+1;
 
 if(screen==1'b1)
  if(vid_pix==1'b1) {r,g,b}<={vid_c[0],vid_c[1],vid_c[2]};
  else {r,g,b}<=3'b000;
  else {r,g,b}<=3'b000;
end

wire[3:0] truecolor_R={{3{vid_pix?vid_c[0]:1'b0}},1'b0};
wire[3:0] truecolor_G={{3{vid_pix?vid_c[1]:1'b0}},1'b0};
wire[3:0] truecolor_B={{3{vid_pix?vid_c[2]:1'b0}},1'b0};
parameter V_SYNC = 0;
parameter PbPr_REF  = 4'd8;
parameter Y_REF  = 4'd2;
wire[11:0] tv_Y_=8'd69*truecolor_R+8'd135*truecolor_G+8'd26*truecolor_B;
wire[11:0] tv_Pb_={PbPr_REF,8'b0}-8'd39*truecolor_R-8'd77*truecolor_G+8'd116*truecolor_B;
wire[11:0] tv_Pr_={PbPr_REF,8'b0}+8'd115*truecolor_R-8'd96*truecolor_G-8'd19*truecolor_B;


always@(negedge clkVid) begin
	casex({vsync,hsync,screen})
	3'b0xx:begin
	tv_Y <= V_SYNC;
	tv_Pb <=PbPr_REF;
	tv_Pr <=PbPr_REF;
	end
	3'b10x:begin
	tv_Y <= V_SYNC;
	tv_Pb <=PbPr_REF;
	tv_Pr <=PbPr_REF;
	end
	3'b111:begin
	tv_Y <=tv_Y_[7]?Y_REF+tv_Y_[11:8]+1:Y_REF+tv_Y_[11:8];
	tv_Pb <=tv_Pb_[7]?tv_Pb_[11:8]+1:tv_Pb_[11:8];
	tv_Pr <=tv_Pr_[7]?tv_Pr_[11:8]+1:tv_Pr_[11:8];
	end
	3'b110:begin
	tv_Y <= Y_REF;
	tv_Pb <=PbPr_REF;
	tv_Pr <=PbPr_REF;
	end
	endcase
end

always@(negedge clkVid) begin
 red<={r,r,r,r,r,1'b0};
 green<={g,g,g,g,g,g,1'b0};
 blue<={b,b,b,b,b,1'b0};
end
 

endmodule