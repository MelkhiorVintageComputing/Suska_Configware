------------------------------------------------------------------------
----                                                                ----
----  Atari Falcon compatible direct memory access processor.       ----
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
-- Revision 2K15B  2015/12/24 WF
--   Removed BGA_INn. BGA_OUTn is now BGAn.
-- Revision 2K21A 20211224 WF
--   Minor code optimizations.
--   Several changes / optimizations to meet the requirements for the new Falcon IP core.
-- Revision 2K24A  20240620 WF
--   CD bus enable signal CD_EN changes.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.FDMA_PKG.all;

entity FDMA_TOP_SOC is
    generic(
        ACSI_FIFO_DEPTH     : integer := 32; -- Number of registers.
        REPLAY_FIFO_DEPTH   : integer := 32; -- Number of registers.
        CAPTURE_FIFO_DEPTH  : integer := 32 -- Number of registers.
    );
    port(
        RESET               : in std_logic;

        -- Clock system:
        CLK_32M0            : in std_logic; -- 32MHz.
        CLK_16M0            : in std_logic; -- This is the BCLK.
        --CLK_32O           : out std_logic; -- 32MHz. Not used nor modeled.
        --CLK_8             : out std_logic; -- 8MHz. Not used nor modeled.
        --CLK_2             : out std_logic; -- 2MHz. Not used nor modeled.
        SNCLK               : in std_logic; -- 25.175MHz.
        CLK_EXT             : in std_logic; -- External clock.

        -- Adress and data bus:
        FC_IN               : in std_logic_vector(2 downto 0);
        FC_OUT              : out std_logic_vector(2 downto 0);
        ADR_IN              : in std_logic_vector(31 downto 1);
        ADR_OUT             : out std_logic_vector(31 downto 1);
        ADR_EN              : out std_logic;
        DATA_IN             : in std_logic_vector(15 downto 0);
        DATA_OUT            : out std_logic_vector(15 downto 0);
        DATA_EN             : out std_logic;

        -- Bus control signals:
        BMODE               : in std_logic; -- '0' = 68030 bus master, '1' = 68000 bus master.
        AS_INn              : in std_logic;
        AS_OUTn             : out std_logic;
        LDS_INn             : in std_logic;
        LDS_OUTn            : out std_logic;
        UDS_INn             : in std_logic;
        UDS_OUTn            : out std_logic;
        RWn_IN              : in std_logic;
        RWn_OUT             : out std_logic;
        DTACK_INn           : in std_logic;
        DTACK_OUTn          : out std_logic;

        -- Bus arstd_logicration signals:
        BRn                 : out std_logic;
        BGIn                : in std_logic;
        BGOn                : out std_logic;
        BGAn                : out std_logic;
        BERRn               : in std_logic;

        -- ACSI bus:
        CA                  : out std_logic_vector(2 downto 0); -- ACSI adress.
        CR_Wn               : out std_logic; -- ACSI/ SCSI read write control.
        CRn_W               : out std_logic; -- ACSI/ SCSI read write control.
        CD_IN               : in std_logic_vector(7 downto 0); -- ACSI data.
        CD_OUT              : out std_logic_vector(7 downto 0); -- ACSI data.
        CD_EN               : out std_logic;  -- CD data enable.

        DRIVE_SEL           : out std_logic_vector(1 downto 0); -- Drive selection during register access and DMA.
        FDCSn               : out std_logic; -- FLOPPY select.
        HDCSn               : out std_logic; -- ACSI drive select.
        SCSICSn             : out std_logic; -- SCSI drive select.
        SDCSn               : out std_logic; -- SDcard drive select.
        FDRQ                : in std_logic; -- FLOPPY request.
        HDRQ                : in std_logic;  -- ACSI drive request.
        ACKn                : out std_logic; -- ACSI data acknowledge.

        -- Floppy disk drive configuration:
        MDET                : in std_logic_vector(1 downto 0);
        DISKCHNG            : in std_logic;
        MODE                : out std_logic_vector(1 downto 0);
        FCCLK               : out std_logic; -- Floppy controller clock.

        -- External serial output channel:
        PLYDATA             : out std_logic;
        PLYCLK              : out std_logic;
        PLYSYNC_IN          : in std_logic; -- Gated clock mode.
        PLYSYNC_OUT         : out std_logic; -- Continuous clock mode.
        PLYSYNC_EN          : out std_logic; -- Continuous clock mode.

        -- External serial input channel:
        RECDATA             : in std_logic;
        RECCLK              : out std_logic;
        RECSYNC_IN          : in std_logic; -- Gated clock mode.
        RECSYNC_OUT         : out std_logic; -- Continuous clock mode.
        RECSYNC_EN          : out std_logic; -- Continuous clock mode.

        -- DSP connector:
        DSP_SRD             : out std_logic; -- DSP receives data.
        DSP_SCK             : out std_logic; -- Transmit clockout.
        DSP_STD             : in std_logic; -- DSP transmits data.
        DSP_PLY_EN          : out std_logic; -- Tristate control.
        DSP_REC_EN          : out std_logic; -- Tristate control.
        DSP_SC0             : out std_logic; -- Receive clockout.
        DSP_SC1_IN          : in std_logic; -- Receive syncout.
        DSP_SC1_OUT         : out std_logic; -- Receive syncout.
        DSP_SC2_IN          : in std_logic; -- Transmit syncout.
        DSP_SC2_OUT         : out std_logic; -- Transmit syncout.

        -- Falcon audio codec:
        SCLOCK              : out std_logic;
        ASCLK               : out std_logic;
        ASSYNC              : out std_logic;
        ASDOUT              : in std_logic; -- Sampled on the rising edge of ASCLK.
        ASDIN               : out std_logic; -- Sampled on the falling edge of ASCLK.
        --PSGN              : This pin (Pin 144) is not documented anywhere. So we do not model it.

        -- Interrupt signals:
        SCNT                : out std_logic; -- Timer A interrupt of the multi function port (MFP).
        SINT                : out std_logic; -- IO7 interrupt of the multi function port (MFP).
        HDINTn              : in std_logic;
        FDINT               : in std_logic;
        DSKIRQn             : out std_logic; -- Open collector with weak pull up?
        
        -- Microwire Interface:
        GPIO_IN             : in std_logic_vector(2 downto 0);
        GPIO_OUT            : out std_logic_vector(2 downto 0);
        GPIO_EN             : out std_logic_vector(2 downto 0);
        UWC                 : out std_logic;
        UWD                 : out std_logic;
        UWEn                : out std_logic
    );
end entity FDMA_TOP_SOC;

architecture structure of FDMA_TOP_SOC is
signal ADR_OUT_ACSI         : std_logic_vector(31 downto 1);
signal ADR_EN_ACSI          : std_logic;
signal ADR_OUT_REPLAY       : std_logic_vector(31 downto 1);
signal ADR_EN_REPLAY        : std_logic;
signal ADR_OUT_CAPTURE      : std_logic_vector(31 downto 1);
signal ADR_EN_CAPTURE       : std_logic;
signal AS_In                : std_logic;
signal DATA_OUT_MW          : std_logic_vector(15 downto 0);
signal DATA_EN_MW           : std_logic;
signal DATA_OUT_ACSI_REG    : std_logic_vector(15 downto 0);
signal DATA_EN_ACSI_REG     : std_logic;
signal DATA_OUT_SOUND_REG   : std_logic_vector(15 downto 0);
signal DATA_EN_SOUND_REG    : std_logic;
signal DATA_OUT_FIFOs       : std_logic_vector(15 downto 0);
signal DATA_EN_ACSI         : std_logic;
signal DATA_EN_CAPTURE      : std_logic;
signal CA_I                 : std_logic_vector(2 downto 0);
signal CD_OUT_REG           : std_logic_vector(7 downto 0);
signal CD_OUT_FIFO          : std_logic_vector(7 downto 0);
signal DTACK_MWn            : std_logic;
signal DTACK_ACSI_REGn      : std_logic;
signal DTACK_SOUND_REGn     : std_logic;
signal CODEC_INT            : std_logic;
signal CODEC_LOAD           : std_logic;
signal SDATA_L              : std_logic_vector(19 downto 0);
signal SDATA_R              : std_logic_vector(19 downto 0);
signal CD_RD_HIn            : std_logic;
signal CD_RD_LOWn           : std_logic;
signal CD_HIBUF_EN          : std_logic;
signal ACSI_FIFO_CLRn       : std_logic;
signal ACSI_FIFO_WR         : std_logic;
signal ACSI_FIFO_RD         : std_logic;
signal ACSI_FIFO_FULL       : std_logic;
signal ACSI_FIFO_LOW        : std_logic;
signal ACSI_FIFO_EMPTY      : std_logic;
signal REPLAY_FIFO_CLRn     : std_logic;
signal REPLAY_FIFO_WR       : std_logic;
signal REPLAY_FIFO_RD       : std_logic;
signal REPLAY_FIFO_FULL     : std_logic;
signal REPLAY_FIFO_LOW      : std_logic;
signal REPLAY_FIFO_EMPTY    : std_logic;
signal CAPTURE_FIFO_CLRn    : std_logic;
signal CAPTURE_FIFO_WR      : std_logic;
signal CAPTURE_FIFO_RD      : std_logic;
signal CAPTURE_FIFO_FULL    : std_logic;
signal CAPTURE_FIFO_LOW     : std_logic;
signal CAPTURE_FIFO_EMPTY   : std_logic;
signal DMA_RWn              : std_logic;
signal SECTOR_CNT_EN        : std_logic;
signal ACSI_DATA_REQ        : std_logic;
signal DMA_FRAME_CNT_EN     : std_logic;
signal CTRL_ACC             : std_logic;
signal FDCS_CTRL_ACCn       : std_logic;
signal FDCS_DMA_ACCn        : std_logic;
signal DMA_SRC_SEL          : std_logic_vector(1 downto 0);
signal CTRL_SRC_SEL         : std_logic_vector(1 downto 0);
signal DMA_EN               : std_logic;
signal ACSI_FIFO_ERROR      : std_logic;
signal PCM_REPLAY           : std_logic;
signal PCM_CAPTURE          : std_logic;
signal REPLAY_FRAME_CNT_EN  : std_logic;
signal CAPTURE_FRAME_CNT_EN : std_logic;
signal REPLAY_DATAREQ       : std_logic;
signal REPLAY_DATACK        : std_logic;
signal REPLAY_DATA_OUT      : std_logic_vector(15 downto 0);
signal CAPTURE_DATAREQ      : std_logic;
signal CAPTURE_DATACK       : std_logic;
signal CAPTURE_DATA_IN      : std_logic_vector(15 downto 0);
signal CROSSBAR_SOURCE      : std_logic_vector(15 downto 0);
signal CROSSBAR_DEST        : std_logic_vector(15 downto 0);
signal DAC_TRACK_SEL        : std_logic_vector(1 downto 0);
signal TRACK_PLAY           : std_logic_vector(1 downto 0);
signal SMODE_SEL            : std_logic_vector(1 downto 0);
signal SMODE_FREQ           : std_logic_vector(1 downto 0);
signal FREQ_DIV_EXT         : std_logic_vector(3 downto 0);
signal FREQ_DIV_INT         : std_logic_vector(3 downto 0);
signal REC_TRACK_SEL        : std_logic_vector(1 downto 0);
signal DAC_SRC              : std_logic_vector(1 downto 0);
signal ADC_SRC              : std_logic_vector(1 downto 0);
signal GAIN                 : std_logic_vector(7 downto 0);
signal ATTENUATION          : std_logic_vector(7 downto 0);
signal DAC_OV               : std_logic;
signal ADC_OV               : std_logic;
signal CODEC_TAG            : std_logic_vector(15 downto 0);
signal CODEC_ADDRESS        : std_logic_vector(15 downto 0);
signal CODEC_COMMAND        : std_logic_vector(15 downto 0);
signal CODEC_FMODEn         : std_logic;
begin
    ADR_EN <= ADR_EN_ACSI or ADR_EN_REPLAY or ADR_EN_CAPTURE;
    ADR_OUT <= ADR_OUT_ACSI when ADR_EN_ACSI = '1' else
               ADR_OUT_REPLAY when ADR_EN_REPLAY = '1' else ADR_OUT_CAPTURE;

    AS_In <= '1' when FC_IN = "111" else AS_INn; -- No access in the CPU space.

    DATA_EN <= DATA_EN_ACSI_REG or DATA_EN_SOUND_REG or DATA_EN_MW or DATA_EN_ACSI or DATA_EN_CAPTURE;
    DATA_OUT <= DATA_OUT_ACSI_REG when DATA_EN_ACSI_REG = '1' else
                DATA_OUT_SOUND_REG when DATA_EN_SOUND_REG = '1' else    
                DATA_OUT_MW when DATA_EN_MW = '1' else
                DATA_OUT_FIFOs when DATA_EN_ACSI = '1' else
                DATA_OUT_FIFOs when DATA_EN_CAPTURE = '1' else (others => '0');

    DTACK_OUTn <= DTACK_ACSI_REGn and DTACK_SOUND_REGn and DTACK_MWn;

    FDCSn <= FDCS_CTRL_ACCn and FDCS_DMA_ACCn;

    CR_Wn <= RWn_IN when CTRL_ACC = '1' else DMA_RWn;
    CRn_W <= not RWn_IN when CTRL_ACC = '1' else not DMA_RWn;

    CA(2) <= CA_I(2) when CTRL_ACC = '1' else '1'; -- Default is required for DMA operation.
    CA(1) <= CA_I(1) when CTRL_ACC = '1' else '1';
    CA(0) <= CA_I(0);

    CD_OUT <= CD_OUT_FIFO when CD_RD_HIn = '0' or CD_RD_LOWn = '0' else CD_OUT_REG;

    -- Decoding for DRIVE_SEL:
    -- ACSI = "00", SCSI = "01", Floppy = "10", SD card = "11".
    DRIVE_SEL <= CTRL_SRC_SEL when CTRL_ACC = '1' else DMA_SRC_SEL;

    DSKIRQn <= '1' when HDINTn = '1' and FDINT = '0' else '0';

    DMA_CONTROL: FDMA_CTRL
        port map(
            CLK                 => CLK_16M0,
            RESET               => RESET,

            -- Bus control:
            BMODE               => BMODE,
            FC_OUT              => FC_OUT,
            AS_INn              => AS_In,
            AS_OUTn             => AS_OUTn,
            ADR_EN_ACSI         => ADR_EN_ACSI,
            ADR_EN_REPLAY       => ADR_EN_REPLAY,
            ADR_EN_CAPTURE      => ADR_EN_CAPTURE,
            UDSn                => UDS_OUTn,
            LDSn                => LDS_OUTn,
            RWn                 => RWn_OUT,
            BERRn               => BERRn,
            DTACKn              => DTACK_INn,
            DATA_EN_ACSI        => DATA_EN_ACSI,
            DATA_EN_CAPTURE     => DATA_EN_CAPTURE,

            -- Bus arbitration:
            BRn                 => BRn,
            BGIn                => BGIn,
            BGOn                => BGOn,
            BGAn                => BGAn,

            -- Control signals for ACSI:
            ACSI_FIFO_CLRn      => ACSI_FIFO_CLRn,
            ACSI_FIFO_WR        => ACSI_FIFO_WR,
            ACSI_FIFO_RD        => ACSI_FIFO_RD,
            ACSI_FIFO_FULL      => ACSI_FIFO_FULL,
            ACSI_FIFO_LOW       => ACSI_FIFO_LOW,
            ACSI_FIFO_EMPTY     => ACSI_FIFO_EMPTY,

            -- Control signals for the PCM out:
            REPLAY_FIFO_CLRn    => REPLAY_FIFO_CLRn,
            REPLAY_FIFO_WR      => REPLAY_FIFO_WR,
            REPLAY_FIFO_RD      => REPLAY_FIFO_RD,
            REPLAY_FIFO_FULL    => REPLAY_FIFO_FULL,
            REPLAY_FIFO_LOW     => REPLAY_FIFO_LOW,

            -- Control signals for the PCM in:
            CAPTURE_FIFO_CLRn   => CAPTURE_FIFO_CLRn,
            CAPTURE_FIFO_WR     => CAPTURE_FIFO_WR,
            CAPTURE_FIFO_RD     => CAPTURE_FIFO_RD,
            CAPTURE_FIFO_LOW    => CAPTURE_FIFO_LOW,
            CAPTURE_FIFO_EMPTY  => CAPTURE_FIFO_EMPTY,

            -- Handshaking:
            HDRQ                => HDRQ,
            HD_ACKn             => ACKn,
            FDCRQ               => FDRQ,
            FDCSn               => FDCS_DMA_ACCn,
            ACSI_DATA_REQ       => ACSI_DATA_REQ,
            REPLAY_DATAREQ      => REPLAY_DATAREQ,
            REPLAY_DATACK       => REPLAY_DATACK,
            CAPTURE_DATAREQ     => CAPTURE_DATAREQ,
            CAPTURE_DATACK      => CAPTURE_DATACK,

            SECTOR_CNT_EN       => SECTOR_CNT_EN,
            DMA_FRAME_CNT_EN    => DMA_FRAME_CNT_EN,
            RP_FRAME_CNT_EN     => REPLAY_FRAME_CNT_EN,
            CA_FRAME_CNT_EN     => CAPTURE_FRAME_CNT_EN,

            -- Control signals for the ACSI multiplexer:
            CD_HIBUF_EN         => CD_HIBUF_EN,
            CD_RD_HIn           => CD_RD_HIn,
            CD_RD_LOWn          => CD_RD_LOWn,

            -- Other controls:
            DMA_EN              => DMA_EN,
            PCM_REPLAY          => PCM_REPLAY,
            PCM_CAPTURE         => PCM_CAPTURE,
            
            DMA_RWn             => DMA_RWn,
            DMA_SRC_SEL         => DMA_SRC_SEL
        );

    I_FIFOs: DMA_FIFOs
        generic map(
            ACSI_FIFO_DEPTH     => ACSI_FIFO_DEPTH,
            REPLAY_FIFO_DEPTH   => REPLAY_FIFO_DEPTH,
            CAPTURE_FIFO_DEPTH  => CAPTURE_FIFO_DEPTH
            )
        port map(
            RESET               => RESET,
            CLK                 => CLK_16M0,

            DATA_IN             => DATA_IN,
            DATA_OUT            => DATA_OUT_FIFOs,

            CD_DATA_IN          => CD_IN,
            CD_DATA_OUT         => CD_OUT_FIFO,

            CAPTURE_DATA_IN     => CAPTURE_DATA_IN,
            REPLAY_DATA_OUT     => REPLAY_DATA_OUT,

            DMA_RWn             => DMA_RWn,
            
            -- Control signals for the ACSI multiplexer:
            ACSI_DATA_EN        => DATA_EN_ACSI,
            CD_HIBUF_EN         => CD_HIBUF_EN,
            CD_RD_HIn           => CD_RD_HIn,
            CD_RD_LOWn          => CD_RD_LOWn,
            CAPTURE_DATA_EN     => DATA_EN_CAPTURE,

            -- Control signals for the ACSI bus:
            ACSI_FIFO_CLRn      => ACSI_FIFO_CLRn,
            ACSI_FIFO_WR        => ACSI_FIFO_WR,
            ACSI_FIFO_RD        => ACSI_FIFO_RD,
            ACSI_FIFO_FULL      => ACSI_FIFO_FULL,
            ACSI_FIFO_LOW       => ACSI_FIFO_LOW,
            ACSI_FIFO_EMPTY     => ACSI_FIFO_EMPTY,
            ACSI_FIFO_ERROR     => ACSI_FIFO_ERROR,

            -- Control signals for the PCM out:
            REPLAY_FIFO_CLRn    => REPLAY_FIFO_CLRn,
            REPLAY_FIFO_WR      => REPLAY_FIFO_WR,
            REPLAY_FIFO_RD      => REPLAY_FIFO_RD,
            REPLAY_FIFO_FULL    => REPLAY_FIFO_FULL,
            REPLAY_FIFO_LOW     => REPLAY_FIFO_LOW,
            REPLAY_FIFO_EMPTY   => REPLAY_FIFO_EMPTY,

            -- Control signals for the PCM in:
            CAPTURE_FIFO_CLRn   => CAPTURE_FIFO_CLRn,
            CAPTURE_FIFO_WR     => CAPTURE_FIFO_WR,
            CAPTURE_FIFO_RD     => CAPTURE_FIFO_RD,
            CAPTURE_FIFO_FULL   => CAPTURE_FIFO_FULL,
            CAPTURE_FIFO_LOW    => CAPTURE_FIFO_LOW,
            CAPTURE_FIFO_EMPTY  => CAPTURE_FIFO_EMPTY
        );

    ACSI_DMA_REGS: FDMA_ACSI_REGs
        port map(
            CLK                 => CLK_16M0,
            RESET               => RESET,

            FC                  => FC_IN,
            ADR_IN              => ADR_IN,
            LDSn                => LDS_INn,
            UDSn                => UDS_INn,
            ASn                 => AS_In,
            RWn                 => RWn_IN,

            DATA_IN             => DATA_IN,
            DATA_OUT            => DATA_OUT_ACSI_REG,
            DATA_EN             => DATA_EN_ACSI_REG,
            DTACKn              => DTACK_ACSI_REGn,
            
            FIFO_ERROR          => ACSI_FIFO_ERROR,
            ACSI_DATA_REQ       => ACSI_DATA_REQ,
            SECTOR_CNT_EN       => SECTOR_CNT_EN,

            CD_IN               => CD_IN,
            CD_OUT              => CD_OUT_REG,
            CD_EN               => CD_EN,

            CTRL_SRC_SEL        => CTRL_SRC_SEL,
            DMA_SRC_SEL         => DMA_SRC_SEL,
            DMA_EN              => DMA_EN,

            DMA_RWn             => DMA_RWn,
            HDCSn               => HDCSn,
            SCSICSn             => SCSICSn,
            SDCSn               => SDCsn,
            FDCSn               => FDCS_CTRL_ACCn,
            CA                  => CA_I,
            CTRL_ACC            => CTRL_ACC,

            MODE                => MODE,
            MDET                => MDET,
            DISKCHNG            => DISKCHNG,
            FCCLK               => FCCLK,
            
            DMA_FRAME_CNT_EN    => DMA_FRAME_CNT_EN,
            DMA_ADR             => ADR_OUT_ACSI
        );

    SOUND_DMA_REGs: FDMA_SOUND_REGs
        port map(
            CLK                 => CLK_32M0,
            RESET               => RESET,

            FC                  => FC_IN,
            ADR_IN              => ADR_IN,
            LDSn                => LDS_INn,
            UDSn                => UDS_INn,
            ASn                 => AS_In,
            RWn                 => RWn_IN,

            DATA_IN             => DATA_IN,
            DATA_OUT            => DATA_OUT_SOUND_REG,
            DATA_EN             => DATA_EN_SOUND_REG,
            DTACKn              => DTACK_SOUND_REGn,
            
            PCM_REPLAY          => PCM_REPLAY,
            PCM_CAPTURE         => PCM_CAPTURE,

            RP_FIFO_EMPTY       => REPLAY_FIFO_EMPTY,
            CA_FIFO_FULL        => CAPTURE_FIFO_FULL,
            RP_FRAME_CNT_EN     => REPLAY_FRAME_CNT_EN,
            CA_FRAME_CNT_EN     => CAPTURE_FRAME_CNT_EN,
            RP_DMA_ADR          => ADR_OUT_REPLAY,
            CA_DMA_ADR          => ADR_OUT_CAPTURE,
            
            CROSSBAR_SOURCE_OUT => CROSSBAR_SOURCE,
            CROSSBAR_DEST_OUT   => CROSSBAR_DEST,
            DAC_TRACK_SEL       => DAC_TRACK_SEL,
            TRACK_PLAY          => TRACK_PLAY,
            SMODE_FREQ          => SMODE_FREQ,
            SMODE_SEL           => SMODE_SEL,
            FREQ_DIV_EXT_OUT    => FREQ_DIV_EXT,
            FREQ_DIV_INT_OUT    => FREQ_DIV_INT,
            REC_TRACK_SEL_OUT   => REC_TRACK_SEL,
            DAC_SRC             => DAC_SRC,
            ADC_SRC             => ADC_SRC,
            GAIN                => GAIN,
            ATTENUATION         => ATTENUATION,
            DAC_OV              => DAC_OV,
            ADC_OV              => ADC_OV,
            CODEC_TAG           => CODEC_TAG,
            CODEC_ADDRESS       => CODEC_ADDRESS,
            CODEC_COMMAND       => CODEC_COMMAND,
            CODEC_FMODEn        => CODEC_FMODEn,

            SCNT                => SCNT,
            SINT                => SINT
        );

    I_PCM_CTRL: PCM_CTRL
        port map(
            RESET               => RESET,

            CLK_32              => CLK_32M0,
            SNCLK               => SNCLK,
            CLK_EXT             => CLK_EXT,

            PLYDATA             => PLYDATA,
            PLYCLK              => PLYCLK,
            PLYSYNC_IN          => PLYSYNC_IN,
            PLYSYNC_OUT         => PLYSYNC_OUT,
            PLYSYNC_EN          => PLYSYNC_EN,

            RECDATA             => RECDATA,
            RECCLK              => RECCLK,
            RECSYNC_IN          => RECSYNC_IN,
            RECSYNC_OUT         => RECSYNC_OUT,
            RECSYNC_EN          => RECSYNC_EN,

            DSP_SRD             => DSP_SRD,
            DSP_SCK             => DSP_SCK,
            DSP_SC2_IN          => DSP_SC2_IN,
            DSP_SC2_OUT         => DSP_SC2_OUT,
            DSP_PLY_EN          => DSP_PLY_EN,
            DSP_STD             => DSP_STD,
            DSP_SC0             => DSP_SC0,
            DSP_SC1_IN          => DSP_SC1_IN,
            DSP_SC1_OUT         => DSP_SC1_OUT,
            DSP_REC_EN          => DSP_REC_EN,

            SCLOCK              => SCLOCK,
            ASCLK               => ASCLK,
            ASSYNC              => ASSYNC,
            ASDOUT              => ASDOUT,
            ASDIN               => ASDIN,

            REPLAY_DATAREQ      => REPLAY_DATAREQ,
            REPLAY_DATACK       => REPLAY_DATACK,
            REPLAY_FIFO_EMPTY   => REPLAY_FIFO_EMPTY,
            PCM_DATA_IN         => REPLAY_DATA_OUT,
            CAPTURE_DATAREQ     => CAPTURE_DATAREQ,
            CAPTURE_DATACK      => CAPTURE_DATACK,
            CAPTURE_FIFO_FULL   => CAPTURE_FIFO_FULL,
            PCM_DATA_OUT        => CAPTURE_DATA_IN,
                               
            CROSSBAR_SOURCE     => CROSSBAR_SOURCE,
            CROSSBAR_DEST       => CROSSBAR_DEST,
            DAC_TRACK_SEL       => DAC_TRACK_SEL,
            TRACK_PLAY          => TRACK_PLAY,
            SMODE_FREQ          => SMODE_FREQ,
            SMODE_SEL           => SMODE_SEL,
            FREQ_DIV_EXT        => FREQ_DIV_EXT,
            FREQ_DIV_INT        => FREQ_DIV_INT,
            REC_TRACK_SEL       => REC_TRACK_SEL,
            DAC_SRC             => DAC_SRC,
            ADC_SRC             => ADC_SRC,
            GAIN                => GAIN,
            ATTENUATION         => ATTENUATION,
            CODEC_TAG           => CODEC_TAG,
            CODEC_ADDRESS       => CODEC_ADDRESS,
            CODEC_COMMAND       => CODEC_COMMAND,
            CODEC_FMODEn        => CODEC_FMODEn,
            DAC_OV              => DAC_OV,
            ADC_OV              => ADC_OV           
        );

    I_MICROWIRE: FDMA_MICROWIRE
        port map(
            RESET               => RESET,
            CLK                 => CLK_32M0,

            FC                  => FC_IN,
            ADR                 => ADR_IN,
            LDSn                => LDS_INn,
            UDSn                => UDS_INn,
            ASn                 => AS_In,
            RWn                 => RWn_IN,

            DATA_IN             => DATA_IN,
            DATA_OUT            => DATA_OUT_MW,
            DATA_EN             => DATA_EN_MW,
            DTACKn              => DTACK_MWn,

            GPx_IN              => GPIO_IN,
            GPx_OUT             => GPIO_OUT,
            GPx_EN              => GPIO_EN,

            UWC                 => UWC,
            UWD                 => UWD,
            UWEn                => UWEn
        );
end Structure;