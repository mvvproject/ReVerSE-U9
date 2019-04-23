-------------------------------------------------------------------------------------
--
--                                 SID 6581 (voice)
--
--     This piece of VHDL code describes a single SID voice (sound channel)
--
-------------------------------------------------------------------------------------
--	to do:	- better resolution of result signal voice, this is now only 12bits, but it could be 20 !! Problem, it does not fit the PWM-dac
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

-------------------------------------------------------------------------------------

entity sid_voice is
	port (
		clk_1MHz		: in std_logic;							-- this line drives the oscilator
		reset			: in std_logic;							-- active high signal (i.e. registers are reset when reset=1)
		Freq_lo		: in std_logic_vector(7 downto 0);	-- low-byte of frequency register 
		Freq_hi		: in std_logic_vector(7 downto 0);	--	high-byte of frequency register 
		Pw_lo			: in std_logic_vector(7 downto 0);	--	low-byte of PuleWidth register
		Pw_hi			: in std_logic_vector(3 downto 0);	--	high-nibble of PuleWidth register
		Control		: in std_logic_vector(7 downto 0);	--	control register
		Att_dec		: in std_logic_vector(7 downto 0);	--	attack-deccay register
		Sus_Rel		: in std_logic_vector(7 downto 0);	--	sustain-release register
		PA_MSB_in	: in std_logic;							--	Phase Accumulator MSB input
		PA_MSB_out	: out std_logic;							--	Phase Accumulator MSB output
		Osc			: out std_logic_vector(7 downto 0);	--	Voice waveform register
		Env			: out std_logic_vector(7 downto 0);	--	Voice envelope register
		voice			: out std_logic_vector(11 downto 0)	--	Voice waveform, this is the actual audio signal
	);
end sid_voice;


architecture Behavioral of sid_voice is	

-------------------------------------------------------------------------------------

	COMPONENT lpm_mult
	GENERIC
	(
		lpm_hint		: STRING;
		lpm_representation		: STRING;
		lpm_type		: STRING;
		lpm_widtha		: NATURAL;
		lpm_widthb		: NATURAL;
		lpm_widthp		: NATURAL;
		lpm_widths		: NATURAL
	);
	PORT 
	(
		dataa	: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		datab	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		result	: OUT STD_LOGIC_VECTOR (19 DOWNTO 0)
	);
	END COMPONENT;

-------------------------------------------------------------------------------------

signal	accumulator				: std_logic_vector(23 downto 0);
signal	accu_bit_prev			: std_logic;
signal	PA_MSB_in_prev			: std_logic;

signal	sawtooth					: std_logic_vector(11 downto 0);
signal	triangle					: std_logic_vector(11 downto 0);
signal	pulse						: std_logic;								-- this type of signal has only two states 0 or 1 (so no more bits are required)
signal	noise						: std_logic_vector(11 downto 0);
signal	LFSR						: std_logic_vector(22 downto 0);

signal 	frequency				: std_logic_vector(15 downto 0);
signal 	pulsewidth				: std_logic_vector(11 downto 0);

-- Envelope Generator
type		envelope_state_types is 	(idle, attack, attack_lp, decay, decay_lp, sustain, release, release_lp);
signal 	cur_state, next_state 		: envelope_state_types; 
signal 	devider_counter		: integer range 0 to 2**18 - 1;
signal 	exp_table_value		: integer range 0 to 2**18 - 1;
signal 	exp_table_active		: std_logic;
signal 	devider_rst 			: std_logic;
signal 	devider_value			: integer range 0 to 2**15 - 1;
signal 	devider_attack			: integer range 0 to 2**15 - 1;
signal 	devider_dec_rel		: integer range 0 to 2**15 - 1;
signal	Dec_rel					: std_logic_vector(3 downto 0);
signal	Dec_rel_sel				: std_logic;

signal	env_counter				: std_logic_vector(7 downto 0);
signal 	env_count_hold_A		: std_logic;
signal	env_count_hold_B		: std_logic;
signal	env_cnt_up				: std_logic;
signal	env_cnt_clear			: std_logic;

signal	signal_mux				: std_logic_vector(11 downto 0);
signal	signal_vol				: std_logic_vector(19 downto 0);

-------------------------------------------------------------------------------------

alias		test						: std_logic is Control(3);						-- stop the oscillator when test = '1'
alias		ringmod					: std_logic is Control(2);						-- Ring Modulation was accomplished by substituting the accumulator MSB of an oscillator in the EXOR function of the triangle waveform generator with the accumulator MSB of the previous oscillator. That is why the triangle waveform must be selected to use Ring Modulation.
alias		sync						: std_logic is Control(1);						-- Hard Sync was accomplished by clearing the accumulator of an Oscillator based on the accumulator MSB of the previous oscillator.
alias		gate						: std_logic is Control(0);						--

-------------------------------------------------------------------------------------

begin

PA_MSB_out					<= accumulator(23);				-- output the Phase accumulator's MSB for sync and ringmod purposes
Osc							<= signal_mux(11 downto 4);	-- output the upper 8-bits of the waveform. Usefull for random numbers (noise must be selected)
Env							<= env_counter;					-- output the envelope register, for special sound effects when connecting this signal to the input of other channels/voices
frequency(15 downto 8)	<= Freq_hi(7 downto 0);			-- use the register value to fill the variable
frequency(7 downto 0)	<=	Freq_lo(7 downto 0);			--
pulsewidth(11 downto 8)	<=	Pw_hi(3 downto 0);			-- use the register value to fill the variable
pulsewidth(7 downto 0)	<=	Pw_lo(7 downto 0);			--
voice							<= signal_vol(19 downto 8);	--


-- Phase accumulator : 	"As I recall, the Oscillator is a 24-bit phase-accumulating design of which thelower 16-bits are programmable for pitch control. The output of the accumulator goes directly to a D/A converter through a waveform selector. Normally, the output of a phase-accumulating oscillator would be used as an address into memory which contained a wavetable, but SID had to be entirely self-contained and there was no room at all for a wavetable on the chip. "
--				"Hard Sync was accomplished by clearing the accumulator of an Oscillator based on the accumulator MSB of the previous oscillator."
PhaseAcc:process(clk_1MHz)
begin
	if (rising_edge(clk_1MHz)) then
		PA_MSB_in_prev <= PA_MSB_in;
		if ((reset = '1') or (test = '1') or ((sync = '1') and (PA_MSB_in_prev /= PA_MSB_in) and (PA_MSB_in = '0'))) then		-- the reset and test signal can stop the oscillator, stopping the oscillator is very usefull when you want to play "samples"
			accumulator <= "000000000000000000000000";
		else
			accumulator <= accumulator + ("0" & frequency(15 downto 0));	-- accumulate the new phase (i.o.w. increment env_counter with the freq. value)
		end if;
	end if;
end process;


--Sawtooth waveform : "The Sawtooth waveform was created by sending the upper 12-bits of the accumulator to the 12-bit Waveform D/A. "
Snd_Sawtooth:process(clk_1MHz)
begin
	if (rising_edge(clk_1MHz)) then
		sawtooth		<= accumulator(23 downto 12);
	end if;
end process;


--Pulse waveform : "The Pulse waveform was created by sending the upper 12-bits of the accumulator to a 12-bit digital comparator. The output of the comparator was either a one or a zero. This single output was then sent to all 12 bits of the Waveform D/A. "
Snd_pulse:process(clk_1MHz)
begin
	if (rising_edge(clk_1MHz)) then
		if ((accumulator(23 downto 12)) >= (pulsewidth(11 downto 0))) then
			pulse <= '1';
		else
			pulse <= '0';
		end if;
	end if;
end process;


--Triangle waveform : 	"The Triangle waveform was created by using the MSB of the accumulator to invert the remaining upper 11 accumulator bits using EXOR gates. These 11 bits were then left-shifted (throwing away the MSB) and sent to the Waveform D/A (so the resolution of the triangle waveform was half that of the sawtooth, but the amplitude and frequency were the same). "
--				"Ring Modulation was accomplished by substituting the accumulator MSB of an oscillator in the EXOR function of the triangle waveform generator with the accumulator MSB of the previous oscillator. That is why the triangle waveform must be selected to use Ring Modulation."
Snd_triangle:process(clk_1MHz)
begin
	if (rising_edge(clk_1MHz)) then
		if ringmod = '0' then	
			triangle(11)<= accumulator(23) xor accumulator(22);	-- no ringmodulation
			triangle(10)<= accumulator(23) xor accumulator(21);
			triangle(9)	<= accumulator(23) xor accumulator(20);
			triangle(8)	<= accumulator(23) xor accumulator(19);
			triangle(7)	<= accumulator(23) xor accumulator(18);
			triangle(6)	<= accumulator(23) xor accumulator(17);
			triangle(5)	<= accumulator(23) xor accumulator(16);
			triangle(4)	<= accumulator(23) xor accumulator(15);
			triangle(3)	<= accumulator(23) xor accumulator(14);
			triangle(2)	<= accumulator(23) xor accumulator(13);
			triangle(1)	<= accumulator(23) xor accumulator(12);
			triangle(0)	<= accumulator(23) xor accumulator(11);
		else			
			triangle(11)<= PA_MSB_in xor accumulator(22);			-- ringmodulation by the other voice (previous voice)
			triangle(10)<= PA_MSB_in xor accumulator(21);
			triangle(9)	<= PA_MSB_in xor accumulator(20);
			triangle(8)	<= PA_MSB_in xor accumulator(19);
			triangle(7)	<= PA_MSB_in xor accumulator(18);
			triangle(6)	<= PA_MSB_in xor accumulator(17);
			triangle(5)	<= PA_MSB_in xor accumulator(16);
			triangle(4)	<= PA_MSB_in xor accumulator(15);
			triangle(3)	<= PA_MSB_in xor accumulator(14);
			triangle(2)	<= PA_MSB_in xor accumulator(13);
			triangle(1)	<= PA_MSB_in xor accumulator(12);
			triangle(0)	<= PA_MSB_in xor accumulator(11);
		end if;
	end if;
end process;


--Noise (23-bit Linear Feedback Shift Register, max combinations = 8388607) : "The Noise waveform was created using a 23-bit pseudo-random sequence generator (i.e., a shift register with specific outputs fed back to the input through combinatorial logic). The shift register was clocked by one of the intermediate bits of the accumulator to keep the frequency content of the noise waveform relatively the same as the pitched waveforms. The upper 12-bits of the shift register were sent to the Waveform D/A."
noise	<= LFSR(22 downto 11);

Snd_noise:process(clk_1MHz)
begin
	if (rising_edge(clk_1MHz)) then
		if ((reset = '1') or (test = '1')) then					-- the test signal can stop the oscillator, stopping the oscillator is very usefull when you want to play "samples"
			accu_bit_prev		<= '0';
			LFSR	<= "00000000000000000000001";		-- the "seed" value (the values that eventually determines the output pattern) may never be '0' otherwise the generator "lock's up"			
		else
			accu_bit_prev	<= accumulator(22);
			if	(accu_bit_prev /= accumulator(22)) then			-- when .. is not equal to ..
				LFSR(22 downto 1)		<= LFSR(21 downto 0);
				LFSR(0) 					<= LFSR(4) xor LFSR(22);
			else
				LFSR	 					<= LFSR;
			end if;
		end if;
	end if;
end process;



-- Waveform Output selector (MUX) : "Since all of the waveforms were just digital bits, the Waveform Selector consisted of multiplexers that selected which waveform bits would be sent to the Waveform D/A. The multiplexers were single transistors and did not provide a "lock-out", allowing combinations of the waveforms to be selected. The combination was actually a logical ANDing of the bits of each waveform, which produced unpredictable results, so I didn't encourage this, especially since it could lock up the pseudo-random sequence generator by filling it with zeroes."
Snd_select:process(clk_1MHz)
begin
	if (rising_edge(clk_1MHz)) then
		signal_mux(11)	<= (sawtooth(11) and Control(5)) or (triangle(11) and Control(4)) or (pulse and Control(6)) or (noise(11) and Control(7));
		signal_mux(10)	<= (sawtooth(10) and Control(5)) or (triangle(10) and Control(4)) or (pulse and Control(6)) or (noise(10) and Control(7));
		signal_mux(9)	<= (sawtooth(9) and Control(5)) or (triangle(9) and Control(4)) or (pulse and Control(6)) or (noise(9) and Control(7));
		signal_mux(8)	<= (sawtooth(8) and Control(5)) or (triangle(8) and Control(4)) or (pulse and Control(6)) or (noise(8) and Control(7));
		signal_mux(7)	<= (sawtooth(7) and Control(5)) or (triangle(7) and Control(4)) or (pulse and Control(6)) or (noise(7) and Control(7));
		signal_mux(6)	<= (sawtooth(6) and Control(5)) or (triangle(6) and Control(4)) or (pulse and Control(6)) or (noise(6) and Control(7));
		signal_mux(5)	<= (sawtooth(5) and Control(5)) or (triangle(5) and Control(4)) or (pulse and Control(6)) or (noise(5) and Control(7));
		signal_mux(4)	<= (sawtooth(4) and Control(5)) or (triangle(4) and Control(4)) or (pulse and Control(6)) or (noise(4) and Control(7));
		signal_mux(3)	<= (sawtooth(3) and Control(5)) or (triangle(3) and Control(4)) or (pulse and Control(6)) or (noise(3) and Control(7));
		signal_mux(2)	<= (sawtooth(2) and Control(5)) or (triangle(2) and Control(4)) or (pulse and Control(6)) or (noise(2) and Control(7));
		signal_mux(1)	<= (sawtooth(1) and Control(5)) or (triangle(1) and Control(4)) or (pulse and Control(6)) or (noise(1) and Control(7));
		signal_mux(0)	<= (sawtooth(0) and Control(5)) or (triangle(0) and Control(4)) or (pulse and Control(6)) or (noise(0) and Control(7));
	end if;
end process;

-- Waveform envelope (volume) control : "The output of the Waveform D/A (which was an analog voltage at this point) was fed into the reference input of an 8-bit multiplying D/A, creating a DCA (digitally-controlled-amplifier). The digital control word which modulated the amplitude of the waveform came from the Envelope Generator."
-- "The 8-bit output of the Envelope Generator was then sent to the Multiplying D/A converter to modulate the amplitude of the selected Oscillator Waveform (to be technically accurate, actually the waveform was modulating the output of the Envelope Generator, but the result is the same)."
--Envelope_multiplier:process(clk_1MHz)
--begin
--	if (rising_edge(clk_1MHz)) then
--		signal_vol	<= ("00000000"& signal_mux) * ("000000000000" & env_counter);		-- calculate the resulting volume (due to the envelope generator) of the voice, signal_mux(12bit) * env_counter(8bit), so the result will require 20 bits !!
--	end if;
--end process;

	lpm_mult_component : lpm_mult
		GENERIC MAP
		(
			lpm_hint => "MAXIMIZE_SPEED=5",
			lpm_representation => "UNSIGNED",
			lpm_type => "LPM_MULT",
			lpm_widtha => 12,
			lpm_widthb => 8,
			lpm_widthp => 20,
			lpm_widths => 1
		)
		PORT MAP
		(
			dataa(11 downto 0) => signal_mux,
			datab(7 downto 0) => env_counter,
			result => signal_vol
		);

-- Envelope generator : "The Envelope Generator was simply an 8-bit up/down counter which, when triggered by the Gate bit, counted from 0 to 255 at the Attack rate, from 255 down to the programmed Sustain value at the Decay rate, remained at the Sustain value until the Gate bit was cleared then counted down from the Sustain value to 0 at the Release rate."
--
--		      /\
--		     /  \ 
--		    / |  \________
--		   /  |   |       \
--		  /   |   |       |\
--		 /    |   |       | \
--		attack|dec|sustain|rel

-- this process controls the state machine "current-state"-value
Envelope_SM_advance: process (reset, clk_1MHz)
begin
	if (reset = '1') then
		cur_state <= idle;
	else
		if (rising_edge(clk_1MHz)) then
			cur_state <= next_state;
		end if;
	end if;
end process;


-- this process controls the envelope (in other words, the volume control)
Envelope_SM: process (reset, cur_state, gate, devider_attack, devider_dec_rel, Att_dec, Sus_Rel, env_counter)
begin
	if (reset = '1') then
		next_state 				<= idle;
		env_cnt_clear			<='1';
		env_cnt_up				<='1';
		env_count_hold_B		<='1';
		devider_rst 			<='1';
		devider_value 			<= 0;
		exp_table_active 		<='0';
		Dec_rel_sel				<='0';					-- select decay as input for decay/release table
	else
		env_cnt_clear	 		<='0';					-- use this statement unless stated otherwise
		env_cnt_up				<='1';					-- use this statement unless stated otherwise
		env_count_hold_B		<='1';					-- use this statement unless stated otherwise
		devider_rst 			<='0';					-- use this statement unless stated otherwise
		devider_value 			<=0;						-- use this statement unless stated otherwise
		exp_table_active 		<='0';					-- use this statement unless stated otherwise
		case cur_state is

			-- IDLE
			when idle =>
				env_cnt_clear 		<= '1';				-- clear envelope env_counter
				devider_rst 		<= '1';
				Dec_rel_sel			<='0';				-- select decay as input for decay/release table
				if gate = '1' then
					next_state 	<= attack;
				else
					next_state 	<= idle;
				end if;
			
			when attack =>
				env_cnt_clear		<= '1';				-- clear envelope env_counter
				devider_rst 		<= '1';
				devider_value 		<= devider_attack;
				next_state 			<= attack_lp;
				Dec_rel_sel			<='0';				-- select decay as input for decay/release table
			
			when attack_lp =>
				env_count_hold_B 	<= '0';				-- enable envelope env_counter
				env_cnt_up 			<= '1';				-- envelope env_counter must count up (increment)
				devider_value 		<= devider_attack;
				Dec_rel_sel			<='0';				-- select decay as input for decay/release table
				if env_counter = "11111111" then
					next_state	<= decay;
				else
					if gate = '0' then
						next_state	<= release;
					else
						next_state	<= attack_lp;
					end if;
				end if;
		
			when decay =>
				devider_rst 		<= '1';
				exp_table_active 	<= '1';				-- activate exponential look-up table
				env_cnt_up	 		<= '0';				-- envelope env_counter must count down (decrement)				
				devider_value 		<= devider_dec_rel;
				next_state 			<= decay_lp;
				Dec_rel_sel			<='0';				-- select decay as input for decay/release table
			
			when decay_lp =>
				exp_table_active 	<= '1';				-- activate exponential look-up table
				env_count_hold_B 	<= '0';				-- enable envelope env_counter
				env_cnt_up 			<= '0';				-- envelope env_counter must count down (decrement)
				devider_value 		<= devider_dec_rel;
				Dec_rel_sel			<='0';				-- select decay as input for decay/release table
				if (env_counter(7 downto 4) = Sus_Rel(7 downto 4)) then
					next_state 		<= sustain;
				else
					if gate = '0' then
						next_state		<= release;
					else
						next_state		<= decay_lp;
					end if;
				end if;
			
			when sustain =>				-- "A digital comparator was used for the Sustain function. The upper four bits of the Up/Down counter were compared to the programmed Sustain value and would stop the clock to the Envelope Generator when the counter counted down to the Sustain value. This created 16 linearly spaced sustain levels without havingto go through a look-up table translation between the 4-bit register value and the 8-bit Envelope Generator output. It also meant that sustain levels were adjustable in steps of 16. Again, more register bits would have provided higher resolution."
				devider_value 		<= 0;	-- "When the Gate bit was cleared, the clock would again be enabled, allowing the counter to count down to zero. Like an analog envelope generator, the SID Envelope Generator would track the Sustain level if it was changed to a lower value during the Sustain portion of the envelope, however, it would not count UP if the Sustain level were set higher."	Instead it would count down to '0'.
				Dec_rel_sel			<='1';				-- select release as input for decay/release table
				if gate = '0' then	
					next_state 			<= release;
				else
					if (env_counter(7 downto 4) = Sus_Rel(7 downto 4)) then
						next_state 		<= sustain;
					else
						next_state 		<= decay;						
					end if;
				end  if;
		
			when release =>
				devider_rst 		<= '1';
				exp_table_active 	<= '1';				-- activate exponential look-up table
				env_cnt_up	 		<= '0';				-- envelope env_counter must count down (decrement)
				devider_value 		<= devider_dec_rel;
				Dec_rel_sel			<='1';				-- select release as input for decay/release table
				next_state 			<= release_lp;
					
			when release_lp =>
				exp_table_active 	<= '1';				-- activate exponential look-up table
				env_count_hold_B 	<= '0';				-- enable envelope env_counter
				env_cnt_up	 		<= '0';				-- envelope env_counter must count down (decrement)
				devider_value 		<= devider_dec_rel;
				Dec_rel_sel			<='1';				-- select release as input for decay/release table
				if env_counter = "00000000" then
					next_state 	<= idle;
				else
					if gate = '1' then
						next_state 	<= idle;
					else
						next_state	<= release_lp;
					end if;
				end if;

			when others =>
					devider_value 		<= 0;
					Dec_rel_sel			<='0';			-- select decay as input for decay/release table
					next_state			<= idle;	
		end case;
	end if;
end process;


-- 8 bit up/down env_counter
Envelope_counter:process(clk_1MHz)
begin
	if (rising_edge(clk_1MHz)) then
		if ((reset = '1') or (env_cnt_clear = '1')) then
			env_counter <= "00000000";		
		else
			if ((env_count_hold_A = '1') or (env_count_hold_B = '1'))then
				env_counter <= env_counter;			
			else
				if (env_cnt_up = '1') then
						env_counter <= env_counter + 1;
				else
						env_counter <= env_counter - 1;
				end if;
			end if;
		end if;
	end if;
end process;


-- Devider	: "A programmable frequency divider was used to set the various rates (unfortunately I don't remember how many bits the divider was, either 12 or 16 bits). A small look-up table translated the 16 register-programmable values to the appropriate number to load into the frequency divider. Depending on what state the Envelope Generator was in (i.e. ADS or R), the appropriate register would be selected and that number would be translated and loaded into the divider. Obviously it would have been better to have individual bit control of the divider which would have provided great resolution for each rate, however I did not have enough silicon area for a lot of register bits. Using this approach, I was able to cram a wide range of rates into 4 bits, allowing the ADSR to be defined in two bytes instead of eight. The actual numbers in the look-up table were arrived at subjectively by setting up typical patches on a Sequential Circuits Pro-1 and measuring the envelope times by ear (which is why the available rates seem strange)!"
prog_freq_div:process(clk_1MHz)
begin
	if (rising_edge(clk_1MHz)) then
		if ((reset = '1') or (devider_rst = '1')) then
			env_count_hold_A 	<= '1';			
			devider_counter	<= 0;
		else
			if (devider_counter = 0) then
				env_count_hold_A 	<= '0';
				if (exp_table_active = '1') then
					devider_counter	<= exp_table_value;
				else
					devider_counter	<= devider_value;
				end if;
			else
				env_count_hold_A	<= '1';					
				devider_counter	<= devider_counter - 1;
			end if;
		end if;
	end if;
end process;


-- Piese-wise linear approximation of an exponential : "In order to more closely model the exponential decay of sounds, another look-up table on the output of the Envelope Generator would sequentially divide the clock to the Envelope Generator by two at specific counts in the Decay and Release cycles. This created a piece-wise linear approximation of an exponential. I was particularly happy how well this worked considering the simplicity of the circuitry. The Attack, however, was linear, but this sounded fine."
-- The clock is divided by two at specifiek values of the envelope generator to create an exponential.  
Exponential_table:process(clk_1MHz)
BEGIN
	if (rising_edge(clk_1MHz)) then		
		if (reset = '1') then
			exp_table_value <= 0;
		else
			case CONV_INTEGER(env_counter) is
				when   0 to  51	=>	exp_table_value <= devider_value * 16;		--  51 to   0
				when  52 to 101 	=>	exp_table_value <= devider_value * 8;		--	101 to  52
				when 102 to 152 	=>	exp_table_value <= devider_value * 4;		-- 152 to 102
				when 153 to 203 	=>	exp_table_value <= devider_value * 2;		--	203 to 153
				when 204 to 255 	=>	exp_table_value <= devider_value;			-- 255 to 204
				when others			=>	exp_table_value <= devider_value;			--
			end case;
		end if;
	end if;
end process;


-- Attack Lookup table : It takes 255 clock cycles from zero to peak value. Therefor the devider equals (attack rate / clockcycletime of 1MHz clock) / 254; 
Attack_table:process(clk_1MHz)
begin
	if (rising_edge(clk_1MHz)) then
		if (reset = '1') then
			devider_attack <= 0;
		else
			case Att_dec(7 downto 4) is
				when "0000"	=>	devider_attack <= 8;			--attack rate: (2mS / 1uSec per clockcycle) / 254 steps
				when "0001" =>	devider_attack <= 31;		--attack rate: (8mS / 1uS per clockcycle) /254 steps
				when "0010" =>	devider_attack <= 63;		--attack rate: (16mS / 1uS per clockcycle) /254 steps
				when "0011" =>	devider_attack <= 94;		--attack rate: (24mS / 1uS per clockcycle) /254 steps
				when "0100" =>	devider_attack <= 150;		--attack rate: (38mS / 1uS per clockcycle) /254 steps
				when "0101" =>	devider_attack <= 220;		--attack rate: (56mS / 1uS per clockcycle) /254 steps
				when "0110" =>	devider_attack <= 268;		--attack rate: (68mS / 1uS per clockcycle) /254 steps
				when "0111" =>	devider_attack <= 315;		--attack rate: (80mS / 1uS per clockcycle) /254 steps
				when "1000" =>	devider_attack <= 394;		--attack rate: (100mS / 1uS per clockcycle) /254 steps
				when "1001" =>	devider_attack <= 984;		--attack rate: (250mS / 1uS per clockcycle) /254 steps
				when "1010" =>	devider_attack <= 1968;		--attack rate: (500mS / 1uS per clockcycle) /254 steps
				when "1011" =>	devider_attack <= 3150;		--attack rate: (800mS / 1uS per clockcycle) /254 steps
				when "1100" =>	devider_attack <= 3937;		--attack rate: (1000mS / 1uS per clockcycle) /254 steps
				when "1101" =>	devider_attack <= 11811;	--attack rate: (3000mS / 1uS per clockcycle) /254 steps
				when "1110" =>	devider_attack <= 19685;	--attack rate: (5000mS / 1uS per clockcycle) /254 steps
				when "1111" =>	devider_attack <= 31496; 	--attack rate: (8000mS / 1uS per clockcycle) / 254steps
				when others =>	devider_attack <= 0;			--
			end case;
		end if;
	end if;
end process;


Decay_Release_input_select:process(Dec_rel_sel, Att_dec, Sus_Rel)
begin
	if (Dec_rel_sel = '0') then
		Dec_rel(3 downto 0)	<= Att_dec(3 downto 0);
	else
		Dec_rel(3 downto 0)	<= Sus_rel(3 downto 0);
	end if;
end process;

-- Decay Lookup table : It takes 32 * 51 = 1632 clock cycles to fall from peak level to zero. 
-- Release Lookup table : It takes 32 * 51 = 1632 clock cycles to fall from peak level to zero. 
Decay_Release_table:process(clk_1MHz)
begin
	if (rising_edge(clk_1MHz)) then
		if reset = '1' then
			devider_dec_rel <= 0;
		else
			case Dec_rel(3 downto 0) is
				when "0000" =>	devider_dec_rel <= 3; 		--release rate: (6mS / 1uS per clockcycle) / 1632
				when "0001" =>	devider_dec_rel <= 15; 		--release rate: (24mS / 1uS per clockcycle) / 1632
				when "0010" =>	devider_dec_rel <= 29; 		--release rate: (48mS / 1uS per clockcycle) / 1632
				when "0011" =>	devider_dec_rel <= 44; 		--release rate: (72mS / 1uS per clockcycle) / 1632
				when "0100" =>	devider_dec_rel <= 70; 		--release rate: (114mS / 1uS per clockcycle) / 1632
				when "0101" =>	devider_dec_rel <= 103; 	--release rate: (168mS / 1uS per clockcycle) / 1632
				when "0110" =>	devider_dec_rel <= 125; 	--release rate: (204mS / 1uS per clockcycle) / 1632
				when "0111" =>	devider_dec_rel <= 147; 	--release rate: (240mS / 1uS per clockcycle) / 1632
				when "1000" =>	devider_dec_rel <= 184; 	--release rate: (300mS / 1uS per clockcycle) / 1632
				when "1001" =>	devider_dec_rel <= 459; 	--release rate: (750mS / 1uS per clockcycle) / 1632
				when "1010" =>	devider_dec_rel <= 919; 	--release rate: (1500mS / 1uS per clockcycle) / 1632
				when "1011" =>	devider_dec_rel <= 1471; 	--release rate: (2400mS / 1uS per clockcycle) / 1632
				when "1100" =>	devider_dec_rel <= 1838; 	--release rate: (3000mS / 1uS per clockcycle) / 1632
				when "1101" =>	devider_dec_rel <= 5515; 	--release rate: (9000mS / 1uS per clockcycle) / 1632
				when "1110" =>	devider_dec_rel <= 9191; 	--release rate: (15000mS / 1uS per clockcycle) / 1632
				when "1111" =>	devider_dec_rel <= 14706;	--release rate: (24000mS / 1uS per clockcycle) / 1632
				when others =>	devider_dec_rel <= 0;		--
			end case;
		end if;
	end if;
end process;

end Behavioral;
