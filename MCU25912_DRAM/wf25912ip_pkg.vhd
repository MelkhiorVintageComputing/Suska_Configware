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
-- Revision 2K15B  20151224 WF
--   Replaced data type bit by std_logic.
--

library ieee;
use ieee.std_logic_1164.all;

package WF25912IP_PKG is
type CLKSEL_TYPE is (CLK_32M, CLK_16M);
type MADR_TYPE is (MEM_LOW_ADR, MEM_HI_ADR);
type BANKTYPE is (K128, K512, K2048);
type MCU_PHASE_TYPE is (IDLE, RAM, VIDEO, SOUND, SHIFTER, REFRESH);
-- Component declarations:
component WF25912IP_CTRL
port (  CLK_x2          : in std_logic;
        CLK_x1          : in std_logic;
        CLKSEL          : in CLKSEL_TYPE;

        RESETn          : in std_logic;
        LDSn, UDSn, RWn : in std_logic;

        M_ADR           : in std_logic_vector(23 downto 1);

        CMPCS_REQ       : in std_logic;
        CMPCSn          : out std_logic;

        SOUND_REQ       : in boolean;
        FRAME_CNT_EN    : out std_logic;
        SLOADn          : out std_logic;

        RAMn            : in std_logic;
        DMAn            : in std_logic;
    
        VSYNCn          : in std_logic;
        DE              : in std_logic;
        DCYCn           : out std_logic;
                    
        MEM_CONFIG_CS   : in std_logic;
        BANK0_TYPE      : out BANKTYPE;
        MCU_PHASE       : out MCU_PHASE_TYPE;

        RAS0n           : out std_logic;
        CAS0Hn          : out std_logic;
        CAS0Ln          : out std_logic;

        WEn             : out std_logic;

        RAS1n           : out std_logic;
        CAS1Hn          : out std_logic;
        CAS1Ln          : out std_logic;

        RDATn           : out std_logic;
        WDATn           : out std_logic;
        LATCHn          : out std_logic;
            
        REF_CNT_EN      : out std_logic;
        DMA_CNT_EN      : out std_logic;
        VIDEO_CNT_EN    : out std_logic;
        VIDEO_CNT_LOAD  : out std_logic;
            
        MADRSEL         : out MADR_TYPE;

        DTACKn          : out std_logic;

        DATA_IN         : in std_logic_vector(7 downto 0);
        DATA_OUT        : out std_logic_vector(7 downto 0);
        DATA_EN         : out std_logic
    );
end component;

component WF25912IP_DMA_CTRL
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

component WF25912IP_RAM_ADRMUX
port (  ADR             : in std_logic_vector(23 downto 1);
        VIDEO_ADR       : in std_logic_vector(23 downto 1);
        SOUND_ADR       : in std_logic_vector(23 downto 1);
        DMA_ADR         : in std_logic_vector(23 downto 1);
        REF_ADR         : in std_logic_vector(9 downto 0);

        M_ADR           : out std_logic_vector(23 downto 1);
        RAM_ADR         : out std_logic_vector(9 downto 0);

        MADRSEL         : in MADR_TYPE;
        BANK0_TYPE      : in BANKTYPE;
        MCU_PHASE       : in MCU_PHASE_TYPE;
        DMAn            : in std_logic
      );
end component;

component WF25912IP_ADRDEC
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

component WF25912IP_CLOCKS
port (
      CLK_x2    : in std_logic;

      CLK_x1    : out std_logic;
      CLK_x05   : out std_logic
    );
end component;

component WF25912IP_RAMREFRESH
port (  CLK         : in std_logic;
        REFCNT_EN   : in std_logic;
        REF_ADR     : out std_logic_vector(9 downto 0)
      );
end component;

component WF25912IP_VIDEO_COUNTER
port (  CLK_x2              : in std_logic;
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

        LINEWIDTH_CS        : in std_logic;
        
        VIDEO_ADR           : out std_logic_vector(23 downto 1);
        
        DATA_IN         : in std_logic_vector(7 downto 0);
        DATA_OUT        : out std_logic_vector(7 downto 0);
        DATA_EN         : out std_logic
      );
end component;

component WF25912IP_DMA_SOUND
port (  RESETn          : in std_logic;
        CLK_x2          : in std_logic;
        
        RWn             : in std_logic;
        DATA_IN         : in std_logic_vector(7 downto 0);
        DATA_OUT        : out std_logic_vector(7 downto 0);
        DATA_EN         : out std_logic;

        MONOMON         : in std_logic;

        DE              : in std_logic;
        MCU_PHASE       : in MCU_PHASE_TYPE;
        SINTn           : out std_logic;
        SINT_TAI        : out std_logic;
        SINT_IO7        : out std_logic;
        FRAME_CNT_EN    : in std_logic;
        SREQ            : in std_logic;
        SOUND_REQ       : out boolean;

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
