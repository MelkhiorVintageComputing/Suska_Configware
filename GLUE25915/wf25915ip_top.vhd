------------------------------------------------------------------------
----                                                                ----
---- ATARI GLUE compatible IP Core                                  ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Atari's ST Glue with all features to reach                     ----
---- ATARI STE compatibility.                                       ----
----                                                                ----
---- This is the Suska GLUE's IP core top level file.               ----
---- To guarantee proper operation of the DMA interchange between   ----
---- MCU, GLUE, DMA, the 8MHz clock edges must have a small delay   ----
---- (one logic element delay) to the clock edges of the 16MHz      ----
---- clock.                                                         ----
----                                                                ----
---- Important Notice concerning the clock system:                  ----
---- To use this code in a stand alone GLUE chip or in a system     ----
---- on a programmable chip (SOC), the clock frequency may be       ----
---- selected via the CLKSEL setting. Use CLK_8M for the original   ----
---- GLUE frequency (8MHz) or CLK_16M for the 16MHz SOC-GLUE.       ----
---- Affected by the clock selection is the video timing and the    ----
---- paddle counter in the STE enhancements file.                   ----
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
-- Revision History:
--
-- Revision 2K6A  2006/06/03 WF
--   Initial Release.
-- Revision 2K6B    2006/11/05 WF
--   Modified Source to compile with the Xilinx ISE.
-- Revision 2K7A  2007/01/02 WF
--   Changes to the clock system and related
--   hardware as video timing or paddles.
-- Revision 2K8B  2008/12/24 WF
--   Rewritten this top level file as a wrapper for the top_soc file.
--   Introduced EN_RAM_14MB.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
-- Revision 2K20A  20200620 WF
--   Changes in the arbiter to use waitstates instead of SYNC states.
-- Revision 2K21A 20211224 WF
--   GLUE has now 32 bit address bus.
-- Revision 2K23B 20231224
--   Removed the ROMSEL_FC_E0n switch ROM_2n is now valid in both address spaces (UMA).
--

library work;
use work.wf25915ip_pkg.all;
library ieee;
use ieee.std_logic_1164.all;

entity WF25915IP_TOP is
    -- TOS operating system configuration:
    -- TOS_CONFIG = 0 for TOS 2.05 or higher in STE machines.
    -- TOS_CONFIG = 1 for TOS 1.62 or lower in ST machines.
    -- TOS_CONFIG = 2 for TOS 2.05 or higher (patched version in 6 512kB EPROMS) in ST machines.
        -- Explanation for the patched mode: the TOS 2.05 or 2.06 is installed on older ST machines
        -- in four 512 Mbit EPROMS. Additionally there is a part of the older TOS 1.62 or lower in
        -- two 512 Mbit EPROMS. It is patched. To get the machine working, it is necessary to control
        -- the DTACKn in a way, that it is asserted in the old TOS RAM space and in the new one. This
        -- behavior is controlled via the PATCHn. For further information, the TOS adaption is
        -- described in detail in c't 1992 Heft1; "Das zweite Gesicht" and in c't 1993 Heft 1
        -- "Teile und rueste auf".
    -- TOS_CONFIG = 3 or higher: reserved do not select this choices; all chip selects disabled.
    generic (TOS_CONFIG : integer range 0 to 7 := 0;
             CLKSEL     : CLKSEL_TYPE := CLK_8M);
    port (
        -- Clock system:
        GL_CLK          : in std_logic;
        GL_CLK_2M       : out std_logic;
        GL_CLK_0M5      : out std_logic;

        -- Adress decoder outputs:
        GL_ROM_6n       : out std_logic;    -- STE.
        GL_ROM_5n       : out std_logic;    -- STE.
        GL_ROM_4n       : out std_logic;    -- ST.
        GL_ROM_3n       : out std_logic;    -- ST.
        GL_ROM_2n       : out std_logic;
        GL_ROM_1n       : out std_logic;
        GL_ROM_0n       : out std_logic;

        GL_ACIACS       : out std_logic;
        GL_MFPCSn       : out std_logic;
        GL_SNDCSn       : out std_logic;
        GL_FCSn         : out std_logic;

        GL_STE_SNDCS    : out std_logic;    -- STE: Sound chip select.
        GL_STE_SNDIR    : out std_logic;    -- STE: Data flow direction control.

        GL_STE_RTCCSn   : out std_logic;    --STE only.
        GL_STE_RTC_WRn  : out std_logic;    --STE only.
        GL_STE_RTC_RDn  : out std_logic;    --STE only.

        -- 6800 peripheral control,
        GL_VPAn         : out std_logic; -- Open drain.
        GL_VMAn         : in std_logic;

        GL_DEVn         : out std_logic;
        GL_RAMn         : out std_logic;
        GL_DMAn         : out std_logic;

        -- Interrupt system:
        -- Comment out GL_AVECn for CPUs which do not provide the VMAn signal.
        GL_AVECn        : out std_logic;
        GL_STE_FDINT    : in std_logic;     -- Floppy disk interrupt; STE only.
        GL_STE_HDINTn   : in std_logic;     -- Hard disk interrupt; STE only.
        GL_MFPINTn      : in std_logic;     -- ST.
        GL_STE_EINT3n   : in std_logic;     --STE only.
        GL_STE_EINT5n   : in std_logic;     --STE only.
        GL_STE_EINT7n   : in std_logic;     --STE only.
        GL_STE_DINTn    : out std_logic;    -- Disk interrupt (floppy or hard disk); STE only.
        GL_IACKn        : out std_logic;    -- ST.
        GL_STE_IPL2n    : out std_logic;    --STE only.
        GL_STE_IPL1n    : out std_logic;    --STE only.
        GL_STE_IPL0n    : out std_logic;    --STE only.

        -- Video timing:
        GL_BLANKn       : out std_logic;
        GL_DE           : out std_logic;
        GL_HSYNCn       : inout std_logic;
        GL_VSYNCn       : inout std_logic;

        -- Bus arbitration control:
        GL_RDYn         : inout std_logic;
        GL_BRn          : out std_logic;
        GL_BGIn         : in std_logic;
        GL_BGOn         : out std_logic;
        GL_BGACKn       : inout std_logic; -- Open drain.

        -- Adress and data bus:
        GL_ADDRESS      : in std_logic_vector(31 downto 1);
        -- ST: put the data bus to 1 downto 0.
        -- STE: put the data bus to 15 downto 0.
        GL_DATA         : inout std_logic_vector(15 downto 0);

        -- Asynchronous bus control:
        GL_RWn          : inout std_logic;
        GL_ASn          : inout std_logic;
        GL_UDSn         : inout std_logic;
        GL_LDSn         : inout std_logic;
        GL_DTACKn       : inout std_logic; -- Open drain.

        -- System control:
        GL_RESETn       : in std_logic;
        GL_BERRn        : out std_logic; -- Open drain.

        -- Processor function codes:
        GL_FC           : inout std_logic_vector(2 downto 0);

        -- STE enhancements:
        GL_STE_FDDS     : out std_logic;        -- Floppy type select (HD or DD).
        GL_STE_FCCLK    : out std_logic;        -- Floppy controller clock select.
        GL_STE_JOY_RHn  : out std_logic;        -- Read only FF9202 high byte.
        GL_STE_JOY_RLn  : out std_logic;        -- Read only FF9202 low byte.
        GL_STE_JOY_WL   : out std_logic;        -- Write only FF9202 low byte.
        GL_STE_JOY_WEn  : out std_logic;        -- Write only FF9202 output enable.
        GL_STE_BUTTONn  : out std_logic;        -- Read only FF9000 low byte.
        GL_STE_PAD0Xn   : in std_logic;         -- Counter input for the Paddle 0X.
        GL_STE_PAD0Yn   : in std_logic;         -- Counter input for the Paddle 0Y.
        GL_STE_PAD1Xn   : in std_logic;         -- Counter input for the Paddle 1X.
        GL_STE_PAD1Yn   : in std_logic;         -- Counter input for the Paddle 1Y.
        GL_STE_PADRSTn  : out std_logic;        -- Paddle monoflops reset.
        GL_STE_PENn     : in std_logic;         -- Input of the light pen.
        GL_STE_SCCn     : out std_logic;        -- Select signal for the STE or TT SCC chip.
        GL_STE_CPROGn   : out std_logic     -- Select signal for the STE's cache processor.
        );
end entity WF25915IP_TOP;

architecture STRUCTURE of WF25915IP_TOP is
component WF25915IP_CLOCKS
port (
  CLK_x1    : in std_logic;
  CLK_x1_4  : out std_logic;
  CLK_x1_16 : out std_logic
);
end component;

component WF25915IP_TOP_V1_SOC
    generic (TOS_CONFIG : integer range 0 to 7 := 0;
             CLKSEL     : CLKSEL_TYPE := CLK_8M);
    port (
        CLK                 : in std_logic;
        CLK_016             : in std_logic;
        ROM_6n              : out std_logic;
        ROM_5n              : out std_logic;
        ROM_4n              : out std_logic;
        ROM_3n              : out std_logic;
        ROM_2n              : out std_logic;
        ROM_1n              : out std_logic;
        ROM_0n              : out std_logic;
        EN_RAM_14MB         : in std_logic;
        ACIACS              : out std_logic;
        MFPCSn              : out std_logic;
        SNDCSn              : out std_logic;
        FCSn                : out std_logic;
        STE_SNDCS           : out std_logic;
        STE_SNDIR           : out std_logic;
        STE_RTCCSn          : out std_logic;
        STE_RTC_WRn         : out std_logic;
        STE_RTC_RDn         : out std_logic;
        VPAn                : out std_logic;
        VMAn                : in std_logic;
        DEVn                : out std_logic;
        RAMn                : out std_logic;
        DMAn                : out std_logic;
        AVECn               : out std_logic;
        STE_FDINT           : in std_logic;
        STE_HDINTn          : in std_logic;
        MFPINTn             : in std_logic;
        STE_EINT3n          : in std_logic;
        STE_EINT5n          : in std_logic;
        STE_EINT7n          : in std_logic;
        STE_DINTn           : out std_logic;
        IACKn               : out std_logic;
        STE_IPL2n           : out std_logic;
        STE_IPL1n           : out std_logic;
        STE_IPL0n           : out std_logic;
        BLANKn              : out std_logic;
        MULTISYNC           : in std_logic_vector(1 downto 0);
        VIDEO_HIMODE        : out std_logic;
        DE                  : out std_logic;
        HSYNC_INn           : in std_logic;
        HSYNC_OUTn          : out std_logic;
        VSYNC_INn           : in std_logic;
        VSYNC_OUTn          : out std_logic;
        SYNC_OUT_EN         : out std_logic;
        RDY_INn             : in std_logic;
        RDY_OUTn            : out std_logic;
        BRn                 : out std_logic;
        BGIn                : in std_logic;
        BGOn                : out std_logic;
        BGACK_INn           : in std_logic;
        BGACK_OUTn          : out std_logic;
        ADDRESS             : in std_logic_vector(31 downto 1);
        DATA_IN             : in std_logic_vector(7 downto 0);
        DATA_OUT            : out std_logic_vector(15 downto 0);
        DATA_EN             : out std_logic;
        RWn_IN              : in std_logic;
        RWn_OUT             : out std_logic;
        AS_INn              : in std_logic;
        AS_OUTn             : out std_logic;
        UDS_INn             : in std_logic;
        UDS_OUTn            : out std_logic;
        LDS_INn             : in std_logic;
        LDS_OUTn            : out std_logic;
        DTACK_INn           : in std_logic;
        DTACK_OUTn          : out std_logic;
        CTRL_EN             : out std_logic;
        RESETn              : in std_logic;
        BERRn               : out std_logic;
        FC_IN               : in std_logic_vector(2 downto 0);
        FC_OUT              : out std_logic_vector(2 downto 0);
        STE_FDDS            : out std_logic;
        STE_FCCLK           : out std_logic;
        STE_JOY_RHn         : out std_logic;
        STE_JOY_RLn         : out std_logic;
        STE_JOY_WL          : out std_logic;
        STE_JOY_WEn         : out std_logic;
        STE_BUTTONn         : out std_logic;
        STE_PAD0Xn          : in std_logic;
        STE_PAD0Yn          : in std_logic;
        STE_PAD1Xn          : in std_logic;
        STE_PAD1Yn          : in std_logic;
        STE_PADRSTn         : out std_logic;
        STE_PENn            : in std_logic;
        STE_SCCn            : out std_logic;
        STE_CPROGn          : out std_logic;
        STE_A4299_CS        : out std_logic
        );
end component;
--
signal CLK_x1           : std_logic;
signal CLK_x1_4         : std_logic;
signal CLK_x1_16        : std_logic;
signal DATA_OUT         : std_logic_vector(15 downto 0);
signal DATA_EN          : std_logic;
signal BGACK_OUTn       : std_logic;
signal VPA_In           : std_logic;
signal FC_OUT        	: std_logic_vector(2 downto 0);
signal CTRL_EN       	: std_logic;
signal AS_OUTn          : std_logic;
signal RWn_OUT          : std_logic;
signal LDS_OUTn         : std_logic;
signal UDS_OUTn         : std_logic;
signal HSYNC_OUTn       : std_logic;
signal VSYNC_OUTn       : std_logic;
signal SYNC_OUT_EN      : std_logic;
signal RDY_OUTn         : std_logic;
signal DTACK_OUTn       : std_logic;
signal BERR_In          : std_logic;
begin
    GL_CLK_2M <= CLK_x1_4;
    GL_CLK_0M5 <= CLK_x1_16;

    GL_DATA <= DATA_OUT when DATA_EN = '1' else (others => 'Z');

    GL_ASn <= AS_OUTn when CTRL_EN = '1' else'Z';
    GL_RWn <= RWn_OUT when CTRL_EN = '1' else'Z';
    GL_UDSn <= UDS_OUTn when CTRL_EN = '1' else'Z';
    GL_LDSn <= LDS_OUTn when CTRL_EN = '1' else'Z';

    GL_BGACKn <= '0' when BGACK_OUTn = '0' else 'Z';
    GL_VPAn <= '0' when VPA_In = '0' else 'Z';

    GL_HSYNCn <= HSYNC_OUTn when SYNC_OUT_EN = '1' else'Z';
    GL_VSYNCn <= VSYNC_OUTn when SYNC_OUT_EN = '1' else'Z';

    GL_RDYn <= '0' when RDY_OUTn = '0' else 'Z';
    GL_DTACKn <= '0' when DTACK_OUTn = '0' else 'Z';

    GL_BERRn <= '0' when BERR_In = '0' else 'Z'; -- Open drain.
--GL_BRn                    => BRn,

    GL_FC <= FC_OUT when CTRL_EN = '1' else (others => 'Z');

    I_GLUECLOCKS: WF25915IP_CLOCKS
    port map(CLK_x1         => GL_CLK,
             CLK_x1_4       => CLK_x1_4,
             CLK_x1_16      => CLK_x1_16
    );

    I_GLUE: WF25915IP_TOP_SOC
        port map(CLK                 	=> GL_CLK,
                 CLK_016             	=> CLK_x1_16,
                 ROM_6n              	=> GL_ROM_6n,
                 ROM_5n              	=> GL_ROM_5n,
                 ROM_4n              	=> GL_ROM_4n,
                 ROM_3n              	=> GL_ROM_3n,
                 ROM_2n              	=> GL_ROM_2n,
                 ROM_1n              	=> GL_ROM_1n,
                 ROM_0n              	=> GL_ROM_0n,
                 EN_RAM_14MB            => '0', -- Set to 4MB RAM address space.
                 ACIACS              	=> GL_ACIACS,
                 MFPCSn              	=> GL_MFPCSn,
                 SNDCSn              	=> GL_SNDCSn,
                 FCSn                	=> GL_FCSn,
                 STE_SNDCS           	=> GL_STE_SNDCS,
                 STE_SNDIR           	=> GL_STE_SNDIR,
                 STE_RTCCSn          	=> GL_STE_RTCCSn,
                 STE_RTC_WRn         	=> GL_STE_RTC_WRn,
                 STE_RTC_RDn         	=> GL_STE_RTC_RDn,
                 VPAn                	=> VPA_In,
                 VMAn                	=> GL_VMAn,
                 DEVn                	=> GL_DEVn,
                 RAMn                	=> GL_RAMn,
                 DMAn                	=> GL_DMAn,
                 AVECn               	=> GL_AVECn,
                 STE_FDINT           	=> GL_STE_FDINT,
                 STE_HDINTn          	=> GL_STE_HDINTn,
                 MFPINTn             	=> GL_MFPINTn,
                 STE_EINT3n          	=> GL_STE_EINT3n,
                 STE_EINT5n          	=> GL_STE_EINT5n,
                 STE_EINT7n          	=> GL_STE_EINT7n,
                 STE_DINTn           	=> GL_STE_DINTn,
                 IACKn               	=> GL_IACKn,
                 STE_IPL2n           	=> GL_STE_IPL2n,
                 STE_IPL1n           	=> GL_STE_IPL1n,
                 STE_IPL0n           	=> GL_STE_IPL0n,
                 BLANKn              	=> GL_BLANKn,
                 MULTISYNC           	=> "00",
                 --VIDEO_HIMODE      	=> ,
                 DE                  	=> GL_DE,
                 HSYNC_INn           	=> GL_HSYNCn,
                 HSYNC_OUTn          	=> HSYNC_OUTn,
                 VSYNC_INn           	=> GL_VSYNCn,
                 VSYNC_OUTn          	=> VSYNC_OUTn,
                 SYNC_OUT_EN         	=> SYNC_OUT_EN,
                 RDY_INn             	=> GL_RDYn,
                 RDY_OUTn            	=> RDY_OUTn,
                 BRn                 	=> GL_BRn,
                 BGIn                	=> GL_BGIn,
                 BGOn                	=> GL_BGOn,
                 BGACK_INn           	=> GL_BGACKn,
                 BGACK_OUTn          	=> BGACK_OUTn,
                 ADDRESS             	=> GL_ADDRESS,
                 DATA_IN             	=> GL_DATA(7 downto 0),
                 DATA_OUT            	=> DATA_OUT,
                 DATA_EN             	=> DATA_EN,
                 RWn_IN              	=> GL_RWn,
                 RWn_OUT             	=> RWn_OUT,
                 AS_INn              	=> GL_ASn,
                 AS_OUTn             	=> AS_OUTn,
                 UDS_INn             	=> GL_UDSn,
                 UDS_OUTn            	=> UDS_OUTn,
                 LDS_INn             	=> GL_LDSn,
                 LDS_OUTn            	=> LDS_OUTn,
                 DTACK_INn           	=> GL_DTACKn,
                 DTACK_OUTn          	=> DTACK_OUTn,
                 CTRL_EN             	=> CTRL_EN,
                 RESETn              	=> GL_RESETn,
                 BERRn               	=> BERR_In,
                 FC_IN               	=> GL_FC,
                 FC_OUT              	=> FC_OUT,
                 STE_FDDS            	=> GL_STE_FDDS,
                 STE_FCCLK           	=> GL_STE_FCCLK,
                 STE_JOY_RHn         	=> GL_STE_JOY_RHn,
                 STE_JOY_RLn         	=> GL_STE_JOY_RLn,
                 STE_JOY_WL          	=> GL_STE_JOY_WL,
                 STE_JOY_WEn         	=> GL_STE_JOY_WEn,
                 STE_BUTTONn         	=> GL_STE_BUTTONn,
                 STE_PAD0Xn          	=> GL_STE_PAD0Xn,
                 STE_PAD0Yn          	=> GL_STE_PAD0Yn,
                 STE_PAD1Xn          	=> GL_STE_PAD1Xn,
                 STE_PAD1Yn          	=> GL_STE_PAD1Yn,
                 STE_PADRSTn         	=> GL_STE_PADRSTn,
                 STE_PENn            	=> GL_STE_PENn,
                 STE_SCCn            	=> GL_STE_SCCn,
                 STE_CPROGn          	=> GL_STE_CPROGn
                 --STE_A4299_CS        	=>
            );
end STRUCTURE;