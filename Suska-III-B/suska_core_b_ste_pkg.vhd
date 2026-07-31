------------------------------------------------------------------------
----                                                                ----
---- Atari STE compatible IP Core                                   ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- This model provides the top level package  file of an STE      ----
---- compatible machine including CPU, Blitter, Shadow, MCU, DMA,   ----
---- FDC, Shifter, GLUE, MFP, SOUND, ACIA and RTC.                  ----
----                                                                ----
----                                                                ----
----                                                                ----
----                                                                ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2006... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K6B 2006/12/24 WF
--   Initial Release.
-- Revision 2K8A 2008/07/14 WF
--   Changes to run on the Suska hardware platform.
-- Revision 2K9A 2008/06/29 WF
--   Changes due to changes in other modules.
-- Revision 2K15B 20151224 WF
--   Replaced the data type bit by std_logic.
-- Revision 2K23B 20231224
--   Removed the ROMSEL_FC_E0n switch ROM_2n is now valid in both address spaces (UMA).
-- Revision 2K24A 20240620
--   GLUE SCC enhancements.
--

library ieee;
use ieee.std_logic_1164.all;

package SUSKA_CORE_B_STE_PKG is
    component WF68K00IP_TOP_SOC -- CPU.
        port (
            CLK             : in std_logic;
            RESET_COREn     : in std_logic; -- Core reset.
            
            -- Address and data:
            ADR_OUT         : out std_logic_vector(23 downto 1);
            ADR_EN          : out std_logic;
            DATA_IN         : in std_logic_vector(15 downto 0);
            DATA_OUT        : out std_logic_vector(15 downto 0);
            DATA_EN         : out std_logic;

            -- System control:
            BERRn           : in std_logic;
            RESET_INn       : in std_logic;
            RESET_OUT_EN    : out std_logic; -- Open drain.
            HALT_INn        : in std_logic;
            HALT_OUT_EN     : out std_logic; -- Open drain.
            
            -- Processor status:
            FC_OUT          : out std_logic_vector(2 downto 0);
            FC_OUT_EN       : out std_logic;
            
            -- Interrupt control:
            AVECn           : in std_logic;
            IPLn            : in std_logic_vector(2 downto 0);

            -- Aynchronous bus control:
            DTACKn          : in std_logic;
            AS_OUTn         : out std_logic;
            AS_OUT_EN       : out std_logic;
            RWn_OUT         : out std_logic;
            RW_OUT_EN       : out std_logic;
            UDS_OUTn        : out std_logic;
            UDS_OUT_EN      : out std_logic;
            LDS_OUTn        : out std_logic;
            LDS_OUT_EN      : out std_logic;
            
            -- Synchronous peripheral control:
            E               : out std_logic;
            VMA_OUTn        : out std_logic;
            VMA_OUT_EN      : out std_logic;
            VPAn            : in std_logic;
            
            -- Bus arstd_logicration control:
            BRn             : in std_logic;
            BGn             : out std_logic;
            BGACKn          : in std_logic
            );
    end component WF68K00IP_TOP_SOC;

    component WF68K10_TOP
        port (
            CLK             : in std_logic;
            
            -- Address and data:
            ADR_OUT         : out std_logic_vector(31 downto 0);
            DATA_IN         : in std_logic_vector(15 downto 0);
            DATA_OUT        : out std_logic_vector(15 downto 0);
            DATA_EN         : out std_logic; -- Enables the data port.
    
            -- System control:
            BERRn           : in std_logic;
            RESET_INn       : in std_logic;
            RESET_OUT       : out std_logic; -- Open drain.
            HALT_INn        : in std_logic;
            HALT_OUTn       : out std_logic; -- Open drain.
            
            -- Processor status:
            FC_OUT          : out std_logic_vector(2 downto 0);
            
            -- Interrupt control:
            AVECn           : in std_logic;
            IPLn            : in std_logic_vector(2 downto 0);
    
            -- Aynchronous bus control:
            DTACKn          : in std_logic;
            ASn             : out std_logic;
            RWn             : out std_logic;
            RMCn            : out std_logic;
            UDSn            : out std_logic;
            LDSn            : out std_logic;
            DBENn           : out std_logic; -- Data buffer enable.
            BUS_EN          : out std_logic; -- Enables ADR, ASn, UDSn, LDSn, RWn, RMCn and FC.
    
            -- Synchronous peripheral control:
            E               : out std_logic;
            VMAn            : out std_logic;
            VMA_EN          : out std_logic;
            VPAn            : in std_logic;
    
            -- Bus arbitration control:
            BRn             : in std_logic;
            BGn             : out std_logic;
            BGACKn          : in std_logic;
            
            -- Other controls:
            K6800n          : in std_logic -- Assert for 68K00 compatibility.
        );
    end component;

    component WF68K30L_TOP is
        generic(VERSION     : std_logic_vector(31 downto 0) := x"20191224"; -- CPU version number.
            -- The following two switches are for debugging purposes. Default for both is false.
            NO_PIPELINE     : boolean := false;  -- If true the main controller work in scalar mode.
            NO_LOOP         : boolean := false; -- If true the DBcc loop mechanism is disabled.
            NO_BFOPS        : boolean := false); -- No bitfield operations if true. This saves 30% of the CPU resources.
        port (
            CLK             : in std_logic;

            -- Address and data:
            ADR_OUT         : out std_logic_vector(31 downto 0);
            DATA_IN         : in std_logic_vector(31 downto 0);
            DATA_OUT        : out std_logic_vector(31 downto 0);
            DATA_EN         : out std_logic; -- Enables the data port.

            -- System control:
            BERRn           : in std_logic;
            RESET_INn       : in std_logic;
            RESET_OUT       : out std_logic; -- Open drain.
            HALT_INn        : in std_logic;
            HALT_OUTn       : out std_logic; -- Open drain.

            -- Processor status:
            FC_OUT          : out std_logic_vector(2 downto 0);

            -- Interrupt control:
            AVECn           : in std_logic;
            IPLn            : in std_logic_vector(2 downto 0);
            IPENDn          : out std_logic;

            -- Aynchronous bus control:
            DSACKn          : in std_logic_vector(1 downto 0);
            SIZE            : out std_logic_vector(1 downto 0);
            ASn             : out std_logic;
            RWn             : out std_logic;
            RMCn            : out std_logic;
            DSn             : out std_logic;
            ECSn            : out std_logic;
            OCSn            : out std_logic;
            DBENn           : out std_logic; -- Data buffer enable.
            BUS_EN          : out std_logic; -- Enables ADR, ASn, DSn, RWn, RMCn, FC and SIZE.

            -- Synchronous bus control:
            STERMn          : in std_logic;

            -- Status controls:
            STATUSn         : out std_logic;
            REFILLn         : out std_logic;

            -- Bus arbitration control:
            BRn             : in std_logic;
            BGn             : out std_logic;
            BGACKn          : in std_logic
        );
    end component WF68K30L_TOP;

    component WF101643IP_TOP_SOC -- Blitter.
        port (
            -- System controls:
            CLK         : in std_logic;
            RESETn      : in std_logic;
            AS_INn      : in std_logic;
            AS_OUTn     : out std_logic;
            LDS_INn     : in std_logic;
            LDS_OUTn    : out std_logic;
            UDS_INn     : in std_logic;
            UDS_OUTn    : out std_logic;
            RWn_IN      : in std_logic;
            RWn_OUT     : out std_logic;
            DTACK_INn   : in std_logic;
            DTACK_OUTn  : out std_logic;
            BERRn       : in std_logic;
            FC_IN       : in std_logic_vector(2 downto 0);
            FC_OUT      : out std_logic_vector(2 downto 0);
            BUSCTRL_EN  : out std_logic;
            INTn        : out std_logic;

            -- The bus:
            ADR_IN      : in std_logic_vector(31 downto 1);
            ADR_OUT     : out std_logic_vector(31 downto 1);
            ADR_EN      : out std_logic;
            DATA_IN     : in std_logic_vector(15 downto 0);
            DATA_OUT    : out std_logic_vector(15 downto 0);
            DATA_EN     : out std_logic;

            -- Bus arstd_logicration:
            BGIn        : in std_logic;
            BGKIn       : in std_logic;
            BRn         : out std_logic;
            BGACK_INn   : in std_logic;
            BGACK_OUTn  : out std_logic;
            BGOn        : out std_logic
        );
    end component WF101643IP_TOP_SOC;

    component WF25915IP_TOP_SOC -- GLUE.
        port (
            -- Clock system:
            CLK_1    		: in std_logic; -- Originally 8MHz.
            CLK_2    		: in std_logic; -- Originally 16MHz.
            CLK_0M5  		: in std_logic; -- One sixteenth of CLK.
            
            -- Core address select:
            EN_RAM_14MB     : in std_logic;
            EN_ALTRAM       : in std_logic;

            -- Adress decoder outputs:
            ROM_6n   		: out std_logic;    -- STE.
            ROM_5n   		: out std_logic;    -- STE.
            ROM_4n   		: out std_logic;    -- ST.
            ROM_3n   		: out std_logic;    -- ST.
            ROM_2n   		: out std_logic;
            ROM_1n   		: out std_logic;
            ROM_0n   		: out std_logic;
            
            ACIACS   		: out std_logic;
            MFPCSn   		: out std_logic;
            SNDCSn   		: out std_logic;
            FCSn     		: out std_logic;

            STE_SNDCS    	: out std_logic;    -- STE: Sound chip select.
            STE_SNDIR    	: out std_logic;    -- STE: Data flow direction control.

            STE_RTCCSn   	: out std_logic;    --STE only.
            STE_RTC_WRn  	: out std_logic;    --STE only.
            STE_RTC_RDn  	: out std_logic;    --STE only.

            -- 6800 peripheral control, 
            VPAn         	: out std_logic;
            VMAn         	: in std_logic;
            
            DEVn         	: out std_logic;
            RAMn         	: out std_logic;
            EXT_RAMn        : out std_logic;
            DMAn         	: out std_logic;
            
            -- Interrupt system:
            -- Comment out AVECn for CPUs which do not provide the VMAn signal.
            AVECn        	: out std_logic;
            STE_FDINT    	: in std_logic;     -- Floppy disk interrupt; STE only.
            STE_HDINTn   	: in std_logic;     -- Hard disk interrupt; STE only.
            MFPINTn      	: in std_logic;     -- ST.
            STE_EINT3n   	: in std_logic;     --STE only.
            STE_EINT5n   	: in std_logic;     --STE only.
            STE_EINT7n   	: in std_logic;     --STE only.
            STE_DINTn    	: out std_logic;    -- Disk interrupt (floppy or hard disk); STE only.
            IACKn        	: out std_logic;    -- ST.
            STE_IPL2n    	: out std_logic;    --STE only.
            STE_IPL1n    	: out std_logic;    --STE only.
            STE_IPL0n    	: out std_logic;    --STE only.
            
            -- Video timing:
            BLANKn       	: out std_logic;
            DE           	: out std_logic;
            MULTISYNC    	: in std_logic_vector(3 downto 2);
            VIDEO_HIMODE 	: out std_logic;
            HSYNC_INn    	: in std_logic;
            HSYNC_OUTn   	: out std_logic;
            VSYNC_INn    	: in std_logic;
            VSYNC_OUTn   	: out std_logic;
            SYNC_OUT_EN  	: out std_logic;
            
            -- Bus arstd_logicration control:
            RDY_INn      	: in std_logic;
            RDY_OUTn     	: out std_logic;
            BRn          	: out std_logic;
            BGIn         	: in std_logic;
            BGOn         	: out std_logic;
            BGACK_INn    	: in std_logic;
            BGACK_OUTn   	: out std_logic;

            -- Adress and data bus:
            ADDRESS      	: in std_logic_vector(31 downto 1);
            -- ST: put the data bus to 1 downto 0. 
            -- STE: put the data out bus to 15 downto 0. 
            DATA_IN      	: in std_logic_vector(7 downto 0);
            DATA_OUT     	: out std_logic_vector(15 downto 0);
            DATA_EN      	: out std_logic;
            
            -- Asynchronous bus control:
            RWn_IN       	: in std_logic;
            RWn_OUT      	: out std_logic;
            AS_INn       	: in std_logic;
            AS_OUTn      	: out std_logic;
            UDS_INn      	: in std_logic;
            UDS_OUTn     	: out std_logic;
            LDS_INn      	: in std_logic;
            LDS_OUTn     	: out std_logic;
            DTACK_INn    	: in std_logic;
            DTACK_OUTn   	: out std_logic;
            CTRL_EN      	: out std_logic;
            
            -- System control:
            RESETn       	: in std_logic;
            BERRn        	: out std_logic;
            
            -- Processor function codes:
            FC_IN    		: in std_logic_vector(2 downto 0);
            FC_OUT   		: out std_logic_vector(2 downto 0);

            -- STE enhancements:
            STE_FDDS     	: out std_logic;        -- Floppy type select (HD or DD).
            STE_FCCLK    	: out std_logic;        -- Floppy controller clock select.
            STE_JOY_RHn  	: out std_logic;        -- Read only FF9202 high byte.
            STE_JOY_RLn  	: out std_logic;        -- Read only FF9202 low byte.
            STE_JOY_WL   	: out std_logic;        -- Write only FF9202 low byte.
            STE_JOY_WEn  	: out std_logic;        -- Write only FF9202 output enable.
            STE_BUTTONn  	: out std_logic;        -- Read only FF9000 low byte.       
            STE_PAD0Xn   	: in std_logic;         -- Counter input for the Paddle 0X.
            STE_PAD0Yn   	: in std_logic;         -- Counter input for the Paddle 0Y.
            STE_PAD1Xn   	: in std_logic;         -- Counter input for the Paddle 1X.
            STE_PAD1Yn   	: in std_logic;         -- Counter input for the Paddle 1Y.
            STE_PADRSTn  	: out std_logic;        -- Paddle monoflops reset.
            STE_PENn     	: in std_logic;         -- Input of the light pen.
            STE_CPROGn   	: out std_logic; -- Select signal for the STE's cache processor.

            -- SCC chip:
            SCCABn          : out std_logic;
            SCCRDn          : out std_logic;
            SCCWRn          : out std_logic;
            SCCIACKn        : out std_logic;
            SCCWAITn        : in std_logic

            );
    end component WF25915IP_TOP_SOC;

    component WF25912IP_SD_TOP_BTYPE_SOC
        port(  
            CLK             : in std_logic;
            SYS_RESET_INn   : in std_logic;
            SYS_RESET_OUTn  : out std_logic;
            RESET_INn       : in std_logic;
            ASn             : in std_logic;
            LDSn            : in std_logic;
            UDSn            : in std_logic;
            RWn             : in std_logic;
            ADR             : in std_logic_vector(25 downto 1);
            RAMn            : in std_logic;
            DMAn            : in std_logic;
            DEVn            : in std_logic;
            VSYNCn          : in std_logic;
            DE              : in std_logic;
            VIDEO_HIMODE    : in std_logic;
            DCYCn           : out std_logic;
            CMPCSn          : out std_logic;
            MONOCHROME      : in std_logic;
            SREQ            : in std_logic;
            SLOADn          : out std_logic;
            SINT_TAI        : out std_logic;
            SINT_IO7        : out std_logic;
            BA              : out std_logic_vector(1 downto 0);
            MAD             : out std_logic_vector(12 downto 0);
            WEn             : out std_logic;
            DQM0H           : out std_logic;
            DQM0L           : out std_logic;
            RAS0n           : out std_logic;
            CAS0n           : out std_logic;
            RDATn           : out std_logic;
            WDATn           : out std_logic;
            LATCHn          : out std_logic;
            DTACKn          : out std_logic;
            DATA_IN         : in std_logic_vector(7 downto 0);
            DATA_OUT        : out std_logic_vector(7 downto 0);
            DATA_EN         : out std_logic
        );
    end component;

    component WF25913IP_TOP_SOC -- DMA.
        port (
            -- System controls:
            RESETn      : in std_logic; -- Master reset.
            CLK         : in std_logic;     -- Clock system.
            FCSn        : in std_logic; -- Adress select.
            A1          : in std_logic; -- Adress select.
            RWn         : in std_logic; -- Read write control.
            RDY_INn     : in std_logic; -- Data acknowlege control (GLUE-DMA).
            RDY_OUTn    : out std_logic;    -- Data acknowlege control (GLUE-DMA).
            DATA_IN     : in std_logic_vector(15 downto 0); -- System data.
            DATA_OUT    : out std_logic_vector(15 downto 0);    -- System data.
            DATA_EN     : out std_logic;

            -- DMA-Configuration:
            DRIVE_SEL   : out std_logic_vector(1 downto 0);

            -- ACSI section:
            CA2         : out std_logic;    -- ACSI adress.
            CA1         : out std_logic;    -- ACSI adress.
            CA0         : out std_logic;    -- ACSI adress.
            CR_Wn       : out std_logic;    -- ACSI read write control.
            CD_IN       : in std_logic_vector(7 downto 0);  -- ACSI data.
            CD_OUT      : out std_logic_vector(7 downto 0); -- ACSI data.
            CD_EN       : out std_logic;    -- CD data enable.
            FDCSn       : out std_logic;    -- FLOPPY select.
            SDCSn       : out std_logic;  -- SD card select.
            SCSICSn     : out std_logic;  -- SCSI device select.
            HDCSn       : out std_logic;    -- ACSI drive select.
            FDRQ        : in std_logic; -- FLOPPY request.
            HDRQ        : in std_logic; -- ACSI drive request.
            ACKn        : out std_logic; -- ACSI data acknowledge.
            EOPn        : out std_logic -- 5380 end of process.
            );
    end component WF25913IP_TOP_SOC;

    component WF1772IP_TOP_SOC -- FDC.
        port (
            CLK         : in std_logic;
            RESETn      : in std_logic;
            CSn         : in std_logic;
            RWn         : in std_logic;
            A1, A0      : in std_logic;
            DATA_IN     : in std_logic_vector(7 downto 0);
            DATA_OUT    : out std_logic_vector(7 downto 0);
            DATA_EN     : out std_logic;
            RDn         : in std_logic;
            TR00n       : in std_logic;
            IPn         : in std_logic;
            WPRTn       : in std_logic;
            DDEn        : in std_logic;
            HDTYPE      : in std_logic;
            MO          : out std_logic;
            WG          : out std_logic;
            WD          : out std_logic;
            STEP        : out std_logic;
            DIRC        : out std_logic;
            DRQ         : out std_logic;
            INTRQ       : out std_logic
        );
    end component WF1772IP_TOP_SOC;

    component WF_SD_DRIVES
        port(
            RESETn              : in std_logic;
            CLK_16MHz           : in std_logic;
            CLK_32MHz           : in std_logic;

            CD_IN               : in std_logic_vector(7 downto 0);
            CD_OUT              : out std_logic_vector(7 downto 0);
            CD_EN               : out std_logic;
            CR_Wn               : in std_logic;
            CA1                 : in std_logic;

            HDCSn               : in std_logic;
            HDRQ                : out std_logic;
            ACKn                : in std_logic;
            HDINTn              : out std_logic;

            FDD_MO              : in std_logic;
            FDD_WG              : in std_logic;
            FDD_WD              : in std_logic;
            FDD_STEP            : in std_logic;
            FDD_DIRC            : in std_logic;
            FDD_D1SELn          : in std_logic;
            FDD_D0SELn          : in std_logic;
            FDD_SDSEL           : in std_logic;
            FDD_DRIVETYPE       : in std_logic;
            FDD_RDn             : out std_logic;
            FDD_TR00n           : out std_logic;
            FDD_IPn             : out std_logic;
            FDD_WPn             : out std_logic;
            
            JOY_DIS             : out std_logic;
            LED_1               : out std_logic;
            LED_2               : out std_logic;

            DRIVES_BSYn         : out std_logic;
            SDC_MISO            : in std_logic;
            SDC_MOSI            : out std_logic;
            SDC_CSn             : out std_logic;
            SDC_SCK             : out std_logic;
            SDC_CDn             : in std_logic;
            SDC_WP              : in std_logic;
            SDC_PWRn            : out std_logic
        );
    end component WF_SD_DRIVES;

    component WF25914IP_TOP_SOC -- Shifter.
        port (
            CLK             : in std_logic; -- Originally 32MHz in the ST machines.
            RESETn          : in std_logic; -- Master reset.
            SH_A            : in std_logic_vector(6 downto 1); -- Adress bus (without base adress).
            SH_D_IN         : in std_logic_vector(15 downto 0); -- Data bus input.
            SH_D_OUT        : out std_logic_vector(15 downto 0); -- Data bus output.
            SH_DATA_HI_EN   : out std_logic; -- Data output enable for the high byte.
            SH_DATA_LO_EN   : out std_logic; -- Data output enable for the low byte.
            SH_RWn          : in std_logic; -- Write to registers is low active.
            SH_CSn          : in std_logic; -- Base adress of the shifter is 0xFF82xx.

            MULTISYNC       : in std_logic_vector(3 downto 2); -- Select multisync compatible video modi.
            SH_LOADn        : in std_logic; -- Load signal for the shift registers.
            SH_DE           : in std_logic; -- Shift switch for the shift registers.
            SH_BLANKn       : in std_logic; -- Blanking input.
            CR_1512         : out std_logic_vector(3 downto 0); -- Hi nibble of the chroma out.
            SH_R            : out std_logic_vector(3 downto 0); -- Red video output.
            SH_G            : out std_logic_vector(3 downto 0); -- Green video output.
            SH_B            : out std_logic_vector(3 downto 0); -- Blue video output.
            SH_MONO         : out std_logic; -- Monochrome video output.
            SH_CSYNCn       : out std_logic; -- COMP_SYNC signal of the ST.
            
            SH_SCLK         : in std_logic; -- Sample clock, 1.6021226 MHz.
            SH_FCLK         : out std_logic; -- Frame clock.
            SH_SLOADn       : in std_logic; -- DMA load control.
            SH_SREQ         : out std_logic; -- DMA load request.
            SH_SDATA_L      : out std_logic_vector(7 downto 0); -- Left audio data.
            SH_SDATA_R      : out std_logic_vector(7 downto 0); -- Right audio data.

            SH_MWK          : out std_logic; -- Microwire interface, clock.
            SH_MWD          : out std_logic; -- Microwire interface, data.
            SH_MWEn         : out std_logic; -- Microwire interface, enable.
            
            xFF827E_D       : out std_logic_vector(7 downto 0)
        );
    end component WF25914IP_TOP_SOC;

    component WF68901IP_TOP_SOC -- MFP.
        port (  -- System control:
                CLK         : in std_logic;
                RESETn      : in std_logic;
                
                -- Asynchronous bus control:
                DSn         : in std_logic;
                CSn         : in std_logic;
                RWn         : in std_logic;
                DTACKn      : out std_logic;
                
                -- Data and Adresses:
                RS          : in std_logic_vector(5 downto 1);
                DATA_IN     : in std_logic_vector(7 downto 0);
                DATA_OUT    : out std_logic_vector(7 downto 0);
                DATA_EN     : out std_logic;
                GPIP_IN     : in std_logic_vector(7 downto 0);
                GPIP_OUT    : out std_logic_vector(7 downto 0);
                GPIP_EN     : out std_logic_vector(7 downto 0);
                
                -- Interrupt control:
                IACKn       : in std_logic;
                IEIn        : in std_logic;
                IEOn        : out std_logic;
                IRQn        : out std_logic;
                
                -- Timers and timer control:
                XTAL1       : in std_logic; -- Use an oszillator instead of a quartz.
                TAI         : in std_logic;
                TBI         : in std_logic;
                TAO         : out std_logic;            
                TBO         : out std_logic;            
                TCO         : out std_logic;            
                TDO         : out std_logic;            
                
                -- Serial I/O control:
                RC          : in std_logic;
                TC          : in std_logic;
                SI          : in std_logic;
                SO          : out std_logic;
                SO_EN       : out std_logic;
                
                -- DMA control:
                RRn         : out std_logic;
                TRn         : out std_logic         
        );
    end component WF68901IP_TOP_SOC;

    component WF2149IP_DIGOUT_TOP_SOC -- Sound.
        port(
            
            SYS_CLK     : in std_logic; -- Read the inforation in the header!
            RESETn      : in std_logic;

            WAV_CLK     : in std_logic; -- Read the inforation in the header!
            SELn        : in std_logic;
            
            BDIR        : in std_logic;
            BC2, BC1    : in std_logic;

            A9n, A8     : in std_logic;
            DA_IN       : in std_logic_vector(7 downto 0);
            DA_OUT      : out std_logic_vector(7 downto 0);
            DA_EN       : out std_logic;
            
            IO_A_IN     : in std_logic_vector(7 downto 0);
            IO_A_OUT    : out std_logic_vector(7 downto 0);
            IO_A_EN     : out std_logic;
            IO_B_IN     : in std_logic_vector(7 downto 0);
            IO_B_OUT    : out std_logic_vector(7 downto 0);
            IO_B_EN     : out std_logic;

            OUT_ALL     : out std_logic_vector(7 downto 0)
        );
    end component WF2149IP_DIGOUT_TOP_SOC;

    component WF6850IP_TOP_SOC -- ACIA.
      port (
            CLK                 : in std_logic;
            RESETn              : in std_logic;

            CS2n, CS1, CS0      : in std_logic;
            E                   : in std_logic;   
            RWn                 : in std_logic;
            RS                  : in std_logic;

            DATA_IN             : in std_logic_vector(7 downto 0);   
            DATA_OUT            : out std_logic_vector(7 downto 0);   
            DATA_EN             : out std_logic;

            TXCLK               : in std_logic;
            RXCLK               : in std_logic;
            RXDATA              : in std_logic;
            CTSn                : in std_logic;
            DCDn                : in std_logic;
            
            IRQn                : out std_logic;
            TXDATA              : out std_logic;   
            RTSn                : out std_logic
           );                                              
    end component WF6850IP_TOP_SOC;

    component WF5C15_139xIP_TOP -- RP5C15_DS1392 RTC bridge.
        port(
            CLK             : in std_logic;
            RESETn          : in std_logic;

            ADR             : in std_logic_vector(3 downto 0);
            DATA_IN         : in std_logic_vector(3 downto 0);
            DATA_OUT        : out std_logic_vector(3 downto 0);
            DATA_EN         : out std_logic;
            CS, CSn         : in std_logic;
            WRn, RDn        : in std_logic;

            SPI_IN          : in std_logic;
            SPI_OUT         : out std_logic;
            SPI_EN          : out std_logic;
            SPI_SCL         : out std_logic;
            SPI_CE          : out std_logic
            );
    end component WF5C15_139xIP_TOP;

    component WF_AUDIO_DAC
        port (
            CLK             : in std_logic;
            RESETn          : in std_logic;
            FCLK            : in std_logic;
            SDATA_L         : in std_logic_vector(7 downto 0);
            SDATA_R         : in std_logic_vector(7 downto 0);
            DAC_SCLK        : out std_logic;
            DAC_SDATA       : out std_logic;
            DAC_SYNCn       : out std_logic;
            DAC_LDACn       : out std_logic
        );
    end component WF_AUDIO_DAC;

    component WF_FLASHBOOT
        port(
            CLK             : in std_logic;
            PLL_LOCK        : in std_logic;
            RESET_COREn     : in std_logic;
            RESET_INn       : in std_logic;
            RESET_OUTn      : out std_logic;
            VERSION         : in std_logic_vector(31 downto 0);
            ROM_CEn         : in std_logic;
            ADR_OUT         : out std_logic_vector(23 downto 0);
            ADR_EN          : out std_logic;
            DATA_IN         : in std_logic_vector(15 downto 0);
            DATA_OUT        : out std_logic_vector(15 downto 0);
            DATA_EN         : out std_logic;
            FLASH_RDY       : in std_logic;
            FLASH_RESETn    : out std_logic;
            FLASH_WEn       : out std_logic;
            FLASH_OEn       : out std_logic;
            FLASH_CEn       : out std_logic;
			JOY             : out std_logic_vector(7 downto 0);
	        KEY             : out std_logic_vector(15 downto 0);
            RAMADDR			: out std_logic_vector(31 downto 0);
            RAMDATA			: out std_logic_vector(15 downto 0);
            RAMWE           : out std_logic;
            SPI_CLK         : in std_logic;
            SPI_DIN         : in std_logic;
            SPI_DOUT        : out std_logic;
            BOOT_ACK        : in std_logic;
            BOOT_REQ        : out std_logic;
            BOOT_LED        : out std_logic
        );
    end component WF_FLASHBOOT;

    component FLASHBOOT_UMASPI
        port(
            CLK             : in std_logic;
            PLL_LOCK        : in std_logic;
            RESET_COREn     : in std_logic;
            RESET_INn       : in std_logic;
            RESET_OUTn      : out std_logic;
			CORETYPE        : in std_logic_vector(15 downto 0);
            VERSION         : in std_logic_vector(31 downto 0);
            ROM_CEn         : in std_logic;
            ADR_OUT         : out std_logic_vector(23 downto 0);
            ADR_EN          : out std_logic;
            DATA_IN         : in std_logic_vector(15 downto 0);
            DATA_OUT        : out std_logic_vector(15 downto 0);
            DATA_EN         : out std_logic;
            FLASH_RDY       : in std_logic;
            FLASH_RESETn    : out std_logic;
            FLASH_WEn       : out std_logic;
            FLASH_OEn       : out std_logic;
            FLASH_CEn       : out std_logic;
			JOY             : out std_logic_vector(7 downto 0);
	        KEY             : out std_logic_vector(15 downto 0);
            SPI_CLK         : in std_logic;
            SPI_SSn         : in std_logic_vector(2 downto 0);
            SPI_DIN         : in std_logic;
            SPI_DOUT        : out std_logic;
            BOOT_ACK        : in std_logic;
            BOOT_REQ        : out std_logic;
            BOOT_LED        : out std_logic
        );
    end component FLASHBOOT_UMASPI;
end SUSKA_CORE_B_STE_PKG;
