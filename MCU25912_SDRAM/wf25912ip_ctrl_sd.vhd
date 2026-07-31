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
---- This controller meets the requirements for SD-RAMs. See the    ----
---- top level file for more information. This controller is in     ----
---- comparision to the original ATARI controller enhanced by the   ----
---- 8192KWords SD-RAM size. This is selected for the respective    ----
---- memory bank by the bits 3 downto 0 of the memory config        ----
---- register. See the coding for the BANK0_TYPE, the BANK_SWITCH   ----
---- and the DTACKn in this file for more information.              ----
----                                                                ----
---- Cotrol file for the different MCU units like registers         ----
---- multiplexers, refresh counter DMA counter sound module etc.    ----
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
--   Modified the D-RAM control scheme to work with SD-RAM.
--   Introduced the 8MB SD-RAM size to the memory config register (effective 7MB).
--   Introduced the 8MB SD-RAM size to DTACKn and the BANK0_TYPE (effective 7MB).
--   Modified video timing (DCYCn) to meet the requirements for the ip core.
-- Revision 2K8B  2008/12/24 WF
--   Introduced VIDEO_HIMODE.
--   Minor changes concerning DMA_SYNC.
-- Revision 2K9A  2009/06/20 WF
--   Introduced multisync compatibility modes (s. P_LINEDOUBLING).
--   Introduced clock phase synchronization in the process TIME_SLICES.
--   LATCHn is now enabled during RAM access and not during VIDEO and SOUND.
-- Revision 2K9B  2009/12/24 WF
--   Small improvement the process TIME_SLICES.
--   Bugfix in the BANK_SWITCH concerning 14MB of memory.
-- Revision 2K10A  20010/06/20 WF
--   Changed logic to enable the 14MB RAM. Introduced EN_RAM_14MB therefore.
--   Changed DTACKn logic to enable 14MB correctly.
--   Minor changes control logic concerning the DMA sound.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
-- Revision 2K20A  20200620 WF
--   Enhancements to enable 32 bit wite SD-RAM access.
--   Several adjustments to meet requirements for the new bus arbiter (GLUE) and memory control (MCU).
-- Revision 2K21A 20211224 WF
--   Changed polarity of MADRSEL to meet with the Falcon IP core.
--   Removed BANK0_TYPE and EN_RAM_14MB and set fixed Bank size to 16Mx16 SD-RAMs.
--

use work.wf25912ip_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity WF25912IP_CTRL_SD is
    port (  CLK             : in std_logic;
            RESETn          : in std_logic;
            
            LDSn            : in std_logic; -- Lower data strobe.
            UDSn            : in std_logic; -- Upper data strobe.
            RWn             : in std_logic; -- Bus control signals.

            M_ADR           : in std_logic_vector(25 downto 1); -- Non multiplexed DRAM addresses.
            
            CMPCS_REQ       : in std_logic;     -- Request for the shifter register access.
            CMPCSn          : out std_logic;    -- Control for the shifter register access.

            SOUND_REQ       : in boolean;
            FRAME_CNT_EN    : out std_logic; -- Count enable for the sound DMA address counter.
            SLOADn          : out std_logic;
            
            RAMn            : in std_logic; -- RAM access control.
            DMAn            : in std_logic; -- DMA access control.

            MEM_CONFIG_CS   : in std_logic; -- Memory config register control.
            MCU_PHASE       : out MCU_PHASE_TYPE;
            
            VSYNCn          : in std_logic; -- Vertical sync signal.
            DE              : in std_logic; -- Horizontal or vertical data enable.
            VIDEO_HIMODE    : in std_logic; -- Access the video RAM with double speed.
            DCYCn           : out std_logic; -- Shifter load signal.
                    
            RAS0n           : out std_logic; -- Memory bank 0 row address strobe.
            RAS1n           : out std_logic; -- Memory bank 1 row address strobe.
            CAS0n           : out std_logic; -- Memory bank 0 column address strobe.
            CAS0Ln          : out std_logic; -- Memory bank 0 column address strobe.
            CAS0Hn          : out std_logic; -- Memory bank 0 column address strobe.
            CAS1n           : out std_logic; -- Memory bank 1 column address strobe.
            CAS1Ln          : out std_logic; -- Memory bank 1 column address strobe.
            CAS1Hn          : out std_logic; -- Memory bank 1 column address strobe.
            WEn             : out std_logic; -- Memory write control, low active.

            RDATn           : out std_logic; -- Buffer control.
            WDATn           : out std_logic; -- Buffer control.
            LATCHn          : out std_logic; -- Buffer control.
            
            REF_EN          : out std_logic; -- Refresh counter enable.
            DMA_CNT_EN      : out std_logic; -- DMA control.
            VIDEO_CNT_EN    : out std_logic; -- Video control.
            VIDEO_CNT_LOAD  : out std_logic; -- Video control.
            LINE80_RELOAD   : out std_logic; -- Video control for multisync compatible mode.
            
            MADRSEL         : out MADR_TYPE; -- Address multiplexer control.

            DTACKn          : out std_logic; -- Data acknowledge signal.

            DATA_IN         : in std_logic_vector(7 downto 0);
            DATA_OUT        : out std_logic_vector(7 downto 0);
            DATA_EN         : out std_logic
    );
end WF25912IP_CTRL_SD;

architecture BEHAVIOR of WF25912IP_CTRL_SD is
type BANKS is (BANK1, BANK0);
type MATRIX_ELEMENTS is array (1 to 13, 0 to 7) of std_logic;
constant TIME_MATRIX : MATRIX_ELEMENTS := 
    (('0','1','1','1','0','1','1','1'),     -- RASn.
     ('1','0','0','1','1','0','0','1'),     -- CASn.
     ('1','0','0','1','1','1','1','1'),     -- WEn.
     ('0','0','0','0','1','1','1','1'),     -- RDATn.
     ('0','0','0','0','1','1','1','1'),     -- WDATn.
     ('0','0','1','1','0','0','0','0'),     -- LATCHn.
     ('1','0','0','0','1','1','1','1'),     -- CMPCSn.
     --('1','1','1','1','0','0','0','1'),   -- DCYCn, SLOADn (video and sound data), original chip timing.
     ('1','1','1','1','1','1','1','0'),     -- DCYCn, SLOADn (video and sound data).
     ('1','0','1','0','0','0','0','0'),     -- REF_EN.
     ('0','0','0','1','0','0','0','0'),     -- DMA_CNT_EN.
     ('0','0','0','0','0','0','0','1'),     -- VIDEO_CNT_EN, FRAME_CNT_EN (video and sound).
     ('1','0','0','0','1','1','1','1'),     -- DTACKn.
     ('1','0','0','0','1','0','0','0'));    -- MADRSEL.

signal MCU_PHASE_I          : MCU_PHASE_TYPE;
signal MADRSEL_I            : std_logic; -- Control signal for the high low data multiplexer.
signal MEMCONFIG            : std_logic_vector(7 downto 0);
signal SLICE_NUMBER         : integer range 0 to 7;
signal BANK_SWITCH          : BANKS;
signal M_ADR_I              : std_logic_vector(25 downto 0);
signal RASn                 : std_logic;
signal CASLn                : std_logic;
signal CASHn                : std_logic;
signal VIDEO_CNT_EN_I       : std_logic;
begin

    MEMCONFIG_REG: process
    begin
        -- The MEMCONFIG must start up with x"0A" indicating virtual 4MB RAM.
        -- Otherwise the RAM test routine will hang due to no DTACKn signal.
        -- The value of x"0A" is written immediately after system startup by
        -- the CPU. This register may not have a clear via RESETn because the
        -- operating system does not initialise it after an interrupt like
        -- monochrome detect (level 15).
        wait until CLK = '1' and CLK' event;
        if MEM_CONFIG_CS = '1' and RWn = '0' then
            MEMCONFIG <= DATA_IN; -- Write to register.
        end if;
    end process MEMCONFIG_REG;

    -- Read memory config register:
    DATA_OUT <= MEMCONFIG when MEM_CONFIG_CS = '1' and RWn = '1' else (others => '0');
    DATA_EN <= MEM_CONFIG_CS and RWn;

    -- Address control:
    MADRSEL <= MEM_HI_ADR when MADRSEL_I = '1' else MEM_LOW_ADR;
    M_ADR_I <= M_ADR & '0';

    MCU_PHASE <= MCU_PHASE_I;

    -- Shifter stuff (sound and video, DMA).
    VIDEO_CNT_LOAD <= '1' when VSYNCn = '0' else '0';
    -- Bus, memory and system control signals:

    BANK_SWITCH <= BANK0 when M_ADR_I < x"2000000" else BANK1; -- 32768 Kbytes in bank 0.

    -- SD-RAM control signals:
    RAS0n <= RASn when BANK_SWITCH = BANK0 else '1';
    RAS1n <= RASn when BANK_SWITCH = BANK1 else '1';
    CAS0n <= CASHn and CASLn when BANK_SWITCH = BANK0 else '1';
    CAS1n <= CASHn and CASLn when BANK_SWITCH = BANK1 else '1';
    CAS0Ln <= CASLn when BANK_SWITCH = BANK0 else '1';
    CAS1Ln <= CASLn when BANK_SWITCH = BANK1 else '1';
    CAS0Hn <= CASHn when BANK_SWITCH = BANK0 else '1';
    CAS1Hn <= CASHn when BANK_SWITCH = BANK1 else '1';

    RASn <= TIME_MATRIX(1, SLICE_NUMBER) when MCU_PHASE_I = REFRESH or MCU_PHASE_I = RAM or MCU_PHASE_I = DMA else
            TIME_MATRIX(1, SLICE_NUMBER) when MCU_PHASE_I = VIDEO or MCU_PHASE_I = SOUND else '1';
    CASLn <= TIME_MATRIX(2, SLICE_NUMBER) when (MCU_PHASE_I = RAM or MCU_PHASE_I = DMA) and LDSn = '0' else
             TIME_MATRIX(2, SLICE_NUMBER) when MCU_PHASE_I = VIDEO or MCU_PHASE_I = SOUND else '1';
    CASHn <= TIME_MATRIX(2, SLICE_NUMBER) when (MCU_PHASE_I = RAM or MCU_PHASE_I = DMA) and UDSn = '0' else
             TIME_MATRIX(2, SLICE_NUMBER) when MCU_PHASE_I = VIDEO or MCU_PHASE_I = SOUND else '1';
    WEn <= TIME_MATRIX(3, SLICE_NUMBER) when (MCU_PHASE_I = RAM or MCU_PHASE_I = DMA) and RWn = '0' else '1'; -- Write is valid in RAM mode.

	RDATn <= TIME_MATRIX(4, SLICE_NUMBER) when (MCU_PHASE_I = RAM or MCU_PHASE_I = DMA or MCU_PHASE_I = SHIFTER) and RWn = '1' else '1';
    WDATn <= TIME_MATRIX(5, SLICE_NUMBER) when (MCU_PHASE_I = RAM or MCU_PHASE_I = DMA or MCU_PHASE_I = SHIFTER) and RWn = '0' else '1';
    LATCHn <= TIME_MATRIX(6, SLICE_NUMBER) when (MCU_PHASE_I = RAM or MCU_PHASE_I = DMA or MCU_PHASE_I = SHIFTER) else '1';

    CMPCSn <= TIME_MATRIX(7, SLICE_NUMBER) when MCU_PHASE_I = SHIFTER else '1';
    DCYCn <= TIME_MATRIX(8, SLICE_NUMBER) when MCU_PHASE_I = VIDEO else '1';
    SLOADn <= TIME_MATRIX(8, SLICE_NUMBER) when MCU_PHASE_I = SOUND else '1';

    REF_EN <= TIME_MATRIX(9, SLICE_NUMBER) when MCU_PHASE_I = REFRESH else '0';
    
	DMA_CNT_EN <= TIME_MATRIX(10, SLICE_NUMBER) when MCU_PHASE_I = DMA else '0'; -- DMA access.
    FRAME_CNT_EN <= TIME_MATRIX(11, SLICE_NUMBER) when MCU_PHASE_I = SOUND else '0'; -- Sound data.
    VIDEO_CNT_EN_I <= TIME_MATRIX(11, SLICE_NUMBER) when MCU_PHASE_I = VIDEO else '0'; -- Video data.

    VIDEO_CNT_EN <= VIDEO_CNT_EN_I;

    P_LINEDOUBLING: process
    -- This logic controls the video counter in the multisync colour modes.
    -- In the STs 640x200 mid colour resolution, the line consists of 80 words 
    -- with 2 words per 16 pixels means 4 colours per pixel. In this mode,
    -- every line is written twice to get 400 lines.
    -- In the STs 320x200 low colour resolution, the line consists of 80 words 
    -- with 4 words per 16 pixels means 16 colours per pixel.
    variable SECOND_LINE    : std_logic;
    variable VIDEO_WORD_CNT : std_logic_vector(6 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        --
        if VSYNCn = '0' or VIDEO_HIMODE = '0' then
            SECOND_LINE := '0';
            VIDEO_WORD_CNT := "0000000";
        elsif VIDEO_CNT_EN_I = '1' and VIDEO_WORD_CNT < "1001111" then
            VIDEO_WORD_CNT := VIDEO_WORD_CNT + '1';
        elsif VIDEO_CNT_EN_I = '1' and SECOND_LINE = '0' then
            VIDEO_WORD_CNT := "0000000";
            SECOND_LINE := '1';
        elsif VIDEO_CNT_EN_I = '1' then
            VIDEO_WORD_CNT := "0000000";
            SECOND_LINE := '0';
        end if;
        --
        if VIDEO_WORD_CNT = "1001111" and SECOND_LINE = '0' then
            LINE80_RELOAD <= '1';
        else
            LINE80_RELOAD <= '0';
        end if;
    end process P_LINEDOUBLING;

	DTACKn <= TIME_MATRIX(12, SLICE_NUMBER) when MCU_PHASE_I = RAM else -- This is regular RAM access.
			  TIME_MATRIX(12, SLICE_NUMBER) when MCU_PHASE_I = DMA else -- RAM-DMA acccess.
			  TIME_MATRIX(12, SLICE_NUMBER) when MCU_PHASE_I = SHIFTER else '1'; -- SHIFTER register access.

    MADRSEL_I <= TIME_MATRIX(13, SLICE_NUMBER);

    MCU_PHASE_SWITCH: process
    -- AD MCU_PHASE_TYPES: SHIFTER is foreseen to  access the shifter
    -- registers; VIDEO transfers video data from RAM to shifter; RAM 
    -- is the CPU or DMA to RAM access.
    -- The REFRESH cycle is foreseen to hold the data in the SD-RAMs.
    -- This process controls the type of data transfer in the second period
    -- of the MCU cycle (250ns ... 500ns). While the first half of the MCU
    -- cycle is reserved for data transfer to the shifter, the second one
    -- shares data transfer between DMA, CPU and RAM and is foreseen for the 
    -- RAM REFRESH process and the data transfer to the shifter registers 
    -- (MCU_PHASE = SHIFTER).
    -- The TMP variable controls the video access every second phase in
    -- case of a fast clocked MCU (double clock rate than the original MCU)
    -- when the VIDEO_HIMODE is not active. The VIDEO_HIMODE enables double
    -- speed video access to provide video data for multisync monitors.
    variable TMP        : std_logic;
    begin
        wait until CLK = '1' and CLK' event;
        if RESETn = '0' then
            MCU_PHASE_I <= REFRESH; -- REFRESH during reset keeps data alive.
            TMP := '0';
        elsif SLICE_NUMBER = 3 then
            TMP := not TMP; -- To achieve 500ns period with a 16MHz clock.
            -- Pay attention here! The DMA sound transfer must happen
            -- Right after the falling edge of DE. Otherwise there might
            -- Occur synchronisation problems with trash video output.
            -- The DMA sound module must look itself for this correct
            -- timing taking the DE status into account.
            if DE = '1' and VIDEO_HIMODE = '1' then
                MCU_PHASE_I <= VIDEO; -- Video data out for an originally clocked MCU.
            elsif DE = '1' and TMP = '1' then
                MCU_PHASE_I <= VIDEO; -- Video data out for an originally clocked MCU.
            elsif DE = '1' then
                MCU_PHASE_I <= IDLE;
            elsif DE = '0' and SOUND_REQ = true and TMP = '1' then
                MCU_PHASE_I <= SOUND; -- DMA sound data out.
            else
                MCU_PHASE_I <= IDLE; -- Do nothing, wait for one of the data cycles.
            end if;
        elsif SLICE_NUMBER = 7 then
            if RAMn = '0' and DMAn = '1' then
                MCU_PHASE_I <= RAM;
            elsif RAMn = '0' and DMAn = '0' then
                MCU_PHASE_I <= DMA;
            elsif CMPCS_REQ = '1' then
                MCU_PHASE_I <= SHIFTER;
            else -- REFRESH, if no data transfer is required.
                MCU_PHASE_I <= REFRESH;
            end if;
        end if;
    end process MCU_PHASE_SWITCH;

    TIME_SLICES: process
    -- This counter must be synchronous to the counter in the
    -- GLUE arbiter section. It is initialized during system reset.
    -- The counter is identical to the counter in the GLUE arbiter. 
    variable TIME_SLICE_CNT : std_logic_vector(2 downto 0);
    variable LOCK   : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if RESETn = '0' then
            LOCK := false;
        elsif RAMn = '0' and LOCK = false then -- Sync once!
            LOCK := true;
            TIME_SLICE_CNT := "111";
        else
            TIME_SLICE_CNT := TIME_SLICE_CNT + '1';
        end if;
        --
        SLICE_NUMBER <= conv_integer(TIME_SLICE_CNT);
    end process TIME_SLICES;
end architecture BEHAVIOR;
