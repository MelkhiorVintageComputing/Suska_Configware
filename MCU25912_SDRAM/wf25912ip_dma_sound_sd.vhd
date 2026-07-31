------------------------------------------------------------------------
----                                                                ----
---- ATARI MCU compatible IP Core                                   ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Memory management controller with all features to reach        ----
---- ATARI STE compatibility.                                       ----
----                                                                ----
---- The DMA sound is a feature of the STE series. It is            ----
---- originally implemented in the memory controller unit (MCU).    ----
---- Therefore the DMA sound module is also implemented in this     ----
---- MCU core.                                                      ----
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
---- Copyright © 2005... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K6A  2006/06/03 WF
--   Initial Release.
-- Revision 2K7A  2007/01/02 WF
--   Changes to the clock system and related
--   hardware as sound or video control.
-- Revision 2K8A  2008/07/14 WF
--    Minor changes.
-- Revision 2K10B  2010/12/27 WF
--    A bunch of changes in this logic. 
-- Revision 2K12A  20120620 WF
--    A minor change concerning SINTn. 
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--

use work.wf25912ip_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF25912IP_DMA_SOUND_SD is
port (  RESETn          : in std_logic;
        CLK             : in std_logic;
        
        RWn             : in std_logic;
        DATA_IN         : in std_logic_vector(7 downto 0);
        DATA_OUT        : out std_logic_vector(7 downto 0);
        DATA_EN         : out std_logic;

        MONOCHROME      : in std_logic;     -- Monochrome monitor detect.

        SINTn           : out std_logic;    -- Interrupt flag.
        SINT_TAI        : out std_logic;    -- Interrupt filtered for timer A.
        SINT_IO7        : out std_logic;    -- Interrupt XORed for MFP_IO7
        FRAME_CNT_EN    : in std_logic;     -- Register access enable.
        SREQ            : in std_logic;     -- SHIFTER sound data request.
        SOUND_REQ       : out boolean;      -- DMA control flag.
        CODEC_4299_DMA  : out std_logic;    -- Enable the Codec in DMA mode.
        
        SOUND_CTRL_CS               : in std_logic;
        SOUND_FRAME_START_HI_CS     : in std_logic;
        SOUND_FRAME_START_MID_CS    : in std_logic;
        SOUND_FRAME_START_LOW_CS    : in std_logic;
        SOUND_FRAME_ADR_HI_CS       : in std_logic;
        SOUND_FRAME_ADR_MID_CS      : in std_logic;
        SOUND_FRAME_ADR_LOW_CS      : in std_logic;
        SOUND_FRAME_END_HI_CS       : in std_logic;
        SOUND_FRAME_END_MID_CS      : in std_logic;
        SOUND_FRAME_END_LOW_CS      : in std_logic;
        
        DMA_SOUND_ADR               : out std_logic_vector(23 downto 1)
      );
end WF25912IP_DMA_SOUND_SD;

architecture BEHAVIOR of WF25912IP_DMA_SOUND_SD is
signal SOUND_CONTROL        : std_logic_vector(7 downto 0);
signal SOUND_FRAME_START    : std_logic_vector(23 downto 0);
signal FRAME_START_BUFFER   : std_logic_vector(23 downto 0);
signal SOUND_FRAME_ADR      : std_logic_vector(23 downto 0);
signal SOUND_FRAME_END      : std_logic_vector(23 downto 0);
signal FRAME_END_BUFFER     : std_logic_vector(23 downto 0);
signal SINT_In              : std_logic;
signal DMA_OFF              : boolean;
signal FRAME_REPEAT         : boolean;
begin
    SINTn <= SINT_In;
    SINT_IO7 <= SINT_In xor MONOCHROME;
    DMA_OFF <= true when SOUND_CONTROL(0) = '0' else false;
    FRAME_REPEAT <= true when SOUND_CONTROL(1) = '1' else false;
    CODEC_4299_DMA <= '1' when DMA_OFF = false else '0';
    SOUND_REQ <= true when SREQ = '1' and DMA_OFF = false and FRAME_REPEAT = true else
                 true when SREQ = '1' and DMA_OFF = false and SOUND_FRAME_ADR < FRAME_END_BUFFER else
                 true when SREQ = '1' and DMA_OFF = false and SOUND_FRAME_ADR = FRAME_END_BUFFER and FRAME_CNT_EN = '0' else false; -- Until the last word is written.

    P_SINT: process(RESETn, CLK)
    -- This process provides the SINTn logic and a filter for the SINTn signal.
    -- In the original machine there were 8 shift stages working on a 2MHz clock.
    -- Here 64 stages with 16MHz are used.
    variable TMP : std_logic_vector(63 downto 0);
    begin
        if RESETn = '0' then
            TMP := (others => '0');
        elsif CLK = '1' and CLK' event then
            if DMA_OFF = true then
                SINT_In <= '1';
            elsif SOUND_FRAME_ADR = FRAME_START_BUFFER then
                SINT_In <= '0';
            elsif SOUND_FRAME_ADR = FRAME_END_BUFFER then
                SINT_In <= '1';
            end if;
            --
            if SINT_In = '1' then
                TMP := (others => '0');
            else
                TMP := TMP(62 downto 0) & '1'; -- Left shift.
            end if;
        end if;
        SINT_TAI <= TMP(63);
    end process P_SINT;

    SOUND_REGS: process(RESETn, CLK)
    -- This process contains the DMA sound relevant registers.
    begin
        if RESETn = '0' then
            SOUND_CONTROL       <= (others => '0');
            SOUND_FRAME_START   <= (others => '0');
            SOUND_FRAME_ADR     <= (others => '0');
            SOUND_FRAME_END     <= (others => '0');
            FRAME_START_BUFFER  <= (others => '0');
            FRAME_END_BUFFER    <= (others => '0');
        elsif CLK = '1' and CLK' event then
            -- Write to registers; SOUND_FRAME_ADR is read only.
            if SOUND_CTRL_CS = '1' and RWn = '0' then
                SOUND_CONTROL <= DATA_IN;
            elsif SOUND_FRAME_ADR = FRAME_END_BUFFER and FRAME_CNT_EN = '1' and FRAME_REPEAT = false then
                SOUND_CONTROL <= x"00"; -- Switch off the DMA unit when ready.
            elsif SOUND_FRAME_START_HI_CS = '1' and RWn = '0' then
                SOUND_FRAME_START(23 downto 16) <= DATA_IN;
            elsif SOUND_FRAME_START_MID_CS = '1' and RWn = '0' then
                SOUND_FRAME_START(15 downto 8) <= DATA_IN;
            elsif SOUND_FRAME_START_LOW_CS = '1' and RWn = '0' then
                SOUND_FRAME_START(7 downto 0) <= DATA_IN;
            elsif SOUND_FRAME_END_HI_CS = '1' and RWn = '0' then
                SOUND_FRAME_END(23 downto 16) <= DATA_IN;
            elsif SOUND_FRAME_END_MID_CS = '1' and RWn = '0' then
                SOUND_FRAME_END(15 downto 8) <= DATA_IN;
            elsif SOUND_FRAME_END_LOW_CS = '1' and RWn = '0' then
                SOUND_FRAME_END(7 downto 0) <= DATA_IN;
            end if;
            
            if DMA_OFF = true then -- Switched off.
                FRAME_START_BUFFER <= SOUND_FRAME_START;
                FRAME_END_BUFFER <= SOUND_FRAME_END;
                SOUND_FRAME_ADR <= FRAME_START_BUFFER;
            elsif SOUND_FRAME_ADR < FRAME_END_BUFFER and FRAME_CNT_EN = '1' then
                SOUND_FRAME_ADR <= SOUND_FRAME_ADR + '1'; -- Count.
            elsif FRAME_CNT_EN = '1' and FRAME_REPEAT = true then -- Reload.
                FRAME_START_BUFFER <= SOUND_FRAME_START;
                FRAME_END_BUFFER <= SOUND_FRAME_END;
                SOUND_FRAME_ADR <= FRAME_START_BUFFER;
            end if;
        end if;
    end process SOUND_REGS;

    -- Read registers:
    DATA_OUT <= SOUND_CONTROL when SOUND_CTRL_CS = '1' and RWn = '1' else
                SOUND_FRAME_START(23 downto 16) when SOUND_FRAME_START_HI_CS = '1' and RWn = '1' else
                SOUND_FRAME_START(15 downto 8) when SOUND_FRAME_START_MID_CS = '1' and RWn = '1' else
                SOUND_FRAME_START(7 downto 0) when SOUND_FRAME_START_LOW_CS = '1' and RWn = '1' else
                SOUND_FRAME_ADR(23 downto 16) when SOUND_FRAME_ADR_HI_CS = '1' and RWn = '1' else
                SOUND_FRAME_ADR(15 downto 8) when SOUND_FRAME_ADR_MID_CS = '1' and RWn = '1' else
                SOUND_FRAME_ADR(7 downto 0) when SOUND_FRAME_ADR_LOW_CS = '1' and RWn = '1' else
                SOUND_FRAME_END(23 downto 16) when SOUND_FRAME_END_HI_CS = '1' and RWn = '1' else
                SOUND_FRAME_END(15 downto 8) when SOUND_FRAME_END_MID_CS = '1' and RWn = '1' else
                SOUND_FRAME_END(7 downto 0) when SOUND_FRAME_END_LOW_CS = '1' and RWn = '1' else (others => '0');

    DATA_EN <= (SOUND_FRAME_START_HI_CS or SOUND_FRAME_START_MID_CS or SOUND_FRAME_START_LOW_CS or 
                SOUND_FRAME_ADR_HI_CS or SOUND_FRAME_ADR_MID_CS or SOUND_FRAME_ADR_LOW_CS or 
                SOUND_FRAME_END_HI_CS or SOUND_FRAME_END_MID_CS or SOUND_FRAME_END_LOW_CS or SOUND_CTRL_CS) and RWn;
    
    DMA_SOUND_ADR <= SOUND_FRAME_ADR(23 downto 1);
end architecture BEHAVIOR;
