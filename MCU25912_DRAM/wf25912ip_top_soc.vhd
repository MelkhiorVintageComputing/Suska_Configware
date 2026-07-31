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
---- Important Notice concerning the clock system:                  ----
---- To use this code in a stand alone MCU chip or in a system      ----
---- on a programmable chip (SOC), the clock frequency may be       ----
---- selected via the CLKSEL setting. Use CLK_16M for the           ----
---- original MCU frequency (16MHz) or CLK_32M for the 32MHz        ----
---- SOC-GLUE.                                                      ----
---- Affected by the clock selection is the video timing and the    ----
---- DMA sound module (originally in the STE machines).             ----
----                                                                ----
---- To guarantee proper operation of the DMA interchange between   ----
---- MCU, GLUE, DMA, the clocks must be well selected. For more     ----
---- information see the Suska top level file for the SOC system    ----
---- or respective documentation for the different original types   ----
---- of ST or STE machines.                                         ----
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
-- 
-- Revision 2K6B 2006/11/05 WF
--   Enhanced the STEs SINTn logic by the two signals SINT_TAI and SINT_IO7.
--   Modified Source to compile with the Xilinx ISE.
--   Top level file provided for SOC (systems on programmable chips).
-- Revision 2K7A  2007/01/02 WF
--   Changes to the clock system and related
--   hardware as sound or video control.
-- Revision 2K15B  20151224 WF
--   Replaced data type bit by std_logic.
-- Revision 2K19B  20191224 WF
--   Delayed DTACK for a further half clock period.
--

use work.wf25912ip_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF25912IP_TOP_SOC is
    generic(
        CLKSEL      : CLKSEL_TYPE := CLK_32M
    );
    port(  
        CLK_x2      : in std_logic; -- System clock, originally 16MHz.
        CLK_x1      : in std_logic; -- System clock, originally 8MHz.
        
        ASn         : in std_logic; -- Bus control signals.
        LDSn, UDSn  : in std_logic; -- Bus control signals.
        RWn         : in std_logic; -- Bus control signals.

        ADR         : in std_logic_vector(23 downto 1); -- The STs address bus.

        RAMn        : in std_logic; -- RAM access control.
        DMAn        : in std_logic; -- DMA access control.
        DEVn        : in std_logic; -- Device access (A23 downto 16) = x"FF".
        
        VSYNCn      : in std_logic; -- Vertical sync.
        DE          : in std_logic; -- Horizontal or vertical sync.
                    
        DCYCn       : out std_logic; -- Shifter load signal.
        CMPCSn      : out std_logic; -- Shifter video and sound register control.

        MONO_DETECT : in std_logic; -- Monochrome monitor detector (pin 4 of the 13 pin round video plug).
        EXT_CLKSELn : in std_logic; -- Genlock clock select (pin 3 of the 13 pin round video plug, formerly GPO).
        SREQ        : in std_logic; -- Sound data request.
        SLOADn      : out std_logic;    -- DMA sound load control.
        SINT_TAI    : out std_logic;    -- Sound frame interrupt filtered for timer A.
        SINT_IO7    : out std_logic;    -- Sound frame interrupt XORed for MFP_IO7

        RAS0n       : out std_logic; -- Memory bank 1 row address strobe.
        CAS0Hn      : out std_logic; -- Memory bank 1 column address strobe.
        CAS0Ln      : out std_logic; -- Memory bank 1 column address strobe.

        WEn         : out std_logic; -- Memory write control, low active.

        RAS1n       : out std_logic; -- memory bank 2 row address strobe.
        CAS1Hn      : out std_logic; -- Memory bank 2 column address strobe.
        CAS1Ln      : out std_logic; -- Memory bank 2 column address strobe.

        MAD         : out std_logic_vector(9 downto 0); -- DRAM addressbus.

        RDATn       : out std_logic; -- Buffer control.
        WDATn       : out std_logic; -- Buffer control.
        LATCHn      : out std_logic; -- Buffer control.
            
        DTACKn      : out std_logic; -- Data acknowledge signal.

        DATA_IN     : in std_logic_vector(7 downto 0);
        DATA_OUT    : out std_logic_vector(7 downto 0);
        DATA_EN     : out std_logic
    );
end entity WF25912IP_TOP_SOC;

architecture STRUCTURE of WF25912IP_TOP_SOC is
signal RESET_In             : std_logic;
signal DTACK_In             : std_logic;
signal DTACK_DMAn           : std_logic;
signal DTACK_MCUn           : std_logic;
signal DATA_OUT_CTRL        : std_logic_vector(7 downto 0);
signal DATA_OUT_DMA_CTRL    : std_logic_vector(7 downto 0);
signal DATA_OUT_VCNT        : std_logic_vector(7 downto 0);
signal DATA_OUT_DMASND      : std_logic_vector(7 downto 0);
signal DATA_EN_CTRL         : std_logic;
signal DATA_EN_DMA_CTRL     : std_logic;
signal DATA_EN_VCNT         : std_logic;
signal DATA_EN_DMASND       : std_logic;

signal CMPCS_REQ_I          : std_logic;
signal DMA_CNT_EN_I         : std_logic;
signal VIDEO_CNT_EN_I       : std_logic;
signal VIDEO_CNT_LOAD_I     : std_logic;
signal MADRSEL_I            : MADR_TYPE;


signal RAM_In               : std_logic;

signal RAM_ADR_I            : std_logic_vector(9 downto 0);
signal M_ADR_I              : std_logic_vector(23 downto 1);
signal DMA_ADR_I            : std_logic_vector(23 downto 1);
signal VIDEO_ADR_I          : std_logic_vector(23 downto 1);
signal REF_ADR_I            : std_logic_vector(9 downto 0);

signal MEM_CONFIG_CS_I      : std_logic;
signal BANK0_TYPE_I         : BANKTYPE;
signal MCU_PHASE_I          : MCU_PHASE_TYPE;
                    
signal VIDEO_BASE_HI_CS_I   : std_logic;
signal VIDEO_BASE_MID_CS_I  : std_logic;
signal VIDEO_BASE_LOW_CS_I  : std_logic;
        
signal VIDEO_COUNT_HI_CS_I  : std_logic;
signal VIDEO_COUNT_MID_CS_I : std_logic;
signal VIDEO_COUNT_LOW_CS_I : std_logic;
        
signal DMA_BASE_HI_CS_I     : std_logic;
signal DMA_BASE_MID_CS_I    : std_logic;
signal DMA_BASE_LOW_CS_I    : std_logic;
        
signal LINEWIDTH_CS_I       : std_logic;

signal REF_CNT_EN_I         : std_logic;
signal SOUND_REQ_I          : boolean;

signal MONOMON_I            : std_logic;

signal SOUND_CTRL_CS_I              : std_logic;
signal SOUND_FRAME_START_HI_CS_I    : std_logic;
signal SOUND_FRAME_START_MID_CS_I   : std_logic;
signal SOUND_FRAME_START_LOW_CS_I   : std_logic;
signal SOUND_FRAME_ADR_HI_CS_I      : std_logic;
signal SOUND_FRAME_ADR_MID_CS_I     : std_logic;
signal SOUND_FRAME_ADR_LOW_CS_I     : std_logic;
signal SOUND_FRAME_END_HI_CS_I      : std_logic;
signal SOUND_FRAME_END_MID_CS_I     : std_logic;
signal SOUND_FRAME_END_LOW_CS_I     : std_logic;
signal FRAME_CNT_EN_I               : std_logic;

signal DMA_SOUND_ADR_I              : std_logic_vector(23 downto 1);
begin

    RESET_FILTER: process(CLK_x2)
    -- To avoid malfunction to the MCU, the reset signal, which is 
    -- generated out of DMAn and RAMn is filtered. The reason is the
    -- asynchromous generation of DMAn and RAMn in the GLUE chip.
    variable TMP: std_logic_vector(1 downto 0);
    begin
        if CLK_x2 = '1' and CLK_x2' event then
            if  DEVn = '0' and RAMn = '0' and TMP < "10" then
                TMP := TMP + '1';
            elsif DEVn = '1' or RAMn = '1' then
                TMP := "00";
            end if;
        end if;
        if TMP = "10" then
            RESET_In <= '0';
        else
            RESET_In <= '1';
        end if;
    end process RESET_FILTER;

    MAD <= RAM_ADR_I;

    DATA_EN <= DATA_EN_CTRL or DATA_EN_DMA_CTRL or DATA_EN_VCNT or DATA_EN_DMASND;
    DATA_OUT <= DATA_OUT_CTRL when DATA_EN_CTRL = '1' else
                DATA_OUT_DMA_CTRL when DATA_EN_DMA_CTRL = '1' else
                DATA_OUT_VCNT when DATA_EN_VCNT = '1' else
                DATA_OUT_DMASND when DATA_EN_DMASND = '1' else (others => '0');

    -- No DTACKn for SOUND_CONTROL register x"8900" necessary here
    -- because it is a mirror register of the SHIFTER and the DTACKn
    -- is done via SHIFTER register control.
    DTACK_In <= '0' when MEM_CONFIG_CS_I = '1'              else
                '0' when VIDEO_BASE_HI_CS_I = '1'           else
                '0' when VIDEO_BASE_MID_CS_I = '1'          else
                '0' when VIDEO_BASE_LOW_CS_I = '1'          else
                '0' when VIDEO_COUNT_HI_CS_I = '1'          else
                '0' when VIDEO_COUNT_MID_CS_I = '1'         else
                '0' when VIDEO_COUNT_LOW_CS_I = '1'         else
                '0' when DMA_BASE_HI_CS_I = '1'             else
                '0' when DMA_BASE_MID_CS_I = '1'            else
                '0' when DMA_BASE_LOW_CS_I = '1'            else
                '0' when LINEWIDTH_CS_I = '1'               else
                '0' when SOUND_FRAME_START_HI_CS_I = '1'    else 
                '0' when SOUND_FRAME_START_MID_CS_I = '1'   else 
                '0' when SOUND_FRAME_START_LOW_CS_I = '1'   else 
                '0' when SOUND_FRAME_ADR_HI_CS_I = '1'      else 
                '0' when SOUND_FRAME_ADR_MID_CS_I = '1'     else 
                '0' when SOUND_FRAME_ADR_LOW_CS_I = '1'     else 
                '0' when SOUND_FRAME_END_HI_CS_I = '1'      else
                '0' when SOUND_FRAME_END_MID_CS_I = '1'     else
                '0' when SOUND_FRAME_END_LOW_CS_I = '1'     else '1';

    DTACK_OUT: process
    -- The DTACKn port pin is released on the falling clock edge after the data
    -- acknowledge detect (DTACK_DELAY) is asserted. The DTACKn is deasserted
    -- immediately when there is no further register access DTACK_In = '1';
    variable DTACK_DELAY : boolean;
    begin
        wait until CLK = '0' and CLK' event;
        if RESET_In = '0' then
            DTACK_MCUn <= '1';
            DTACK_DELAY := false;
        elsif DTACK_In = '1' then
            DTACK_MCUn <= '1';
            DTACK_DELAY := false;
        elsif DTACK_DELAY = false then
            DTACK_DELAY := true;
        else
            DTACK_MCUn <= '0';
        end if;
    end process DTACK_OUT;

    -- The DMA relevant data acknowlege works instantaneous.
    DTACKn <=   '0' when DTACK_DMAn = '0' else 
                '0' when DTACK_MCUn = '0' else '1';

    MONOMON_I <= MONO_DETECT when EXT_CLKSELn = '1' else '1';

    I_CONTROL: WF25912IP_CTRL
        port map(
            CLK_x2  => CLK_x2,
            CLK_x1  => CLK_x1,
            CLKSEL  => CLKSEL,

            RESETn  => RESET_In,

            LDSn    => LDSn,
            UDSn    => UDSn,
            RWn     => RWn,
            
            M_ADR   => M_ADR_I,

            CMPCS_REQ   => CMPCS_REQ_I,
            CMPCSn      => CMPCSn,

            SOUND_REQ       => SOUND_REQ_I,
            FRAME_CNT_EN    => FRAME_CNT_EN_I,
            SLOADn          => SLOADn,

            RAMn => RAMn,
            DMAn => DMAn,
            
            MEM_CONFIG_CS => MEM_CONFIG_CS_I,

            VSYNCn => VSYNCn,
            DE => DE,
            DCYCn => DCYCn,

            RAS0n => RAS0n,
            CAS0Hn => CAS0Hn,
            CAS0Ln => CAS0Ln,

            WEn => WEn,

            RAS1n => RAS1n,
            CAS1Hn => CAS1Hn,
            CAS1Ln => CAS1Ln,

            RDATn => RDATn,
            WDATn => WDATn,
            LATCHn => LATCHn,
            
            REF_CNT_EN => REF_CNT_EN_I,
            DMA_CNT_EN => DMA_CNT_EN_I,
            VIDEO_CNT_EN => VIDEO_CNT_EN_I,
            VIDEO_CNT_LOAD => VIDEO_CNT_LOAD_I,
            
            MADRSEL     => MADRSEL_I,
            BANK0_TYPE  => BANK0_TYPE_I,
            MCU_PHASE   => MCU_PHASE_I,
            
            DTACKn      => DTACK_DMAn,
            
            DATA_IN     => DATA_IN,
            DATA_OUT    => DATA_OUT_CTRL,
            DATA_EN     => DATA_EN_CTRL
        );

    I_DMA: WF25912IP_DMA_CTRL
        port map(
            CLK => CLK_x2,
            RESETn => RESET_In,
            
            RWn => RWn,
        
            DMA_BASE_HI_CS => DMA_BASE_HI_CS_I,
            DMA_BASE_MID_CS => DMA_BASE_MID_CS_I,
            DMA_BASE_LOW_CS => DMA_BASE_LOW_CS_I,

            DMA_COUNT_EN => DMA_CNT_EN_I,

            DMA_ADR => DMA_ADR_I,
        
            DATA_IN     => DATA_IN,
            DATA_OUT    => DATA_OUT_DMA_CTRL,
            DATA_EN     => DATA_EN_DMA_CTRL
         );

    I_RAMMUX: WF25912IP_RAM_ADRMUX
        port map(  
            ADR => ADR,
            VIDEO_ADR => VIDEO_ADR_I,
            SOUND_ADR => DMA_SOUND_ADR_I,
            DMA_ADR => DMA_ADR_I,
            REF_ADR => REF_ADR_I,

            M_ADR => M_ADR_I,
            RAM_ADR => RAM_ADR_I,
            MADRSEL => MADRSEL_I,
            BANK0_TYPE => BANK0_TYPE_I,
            MCU_PHASE => MCU_PHASE_I,
            DMAn => DMAn
        );

    I_ADRDEC: WF25912IP_ADRDEC
        port map(
            ADR     => ADR(15 downto 1),
            ASn     => ASn,
            LDSn    => LDSn,
            DEVn    => DEVn,
        
            MEM_CONFIG_CS => MEM_CONFIG_CS_I,
        
            VIDEO_BASE_HI_CS    => VIDEO_BASE_HI_CS_I,
            VIDEO_BASE_MID_CS   => VIDEO_BASE_MID_CS_I,
            VIDEO_BASE_LOW_CS   => VIDEO_BASE_LOW_CS_I,
        
            VIDEO_COUNT_HI_CS   => VIDEO_COUNT_HI_CS_I,
            VIDEO_COUNT_MID_CS  => VIDEO_COUNT_MID_CS_I,
            VIDEO_COUNT_LOW_CS  => VIDEO_COUNT_LOW_CS_I,
        
            DMA_BASE_HI_CS  => DMA_BASE_HI_CS_I,
            DMA_BASE_MID_CS => DMA_BASE_MID_CS_I,
            DMA_BASE_LOW_CS => DMA_BASE_LOW_CS_I,
        
            CMPCS_REQ       => CMPCS_REQ_I,
        
            LINEWIDTH_CS    => LINEWIDTH_CS_I,

            SOUND_CTRL_CS               =>SOUND_CTRL_CS_I,
            SOUND_FRAME_START_HI_CS     => SOUND_FRAME_START_HI_CS_I,
            SOUND_FRAME_START_MID_CS    => SOUND_FRAME_START_MID_CS_I,
            SOUND_FRAME_START_LOW_CS    => SOUND_FRAME_START_LOW_CS_I,
            SOUND_FRAME_ADR_HI_CS       => SOUND_FRAME_ADR_HI_CS_I,
            SOUND_FRAME_ADR_MID_CS      => SOUND_FRAME_ADR_MID_CS_I,
            SOUND_FRAME_ADR_LOW_CS      => SOUND_FRAME_ADR_LOW_CS_I,
            SOUND_FRAME_END_HI_CS       => SOUND_FRAME_END_HI_CS_I,
            SOUND_FRAME_END_MID_CS      => SOUND_FRAME_END_MID_CS_I,
            SOUND_FRAME_END_LOW_CS      => SOUND_FRAME_END_LOW_CS_I
        );

    I_REFRESH: WF25912IP_RAMREFRESH
        port map (
            CLK         => CLK_x2,
            REFCNT_EN   => REF_CNT_EN_I,

            REF_ADR     => REF_ADR_I
        );
    
    I_VIDEO: WF25912IP_VIDEO_COUNTER
        port map(
            CLK_x2      => CLK_x2,
            RESETn      => RESET_In,

            RWn         => RWn,
        
            VIDEO_BASE_HI_CS    => VIDEO_BASE_HI_CS_I,
            VIDEO_BASE_MID_CS   => VIDEO_BASE_MID_CS_I,
            VIDEO_BASE_LOW_CS   => VIDEO_BASE_LOW_CS_I,

            VIDEO_COUNT_HI_CS   => VIDEO_COUNT_HI_CS_I,
            VIDEO_COUNT_MID_CS  => VIDEO_COUNT_MID_CS_I,
            VIDEO_COUNT_LOW_CS  => VIDEO_COUNT_LOW_CS_I,
        
            DE                  => DE,
            VIDEO_COUNT_EN      => VIDEO_CNT_EN_I,
            VIDEO_COUNT_LOAD    => VIDEO_CNT_LOAD_I,

            LINEWIDTH_CS        => LINEWIDTH_CS_I,
        
            VIDEO_ADR           => VIDEO_ADR_I,
        
            DATA_IN     => DATA_IN,
            DATA_OUT    => DATA_OUT_VCNT,
            DATA_EN     => DATA_EN_VCNT
        );

    I_DMASOUND: WF25912IP_DMA_SOUND
        port map(
            CLK_x2          => CLK_x2,
            RESETn          => RESET_In,
            RWn             => RWn,
            DATA_IN         => DATA_IN,
            DATA_OUT        => DATA_OUT_DMASND,
            DATA_EN         => DATA_EN_DMASND,
            
            MONOMON         => MONOMON_I,

            DE              => DE,
            FRAME_CNT_EN    => FRAME_CNT_EN_I,
            -- SINTn            => , -- Not required due to the use of SINT_IO7.
            SINT_TAI        => SINT_TAI,
            SINT_IO7        => SINT_IO7,
            MCU_PHASE       => MCU_PHASE_I,
            SREQ            => SREQ,
            SOUND_REQ       => SOUND_REQ_I,
            
            SOUND_CTRL_CS               => SOUND_CTRL_CS_I,
            SOUND_FRAME_START_HI_CS     => SOUND_FRAME_START_HI_CS_I,
            SOUND_FRAME_START_MID_CS    => SOUND_FRAME_START_MID_CS_I,
            SOUND_FRAME_START_LOW_CS    => SOUND_FRAME_START_LOW_CS_I,
            SOUND_FRAME_ADR_HI_CS       => SOUND_FRAME_ADR_HI_CS_I,
            SOUND_FRAME_ADR_MID_CS      => SOUND_FRAME_ADR_MID_CS_I,
            SOUND_FRAME_ADR_LOW_CS      => SOUND_FRAME_ADR_LOW_CS_I,
            SOUND_FRAME_END_HI_CS       => SOUND_FRAME_END_HI_CS_I,
            SOUND_FRAME_END_MID_CS      => SOUND_FRAME_END_MID_CS_I,
            SOUND_FRAME_END_LOW_CS      => SOUND_FRAME_END_LOW_CS_I,
            DMA_SOUND_ADR               => DMA_SOUND_ADR_I
        );
end architecture STRUCTURE;
