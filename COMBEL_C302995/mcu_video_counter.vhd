------------------------------------------------------------------------
----                                                                ----
---- ATARI MCU compatible IP Core                                   ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Memory management controller with all features to reach        ----
---- ATARI Falcon compatibility. This controller handles 32 bit     ----
---- wide memory. Implementation of line doubling or interlaces     ----
---- video modi meet all requirements for the Falcon VIDEL.         ----
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
-- Revision 2K7A  2007/01/02 WF
--   Changes to the clock system and related
--   hardware as sound or video control.
-- Revision 2K8A  2008/07/14 WF
--   Minor changes.
-- Revision 2K9A  2008/12/24 WF
--   Introduced multisync compatibility modes (s. VIDEO_CNT).
-- Revision 2K21A 20211224 WF
--   This is a complete code lifting with several changes and bug fixes.
-- Revision 2K25A 20250620 WF
--   For better video quality we suppress interlaced mode for TFT / VGA monitors.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity MCU_VIDEO_COUNTER is
    generic(RAM_16              : boolean := false); -- Set true, if we have a 16 bit RAM data bus, false for 32 bit.
    port (CLK                   : in std_logic;
          RESET                 : in std_logic;
          RWn                   : in std_logic; -- Read write control.

          VIDEO_BASE_HIWORD_RS  : in std_logic; -- Hi portion of the 32 bit wide video base.
          VIDEO_BASE_LOWORD_RS  : in std_logic; -- Lo portion of the 32 bit wide video base.
          VIDEO_COUNT_HIWORD_RS : in std_logic; -- Hi portion of the 32 bit wide video counter.
          VIDEO_COUNT_LOWORD_RS : in std_logic; -- Lo portion of the 32 bit wide video counter.

          VIDEO_BASE_HI_RS      : in std_logic; -- Register control signal.
          VIDEO_BASE_MID_RS     : in std_logic; -- Register control signal.
          VIDEO_BASE_LOW_RS     : in std_logic; -- Register control signal.

          VIDEO_COUNT_HI_RS     : in std_logic; -- Register control signal.
          VIDEO_COUNT_MID_RS    : in std_logic; -- Register control signal.
          VIDEO_COUNT_LOW_RS    : in std_logic; -- Register control signal.

          R8006_SHADOW_RS       : in std_logic;
          SHMOD_ST_SHADOW_RS    : in std_logic; -- Shadow acces for the ST shift mode register located in the Videl.
          VMODE_SHADOW_RS       : in std_logic; -- Shadow acces for the video mode register located in the Videl.

          EVENn_ODD             : in std_logic; -- Interlaced video frame indicator.
          VIDEO_COUNT_EN        : in std_logic; -- Counter enable.
          VIDEO_COUNT_LOAD      : in std_logic; -- Load control.

          LINE_OFFS_RS          : in std_logic; -- Select for the STEs linewidth register.
          LINE_WIDTH_RS         : in std_logic; -- Select for the STEs linewidth register.

          VIDEO_ADR_OUT         : out std_logic_vector(31 downto 1);

          DATA_IN               : in std_logic_vector(15 downto 0);
          DATA_OUT              : out std_logic_vector(15 downto 0);
          DATA_EN               : out std_logic
        );
end MCU_VIDEO_COUNTER;

architecture BEHAVIOR of MCU_VIDEO_COUNTER is
signal VIDEO_BASE       : std_logic_vector(31 downto 0);
signal VIDEO_ADR        : std_logic_vector(31 downto 1);
signal LINEOFFSET       : std_logic_vector(8 downto 0);
signal LINEWIDTH        : std_logic_vector(9 downto 0);
signal LINE_LOAD        : std_logic;
signal LINE_RELOAD      : std_logic;
signal INTERLACED_EN    : std_logic;
signal DOUBLELINE_EN    : std_logic;
signal MTYPE            : std_logic_vector(1 downto 0); -- "11" = TV set, "10" = VGA, "01" = RGB (SC1224), "00" = SM124.
begin
    VIDEO_REGS: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            VIDEO_BASE <= (others => '0');
        elsif VIDEO_BASE_HIWORD_RS = '1' and RWn = '0' then -- x"FFFF8212"
            VIDEO_BASE(31 downto 16) <= DATA_IN;
            VIDEO_ADR(7 downto 1) <= (others => '0'); -- Clear video address low byte.
        elsif VIDEO_BASE_LOWORD_RS = '1' and RWn = '0' then -- x"FFFF8214"
            VIDEO_BASE(15 downto 0) <= DATA_IN;
            VIDEO_ADR(7 downto 1) <= (others => '0'); -- Clear video address low byte.
        elsif VIDEO_BASE_HI_RS = '1' and RWn = '0' then -- x"FFFF8201".
            VIDEO_BASE(31 downto 24) <= x"00"; -- Clear upper portion for compatibility reasons.
            VIDEO_BASE(23 downto 16) <= DATA_IN(7 downto 0);
            VIDEO_ADR(7 downto 1) <= (others => '0'); -- Clear video address low byte.
        elsif VIDEO_BASE_MID_RS = '1' and RWn = '0' then -- x"FFFF8203".
            VIDEO_BASE(15 downto 8) <= DATA_IN(7 downto 0);
            VIDEO_ADR(7 downto 1) <= (others => '0'); -- Clear video address low byte.
        elsif VIDEO_BASE_LOW_RS = '1' and RWn = '0' then -- x"FFFF820D".
            VIDEO_BASE(7 downto 0) <= DATA_IN(7 downto 0);
        end if;
        --
        if RESET = '1' then
            VIDEO_ADR <= (others => '0');
        elsif VIDEO_COUNT_HIWORD_RS = '1' and RWn = '0' then -- x"FFFF8216"
            VIDEO_ADR(31 downto 16) <= DATA_IN;
        elsif VIDEO_COUNT_LOWORD_RS = '1' and RWn = '0' then -- x"FFFF8218"
            VIDEO_ADR(15 downto 1) <= DATA_IN(15 downto 1);
        elsif VIDEO_COUNT_HI_RS = '1' and RWn = '0' then -- x"FFFF8205".
            VIDEO_ADR(31 downto 24) <= x"00"; -- Clear upper portion for compatibility reasons.
            VIDEO_ADR(23 downto 16) <= DATA_IN(7 downto 0);
        elsif VIDEO_COUNT_MID_RS = '1' and RWn = '0' then -- x"FFFF8207".
            VIDEO_ADR(15 downto 8) <= DATA_IN(7 downto 0);
        elsif VIDEO_COUNT_LOW_RS = '1' and RWn = '0' then -- x"FFFF8209".
            VIDEO_ADR(7 downto 1) <= DATA_IN(7 downto 1);
        end if;

        if VIDEO_COUNT_LOAD = '1' then -- Load has priority over counting.
            if INTERLACED_EN = '1' and EVENn_ODD = '1' then
                VIDEO_ADR <= VIDEO_BASE(31 downto 1) + LINEWIDTH; -- Load second line.
            else
                VIDEO_ADR <= VIDEO_BASE(31 downto 1);
            end if;
        elsif RAM_16 = true and VIDEO_COUNT_EN = '1' and LINE_RELOAD = '1' then
            VIDEO_ADR <= VIDEO_ADR - (LINEWIDTH - "010") + LINEOFFSET; -- Rescan one line.
        elsif RAM_16 = false and VIDEO_COUNT_EN = '1' and LINE_RELOAD = '1' then
            VIDEO_ADR <= VIDEO_ADR - (LINEWIDTH - "100") + LINEOFFSET; -- Rescan one line.
        elsif RAM_16 = true and VIDEO_COUNT_EN = '1' and LINE_LOAD = '1' then
            VIDEO_ADR <= VIDEO_ADR + LINEWIDTH + "010" + LINEOFFSET; -- Interlaced lines.
        elsif RAM_16 = false and VIDEO_COUNT_EN = '1' and LINE_LOAD = '1' then
            VIDEO_ADR <= VIDEO_ADR + LINEWIDTH + "100" + LINEOFFSET; -- Interlaced lines.
        elsif VIDEO_COUNT_EN = '1' and RAM_16 = true then
            VIDEO_ADR <= VIDEO_ADR + "010"; -- We use a burst of two WORD-16.
        elsif VIDEO_COUNT_EN = '1' then
            VIDEO_ADR <= VIDEO_ADR + "100"; -- We use a burst of two LONG-32.
        end if;
        --
        if RESET = '1' then
            LINEOFFSET <= (others => '0');
        elsif LINE_OFFS_RS = '1' and RWn = '0' then -- x"FFFF820E - FFFF820F".
            LINEOFFSET <= DATA_IN(8 downto 0);
        end if;
        --
        if RESET = '1' then -- The initial setting is ST low resolution.
            LINEWIDTH <= "0001010000";
        elsif LINE_WIDTH_RS = '1' and RWn = '0' then -- x"FFFF8210 - FFFF8211".
            LINEWIDTH <= DATA_IN(9 downto 0);
        elsif R8006_SHADOW_RS = '1' and RWn = '0' then
            MTYPE <= DATA_IN(15 downto 14); -- This is the monitor type. "10" = VGA, "01" = RGB, "00" = SM124.
        elsif SHMOD_ST_SHADOW_RS = '1' and RWn = '0' then -- Shadow for x"FFFF8260".
            case DATA_IN(9 downto 8) is -- Change Linewidth.
                when "11" | "01" | "00" => LINEWIDTH <= b"00_0101_0000"; -- x"50".
                when others => LINEWIDTH <= b"00_0010_1000"; -- x"28"
            end case;

            if MTYPE = "01" and DATA_IN(9 downto 8) = "10" then -- RGB monitor.
                INTERLACED_EN <= '1';
            else
                INTERLACED_EN <= '0';
            end if;
        end if;
        --
        if VMODE_SHADOW_RS = '1' and RWn = '0' then -- x"FFFF82C2 - FFFF82C3".
            if MTYPE = "10" then -- Do not enable interlaced mode when we use a VGA (TFT) monitor.
                INTERLACED_EN <= '0';
            else
                INTERLACED_EN <= DATA_IN(1);
            end if;
            DOUBLELINE_EN <= DATA_IN(0);
        end if;
        --
    end process VIDEO_REGS;

    P_LINEDOUBLING: process
    -- This logic controls the double line mode. If enabled i.e.
    -- DOUBLELINE_EN = '1' the word counter counts the lines of
    -- a line already processed (shifted out in the VIDEL). In
    -- the end of the line the video counter is reloaded with
    -- the start address of the respective line or the next line
    -- is addressed depending of the toggle flip flop SECOND_LINE.
    -- Be aware that we have a 32 bit video data bus so that the
    -- address always increments by two words. This results in a
    -- logic which requires long word boundaries of the scan lines
    -- or in other words the LINEWIDTH must have a value which is
    -- dividable by four.
    variable SECOND_LINE        : std_logic;
    variable VIDEO_WORD_CNT     : std_logic_vector(9 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        if VIDEO_COUNT_LOAD = '1' or DOUBLELINE_EN = '0' then
            SECOND_LINE := '0';
            VIDEO_WORD_CNT := (others => '0');
            LINE_RELOAD <= '0';
        elsif RAM_16 = true and VIDEO_COUNT_EN = '1' and VIDEO_WORD_CNT < LINEWIDTH - "010" then
            VIDEO_WORD_CNT := VIDEO_WORD_CNT + "010"; -- We fetch two 16 bit WORD in a burst.

            if VIDEO_WORD_CNT = LINEWIDTH - "010" and SECOND_LINE = '0' then
                LINE_RELOAD <= '1';
            else
                LINE_RELOAD <= '0';
            end if;
        elsif RAM_16 = false and VIDEO_COUNT_EN = '1' and VIDEO_WORD_CNT < LINEWIDTH - "100" then
            VIDEO_WORD_CNT := VIDEO_WORD_CNT + "100"; -- We fetch two 32 bit LONG in a burst.

            if VIDEO_WORD_CNT = LINEWIDTH - "100" and SECOND_LINE = '0' then
                LINE_RELOAD <= '1';
            else
                LINE_RELOAD <= '0';
            end if;
        elsif VIDEO_COUNT_EN = '1' then
            VIDEO_WORD_CNT := (others => '0');
            SECOND_LINE := not SECOND_LINE;
            LINE_RELOAD <= '0';
        end if;
    end process P_LINEDOUBLING;

    INTERLACED_CONTROL: process
    -- This logic controls the correct loading of the video counter
    -- addresses in the interlaced video mode. Each end of a video line
    -- the signal LINE_LOAD is asserted. This causes the video counter
    -- address to be incremented by the line offset.
    variable VIDEO_WORD_CNT     : std_logic_vector(9 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        if VIDEO_COUNT_LOAD = '1' or INTERLACED_EN = '0' then
            VIDEO_WORD_CNT := (others => '0');
            LINE_LOAD <= '0';
        elsif RAM_16 = true and VIDEO_COUNT_EN = '1' and VIDEO_WORD_CNT < LINEWIDTH - "010" then
            VIDEO_WORD_CNT := VIDEO_WORD_CNT + "010"; -- We fetch two 16 bit WORD in a burst.

            if VIDEO_WORD_CNT = LINEWIDTH - "010" then
                LINE_LOAD <= '1';
            else
                LINE_LOAD <= '0';
            end if;
        elsif RAM_16 = false and VIDEO_COUNT_EN = '1' and VIDEO_WORD_CNT < LINEWIDTH - "100" then
            VIDEO_WORD_CNT := VIDEO_WORD_CNT + "100"; -- We fetch two 32 bit LONG in a burst.

            if VIDEO_WORD_CNT = LINEWIDTH - "100" then
                LINE_LOAD <= '1';
            else
                LINE_LOAD <= '0';
            end if;
        elsif VIDEO_COUNT_EN = '1' then
            VIDEO_WORD_CNT := (others => '0');
            LINE_LOAD <= '0';
        end if;
    end process INTERLACED_CONTROL;

    -- Read registers.
    DATA_OUT <= VIDEO_BASE(31 downto 16) when VIDEO_BASE_HIWORD_RS = '1' and RWn = '1' else -- WORD access.
                VIDEO_BASE(15 downto 0) when VIDEO_BASE_LOWORD_RS = '1' and RWn = '1' else -- WORD access.
                VIDEO_BASE(23 downto 16) & VIDEO_BASE(23 downto 16) when VIDEO_BASE_HI_RS = '1' and RWn = '1' else
                VIDEO_BASE(15 downto 8) & VIDEO_BASE(15 downto 8) when VIDEO_BASE_MID_RS = '1' and RWn = '1' else
                VIDEO_BASE(7 downto 0) & VIDEO_BASE(7 downto 0) when VIDEO_BASE_LOW_RS = '1' and RWn = '1' else
                VIDEO_ADR(31 downto 16) when VIDEO_COUNT_HIWORD_RS = '1' and RWn = '1' else -- WORD access.
                VIDEO_ADR(15 downto 1) & '0' when VIDEO_COUNT_LOWORD_RS = '1' and RWn = '1' else -- WORD access.
                VIDEO_ADR(23 downto 16) & VIDEO_ADR(23 downto 16) when VIDEO_COUNT_HI_RS = '1' and RWn = '1' else
                VIDEO_ADR(15 downto 8) & VIDEO_ADR(15 downto 8) when VIDEO_COUNT_MID_RS = '1' and RWn = '1' else
                VIDEO_ADR(7 downto 1) & '0' & VIDEO_ADR(7 downto 1) & '0' when VIDEO_COUNT_LOW_RS = '1' and RWn = '1' else
                "0000000" & LINEOFFSET when LINE_OFFS_RS = '1' and RWn = '1' else
                "000000" & LINEWIDTH when LINE_WIDTH_RS = '1' and RWn = '1' else (others => '0');

    DATA_EN <=  (VIDEO_BASE_HIWORD_RS or VIDEO_BASE_LOWORD_RS or VIDEO_COUNT_HIWORD_RS or VIDEO_COUNT_LOWORD_RS or
                 LINE_WIDTH_RS or LINE_OFFS_RS or VIDEO_BASE_HI_RS or VIDEO_BASE_MID_RS or VIDEO_BASE_LOW_RS or
                 VIDEO_COUNT_HI_RS or VIDEO_COUNT_MID_RS or VIDEO_COUNT_LOW_RS) and RWn;

    VIDEO_ADR_OUT <= VIDEO_ADR;
end architecture BEHAVIOR;
