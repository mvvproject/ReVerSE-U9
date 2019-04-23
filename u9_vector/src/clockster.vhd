--// ====================================================================
--//                         VECTOR-06C FPGA REPLICA
--//
--// 				  Copyright (C) 2007-2009 Viacheslav Slavinsky
--//
--// This core is distributed under modified BSD license. 
--// For complete licensing information see LICENSE.TXT.
--// -------------------------------------------------------------------- 
--//
--// An open implementation of Vector-06C home computer
--//
--// Author: Viacheslav Slavinsky, http://sensi.org/~svo
--// 
--// Design File: clockster.v
--//
--// Vector-06C clock generator.
--//
--// --------------------------------------------------------------------
--
--`default_nettype none
--
--module clockster(clk, clk50, clk24, clk18, clk14, ce12, ce6, ce6x, ce3, video_slice, pipe_ab, ce1m5, clkpalFSC);
--input  [1:0] 	clk;
--input			clk50;
--output clk24;
--output clk18;
--output clk14;
--output ce12 = qce12;
--output ce6 = qce6;
--output ce6x = qce6x;
--output ce3 = qce3;
--output video_slice = qvideo_slice;
--output pipe_ab = qpipe_ab;
--output ce1m5 = qce1m5;
--output clkpalFSC;
--
--reg[5:0] ctr;
--reg[4:0] initctr;
--
--reg qce12, qce6, qce6x, qce3, qce3v, qvideo_slice, qpipe_ab, qce1m5;
--
--wire lock;
--wire clk13_93;
--wire clk14_00;
--wire clk14_xx;
--
--wire clk300x;
--wire clk300;
--wire clk70k9;
--
--wire clk30;
--wire clk28;
--
--mclk24mhz vector_xtal(clk50, clk24, clk300, clk28, lock);
--
--// Derive clock for PAL subcarrier: 4x 4.43361875
--`define PHACC_WIDTH 32
--`define PHACC_DELTA 253896634 
--`define PHACC_DELTA 507793268
--
--reg [`PHACC_WIDTH-1:0] pal_phase;
--wire [`PHACC_WIDTH-1:0] pal_phase_next;
--assign pal_phase_next = pal_phase + `PHACC_DELTA;
--reg palclkreg;
--
--always @(posedge clk300) begin
--	pal_phase <= pal_phase_next;
--end
--
--ayclkdrv clkbufpalfsc(pal_phase[`PHACC_WIDTH-1], clkpalFSC);
--
--`ifdef ONE_50MHZ_PLL_FOR_ALL
--
--// Make codec 18MHz
--`define COPHACC_DELTA 15729
--reg [15:0] cophacc;
--wire [15:0] cophacc_next = cophacc + `COPHACC_DELTA;
--always @(posedge clk300) cophacc <= cophacc_next;
--
--ayclkdrv clkbuf18mhz(cophacc[15], clk18);
--
--
--// phase accu doesn't work for AY, why?
--//
--// Make AY 14MHz 
--//`define AYPHACC_DELTA 12233
--//reg [15:0] ayphacc;
--//wire [15:0] ayphacc_next = ayphacc + `AYPHACC_DELTA;
--//always @(posedge clk300) ayphacc <= ayphacc_next;
--//
--//ayclkdrv clkbuf14mhz(ayphacc[15], clk14_xx);
--
--reg[5:0] div300by21;
--assign clk14 = clk14_xx; // 300/21 = 14.3MHz
--always @(posedge clk300) begin
--	div300by21 <= div300by21 + 1'b1;
--	if (div300by21+1'b1 == 21) div300by21 <= 0;
--end
--ayclkdrv clkbuf14mhz(div300by21[4], clk14_xx);
--`else 
--
--mclk14mhz audiopll(.inclk0(clk), .c0(clk14), .c1(clk18));
--
--`endif
--
--always @(posedge clk24) begin
--	if (initctr != 3) begin
--		initctr <= initctr + 1'b1;
--	end // latch
--	else begin
--		qpipe_ab <= ctr[5]; 				// pipe a/b 2x slower
--		qce12 <= ctr[0]; 					// pixel push @12mhz
--		qce6 <= ctr[1] & ctr[0];			// pixel push @6mhz
--		qce6x <= ctr[1] & ~ctr[0];          // pre-pixel push @6mhz
--		qce3 <= ctr[2] & ctr[1] & !ctr[0];
--		qvideo_slice <= !ctr[2];
--		qce1m5 <= !ctr[3] & ctr[2] & ctr[1] & !ctr[0]; 
--		ctr <= ctr + 1'b1;
--	end
--end
--endmodule
--
--// $Id: clockster.v 377 2011-03-08 11:46:05Z svofski $

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity clockst is
	port (
		clk50		: in std_logic;
		clk24		: out std_logic;
		clkdac		: out std_logic;
		clk14		: out std_logic;
		ce12		: out std_logic;
		ce6			: out std_logic;
		ce6x		: out std_logic;
		ce3			: out std_logic;
		video_slice	: out std_logic;
		pipe_ab		: out std_logic;
		ce1m5		: out std_logic;
		clkpalFSC	: out std_logic );
end entity;

architecture rtl of clockst is
	signal qpipe_ab		: std_logic;
	signal qce12		: std_logic;
	signal qce6			: std_logic;
	signal qce6x		: std_logic;
	signal qce3			: std_logic;
	signal qvideo_slice	: std_logic;
	signal qce1m5		: std_logic;
	signal ctr			: std_logic_vector(5 downto 0);
	signal qclk24		: std_logic;
	signal qclk14		: std_logic;
	signal qclkdac		: std_logic;

begin

-- PLL
U0: entity work.altpll0
port map (
	inclk0	=> clk50,
	c0		=> qclk24,
	c1		=> qclk14,
	c2		=> qclkdac);

process (qclk24)
begin
	if qclk24'event and qclk24 = '1' then
		qpipe_ab <= ctr(5); 				-- pipe a/b 2x slower
		qce12 <= ctr(0); 					-- pixel push @12mhz
		qce6 <= ctr(1) and ctr(0);			-- pixel push @6mhz
		qce6x <= ctr(1) and not ctr(0);     -- pre-pixel push @6mhz
		qce3 <= ctr(2) and ctr(1) and not ctr(0);
		qvideo_slice <= not ctr(2);
		qce1m5 <= not ctr(3) and ctr(2) and ctr(1) and not ctr(0); 
		ctr <= ctr + 1;
	end if;
end process;

ce12 <= qce12;
ce6 <= qce6;
ce6x <= qce6x;
ce3 <= qce3;
video_slice <= qvideo_slice;
pipe_ab <= qpipe_ab;
ce1m5 <= qce1m5;
clkpalFSC <= '1';
clk24 <= qclk24;
clk14 <= qclk14;
clkdac <= qclkdac;

end architecture;