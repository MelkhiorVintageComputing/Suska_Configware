------------------------------------------------------------------------
----                                                                ----
---- SD-RAM memory control unit (MCU).                              ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- This MCU is an enhanced version of the original ATARI MCU to   ----
---- meet the requirements for modern SD-RAM chips. In detail,      ----
---- this MCU is well suited for the Micron device MT48LC16M16.     ----
---- This controller is compatible to the original Atari MCU        ----
---- CO25912 but 14 MBytes max.                                     ----
--   This controller features the sound of STE machines.            ----
----                                                                ----
---- Important Notice concerning the clock system:                  ----
---- To use this code in a stand alone MCU chip or in a system      ----
---- on a programmable chip (SOC), the clock frequency must be      ----
---- 16MHz to meet the requirements for the original STs screen     ----
---- resolutions.                                                   ----
---- Affected by the clock selection is the video timing and the    ----
---- DMA sound module (originally in the STE machines).             ----
----                                                                ----
---- To guarantee proper operation of the DMA interchange between   ----
---- MCU, GLUE, DMA, the clocks must be well selected. For more     ----
---- information see the Suska top level file for the SOC system    ----
---- or respective documentation for the different original types   ----
---- of ST or STE machines.                                         ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2008... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K8A  2008/02/10 WF
--   Initial release.
-- Revision 2K8B  2008/12/24 WF
--   Minor changes.
-- Revision 2K9A  2009/06/20 WF
--   Introduced VIDEO_HIMODE and LINE80_RELOAD.
--   DTACK_MCUn has now synchronous reset to meet preset requirement.
-- Revision 2K9B  2009/12/24 WF
--   RESET_INn is now SYS_RESET_INn.
--   RESET_OUTn is now SYS_RESET_OUTn.
--   Replaced RESETn filter by new RESET_INn.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
-- Revision 2K19B  20191224 WF
--   Fixed a precharge bug during memory initialisation.
--   Delayed DTACK for a further half clock period.
-- Revision 2K21A 20211224 WF
--   Changed polarity of MADRSEL to meet with the Falcon IP core.
--   Implemented additional RAM of 16MB.
--   Remark: Modified the BANK switching to meet the requirements of actual SD-RAMs.
--

use work.wf25912ip_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF25912IP_SD_TOP_BTYPE_SOC is
    port(  
        CLK             : in std_logic; -- System clock, originally 16MHz, 32 MHz in the core.

        SYS_RESET_INn   : in std_logic;
        SYS_RESET_OUTn  : out std_logic;
        RESET_INn       : in std_logic;

        ASn             : in std_logic; -- Bus control signals.
        LDSn, UDSn      : in std_logic; -- Bus control signals.
        RWn             : in std_logic; -- Bus control signals.

        ADR             : in std_logic_vector(25 downto 1); -- The STs address bus.

        RAMn            : in std_logic; -- RAM access control.
        DMAn            : in std_logic; -- DMA access control.
        DEVn            : in std_logic; -- Device access (A23 downto 16) = x"FF".
        
        VSYNCn          : in std_logic; -- Vertical sync.
        DE              : in std_logic; -- Horizontal or vertical data enable.
        VIDEO_HIMODE    : in std_logic; -- Access the video RAM with double speed.
                    
        DCYCn           : out std_logic; -- Shifter load signal.
        CMPCSn          : out std_logic; -- Shifter video and sound register control.

        MONOCHROME      : in std_logic; -- Monochrome monitor.

        SREQ            : in std_logic; -- Sound data request.
        SLOADn          : out std_logic; -- DMA sound load control.
        SINT_TAI        : out std_logic; -- Sound frame interrupt filtered for timer A.
        SINT_IO7        : out std_logic; -- Sound frame interrupt XORed for MFP_IO7

        BA              : out std_logic_vector(1 downto 0); -- SD-RAM bank select.
        MAD             : out std_logic_vector(12 downto 0); -- SD-RAM address bus.

        WEn             : out std_logic; -- SD-RAM write select.

        DQM0H           : out std_logic; -- SD-RAM output buffer controls.
        DQM0L           : out std_logic;
                    
        RAS0n           : out std_logic; -- SD-RAM row address select.

        CAS0n           : out std_logic; -- SD-RAM column address select.

        RDATn           : out std_logic; -- Buffer control.
        WDATn           : out std_logic; -- Buffer control.
        LATCHn          : out std_logic; -- Buffer control.
            
        DTACKn          : out std_logic; -- Data acknowledge signal.

        DATA_IN         : in std_logic_vector(7 downto 0);
        DATA_OUT        : out std_logic_vector(7 downto 0);
        DATA_EN         : out std_logic
    );
end entity WF25912IP_SD_TOP_BTYPE_SOC;

architecture STRUCTURE of WF25912IP_SD_TOP_BTYPE_SOC is
signal DTACK_In             : std_logic;
signal DTACK_CTRLn          : std_logic;
signal DTACK_MCUn           : std_logic;
signal DATA_OUT_CTRL        : std_logic_vector(7 downto 0);
signal DATA_OUT_DMA_CTRL    : std_logic_vector(7 downto 0);
signal DATA_OUT_VCNT        : std_logic_vector(7 downto 0);
signal DATA_OUT_DMASND      : std_logic_vector(7 downto 0);
signal DATA_EN_CTRL         : std_logic;
signal DATA_EN_DMA_CTRL     : std_logic;
signal DATA_EN_VCNT         : std_logic;
signal DATA_EN_DMASND       : std_logic;

signal RAS1_CTRLn           : std_logic;
signal CAS1H_CTRLn          : std_logic;
signal CAS1L_CTRLn          : std_logic;

signal RAS0_CTRLn           : std_logic;
signal CAS0H_CTRLn          : std_logic;
signal CAS0L_CTRLn          : std_logic;

signal WE_CTRLn             : std_logic;

signal CMPCS_REQ_I          : std_logic;
signal DMA_CNT_EN_I         : std_logic;
signal VIDEO_CNT_EN_I       : std_logic;
signal VIDEO_CNT_LOAD_I     : std_logic;
signal LINE80_RELOAD_I      : std_logic;

signal MADRSEL_I            : MADR_TYPE;

signal RAM_ADR_I            : std_logic_vector(12 downto 0);
signal M_ADR_I              : std_logic_vector(25 downto 1);
signal DMA_ADR_I            : std_logic_vector(23 downto 1);
signal VIDEO_ADR_I          : std_logic_vector(23 downto 1);

signal MEM_CONFIG_CS_I      : std_logic;
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

signal REF_EN_I             : std_logic;
signal SOUND_REQ_I          : boolean;

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

signal INIT_STATE                   : std_logic_vector(11 downto 0);
begin
    P_SDINIT: process(SYS_RESET_INn, CLK)
    -- This process provides the control for the initialisation of the SD-RAM.
    -- Since it is clocked by a 32MHz clock, the period is 31.25ns. There is a
    -- predivider, so that the INIT_STATE increments every eigths clock, means
    -- every 250ns. To meet the requirement of a 100us idle period, the INIT_STATE
    -- requires a value of 400. All other init steps work on the 250ns time step.
    -- The initialisation of the command respective to the INIT_STATE works as
    -- follows:
        -- <= x"190" (400): IDLE.
        -- x"191" (401): PRECHARGE_ALL command.
        -- x"192" (402): NOP command.
        -- x"193" (403): AUTO_REFRESH command.
        -- x"194" (404): NOP command.
        -- x"195" (405): AUTO_REFRESH command.
        -- x"196" (404): NOP command.
        -- x"197" (406): Write to the mode register.
        -- x"198" (407): NOP command.
        -- x"199" (408): Stay in this mode, normal SD-RAM operation.
    variable TMP : std_logic_vector(2 downto 0);
    begin
        if SYS_RESET_INn = '0' then
            INIT_STATE <= (others => '0');
            TMP := "000"; -- Init ready, do nothing.
        elsif CLK = '1' and CLK' event then
            if TMP = "111" then
                INIT_STATE <= INIT_STATE + '1';
                TMP := "000";
            elsif INIT_STATE = x"199" then
                TMP := "000"; -- Init ready, do nothing.
            else
                TMP := TMP + '1';
            end if;
        end if;
    end process P_SDINIT;

    SYS_RESET_OUTn <= '1' when INIT_STATE = x"199" else '0'; -- This reset controls the CPU.
    
    M_ADR_I <= ADR when MCU_PHASE_I = RAM else
               "00" & DMA_ADR_I when MCU_PHASE_I = DMA else
               "00" & VIDEO_ADR_I when MCU_PHASE_I = VIDEO else
               "00" & DMA_SOUND_ADR_I when MCU_PHASE_I = SOUND else (others => '0');

    -- Select column and row with MADRSEL_I:
    RAM_ADR_I <= x"0" & M_ADR_I(22 downto 14) when MADRSEL_I = MEM_LOW_ADR else M_ADR_I(13 downto 1);

    BA <= M_ADR_I(24 downto 23);

    MAD <= '0' & x"220" when INIT_STATE = x"197" else -- Command: CAS latency = 2, single location access, burst length = 1.
           '0' & x"220" when INIT_STATE = x"198" else -- Command: CAS latency = 2, single location access, burst length = 1.
           '0' & x"400" when INIT_STATE /= x"199" else -- Used for PRECHARGE_ALL (A10 must be high).
           RAM_ADR_I when RAS1_CTRLn = '0' or RAS0_CTRLn = '0' else -- Row address programming.
           x"2" & RAM_ADR_I(8 downto 0); -- Select auto precharge and column address.
    
    WEn <= '0' when INIT_STATE = x"191" else -- PRECHARGE_ALL.
           '0' when INIT_STATE = x"197" else -- Write mode register.
           '0' when WE_CTRLn = '0' and INIT_STATE = x"199" else '1';

    RAS0n <= '0' when INIT_STATE = x"191" else -- PRECHARGE_ALL.           
             '0' when INIT_STATE = x"193" else -- Auto refresh.
             '0' when INIT_STATE = x"195" else -- Auto refresh.
             '0' when INIT_STATE = x"197" else -- Write mode register.
             '0' when REF_EN_I = '1' and INIT_STATE = x"199" else -- Auto refresh.
             '0' when RAS0_CTRLn = '0' and INIT_STATE = x"199" else
             '0' when RAS1_CTRLn = '0' and INIT_STATE = x"199" else '1';

    CAS0n <= '0' when INIT_STATE = x"193" else -- Auto refresh.
             '0' when INIT_STATE = x"195" else -- Auto refresh.
             '0' when INIT_STATE = x"197" else -- Write mode register.
             '0' when REF_EN_I = '1' and INIT_STATE = x"199" else -- Auto refresh.
             '0' when (CAS0H_CTRLn = '0' or CAS0L_CTRLn = '0') and INIT_STATE = x"199" else
             '0' when (CAS1H_CTRLn = '0' or CAS1L_CTRLn = '0') and INIT_STATE = x"199" else '1';

    DQM0H <= '0' when (CAS0H_CTRLn = '0' or CAS1H_CTRLn = '0') and INIT_STATE = x"199" else '1';
    DQM0L <= '0' when (CAS0L_CTRLn = '0' or CAS1L_CTRLn = '0') and INIT_STATE = x"199" else '1';

    DATA_EN <= '0' when INIT_STATE /= x"199"  else
               DATA_EN_CTRL or DATA_EN_DMA_CTRL or DATA_EN_VCNT or DATA_EN_DMASND;

    DATA_OUT <= DATA_OUT_CTRL when DATA_EN_CTRL = '1' else
                DATA_OUT_DMA_CTRL when DATA_EN_DMA_CTRL = '1' else
                DATA_OUT_VCNT when DATA_EN_VCNT = '1' else
                DATA_OUT_DMASND when DATA_EN_DMASND = '1' else (others => '0');

    -- Do not assert DTACKn for SOUND_CONTROL register x"8900"
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
        if RESET_INn = '0' then
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
    DTACKn <=   '0' when DTACK_CTRLn = '0' else 
                '0' when DTACK_MCUn = '0' else '1';

    I_CONTROL: WF25912IP_CTRL_SD
        port map(
            CLK             => CLK,
            RESETn          => RESET_INn,

            LDSn            => LDSn,
            UDSn            => UDSn,
            RWn             => RWn,
            
            M_ADR           => M_ADR_I,

            CMPCS_REQ       => CMPCS_REQ_I,
            CMPCSn          => CMPCSn,

            SOUND_REQ       => SOUND_REQ_I,
            FRAME_CNT_EN    => FRAME_CNT_EN_I,
            SLOADn          => SLOADn,

            RAMn            => RAMn,
            DMAn            => DMAn,

            MEM_CONFIG_CS   => MEM_CONFIG_CS_I,

            VSYNCn          => VSYNCn,
            DE              => DE,
            VIDEO_HIMODE    => VIDEO_HIMODE,
            DCYCn           => DCYCn,

            RAS0n           => RAS0_CTRLn,
            RAS1n           => RAS1_CTRLn,

            --CAS0n         =>,
            CAS0Hn          => CAS0H_CTRLn,
            CAS0Ln          => CAS0L_CTRLn,

            --CAS1n         =>,
            CAS1Hn          => CAS1H_CTRLn,
            CAS1Ln          => CAS1L_CTRLn,

            WEn             => WE_CTRLn,

            RDATn           => RDATn,
            WDATn           => WDATn,
            LATCHn          => LATCHn,
            
            REF_EN          => REF_EN_I,
            DMA_CNT_EN      => DMA_CNT_EN_I,
            VIDEO_CNT_EN    => VIDEO_CNT_EN_I,
            VIDEO_CNT_LOAD  => VIDEO_CNT_LOAD_I,
            LINE80_RELOAD   => LINE80_RELOAD_I,
            
            MADRSEL         => MADRSEL_I,
            MCU_PHASE       => MCU_PHASE_I,
            --VIDEO_SOUNDn  =>,
            
            DTACKn          => DTACK_CTRLn,
            
            DATA_IN         => DATA_IN,
            DATA_OUT        => DATA_OUT_CTRL,
            DATA_EN         => DATA_EN_CTRL
        );

    I_DMA: WF25912IP_DMA_CTRL_SD
        port map(
            CLK             => CLK,
            RESETn          => RESET_INn,
            
            RWn             => RWn,
        
            DMA_BASE_HI_CS  => DMA_BASE_HI_CS_I,
            DMA_BASE_MID_CS => DMA_BASE_MID_CS_I,
            DMA_BASE_LOW_CS => DMA_BASE_LOW_CS_I,

            DMA_COUNT_EN    => DMA_CNT_EN_I,

            DMA_ADR         => DMA_ADR_I,
        
            DATA_IN         => DATA_IN,
            DATA_OUT        => DATA_OUT_DMA_CTRL,
            DATA_EN         => DATA_EN_DMA_CTRL
         );

    I_ADRDEC: WF25912IP_ADRDEC_SD
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
        
            DMA_BASE_HI_CS      => DMA_BASE_HI_CS_I,
            DMA_BASE_MID_CS     => DMA_BASE_MID_CS_I,
            DMA_BASE_LOW_CS     => DMA_BASE_LOW_CS_I,
        
            CMPCS_REQ           => CMPCS_REQ_I,
        
            LINEWIDTH_CS        => LINEWIDTH_CS_I,

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

    I_VIDEO: WF25912IP_VIDEO_COUNTER_SD
        port map(
            CLK                 => CLK,
            RESETn              => RESET_INn,

            RWn                 => RWn,
        
            VIDEO_BASE_HI_CS    => VIDEO_BASE_HI_CS_I,
            VIDEO_BASE_MID_CS   => VIDEO_BASE_MID_CS_I,
            VIDEO_BASE_LOW_CS   => VIDEO_BASE_LOW_CS_I,

            VIDEO_COUNT_HI_CS   => VIDEO_COUNT_HI_CS_I,
            VIDEO_COUNT_MID_CS  => VIDEO_COUNT_MID_CS_I,
            VIDEO_COUNT_LOW_CS  => VIDEO_COUNT_LOW_CS_I,
        
            DE                  => DE,
            VIDEO_COUNT_EN      => VIDEO_CNT_EN_I,
            VIDEO_COUNT_LOAD    => VIDEO_CNT_LOAD_I,
            LINE80_RELOAD       => LINE80_RELOAD_I,

            LINEWIDTH_CS        => LINEWIDTH_CS_I,
        
            VIDEO_ADR           => VIDEO_ADR_I,
        
            DATA_IN             => DATA_IN,
            DATA_OUT            => DATA_OUT_VCNT,
            DATA_EN             => DATA_EN_VCNT
        );

    I_DMASOUND: WF25912IP_DMA_SOUND_SD
        port map(
            CLK             => CLK,
            RESETn          => RESET_INn,
            RWn             => RWn,
            DATA_IN         => DATA_IN,
            DATA_OUT        => DATA_OUT_DMASND,
            DATA_EN         => DATA_EN_DMASND,
            
            MONOCHROME      => MONOCHROME,

            FRAME_CNT_EN    => FRAME_CNT_EN_I,
            -- SINTn        => , -- Not required due to the use of SINT_IO7.
            SINT_TAI        => SINT_TAI,
            SINT_IO7        => SINT_IO7,
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
