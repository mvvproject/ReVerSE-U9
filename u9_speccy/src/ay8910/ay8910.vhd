-----------------------------------------------------------------[Rev.20111023]
-- I2S Master Controller (TDA1543) Mode MSB First
-------------------------------------------------------------------------------
-- V0.01 Rev.20110212	первая версия

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
 
entity ay8910 is
   port(
      CLK   : in  std_logic;                    -- System Clock
      CLKEN	: in  std_logic;                    -- PSG Clock
      RESET : in  std_logic;                    -- Chip Reset (set all Registers to '0', active low)
      BDIR  : in  std_logic;                    -- Bus Direction (0 - read , 1 - write)
      CS    : in  std_logic;                    -- Chip Select (active low)
      BC    : in  std_logic;                    -- Bus control
      DI    : in  std_logic_vector(7 downto 0); -- Data In
      DO    : out std_logic_vector(7 downto 0); -- Data Out
      OUT_A : out std_logic_vector(7 downto 0); -- PSG Output channel A
      OUT_B : out std_logic_vector(7 downto 0); -- PSG Output channel B
      OUT_C : out std_logic_vector(7 downto 0)  -- PSG Output channel C
   );
end ay8910;
 
architecture rtl of ay8910 is
 
   signal ClockDiv   : unsigned (3 downto 0);			-- Divide CLK
 
-- AY Registers
   signal Period_A   : std_logic_vector (11 downto 0);	-- Channel A Tone Period (R1:R0)
   signal Period_B   : std_logic_vector (11 downto 0);	-- Channel B Tone Period (R3:R2)
   signal Period_C   : std_logic_vector (11 downto 0);	-- Channel C Tone Period (R5:R4)
   signal Period_N   : std_logic_vector (4 downto 0);	-- Noise Period (R6)
   signal Enable     : std_logic_vector (7 downto 0);	-- Enable (R7)
   signal Volume_A   : std_logic_vector (4 downto 0);	-- Channel A Amplitude (R10)
   signal Volume_B   : std_logic_vector (4 downto 0);	-- Channel B Amplitude (R11)
   signal Volume_C   : std_logic_vector (4 downto 0);	-- Channel C Amplitude (R12)
   signal Period_E   : std_logic_vector (15 downto 0);	-- Envelope Period (R14:R13)
   signal Shape      : std_logic_vector (3 downto 0);	-- Envelope Shape/Cycle (R15)
   signal Port_A     : std_logic_vector (7 downto 0);	-- I/O Port A Data Store (R16)
   signal Port_B     : std_logic_vector (7 downto 0);	-- I/O Port B Data Store (R17)

   signal Address    : std_logic_vector (3 downto 0);	-- Selected Register
 
   alias  Continue   : std_logic is Shape(3);			-- Envelope Control
   alias  Attack     : std_logic is Shape(2);
   alias  Alternate  : std_logic is Shape(1);
   alias  Hold       : std_logic is Shape(0);
 
   signal Reset_Req  : std_logic;						-- Envelope Reset Required
   signal Reset_Ack  : std_logic;						-- Envelope Reset Acknoledge
   signal Volume_E   : std_logic_vector (3 downto 0);   -- Envelope Volume
 
   signal Freq_A     : std_logic;                       -- Tone Generator A Output
   signal Freq_B     : std_logic;                       -- Tone Generator B Output
   signal Freq_C     : std_logic;                       -- Tone Generator C Output
   signal Freq_N     : std_logic;                       -- Noise Generator Output
 
-- Volume Table
   function VolumeTable (value : std_logic_vector(3 downto 0)) return std_logic_vector is
      variable result : std_logic_vector (7 downto 0);
   begin
      case value is
		when X"0"  => result := X"00";
		when X"1"  => result := X"01";
		when X"2"  => result := X"02";
		when X"3"  => result := X"03";
		when X"4"  => result := X"05";
		when X"5"  => result := X"07";
		when X"6"  => result := X"0B";
		when X"7"  => result := X"0F";
		when X"8"  => result := X"16";
		when X"9"  => result := X"1F";
		when X"A"  => result := X"2D";
		when X"B"  => result := X"3F";
		when X"C"  => result := X"5A";
		when X"D"  => result := X"7F";
		when X"E"  => result := X"B4";
		when X"F"  => result := X"FF";
		when others => null;
      end case;
   return result;
   end VolumeTable;
 
begin
 
-- Write to AY
process (RESET, CLK)
begin
   if RESET = '0' then
      Address   <= "0000";
      Period_A  <= "000000000000";
      Period_B  <= "000000000000";
      Period_C  <= "000000000000";
      Period_N  <= "00000";
      Enable    <= "00000000";
      Volume_A  <= "00000";
      Volume_B  <= "00000";
      Volume_C  <= "00000";
      Period_E  <= "0000000000000000";
      Shape     <= "0000";
      Port_A    <= "00000000";
      Port_B    <= "00000000";
      Reset_Req <= '0';
   elsif CLK'event and CLK = '1' then 
      if CS = '0' and BDIR = '1' then
         if BC = '1' then
            Address <= DI (3 downto 0);	-- Latch Address
         else
            case Address is 			-- Latch Registers
               when X"0" => Period_A (7 downto 0)   <= DI;
               when X"1" => Period_A (11 downto 8)  <= DI (3 downto 0);
               when X"2" => Period_B (7 downto 0)   <= DI;
               when X"3" => Period_B (11 downto 8)  <= DI (3 downto 0);
               when X"4" => Period_C (7 downto 0)   <= DI;
               when X"5" => Period_C (11 downto 8)  <= DI (3 downto 0);
               when X"6" => Period_N                <= DI (4 downto 0);
               when X"7" => Enable                  <= DI;
               when X"8" => Volume_A                <= DI (4 downto 0);
               when X"9" => Volume_B                <= DI (4 downto 0);
               when X"A" => Volume_C                <= DI (4 downto 0);
               when X"B" => Period_E (7 downto 0)   <= DI;
               when X"C" => Period_E (15 downto 8)  <= DI;
               when X"D" => Shape                   <= DI (3 downto 0);
                              Reset_Req               <= not Reset_Ack; -- Reset Envelope Generator
               when X"E" => Port_A                  <= DI;
               when X"F" => Port_B                  <= DI;
               when others => null;
            end case;
         end if;
      end if;
   end if;
end process;
 
-- Read from AY
DO	<=	Period_A (7 downto 0)			when Address = X"0" and CS = '0' and BDIR = '0' and BC = '1' else
		"0000" & Period_A (11 downto 8)	when Address = X"1" and CS = '0' and BDIR = '0' and BC = '1' else
		Period_B (7 downto 0)   		when Address = X"2" and CS = '0' and BDIR = '0' and BC = '1' else
		"0000" & Period_B (11 downto 8) when Address = X"3" and CS = '0' and BDIR = '0' and BC = '1' else
		Period_C (7 downto 0)   		when Address = X"4" and CS = '0' and BDIR = '0' and BC = '1' else
		"0000" & Period_C (11 downto 8) when Address = X"5" and CS = '0' and BDIR = '0' and BC = '1' else
		"000" & Period_N                when Address = X"6" and CS = '0' and BDIR = '0' and BC = '1' else
        Enable                  		when Address = X"7" and CS = '0' and BDIR = '0' and BC = '1' else
        "000" & Volume_A                when Address = X"8" and CS = '0' and BDIR = '0' and BC = '1' else
        "000" & Volume_B                when Address = X"9" and CS = '0' and BDIR = '0' and BC = '1' else
        "000" & Volume_C                when Address = X"A" and CS = '0' and BDIR = '0' and BC = '1' else
		Period_E (7 downto 0)   		when Address = X"B" and CS = '0' and BDIR = '0' and BC = '1' else
		Period_E (15 downto 8)  		when Address = X"C" and CS = '0' and BDIR = '0' and BC = '1' else
		"0000" & Shape                  when Address = X"D" and CS = '0' and BDIR = '0' and BC = '1' else
		"11111111";
 
-- Divide CLKEN
process (RESET, CLK)
begin
   if RESET = '0' then
      ClockDiv <= "0000";
   elsif CLK'event and CLK = '1' then
      if CLKEN = '1' then
         ClockDiv <= ClockDiv - 1;
      end if;
   end if;
end process;
 
-- Tone Generator
process (RESET, CLK)
   variable Counter_A   : unsigned (11 downto 0);
   variable Counter_B   : unsigned (11 downto 0);
   variable Counter_C   : unsigned (11 downto 0);
begin
   if RESET = '0' then
      Counter_A   := "000000000000";
      Counter_B   := "000000000000";
      Counter_C   := "000000000000";
      Freq_A      <= '0';
      Freq_B      <= '0';
      Freq_C      <= '0';
   elsif CLK'event and CLK = '1' then
      if ClockDiv(2 downto 0) = "000" and CLKEN = '1' then
 
         -- Channel A Counter
         if (Counter_A /= X"000") then
            Counter_A := Counter_A - 1;
         elsif (Period_A /= X"000") then
            Counter_A := unsigned(Period_A) - 1;
         end if;
         if (Counter_A = X"000") then
            Freq_A <= not Freq_A;
         end if;
 
         -- Channel B Counter
         if (Counter_B /= X"000") then
            Counter_B := Counter_B - 1;
         elsif (Period_B /= X"000") then
            Counter_B := unsigned(Period_B) - 1;
         end if;
         if (Counter_B = X"000") then
            Freq_B <= not Freq_B;
         end if;
 
         -- Channel C Counter
         if (Counter_C /= X"000") then
            Counter_C := Counter_C - 1;
         elsif (Period_C /= X"000") then
            Counter_C := unsigned(Period_C) - 1;
         end if;
         if (Counter_C = X"000") then
            Freq_C <= not Freq_C;
         end if;
 
      end if;
   end if;
end process;
 
-- Noise Generator
process (RESET, CLK)
   variable NoiseShift : unsigned (16 downto 0);
   variable Counter_N  : unsigned (4 downto 0);
begin
   if RESET = '0' then
      Counter_N   := "00000";
      NoiseShift  := "00000000000000001";
   elsif CLK'event and CLK = '1' then
     if ClockDiv(2 downto 0) = "000" and CLKEN = '1' then
         if (Counter_N /= "00000") then
            Counter_N := Counter_N - 1;
         elsif (Period_N /= "00000") then
            Counter_N := unsigned(Period_N) - 1;
         end if;
 
         if Counter_N = "00000" then
            NoiseShift := (NoiseShift(0) xor NoiseShift(2)) & NoiseShift(16 downto 1);
         end if;
 
         Freq_N <= NoiseShift(0);
 
      end if;
   end if;
end process;
 
-- Envelope Generator
process (RESET, CLK)
   variable EnvCounter  : unsigned(15 downto 0);
   variable EnvWave     : unsigned(4 downto 0);
begin
   if RESET = '0' then
      EnvCounter  := "0000000000000000";
      EnvWave     := "11111";
      Volume_E    <= "0000";
      Reset_Ack   <= '0';
   elsif CLK'event and CLK = '1' then
      if ClockDiv = "0000" and CLKEN = '1' then
         -- Envelope Period Counter
         if (EnvCounter /= X"0000" and Reset_Req = Reset_Ack) then 
            EnvCounter := EnvCounter - 1;
         elsif (Period_E /= X"0000") then
            EnvCounter := unsigned(Period_E) - 1;
         end if;
 
         -- Envelope Phase Counter
         if (Reset_Req /= Reset_Ack) then
            EnvWave := (others => '1');
         elsif (EnvCounter = X"0000" and (EnvWave(4) = '1' or (Hold = '0' and Continue = '1'))) then
            EnvWave := EnvWave - 1;
         end if;
 
         -- Envelope Amplitude Counter
         for I in 3 downto 0 loop
            if (EnvWave(4) = '0' and Continue = '0') then
               Volume_E(I) <= '0';
            elsif (EnvWave(4) = '1' or (Alternate xor Hold) = '0') then
               Volume_E(I) <= EnvWave(I) xor Attack;
            else
              Volume_E(I) <= EnvWave(I) xor Attack xor '1';
            end if;
         end loop;
 
         Reset_Ack <= Reset_Req;
 
      end if;
   end if;
end process;
 
-- Mixer
process (RESET, CLK)
begin
   if RESET = '0' then
      OUT_A <= "00000000";
      OUT_B <= "00000000";
      OUT_C <= "00000000";
   elsif CLK'event and CLK = '1' then
      if CLKEN = '1' then
         if (((Enable(0) or Freq_A) and (Enable(3) or Freq_N)) = '0') then
            OUT_A <= "00000000";
         elsif (Volume_A(4) = '0') then
            OUT_A <= VolumeTable(Volume_A(3 downto 0));
         else
            OUT_A <= VolumeTable(Volume_E);
         end if;
 
         if (((Enable(1) or Freq_B) and (Enable(4) or Freq_N)) = '0') then
            OUT_B <= "00000000";
         elsif (Volume_B(4) = '0') then
            OUT_B <= VolumeTable(Volume_B(3 downto 0));
         else
            OUT_B <= VolumeTable(Volume_E);
         end if;
 
         if (((Enable(2) or Freq_C) and (Enable(5) or Freq_N)) = '0') then
            OUT_C <= "00000000";
         elsif (Volume_C(4) = '0') then
            OUT_C <= VolumeTable(Volume_C(3 downto 0));
         else
            OUT_C <= VolumeTable(Volume_E);
         end if;
      end if;
   end if;
end process;
 
end rtl;