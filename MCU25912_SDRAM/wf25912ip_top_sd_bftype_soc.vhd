------------------------------------------------------------------------
----                                                                ----
---- SD-RAM memory control unit for a 64MB - 16Mx32 SD RAM.         ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- This MCU is an enhanced version of the original ATARI MCU to   ----
---- meet the requirements for modern SD-RAM chips. In detail,      ----
---- this MCU is well suited for the Alliance Memory device type    ----
---- AS4C16M32C synchronous DRAM or compatible.                     ----
---- This controller is compatible to the original Atari MCU        ----
---- CO25912 but enhanced to 14 MBytes max. and additional 48MB     ----
---- ALTRAM. This controller features the sound of STE machines.    ----
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
---- Copyright © 2019... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K19B  20191224 WF
--   Initial release.
-- Revision 2K20A  20191224 WF
--   Toplevel: restructured for 32 bit wide CPU-RAM access.
--   Control: Enhancements to enable 32 bit wite SD-RAM access.
--   Control: Several adjustments to meet requirements for the new bus arbiter (GLUE) and memory control (MCU).
-- Revision 2K21A 20211224 WF
--   Changed polarity of MADRSEL to meet with the Falcon IP core.
--   Implemented additional RAM of 48MB.
--   Remark: Modified the BANK switching to meet the requirements of actual SD-RAMs.
--   Opted out signal K30 to meet the requirements for 48MB ALTRAM.
--

use work.wf25912ip_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF25912IP_SD_TOP_BFTYPE_SOC is
    port(
        CLK             : in std_logic; -- System clock, originally 16MHz, 32 MHz in the core.

        SYS_RESET_INn   : in std_logic;
        SYS_RESET_OUTn  : out std_logic;
        RESET_INn       : in std_logic;

        ASn             : in std_logic; -- Bus control signals.
        LDSn            : in std_logic; -- Bus control signals.
        UDSn            : in std_logic; -- Bus control signals.
        RWn             : in std_logic; -- Bus control signals.

        ADR             : in std_logic_vector(25 downto 0); -- The STs address bus inclusive additional RAM.
        MCU_ADR_1       : out std_logic; -- HiLo control for video or sound address in use.

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

        CKE             : out std_logic; -- RAM clock enable.
        CSn             : out std_logic; -- RAM chip enable.
        BA              : out std_logic_vector(1 downto 0); -- SD-RAM bank select.
        MAD             : out std_logic_vector(12 downto 0); -- SD-RAM address bus.
        WEn             : out std_logic; -- SD-RAM write select.
        RASn            : out std_logic; -- SD-RAM row address select.
        CASn            : out std_logic; -- SD-RAM column address select.
        BUS_WIDTH       : in RAMWIDTH_TYPE; -- Select CPU-RAM bus width.
        SIZE            : in std_logic_vector(1 downto 0); -- Data size control.
        DQMn            : out std_logic_vector(3 downto 0); -- SD-RAM output buffer controls.

        RDATn           : out std_logic; -- Buffer control.
        WDATn           : out std_logic; -- Buffer control.
        LATCHn          : out std_logic; -- Buffer control.

        DTACKn          : out std_logic; -- Data acknowledge signal.

        DATA_IN         : in std_logic_vector(7 downto 0);
        DATA_OUT        : out std_logic_vector(7 downto 0);
        DATA_EN         : out std_logic
    );
end entity WF25912IP_SD_TOP_BFTYPE_SOC;

architecture STRUCTURE of WF25912IP_SD_TOP_BFTYPE_SOC is
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

signal RAS0n                : std_logic;
signal RAS1n                : std_logic;
signal CAS0n                : std_logic;
signal CAS1n                : std_logic;

signal WE_CTRLn             : std_logic;

signal CMPCS_REQ_I          : std_logic;
signal DMA_CNT_EN_I         : std_logic;
signal VIDEO_CNT_EN_I       : std_logic;
signal VIDEO_CNT_LOAD_I     : std_logic;
signal LINE80_RELOAD_I      : std_logic;

signal MADRSEL_I            : MADR_TYPE;

signal ADR_B                : std_logic_vector(1 downto 0); -- Byte address.
signal RAM_ADR_I            : std_logic_vector(12 downto 0);
signal M_ADR_I              : std_logic_vector(25 downto 1);
signal DMA_ADR_I            : std_logic_vector(23 downto 1);
signal VIDEO_ADR_I          : std_logic_vector(23 downto 1);

signal MEM_CONFIG_CS_I      : std_logic;
signal MCU_PHASE            : MCU_PHASE_TYPE;

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

signal INIT_STATE                   : integer range 0 to 1023;
begin
    P_SDINIT: process(SYS_RESET_INn, CLK)
    -- This process provides the control for the initialisation of the SD-RAM.
    -- Since it is clocked by a 32MHz clock, the period is 31.25ns. There is a
    -- predivider, so that the INIT_STATE increments every eigths clock, means
    -- every 250ns. To meet the requirement of a 200us idle period, the INIT_STATE
    -- requires a value of 800. All other init steps work on the 250ns time step.
    -- The initialisation of the command respective to the INIT_STATE works as
    -- follows:
        -- <= 800 : IDLE.
        -- 801    : PRECHARGE_ALL command.
        -- 802    : NOP command.
        -- 803    : AUTO_REFRESH command.
        -- 804    : NOP command.
        -- 805    : AUTO_REFRESH command.
        -- 806    : NOP command.
        -- 807    : AUTO_REFRESH command.
        -- 808    : NOP command.
        -- 809    : AUTO_REFRESH command.
        -- 810    : NOP command.
        -- 811    : AUTO_REFRESH command.
        -- 812    : NOP command.
        -- 813    : AUTO_REFRESH command.
        -- 814    : NOP command.
        -- 815    : AUTO_REFRESH command.
        -- 816    : NOP command.
        -- 817    : AUTO_REFRESH command.
        -- 818    : NOP command.
        -- 819    : Write to the mode register.
        -- 820    : NOP command.
        -- 821    : Stay in this mode, normal SD-RAM operation.
    variable TMP : std_logic_vector(2 downto 0);
    begin
        if SYS_RESET_INn = '0' then
            INIT_STATE <= 0;
            TMP := "000"; -- Init ready, do nothing.
        elsif CLK = '1' and CLK' event then
            if init_STATE < 800 and TMP = "111" then
                INIT_STATE <= INIT_STATE + 1;
                TMP := "000";
            elsif INIT_STATE < 821 then
                INIT_STATE <= INIT_STATE + 1;
            else
                TMP := TMP + '1';
            end if;
        end if;
    end process P_SDINIT;

    SYS_RESET_OUTn <= '1' when INIT_STATE = 821 else '0'; -- This reset controls the CPU.

    HILO_SWITCH: process
	-- This address bit is used to handle the top level data 
	-- multiplexers correctly. For DMA operation we need a 
	-- delay of one clock cycle to sample the data right 
	-- after the DMA phase. Other MCU phases are not affected 
	-- by the delay.
    begin
        wait until CLK = '1' and CLK' event;
		case MCU_PHASE is
			when DMA => MCU_ADR_1 <= DMA_ADR_I(1);
			when VIDEO => MCU_ADR_1 <= VIDEO_ADR_I(1);
			when SOUND => MCU_ADR_1 <= DMA_SOUND_ADR_I(1);
            when others => MCU_ADR_1 <= ADR(1); -- This is used for 32 bit CPU, required shifter register access.
		end case;
    end process HILO_SWITCH;

    M_ADR_I <= ADR(25 downto 1) when MCU_PHASE = RAM else
               "00" & DMA_ADR_I when MCU_PHASE = DMA else
               "00" & VIDEO_ADR_I when MCU_PHASE = VIDEO else
               "00" & DMA_SOUND_ADR_I when MCU_PHASE = SOUND else (others => '0');

    RAM_ADR_I <= M_ADR_I(23 downto 11) when MADRSEL_I = MEM_HI_ADR else x"0" & M_ADR_I(10 downto 2);

    BA <= M_ADR_I(25 downto 24); -- In each bank we use 4Mx32 from the 16Mx32 SDRAM.

    MAD <= '0' & x"220" when INIT_STATE = 819 else -- Command: CAS latency = 2, single location access, burst length = 1.
           '0' & x"400" when INIT_STATE /= 821 else -- Used for PRECHARGE_ALL (A10 must be high).
           RAM_ADR_I when RAS1n = '0' or RAS0n = '0' else -- Row address programming.
           x"2" & RAM_ADR_I(8 downto 0); -- Select auto precharge and column address.

    CSn <= '0';
    CKE <= '1';

    WEn <= '0' when INIT_STATE = 801 else -- PRECHARGE_ALL.
           '0' when INIT_STATE = 819 else -- Write mode register.
           '0' when WE_CTRLn = '0' and INIT_STATE = 821 else '1';

    RASn <= '0' when INIT_STATE = 801 else -- PRECHARGE_ALL.
            '0' when INIT_STATE = 803 else -- Auto refresh.
            '0' when INIT_STATE = 805 else -- Auto refresh.
            '0' when INIT_STATE = 807 else -- Auto refresh.
            '0' when INIT_STATE = 809 else -- Auto refresh.
            '0' when INIT_STATE = 811 else -- Auto refresh.
            '0' when INIT_STATE = 813 else -- Auto refresh.
            '0' when INIT_STATE = 815 else -- Auto refresh.
            '0' when INIT_STATE = 817 else -- Auto refresh.
            '0' when INIT_STATE = 819 else -- Write mode register.
            '0' when REF_EN_I = '1' and INIT_STATE = 821 else -- Auto refresh.
            '0' when RAS0n = '0' and INIT_STATE = 821 else
            '0' when RAS1n = '0' and INIT_STATE = 821 else '1';

    CASn <= '0' when INIT_STATE = 803 else -- Auto refresh.
            '0' when INIT_STATE = 805 else -- Auto refresh.
            '0' when INIT_STATE = 807 else -- Auto refresh.
            '0' when INIT_STATE = 809 else -- Auto refresh.
            '0' when INIT_STATE = 811 else -- Auto refresh.
            '0' when INIT_STATE = 813 else -- Auto refresh.
            '0' when INIT_STATE = 815 else -- Auto refresh.
            '0' when INIT_STATE = 817 else -- Auto refresh.
            '0' when INIT_STATE = 819 else -- Write mode register.
            '0' when REF_EN_I = '1' and INIT_STATE = 821 else -- Auto refresh.
            '0' when CAS0n = '0' and INIT_STATE = 821 else
            '0' when CAS1n = '0' and INIT_STATE = 821 else '1';

    ADR_B <= DMA_ADR_I(1) & '0' when DMAn = '0' else ADR(1 downto 0); -- This is the byte address in a long word frame.
    
    -- SD-RAM output buffer controls.
    -- Be aware: we need a 32bit wide RAM. The BUS_WIDTH is used to control the access between RAM and 68K30 which 
    -- is selectable via BUS_WIDTH in LONG, WORD or BYTE portions. This feature is for 68K30 bus controller debugging purpose.
    DQMn <= "1111" when INIT_STATE /= 821 else
            "0000" when (CAS1n = '0' or CAS0n = '0') and MCU_PHASE = VIDEO else -- 32 bit wide.
            "0000" when (CAS1n = '0' or CAS0n = '0') and MCU_PHASE = SOUND else -- 32 bit wide.
            "0000" when RWn = '1' and (CAS0n = '0' or CAS1n = '0') else -- During read from RAM all outputs enabled to feed any RAM data multiplexers correctly. 
            "0000" when BUS_WIDTH = L32 and SIZE = "00" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "00" else -- Long.
            "1000" when BUS_WIDTH = L32 and SIZE = "00" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "01" else -- Long.
            "1100" when BUS_WIDTH = L32 and SIZE = "00" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "10" else -- Long.
            "1110" when BUS_WIDTH = L32 and SIZE = "00" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "11" else -- Long.
            "0001" when BUS_WIDTH = L32 and SIZE = "11" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "00" else -- Three bytes.
            "1000" when BUS_WIDTH = L32 and SIZE = "11" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "01" else -- Three bytes.
            "1100" when BUS_WIDTH = L32 and SIZE = "11" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "10" else -- Three bytes.
            "1110" when BUS_WIDTH = L32 and SIZE = "11" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "11" else -- Three bytes.
            "0011" when BUS_WIDTH = L32 and SIZE = "10" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "00" else -- Word.
            "1001" when BUS_WIDTH = L32 and SIZE = "10" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "01" else -- Word.
            "1100" when BUS_WIDTH = L32 and SIZE = "10" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "10" else -- Word.
            "1110" when BUS_WIDTH = L32 and SIZE = "10" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "11" else -- Word.
            "0111" when BUS_WIDTH = L32 and SIZE = "01" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "00" else -- Byte.
            "1011" when BUS_WIDTH = L32 and SIZE = "01" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "01" else -- Byte.
            "1101" when BUS_WIDTH = L32 and SIZE = "01" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "10" else -- Byte.
            "1110" when BUS_WIDTH = L32 and SIZE = "01" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "11" else -- Byte.
            "0011" when BUS_WIDTH = W16 and SIZE /= "01" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "00" else -- Long, three bytes or word.
            "1001" when BUS_WIDTH = W16 and SIZE /= "01" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "01" else -- Long, three bytes or word.
            "1100" when BUS_WIDTH = W16 and SIZE /= "01" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "10" else -- Long, three bytes or word.
            "1110" when BUS_WIDTH = W16 and SIZE /= "01" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "11" else -- Long, three bytes or word.
            "0111" when BUS_WIDTH = W16 and SIZE = "01" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "00" else -- Byte.
            "1011" when BUS_WIDTH = W16 and SIZE = "01" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "01" else -- Byte.
            "1101" when BUS_WIDTH = W16 and SIZE = "01" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "10" else -- Byte.
            "1110" when BUS_WIDTH = W16 and SIZE = "01" and (CAS0n = '0' or CAS1n = '0') and ADR_B = "11" else -- Byte.
            "0111" when BUS_WIDTH = B8 and (CAS0n = '0' or CAS1n = '0') and ADR_B = "00" else -- Byte.
            "1011" when BUS_WIDTH = B8 and (CAS0n = '0' or CAS1n = '0') and ADR_B = "01" else -- Byte.
            "1101" when BUS_WIDTH = B8 and (CAS0n = '0' or CAS1n = '0') and ADR_B = "10" else -- Byte.
            "1110"; -- when BUS_WIDTH = B8 and (CAS0n = '0' or CAS1n = '0') and ADR_B = "11" else -- Byte.

    DATA_EN <= '0' when INIT_STATE /= 821  else
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
            MCU_PHASE       => MCU_PHASE,

            VSYNCn          => VSYNCn,
            DE              => DE,
            VIDEO_HIMODE    => VIDEO_HIMODE,
            DCYCn           => DCYCn,

            RAS0n           => RAS0n,
            RAS1n           => RAS1n,

            CAS0n           => CAS0n,
            --CAS0Ln        =>,
            --CAS0Hn        =>,

            CAS1n           => CAS1n,
            --CAS1Ln        =>,
            --CAS1Hn        =>,

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
            ADR                         => ADR(15 downto 1),
            ASn                         => ASn,
            LDSn                        => LDSn,
            DEVn                        => DEVn,

            MEM_CONFIG_CS               => MEM_CONFIG_CS_I,

            VIDEO_BASE_HI_CS            => VIDEO_BASE_HI_CS_I,
            VIDEO_BASE_MID_CS           => VIDEO_BASE_MID_CS_I,
            VIDEO_BASE_LOW_CS           => VIDEO_BASE_LOW_CS_I,

            VIDEO_COUNT_HI_CS           => VIDEO_COUNT_HI_CS_I,
            VIDEO_COUNT_MID_CS          => VIDEO_COUNT_MID_CS_I,
            VIDEO_COUNT_LOW_CS          => VIDEO_COUNT_LOW_CS_I,

            DMA_BASE_HI_CS              => DMA_BASE_HI_CS_I,
            DMA_BASE_MID_CS             => DMA_BASE_MID_CS_I,
            DMA_BASE_LOW_CS             => DMA_BASE_LOW_CS_I,

            CMPCS_REQ                   => CMPCS_REQ_I,

            LINEWIDTH_CS                => LINEWIDTH_CS_I,

            SOUND_CTRL_CS               => SOUND_CTRL_CS_I,
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
