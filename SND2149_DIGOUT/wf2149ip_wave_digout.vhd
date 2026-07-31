------------------------------------------------------------------------
----                                                                ----
---- YM2149 compatible sound generator.				                ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Model of the ST or STE's YM2149 sound generator.               ----
----                                                                ----
---- Waveform generator.                                            ----
----                                                                ----
----                                                                ----
---- To Do:                                                         ----
---- -                                                              ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2006... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- All rights reserved. No portion of this sourcecode may be      ----
---- reproduced or transmitted in any form by any means, whether    ----
---- by electronic, mechanical, photocopying, recording or          ----
---- otherwise, without my written permission.                      ----
----                                                                ----
------------------------------------------------------------------------
-- 
-- Revision History
-- 
-- Revision 2K6A  2006/06/03 WF
--   Initial Release.
-- Revision 2K6B  2006/11/07 WF
--   Modified Source to compile with the Xilinx ISE.
-- Revision 2K8A  2008/07/14 WF
--   Minor changes.
-- Revision 2K9A  2009/06/20 WF
--   NOISE_OUT has now synchronous reset to meet preset requirement.
--   Fixed a bug in the envelope generator. Thanks to Lyndon Amsdon finding it.
--   Correction of the schematic given in the end of this file.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.WF2149IP_DIGOUT_PKG.all;

entity WF2149IP_WAVE_DIGOUT is
	port(
		RESETn		: in std_logic;
		SYS_CLK		: in std_logic;

		WAV_STRB	: in std_logic;

		ADR			: in std_logic_vector(3 downto 0);
		DATA_IN		: in std_logic_vector(7 downto 0);
		DATA_OUT	: out std_logic_vector(7 downto 0);
		DATA_EN		: out std_logic;
		
		BUSCYCLE	: in BUSCYCLES;
		CTRL_REG	: in std_logic_vector(5 downto 0);

		OUT_ALL		: out std_logic_vector(7 downto 0)
	);
end entity WF2149IP_WAVE_DIGOUT;

architecture BEHAVIOR of WF2149IP_WAVE_DIGOUT is
signal FREQUENCY_A	: std_logic_vector(11 downto 0);
signal FREQUENCY_B	: std_logic_vector(11 downto 0);
signal FREQUENCY_C	: std_logic_vector(11 downto 0);
signal NOISE_FREQ	: std_logic_vector(4 downto 0);
signal LEVEL_A		: std_logic_vector(4 downto 0);
signal LEVEL_B		: std_logic_vector(4 downto 0);
signal LEVEL_C		: std_logic_vector(4 downto 0);
signal ENV_FREQ		: std_logic_vector(15 downto 0);
signal ENV_SHAPE	: std_logic_vector(3 downto 0);
signal ENV_RESET	: boolean;
signal ENV_STRB		: std_logic;
signal OSC_A_OUT	: std_logic;
signal OSC_B_OUT	: std_logic;
signal OSC_C_OUT	: std_logic;
signal NOISE_OUT	: std_logic;
signal AUDIO_A		: std_logic;
signal AUDIO_B		: std_logic;
signal AUDIO_C		: std_logic;
signal VOL_ENV		: std_logic_vector(4 downto 0);
signal AMPLITUDE_A	: std_logic_vector(4 downto 0);
signal AMPLITUDE_B	: std_logic_vector(4 downto 0);
signal AMPLITUDE_C	: std_logic_vector(4 downto 0);
signal VOLUME_A		: std_logic_vector(7 downto 0);
signal VOLUME_B		: std_logic_vector(7 downto 0);
signal VOLUME_C		: std_logic_vector(7 downto 0);
signal OUT_A        : std_logic_vector(9 downto 0);
signal OUT_B        : std_logic_vector(9 downto 0);
signal OUT_C        : std_logic_vector(9 downto 0);
signal OUT_ALL_I    : std_logic_vector(9 downto 0);
begin
	REGISTERS: process(RESETn, SYS_CLK)
	-- This process is responsible for initialisation
	-- and write access to the configuration registers.
	begin
		if RESETn = '0' then
			FREQUENCY_A <= x"000";
			FREQUENCY_B <= x"000";
			FREQUENCY_C <= x"000";
			NOISE_FREQ <= "00000";
			LEVEL_A <= "00000";
			LEVEL_B <= "00000";
			LEVEL_C <= "00000";
			ENV_FREQ <= (others => '0');
			ENV_SHAPE <= "0000";
		elsif SYS_CLK = '1' and SYS_CLK' event then
			ENV_RESET <= false; -- Initialize signal.
			if BUSCYCLE = R_WRITE then
				case ADR is
					when x"0" => FREQUENCY_A(7 downto 0) <= DATA_IN;
					when x"1" => FREQUENCY_A(11 downto 8) <= DATA_IN(3 downto 0);
					when x"2" => FREQUENCY_B(7 downto 0) <= DATA_IN;
					when x"3" => FREQUENCY_B(11 downto 8) <= DATA_IN(3 downto 0);
					when x"4" => FREQUENCY_C(7 downto 0) <= DATA_IN;
					when x"5" => FREQUENCY_C(11 downto 8) <= DATA_IN(3 downto 0);
					when x"6" => NOISE_FREQ <= DATA_IN(4 downto 0);
					when x"8" => LEVEL_A <= DATA_IN(4 downto 0);
					when x"9" => LEVEL_B <= DATA_IN(4 downto 0);
					when x"A" => LEVEL_C <= DATA_IN(4 downto 0);
					when x"B" => ENV_FREQ(7 downto 0) <= DATA_IN;
					when x"C" => ENV_FREQ(15 downto 8) <= DATA_IN;	
								 ENV_RESET <= true; -- Initialize the envelope generator.
					when x"D" => ENV_SHAPE <= DATA_IN(3 downto 0);
					when others => null;
				end case;
			end if;
		end if;
	end process REGISTERS;

	-- Read back the configuration registers:
	DATA_OUT <=	FREQUENCY_A(7 downto 0) when BUSCYCLE = R_READ and ADR = x"0" else
				"0000" & FREQUENCY_A(11 downto 8) when BUSCYCLE = R_READ and ADR = x"1" else
				FREQUENCY_B(7 downto 0) when BUSCYCLE = R_READ and ADR = x"2" else
				"0000" & FREQUENCY_B(11 downto 8) when BUSCYCLE = R_READ and ADR = x"3" else
				FREQUENCY_C(7 downto 0) when BUSCYCLE = R_READ and ADR = x"4" else
				"0000" & FREQUENCY_C(11 downto 8) when BUSCYCLE = R_READ and ADR = x"5" else
				"000" & NOISE_FREQ when BUSCYCLE = R_READ and ADR = x"6" else
				"000" & LEVEL_A when BUSCYCLE = R_READ and ADR = x"8" else
				"000" & LEVEL_B when BUSCYCLE = R_READ and ADR = x"9" else
				"000" & LEVEL_C when BUSCYCLE = R_READ and ADR = x"A" else
				ENV_FREQ(7 downto 0) when BUSCYCLE = R_READ and ADR = x"B" else
				ENV_FREQ(15 downto 8) when BUSCYCLE = R_READ and ADR = x"C" else
				x"0" & ENV_SHAPE when BUSCYCLE = R_READ and ADR = x"D" else (others => '0');
	DATA_EN <=	'1' when BUSCYCLE = R_READ and ADR >= x"0" and ADR <= x"6" else
				'1' when BUSCYCLE = R_READ and ADR >= x"8" and ADR <= x"D" else '0';

	MUSICGENERATOR: process(RESETn, SYS_CLK)
	variable CLK_DIV	: std_logic_vector(2 downto 0);
	variable CNT_CH_A 	: std_logic_vector(11 downto 0);
	variable CNT_CH_B 	: std_logic_vector(11 downto 0);
	variable CNT_CH_C 	: std_logic_vector(11 downto 0);
	begin
		if RESETn = '0' then
			CLK_DIV := "000";
			CNT_CH_A := (others => '0');
			CNT_CH_B := (others => '0');
			CNT_CH_C := (others => '0');
			OSC_A_OUT <= '0';
			OSC_B_OUT <= '0';
			OSC_C_OUT <= '0';
		elsif SYS_CLK = '1' and SYS_CLK' event then
			if WAV_STRB = '1' then
				-- Divider by 8 for the oscillators brings in connection 
				-- with the toggle flip flops CH_x_OUT the required divider
				-- ratio of 16.
				CLK_DIV := CLK_DIV + '1';

				if CLK_DIV = "000" then
					if FREQUENCY_A = x"000" then
						CNT_CH_A := (others => '0');
						OSC_A_OUT <= '0';
					elsif CNT_CH_A = x"000" then
						CNT_CH_A := FREQUENCY_A - '1' ;
						OSC_A_OUT <= not OSC_A_OUT;
					else
						CNT_CH_A := CNT_CH_A - '1';
					end if;

					if FREQUENCY_B = x"000" then
						CNT_CH_B := (others => '0');
						OSC_B_OUT <= '0';
					elsif CNT_CH_B = x"000" then
						CNT_CH_B := FREQUENCY_B - '1' ;
						OSC_B_OUT <= not OSC_B_OUT;
					else
						CNT_CH_B := CNT_CH_B - '1';
					end if;

					if FREQUENCY_C = x"000" then
						CNT_CH_C := (others => '0');
						OSC_C_OUT <= '0';
					elsif CNT_CH_C = x"000" then
						CNT_CH_C := FREQUENCY_C - '1' ;
						OSC_C_OUT <= not OSC_C_OUT;
					else
						CNT_CH_C := CNT_CH_C - '1';
					end if;
				end if;
			end if;
		end if;
	end process MUSICGENERATOR;

	NOISEGENERATOR: process
	-- The noise shift polynomial is taken from a template of Kazuhiro TSUJIKAWA's 
	-- (ESE Artists' factory) approach for a 2149 equivalent. But the implementation
	-- is done in another way.
	-- LFSR (linear feedback shift register polynomial: f(x) = x^17 + x^14 + 1.
	variable CLK_DIV	: std_logic_vector(3 downto 0);
	variable CNT_NOISE 	: std_logic_vector(4 downto 0);
	variable N_SHFT 	: std_logic_vector(16 downto 0);
	begin
		wait until SYS_CLK = '1' and SYS_CLK' event;
		if RESETn = '0' then
			CLK_DIV := x"0";
			CNT_NOISE := (others => '1'); -- Preset the polynomial shift register.
			NOISE_OUT <= '1';
		elsif WAV_STRB = '1' then
			-- Divider by 16 for the noise generator.
			CLK_DIV := CLK_DIV + '1';
			if CLK_DIV = x"0" then
				-- Noise frequency counter.
				if NOISE_FREQ = "00000" then
					CNT_NOISE := (others => '0');
				elsif CNT_NOISE = "00000" then
					CNT_NOISE := NOISE_FREQ - '1' ;
					N_SHFT := N_SHFT(15 downto 14) & not(N_SHFT(16) xor N_SHFT(13)) & 
													N_SHFT(12 downto 0) & not N_SHFT(16);
				else
					CNT_NOISE := CNT_NOISE - '1';
				end if;
			end if;
		end if;
		NOISE_OUT <= N_SHFT(16);
	end process NOISEGENERATOR;

	ENVELOPE_PERIOD: process(RESETn, SYS_CLK)
	-- The envelope period is controlled by the Envelope Frequency and the divider ratio which is
	-- 256/32 = 8. For further information see the original data sheet.
	variable ENV_CLK : std_logic_vector(18 downto 0);
	variable LOCK : boolean;
	begin
		if RESETn = '0' then
			ENV_STRB <= '0';
			ENV_CLK := (others => '0');
			LOCK := false;
		elsif SYS_CLK = '1' and SYS_CLK' event then
			if WAV_STRB = '1' and LOCK = false then
				LOCK := true;
				if ENV_FREQ = x"0000" then
					ENV_STRB <= '0';
				elsif ENV_CLK = x"0000" & "000" then
					ENV_CLK := (ENV_FREQ & "111") - '1' ;
					ENV_STRB <= '1';
				else
					ENV_CLK := ENV_CLK - '1';
					ENV_STRB <= '0';
				end if;
			elsif WAV_STRB = '0' then
				LOCK := false;
				ENV_STRB <= '0';
			else
				ENV_STRB <= '0';
			end if;
		end if;
	end process ENVELOPE_PERIOD;
	
	ENVELOPE: process(RESETn, SYS_CLK)
	-- Envelope shapes:
	-- case ENV_SHAPE:
	--
	-- 0 0 x x  \___
	--
	-- 0 1 x x  /|___
	--
	-- 1 0 0 0  _|\|\|\|\|
	--
	-- 1 0 0 1  \___
	--
	-- 1 0 1 0  \/\/
	--            ___
	-- 1 0 1 1  \|
	--
	-- 1 1 0 0  /|/|/|/|
	--           ___
	-- 1 1 0 1  /
	--
	-- 1 1 1 0  /\/\
	--
	-- 1 1 1 1  /|___
	--
	variable ENV_STOP	: boolean;
	variable ENV_UP_DNn	: std_logic;
	begin
		if RESETn = '0' then
			VOL_ENV <= (others => '0');
			ENV_UP_DNn := '0';
			ENV_STOP := false;
		elsif SYS_CLK = '1' and SYS_CLK' event then
			if ENV_RESET = true then
				ENV_STOP := false;
				case ENV_SHAPE is
					when "1011" | "1010" | "1001" | "1000" | "0011" | "0010" | "0001" | "0000" =>
						VOL_ENV <= "11111"; -- Start on top.
						ENV_UP_DNn := '0';
					when others =>
						VOL_ENV <= "00000"; -- Start at bottom.
						ENV_UP_DNn := '1';
				end case;
			elsif ENV_STRB = '1' then
				case ENV_SHAPE is
					when "1001" | "0011" | "0010" | "0001" | "0000"  =>
						if VOL_ENV > "00000" then
							VOL_ENV <= VOL_ENV - '1';
						end if;
					when "1111" | "0111" | "0110" | "0101" | "0100"  =>
						if VOL_ENV < "11111" and ENV_STOP = false then
							VOL_ENV <= VOL_ENV + '1';
						else
							VOL_ENV <= "00000";
							ENV_STOP := true;
						end if;
					when "1000" =>
						VOL_ENV <= VOL_ENV - '1';
					when "1110" | "1010" =>
						if ENV_UP_DNn = '0' then
							VOL_ENV <= VOL_ENV - '1';
						else
							VOL_ENV <= VOL_ENV + '1';
						end if;
						--
                        if VOL_ENV = "00001" then
							ENV_UP_DNn := '1';
                        elsif VOL_ENV = "11110" then
							ENV_UP_DNn := '0';
						end if;
					when "1011" =>
						if VOL_ENV > "00000" and ENV_STOP = false then
							VOL_ENV <= VOL_ENV - '1';
						else
							VOL_ENV <= "11111";
							ENV_STOP := true;
						end if;
					when "1100" =>
						VOL_ENV <= VOL_ENV + '1';
					when "1101" =>
						if VOL_ENV < "11111" then
							VOL_ENV <= VOL_ENV + '1';
						end if;
					when others => null; -- Covers U, X, Z, W, H, L, -.
				end case;
			end if;
		end if;
	end process ENVELOPE;

	--MIXER:
	-- The mixer controls are dependant on the mixer settings and the output of the
	-- audio data for all three channels. The noise generator and the square wave
	-- generators A, B and C are mixed together by a simple boolean OR.
	AUDIO_A <= (OSC_A_OUT and not CTRL_REG(0)) or (NOISE_OUT and not CTRL_REG(3));
	AUDIO_B <= (OSC_B_OUT and not CTRL_REG(1)) or (NOISE_OUT and not CTRL_REG(4));
	AUDIO_C <= (OSC_C_OUT and not CTRL_REG(2)) or (NOISE_OUT and not CTRL_REG(5));

	--LEVEL (e.g. volume control):
	-- The linear amplitude for the DA converters of channel A, B or C are fixed
	-- (LEVEL(3 downto 0)) or delivered by the envelope generator.
	-- The following behavior is taken from the 2149 IP core of Mike J (www.fpgaarcade.com):
	-- "make sure level 31 (env) = level 15 (tone)"
	-- Thus there is a resulting & '1' modeling if LEVEL amplitudes are selected.
	AMPLITUDE_A <= 	LEVEL_A(3 downto 0) & '1' 	when LEVEL_A(4) = '0' and AUDIO_A = '1' else
					VOL_ENV 					when LEVEL_A(4) = '1' and AUDIO_A = '1' else "00000";
	AMPLITUDE_B <= 	LEVEL_B(3 downto 0) & '1' 	when LEVEL_B(4) = '0' and AUDIO_B = '1' else
					VOL_ENV 					when LEVEL_B(4) = '1' and AUDIO_B = '1' else "00000";
	AMPLITUDE_C <= 	LEVEL_C(3 downto 0) & '1' 	when LEVEL_C(4) = '0' and AUDIO_C = '1' else
					VOL_ENV 					when LEVEL_C(4) = '1' and AUDIO_C = '1' else "00000";

	-- The values for the logarithmic DA converter volume controls are taken from the linear 
	-- mixer of Mike J's 2149 IP core (www.fpgaarcade.com).
	with AMPLITUDE_A select
						VOLUME_A <= x"FF" when "11111",
									x"D9" when "11110",
									x"BA" when "11101",
									x"9F" when "11100",
									x"88" when "11011",
									x"74" when "11010",
									x"63" when "11001",
									x"54" when "11000",
									x"48" when "10111",
									x"3D" when "10110",
									x"34" when "10101",
									x"2C" when "10100",
									x"25" when "10011",
									x"1F" when "10010",
									x"1A" when "10001",
									x"16" when "10000",
									x"13" when "01111",
									x"10" when "01110",
									x"0D" when "01101",
									x"0B" when "01100",
									x"09" when "01011",
									x"08" when "01010",
									x"07" when "01001",
									x"06" when "01000",
									x"05" when "00111",
									x"04" when "00110",
									x"03" when "00101",
									x"03" when "00100",
									x"02" when "00011",
									x"02" when "00010",
									x"01" when "00001",
									x"00" when others; -- Also covers U, X, Z, W, H, L, -.

	with AMPLITUDE_B select 
						VOLUME_B <= x"FF" when "11111",
									x"D9" when "11110",
									x"BA" when "11101",
									x"9F" when "11100",
									x"88" when "11011",
									x"74" when "11010",
									x"63" when "11001",
									x"54" when "11000",
									x"48" when "10111",
									x"3D" when "10110",
									x"34" when "10101",
									x"2C" when "10100",
									x"25" when "10011",
									x"1F" when "10010",
									x"1A" when "10001",
									x"16" when "10000",
									x"13" when "01111",
									x"10" when "01110",
									x"0D" when "01101",
									x"0B" when "01100",
									x"09" when "01011",
									x"08" when "01010",
									x"07" when "01001",
									x"06" when "01000",
									x"05" when "00111",
									x"04" when "00110",
									x"03" when "00101",
									x"03" when "00100",
									x"02" when "00011",
									x"02" when "00010",
									x"01" when "00001",
									x"00" when others; -- Also covers U, X, Z, W, H, L, -.

	with AMPLITUDE_C select
						VOLUME_C <= x"FF" when "11111",
									x"D9" when "11110",
									x"BA" when "11101",
									x"9F" when "11100",
									x"88" when "11011",
									x"74" when "11010",
									x"63" when "11001",
									x"54" when "11000",
									x"48" when "10111",
									x"3D" when "10110",
									x"34" when "10101",
									x"2C" when "10100",
									x"25" when "10011",
									x"1F" when "10010",
									x"1A" when "10001",
									x"16" when "10000",
									x"13" when "01111",
									x"10" when "01110",
									x"0D" when "01101",
									x"0B" when "01100",
									x"09" when "01011",
									x"08" when "01010",
									x"07" when "01001",
									x"06" when "01000",
									x"05" when "00111",
									x"04" when "00110",
									x"03" when "00101",
									x"03" when "00100",
									x"02" when "00011",
									x"02" when "00010",
									x"01" when "00001",
									x"00" when others; -- Also covers U, X, Z, W, H, L, -.
    
    OUT_A <= "00" & VOLUME_A;
    OUT_B <= "00" & VOLUME_B;
    OUT_C <= "00" & VOLUME_C;
	OUT_ALL_I <= OUT_A + OUT_B + OUT_C;
	OUT_ALL <= OUT_ALL_I(9 downto 2);
end architecture BEHAVIOR;
