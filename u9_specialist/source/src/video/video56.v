//Based on
//Spetsialist_MX_FPGA  beta version
//31/01/2012
//Fifan, Ewgeny7, HardWareMan
//www.zx.pk.ru
//www.spetsialist-mx.ru

//Ivan Gorodetsky 2014-2015

`default_nettype none

module spec_video56(
input clkVid,
input [15:0] vdata,
output [13:0] vram,
output reg hsync,
output reg vsync,
output reg[4:0] red,
output reg[5:0] green,
output reg[4:0] blue,
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
 if(hcnt==9'd511) hcnt<=9'd32;
 else hcnt<=hcnt+1;

 if(hcnt==9'd55) hsync<=1'b0;
 else if(hcnt==9'd87) hsync<=1'b1;

 if(vcnt[9:1]==9'd271) vsync<=1'b0;
 else if(vcnt[9:1]==9'd275) vsync<=1'b1;

 if(hcnt>=9'd128&&hcnt<=9'd511&&vcnt[9]==1'b0) screen_pre<=1'b1;
 else screen_pre<=1'b0;

 if(hcnt[2:0]==3'b000) rdvid<=1'b1;
 else rdvid<=1'b0;

 if(hcnt[2:0]==3'b111) begin
  vid_bw<=vdata[7:0];
  vid_c<=vdata[10:8];
  screen<=screen_pre;
 end
 
 if(screen==1'b1)
  if(vid_pix==1'b1) {r,g,b}<={vid_c[0],vid_c[1],vid_c[2]};
  else {r,g,b}<=3'b000;
  else {r,g,b}<=3'b000;
end
 
always@(negedge hcnt[8])
 if(vcnt[9:1]==9'd300) vcnt<=10'd0;
 else vcnt<=vcnt+1;

always@(negedge clkVid) begin
 red<={r,r,r,r,r};
 green<={g,g,g,g,g,g};
 blue<={b,b,b,b,b};
end


endmodule