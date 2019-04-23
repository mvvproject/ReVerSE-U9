// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
// 					Copyright (C) 2007, Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Design File: oneshot.v
//
// A parametric one-shot with sampling trigger and clock enable.
//
// --------------------------------------------------------------------

module oneshot(clk, ce, trigger, q);
parameter CLOCKS = 8'd16;
input 		clk;
input 		ce;
input 		trigger;
output reg 	q;

reg [8:0] n_shot;
reg trigsample;

always @(posedge clk) begin
	if (ce) begin
		trigsample <= trigger;
		if (~trigsample & trigger) begin
			q <= 1'b1;
			n_shot <= CLOCKS;
		end else begin
			if (q) n_shot <= n_shot - 1'b1;
			if (n_shot == 0) q <= 1'b0;
		end
	end
end
endmodule

// $Id: oneshot.v 85 2007-12-24 04:17:00Z svofski $
