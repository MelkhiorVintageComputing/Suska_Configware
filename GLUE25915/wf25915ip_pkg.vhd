------------------------------------------------------------------------
----                                                                ----
---- ATARI GLUE compatible IP Core                                  ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Atari's ST GLUE with all features to reach                     ----
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
--   Initial Release.
-- Revision 2K6B    2006/11/05 WF
--   Modified Source to compile with the Xilinx ISE.
-- Revision 2K8A  2008/07/14 WF
--   Minor changes.
-- Revision 2K9A  2008/12/08 WF
--   Enhancements for the multisync compatible video modi.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
-- Revision 2K21A 2021224 UMA/WF
--   GLUE has now 32 bit address bus and address decoding.
-- Revision 2K23A 20230620 UMA
--   Implemented Udo Matthe Shadow TOS.
-- Revision 2K23B 20231224
--   Removed the ROMSEL_FC_E0n switch ROM_2n is now valid in both address spaces (UMA).
-- Revision 2K24A 20240620
--   SCC enhancements.
--

library ieee;
use ieee.std_logic_1164.all;

package WF25915IP_PKG is
type CLKSEL_TYPE is (CLK_16M, CLK_8M);
-- Component declarations:
component WF25915IP_INTERRUPTS
    port(
        RESETn          : in std_logic;
        CLK             : in std_logic;
        ADR_HI          : in std_logic_vector(19 downto 16);
        ADR_LO          : in std_logic_vector(3 downto 1);
        FC              : in std_logic_vector(2 downto 0);
        ASn             : in std_logic;
        EINT3n          : in std_logic; -- STE GLUE.
        EINT5n          : in std_logic; -- STE GLUE.
        EINT7n          : in std_logic; -- STE GLUE.
        MFPINTn         : in std_logic;
        HSYNCn          : in std_logic;
        VSYNCn          : in std_logic;
        VIDEO_HIMODE    : in std_logic;
        AVECn           : out std_logic;
        IACKn           : out std_logic;
		SCCIACKn		: out std_logic;
        GI2n            : out std_logic;
        GI1n            : out std_logic;
        IPLn            : out std_logic_vector(2 downto 0) -- STE GLUE.
    );
end component;

component WF25915IP_ADRDEC
    generic(TOS_CONFIG  : integer range 0 to 7);
    port (
        ADR             : in std_logic_vector(31 downto 1);
        RWn             : in std_logic;

        RESETn          : in std_logic;

        EN_RAM_14MB     : in std_logic;

        LDSn            : in std_logic;
        UDSn            : in std_logic;

        ASn             : in std_logic;
        VPAn            : out std_logic;
        VMAn            : in std_logic;

        FC              : in std_logic_vector(2 downto 0);

        DMAn            : in std_logic;

        ROM_0n          : out std_logic;
        ROM_1n          : out std_logic;
        ROM_2n          : out std_logic;
        ROM_3n          : out std_logic;
        ROM_4n          : out std_logic;
        ROM_5n          : out std_logic;
        ROM_6n          : out std_logic;
        PATCHn          : out std_logic;
        ACIACS          : out std_logic;
        MFPCSn          : out std_logic;
        SNDCSn          : out std_logic;
        A4299_CS        : out std_logic;
        FCSn            : out std_logic;
        SCCn            : out std_logic;
        CPROGn          : out std_logic;
        HD_REG_CSn      : out std_logic;
        RTCCSn          : out std_logic;
        SYNCMODE_CSn    : out std_logic;
        SHIFTMODE_CSn   : out std_logic;
        DMA_MODE_CSn    : out std_logic;
        DEVn            : out std_logic;
        RAMn            : out std_logic;
        ALTRAMn         : out std_logic;
        JOY_CS          : out std_logic;
        PAD0X_CS        : out std_logic;
        PAD0Y_CS        : out std_logic;
        PAD1X_CS        : out std_logic;
        PAD1Y_CS        : out std_logic;
        BUTTON_CS       : out std_logic;
        XPEN_REG_CS     : out std_logic;
        YPEN_REG_CS     : out std_logic;
        SHADOW_TOS_CSn  : out std_logic;
        Lightning_CSn   : out std_logic;
        USB1160_CSn     : out std_logic
    );
end component;

component WF25915IP_VIDEO_TIMING
    generic(CLKSEL      : CLKSEL_TYPE);
    port(
        RESETn          : in std_logic;
        CLK             : in std_logic;
        DATA_IN         : in std_logic_vector(7 downto 0);
        DATA_OUT        : out std_logic_vector(1 downto 0);
        DATA_EN         : out std_logic;

        RWn             : in std_logic;
        SYNCMODE_CSn    : in std_logic;
        SHIFTMODE_CSn   : in std_logic;

        DE              : out std_logic;
        MULTISYNC       : in std_logic_vector(1 downto 0);
        VIDEO_HIMODE    : out std_logic;
        BLANKn          : out std_logic;

        VSYNC_INn       : in std_logic;
        HSYNC_INn       : in std_logic;
        VSYNC_OUTn      : out std_logic;
        HSYNC_OUTn      : out std_logic;
        SYNC_OUT_EN     : out std_logic
    );
end component;

component WF25915IP_CLOCKS
    port (
        CLK_x1          : in std_logic;

        CLK_x1_4        : out std_logic;
        CLK_x1_16       : out std_logic
    );
end component;

component WF25915IP_ERRHANDLE
    port(
        RESETn          : in std_logic;
        CLK             : in std_logic;
        ASn             : in std_logic;

        BERRn           : out std_logic
    );
end component;

component WF25915IP_BUS_ARBITER
    port (
        RESETn          : in std_logic;
        CLK             : in std_logic;

        D8              : in std_logic;

        RAMn            : in std_logic;
        DTACKn          : in std_logic;
        AS_INn          : in std_logic;
        AS_OUTn         : out std_logic;
        RWn_OUT         : out std_logic;
        LDS_OUTn        : out std_logic;
        UDS_OUTn        : out std_logic;
        FC_OUT          : out std_logic_vector(2 downto 0);
        CTRL_EN         : out std_logic;

        RDY_INn         : in std_logic;
        RDY_OUTn        : out std_logic;
        BGACK_INn       : in std_logic;
        BGACK_OUTn      : out std_logic;
        DMA_MODE_CSn    : in std_logic;
        BGIn            : in std_logic;
        BRn             : out std_logic;
        BGOn            : out std_logic;
        DMAn            : out std_logic
    );
end component;

component WF25915IP_STE_ENH
    generic(CLKSEL      : CLKSEL_TYPE);
    port(
        CLK, CLK_0M5    : in std_logic;
        RESETn          : in std_logic;
        RWn             : in std_logic;
        DATA_IN         : in std_logic_vector(1 downto 0);
        DATA_OUT        : out std_logic_vector(15 downto 0);
        DATA_EN         : out std_logic;

        HD_REG_CSn      : in std_logic;
        FDDS            : out std_logic;
        FCCLK           : out std_logic;

        PAD0X_CS        : in std_logic;
        PAD0Y_CS        : in std_logic;
        PAD1X_CS        : in std_logic;
        PAD1Y_CS        : in std_logic;

        PAD0X_INHn      : in std_logic;
        PAD0Y_INHn      : in std_logic;
        PAD1X_INHn      : in std_logic;
        PAD1Y_INHn      : in std_logic;
        PADRSTn         : out std_logic;

        XPEN_REG_CS     : in std_logic; -- Pen register access.
        YPEN_REG_CS     : in std_logic; -- Pen register access.

        HSYNCn          : in std_logic;
        VSYNCn          : in std_logic;
        DE              : in std_logic;

        PENn            : in std_logic -- Light pen input.
    );
end component;
end WF25915IP_PKG;
