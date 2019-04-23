//Modified for ReVerSE-U9 By MVV (build 20160103)

//Dmitry Tselikov (b2m) http://bashkiria-2m.narod.ru/
//Modified by Ivan Gorodetsky

module SDRAM_Controller(
	input			clk,
	input			reset,
//	inout	[15:0]	DRAM_DQ,
//	output	reg[11:0]	DRAM_ADDR,
	inout	[7:0]	DRAM_DQ,
	output	reg[12:0]	DRAM_ADDR,
	output			DRAM_LDQM,
	output			DRAM_UDQM,
	output	reg		DRAM_WE_N,
	output	reg		DRAM_CAS_N,
	output	reg		DRAM_RAS_N,
	output			DRAM_CS_N,
	output			DRAM_BA_0,
	output			DRAM_BA_1,
	input	[19:0]	iaddr,
	input	[15:0]	idata,
	input			rd,
	input			we_n,
	output	reg [15:0]	odata,
	output reg memcpubusy,
	output reg memvidbusy,
	input rdv
);

parameter ST_RESET0 = 5'd0;
parameter ST_RESET1 = 5'd1;
parameter ST_IDLE   = 5'd2;
parameter ST_RAS0   = 5'd3;
parameter ST_RAS1   = 5'd4;
parameter ST_READ0  = 5'd5;
parameter ST_READ1  = 5'd6;
parameter ST_READ2  = 5'd7;
parameter ST_READV0  = 5'd8;
parameter ST_WRITE0 = 5'd9;
parameter ST_WRITE1 = 5'd10;
parameter ST_WRITE2 = 5'd11;
parameter ST_REFRESH0 = 5'd12;
parameter ST_REFRESH1 = 5'd13;

reg[4:0] state;
reg[9:0] refreshcnt;
reg[19:0] addr;
reg[31:0] data;
reg exrd,exwen,rdvid;

assign DRAM_DQ[7:0] = state==ST_WRITE0 ? data[7:0]:8'bZZZZZZZZ;
assign DRAM_DQ[7:0] = state==ST_WRITE1 ? data[15:8]:8'bZZZZZZZZ;
assign DRAM_LDQM = 0;
assign DRAM_UDQM = 1;
assign DRAM_CS_N = reset;
assign DRAM_BA_0 = addr[18];
assign DRAM_BA_1 = addr[19];

always @(*) begin
	case (state)
//	ST_RESET0: DRAM_ADDR = 12'b100001;
//	ST_RAS0:   DRAM_ADDR = addr[17:6];
//	ST_READ0:   DRAM_ADDR = {4'b0100,addr[5:0],2'b00};
//	ST_WRITE0:   DRAM_ADDR = {4'b0100,addr[5:0],2'b00};
	ST_RESET0: DRAM_ADDR = 13'b0100001;
	ST_RAS0:   DRAM_ADDR = {1'b0,addr[17:6]};
	ST_READ0:   DRAM_ADDR = {5'b00100,addr[5:0],2'b00};
	ST_WRITE0:   DRAM_ADDR = {5'b00100,addr[5:0],2'b00};

	endcase
	case (state)
	ST_RESET0:   {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N} = 3'b000;
	ST_RAS0:     {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N} = 3'b011;
	ST_READ0:    {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N} = 3'b101;
	ST_WRITE0:   {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N} = 3'b100;
	ST_REFRESH0: {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N} = 3'b001;
	default:     {DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N} = 3'b111;
	endcase
end

always @(posedge clk) begin
	refreshcnt <= refreshcnt + 10'b1;
	if (reset) {state,exrd,exwen,rdvid,memcpubusy,memvidbusy}<={ST_RESET0,5'b01000};
	else begin
		case (state)
		ST_RESET0: state <= ST_RESET1;
		ST_RESET1: state <= ST_IDLE;
		ST_IDLE:
		begin
			addr <= iaddr; data <= idata;
			rdvid<=rdv;{memcpubusy,memvidbusy}<=2'b00;
			if(rdv==0){exrd,exwen} <= {rd,we_n};
			casex ({rd,exrd,we_n,exwen,rdv})
			5'b10110: {state,memcpubusy} <= {ST_RAS0,1'b1};
			5'b00010: {state,memcpubusy} <= {ST_RAS0,1'b1};
			5'bxxxx1: {state,memvidbusy} <= {ST_RAS0,1'b1};
			default: state <= ST_IDLE;
			endcase
		end
		ST_RAS0: state <= ST_RAS1;
		ST_RAS1:
			casex ({exrd,exwen,rdvid})
			3'b110: state <= ST_READ0;
			3'b000: state <= ST_WRITE0;
			3'bxx1: state <= ST_READ0;
			default: state <= ST_IDLE;
			endcase
		ST_READ0: state <= ST_READ1;
		ST_READ1: state <= ST_READ2;
		ST_READ2: {state,odata[7:0]} <= {rdvid?ST_READV0:ST_IDLE,DRAM_DQ[7:0]};
		ST_READV0: {state,odata[15:8]} <= {ST_REFRESH0,DRAM_DQ[7:0]};
		ST_WRITE0: state <= ST_WRITE1;
		ST_WRITE1: state <= ST_WRITE2;
		ST_WRITE2: state <= ST_IDLE;
		ST_REFRESH0: state <= ST_REFRESH1;
		ST_REFRESH1: state <= ST_IDLE;
		default: state <= ST_IDLE;
		endcase
	end
end

endmodule
