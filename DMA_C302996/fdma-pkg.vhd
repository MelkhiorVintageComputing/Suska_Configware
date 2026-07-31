------------------------------------------------------------------------
----                                                                ----
----  Atari Falcon compatible direct memory access coprocessor.     ----
----  This file is part of the SUSKA-ATARI clone project.           ----
----                                                                ----
----  Author: Wolfgang Foerster                                     ----
----          support@inventronk.de                                 ----
----          www.inventronik.de                                    ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2012... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- All rights reserved. No portion of this sourcecode may be      ----
---- reproduced or transmitted in any form by any means, whether    ----
---- by electronic, mechanical, photocopying, recording or          ----
---- otherwise, without my written permission.                      ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Description:                                                   ----
----                                                                ----
------------------------------------------------------------------------
-- 
-- Revision History
-- 
-- Revision 2K12A  20120620 WF
--   Initial Release.
-- 

library ieee;
use ieee.std_logic_1164.all;

package FDMA_PKG is
    component FDMA_CTRL
        port (
            CLK                 : in std_logic;
            RESET               : in std_logic;

            -- Bus control:
            BMODE               : in std_logic; -- '0' = 68030 bus master, '1' = 68000 bus master.
            FC_OUT              : out std_logic_vector(2 downto 0);
            AS_INn              : in std_logic;
            AS_OUTn             : out std_logic;
            ADR_EN_ACSI         : out std_logic;
            ADR_EN_REPLAY       : out std_logic;
            ADR_EN_CAPTURE      : out std_logic;
            UDSn                : out std_logic;
            LDSn                : out std_logic;
            RWn                 : out std_logic;
            BERRn               : in std_logic; -- Bus error.
            DTACKn              : in std_logic;
            DATA_EN_ACSI        : out std_logic; -- Switch to connect the ACSI FIFO data to the bus.
            DATA_EN_CAPTURE     : out std_logic; -- Switch to connect the capture FIFO data to the bus.
            
            -- Bus arstd_logicration:
            BRn                 : out std_logic;
            BGIn                : in std_logic;
            BGOn                : out std_logic;
            BGAn                : out std_logic;

            -- Control signals for ACSI:
            ACSI_FIFO_CLRn      : out std_logic; -- Invalidate the FIFO entries.
            ACSI_FIFO_WR        : out std_logic;
            ACSI_FIFO_RD        : out std_logic;
            ACSI_FIFO_FULL      : in std_logic;
            ACSI_FIFO_LOW       : in std_logic;
            ACSI_FIFO_EMPTY     : in std_logic;

            -- Control signals for the PCM out:
            REPLAY_FIFO_CLRn    : out std_logic; -- Invalidate the FIFO entries.
            REPLAY_FIFO_WR      : out std_logic;
            REPLAY_FIFO_RD      : out std_logic;
            REPLAY_FIFO_FULL    : in std_logic;
            REPLAY_FIFO_LOW     : in std_logic;

            -- Control signals for the PCM in:
            CAPTURE_FIFO_CLRn   : out std_logic; -- Invalidate the FIFO entries.
            CAPTURE_FIFO_WR     : out std_logic;
            CAPTURE_FIFO_RD     : out std_logic;
            CAPTURE_FIFO_LOW    : in std_logic;
            CAPTURE_FIFO_EMPTY  : in std_logic;

            -- Handshaking:
            HDRQ                : in std_logic; -- Data request from the sound device.
            HD_ACKn             : out std_logic;
            FDCRQ               : in std_logic; -- Data request from the sound device.
            FDCSn               : out std_logic;      
            ACSI_DATA_REQ       : out std_logic; -- Status register stuff.
            REPLAY_DATAREQ      : in std_logic; -- Data request from the sound device.
            REPLAY_DATACK       : out std_logic; -- Data request from the sound device.
            CAPTURE_DATAREQ     : in std_logic; -- Data request from the sound device.
            CAPTURE_DATACK      : out std_logic; -- Data request from the sound device.

            -- Counter controls:
            SECTOR_CNT_EN       : out std_logic;
            DMA_FRAME_CNT_EN    : out std_logic;
            RP_FRAME_CNT_EN     : out std_logic;
            CA_FRAME_CNT_EN     : out std_logic;

            -- Control signals for the ACSI multiplexer:
            CD_HIBUF_EN         : out std_logic; -- Writes ACSI_BUF_HI.
            CD_RD_HIn           : out std_logic; -- Reads high FIFO byte to CD.
            CD_RD_LOWn          : out std_logic; -- Reads low FIFO byte to CD.

            -- Other controls:
            DMA_EN              : in std_logic;
            PCM_REPLAY          : in std_logic;
            PCM_CAPTURE         : in std_logic;
            
            DMA_RWn             : in std_logic; -- FIFO direction '1' is peripherals to RAM.
            DMA_SRC_SEL         : in std_logic_vector(1 downto 0)
        );
    end component;

    component DMA_FIFOs
        generic(
            ACSI_FIFO_DEPTH     : integer := 16; -- Number of registers.
            REPLAY_FIFO_DEPTH   : integer := 16; -- Number of registers.
            CAPTURE_FIFO_DEPTH  : integer := 16 -- Number of registers.
            );
        port (
            RESET               : in std_logic;
            CLK                 : in std_logic;

            DATA_IN             : in std_logic_vector(15 downto 0);
            DATA_OUT            : out std_logic_vector(15 downto 0);

            CD_DATA_IN          : in std_logic_vector (7 downto 0);
            CD_DATA_OUT         : out std_logic_vector (7 downto 0);

            CAPTURE_DATA_IN     : in std_logic_vector (15 downto 0);
            REPLAY_DATA_OUT     : out std_logic_vector (15 downto 0);

            DMA_RWn             : in std_logic; -- FIFO direction '1' is peripherals to RAM.
            
            -- Control signals for the ACSI multiplexer:
            ACSI_DATA_EN        : in std_logic; -- Switch to connect the ACSI FIFO data to the bus.
            CD_HIBUF_EN         : in std_logic; -- Writes ACSI_BUF_HI.
            CD_RD_HIn           : in std_logic; -- Reads high FIFO byte to CD.
            CD_RD_LOWn          : in std_logic;  -- Reads low FIFO byte to CD.
            CAPTURE_DATA_EN     : in std_logic;  -- Switch to connect the PCM capture FIFO data to the bus.

            -- Control signals for the ACSI bus:
            ACSI_FIFO_CLRn      : in std_logic; -- Invalidate the FIFO entries.
            ACSI_FIFO_WR        : in std_logic;
            ACSI_FIFO_RD        : in std_logic;
            ACSI_FIFO_FULL      : out std_logic;
            ACSI_FIFO_LOW       : out std_logic;
            ACSI_FIFO_EMPTY     : out std_logic;
            ACSI_FIFO_ERROR     : out std_logic;

            -- Control signals for the PCM out:
            REPLAY_FIFO_CLRn    : in std_logic; -- Invalidate the FIFO entries.
            REPLAY_FIFO_WR      : in std_logic;
            REPLAY_FIFO_RD      : in std_logic;
            REPLAY_FIFO_FULL    : out std_logic;
            REPLAY_FIFO_LOW     : out std_logic;
            REPLAY_FIFO_EMPTY   : out std_logic;

            -- Control signals for the PCM in:
            CAPTURE_FIFO_CLRn   : in std_logic; -- Invalidate the FIFO entries.
            CAPTURE_FIFO_WR     : in std_logic;
            CAPTURE_FIFO_RD     : in std_logic;
            CAPTURE_FIFO_FULL   : out std_logic;
            CAPTURE_FIFO_LOW    : out std_logic;
            CAPTURE_FIFO_EMPTY  : out std_logic
        );
    end component;
    
    component FDMA_ACSI_REGs
        port(
            CLK                 : in std_logic;
            RESET               : in std_logic;

            FC                  : in std_logic_vector(2 downto 0); -- Processor function codes.
            ADR_IN              : in std_logic_vector(31 downto 1); --Adress inputs.
            LDSn                : in std_logic; -- Lower data strobe; not used so far.
            UDSn                : in std_logic; -- Upper data strobe.
            ASn                 : in std_logic; -- Adress strobe signal indicates valid adress.
            RWn                 : in std_logic; -- Read write control.

            DATA_IN             : in std_logic_vector (9 downto 0);
            DATA_OUT            : out std_logic_vector (15 downto 0);
            DATA_EN             : out std_logic;
            DTACKn              : out std_logic;
            
            FIFO_ERROR          : in std_logic;
            ACSI_DATA_REQ       : in std_logic;
            SECTOR_CNT_EN       : in std_logic;

            CD_IN               : in std_logic_vector (7 downto 0);
            CD_OUT              : out std_logic_vector (7 downto 0);
            CD_EN               : out std_logic;      

            CTRL_SRC_SEL        : out std_logic_vector(1 downto 0);
            DMA_SRC_SEL         : out std_logic_vector(1 downto 0);
            DMA_EN              : out std_logic;

            DMA_RWn             : out std_logic;
            HDCSn               : out std_logic;
            SCSICSn             : out std_logic;
            SDCSn               : out std_logic;
            FDCSn               : out std_logic;
            CA                  : out std_logic_vector(2 downto 0);
            CTRL_ACC            : out std_logic;

            MDET                : in std_logic_vector(1 downto 0);
            DISKCHNG            : in std_logic;
            MODE                : out std_logic_vector(1 downto 0);
            FCCLK               : out std_logic;
            
            DMA_FRAME_CNT_EN    : in std_logic;
            DMA_ADR             : out std_logic_vector(31 downto 1)
        );
    end component;

    component FDMA_SOUND_REGs
        port(
            CLK                 : in std_logic;
            RESET               : in std_logic;

            FC                  : in std_logic_vector(2 downto 0); -- Processor function codes.
            ADR_IN              : in std_logic_vector(31 downto 1); --Adress inputs.
            LDSn                : in std_logic; -- Lower data strobe; not used so far.
            UDSn                : in std_logic; -- Upper data strobe.
            ASn                 : in std_logic; -- Adress strobe signal indicates valid adress.
            RWn                 : in std_logic; -- Read write control.

            DATA_IN             : in std_logic_vector (15 downto 0);
            DATA_OUT            : out std_logic_vector (15 downto 0);
            DATA_EN             : out std_logic;
            DTACKn              : out std_logic;

            PCM_REPLAY          : out std_logic;
            PCM_CAPTURE         : out std_logic;
            
            RP_FIFO_EMPTY       : in std_logic;
            CA_FIFO_FULL        : in std_logic;
            RP_FRAME_CNT_EN     : in std_logic;
            CA_FRAME_CNT_EN     : in std_logic;
            RP_DMA_ADR          : out std_logic_vector(31 downto 1);
            CA_DMA_ADR          : out std_logic_vector(31 downto 1);
            
            -- Configuration signals:
            CROSSBAR_SOURCE_OUT     : out std_logic_vector(15 downto 0);
            CROSSBAR_DEST_OUT       : out std_logic_vector(15 downto 0);
            DAC_TRACK_SEL           : out std_logic_vector(1 downto 0);
            TRACK_PLAY              : out std_logic_vector(1 downto 0);
            SMODE_FREQ              : out std_logic_vector(1 downto 0);
            SMODE_SEL               : out std_logic_vector(1 downto 0);
            FREQ_DIV_EXT_OUT        : out std_logic_vector(3 downto 0);
            FREQ_DIV_INT_OUT        : out std_logic_vector(3 downto 0);
            REC_TRACK_SEL_OUT       : out std_logic_vector(1 downto 0);
            DAC_SRC                 : out std_logic_vector(1 downto 0);
            ADC_SRC                 : out std_logic_vector(1 downto 0);
            GAIN                    : out std_logic_vector(7 downto 0);
            ATTENUATION             : out std_logic_vector(7 downto 0);
            DAC_OV                  : in std_logic; -- Overflow.
            ADC_OV                  : in std_logic; -- Overflow.       
            CODEC_TAG               : out std_logic_vector(15 downto 0);
            CODEC_ADDRESS           : out std_logic_vector(15 downto 0);
            CODEC_COMMAND           : out std_logic_vector(15 downto 0);
            CODEC_FMODEn            : out std_logic; -- ´'0' = Falcon compatible.

            -- Interrupts:
            SCNT                : out std_logic; -- Timer A interrupt of the multi function port (MFP).
            SINT                : out std_logic -- IO7 interrupt of the multi function port (MFP).
        );
    end component;

    component PCM_CTRL
        port(
            RESET                   : in std_logic;

            CLK_32                   : in std_logic; -- 32MHz.
            SNCLK                   : in std_logic; -- 25.175MHz.
            CLK_EXT                 : in std_logic; -- External clock.

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
            DSP_SC2_IN              : in std_logic; -- Transmit syncout.
            DSP_SC2_OUT             : out std_logic; -- Transmit syncout.
            DSP_PLY_EN              : out std_logic; -- Tristate control.
            DSP_STD                 : in std_logic; -- DSP transmits data.
            DSP_SC0                 : out std_logic; -- Receive clockout.
            DSP_SC1_IN              : in std_logic; -- Receive syncout.
            DSP_SC1_OUT             : out std_logic; -- Receive syncout.
            DSP_REC_EN              : out std_logic; -- Tristate control.

            -- Falcon audio codec:
            SCLOCK                  : out std_logic;
            ASCLK                   : out std_logic;
            ASSYNC                  : out std_logic;
            ASDOUT                  : in std_logic; -- Sampled on the rising edge of ASCLK.
            ASDIN                   : out std_logic; -- Sampled on the falling edge of ASCLK.
            
            -- PCM playback data channel:
            REPLAY_DATAREQ          : out std_logic; -- Data request from the sound device.
            REPLAY_DATACK           : in std_logic; -- Data request from the sound device.
            REPLAY_FIFO_EMPTY       : in std_logic;
            PCM_DATA_IN             : in std_logic_vector (15 downto 0);

            -- PCM capture data channel:
            CAPTURE_DATAREQ         : out std_logic; -- Data request from the sound device.
            CAPTURE_DATACK          : in std_logic; -- Data request from the sound device.
            CAPTURE_FIFO_FULL       : in std_logic;
            PCM_DATA_OUT            : out std_logic_vector (15 downto 0);

            -- Configuration signals:
            CROSSBAR_SOURCE         : in std_logic_vector(15 downto 0);
            CROSSBAR_DEST           : in std_logic_vector(15 downto 0);
            DAC_TRACK_SEL           : in std_logic_vector(1 downto 0);
            TRACK_PLAY              : in std_logic_vector(1 downto 0);
            SMODE_FREQ              : in std_logic_vector(1 downto 0);
            SMODE_SEL               : in std_logic_vector(1 downto 0);
            FREQ_DIV_EXT            : in std_logic_vector(3 downto 0);
            FREQ_DIV_INT            : in std_logic_vector(3 downto 0);
            REC_TRACK_SEL           : in std_logic_vector(1 downto 0);
            DAC_SRC                 : in std_logic_vector(1 downto 0);
            ADC_SRC                 : in std_logic_vector(1 downto 0);
            GAIN                    : in std_logic_vector(7 downto 0);
            ATTENUATION             : in std_logic_vector(7 downto 0);
            CODEC_TAG               : in std_logic_vector(15 downto 0);
            CODEC_ADDRESS           : in std_logic_vector(15 downto 0);
            CODEC_COMMAND           : in std_logic_vector(15 downto 0);
            CODEC_FMODEn            : in std_logic; -- ´'0' = Falcon compatible.
            DAC_OV                  : out std_logic; -- Overflow.
            ADC_OV                  : out std_logic -- Overflow.       
        );
    end component;

    component FDMA_MICROWIRE
        port(
            RESET           : in std_logic;
            CLK             : in std_logic; -- Use a 32MHz clock.

            FC              : in std_logic_vector(2 downto 0); -- Processor function codes.
            ADR             : in std_logic_vector(31 downto 1); --Adress inputs.
            LDSn            : in std_logic; -- Lower data strobe; not used so far.
            UDSn            : in std_logic; -- Upper data strobe.
            ASn             : in std_logic; -- Adress strobe signal indicates valid adress.
            RWn             : in std_logic; -- Read write control.

            DATA_IN         : in std_logic_vector(15 downto 0); -- Data.
            DATA_OUT        : out std_logic_vector(15 downto 0);
            DATA_EN         : out std_logic;
            DTACKn          : out std_logic;

            GPx_IN          : in std_logic_vector(2 downto 0);
            GPx_OUT         : out std_logic_vector(2 downto 0);
            GPx_EN          : out std_logic_vector(2 downto 0);

            UWC             : out std_logic;
            UWD             : out std_logic;
            UWEn            : buffer std_logic
        );
    end component;
end FDMA_PKG;
