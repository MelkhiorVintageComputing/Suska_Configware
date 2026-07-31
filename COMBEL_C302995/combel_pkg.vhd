------------------------------------------------------------------------
----                                                                ----
---- ATARI Falcon COMBEL compatible IP Core                         ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Atari's COMBEL with all features to reach                      ----
---- ATARI Falcon compatibility.                                    ----
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
---- Copyright Â© 2009... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- All rights reserved. No portion of this sourcecode may be      ----
---- reproduced or transmitted in any form by any means, whether    ----
---- by electronic, mechanical, photocopying, recording or          ----
---- otherwise, without my written permission.                      ----
----                                                                ----
------------------------------------------------------------------------
--
-- Revision History
--
-- Revision 2K9B  2009/12/24 WF
--   Initial Release.
-- Revision 2K21A 20211224 WF
--   Adaptions respective to the requirements of COMBEL changes.
--

library ieee;
use ieee.std_logic_1164.all;

package COMBEL_PKG is
    type RAM_TYPES is (K128, K512, K2048, K8192, K16384, K4096x32x4);
    type MCU_PHASE_TYPE is (IDLE, RAM, VIDEO, REFRESH);
    type MADR_TYPE is (MEM_LOW_ADR, MEM_HI_ADR);
    type RAMWIDTH_TYPE is(L32, W16, B8);

    -- Component declarations:
    component CLOCKS
    port (
        CLK     : in std_logic;

        CLK_04  : out std_logic;
        CLK_08  : out std_logic;
        CLK_064 : out std_logic
    );
    end component;

    component BLITTER_TOP
        port (
            CLK                     : in std_logic;
            RESET                   : in std_logic;
            AS_INn                  : in std_logic;
            AS_OUTn                 : out std_logic;
            LDS_INn                 : in std_logic;
            LDS_OUTn                : out std_logic;
            UDS_INn                 : in std_logic;
            UDS_OUTn                : out std_logic;
            RWn_IN                  : in std_logic;
            RWn_OUT                 : out std_logic;
            DTACK_INn               : in std_logic;
            DTACK_OUTn              : out std_logic;
            BERRn                   : in std_logic;
            BMODE                   : in std_logic;
            FC_IN                   : in std_logic_vector(2 downto 0);
            FC_OUT                  : out std_logic_vector(2 downto 0);
            BUSCTRL_EN              : out std_logic;
            INTn                    : out std_logic;
            ADR_IN                  : in std_logic_vector(31 downto 1);
            ADR_OUT                 : out std_logic_vector(31 downto 1);
            ADR_EN                  : out std_logic;
            DATA_IN                 : in std_logic_vector(15 downto 0);
            DATA_OUT                : out std_logic_vector(15 downto 0);
            DATA_EN                 : out std_logic;
            BGIn                    : in std_logic;
            BRn                     : out std_logic;
            BGACK_INn               : in std_logic;
            BGACK_OUTn              : out std_logic;
            BGOn                    : out std_logic
        );
    end component;

    component ADRDEC
        port (
            ADR                     : in std_logic_vector(31 downto 1);
            RWn                     : in std_logic;
            LDSn                    : in std_logic;
            UDSn                    : in std_logic;
            ASn                     : in std_logic;
            VPAn                    : out std_logic;
            VMAn                    : in std_logic;
            FC                      : in std_logic_vector(2 downto 0);
            ROM_0n                  : out std_logic;
            ROM_1n                  : out std_logic;
            ROM_2n                  : out std_logic;
            ROM_3n                  : out std_logic;
            ROM_4n                  : out std_logic;
            ROM_5n                  : out std_logic;
            ROM_6n                  : out std_logic;
            ACIACS                  : out std_logic;
            MFPCSn                  : out std_logic;
            SNDCSn                  : out std_logic;
            SCCn                    : out std_logic;
            RTCCS                   : out std_logic; -- Select signal for the DS1287 real time clock.
            RP5C15_CS               : out std_logic; -- Select signal for the RP5C15 real time clock.
            JOY_RS                  : out std_logic;
            PAD0X_RS                : out std_logic;
            PAD0Y_RS                : out std_logic;
            PAD1X_RS                : out std_logic;
            PAD1Y_RS                : out std_logic;
            BUTTON_RS               : out std_logic;
            R8006_RS                : out std_logic;
            R8007_RS                : out std_logic;
            FPUCS                   : out std_logic;
            VCS                     : out std_logic;
            MEM_CONFIG_RS           : out std_logic;
            LINE_OFFS_RS            : out std_logic;
            LINE_WIDTH_RS           : out std_logic;
            VIDEO_BASE_HIWORD_RS    : out std_logic;
            VIDEO_BASE_LOWORD_RS    : out std_logic;
            VIDEO_COUNT_HIWORD_RS   : out std_logic;
            VIDEO_COUNT_LOWORD_RS   : out std_logic;
            VIDEO_BASE_HI_RS        : out std_logic;
            VIDEO_BASE_MID_RS       : out std_logic;
            VIDEO_BASE_LOW_RS       : out std_logic;
            VIDEO_COUNT_HI_RS       : out std_logic;
            VIDEO_COUNT_MID_RS      : out std_logic;
            VIDEO_COUNT_LOW_RS      : out std_logic;
            SHMOD_ST_SHADOW_RS      : out std_logic;
            VMODE_SHADOW_RS         : out std_logic;
            RAM_16MB                : in std_logic;
            RAM_512MB               : in std_logic;
            RAMn                    : out std_logic;
            ALTRAMn                 : out std_logic;
            Lightning_CSn           : out std_logic; -- Lightning-CPLD Dummy
            SHADOW_TOS_CSn          : out std_logic;
            USB1160_CSn             : out std_logic
          );
    end component;

    component MCU_TOP
        generic(RAM_16              : boolean); -- Set true, if we have a 16 bit RAM data bus, false for 32 bit.
        port(
            CLK                     : in std_logic;
            SYS_RESET_INn           : in std_logic;
            SYS_RESET_OUTn          : out std_logic;
            RESET                   : in std_logic;
            LDSn                    : in std_logic;
            UDSn                    : in std_logic;
            RWn                     : in std_logic;
            ADR                     : in std_logic_vector(31 downto 0);
            RAMn                    : in std_logic;
            VREQ                    : in std_logic;
            EVENn_ODD               : in std_logic;
            RDATn                   : out std_logic;
            WDATn                   : out std_logic;
            RAMH                    : out std_logic;
            VINT                    : in std_logic;
            VIDEO_BASE_HIWORD_RS    : in std_logic;
            VIDEO_BASE_LOWORD_RS    : in std_logic;
            VIDEO_COUNT_HIWORD_RS   : in std_logic;
            VIDEO_COUNT_LOWORD_RS   : in std_logic;
            VIDEO_BASE_HI_RS        : in std_logic;
            VIDEO_BASE_MID_RS       : in std_logic;
            VIDEO_BASE_LOW_RS       : in std_logic;
            VIDEO_COUNT_HI_RS       : in std_logic;
            VIDEO_COUNT_MID_RS      : in std_logic;
            VIDEO_COUNT_LOW_RS      : in std_logic;
            R8006_SHADOW_RS         : in std_logic;
            SHMOD_ST_SHADOW_RS      : in std_logic;
            VMODE_SHADOW_RS         : in std_logic;
            MEM_CONFIG_RS           : in std_logic;
            LINE_OFFS_RS            : in std_logic;
            LINE_WIDTH_RS           : in std_logic;
            DTACKn                  : out std_logic;
            DATA_IN                 : in std_logic_vector(15 downto 0);
            DATA_OUT                : out std_logic_vector(15 downto 0);
            DATA_EN                 : out std_logic;
            -- RAM interface:
            CKE                     : out std_logic; -- RAM clock enable.
            CSn                     : out std_logic; -- RAM chip enable.
            BA                      : out std_logic_vector(1 downto 0); -- SD-RAM bank select.
            MAD                     : out std_logic_vector(12 downto 0); -- SD-RAM address bus.
            MAD_32                  : out std_logic_vector(31 downto 2); -- SD-RAM address bus.
            WEn                     : out std_logic;
            RASn                    : out std_logic; -- This is for 512Mb chips.
            CASn                    : out std_logic; -- This is for 512Mb chips.
            RAS0n                   : out std_logic; -- This is for 256Mb chips.
            CAS0n                   : out std_logic; -- This is for 256Mb chips.
            RAS1n                   : out std_logic; -- This is for 256Mb chips.
            CAS1n                   : out std_logic; -- This is for 256Mb chips.
            BUS_WIDTH               : in RAMWIDTH_TYPE; -- Select RAM bus width in K30 mode.
            SIZE                    : in std_logic_vector(1 downto 0); -- Data size control.
            DQMn                    : out std_logic_vector(3 downto 0); -- SD-RAM output buffer controls.
            VLDn                    : out std_logic -- Video data load signal.
        );
    end component;

    component MCU_CTRL
        port (
            CLK                     : in std_logic;
            RESET                   : in std_logic;
            LDSn                    : in std_logic;
            UDSn                    : in std_logic;
            RWn                     : in std_logic;
            M_ADR                   : in std_logic_vector(25 downto 1);
            RAMn                    : in std_logic;
            MEM_CONFIG_RS           : in std_logic;
            MCU_PHASE               : out MCU_PHASE_TYPE;
            VINT                    : in std_logic;
            VREQ                    : in std_logic;
            VLDn                    : out std_logic;
            RAS0n                   : out std_logic;
            CAS0n                   : out std_logic;
            CAS0Hn                  : out std_logic;
            CAS0Ln                  : out std_logic;
            RAS1n                   : out std_logic;
            CAS1n                   : out std_logic;
            CAS1Hn                  : out std_logic;
            CAS1Ln                  : out std_logic;
            WEn                     : out std_logic;
            RDATn                   : out std_logic;
            WDATn                   : out std_logic;
            RAMH                    : out std_logic;
            REF_EN                  : out std_logic;
            VIDEO_CNT_EN            : out std_logic;
            VIDEO_CNT_LOAD          : out std_logic;
            MADRSEL                 : out MADR_TYPE;
            DTACKn                  : out std_logic;
            DATA_IN                 : in std_logic_vector(7 downto 0);
            DATA_OUT                : out std_logic_vector(7 downto 0);
            DATA_EN                 : out std_logic
        );
    end component;

    component MCU_VIDEO_COUNTER
    generic(RAM_16              : boolean); -- Set true, if we have a 16 bit RAM data bus, false for 32 bit.
    port (  CLK                     : in std_logic;
            RESET                   : in std_logic;
            RWn                     : in std_logic;
            VIDEO_BASE_HIWORD_RS    : in std_logic;
            VIDEO_BASE_LOWORD_RS    : in std_logic;
            VIDEO_COUNT_HIWORD_RS   : in std_logic;
            VIDEO_COUNT_LOWORD_RS   : in std_logic;
            VIDEO_BASE_HI_RS        : in std_logic;
            VIDEO_BASE_MID_RS       : in std_logic;
            VIDEO_BASE_LOW_RS       : in std_logic;
            VIDEO_COUNT_HI_RS       : in std_logic;
            VIDEO_COUNT_MID_RS      : in std_logic;
            VIDEO_COUNT_LOW_RS      : in std_logic;
            R8006_SHADOW_RS         : in std_logic;
            SHMOD_ST_SHADOW_RS      : in std_logic;
            VMODE_SHADOW_RS         : in std_logic;
            EVENn_ODD               : in std_logic;
            VIDEO_COUNT_EN          : in std_logic;
            VIDEO_COUNT_LOAD        : in std_logic;
            LINE_OFFS_RS            : in std_logic;
            LINE_WIDTH_RS           : in std_logic;
            VIDEO_ADR_OUT           : out std_logic_vector(31 downto 1);
            DATA_IN                 : in std_logic_vector(15 downto 0);
            DATA_OUT                : out std_logic_vector(15 downto 0);
            DATA_EN                 : out std_logic
          );
    end component;

    component INTERRUPTS
        port(
            RESET                   : in std_logic;
            CLK                     : in std_logic;
            ADR_HI                  : in std_logic_vector(19 downto 16);
            ADR_LO                  : in std_logic_vector(3 downto 1);
            FC                      : in std_logic_vector(2 downto 0);
            ASn                     : in std_logic;
            EINT1                   : in std_logic;
            EINT3                   : in std_logic;
            EINT5n                  : in std_logic;
            EINT7n                  : in std_logic;
            MFPINTn                 : in std_logic;
            HINT                    : in std_logic;
            VINT                    : in std_logic;
            AVECn                   : out std_logic;
            IACKn                   : out std_logic;
            SCCIACKn                : out std_logic;
            IPLn                    : out std_logic_vector(2 downto 0) -- STE GLUE.
        );
    end component;

    component ERRHANDLER
        port(
            RESET                   : in std_logic;
            CLK                     : in std_logic;
            ASn                     : in std_logic;

            BERRn                   : out std_logic
        );
    end component;

    component JOYPORT_PADDLES
        port(
            CLK                     : in std_logic;
            KHz_500                 : in std_logic;
            RESET                   : in std_logic;
            DATA_OUT                : out std_logic_vector(15 downto 0);
            DATA_EN                 : out std_logic;
            PAD0X_RS                : in std_logic;
            PAD0Y_RS                : in std_logic;
            PAD1X_RS                : in std_logic;
            PAD1Y_RS                : in std_logic;
            PAD0X_INHn              : in std_logic;
            PAD0Y_INHn              : in std_logic;
            PAD1X_INHn              : in std_logic;
            PAD1Y_INHn              : in std_logic;
            PADRSTn                 : out std_logic
        );
    end component;

    component WF_IDE
        port (
            CLK                     : in std_logic;
            RESET                   : in std_logic;

            ADR                     : in std_logic_vector(31 downto 1);
            DATA_IN		            : in std_logic_vector(7 downto 0);

            ASn                     : in std_logic;
            LDSn                    : in std_logic;
            RWn                     : in std_logic;
            DTACKn                  : out std_logic;
            HDINTn                  : out std_logic;
            IDE_INTRQ               : in std_logic;
            IDE_IORDY               : in std_logic;
            -- PDIAG                : in std_logic;
            -- DASP                 : in std_logic;
            -- DMARQ                : in std_logic;
            -- DMACKn               : out std_logic;
            IDE_RESn                : out std_logic;
            CS0n                    : out std_logic;
            CS1n                    : out std_logic;
            IORDn                   : out std_logic;
            IOWRn                   : out std_logic;
            IDE_BYTESWAP            : out std_logic;
            IDE_D_EN_INn            : out std_logic;
            IDE_D_EN_OUTn           : out std_logic
          );
    end component;
end COMBEL_PKG;
