//Based on
//Spetsialist_MX_FPGA  beta version
//31/01/2012
//Fifan, Ewgeny7, HardWareMan
//www.zx.pk.ru
//www.spetsialist-mx.ru

//Ivan Gorodetsky 2014-2015

//Choose your CPU
//Default (without define) - T80
//`define CPU_B2M
//`define CPU_VSLAV

//Choose frame rate
//Default (without define) - 50 Hz
//`define FR56HZ

`default_nettype none

module spec(
		  input clock_48,
		  input clock_64,
		  input clock_128,
        inout ps2_clk,
        inout ps2_data,
		  
		  input [3:0] hardware_keys,

        output [7:0] dataWr,
        input [7:0] dataRd,
        input [15:0] vdataRd,
        output [7:0] vdataWr,
        input [7:0] sdRd,

        output hsync,
        output vsync,
        output [4:0] red,
        output [5:0] green,
        output [4:0] blue,
        output [3:0] tv_Y,
        output [3:0] tv_Pb,
        output [3:0] tv_Pr,
		  output [4:0] tv_cvbs,
		  output [4:0] tv_luma,
		  output [4:0] tv_chroma_o,

		  output rdvid,
        output [13:0] vadr,
        output [13:0] vadrTV,
		  
        output sound,
        input tapein,
                    
        output [15:0] adr,
        output ram_oe,
        output ram_we,
        output led_red,
        output led_green,
		  output reset_n
);

assign dataWr=dataO;
assign vdataWr[2:0]=clrdata[2:0];
assign sound=beep;
assign adr=a_buff;
assign ram_oe=rd_n;
assign ram_we=wr_n;
assign reset_n=start?1'b0:res_n;

wire clock_16=div[1];
wire clkPhAcc;
assign clkPhAcc = clock_128;
wire res_k;
reg [4:0] div;
reg [7:0] dataI;
wire [7:0] dataO;
wire [15:0] a_buff;
wire wr_n;
wire rd_n=!rd;
wire rd;
wire [7:0] romdata;
wire rom_sel=(a_buff[15:13]==3'b110)||(a_buff[15:12]==4'b1110);
wire u7=a_buff[15:11]==5'b11111;
wire u7wr=u7&~wr_n;
wire u7rd=u7&~rd_n;

wire sd=(a_buff[15:0]==16'hF700)||(a_buff[15:0]==16'hF701);
wire sdrd=sd&~rd_n;

wire res_n=!res_k;
wire clk_cpu=turbo?(div[4:0]==5'b11001)||(div[4:0]==5'b01110):div[4:0]==5'b11001;
wire clk_cpuVS=div[4:0]==5'b11001;
wire [11:0] kbscan_in=kbmethod?{6'b111111,portb1[7:2]}:{portc1,porta1};
wire [11:0] kbscan_out;
wire kbshift;
reg kbmethod;
reg [7:0] porta;
reg [7:0] porta1;
reg [7:0] portb;
reg [7:0] portb1;
reg [3:0] portc;
reg [3:0] portc1;
reg [7:0] portr;
reg beep;
reg [2:0] clrdata;
wire turbo_key;
wire turbo=turbo_key;
wire ruslat=rs_lt_key;
wire rs_lt_key;
reg startup=1;

reg start;
reg [4:0] delay=5'd0;
always@(posedge clock_16) 
begin
 if(delay<16) begin delay <= delay + 1; start<=1'b1; end
 else begin start<=1'b0; end
end

always @(posedge clock_64) div<=div+1;

always @(negedge reset_n or posedge clock_64)
 if (reset_n==1'b0) begin
  porta<=8'h00;
  portb<=8'h00;
  portc<=4'h0;
  portr<=8'h00;
  clrdata<=3'b111;
  startup<=1'b1;
 end
 else if(u7wr==1'b1)
 begin
  case(a_buff[1:0])
  2'b00:porta<=dataO;
  2'b01:portb<=dataO;
  2'b10:begin
   portc<=dataO[3:0];
	clrdata<={~dataO[4],~dataO[6],~dataO[7]};
	beep<=~dataO[5];
  end
  2'b11:begin
   portr<=dataO;
	startup<=1'b0;
   if(dataO[7]==1'b0 && dataO[3:1]==3'b101) beep<=~dataO[0];
  end
  endcase
 end

always @(negedge reset_n or posedge clock_64)
begin
 if (reset_n==1'b0) begin
  porta1<=8'hff;
  portb1<=8'hff;
  portc1<=4'hf;
 end
 else begin
  if(portr[4]==1'b0)
  begin
   portc1<=portc;porta1<=porta;
  end
  else begin
   portc1<=4'b1111;porta1<=8'b11111111;
  end 
  if(portr[1]==1'b0) portb1[7:2]<=portb[7:2];
  else portb1[7:2]<=6'b111111;
 end
end

always@(posedge clock_64)
begin
 if(rom_sel==1'b1) dataI<=romdata;
 else if(sdrd==1'b1) dataI<=sdRd;
 else if(u7rd==1'b1) begin
  case(a_buff[1:0])
   2'b00:begin
	 dataI<=kbscan_out[7:0];
	 kbmethod<=1'b1;
	end
	2'b01:begin
	 dataI<={kbscan_out[5:0],~kbshift,tapein};
	 kbmethod<=1'b0;
	end
	2'b10:begin
	 dataI<={4'b0000,kbscan_out[11:8]};
	 kbmethod<=1'b1;
	end
	2'b11:dataI<=portr;
  endcase
 end
 else
 if(startup==1'b1) dataI<=romdata;
 else dataI<=dataRd;
end

`ifdef CPU_B2M
k580wm80a(
	.clk(clock_64),
	.ce(clk_cpu),
	.reset(~reset_n),
	.idata(dataI),
	.addr(a_buff),
	.rd(rd),
	.wr_n(wr_n),
	.odata(dataO),
	);
`else
`ifdef CPU_VSLAV
vm80a_core
(
	.pin_clk(clock_64),
	.pin_f1(clk_cpuVS),
	.pin_f2(~clk_cpuVS),
	.pin_reset(~reset_n),
	.pin_a(a_buff),
	.pin_dout(dataO),
	.pin_din(dataI),
	.pin_ready(1'b1),
	.pin_dbin(rd),
	.pin_wr_n(wr_n)
);
`else
T8080se (
            .RESET_n(reset_n),
            .CLK(clock_64),
            .CLKEN(clk_cpu),
            .READY(1'b1),
            .DBIN(rd),
            .WR_n(wr_n),
            .A(a_buff),
            .DI(dataI),
            .DO(dataO)
    );
`endif
`endif

lpm_dos1 (
            .address(a_buff[12:0]),
            .clock(~clock_64),
            .q(romdata)
    );

spetskeyboard (
            .clk(clock_64),
            .reset(~reset_n),
				.hardware_keys(hardware_keys),
            .res_k(res_k),
            .metod(kbmethod),
            .ps2_clk(ps2_clk),
            .ps2_data(ps2_data),
            .sp_kb_scan(kbscan_in),
            .mode(1'b0),
            .rus_lat(ruslat),
            .sp_kb_out(kbscan_out),
            .key_ss(kbshift),
            .ruslat_k(rs_lt_key),
            .turbo_k(turbo_key)
);

`ifdef FR56HZ
spec_video56(
`else
spec_video(
.tv_Y(tv_Y),
.tv_Pb(tv_Pb),
.tv_Pr(tv_Pr),
`endif

.clkVid(clock_16),
.vdata(vdataRd),
.vram(vadr),
.hsync(hsync),
.vsync(vsync),
.red(red),
.green(green),
.blue(blue),
.rdvid(rdvid)
);

spec_videoTV(
.clkVid(clock_16),
.clkPhAcc(clkPhAcc),
.vdata(vdataRd),
.vram(vadrTV),
.tv_cvbs(tv_cvbs),
.tv_luma(tv_luma),
.tv_chroma_o(tv_chroma_o)
);

endmodule
