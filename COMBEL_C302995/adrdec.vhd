--------------------------------------------------------------------------------
----                                                                        ----
---- ATARI compatible IP Core                                               ----
----                                                                        ----
---- This file is part of the SUSKA ATARI clone project.                    ----
---- http://www.experiment-s.de                                             ----
----                                                                        ----
---- Description:                                                           ----
---- Atari's COMBEL with all features to reach                              ----
---- ATARI Falcon compatibility. This is the address decoder.               ----
----                                                                        ----
---- Address decoder file.                                                  ----
----                                                                        ----
----                                                                        ----
---- To Do:                                                                 ----
---- -                                                                      ----
----                                                                        ----
---- Author(s):                                                             ----
----   Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de             ----
----   Udo Matthe, umatthe@web.de                                           ----
----                                                                        ----
--------------------------------------------------------------------------------
---- MCU register addresses (access in superuser mode):                     ----
---- VIDEO_BASE_HI    : x"FF8201" read-write.                               ----
---- VIDEO_BASE_MID   : x"FF8203" read-write.                               ----
---- VIDEO_BASE_LOW   : x"FF820C" read-write, STE only.                     ----
----                                                                        ----
---- VIDEO_COUNT_HI   : x"FF8205" ST: read, STE (implemented): read-write.  ----
---- VIDEO_COUNT_MID  : x"FF8207" ST: read, STE (implemented): read-write.  ----
---- VIDEO_COUNT_LOW  : x"FF8209" ST: read, STE (implemented): read-write.  ----
----                                                                        ----
---- MEM_CONFIG       : x"FF8001" read-write.                               ----
---- LINE_OFFS        : x"FF820E" read-write, STE only.                     ----
---- LINE_WIDTH       : x"FF8210" read-write, STE only.                     ----
--------------------------------------------------------------------------------
----                                                                        ----
---- Copyright © 2009... Wolfgang Foerster - Inventronik GmbH.              ----
---- Copyright © 2023... Udo Matthe.                                        ----
----                                                                        ----
---- All rights reserved. No portion of this sourcecode may be              ----
---- reproduced or transmitted in any form by any means, whether            ----
---- by electronic, mechanical, photocopying, recording or                  ----
---- otherwise, without my written permission.                              ----
----                                                                        ----
--------------------------------------------------------------------------------
--
-- Revision History
--
-- Revision 2K9B  2009/12/24 WF
--   Initial Release.
-- Revision 2K14B  2014/12/24 WF
--   Update to the Suska-III-C level.
-- Revision 2K21A 20211224 WF
--   Code clean ups.
--   Implemented support for the RP5C15 real time clock.
--   Introduced an explicit user mode to avoid CPU space mismatch.
--   We have now ALTRAM.
-- Revision 2K21A 20220620 WF
--   USB1160 addressdecoding changes.
-- Revision 2K23A 20230620 UMA
--   Implemented Udo Matthe Shadow TOS.
-- Revision 2K23B 20231224
--   Extra RAM from => x"00E80000" to < x"00F00000".
-- Revision 2K24A 20240620
--   SCC enhancements.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ADRDEC is
    port(
        ADR                     : in std_logic_vector(31 downto 1); --Adress inputs.
        RWn                     : in std_logic; -- Read write control.

        LDSn                    : in std_logic; -- Lower data strobe; not used so far.
        UDSn                    : in std_logic; -- Upper data strobe.

        ASn                     : in std_logic; -- Adress strobe signal indicates valid adress.
        VPAn                    : out std_logic; -- Valid peripheral adress.
        VMAn                    : in std_logic; -- Valid memory adress; for 6850 (ACIA) access.

        FC                      : in std_logic_vector(2 downto 0); -- Processor function codes.

        ROM_0n                  : out std_logic; -- Adress select bit for ROM 0, (compatibility to ST/STE hardware), active low.
        ROM_1n                  : out std_logic; -- Adress select bit for ROM 1, (compatibility to ST/STE hardware), active low.
        ROM_2n                  : out std_logic; -- Adress select bit for ROM 2, (compatibility to ST/STE hardware), active low.
        ROM_3n                  : out std_logic; -- Adress select bit for ROM 3, (compatibility to ST/STE hardware), active low.
        ROM_4n                  : out std_logic; -- Adress select bit for ROM 4, (compatibility to ST/STE hardware), active low.
        ROM_5n                  : out std_logic; -- Adress select bit for ROM 3, (compatibility to ST/STE hardware), active low.
        ROM_6n                  : out std_logic; -- Adress select bit for ROM 4, (compatibility to ST/STE hardware), active low.
        ACIACS                  : out std_logic; -- Select signal for the ACIA.
        MFPCSn                  : out std_logic; -- Select signal for the MFP.
        SNDCSn                  : out std_logic; -- Select signal for the SOUND.
        SCCn                    : out std_logic; -- Select signal for the SCC chip.
        SCCABn                  : out std_logic; -- SCC channel A ('1') or B ('0') select.
        RTCCS                   : out std_logic; -- Select signal for the DS1287 real time clock.
        RP5C15_CS               : out std_logic; -- Select signal for the RP5C15 real time clock.
        JOY_RS                  : out std_logic; -- Joystick read and write register chip select.
        PAD0X_RS                : out std_logic; -- Paddle counter register chip select.
        PAD0Y_RS                : out std_logic; -- Paddle counter register chip select.
        PAD1X_RS                : out std_logic; -- Paddle counter register chip select.
        PAD1Y_RS                : out std_logic; -- Paddle counter register chip select.
        BUTTON_RS               : out std_logic; -- Button register chip select.

        R8006_RS                : out std_logic; -- Falcon's configuration register, R.
        R8007_RS                : out std_logic; -- Falcon's configuration register, RW.
        FPUCS                   : out std_logic; -- This is the floating point processor.

        VCS                     : out std_logic; -- Videl chip select.

        MEM_CONFIG_RS           : out std_logic; -- Select for the memory configuration register.
        LINE_OFFS_RS            : out std_logic; -- Select for the linewidth register.
        LINE_WIDTH_RS           : out std_logic; -- Select for the linewidth register.

        VIDEO_BASE_HIWORD_RS    : out std_logic; -- Hi portion of the 32 bit wide video base.
        VIDEO_BASE_LOWORD_RS    : out std_logic; -- Lo portion of the 32 bit wide video base.
        VIDEO_COUNT_HIWORD_RS   : out std_logic; -- Hi portion of the 32 bit wide video counter.
        VIDEO_COUNT_LOWORD_RS   : out std_logic; -- Lo portion of the 32 bit wide video counter.

        VIDEO_BASE_HI_RS        : out std_logic; -- Select for the video base register.
        VIDEO_BASE_MID_RS       : out std_logic; -- Select for the video base register.
        VIDEO_BASE_LOW_RS       : out std_logic; -- Select for the video base register.

        VIDEO_COUNT_HI_RS       : out std_logic; -- Select for the video address counter.
        VIDEO_COUNT_MID_RS      : out std_logic; -- Select for the video address counter.
        VIDEO_COUNT_LOW_RS      : out std_logic; -- Select for the video address counter.

        SHMOD_ST_SHADOW_RS      : out std_logic; -- Shadow acces for the ST shift mode register located in the Videl.
        SHMOD_F_SHADOW_RS       : out std_logic; -- Shadow acces for the Falcon shift mode register located in the Videl.
        VMODE_SHADOW_RS         : out std_logic; -- Shadow acces for the video mode register located in the Videl.

        RAM_16MB                : in std_logic; -- RAM size.
        RAM_512MB               : in std_logic; -- RAM size.
        RAMn                    : out std_logic; -- Ram select signal.
        ALTRAMn                 : out std_logic; -- Ram select signal.
        Lightning_CSn           : out std_logic; -- Lightning-CPLD Dummy
        SHADOW_TOS_CSn          : out std_logic; -- Shadow TOS configuration register.
        USB1160_CSn             : out std_logic -- ISP1160 compatible core.
          );
end ADRDEC;

architecture BEHAVIOR of ADRDEC is
alias ADR_HI    : std_logic_vector(31 downto 16) is ADR(31 downto 16);
signal ADR_I    : std_logic_vector(31 downto 0);
signal SU       : boolean; -- Superuser.
signal US       : boolean; -- Normal user.
begin
    SU <= true when FC = "101" or FC = "110" else false; -- Superuser mode.
    US <= true when FC = "001" or FC = "010" else false; -- User mode.
    
    ADR_I <= ADR & '0'; -- We use word address

    ROM_6n <= '0' when (SU = true or US = true) and ASn = '0' and RWn = '1' and ADR_HI >= x"00FA" and ADR_HI < x"00FC" else '1'; -- Cartridge ROM.
    ROM_5n <= '0' when (SU = true or US = true) and ASn = '0' and RWn = '1' and ADR_HI >= x"00FE" and ADR_HI < x"00FF" else '1'; -- Cartridge ROM
    ROM_4n <= '0' when (SU = true or US = true) and ASn = '0' and RWn = '1' and ADR_HI >= x"00FA" and ADR_HI < x"00FB" else '1'; -- Cartridge ROM.
    ROM_3n <= '0' when (SU = true or US = true) and ASn = '0' and RWn = '1' and ADR_HI >= x"00FB" and ADR_HI < x"00FC" else '1'; -- Cartridge ROM.
    ROM_2n <= '0' when (SU = true or US = true) and ASn = '0' and RWn = '1' and ADR_HI >= x"00E0" and ADR_HI < x"00E8" else -- 512K TOS ROMs.
              '0' when (SU = true or US = true) and ASn = '0' and RWn = '1' and ADR_I < x"00000008" else '1'; -- TOS mirroring.
    ROM_1n <= '0' when (SU = true or US = true) and ASn = '0' and RWn = '1' and ADR_HI >= x"00E0" and ADR_HI < x"00E2" else '1'; -- STE TOS ROM LO for compatibility.
    ROM_0n <= '0' when (SU = true or US = true) and ASn = '0' and RWn = '1' and ADR_HI >= x"00E2" and ADR_HI < x"00E4" else '1'; -- STE TOS ROM HI for compatibility.

    R8006_RS <= '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8006" and RWn = '1' and SU = true else '0'; -- Read only.
    R8007_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8006" and SU = true else '0';

    -- Memo-mapped chip selects:
    -- Select ACIA, write access in SU mode:
    ACIACS <= '1' when ASn = '0' and ADR_I >= x"FFFFFC00" and ADR_I < x"FFFFFC08" and RWn = '0' and SU = true and VMAn = '0' else
              '1' when ASn = '0' and ADR_I >= x"FFFFFC00" and ADR_I < x"FFFFFC08" and RWn = '1' and (SU = true or US = true ) and VMAn = '0' else '0';

    -- Synchronous bus controlling:
    VPAn <= '0' when ASn = '0' and ADR_I >= x"FFFFFC00" and ADR_I < x"FFFFFC08" and RWn = '0' and SU = true else -- Validation for ACIACSn.
            '0' when ASn = '0' and ADR_I >= x"FFFFFC00" and ADR_I < x"FFFFFC08" and RWn = '1' and (SU = true or US = true) else -- Validation for ACIACSn.
            '0' when ASn = '0' and ADR_I >= x"FFFFFC20" and ADR_I < x"FFFFFC40" and RWn = '0' and SU = true else -- Validation for RP5C15 RTC.
            '0' when ASn = '0' and ADR_I >= x"FFFFFC20" and ADR_I < x"FFFFFC40" and RWn = '1' and (SU = true or US = true) else '1'; -- Validation for RP5C15 RTC.

    -- Select MFP (8 bit access), write access in superuser mode:
    MFPCSn <=   '0' when ASn = '0' and ADR_I >= x"FFFFFA00" and ADR_I < x"FFFFFA40" and  RWn = '0' and SU = true else
                '0' when ASn = '0' and ADR_I >= x"FFFFFA00" and ADR_I < x"FFFFFA40" and RWn = '1' and (SU = true or US = true) else '1';

    -- Select Sound (8 bit access), write access in SU mode:
    SNDCSn <=   '0' when ASn = '0' and UDSn = '0' and (ADR_I = x"FFFF8800" or ADR_I = x"FFFF8802") and RWn = '0' and SU = true else
                '0' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8800" and  RWn = '1' and (SU = true or US = true) else '1';

    -- Write access only in SU mode:
    SCCn <= '0' when ASn = '0' and ADR_I = x"FFFF8C80" and RWn = '0' and SU = true else
            '0' when ASn = '0' and ADR_I = x"FFFF8C82" and RWn = '0' and SU = true else
            '0' when ASn = '0' and ADR_I = x"FFFF8C84" and RWn = '0' and SU = true else
            '0' when ASn = '0' and ADR_I = x"FFFF8C86" and RWn = '0' and SU = true else
            '0' when ASn = '0' and ADR_I = x"FFFF8C80" and RWn = '1' and (SU = true or US = true) else
            '0' when ASn = '0' and ADR_I = x"FFFF8C82" and RWn = '1' and (SU = true or US = true) else
            '0' when ASn = '0' and ADR_I = x"FFFF8C84" and RWn = '1' and (SU = true or US = true) else
            '0' when ASn = '0' and ADR_I = x"FFFF8C86" and RWn = '1' and (SU = true or US = true) else '1';

    SCCABn <= '1' when ASn = '0' and ADR_I = x"FFFF8C80" and (SU = true or US = true) else
              '1' when ASn = '0' and ADR_I = x"FFFF8C82" and (SU = true or US = true) else '0';

    -- Read access only for the buttons:
    BUTTON_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF9200" and RWn = '1' and (SU = true or US = true) else '0'; -- Read only, 16 bit.

    -- Write access only in supervisor mode:
    JOY_RS <= '1' when ASn = '0' and ADR_I = x"FFFF9202" and RWn = '0' and SU = true else
              '1' when ASn = '0' and ADR_I = x"FFFF9202" and RWn = '1' and (SU = true or US = true) else '0';

    PAD0X_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF9210" and RWn = '1' and (SU = true or US = true) else '0'; -- Read only
    PAD0Y_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF9212" and RWn = '1' and (SU = true or US = true) else '0'; -- Read only
    PAD1X_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF9214" and RWn = '1' and (SU = true or US = true) else '0'; -- Read only
    PAD1Y_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF9216" and RWn = '1' and (SU = true or US = true) else '0'; -- Read only

    -- Floating point coprocessor:
    FPUCS <= '1' when ASn = '0' and UDSn = '0' and ADR_I(31 downto 4) = x"FFFFFA4" and SU = true else
             '1' when ASn = '0' and UDSn = '0' and ADR_I(31 downto 4) = x"FFFFFA4" and SU = true else '0';

    -- Select RTC DS1287 / MC146818A, write access in supervisor mode (x"8961", x"8963"):
    RTCCS <= '1' when ASn = '0' and LDSn = '0' and (ADR_I = x"FFFF8960" or ADR_I = x"FFFF8962") and RWn = '0' and SU = true else
             '1' when ASn = '0' and LDSn = '0' and (ADR_I = x"FFFF8960" or ADR_I = x"FFFF8962") and RWn = '1' and (SU = true or US = true) else '0';

    -- Select RTC RP5C15, write access in supervisor mode:
    RP5C15_CS <= '1' when ASn = '0' and ADR_I >= x"FFFFFC20" and ADR_I < x"FFFFFC40" and RWn = '0' and SU = true else
                 '1' when ASn = '0' and ADR_I >= x"FFFFFC20" and ADR_I < x"FFFFFC40" and RWn = '1' and (SU = true or US = true) else '0';

    MEM_CONFIG_RS <= '1' when ADR_I = x"FFFF8000" and ASn = '0' and LDSn = '0' and SU = true else '0'; -- Via LDSn x"FFFF8001".

    VCS <=  '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8006" and SU = true else -- Monitor type.
            '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF820A" and SU = true else -- All: Sync mode register.
            '1' when ASn = '0' and ADR_I = x"FFFF8210" and SU = true else -- All: line width register.
            '1' when ASn = '0' and ADR_I(31 downto 4) = x"FFFF824" and SU = true else -- ST(E): Palette registers.
            '1' when ASn = '0' and ADR_I(31 downto 4) = x"FFFF825" and SU = true else -- ST(E): Palette registers.
            '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8260" and SU = true else -- ST(E): Shift mode register.
            '1' when ASn = '0' and ADR_I = x"FFFF8264" and SU = true else -- All: HSCROLL register.
            '1' when ASn = '0' and ADR_I = x"FFFF8266" and SU = true else -- Falcon: Shift mode register.
            '1' when ASn = '0' and ADR_I = x"FFFF8280" and SU = true else -- Falcon: Horizontal hold counter.
            '1' when ASn = '0' and ADR_I = x"FFFF8282" and SU = true else -- Falcon: Horizontal hold timer.
            '1' when ASn = '0' and ADR_I = x"FFFF8284" and SU = true else -- Falcon: Horizontal boarder begin.
            '1' when ASn = '0' and ADR_I = x"FFFF8286" and SU = true else -- Falcon: Horizontal boarder end.
            '1' when ASn = '0' and ADR_I = x"FFFF8288" and SU = true else -- Falcon: Horizontal display begin.
            '1' when ASn = '0' and ADR_I = x"FFFF828A" and SU = true else -- Falcon: Horizontal display end.
            '1' when ASn = '0' and ADR_I = x"FFFF828C" and SU = true else -- Falcon: Horizontal sync start.
            '1' when ASn = '0' and ADR_I = x"FFFF828E" and SU = true else -- Falcon: Horizontal FS.
            '1' when ASn = '0' and ADR_I = x"FFFF8290" and SU = true else -- Falcon: Horizontal EE.
            '1' when ASn = '0' and ADR_I = x"FFFF82A0" and SU = true else -- Falcon: Vertical frequency counter.
            '1' when ASn = '0' and ADR_I = x"FFFF82A2" and SU = true else -- Falcon: Vertical frequency timer.
            '1' when ASn = '0' and ADR_I = x"FFFF82A4" and SU = true else -- Falcon: Vertical boarder begin.
            '1' when ASn = '0' and ADR_I = x"FFFF82A6" and SU = true else -- Falcon: Vertical boarder end.
            '1' when ASn = '0' and ADR_I = x"FFFF82A8" and SU = true else -- Falcon: Vertical display begin.
            '1' when ASn = '0' and ADR_I = x"FFFF82AA" and SU = true else -- Falcon: Vertical display end.
            '1' when ASn = '0' and ADR_I = x"FFFF82AC" and SU = true else -- Falcon: Vertical sync start.
            '1' when ASn = '0' and ADR_I = x"FFFF82C0" and SU = true else -- Falcon: Video control.
            '1' when ASn = '0' and ADR_I = x"FFFF82C2" and SU = true else -- Falcon: Video mode.
            '1' when ASn = '0' and ADR_I = x"FFFF9220" and LDSn = '1' and SU = true else -- XPEN.
            '1' when ASn = '0' and ADR_I = x"FFFF9222" and LDSn = '1' and SU = true else -- YPEN.
            '1' when ASn = '0' and ADR_I(31 downto 8) = x"FFFF98" and SU = true else -- Falcon pallette registers.
            '1' when ASn = '0' and ADR_I(31 downto 8) = x"FFFF99" and SU = true else -- Falcon pallette registers.
            '1' when ASn = '0' and ADR_I(31 downto 8) = x"FFFF9A" and SU = true else -- Falcon pallette registers.
            '1' when ASn = '0' and ADR_I(31 downto 8) = x"FFFF9B" and SU = true else '0'; -- Falcon pallette registers.

    VIDEO_BASE_HI_RS <= '1' when ADR_I = x"FFFF8200" and ASn = '0' and LDSn = '0' and SU = true else '0'; -- Via LDSn x"FFFF8201".
    VIDEO_BASE_MID_RS <= '1' when ADR_I = x"FFFF8202" and ASn = '0' and LDSn = '0' and SU = true else '0'; -- Via LDSn x"FFFF8203".
    VIDEO_BASE_LOW_RS <= '1' when ADR_I = x"FFFF820C" and ASn = '0' and LDSn = '0' and SU = true else '0'; -- Via LDSn x"FFFF820D".
    VIDEO_COUNT_HI_RS <= '1' when ADR_I = x"FFFF8204" and ASn = '0' and LDSn = '0' and SU = true else '0'; -- Via LDSn x"FFFF8205".
    VIDEO_COUNT_MID_RS <= '1' when ADR_I = x"FFFF8206" and ASn = '0' and LDSn = '0' and SU = true else '0'; -- Via LDSn x"FFFF8207".
    VIDEO_COUNT_LOW_RS <= '1' when ADR_I = x"FFFF8208" and ASn = '0' and LDSn = '0' and SU = true else '0'; -- Via LDSn x"FFFF8209".
    VIDEO_BASE_HIWORD_RS <= '1' when ADR_I = x"FFFF8212" and ASn = '0' and SU = true else '0';
    VIDEO_BASE_LOWORD_RS <= '1' when ADR_I = x"FFFF8214" and ASn = '0' and SU = true else '0';
    VIDEO_COUNT_HIWORD_RS <= '1' when ADR_I = x"FFFF8216" and ASn = '0' and SU = true else '0';
    VIDEO_COUNT_LOWORD_RS <= '1' when ADR_I = x"FFFF8218" and ASn = '0' and SU = true else '0';

    -- These are shadows required in the video counter module:
    SHMOD_ST_SHADOW_RS <= '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8260" and SU = true else '0';
    SHMOD_F_SHADOW_RS <= '1' when ASn = '0' and ADR_I = x"FFFF8266" and SU = true else '0';
    VMODE_SHADOW_RS <= '1' when ASn = '0' and ADR_I = x"FFFF82C2" and SU = true else '0';

    LINE_OFFS_RS <= '1' when ADR_I = x"FFFF820E" and ASn = '0' and SU = true else '0';
    LINE_WIDTH_RS <= '1' when ADR_I = x"FFFF8210" and ASn = '0' and SU = true else '0';

    -- User RAM:
    RAMn <= '0' when RAM_16MB = '0' and ADR_I >= x"00000800" and ADR_I < x"00400000" and ASn = '0' and (SU = true or US = true) else -- 4MB RAM.
            '0' when RAM_16MB = '1' and ADR_I >= x"00000800" and ADR_I < x"00E00000" and ASn = '0' and (SU = true or US = true) else -- 14MB RAM.
            '0' when ADR_I >= x"00E80000" and ADR_I < x"00F00000" and ASn = '0' and (SU = true or US = true) else -- Extra E80000-EFFFFF RAM (for Udo).
            --'0' when RAM_512MB = '1' and ADR_I >= x"00000800" and ADR_I < x"00E00000" and ASn = '0' and (SU = true or US = true) else -- 512MB RAM.
            --'0' when RAM_512MB = '1' and ADR_I >= x"01000000" and ADR_I < x"20000000" and ASn = '0' and (SU = true or US = true) else -- 512MB RAM.
            '0' when ADR_I >= x"00000008" and ADR_I < x"00000800" and ASn = '0' and SU = true and RWn = '0' else
            '0' when ADR_I >= x"00000008" and ADR_I < x"00000800" and ASn = '0' and RWn = '1' and (SU = true or US = true) else '1';

    ALTRAMn <= '0' when ADR_I >= x"01000000" and ADR_I < x"04000000" and ASn = '0' and (SU = true or US = true) else '1'; -- This are additional 48MB :-)

    SHADOW_TOS_CSn <= '0' when ASn = '0' and ADR_I = x"00F82000" and (SU = true or US = true) else '1';

    -- ISP1160 compatible core chip select:
    USB1160_CSn <= '0' when ASn = '0' and (ADR_I = x"00F80000" or ADR_I = x"00F80004") and (SU = true or US = true) else '1';
    Lightning_CSn <= '0' when ASn = '0' and ADR_I = x"00F80008" and (SU = true or US = true) else '1';

end BEHAVIOR;
