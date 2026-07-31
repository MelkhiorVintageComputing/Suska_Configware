------------------------------------------------------------------------
----                                                                ----
---- USB1160 IP Core                                                ----
----                                                                ----
---- Description:                                                   ----
---- This model provides an embedded Universal Serial Bus host      ----
---- controller compatible to the Philips ISP1160.                  ----
----                                                                ----
---- This  is the package file of the ip core.                      ----
----                                                                ----
----                                                                ----
----                                                                ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2020... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K20B  20201224 WF
--   Draft version.
-- Revision 2K22A  20221224 WF
--   Debugging version.
-- Revision 2K23A  20230620 WF
--   Initial release.
-- Revision 2K23B  20231224 WF
--   Updates concerning changes in the entities.
--

library ieee;
use ieee.std_logic_1164.all;

package USB1160_PKG is
    component MC_INTERFACE
        port (
            CLK_48MHz            : in std_logic;
            RESET               : in std_logic;
            A0                  : in std_logic;
            CSn                 : in std_logic;
            RDn                 : in std_logic;
            WRn                 : in std_logic;
            DATA_IN             : in  std_logic_vector(15 downto 0);
            DATA_OUT            : out std_logic_vector(15 downto 0);
            DATA_EN             : out std_logic;
            NDP_SEL             : in std_logic;
            HCFS_IN             : in std_logic_vector(1 downto 0);
            HCFS_OUT            : out std_logic_vector(1 downto 0);
            HCR                 : out std_logic;
            SOFTWARE_RESET      : out std_logic;
            UE                  : in std_logic;
            RD                  : in std_logic;
            SO                  : in std_logic;
            SOF                 : out std_logic;
            FRAME_NUMBER        : out std_logic_vector(10 downto 0);
            FSMPS               : out std_logic_vector(14 downto 0);
            FR                  : out std_logic_vector(13 downto 0);
            FR_DEC              : in std_logic;
            LST                 : out std_logic_vector(10 downto 0);
            CCS_1               : in std_logic;
            LSDA_1              : in std_logic;
            OPBERR_1            : in std_logic;
            POCI_1              : in std_logic;
            PESC_1              : in std_logic;
            PRSC_1              : in std_logic;
            PSSC_1              : in std_logic;
            PES_1               : out std_logic;
            PPS_1               : out std_logic;
            PRS_1               : out std_logic;
            CCS_2               : in std_logic;
            LSDA_2              : in std_logic;
            OPBERR_2            : in std_logic;
            POCI_2              : in std_logic;
            PESC_2              : in std_logic;
            PRSC_2              : in std_logic;
            PSSC_2              : in std_logic;
            PES_2               : out std_logic;
            PPS_2               : out std_logic;
            PRS_2               : out std_logic;
            DP15K               : out std_logic;
            CLKNS               : out std_logic;
            AOCEN               : out std_logic;
            INT                 : out std_logic;
            DACKn               : in std_logic;
            DREQ                : out std_logic;
            EOT                 : in std_logic;
            WAKEUP              : in std_logic;
            SUSPEND             : out std_logic;
            ATL_INT             : in std_logic;
            ITL_INT             : in std_logic;
            ITL_BUFF_LEN        : out std_logic_vector(11 downto 0);
            RD_ITL0_BUFF_LENGTH : in std_logic_vector(15 downto 0);
            RD_ITL1_BUFF_LENGTH : in std_logic_vector(15 downto 0);
            ATL_BUFF_DONE       : in std_logic;
            ITL1_BUFF_DONE      : in std_logic;
            ITL0_BUFF_DONE      : in std_logic;
            ATL_BUFF_FULL       : out std_logic;
            ITL1_BUFF_FULL      : out std_logic;
            ITL0_BUFF_FULL      : out std_logic;
            BUFFER_IN           : in std_logic_vector(15 downto 0);
            BUFFER_OUT          : out std_logic_vector(15 downto 0);
            ITL_RD              : out std_logic;
            ITL_WR              : out std_logic;
            ATL_RD              : out std_logic;
            ATL_WR              : out std_logic;
            HC_ITL1             : in std_logic
        );
    end component MC_INTERFACE;

    component FIFO_BUFFER
        port (
            CLK_48MHz           : in std_logic;
            RESET               : in std_logic;
            HCR                 : in std_logic;
            ITL_BUFF_LEN        : in std_logic_vector(11 downto 0);
            RD_ITL0_BUFF_LENGTH : out std_logic_vector(15 downto 0);
            RD_ITL1_BUFF_LENGTH : out std_logic_vector(15 downto 0);
            BUFFER_IN_MC        : in std_logic_vector(15 downto 0);
            BUFFER_IN_HC        : in std_logic_vector(15 downto 0);
            BUFFER_OUT_MC       : out std_logic_vector(15 downto 0);
            BUFFER_OUT_HC       : out std_logic_vector(15 downto 0);
            BUFFER_RDY_HC       : out std_logic;
            ATL_RD_MC           : in std_logic;
            ATL_WR_MC           : in std_logic;
            ITL_RD_MC           : in std_logic;
            ITL_WR_MC           : in std_logic;
            ATL_RD_HC           : in std_logic;
            ATL_WR_HC           : in std_logic;
            ITL_RD_HC           : in std_logic;
            ITL_WR_HC           : in std_logic;
            HC_ITL1             : in std_logic;
            HC_ADR              : in std_logic_vector(11 downto 0)
        );
    end component FIFO_BUFFER;

    component HOST_CONTROLLER
        port (
            CLK_48MHz            : in std_logic;
            RESET               : in std_logic;

            DP_IN               : in std_logic;
            DM_IN               : in std_logic;
            DP_OUT              : out std_logic;
            DM_OUT              : out std_logic;

            BUFFER_IN           : in std_logic_vector(15 downto 0);
            BUFFER_RDY          : in std_logic;
            BUFFER_OUT          : out std_logic_vector(15 downto 0);

            ATL_BUFF_FULL       : in std_logic;
            ITL0_BUFF_FULL      : in std_logic;
            ITL1_BUFF_FULL      : in std_logic;
            ATL_BUFF_DONE       : buffer std_logic;
            ITL0_BUFF_DONE      : out std_logic;
            ITL1_BUFF_DONE      : out std_logic;
    
            ATL_RD              : out std_logic;
            ATL_WR              : out std_logic;
            ITL_RD              : out std_logic;
            ITL_WR              : out std_logic;
            HC_ITL1             : out std_logic;
            HC_ADR              : out std_logic_vector(11 downto 0);
            
            HCR                 : in std_logic;
            SOFTWARE_RESET      : in std_logic;
            HCFS_IN             : in std_logic_vector(1 downto 0);
            HCFS_OUT            : out std_logic_vector(1 downto 0);

            FSMPS               : in std_logic_vector(14 downto 0);
            FR                  : in std_logic_vector(13 downto 0);
            FR_DEC              : out std_logic;
            LST                 : in std_logic_vector(10 downto 0);

            ATL_INT             : out std_logic;
            ITL_INT             : out std_logic;

            UE                  : out std_logic;
            SO                  : out std_logic;
            SOF                 : in std_logic;
            FRAME_NUMBER        : in std_logic_vector(10 downto 0);

            RD                  : out std_logic;
            OPBERR              : out std_logic
        );
    end component HOST_CONTROLLER;

    component ROOTHUB_2PORT
        port(
            CLK_48MHz           : in std_logic;
            RESET               : in std_logic;

            DP1_IN              : in std_logic;
            DM1_IN              : in std_logic;
            DP2_IN              : in std_logic;
            DM2_IN              : in std_logic;
            DP1_OUT             : out std_logic;
            DM1_OUT             : out std_logic;
            DPM1_EN             : out std_logic;
            DP2_OUT             : out std_logic;
            DM2_OUT             : out std_logic;
            DPM2_EN             : out std_logic;

            DP_IN               : in std_logic;
            DM_IN               : in std_logic;
            DP_OUT              : out std_logic;
            DM_OUT              : out std_logic;

            PSW1n               : buffer std_logic;
            PSW2n               : buffer std_logic;
            OC1n                : in std_logic;
            OC2n                : in std_logic;

            CCS_1               : out std_logic;
            LSDA_1              : out std_logic;
            POCI_1              : out std_logic;
            PESC_1              : out std_logic;
            PRSC_1              : out std_logic;
            PSSC_1              : out std_logic;
            PES_1               : in std_logic;
            PPS_1               : in std_logic;
            PRS_1               : in std_logic;

            CCS_2               : out std_logic;
            LSDA_2              : out std_logic;
            POCI_2              : out std_logic;
            PESC_2              : out std_logic;
            PRSC_2              : out std_logic;
            PSSC_2              : out std_logic;
            PES_2               : in std_logic;
            PPS_2               : in std_logic;
            PRS_2               : in std_logic;

            UPSTREAM_P1_P2n     : out std_logic
        );
    end component ROOTHUB_2PORT;
end USB1160_PKG;
