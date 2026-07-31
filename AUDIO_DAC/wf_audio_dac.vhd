------------------------------------------------------------------------
----                                                                ----
---- ATARI IP Core peripheral Add-On				                ----
----                                                                ----
---- This file is part of the FPGA-ATARI project.                   ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- This hardware features the control of a serial DAC 'AD5302'    ----
---- from Analog Devices. The original Mega ST hardware was         ----
---- equipped with two ADC0802 parallel DACs. This controller       ----
---- uses the parallel data as the source for the serial device.    ----
----                                                                ----
---- To Do:                                                         ----
---- -                                                              ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2007... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- This source file may be used and distributed without           ----
---- restriction provided that this copyright statement is not      ----
---- removed from the file and that any derivative work contains    ----
---- the original copyright notice and the associated disclaimer.   ----
----                                                                ----
---- This source file is free software; you can redistribute it     ----
---- and/or modify it under the terms of the GNU Lesser General     ----
---- Public License as published by the Free Software Foundation;   ----
---- either version 2.1 of the License, or (at your option) any     ----
---- later version.                                                 ----
----                                                                ----
---- This source is distributed in the hope that it will be         ----
---- useful, but WITHOUT ANY WARRANTY; without even the implied     ----
---- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR        ----
---- PURPOSE. See the GNU Lesser General Public License for more    ----
---- details.                                                       ----
----                                                                ----
---- You should have received a copy of the GNU Lesser General      ----
---- Public License along with this source; if not, download it     ----
---- from http://www.gnu.org/licenses/lgpl.html                     ----
----                                                                ----
------------------------------------------------------------------------
-- 
-- Revision History
-- 
-- Revision 2K7A  2007/02/03 WF
--   Initial Release.
-- Revision 2K8A  2008/07/14 WF
--   Minor changes.
-- Revision 2K10B  2010/12/27 WF
--   Several behavioural changes.
--   Fixed distortion bug (introduced FCLK).
-- Revision 2K12A  20120620 WF
--   Changes due to audiodata is now 2's complement.
-- Revision 2K15B 20151224 WF
--   Replaced the data type bit by std_logic.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF_AUDIO_DAC is
	port (
		CLK				: in std_logic; -- Use 16MHz.
		RESETn			: in std_logic;

        FCLK            : in std_logic;

		SDATA_L			: in std_logic_vector(7 downto 0);
		SDATA_R			: in std_logic_vector(7 downto 0);
		
		DAC_SCLK		: out std_logic;
		DAC_SDATA		: out std_logic;
		DAC_SYNCn		: out std_logic;
		DAC_LDACn		: out std_logic
	);
end entity WF_AUDIO_DAC;

architecture BEHAVIOR of WF_AUDIO_DAC is
signal DAC_TX				: std_logic_vector(16 downto 0);
signal DAC_SH_CLK			: std_logic;
signal SHIFT_READY			: boolean;
signal SHIFT_EN				: boolean;
-- DAC state machine:
type DAC_CTRL_STATES is (IDLE, LOAD_L, LOAD_R, SHIFT_L, SHIFT_R, LOAD_DAC);
signal DAC_CTRL_STATE		: DAC_CTRL_STATES;
signal NEXT_DAC_CTRL_STATE	: DAC_CTRL_STATES;
begin
	DAC_SDATA 	<= DAC_TX(16); -- The MSB is shifted first.
    DAC_SCLK 	<= '1' when DAC_SH_CLK = '1' else '0';
	DAC_SYNCn 	<= '0' when SHIFT_EN = true else '1';
	DAC_LDACn   <= '0' when DAC_CTRL_STATE = LOAD_DAC else '1';

	DAC_CLOCK: process(CLK, RESETn)
	-- This process generates a DAC_SH_CLK signal with a sixteenth of the
	-- frequency of CLK.
	variable DAC_SH_CLK_COUNT: std_logic_vector(3 downto 0);
	begin
		if RESETn = '0' then
			DAC_SH_CLK_COUNT := (others => '0');
		elsif CLK = '1' and CLK' event then
			DAC_SH_CLK_COUNT := DAC_SH_CLK_COUNT + '1'; 
		end if;
		DAC_SH_CLK <= DAC_SH_CLK_COUNT(3); 	-- 1/16 of CLK.
	end process DAC_CLOCK;

	TX_SHIFT: process(RESETn, CLK)
	variable LOCK	: boolean;
	begin
		if RESETn = '0' then
			DAC_TX	 	<= '0' & x"0000";	-- 16 bit.
			LOCK		:= false;
		elsif CLK = '1' and CLK' event then
			-- The 16 DAC bits are as follows:
			-- 15: Select '0' for channel A and '1' for channel B.
			-- 14: Select '0' for unbuffered reference and '1' for buffered.
			-- 13, 12: Power down bits. See data sheet for mor information.
			-- 11 ... 4: This are the data bits.
			-- 3 ... 0: not used bits for the AD5302, don't care.
			if DAC_CTRL_STATE = LOAD_L then
				DAC_TX <=  '0' & x"0" & not SDATA_L(7) & SDATA_L(6 downto 0) & x"0"; -- Convert to linear.
			elsif DAC_CTRL_STATE = LOAD_R then
				DAC_TX <=  '0' & x"8" & not SDATA_R(7) & SDATA_R(6 downto 0) & x"0"; -- Convert to linear.
			elsif SHIFT_EN = true then -- Shift has priority.
				-- The shift register operates on the falling edge of DAC_SH_CLK
				-- due to the sampling by the DAC with the negative edge of DAC_SH_CLK.
				if DAC_SH_CLK = '1' and LOCK = false then -- Sampling on positive clock edge.
					LOCK := true; -- Operate on rising edge of DAC_SH_CLK.
					DAC_TX <= DAC_TX(15 downto 0) & DAC_TX(16); -- Rotate left, MSB first.
				elsif DAC_SH_CLK = '0' then
					LOCK := false;
				end if;
			end if;
		end if;
	end process TX_SHIFT;

	BITCNT: process(RESETn, CLK, DAC_SH_CLK)
	variable BIT_CNT 	: std_logic_vector(4 downto 0); 
	variable LOCK		: boolean;
	begin
		if RESETn = '0' then
			BIT_CNT	 	:= (others => '0');
			LOCK		:= false;
		elsif CLK = '1' and CLK' event then
			if SHIFT_EN = false then
				BIT_CNT := "10000";	-- Load 16 bit.
				LOCK := false;
			elsif DAC_SH_CLK = '1' and LOCK = false then
				LOCK := true; -- Operate on rising edge of DAC_SH_CLK.
				BIT_CNT := BIT_CNT - '1';
			elsif DAC_SH_CLK = '0' then
				LOCK := false;
			end if;
			--
			-- Wait until DAC_SH_CLK pulse finished in count state zero:
			if BIT_CNT = "00000" and DAC_SH_CLK = '0' then
				SHIFT_READY <= true;
			else
				SHIFT_READY <= false;
			end if;
		end if;
	end process BITCNT;

	DAC_CTRL_STATE_REGISTER: process
	begin
		wait until CLK = '1' and CLK' event;
		DAC_CTRL_STATE <= NEXT_DAC_CTRL_STATE;
	end process DAC_CTRL_STATE_REGISTER;

	DAC_CTRL_STATE_DECODER: process (DAC_CTRL_STATE, SHIFT_READY, DAC_SH_CLK, FCLK)
	begin
		SHIFT_EN <= false; -- Default.
		case DAC_CTRL_STATE is
            when IDLE =>
                if FCLK = '1' then
                    NEXT_DAC_CTRL_STATE <= LOAD_L;
                else
                    NEXT_DAC_CTRL_STATE <= IDLE;
                end if;
			when LOAD_L =>
				-- Start when the shift clock is not active.
				if DAC_SH_CLK = '0' then
					NEXT_DAC_CTRL_STATE <= SHIFT_L;
				else
					NEXT_DAC_CTRL_STATE <= LOAD_L;
				end if;
			when SHIFT_L =>
				if SHIFT_READY = true then
					NEXT_DAC_CTRL_STATE <= LOAD_R;
				else
					NEXT_DAC_CTRL_STATE <= SHIFT_L;
				end if;
				SHIFT_EN <= true;
			when LOAD_R =>
				-- Start when the shift clock is not active.
				if DAC_SH_CLK = '0' then
					NEXT_DAC_CTRL_STATE <= SHIFT_R;
				else
					NEXT_DAC_CTRL_STATE <= LOAD_R;
				end if;
			when SHIFT_R =>
				if SHIFT_READY = true then
					NEXT_DAC_CTRL_STATE <= LOAD_DAC;
				else
					NEXT_DAC_CTRL_STATE <= SHIFT_R;
				end if;
				SHIFT_EN <= true;
            when LOAD_DAC =>
                if FCLK = '0' then
                    NEXT_DAC_CTRL_STATE <= IDLE;
                else
                    NEXT_DAC_CTRL_STATE <= LOAD_DAC;
                end if;
		end case;
	end process DAC_CTRL_STATE_DECODER;
end architecture BEHAVIOR;
