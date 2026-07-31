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
---- This is the package file containing the component              ----
---- declarations.                                                  ----
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
-- Initial Release.
-- Revision 2K8A  2008/07/14 WF
--   Minor changes.
-- Revision 2K9A  2008/11/29 WF
--   Introduced VIDEO_HIMODE and LINE80_RELOAD.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
-- Revision 2K21A 20211224 WF
--   Removed BANKTYPE.
--

library ieee;
use ieee.std_logic_1164.all;

package WF25912IP_PKG is
type MADR_TYPE is (MEM_LOW_ADR, MEM_HI_ADR);
type MCU_PHASE_TYPE is (IDLE, DMA, RAM, VIDEO, SOUND, SHIFTER, REFRESH);
type RAMWIDTH_TYPE is(L32, W16, B8);
-- Component declarations:
component WF25912IP_CTRL_SD
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
end component;

component WF25912IP_DMA_CTRL_SD
port (  CLK             : in std_logic;
        RESETn          : in std_logic;

        RWn             : in std_logic;
        
        DMA_BASE_HI_CS  : in std_logic;
        DMA_BASE_MID_CS : in std_logic;
        DMA_BASE_LOW_CS : in std_logic;

        DMA_COUNT_EN    : in std_logic;

        DMA_ADR         : out std_logic_vector(23 downto 1);
        
        DATA_IN         : in std_logic_vector(7 downto 0);
        DATA_OUT        : out std_logic_vector(7 downto 0);
        DATA_EN         : out std_logic
      );
end component;

component WF25912IP_ADRDEC_SD
port (  ADR                 : in std_logic_vector(15 downto 1);
        ASn                 : in std_logic;
        LDSn                : in std_logic;
        DEVn                : in std_logic;
        
        MEM_CONFIG_CS       : out std_logic;
        
        VIDEO_BASE_HI_CS    : out std_logic;
        VIDEO_BASE_MID_CS   : out std_logic;
        VIDEO_BASE_LOW_CS   : out std_logic;
        
        VIDEO_COUNT_HI_CS   : out std_logic;
        VIDEO_COUNT_MID_CS  : out std_logic;
        VIDEO_COUNT_LOW_CS  : out std_logic;
        
        DMA_BASE_HI_CS      : out std_logic;
        DMA_BASE_MID_CS     : out std_logic;
        DMA_BASE_LOW_CS     : out std_logic;
        
        CMPCS_REQ           : out std_logic;

        LINEWIDTH_CS        : out std_logic;

        SOUND_CTRL_CS               : out std_logic;
        SOUND_FRAME_START_HI_CS     : out std_logic;
        SOUND_FRAME_START_MID_CS    : out std_logic;
        SOUND_FRAME_START_LOW_CS    : out std_logic;
        SOUND_FRAME_ADR_HI_CS       : out std_logic;
        SOUND_FRAME_ADR_MID_CS      : out std_logic;
        SOUND_FRAME_ADR_LOW_CS      : out std_logic;
        SOUND_FRAME_END_HI_CS       : out std_logic;
        SOUND_FRAME_END_MID_CS      : out std_logic;
        SOUND_FRAME_END_LOW_CS      : out std_logic
      );
end component;

component WF25912IP_VIDEO_COUNTER_SD
port (  CLK                 : in std_logic;
        RESETn              : in std_logic;
        RWn                 : in std_logic;
        
        VIDEO_BASE_HI_CS    : in std_logic;
        VIDEO_BASE_MID_CS   : in std_logic;
        VIDEO_BASE_LOW_CS   : in std_logic;

        VIDEO_COUNT_HI_CS   : in std_logic;
        VIDEO_COUNT_MID_CS  : in std_logic;
        VIDEO_COUNT_LOW_CS  : in std_logic;
        
        DE                  : in std_logic;
        VIDEO_COUNT_EN      : in std_logic;
        VIDEO_COUNT_LOAD    : in std_logic;
        LINE80_RELOAD       : in std_logic;

        LINEWIDTH_CS        : in std_logic;
        
        VIDEO_ADR           : out std_logic_vector(23 downto 1);
        
        DATA_IN         : in std_logic_vector(7 downto 0);
        DATA_OUT        : out std_logic_vector(7 downto 0);
        DATA_EN         : out std_logic
      );
end component;

component WF25912IP_DMA_SOUND_SD
port (  RESETn          : in std_logic;
        CLK             : in std_logic;
        
        RWn             : in std_logic;
        DATA_IN         : in std_logic_vector(7 downto 0);
        DATA_OUT        : out std_logic_vector(7 downto 0);
        DATA_EN         : out std_logic;

        MONOCHROME      : in std_logic;

        SINTn           : out std_logic;
        SINT_TAI        : out std_logic;
        SINT_IO7        : out std_logic;
        FRAME_CNT_EN    : in std_logic;
        SREQ            : in std_logic;
        SOUND_REQ       : out boolean;
        CODEC_4299_DMA  : out std_logic;

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
end component;
end WF25912IP_PKG;
