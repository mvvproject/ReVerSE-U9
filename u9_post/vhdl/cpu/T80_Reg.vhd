--
-- T80 Registers, technology independent
--
-- Version : 0244
--
-- Copyright (c) 2002 Daniel Wallner (jesus@opencores.org)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-- The latest version of this file can be found at:
--	http://www.opencores.org/cvsweb.shtml/t51/
--
-- Limitations :
--
-- File history :
--
--	0242 : Initial release
--
--	0244 : Changed to single register file
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity T80_Reg is
	port(
		Clk			: in std_logic;
		CEN			: in std_logic;
		WEH			: in std_logic;
		WEL			: in std_logic;
		AddrA		: in std_logic_vector(2 downto 0);
		AddrB		: in std_logic_vector(2 downto 0);
		AddrC		: in std_logic_vector(2 downto 0);
		DIH			: in std_logic_vector(7 downto 0);
		DIL			: in std_logic_vector(7 downto 0);
		DOAH		: out std_logic_vector(7 downto 0);
		DOAL		: out std_logic_vector(7 downto 0);
		DOBH		: out std_logic_vector(7 downto 0);
		DOBL		: out std_logic_vector(7 downto 0);
		DOCH		: out std_logic_vector(7 downto 0);
		DOCL		: out std_logic_vector(7 downto 0)
	);
end T80_Reg;

architecture rtl of T80_Reg is

	signal RegsH0	: std_logic_vector (7 downto 0);
	signal RegsH1	: std_logic_vector (7 downto 0);
	signal RegsH2	: std_logic_vector (7 downto 0);
	signal RegsH3	: std_logic_vector (7 downto 0);
	signal RegsH4	: std_logic_vector (7 downto 0);
	signal RegsH5	: std_logic_vector (7 downto 0);
	signal RegsH6	: std_logic_vector (7 downto 0);
	signal RegsH7	: std_logic_vector (7 downto 0);

	signal RegsL0	: std_logic_vector (7 downto 0);
	signal RegsL1	: std_logic_vector (7 downto 0);
	signal RegsL2	: std_logic_vector (7 downto 0);
	signal RegsL3	: std_logic_vector (7 downto 0);
	signal RegsL4	: std_logic_vector (7 downto 0);
	signal RegsL5	: std_logic_vector (7 downto 0);
	signal RegsL6	: std_logic_vector (7 downto 0);
	signal RegsL7	: std_logic_vector (7 downto 0);
	
begin
	process (Clk)
	begin
		if Clk'event and Clk = '1' then
			if CEN = '1' then
				if WEH = '1' then
					case AddrA is
						when "000" => RegsH0 <= DIH;
						when "001" => RegsH1 <= DIH;
						when "010" => RegsH2 <= DIH;
						when "011" => RegsH3 <= DIH;
						when "100" => RegsH4 <= DIH;
						when "101" => RegsH5 <= DIH;
						when "110" => RegsH6 <= DIH;
						when "111" => RegsH7 <= DIH;
						when others => null;
					end case;
				end if;
				if WEL = '1' then
					case AddrA is
						when "000" => RegsL0 <= DIL;
						when "001" => RegsL1 <= DIL;
						when "010" => RegsL2 <= DIL;
						when "011" => RegsL3 <= DIL;
						when "100" => RegsL4 <= DIL;
						when "101" => RegsL5 <= DIL;
						when "110" => RegsL6 <= DIL;
						when "111" => RegsL7 <= DIL;
						when others => null;
					end case;
				end if;
			end if;
		end if;
		
		case AddrA is
			when "000" =>
				DOAH <= RegsH0;
				DOAL <= RegsL0;
			when "001" =>	
				DOAH <= RegsH1;
				DOAL <= RegsL1;
			when "010" =>
				DOAH <= RegsH2;
				DOAL <= RegsL2;
			when "011" =>
				DOAH <= RegsH3;
				DOAL <= RegsL3;
			when "100" =>
				DOAH <= RegsH4;
				DOAL <= RegsL4;
			when "101" =>
				DOAH <= RegsH5;
				DOAL <= RegsL5;
			when "110" =>
				DOAH <= RegsH6;
				DOAL <= RegsL6;
			when "111" =>
				DOAH <= RegsH7;
				DOAL <= RegsL7;
			when others => null;
		end case;
		
		case AddrB is
			when "000" =>
				DOBH <= RegsH0;
				DOBL <= RegsL0;
			when "001" =>	
				DOBH <= RegsH1;
				DOBL <= RegsL1;
			when "010" =>
				DOBH <= RegsH2;
				DOBL <= RegsL2;
			when "011" =>
				DOBH <= RegsH3;
				DOBL <= RegsL3;
			when "100" =>
				DOBH <= RegsH4;
				DOBL <= RegsL4;
			when "101" =>
				DOBH <= RegsH5;
				DOBL <= RegsL5;
			when "110" =>
				DOBH <= RegsH6;
				DOBL <= RegsL6;
			when "111" =>
				DOBH <= RegsH7;
				DOBL <= RegsL7;
			when others => null;
		end case;
		
		case AddrC is
			when "000" =>
				DOCH <= RegsH0;
				DOCL <= RegsL0;
			when "001" =>	
				DOCH <= RegsH1;
				DOCL <= RegsL1;
			when "010" =>
				DOCH <= RegsH2;
				DOCL <= RegsL2;
			when "011" =>
				DOCH <= RegsH3;
				DOCL <= RegsL3;
			when "100" =>
				DOCH <= RegsH4;
				DOCL <= RegsL4;
			when "101" =>
				DOCH <= RegsH5;
				DOCL <= RegsL5;
			when "110" =>
				DOCH <= RegsH6;
				DOCL <= RegsL6;
			when "111" =>
				DOCH <= RegsH7;
				DOCL <= RegsL7;
			when others => null;
		end case;
	
	end process;
end;
