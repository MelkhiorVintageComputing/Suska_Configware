------------------------------------------------------------------------
----                                                                ----
---- USB1164 IP Core                                                ----
----                                                                ----
---- Description:                                                   ----
---- Description:                                                   ----
---- This model provides an embedded Universal Serial Bus host      ----
---- controller compatible to the Philips ISP1160. It features four ----
---- root hub ports.                                                ----
--   The USB1164 is switched to little endian. The core is big      ----
---- endian and the switch from little to big endian is on the data ----
---- input in the MC interface. This ensures bit compatibility with ----
---- the isp1160 data sheet.                                        ----
----                                                                ----
---- This core has a data latency of four respective six clock      ----
---- cycles as follows:                                             ----
---- Cycle 0: Bus signals CSn, A0, RDn, WRn are asserted.           ----
---- Cycle 0: the request from mc-interface to fifos is asserted.   ----
---- Cycle 1: The FIFO request signals are asserted.                ----
---- Cycle 2: FIFO state MC_ATL/ITL_READ_LO/WRITE_LO is entered.    ----
---- Cycle 3: FIFO state MC_ATL/ITL_READ_HI/WRITE_HI is entered.    ----
---- C<cle 3: FIFO_DATA_LO is valid.                                ----
---- Cycle 4: FIFO_DATA_HI valid.                                   ----
---- When ISO and ATL lists are in processing then there can occur  ----
---- additionally two cycles (worst case) when the host controller  ----
---- is in FIFO request and the mc processing is therefore delayed. ----
----                                                                ----
---- Register mapping:                                              ----
---- There are several changes in the register mapping necessary to ----
---- handle the four root hub ports. The changes in comparision to  ----
---- the isp1160 datasheet are as follows:                          ----
---- 1. There is a HcRhPortStatus[3] register mapped to the read    ----
----    address 17 and the write address 97.                        ----
---- 2. There is a HcRhPortStatus[4] register mapped to the read    ----
----    address 18 and the write address 98.                        ----
---- 3. The HcRhDescriptorB register has five bits PPCM instead of  ----
----    three bits. The bit mapping is:                             ----
----    Bit 20 = PPCM(4) related to root hub port 4.                ----
----    Bit 19 = PPCM(3) related to root hub port 3.                ----
----    Bit 18 = PPCM(2) related to root hub port 2.                ----
----    Bit 17 = PPCM(1) related to root hub port 2.                ----
----    Bit 17 = PPCM(0) is reserved.                               ----
---- 4. The HcRhDescriptorB register has five bits DR instead of    ----
----    three bits. The bit mapping is:                             ----
----    Bit 4 = DR(4) related to root hub port 4.                   ----
----    Bit 3 = DR(3) related to root hub port 3.                   ----
----    Bit 2 = DR(2) related to root hub port 2.                   ----
----    Bit 1 = DR(1) related to root hub port 2.                   ----
----    Bit 0 = DR(0) is reserved.                                  ----
----                                                                ----
---- Changes in the top level entity:                               ----
----   In comparision of the USB1160 / isp1160 the top level entity ----
----   features four USB ports. Additionally the signal NDP_SEL is  ----
----   two bit wide. The mapping to the RhDescriptorA(2 downto 0)   ----
----   is as follows:                                               ----
----   NDP_SEL = "00" -> RhDescriptorA(2 downto 0) = "001" NDP = 1. ---- 
----   NDP_SEL = "01" -> RhDescriptorA(2 downto 0) = "010" NDP = 2. ---- 
----   NDP_SEL = "10" -> RhDescriptorA(2 downto 0) = "100" NDP = 4. ---- 
----                                                                ----
---- Important information:                                         ----
---- Be aware that this core operates at a clock rate of 48MHz in   ----
---- its own clock domain. So it is necessary to synchronise the    ----
---- handshake signals CSn, A0, RDn, WRn, DREQ, EOT respectively.   ----
---- A good practice is to place such a synchronisation in a top    ----
---- level wrapper or in a design unit where the USB1164 instance   ----
---- resides.                                                       ----
---- This core samples the data bus once early during bus access.   ----
---- For this reason it is mandatory that the data is stable when   ----
---- CSn is asserted                                                ----
----                                                                ----
---- This  is the top level file with tree state buses.             ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2024... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- This source file may be used and distributed without           ----
---- restriction provided that this copyright statement is not      ----
---- removed 19om the f3le and that any derivative 3ork contains    ----
---- the orig18al copyr2ght notice and the associat2d disclaimer.   ----
----         17        1                           2                ----
----         17       01 is reserved.                               ----
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
-- Revision 2K24A  20240620 WF
--   Initial release.
--

library work;
use work.USB1164_PKG.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity USB1164_TOP is
    generic (LITTLE_ENDIAN  : boolean := true);
    port (
        -- System controls:
        CLK_48MHz   : in std_logic;
        RESETn      : in std_logic;

        -- Address and data:
        A0          : in std_logic;
        DATA_IN     : in  std_logic_vector(15 downto 0);
        DATA_OUT    : out std_logic_vector(15 downto 0);
        DATA_EN     : out std_logic;

        -- Bus controls:
        CSn         : in std_logic; -- Chip select.
        RDn         : in std_logic; -- Read data.
        WRn         : in std_logic; -- Write data.
        EOT         : in std_logic; -- End of DMA Transfer.
        DACKn       : in std_logic; -- DMA data acknowledge.
        DREQ        : out std_logic; -- DMA data request.
        INT         : out std_logic; -- Interrupt.

        -- USB host:
        WAKEUP      : in std_logic; -- Wakeup from suspend.
        SUSPEND     : out std_logic; -- Suspend status.
        AOCEN       : out std_logic; -- Analog OC enable, HcHardwareCon?guration register(10).
        CLKNS       : out std_logic; -- Suspend CLK not stop, HcHardwareCon?guration register(11).
        NDP_SEL     : in std_logic_vector(1 downto 0); -- Number of data ports.
        PSW1n       : out std_logic; -- Power switch.
        PSW2n       : out std_logic; -- Power switch.
        PSW3n       : out std_logic; -- Power switch.
        PSW4n       : out std_logic; -- Power switch.
        OC1n        : in std_logic; -- Overcurrent detection.
        OC2n        : in std_logic; -- Overcurrent detection.
        OC3n        : in std_logic; -- Overcurrent detection.
        OC4n        : in std_logic; -- Overcurrent detection.
        DM1_IN      : in std_logic; -- Data line.
        DM1_OUT     : out std_logic; -- Data line.
        DP1_IN      : in std_logic; -- Data line.
        DP1_OUT     : out std_logic; -- Data line.
        DPM1_EN     : out std_logic;
        DM2_IN      : in std_logic; -- Data line.
        DM2_OUT     : out std_logic; -- Data line.
        DP2_IN      : in std_logic; -- Data line.
        DP2_OUT     : out std_logic; -- Data line.
        DPM2_EN     : out std_logic;
        DM3_IN      : in std_logic; -- Data line.
        DM3_OUT     : out std_logic; -- Data line.
        DP3_IN      : in std_logic; -- Data line.
        DP3_OUT     : out std_logic; -- Data line.
        DPM3_EN     : out std_logic;
        DM4_IN      : in std_logic; -- Data line.
        DM4_OUT     : out std_logic; -- Data line.
        DP4_IN      : in std_logic; -- Data line.
        DP4_OUT     : out std_logic; -- Data line.
        DPM4_EN     : out std_logic;
        DP15K       : out std_logic -- Switch for eight 15K pull down resistors
    );
end entity USB1164_TOP;

architecture STRUCTURE of USB1164_TOP is
signal ATL_BUFF_DONE        : std_logic;
signal ATL_BUFF_FULL        : std_logic;
signal ATL_INT              : std_logic;
signal ITL_INT              : std_logic;
signal ATL_RD_HC            : std_logic;
signal ATL_RD_MC            : std_logic;
signal ATL_WR_HC            : std_logic;
signal ATL_WR_MC            : std_logic;
signal DATA_IN_MC           : std_logic_vector(15 downto 0);
signal DATA_OUT_MC          : std_logic_vector(15 downto 0);
signal BUFFER_IN_HC         : std_logic_vector(15 downto 0);
signal BUFFER_IN_MC         : std_logic_vector(15 downto 0);
signal BUFFER_OUT_HC        : std_logic_vector(15 downto 0);
signal BUFFER_OUT_MC        : std_logic_vector(15 downto 0);
signal BUFFER_RDY_HC        : std_logic;
signal CCS_1                : std_logic;
signal CCS_2                : std_logic;
signal CCS_3                : std_logic;
signal CCS_4                : std_logic;
signal DM_IN_HUB            : std_logic;
signal DP_IN_HUB            : std_logic;
signal DM_OUT_HUB           : std_logic;
signal DP_OUT_HUB           : std_logic;
signal DM1_IN_I             : std_logic;
signal DP1_IN_I             : std_logic;
signal DM2_IN_I             : std_logic;
signal DP2_IN_I             : std_logic;
signal DM3_IN_I             : std_logic;
signal DP3_IN_I             : std_logic;
signal DM4_IN_I             : std_logic;
signal DP4_IN_I             : std_logic;
signal FR                   : std_logic_vector(13 downto 0);
signal FR_DEC               : std_logic;
signal FRAME_NUMBER         : std_logic_vector(10 downto 0);
signal FSMPS                : std_logic_vector(14 downto 0);
signal HC_ADR               : std_logic_vector(11 downto 0);
signal HC_ITL1              : std_logic;
signal HCFS_HC              : std_logic_vector(1 downto 0);
signal HCFS_MC              : std_logic_vector(1 downto 0);
signal HCR                  : std_logic;
signal ITL0_BUFF_DONE       : std_logic;
signal ITL1_BUFF_DONE       : std_logic;
signal ITL0_BUFF_FULL       : std_logic;
signal ITL1_BUFF_FULL       : std_logic;
signal RD_ITL0_BUFF_LENGTH  : std_logic_vector(15 downto 0);
signal RD_ITL1_BUFF_LENGTH  : std_logic_vector(15 downto 0);
signal ITL_BUFF_LEN         : std_logic_vector(11 downto 0);
signal ITL_RD_HC            : std_logic;
signal ITL_RD_MC            : std_logic;
signal ITL_WR_HC            : std_logic;
signal ITL_WR_MC            : std_logic;
signal LSDA_1               : std_logic;
signal LSDA_2               : std_logic;
signal LSDA_3               : std_logic;
signal LSDA_4               : std_logic;
signal LST                  : std_logic_vector(10 downto 0);
signal OC1_In               : std_logic;
signal OC2_In               : std_logic;
signal OC3_In               : std_logic;
signal OC4_In               : std_logic;
signal OPBERR               : std_logic;
signal OPBERR_1             : std_logic;
signal OPBERR_2             : std_logic;
signal OPBERR_3             : std_logic;
signal OPBERR_4             : std_logic;
signal POCI_1               : std_logic;
signal POCI_2               : std_logic;
signal POCI_3               : std_logic;
signal POCI_4               : std_logic;
signal PES_1                : std_logic;
signal PES_2                : std_logic;
signal PES_3                : std_logic;
signal PES_4                : std_logic;
signal PESC_2               : std_logic;
signal PESC_1               : std_logic;
signal PESC_3               : std_logic;
signal PESC_4               : std_logic;
signal PPS_1                : std_logic;
signal PPS_2                : std_logic;
signal PPS_3                : std_logic;
signal PPS_4                : std_logic;
signal PRS_1                : std_logic;
signal PRS_2                : std_logic;
signal PRS_3                : std_logic;
signal PRS_4                : std_logic;
signal PRSC_1               : std_logic;
signal PRSC_2               : std_logic;
signal PRSC_3               : std_logic;
signal PRSC_4               : std_logic;
signal PSSC_1               : std_logic;
signal PSSC_2               : std_logic;
signal PSSC_3               : std_logic;
signal PSSC_4               : std_logic;
signal RD                   : std_logic;
signal RESET                : std_logic;
signal SOF                  : std_logic;
signal SO                   : std_logic;
signal SOFTWARE_RESET       : std_logic;
signal UPSTREAM_P1          : std_logic;
signal UPSTREAM_P2          : std_logic;
signal UPSTREAM_P3          : std_logic;
signal UPSTREAM_P4          : std_logic;
signal UE                   : std_logic;
begin
    SYNC: process
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        RESET <= not RESETn;
        DM1_IN_I <= DM1_IN;
        DP1_IN_I <= DP1_IN;
        DM2_IN_I <= DM2_IN;
        DP2_IN_I <= DP2_IN;
        DM3_IN_I <= DM3_IN;
        DP3_IN_I <= DP3_IN;
        DM4_IN_I <= DM4_IN;
        DP4_IN_I <= DP4_IN;
        OC1_In <= OC1n;
        OC2_In <= OC2n;
        OC3_In <= OC3n;
        OC4_In <= OC4n;
    end process SYNC;

    -- At this point we switch the endian format to big or little endian.
    -- The USB1164 is internally arranged big endian.
    -- LITTLE_ENDIAN = false means, the USB1164 data bus is big endian.
    -- LITTLE_ENDIAN = true means, the USB1164 data bus is little endian.
    DATA_IN_MC <= DATA_IN(7 downto 0) & DATA_IN(15 downto 8) when LITTLE_ENDIAN = false else DATA_IN;
    DATA_OUT <= DATA_OUT_MC(7 downto 0) & DATA_OUT_MC(15 downto 8) when LITTLE_ENDIAN = false else DATA_OUT_MC;

    OPBERR_1 <= OPBERR when UPSTREAM_P1 = '1' else '0';
    OPBERR_2 <= OPBERR when UPSTREAM_P2 = '1' else '0';
    OPBERR_3 <= OPBERR when UPSTREAM_P3 = '1' else '0';
    OPBERR_4 <= OPBERR when UPSTREAM_P4 = '1' else '0';

    I_MC_IF: MC_INTERFACE
        port map(
            CLK_48MHz               => CLK_48MHz,
            RESET                   => RESET,
            A0                      => A0,
            CSn                     => CSn,
            RDn                     => RDn,
            WRn                     => WRn,
            DATA_IN                 => DATA_IN_MC,
            DATA_OUT                => DATA_OUT_MC,
            DATA_EN                 => DATA_EN,
            NDP_SEL                 => NDP_SEL,
            HCFS_IN                 => HCFS_HC,
            HCFS_OUT                => HCFS_MC,
            HCR                     => HCR,
            SOFTWARE_RESET          => SOFTWARE_RESET,
            UE                      => UE,
            RD                      => RD,
            SO                      => SO,
            SOF                     => SOF,
            FRAME_NUMBER            => FRAME_NUMBER,
            FSMPS                   => FSMPS,
            FR                      => FR,
            FR_DEC                  => FR_DEC,
            LST                     => LST,
            CCS_1                   => CCS_1,
            LSDA_1                  => LSDA_1,
            OPBERR_1                => OPBERR_1,
            POCI_1                  => POCI_1,
            PESC_1                  => PESC_1,
            PRSC_1                  => PRSC_1,
            PSSC_1                  => PSSC_1,
            PES_1                   => PES_1,
            PPS_1                   => PPS_1,
            PRS_1                   => PRS_1,
            CCS_2                   => CCS_2,
            LSDA_2                  => LSDA_2,
            OPBERR_2                => OPBERR_2,
            POCI_2                  => POCI_2,
            PESC_2                  => PESC_2,
            PRSC_2                  => PRSC_2,
            PSSC_2                  => PSSC_2,
            PES_2                   => PES_2,
            PPS_2                   => PPS_2,
            PRS_2                   => PRS_2,
            CCS_3                   => CCS_3,
            LSDA_3                  => LSDA_3,
            OPBERR_3                => OPBERR_3,
            POCI_3                  => POCI_3,
            PESC_3                  => PESC_3,
            PRSC_3                  => PRSC_3,
            PSSC_3                  => PSSC_3,
            PES_3                   => PES_3,
            PPS_3                   => PPS_3,
            PRS_3                   => PRS_3,
            CCS_4                   => CCS_4,
            LSDA_4                  => LSDA_4,
            OPBERR_4                => OPBERR_4,
            POCI_4                  => POCI_4,
            PESC_4                  => PESC_4,
            PRSC_4                  => PRSC_4,
            PSSC_4                  => PSSC_4,
            PES_4                   => PES_4,
            PPS_4                   => PPS_4,
            PRS_4                   => PRS_4,
            DP15K                   => DP15K,
            CLKNS                   => CLKNS,
            AOCEN                   => AOCEN,
            INT                     => INT,
            DACKn                   => DACKn,
            DREQ                    => DREQ,
            EOT                     => EOT,
            WAKEUP                  => WAKEUP,
            SUSPEND                 => SUSPEND,
            ATL_INT                 => ATL_INT,
            ITL_INT                 => ITL_INT,
            ITL_BUFF_LEN            => ITL_BUFF_LEN,
            ATL_BUFF_DONE           => ATL_BUFF_DONE,
            ITL1_BUFF_DONE          => ITL1_BUFF_DONE,
            ITL0_BUFF_DONE          => ITL0_BUFF_DONE,
            ATL_BUFF_FULL           => ATL_BUFF_FULL,
            ITL1_BUFF_FULL          => ITL1_BUFF_FULL,
            ITL0_BUFF_FULL          => ITL0_BUFF_FULL,
            RD_ITL0_BUFF_LENGTH     => RD_ITL0_BUFF_LENGTH,
            RD_ITL1_BUFF_LENGTH     => RD_ITL1_BUFF_LENGTH,
            BUFFER_IN               => BUFFER_IN_MC,
            BUFFER_OUT              => BUFFER_OUT_MC,
            ITL_RD                  => ITL_RD_MC,
            ITL_WR                  => ITL_WR_MC,
            ATL_RD                  => ATL_RD_MC,
            ATL_WR                  => ATL_WR_MC,
            HC_ITL1                 => HC_ITL1
        );
        
    I_FIFO: FIFO_BUFFER
        port map(
            CLK_48MHz               => CLK_48MHz,
            RESET                   => RESET,
            HCR                     => HCR,

            ITL_BUFF_LEN            => ITL_BUFF_LEN,
            RD_ITL0_BUFF_LENGTH     => RD_ITL0_BUFF_LENGTH,
            RD_ITL1_BUFF_LENGTH     => RD_ITL1_BUFF_LENGTH,

            BUFFER_IN_MC            => BUFFER_OUT_MC,
            BUFFER_IN_HC            => BUFFER_OUT_HC,
            BUFFER_OUT_MC           => BUFFER_IN_MC,
            BUFFER_OUT_HC           => BUFFER_IN_HC,
            BUFFER_RDY_HC           => BUFFER_RDY_HC,

            ATL_RD_MC               => ATL_RD_MC,
            ATL_WR_MC               => ATL_WR_MC,
            ITL_RD_MC               => ITL_RD_MC,
            ITL_WR_MC               => ITL_WR_MC,

            ATL_RD_HC               => ATL_RD_HC,
            ATL_WR_HC               => ATL_WR_HC,
            ITL_RD_HC               => ITL_RD_HC,
            ITL_WR_HC               => ITL_WR_HC,
            HC_ITL1                 => HC_ITL1,
            HC_ADR                  => HC_ADR
        );

    I_HC: HOST_CONTROLLER
        port map(
            CLK_48MHz               => CLK_48MHz,
            RESET                   => RESET,

            DP_IN                   => DP_OUT_HUB,
            DM_IN                   => DM_OUT_HUB,
            DP_OUT                  => DP_IN_HUB, 
            DM_OUT                  => DM_IN_HUB, 

            BUFFER_IN               => BUFFER_IN_HC,
            BUFFER_RDY              => BUFFER_RDY_HC,
            BUFFER_OUT              => BUFFER_OUT_HC,

            ATL_BUFF_FULL           => ATL_BUFF_FULL,
            ITL0_BUFF_FULL          => ITL0_BUFF_FULL,
            ITL1_BUFF_FULL          => ITL1_BUFF_FULL,
            ATL_BUFF_DONE           => ATL_BUFF_DONE,
            ITL1_BUFF_DONE          => ITL1_BUFF_DONE,
            ITL0_BUFF_DONE          => ITL0_BUFF_DONE,

            ATL_RD                  => ATL_RD_HC,
            ATL_WR                  => ATL_WR_HC,
            ITL_RD                  => ITL_RD_HC,
            ITL_WR                  => ITL_WR_HC,
            HC_ITL1                 => HC_ITL1,
            HC_ADR                  => HC_ADR,

            HCR                     => HCR,
            SOFTWARE_RESET          => SOFTWARE_RESET,
            HCFS_IN                 => HCFS_MC,
            HCFS_OUT                => HCFS_HC,

            UE                      => UE,
            SO                      => SO,
            SOF                     => SOF,
            FRAME_NUMBER            => FRAME_NUMBER,
            
            FSMPS                   => FSMPS,
            FR                      => FR,
            FR_DEC                  => FR_DEC,
            LST                     => LST,
            ATL_INT                 => ATL_INT,
            ITL_INT                 => ITL_INT,

            RD                      => RD,
            OPBERR                  => OPBERR
        );

    I_ROOTHUB: ROOTHUB_4PORT
        port map(
            CLK_48MHz               => CLK_48MHz,
            RESET                   => RESET,

            DP1_IN                  => DP1_IN_I,
            DM1_IN                  => DM1_IN_I,
            DP2_IN                  => DP2_IN_I,
            DM2_IN                  => DM2_IN_I,
            DP3_IN                  => DP3_IN_I,
            DM3_IN                  => DM3_IN_I,
            DP4_IN                  => DP4_IN_I,
            DM4_IN                  => DM4_IN_I,
            DP1_OUT                 => DP1_OUT,
            DM1_OUT                 => DM1_OUT,
            DPM1_EN                 => DPM1_EN,
            DP2_OUT                 => DP2_OUT,
            DM2_OUT                 => DM2_OUT,
            DPM2_EN                 => DPM2_EN,
            DP3_OUT                 => DP3_OUT,
            DM3_OUT                 => DM3_OUT,
            DPM3_EN                 => DPM3_EN,
            DP4_OUT                 => DP4_OUT,
            DM4_OUT                 => DM4_OUT,
            DPM4_EN                 => DPM4_EN,

            DP_IN                   => DP_IN_HUB,
            DM_IN                   => DM_IN_HUB,
            DP_OUT                  => DP_OUT_HUB, 
            DM_OUT                  => DM_OUT_HUB, 

            PSW1n                   => PSW1n,
            PSW2n                   => PSW2n,
            PSW3n                   => PSW3n,
            PSW4n                   => PSW4n,
            OC1n                    => OC1_In,
            OC2n                    => OC2_In,
            OC3n                    => OC3_In,
            OC4n                    => OC4_In,

            CCS_1                   => CCS_1,
            LSDA_1                  => LSDA_1,
            POCI_1                  => POCI_1,
            PESC_1                  => PESC_1,
            PRSC_1                  => PRSC_1,
            PSSC_1                  => PSSC_1,
            PES_1                   => PES_1,
            PPS_1                   => PPS_1,
            PRS_1                   => PRS_1,

            CCS_2                   => CCS_2,
            LSDA_2                  => LSDA_2,
            POCI_2                  => POCI_2,
            PESC_2                  => PESC_2,
            PRSC_2                  => PRSC_2,
            PSSC_2                  => PSSC_2,
            PES_2                   => PES_2,
            PPS_2                   => PPS_2,
            PRS_2                   => PRS_2,

            CCS_3                   => CCS_3,
            LSDA_3                  => LSDA_3,
            POCI_3                  => POCI_3,
            PESC_3                  => PESC_3,
            PRSC_3                  => PRSC_3,
            PSSC_3                  => PSSC_3,
            PES_3                   => PES_3,
            PPS_3                   => PPS_3,
            PRS_3                   => PRS_3,

            CCS_4                   => CCS_4,
            LSDA_4                  => LSDA_4,
            POCI_4                  => POCI_4,
            PESC_4                  => PESC_4,
            PRSC_4                  => PRSC_4,
            PSSC_4                  => PSSC_4,
            PES_4                   => PES_4,
            PPS_4                   => PPS_4,
            PRS_4                   => PRS_4,

            UPSTREAM_P1             => UPSTREAM_P1,
            UPSTREAM_P2             => UPSTREAM_P2,
            UPSTREAM_P3             => UPSTREAM_P3,
            UPSTREAM_P4             => UPSTREAM_P4
        );
end STRUCTURE;
