------------------------------------------------------------------------
----                                                                ----
---- ATARI GLUE compatible IP Core                                  ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Atari's ST Glue with all features to reach                     ----
---- ATARI STE compatibility.                                       ----
----                                                                ----
---- Address decoder file.                                          ----
----                                                                ----
----                                                                ----
---- To Do:                                                         ----
---- -                                                              ----
----                                                                ----
---- Author(s):                                                     ----
----   Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----   Udo Matthe, umatthe@web.de                                   ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2005... Wolfgang Foerster - Inventronik GmbH.      ----
---- Copyright © 2023... Udo Matthe.                                ----
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
-- Revision 2K8A  2008/02/13 WF
--   The decoder for RAMn now uses the ASn signal too.
--   The ROM2n is extended to detect also 512K ROMs for emuTOS.
-- Revision 2K9B  2009/12/24 WF
--   Removed the unneccesary DMA_LOCKn.
--   Fixed a bug in FCSn.
--   Fixed a bug in DMA_MODE_CSn.
-- Revision 2K10A  2010/06/20 WF
--   Fixed VMAn for RTC access.
-- Revision 2K12A  20120620 WF
--   Introduced GL_STE_A4299_CS for the audio codec.
--   Minor change concerning CMPCSn (UDSn locked now).
-- Revision 2K13B  20131224 WF
--   Disabled signal SCCn (emuTos crashes due to not present SCC).
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--   TOS_CONFIG is now generic.
-- Revision 2K21A 20211224 WF
--   Introduced an explicit user mode to avoid CPU space mismatch.
--   32 bit address bus and address decoding.
--   ALTRAM decoding.
-- Revision 2K22A 20221224 WF
--   ALTRAM is disabled when the EN_RAM_14MB is switched to 4MB.
-- Revision 2K21A 20220620 WF
--   USB1160 addressdecoding changes.
-- Revision 2K23A 20230620 UMA
--   Implemented Udo Matthe Shadow TOS.
-- Revision 2K23B 20231224
--   Removed the ROMSEL_FC_E0n switch ROM_2n is now valid in both address spaces (UMA).
--   Extra RAM from => x"00E80000" to < x"00F00000".
-- Revision 2K24A 20240620
--   SCC enhancements.
-- Revision 2K24B 20241224
--   To improve data integrity the address decoder uses UDSn and LDSn where possible.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF25915IP_ADRDEC is
    generic (TOS_CONFIG     : integer range 0 to 7 := 0);
    port (  ADR             : in std_logic_vector(31 downto 1); --Adress inputs.
            RWn             : in std_logic; -- Read write control.

            RESETn          : in std_logic; -- System reset.

            EN_RAM_14MB     : in std_logic; -- '1' enables 14MB RAM address space, '0' is 4MB.

            LDSn            : in std_logic; -- Lower data strobe; not used so far.
            UDSn            : in std_logic; -- Upper data strobe.

            ASn             : in std_logic; -- Adress strobe signal indicates valid adress.
            VPAn            : out std_logic; -- Valid peripheral adress.
            VMAn            : in std_logic; -- Valid memory adress; for 6850 (ACIA) access.

            FC              : in std_logic_vector(2 downto 0); -- Processor function codes.

            DMAn            : in std_logic; -- Control signal for the DMA transfer.

            ROM_0n          : out std_logic; -- Adress select bit for ROM 0, (compatibility to ST/STE hardware), active low.
            ROM_1n          : out std_logic; -- Adress select bit for ROM 1, (compatibility to ST/STE hardware), active low.
            ROM_2n          : out std_logic; -- Adress select bit for ROM 2, (compatibility to ST/STE hardware), active low.
            ROM_3n          : out std_logic; -- Adress select bit for ROM 3, (compatibility to ST/STE hardware), active low.
            ROM_4n          : out std_logic; -- Adress select bit for ROM 4, (compatibility to ST/STE hardware), active low.
            ROM_5n          : out std_logic; -- Adress select bit for ROM 3, (compatibility to ST/STE hardware), active low.
            ROM_6n          : out std_logic; -- Adress select bit for ROM 4, (compatibility to ST/STE hardware), active low.
            PATCHn          : out std_logic; -- Dummy if the patched TOS is installed.
            ACIACS          : out std_logic; -- Select signal for the ACIA.
            MFPCSn          : out std_logic; -- Select signal for the MFP.
            SNDCSn          : out std_logic; -- Select signal for the SOUND.
            A4299_CS        : out std_logic; -- Select signal for the audio codec.
            FCSn            : out std_logic; -- Select signal for harddrive / floppy via DMA.
            SCCn            : out std_logic; -- Select signal for the STE or TT SCC chip.
            CPROGn          : out std_logic; -- Select signal for the STE's cache processor.
            HD_REG_CSn      : out std_logic; -- Select signal for the high density floppy control register.
            RTCCSn          : out std_logic; -- Select signal for the real time clock.
            SYNCMODE_CSn    : out std_logic; -- Select signal for the GLUE internal sync mode register.
            SHIFTMODE_CSn   : out std_logic; -- Select signal for the shift mode mirror register.
            DMA_MODE_CSn    : out std_logic; -- Chip select of the mirror register of the DMA unit.
            DEVn            : out std_logic; -- Peripheral select signal.
            RAMn            : out std_logic; -- RAM select signal.
            ALTRAMn         : out std_logic; -- Alternative RAM select signal.
            JOY_CS          : out std_logic; -- Joystick read and write register chip select.
            PAD0X_CS        : out std_logic; -- Paddle counter register chip select.
            PAD0Y_CS        : out std_logic; -- Paddle counter register chip select.
            PAD1X_CS        : out std_logic; -- Paddle counter register chip select.
            PAD1Y_CS        : out std_logic; -- Paddle counter register chip select.
            BUTTON_CS       : out std_logic; -- Button register chip select.
            XPEN_REG_CS     : out std_logic; -- Light pen register.
            YPEN_REG_CS     : out std_logic; -- Light pen register.
			SHADOW_TOS_CSn  : out std_logic; -- Shadow TOS configuration register.
			Lightning_CSn   : out std_logic; -- Ligtning-CPLD Dummy
            USB1160_CSn     : out std_logic -- ISP1160 compatible core.
          );
end WF25915IP_ADRDEC;

architecture BEHAVIOR of WF25915IP_ADRDEC is
alias ADR_HI    : std_logic_vector(31 downto 16) is ADR(31 downto 16);
signal ADR_I    : std_logic_vector(31 downto 0);
signal CTOS_RD  : std_logic; -- Core TOS for 512K ROMs.
signal STE_RD   : std_logic;
signal ST_RD    : std_logic;
signal ST_P_RD  : std_logic;
signal R_READ   : std_logic;
signal SU       : boolean; -- Superuser.
signal US       : boolean; -- Normal user.
begin
    -- Generation of the complete 32 bit wide adress:
    ADR_I <= ADR & '0';

    CTOS_RD <= '1' when TOS_CONFIG = 4 and ASn = '0' and RWn = '1' else '0';
    STE_RD <= '1' when TOS_CONFIG = 0 and ASn = '0' and RWn = '1' else '0';
    ST_RD <= '1' when TOS_CONFIG = 1 and ASn = '0' and RWn = '1' else '0';
    ST_P_RD <= '1' when TOS_CONFIG = 2 and ASn = '0' and RWn = '1' else '0';
    R_READ <= '1' when ASn = '0' and RWn = '1' else '0'; -- ROM, for all TOS versions.

    SU <= true when FC = "101" or FC = "110" else false; -- Superuser mode.
    US <= true when FC = "001" or FC = "010" else false; -- User mode.

    ROM_6n <= '0' when (SU = true or US = true) and STE_RD = '1' and ADR_HI >= x"00FA" and ADR_HI < x"00FC" else
              '0' when (SU = true or US = true) and CTOS_RD = '1' and ADR_HI >= x"00FA" and ADR_HI < x"00FC" else '1'; -- Cartridge ROM (STE).
    ROM_5n <= '0' when (SU = true or US = true) and STE_RD = '1' and ADR_HI >= x"00FE" and ADR_HI < x"00FF" else
              '0' when (SU = true or US = true) and CTOS_RD = '1' and ADR_HI >= x"00FE" and ADR_HI < x"00FF" else '1'; -- Cartridge ROM (STE).
    ROM_4n <= '0' when (SU = true or US = true) and R_READ = '1' and ADR_HI >= x"00FA" and ADR_HI < x"00FB" else '1'; -- Cartridge ROM (ST).
    ROM_3n <= '0' when (SU = true or US = true) and R_READ = '1' and ADR_HI >= x"00FB" and ADR_HI < x"00FC" else '1'; -- Cartridge ROM (ST).
    ROM_2n <= '0' when (SU = true or US = true) and STE_RD = '1' and ADR_HI >= x"00E0" and ADR_HI < x"00E4" else -- STE TOS complete.
              '0' when (SU = true or US = true) and CTOS_RD = '1' and ADR_HI >= x"00E0" and ADR_HI < x"00E8" else -- 512K TOS ROMs (emutos).
              '0' when (SU = true or US = true) and CTOS_RD = '1' and ADR_HI >= x"00FC" and ADR_HI < x"00FF" else -- 192K TOS ROMs.
              '0' when (SU = true or US = true) and ST_P_RD = '1' and ADR_HI >= x"00FC" and ADR_HI < x"00FD" else -- ST TOS ROM LOW.
              '0' when (SU = true or US = true) and ST_RD = '1' and ADR_HI >= x"00FC" and ADR_HI < x"00FD" else -- ST TOS ROM LOW.
              '0' when (SU = true or US = true) and R_READ = '1' and ADR_I < x"00000008" else '1'; -- TOS mirroring.
    ROM_1n <= '0' when (SU = true or US = true) and STE_RD = '1' and ADR_HI >= x"00E0" and ADR_HI < x"00E2" else -- STE TOS ROM LO.
              '0' when (SU = true or US = true) and CTOS_RD = '1' and ADR_HI >= x"00E0" and ADR_HI < x"00E2" else -- STE TOS ROM LO for compatibility.
              '0' when (SU = true or US = true) and ST_P_RD = '1' and ADR_HI >= x"00E0" and ADR_HI < x"00E2" else -- ST TOS ROM MID.
              '0' when (SU = true or US = true) and ST_RD = '1' and ADR_HI >= x"00FD" and ADR_HI < x"00FE" else -- ST TOS ROM MID.
              '0' when (SU = true or US = true) and STE_RD = '1' and ADR_I < x"00000008" else '1'; -- TOS mirroring.
    ROM_0n <= '0' when (SU = true or US = true) and STE_RD = '1' and ADR_HI >= x"00E2" and ADR_HI < x"00E4" else -- STE TOS ROM HI.
              '0' when (SU = true or US = true) and CTOS_RD = '1' and ADR_HI >= x"00E2" and ADR_HI < x"00E4" else -- STE TOS ROM HI for compatibility.
              '0' when (SU = true or US = true) and ST_P_RD = '1' and ADR_HI >= x"00E2" and ADR_HI < x"00E4" else -- ST TOS ROM HI.
              '0' when (SU = true or US = true) and ST_RD = '1' and ADR_HI >= x"00FE" and ADR_HI < x"00FF" else '1'; -- ST TOS ROM HI.
    PATCHn <= '0' when (SU = true or US = true) and ST_P_RD = '1' and ADR_HI >= x"00FD" and ADR_HI < x"00FF" else '1'; -- Dummy for DTACkn.

    -- Memo-mapped chip selects:
    -- Select ACIA, write access in SU mode:
    ACIACS <= '1' when ASn = '0' and ADR_I >= x"FFFFFC00" and ADR_I < x"FFFFFC08" and RWn = '0' and SU = true and VMAn = '0' else
              '1' when ASn = '0' and ADR_I >= x"FFFFFC00" and ADR_I < x"FFFFFC08" and RWn = '1' and (SU = true or US = true) and VMAn = '0' else '0';

    -- Synchronous bus controlling:
    VPAn <= '0' when ASn = '0' and ADR_I >= x"FFFFFC00" and ADR_I < x"FFFFFC08" and RWn = '0' and SU = true else -- Validation for ACIACSn.
            '0' when ASn = '0' and ADR_I >= x"FFFFFC00" and ADR_I < x"FFFFFC08" and RWn = '1' and (SU = true or US = true) else -- Validation for ACIACSn.
            '0' when ASn = '0' and ADR_I >= x"FFFFFC20" and ADR_I < x"FFFFFC40" and RWn = '0' and SU = true else -- Validation for RTC.
            '0' when ASn = '0' and ADR_I >= x"FFFFFC20" and ADR_I < x"FFFFFC40" and RWn = '1' and (SU = true or US = true) else '1'; -- Validation for RTC.

    -- Select MFP (8 bit access), write access in superuser mode:
    MFPCSn <=   '0' when ASn = '0' and ADR_I >= x"FFFFFA00" and LDSn = '0' and ADR_I < x"FFFFFA40" and  RWn = '0' and SU = true else
                '0' when ASn = '0' and ADR_I >= x"FFFFFA00" and LDSn = '0' and ADR_I < x"FFFFFA40" and RWn = '1' and (SU = true or US = true) else '1';

    -- This is the CS4299 chip enable. Access in superuser and user mode. Always word access.
    A4299_CS <= '1' when ASn = '0' and UDSn = '0' and LDSn = '0' and ADR_I >= x"FFFF8820" and ADR_I < x"FFFF882E" and (SU = true or US = true) else '0';

    -- Select Sound (8 bit access), write access in SU mode:
    SNDCSn <= '0' when ASn = '0' and UDSn = '0' and (ADR_I = x"FFFF8800" or ADR_I = x"FFFF8802") and RWn = '0' and SU = true else
              '0' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8800" and  RWn = '1' and (SU = true or US = true) else '1';

    -- Write access only in SU mode:
    SYNCMODE_CSn <= '0' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF820A" and RWn = '0' and SU = true else
                    '0' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF820A" and RWn = '1' and (SU = true or US = true) else '1';

    -- Write access only in SU mode:
    SHIFTMODE_CSn <= '0' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8260" and RWn = '0' and SU = true else
                     '0' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8260" and RWn = '1' and (SU = true or US = true) else '1';

    -- FCSn write access only in SU mode:
    FCSn <= '0' when RESETn = '0' else
            '0' when ASn = '0' and ADR_I = x"FFFF8604" and UDSn = '0' and LDSn = '0' and RWn = '0' and SU = true else
            '0' when ASn = '0' and ADR_I = x"FFFF8604" and UDSn = '0' and LDSn = '0' and RWn = '1' and (SU = true or US = true) else
            '0' when ASn = '0' and ADR_I = x"FFFF8606" and UDSn = '0' and LDSn = '0' and RWn = '0' and SU = true else
            '0' when ASn = '0' and ADR_I = x"FFFF8606" and UDSn = '0' and LDSn = '0' and RWn = '1' and (SU = true or US = true) else '1';

    -- Write only register in SU mode:
    DMA_MODE_CSn <= '0' when ASn = '0' and ADR_I = x"FFFF8606" and UDSn = '0' and RWn = '0' and SU = true else '1';

    -- High density floppy control register:
    HD_REG_CSn <= '0' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF860E" and RWn = '0' and SU = true else
                  '0' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF860E" and RWn = '1' and (SU = true or US = true) else '1';

    -- Write access only in SU mode:
    --SCCn <= '0' when ASn = '0' and ADR_I = x"FFFF8C80" and LDSn = '0' and RWn = '0' and SU = true else
    --        '0' when ASn = '0' and ADR_I = x"FFFF8C82" and LDSn = '0' and RWn = '0' and SU = true else
    --        '0' when ASn = '0' and ADR_I = x"FFFF8C84" and LDSn = '0' and RWn = '0' and SU = true else
    --        '0' when ASn = '0' and ADR_I = x"FFFF8C86" and LDSn = '0' and RWn = '0' and SU = true else
    --        '0' when ASn = '0' and ADR_I = x"FFFF8C80" and LDSn = '0' and RWn = '1' and (SU = true or US = true) else
    --        '0' when ASn = '0' and ADR_I = x"FFFF8C82" and LDSn = '0' and RWn = '1' and (SU = true or US = true) else
    --        '0' when ASn = '0' and ADR_I = x"FFFF8C84" and LDSn = '0' and RWn = '1' and (SU = true or US = true) else
    --        '0' when ASn = '0' and ADR_I = x"FFFF8C86" and LDSn = '0' and RWn = '1' and (SU = true or US = true) else '1';

    
    -- Write access only in SU mode:
    -- TOS and EmuTOS tests the presence of the SCC chip by a read access to register x"FFFF8C80". The
    -- correct address of the SCC is x"FFFF8C81". To be compatible with this issue of TOS and EmuTOS the
    -- address decoder accepts even and odd addresses (omit LDSn).
    SCCn <= '0' when ASn = '0' and ADR_I = x"FFFF8C80" and RWn = '0' and SU = true else
            '0' when ASn = '0' and ADR_I = x"FFFF8C82" and RWn = '0' and SU = true else
            '0' when ASn = '0' and ADR_I = x"FFFF8C84" and RWn = '0' and SU = true else
            '0' when ASn = '0' and ADR_I = x"FFFF8C86" and RWn = '0' and SU = true else
            '0' when ASn = '0' and ADR_I = x"FFFF8C80" and RWn = '1' and (SU = true or US = true) else
            '0' when ASn = '0' and ADR_I = x"FFFF8C82" and RWn = '1' and (SU = true or US = true) else
            '0' when ASn = '0' and ADR_I = x"FFFF8C84" and RWn = '1' and (SU = true or US = true) else
            '0' when ASn = '0' and ADR_I = x"FFFF8C86" and RWn = '1' and (SU = true or US = true) else '1';

    --  -- Cache control register: Write access only in SU mode:
    --  CPROGn <=   '0' when ASn = '0' and ADR_I = x"FFFF8E20" and LDSn = '0' and RWn = '0' and SU = true else
    --              '0' when ASn = '0' and ADR_I = x"FFFF8E22" and LDSn = '0' and RWn = '0' and SU = true else
    --              '0' when ASn = '0' and ADR_I = x"FFFF8E20" and LDSn = '0' and RWn = '1' and (SU = true or US = true) else
    --              '0' when ASn = '0' and ADR_I = x"FFFF8E22" and LDSn = '0' and RWn = '1' and (SU = true or US = true) else '1';
    CPROGn <= '1';

    -- Read access only for the buttons:
    BUTTON_CS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF9200" and RWn = '1' and (SU = true or US = true) else '0'; -- Read only, 8 bit.

    -- Write access only in supervisor mode:
    JOY_CS <= '1' when ASn = '0' and ADR_I = x"FFFF9202" and UDSn = '0' and RWn = '0' and SU = true else
            '1' when ASn = '0' and ADR_I = x"FFFF9202" and UDSn = '0' and RWn = '1' and (SU = true or US = true) else '0';

    PAD0X_CS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF9210" and UDSn = '0' and RWn = '1' and (SU = true or US = true) else '0'; -- Read only
    PAD0Y_CS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF9212" and UDSn = '0' and RWn = '1' and (SU = true or US = true) else '0'; -- Read only
    PAD1X_CS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF9214" and UDSn = '0' and RWn = '1' and (SU = true or US = true) else '0'; -- Read only
    PAD1Y_CS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF9216" and UDSn = '0' and RWn = '1' and (SU = true or US = true) else '0'; -- Read only

    XPEN_REG_CS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF9220" and UDSn = '0' and RWn = '1' and (SU = true or US = true) else '0'; -- Read only, 16 bit.
    YPEN_REG_CS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF9222" and UDSn = '0' and RWn = '1' and (SU = true or US = true) else '0'; -- Read only, 16 bit.

    -- Select RTC, write access in supervisor mode:
    RTCCSn <= '0' when ASn = '0' and ADR_I >= x"FFFFFC20" and ADR_I < x"FFFFFC40" and LDSn = '0' and RWn = '0' and SU = true else
            '0' when ASn = '0' and ADR_I >= x"FFFFFC20" and ADR_I < x"FFFFFC40" and LDSn = '0' and RWn = '1' and (SU = true or US = true) else '1';

    -- Peripheral acess control, not valid during DMA transfer:
    DEVn <= '0' when RESETn = '0' else
            '0' when ADR_I(31 downto 16) = x"FFFF" and ASn = '0' and SU = true else '1';

    -- User RAM: The ASn control signal decoding is done in the MMU.
    -- SU RAM in write mode (no ASn decoding):
    RAMn <= '0' when RESETn = '0' else
            '0' when DMAn = '0' else -- Do not decode with ASn, see GLUE's bus arbiter MCU_SYNC process.
            '0' when ADR_I >= x"00000800" and ADR_I < x"00E00000" and ASn = '0' and EN_RAM_14MB = '1' and (SU = true or US = true) else -- 14 MB RAM.
            '0' when ADR_I >= x"00E80000" and ADR_I < x"00F00000" and ASn = '0' and (SU = true or US = true) else -- Extra E80000-EFFFFF RAM (for Udo).
            '0' when ADR_I >= x"00000800" and ADR_I < x"00400000" and ASn = '0' and (SU = true or US = true) else -- 4 MB RAM.
            '0' when ADR_I >= x"00000008" and ADR_I < x"00000800" and ASn = '0' and SU = true and RWn = '0' else
            '0' when ADR_I >= x"00000008" and ADR_I < x"00000800" and ASn = '0' and RWn = '1' and (SU = true or US = true) else '1';

    ALTRAMn <= '1' when EN_RAM_14MB = '0' else -- Disable ALTRAM when we are in 4MB mode.
               '0' when ADR_I >= x"01000000" and ADR_I < x"04000000" and ASn = '0' and (SU = true or US = true) else '1'; -- This are additional 48MB :-)

    SHADOW_TOS_CSn <= '0' when ASn = '0' and ADR_I = x"00F82000" and UDSn = '0' and (SU = true or US = true) else '1';

    -- ISP1160 compatible core chip select:
    USB1160_CSn <= '0' when ASn = '0' and (ADR_I = x"00F80000" or ADR_I = x"00F80004") and (SU = true or US = true) else '1';
    Lightning_CSn <= '0' when ASn = '0' and ADR_I = x"00F80008" and LDSn = '0' and (SU = true or US = true) else '1'; -- 0x00F80009.
end BEHAVIOR;
