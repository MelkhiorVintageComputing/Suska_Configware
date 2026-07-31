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
---- Copyright © 2021... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K21A 20211224 WF
--   Initial release.
--

library ieee;
use ieee.std_logic_1164.all;

package SUSKA_CORE_C_FALCON_PKG is

    type RAMWIDTH_TYPE is(L32, W16, B8);

    component WF68K30L_TOP
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

    component COMBEL_TOP -- Combel chip.
        generic(RAM_16              : boolean); -- Set true, if we have a 16 bit RAM data bus, false for 32 bit.
        port (
            -- System and core control:
            SYS_RESET_INn           : in std_logic;
            SYS_RESET_OUTn          : out std_logic;
            RESET                   : in std_logic;
            CLK_32                  : in std_logic; -- Originally 32MHz.
            CLK_16                  : in std_logic;
            CLK_CPU                 : out std_logic;
            CLK_8                   : out std_logic;
            CLK_4                   : out std_logic;
            KHz_500                 : out std_logic; -- Clock for the MIDI ACIA and the keyboard ACIA (receiver).
            KHz_500W                : out std_logic; -- Clock for the transmitter of the keyboard ACIA.

            -- Adress and data bus:
            ADR_IN                  : in std_logic_vector(31 downto 0);
            ADR_OUT                 : out std_logic_vector(31 downto 1);
            ADR_EN                  : out std_logic; -- Used for the Blitter.

            DATA_IN                 : in std_logic_vector(15 downto 0);
            DATA_OUT                : out std_logic_vector(15 downto 0);
            DATA_EN                 : out std_logic;

            -- The RAM interface:
            RAM_CKE                 : out std_logic; -- RAM clock enable.
            RAM_CSn                 : out std_logic; -- RAM chip enable.
            RAM_BA                  : out std_logic_vector(1 downto 0); -- SD-RAM bank select.
            RAM_ADR                 : out std_logic_vector(12 downto 0); -- SD-RAM address bus.
            RAM_ADR_32              : out std_logic_vector(31 downto 2); -- 32 bit linear RAM address (LONG32).
            RAM_WEn                 : out std_logic;
            RAM_RASn                : out std_logic; -- This is for 512Mb chips.
            RAM_CASn                : out std_logic; -- This is for 512Mb chips.
            RAM_RAS0n               : out std_logic; -- This is for 256Mb chips.
            RAM_CAS0n               : out std_logic; -- This is for 256Mb chips.
            RAM_RAS1n               : out std_logic; -- This is for 256Mb chips.
            RAM_CAS1n               : out std_logic; -- This is for 256Mb chips.
            BUS_WIDTH               : in RAMWIDTH_TYPE; -- Select RAM bus width in K30 mode.
            RAM_DQMn                : out std_logic_vector(3 downto 0); -- SD-RAM output buffer controls.
            SIZE_MCU                : in std_logic_vector(1 downto 0); -- Data size control.

            -- Bus control:
            RWn_IN                  : in std_logic;
            ASn_OUT                 : out std_logic;
            ASn_IN                  : in std_logic;
            RWn_OUT                 : out std_logic;
            UDSn_IN                 : in std_logic;
            UDSn_OUT                : out std_logic;
            LDSn_IN                 : in std_logic;
            LDSn_OUT                : out std_logic;

            RAMn                    : out std_logic; -- Additional signal to handle the 32 bit wide RAM.
            RAMH                    : out std_logic; -- VIDEL's data latch control.

            DTACK_INn               : in std_logic;
            DTACK_OUTn              : out std_logic;

            -- 6800 peripheral control:
            VPAn                    : out std_logic;
            VMAn                    : in std_logic;

            -- Bus status:
            BERRn                   : out std_logic;

            -- Processor function codes:
            FC_IN                   : in std_logic_vector(2 downto 0);
            FC_OUT                  : out std_logic_vector(2 downto 0);

            BUS_EN                  : out std_logic;

            -- Bus arbitration control:
            BRn                     : out std_logic;
            BGIn                    : in std_logic;
            BGOn                    : out std_logic;
            BGAn                    : out std_logic;

            -- Adress decoder stuff:
            -- In original COMBEL ther are only
            -- Pins for ROM2n, ROM3n and ROM4n.
            ROM_6n                  : out std_logic;  -- STE.
            ROM_5n                  : out std_logic;  -- STE.
            ROM_4n                  : out std_logic;  -- ST.
            ROM_3n                  : out std_logic;  -- ST.
            ROM_2n                  : out std_logic;
            ROM_1n                  : out std_logic;
            ROM_0n                  : out std_logic;

            N6850                   : out std_logic;
            MFPCSn                  : out std_logic;

            SNDCS                   : out std_logic; -- STE: Sound chip select.
            SNDIR                   : out std_logic; -- STE: Data flow direction control.
            FPUCS                   : out std_logic; -- Floating point unit
            R8006n                  : out std_logic; -- Falcon's configuration register.

            -- Keyboard stuff:
            TOK                     : in std_logic; -- 'Transmit Ok', to KROK of the Keyboard connector.
            TID                     : in std_logic; -- To TXD of the keyboard ACIA, not used yet.

            -- VIDEL control signals:
            VREQ                    : in std_logic; -- Video data request.
            EVENn_ODD               : in std_logic; -- Indicates the interlaced video frame.
            VCS                     : out std_logic; -- VIDEL chip select.
            VLDn                    : out std_logic; -- Shifter load signal.
            RDATn                   : out std_logic; -- VIDEL's data latch control.
            WDATn                   : out std_logic; -- VIDEL's data latch control.

            -- Bus control signal:
            BMODE                   : in std_logic; -- '0' = 68030 bus timing '1' = 68000 bus timing.

            -- DS1287 real time clock:
            RTCCS                   : out std_logic; -- Real time clock chip select.
            RTCAS                   : out std_logic; -- Address strobe.
            RTCDS                   : out std_logic; -- Data strobe.
            RTC_ACK                 : in std_logic; -- Set to '1' if not used.

            -- RP5C15 real time clock:
            RP5C15_CSn              : out std_logic; -- RP5C15 clock chip control.
            RP5C15_WRn              : out std_logic; -- RP5C15 clock chip control.
            RP5C15_RDn              : out std_logic; -- RP5C15 clock chip control.

            -- Interrupt system:
            HINT                    : in std_logic; -- Horizontal interrupt.
            VINT                    : in std_logic; -- Vertical Interrupt.
            MFPINTn                 : in std_logic;
            EINT1                   : in std_logic;
            EINT3                   : in std_logic;
            EINT5n                  : in std_logic;
            EINT7n                  : in std_logic;
            BINTn                   : out std_logic; -- Blitter.
            AVECn                   : out std_logic; -- Add-On over COMBEL.
            IACKn                   : out std_logic; -- ST.
            IPLn                    : out std_logic_vector(2 downto 0); -- STE only.

            -- IDE interface:
            IDE_RS0n                : out std_logic;
            IDE_RS1n                : out std_logic;
            IDE_IORDn               : out std_logic;
            IDE_IOWRn               : out std_logic;
            IDE_BYTESWAP            : out std_logic;
            IDE_D_EN_INn            : out std_logic; -- In-Buffer control, Add-On over COMBEL.
            IDE_D_EN_OUTn           : out std_logic; -- Out-Buffer control, Add-On over COMBEL.

            -- SCC chip:
            SCCABn                  : out std_logic;
            SCCRDn                  : out std_logic;
            SCCWRn                  : out std_logic;
            SCCIACKn                : out std_logic;
            SCCWAITn                : in std_logic;

            -- Joyport:
            JOY_RHn                 : out std_logic;      -- Read only FF9202 high byte.
            JOY_RLn                 : out std_logic;      -- Read only FF9202 low byte.
            JOY_WL                  : out std_logic;      -- Write only FF9202 low byte.
            JOY_WEn                 : out std_logic;      -- Write only FF9202 output enable.
            BUTTONn                 : out std_logic;      -- Read only FF9000 low byte.
            PAD0Xn                  : in std_logic;       -- Counter input for the Paddle 0X.
            PAD0Yn                  : in std_logic;       -- Counter input for the Paddle 0Y.
            PAD1Xn                  : in std_logic;       -- Counter input for the Paddle 1X.
            PAD1Yn                  : in std_logic;       -- Counter input for the Paddle 1Y.
            PADRSTn                 : out std_logic;      -- Paddle monoflops reset.

            -- Enhancements:
            USB1160_CSn             : out std_logic -- ISP1160 compatible core.
    );
    end component COMBEL_TOP;

    component FDMA_TOP_SOC
        generic(
            ACSI_FIFO_DEPTH         : integer := 32; -- Number of registers.
            REPLAY_FIFO_DEPTH       : integer := 32; -- Number of registers.
            CAPTURE_FIFO_DEPTH      : integer := 32 -- Number of registers.
        );
        port(
            RESET                   : in std_logic;

            -- Clock system:
            CLK_32M0                : in std_logic; -- 32MHz.
            CLK_16M0               : in std_logic; -- This is the BCLK.
            --CLK_32O               : out std_logic; -- 32MHz. Not used nor modeled.
            --CLK_8                 : out std_logic; -- 8MHz. Not used nor modeled.
            --CLK_2                 : out std_logic; -- 2MHz. Not used nor modeled.
            SNCLK                   : in std_logic; -- 25.175MHz.
            CLK_EXT                 : in std_logic; -- External clock.

            -- Adress and data bus:
            FC_IN                   : in std_logic_vector(2 downto 0);
            FC_OUT                  : out std_logic_vector(2 downto 0);
            ADR_IN                  : in std_logic_vector(31 downto 1);
            ADR_OUT                 : out std_logic_vector(31 downto 1);
            ADR_EN                  : out std_logic;
            DATA_IN                 : in std_logic_vector(15 downto 0);
            DATA_OUT                : out std_logic_vector(15 downto 0);
            DATA_EN                 : out std_logic;

            -- Bus control signals:
            BMODE                   : in std_logic; -- '0' = 68030 bus master, '1' = 68000 bus master.
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

            -- Bus arstd_logicration signals:
            BRn                     : out std_logic;
            BGIn                    : in std_logic;
            BGOn                    : out std_logic;
            BGAn                    : out std_logic;
            BERRn                   : in std_logic;

            -- ACSI bus:
            CA                      : out std_logic_vector(2 downto 0); -- ACSI adress.
            CR_Wn                   : out std_logic; -- ACSI/SCSI read write control.
            CRn_W                   : out std_logic; -- ACSI/SCSI read write control.
            CD_IN                   : in std_logic_vector(7 downto 0); -- ACSI data.
            CD_OUT                  : out std_logic_vector(7 downto 0); -- ACSI data.
            CD_EN                   : out std_logic;  -- CD data enable.

            DRIVE_SEL               : out std_logic_vector(1 downto 0); -- Drive selection during register access and DMA.
            FDCSn                   : out std_logic; -- FLOPPY select.
            HDCSn                   : out std_logic; -- ACSI drive select.
            SCSICSn                 : out std_logic; -- SCSI drive select.
            SDCSn                   : out std_logic; -- SDcard drive select.
            FDRQ                    : in std_logic; -- FLOPPY request.
            HDRQ                    : in std_logic;  -- ACSI drive request.
            ACKn                    : out std_logic; -- ACSI data acknowledge.

            -- Floppy disk drive configuration:
            MDET                    : in std_logic_vector(1 downto 0);
            DISKCHNG                : in std_logic;
            MODE                    : out std_logic_vector(1 downto 0);
            FCCLK                   : out std_logic; -- Floppy controller clock.

            -- External serial output channel:
            PLYDATA                 : out std_logic;
            PLYCLK                  : out std_logic;
            PLYSYNC_IN              : in std_logic; -- Gated clock mode.
            PLYSYNC_OUT             : out std_logic; -- Continuous clock mode.
            PLYSYNC_EN              : out std_logic; -- Continuous clock mode.

            -- External serial input channel:
            RECDATA                 : in std_logic;
            RECCLK                  : out std_logic;
            RECSYNC_IN              : in std_logic; -- Gated clock mode.
            RECSYNC_OUT             : out std_logic; -- Continuous clock mode.
            RECSYNC_EN              : out std_logic; -- Continuous clock mode.

            -- DSP connector:
            DSP_SRD                 : out std_logic; -- DSP receives data.
            DSP_SCK                 : out std_logic; -- Transmit clockout.
            DSP_STD                 : in std_logic; -- DSP transmits data.
            DSP_PLY_EN              : out std_logic; -- Tristate control.
            DSP_REC_EN              : out std_logic; -- Tristate control.
            DSP_SC0                 : out std_logic; -- Receive clockout.
            DSP_SC1_IN              : in std_logic; -- Receive syncout.
            DSP_SC1_OUT             : out std_logic; -- Receive syncout.
            DSP_SC2_IN              : in std_logic; -- Transmit syncout.
            DSP_SC2_OUT             : out std_logic; -- Transmit syncout.

            -- Falcon audio codec:
            SCLOCK                  : out std_logic;
            ASCLK                   : out std_logic;
            ASSYNC                  : out std_logic;
            ASDOUT                  : in std_logic; -- Sampled on the rising edge of ASCLK.
            ASDIN                   : out std_logic; -- Sampled on the falling edge of ASCLK.

            -- Interrupt signals:
            SCNT                    : out std_logic; -- Timer A interrupt of the multi function port (MFP).
            SINT                    : out std_logic; -- IO7 interrupt of the multi function port (MFP).
            HDINTn                  : in std_logic;
            FDINT                   : in std_logic;
            DSKIRQn                 : out std_logic; -- Open collector with weak pull up?

            -- Microwire Interface:
            GPIO_IN                 : in std_logic_vector(2 downto 0);
            GPIO_OUT                : out std_logic_vector(2 downto 0);
            GPIO_EN                 : out std_logic_vector(2 downto 0);
            UWC                     : out std_logic;
            UWD                     : out std_logic;
            UWEn                    : out std_logic
        );
    end component FDMA_TOP_SOC;

    component WF_SHD101775IP_TOP_SOC -- Shadow.
        port (
            RESETn      : in std_logic;
            CLK         : in std_logic; -- 16MHz, same as MCU clock.

            -- Video control:
            M_DATA      : in std_logic_vector(15 downto 0); -- Data of the shared system RAM.
            SEL_640x400 : in std_logic; -- Select either 640x400 or 640x480.
            DE          : in std_logic; -- Video Data enable.
            LOADn       : in std_logic; -- Video data load control.

            -- VIDEO RAM:
            -- The core is written for use of a KM681000 SRAM.
            -- If smaller ones are used, do not connect A16,
            -- A15 and if not necessary CS and CSn.
            R_ADR       : out std_logic_vector(14 downto 0);
            R_DATA_IN   : in std_logic_vector(7 downto 0);
            R_DATA_OUT  : out std_logic_vector(7 downto 0);
            R_DATA_EN   : out std_logic;
            R_WRn       : out std_logic;

            -- LCD control:
            UDATA       : out std_logic_vector(3 downto 0);
            LDATA       : out std_logic_vector(3 downto 0);
            LFS         : out std_logic; -- Line frame strobe.
            VDCLK       : out std_logic; -- Video data clock.
            LLCLK       : out std_logic -- Line latch clock.
        );
    end component WF_SHD101775IP_TOP_SOC;

    component VIDEL_TOP
        generic(RAM_16              : boolean); -- Set true, if we have a 16 bit RAM data bus, false for 32 bit.
        port (
            -- System and core control:
            RESET                   : in std_logic;
            CLK_32M0                : in std_logic;  -- Originally 32.000MHz.
            CLK_25M175              : in std_logic;  -- Originally 25.175MHz.
            CLK_EXT                 : in std_logic;  -- External clock (GENLOCK).

            -- System bus:
            ADR                     : in std_logic_vector(11 downto 1);
            DATA_IN                 : in std_logic_vector(31 downto 0);
            DATA_OUT                : out std_logic_vector(31 downto 0);
            DATA_EN                 : out std_logic;
            VCS                     : in std_logic; -- Videl chip select.
            VLDn                    : in std_logic; -- Shifter load signal.
            VREQ                    : out std_logic; -- Video data request.
            RWn                     : in std_logic;

            -- Memory bus:
            RDATn                   : in std_logic;
            WDATn                   : in std_logic;
            RAMH                    : in std_logic; -- VIDEL data lacht control signal.

            MD_IN                   : in std_logic_vector(31 downto 0);
            MD_OUT                  : out std_logic_vector(31 downto 0);
            MD_EN                   : out std_logic;

            -- Videl control inputs:
            PEN                     : in std_logic; -- Light pen.

            -- Video section:
            DE                      : out std_logic; -- Display enable.
            VSYNC                   : out std_logic;
            VSYNC_EN                : out std_logic;
            HSYNC                   : out std_logic;
            HSYNC_EN                : out std_logic;
            CSYNC                   : out std_logic;
            COLOR                   : out std_logic;
            HINT                    : out std_logic;
            VINT                    : out std_logic;
            EVENn_ODD               : out std_logic; -- Interlaced video frame indicator, '0' = even.
            DOTCK                   : out std_logic; -- This is the video DAC clock.
            MONO                    : out std_logic;
            R_OUT                   : out std_logic_vector(7 downto 0);
            G_OUT                   : out std_logic_vector(7 downto 0);
            B_OUT                   : out std_logic_vector(7 downto 0)
        );
    end component VIDEL_TOP;

    component WF1772IP_TOP_SOC -- FDC.
        port (
            CLK                     : in std_logic;
            RESETn                  : in std_logic;
            CSn                     : in std_logic;
            RWn                     : in std_logic;
            A1, A0                  : in std_logic;
            DATA_IN                 : in std_logic_vector(7 downto 0);
            DATA_OUT                : out std_logic_vector(7 downto 0);
            DATA_EN                 : out std_logic;
            RDn                     : in std_logic;
            TR00n                   : in std_logic;
            IPn                     : in std_logic;
            WPRTn                   : in std_logic;
            DDEn                    : in std_logic;
            HDTYPE                  : in std_logic;
            MO                      : out std_logic;
            WG                      : out std_logic;
            WD                      : out std_logic;
            STEP                    : out std_logic;
            DIRC                    : out std_logic;
            DRQ                     : out std_logic;
            INTRQ                   : out std_logic
        );
    end component WF1772IP_TOP_SOC;

    component ASC35530_42L52
        port(
            RESETn              : in std_logic;
            CLK                 : in std_logic; -- Use 16MHz+.

            ADR                 : in std_logic_vector(7 downto 1);
            A4299_CS            : in std_logic; -- Base address is x"FF88xx".
            RWn                 : in std_logic;

            DATA_IN             : in std_logic_vector(15 downto 0);
            DATA_OUT            : out std_logic_vector(15 downto 0);
            DATA_EN             : out std_logic;

            INT                 : out std_logic;
            DMA_EN              : in std_logic;
            SDATA_L             : in std_logic_vector(19 downto 0);
            SDATA_R             : in std_logic_vector(19 downto 0);

            BIT_CLK             : in std_logic; -- The bit clock is 12.288MHz.
            SYNC                : out std_logic;
            SDATA_IN            : in std_logic;
            SDATA_OUT           : out std_logic;

            -- ASC35530:
            SCLOCK              : in std_logic;
            ASCLK               : in std_logic;
            ASSYNC              : in std_logic;
            ASDOUT              : in std_logic;
            ASDIN               : out std_logic;

            -- 42L52:
            CODEC_SPKR_HP       : in std_logic;
            CODEC_MCLK          : in std_logic;
            CODEC_SDA           : in std_logic;
            CODEC_AD0           : in std_logic;
            CODEC_FS_LRCK       : in std_logic;
            CODEC_SCLK          : out std_logic;
            CODEC_SDIN          : out std_logic;
            CODEC_SDOUT         : in std_logic;
            CODEC_SCL           : in std_logic
        );
    end component ASC35530_42L52;

    component WF_SD_DRIVES
        port(
            RESETn                  : in std_logic;
            CLK_16MHz               : in std_logic;
            CLK_32MHz               : in std_logic;
            CLK_SDCARD              : in std_logic;

            CD_IN                   : in std_logic_vector(7 downto 0);
            CD_OUT                  : out std_logic_vector(7 downto 0);
            CD_EN                   : out std_logic;
            CR_Wn                   : in std_logic;
            CA1                     : in std_logic;

            HDCSn                   : in std_logic;
            HDRQ                    : out std_logic;
            ACKn                    : in std_logic;
            HDINTn                  : out std_logic;

            FDD_MO                  : in std_logic;
            FDD_WG                  : in std_logic;
            FDD_WD                  : in std_logic;
            FDD_STEP                : in std_logic;
            FDD_DIRC                : in std_logic;
            FDD_D1SELn              : in std_logic;
            FDD_D0SELn              : in std_logic;
            FDD_SDSEL               : in std_logic;
            FDD_DRIVETYPE           : in std_logic;
            FDD_RDn                 : out std_logic;
            FDD_TR00n               : out std_logic;
            FDD_IPn                 : out std_logic;
            FDD_WPn                 : out std_logic;

            JOY_DIS                 : out std_logic;
            LED_1                   : out std_logic;
            LED_2                   : out std_logic;

            DRIVES_BSYn             : out std_logic;
            SDC_MISO                : in std_logic;
            SDC_MOSI                : out std_logic;
            SDC_CSn                 : out std_logic;
            SDC_SCK                 : out std_logic;
            SDC_CDn                 : in std_logic;
            SDC_WP                  : in std_logic;
            SDC_PWRn                : out std_logic
        );
    end component WF_SD_DRIVES;

    component WF68901IP_TOP_SOC -- MFP.
        port (  -- System control:
            CLK                     : in std_logic;
            RESETn                  : in std_logic;

            -- Asynchronous bus control:
            DSn                     : in std_logic;
            CSn                     : in std_logic;
            RWn                     : in std_logic;
            DTACKn                  : out std_logic;

            -- Data and Adresses:
            RS                      : in std_logic_vector(5 downto 1);
            DATA_IN                 : in std_logic_vector(7 downto 0);
            DATA_OUT                : out std_logic_vector(7 downto 0);
            DATA_EN                 : out std_logic;
            GPIP_IN                 : in std_logic_vector(7 downto 0);
            GPIP_OUT                : out std_logic_vector(7 downto 0);
            GPIP_EN                 : out std_logic_vector(7 downto 0);

            -- Interrupt control:
            IACKn                   : in std_logic;
            IEIn                    : in std_logic;
            IEOn                    : out std_logic;
            IRQn                    : out std_logic;

            -- Timers and timer control:
            XTAL1                   : in std_logic; -- Use an oszillator instead of a quartz.
            TAI                     : in std_logic;
            TBI                     : in std_logic;
            TAO                     : out std_logic;
            TBO                     : out std_logic;
            TCO                     : out std_logic;
            TDO                     : out std_logic;

            -- Serial I/O control:
            RC                      : in std_logic;
            TC                      : in std_logic;
            SI                      : in std_logic;
            SO                      : out std_logic;
            SO_EN                   : out std_logic;

            -- DMA control:
            RRn                     : out std_logic;
            TRn                     : out std_logic
        );
    end component WF68901IP_TOP_SOC;

    component WF2149IP_TOP_SOC -- Sound.
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

            OUT_A       : out std_logic; -- Analog (PWM) outputs.
            OUT_B       : out std_logic;
            OUT_C       : out std_logic
        );
    end component WF2149IP_TOP_SOC;


    component WF6850IP_TOP_SOC -- ACIA.
      port (
            CLK                     : in std_logic;
            RESETn                  : in std_logic;

            CS2n, CS1, CS0          : in std_logic;
            E                       : in std_logic;
            RWn                     : in std_logic;
            RS                      : in std_logic;

            DATA_IN                 : in std_logic_vector(7 downto 0);
            DATA_OUT                : out std_logic_vector(7 downto 0);
            DATA_EN                 : out std_logic;

            TXCLK                   : in std_logic;
            RXCLK                   : in std_logic;
            RXDATA                  : in std_logic;
            CTSn                    : in std_logic;
            DCDn                    : in std_logic;

            IRQn                    : out std_logic;
            TXDATA                  : out std_logic;
            RTSn                    : out std_logic
           );
    end component WF6850IP_TOP_SOC;

    component RTC1287_85363 is
        port(
            CLK                     : in std_logic; -- < 32MHz.
            RESET                   : in std_logic;

            -- The bus interface:
            RTC_AD_IN               : in std_logic_vector(7 downto 0);
            RTC_D_OUT               : buffer std_logic_vector(7 downto 0);
            RTC_D_EN                : out std_logic;
            RTCCS                   : in std_logic;
            RTCAS                   : in std_logic; -- Address strobe.
            RTCDS                   : in std_logic; -- Data strobe.
            RTC_RWn                 : in std_logic;
            RTC_ACK                 : out std_logic;

            -- The SPI signals:
            PCF85363_SDA_IN         : in std_logic;
            PCF85363_SDA_OUT        : out std_logic;
            PCF85363_SDA_EN         : out std_logic;
            PCF85363_SCL            : out std_logic;
            PCF85363_SCL_EN         : out std_logic;
            PCF85363_CLK            : in std_logic; -- Currently not in use.
            PCF85363_INTn           : in std_logic; -- Currently not in use.
            PCF85363_TS             : in std_logic -- Currently not in use.
        );
    end component RTC1287_85363;

    component WF5C15_139xIP_TOP -- RP5C15_DS1392 RTC bridge.
        port(
            CLK                     : in std_logic;
            RESETn                  : in std_logic;

            ADR                     : in std_logic_vector(3 downto 0);
            DATA_IN                 : in std_logic_vector(3 downto 0);
            DATA_OUT                : out std_logic_vector(3 downto 0);
            DATA_EN                 : out std_logic;
            CS, CSn                 : in std_logic;
            WRn, RDn                : in std_logic;

            SPI_IN                  : in std_logic;
            SPI_OUT                 : out std_logic;
            SPI_EN                  : out std_logic;
            SPI_SCL                 : out std_logic;
            SPI_CE                  : out std_logic
            );
    end component WF5C15_139xIP_TOP;

    component SCC8530_TOP is
        port(
            -- System controls:
            PCLK            : in std_logic;
    
            -- Bus:
            DATA_IN         : in std_logic_vector(7 downto 0);
            DATA_OUT        : out std_logic_vector(7 downto 0);
            DATA_EN         : out std_logic;
    
            -- Bus controls:
            CEn             : in std_logic;
            RDn             : in std_logic;
            WRn             : in std_logic;
            A_Bn            : in std_logic;
            D_Cn            : in std_logic;
    
            -- Interrupt:
            INTACKn         : in std_logic;
            IEI             : in std_logic;
            IEO             : out std_logic;
            INTn            : out std_logic; -- Open drain in 5380.
    
            -- Serial Data:
            RxDA            : in std_logic;
            TxDA            : out std_logic;
            TxDA_EN         : out std_logic; -- This is an enhancement over the original chip.
            RxDB            : in std_logic;
            TxDB            : out std_logic;
    
            -- Channel clocks:
            TRxCA_INn       : in std_logic;
            TRxCA_OUTn      : out std_logic;
            TRxCA_EN        : out std_logic;
            RTxCAn          : in std_logic;
            TRxCB_INn       : in std_logic;
            TRxCB_OUTn      : out std_logic;
            TRxCB_EN        : out std_logic;
            RTxCBn          : in std_logic;
    
            -- Channel controls:
            SYNCA_IN        : in std_logic;
            SYNCA_OUT       : out std_logic;
            SYNCA_EN        : out std_logic;
            Wn_REQAn        : out std_logic; -- Open drain in 5380.
            DTRn_REQAn      : out std_logic;
            RTSAn           : out std_logic;
            CTSAn           : in std_logic;
            DCDAn           : in std_logic;
            SYNCB_IN        : in std_logic;
            SYNCB_OUT       : out std_logic;
            SYNCB_EN        : out std_logic;
            Wn_REQBn        : out std_logic;
            DTRn_REQBn      : out std_logic;
            RTSBn           : out std_logic;
            CTSBn           : in std_logic;
            DCDBn           : in std_logic
        );
    end component;

    component USB1164_TOP
        generic (LITTLE_ENDIAN  : boolean);
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
    end component USB1164_TOP;

    component WF5380_TOP_SOC
        port (
            -- System controls:
            CLK                     : in std_logic;
            RESET                   : in std_logic;

            -- Address and data:
            ADR                     : in std_logic_vector(2 downto 0);
            DATA_IN                 : in std_logic_vector(7 downto 0);
            DATA_OUT                : out std_logic_vector(7 downto 0);
            DATA_EN                 : out std_logic;

            -- Bus and DMA controls:
            CSn                     : in std_logic;
            RDn                     : in std_logic;
            WRn                     : in std_logic;
            EOPn                    : in std_logic;
            DACKn                   : in std_logic;
            DRQ                     : out std_logic;
            INT                     : out std_logic;
            READY                   : out std_logic;

            -- SCSI bus:
            DB_INn                  : in std_logic_vector(7 downto 0);
            DB_OUTn                 : out std_logic_vector(7 downto 0);
            DB_EN                   : out std_logic;
            DBP_INn                 : in std_logic;
            DBP_OUTn                : out std_logic;
            DBP_EN                  : out std_logic;
            RST_INn                 : in std_logic;
            RST_OUTn                : out std_logic;
            RST_EN                  : out std_logic;
            BSY_INn                 : in std_logic;
            BSY_OUTn                : out std_logic;
            BSY_EN                  : out std_logic;
            SEL_INn                 : in std_logic;
            SEL_OUTn                : out std_logic;
            SEL_EN                  : out std_logic;
            ACK_INn                 : in std_logic;
            ACK_OUTn                : out std_logic;
            ACK_EN                  : out std_logic;
            ATN_INn                 : in std_logic;
            ATN_OUTn                : out std_logic;
            ATN_EN                  : out std_logic;
            REQ_INn                 : in std_logic;
            REQ_OUTn                : out std_logic;
            REQ_EN                  : out std_logic;
            IOn_IN                  : in std_logic;
            IOn_OUT                 : out std_logic;
            IO_EN                   : out std_logic;
            DCn_IN                  : in std_logic;
            DCn_OUT                 : out std_logic;
            DC_EN                   : out std_logic;
            MSG_INn                 : in std_logic;
            MSG_OUTn                : out std_logic;
            MSG_EN                  : out std_logic
        );
    end component WF5380_TOP_SOC;

    component FLASHBOOT_UMASPI
        port(
            CLK                     : in std_logic;
            PLL_LOCK                : in std_logic;
            RESET_COREn             : in std_logic;
            RESET_INn               : in std_logic;
            RESET_OUTn              : out std_logic;
            CORETYPE                : in std_logic_vector(15 downto 0);
            VERSION                 : in std_logic_vector(31 downto 0);
            ROM_CEn                 : in std_logic;
            ADR_OUT                 : out std_logic_vector(23 downto 0);
            ADR_EN                  : out std_logic;
            DATA_IN                 : in std_logic_vector(15 downto 0);
            DATA_OUT                : out std_logic_vector(15 downto 0);
            DATA_EN                 : out std_logic;
            FLASH_RDY               : in std_logic;
            FLASH_RESETn            : out std_logic;
            FLASH_WEn               : out std_logic;
            FLASH_OEn               : out std_logic;
            FLASH_CEn               : out std_logic;
            JOY                     : out std_logic_vector(7 downto 0);
            KEY                     : out std_logic_vector(15 downto 0);
            RAMADDR			        : out std_logic_vector(31 downto 0);
            RAMDATA			        : out std_logic_vector(15 downto 0);
            RAMWE                   : out std_logic;
            SPI_CLK                 : in std_logic;
            SPI_SSn                 : in std_logic_vector(2 downto 0);
            SPI_DIN                 : in std_logic;
            SPI_DOUT                : out std_logic;
            BOOT_ACK                : in std_logic;
            BOOT_REQ                : out std_logic;
            BOOT_LED                : out std_logic
        );
    end component FLASHBOOT_UMASPI;
end SUSKA_CORE_C_FALCON_PKG;
