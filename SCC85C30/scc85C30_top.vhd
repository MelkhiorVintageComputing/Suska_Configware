------------------------------------------------------------------------
----                                                                ----
---- Serial Communication Controller SCC_85C30 IP Core              ----
----                                                                ----
---- This model provides an asynchronous SCSI interface compa-      ----
---- tible to the Am85C30 from AMD or ESCC 85C30 from Zilog.        ----
---- This core features all functions of their originals except the ----
---- oscillator for external crystals.                              ----
----                                                                ----
---- This file is the top level file without tree state IOs for     ----
---- use in 'systems on chip' designs.                              ----
----                                                                ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2015... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K15B 20151224 WF
--   Draft model.
-- Revision 2K22A 20221224 WF
--   Initial Release.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity SCC8530_TOP is
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
end entity SCC8530_TOP;

architecture STRUCTURE of SCC8530_TOP is
component REGISTERS
    port(
        CLK                 : in std_logic;

        DATA_IN             : in std_logic_vector(7 downto 0);
        DATA_OUT            : out std_logic_vector(7 downto 0);
        DATA_EN             : out std_logic;
        CEn                 : in std_logic;
        RDn                 : in std_logic;
        WRn                 : in std_logic;
        ABn                 : in std_logic;
        DCn                 : in std_logic;

        ONE_CLK_MISS_A      : in std_logic;
        TWO_CLK_MISS_A      : in std_logic;
        LOOP_SEND_A         : in std_logic;
        ON_LOOP_A           : in std_logic;
        Rx_IP_A             : in std_logic;
        Tx_IP_A             : in std_logic;
        EXT_STAT_IP_A       : in std_logic;

        ONE_CLK_MISS_B      : in std_logic;
        TWO_CLK_MISS_B      : in std_logic;
        LOOP_SEND_B         : in std_logic;
        ON_LOOP_B           : in std_logic;
        Rx_IP_B             : in std_logic;
        Tx_IP_B             : in std_logic;
        EXT_STAT_IP_B       : in std_logic;

        BREAK_ABORT_IE_A    : out std_logic;
        EOM_IE_A            : out std_logic;
        CTS_IE_A            : out std_logic;
        SYNC_HUNT_IE_A      : out std_logic;
        DCD_IE_A            : out std_logic;
        FRAME_FIFO_EN_A     : out std_logic;
        ZCOUNT_IE_A         : out std_logic;
        SDLC_HDLC_A         : out std_logic;
        DPLL_COMMAND_A      : out std_logic_vector(2 downto 0);
        LOOPBACK_A          : out std_logic;
        AUTO_ECHO_A         : out std_logic;
        DTRn_REQ_A          : out std_logic;
        BR_GEN_SRC_A        : out std_logic;
        BR_GEN_EN_A         : out std_logic;
        XTAL_A              : out std_logic;
        Rx_CLK_SEL_A        : out std_logic_vector(1 downto 0);
        Tx_CLK_SEL_A        : out std_logic_vector(1 downto 0);
        TRXCn_SEL_A         : out std_logic_vector(2 downto 0);
        CRC_PRES_A          : out std_logic;
        NRZ_FM_A            : out std_logic_vector(1 downto 0);
        GO_ACTIVE_ON_POLL_A : out std_logic;
        MARK_FLAGn_A        : out std_logic;
        ABORT_FLAGn_A       : out std_logic;
        LOOP_MODE_A         : out std_logic;
        B6_B8n_A            : out std_logic;
        RES_A               : out std_logic;
        AUTO_Tx_FLAG_A      : out std_logic;
        AUTO_EOM_LRES_A     : out std_logic;
        AUTO_RTS_A          : out std_logic;
        TxD_PULLED_HIGH_A   : out std_logic;
        FAST_DTR_A          : out std_logic;
        CRC_CHECK_RCVD_A    : out std_logic;
        SYNC_SDLC_ADR_A     : out std_logic_vector(7 downto 0);
        SYNC_SDLC_FLAG_A    : out std_logic_vector(7 downto 0);
        Tx_CRC_EN_A         : out std_logic;
        RTS_A               : out std_logic;
        CRC16_SDLCn_A       : out std_logic;
        Tx_EN_A             : out std_logic;
        SEND_BREAK_A        : out std_logic;
        Tx_BITS_A           : out std_logic_vector(1 downto 0);
        DTR_A               : out std_logic;
        PAR_EN_A            : out std_logic;
        PAR_EVEN_ODDn_A     : out std_logic;
        SYNC_MODE_A         : out std_logic_vector(1 downto 0);
        SYNC_CHAR_A         : out std_logic_vector(1 downto 0);
        CLK_MODE_A          : out std_logic_vector(1 downto 0);
        EXT_INT_EN_A        : out std_logic;
        Tx_INT_EN_A         : out std_logic;
        PAR_S_COND_A        : out std_logic;
        Rx_INT_MODE_A       : out std_logic_vector(1 downto 0);
        DMA_REQ_MODE_A      : out std_logic_vector(2 downto 0);
        Rx_EN_A             : out std_logic;
        SYNC_CHAR_INH_A     : out std_logic;
        ADR_SEARCH_MODE_A   : out std_logic;
        Rx_CRC_EN_A         : out std_logic;
        ENTER_HUNT_MODE_A   : out std_logic;
        AUTO_EN_A           : out std_logic;
        Rx_BITS_A           : out std_logic_vector(1 downto 0);
        TCA                 : out std_logic_vector(15 downto 0);

        BREAK_ABORT_IE_B    : out std_logic;
        EOM_IE_B            : out std_logic;
        CTS_IE_B            : out std_logic;
        SYNC_HUNT_IE_B      : out std_logic;
        DCD_IE_B            : out std_logic;
        FRAME_FIFO_EN_B     : out std_logic;
        ZCOUNT_IE_B         : out std_logic;
        SDLC_HDLC_B         : out std_logic;
        DPLL_COMMAND_B      : out std_logic_vector(2 downto 0);
        LOOPBACK_B          : out std_logic;
        AUTO_ECHO_B         : out std_logic;
        DTRn_REQ_B          : out std_logic;
        BR_GEN_SRC_B        : out std_logic;
        BR_GEN_EN_B         : out std_logic;
        XTAL_B              : out std_logic;
        Rx_CLK_SEL_B        : out std_logic_vector(1 downto 0);
        Tx_CLK_SEL_B        : out std_logic_vector(1 downto 0);
        TRXCn_SEL_B         : out std_logic_vector(2 downto 0);
        CRC_PRES_B          : out std_logic;
        NRZ_FM_B            : out std_logic_vector(1 downto 0);
        GO_ACTIVE_ON_POLL_B : out std_logic;
        MARK_FLAGn_B        : out std_logic;
        ABORT_FLAGn_B       : out std_logic;
        LOOP_MODE_B         : out std_logic;
        B6_B8n_B            : out std_logic;
        RES_B               : out std_logic;
        AUTO_Tx_FLAG_B      : out std_logic;
        AUTO_EOM_LRES_B     : out std_logic;
        AUTO_RTS_B          : out std_logic;
        TxD_PULLED_HIGH_B   : out std_logic;
        FAST_DTR_B          : out std_logic;
        CRC_CHECK_RCVD_B    : out std_logic;
        SYNC_SDLC_ADR_B     : out std_logic_vector(7 downto 0);
        SYNC_SDLC_FLAG_B    : out std_logic_vector(7 downto 0);
        Tx_CRC_EN_B         : out std_logic;
        RTS_B               : out std_logic;
        CRC16_SDLCn_B       : out std_logic;
        Tx_EN_B             : out std_logic;
        SEND_BREAK_B        : out std_logic;
        Tx_BITS_B           : out std_logic_vector(1 downto 0);
        DTR_B               : out std_logic;
        PAR_EN_B            : out std_logic;
        PAR_EVEN_ODDn_B     : out std_logic;
        SYNC_MODE_B         : out std_logic_vector(1 downto 0);
        SYNC_CHAR_B         : out std_logic_vector(1 downto 0);
        CLK_MODE_B          : out std_logic_vector(1 downto 0);
        EXT_INT_EN_B        : out std_logic;
        Tx_INT_EN_B         : out std_logic;
        PAR_S_COND_B        : out std_logic;
        Rx_INT_MODE_B       : out std_logic_vector(1 downto 0);
        DMA_REQ_MODE_B      : out std_logic_vector(2 downto 0);
        Rx_EN_B             : out std_logic;
        SYNC_CHAR_INH_B     : out std_logic;
        ADR_SEARCH_MODE_B   : out std_logic;
        Rx_CRC_EN_B         : out std_logic;
        ENTER_HUNT_MODE_B   : out std_logic;
        AUTO_EN_B           : out std_logic;
        Rx_BITS_B           : out std_logic_vector(1 downto 0);
        TCB                 : out std_logic_vector(15 downto 0);
        STATUS_A            : in std_logic_vector(1 downto 0);
        STATUS_B            : in std_logic_vector(1 downto 0);
        INT_VECT            : out std_logic_vector(7 downto 0);
        INTACKn_INH         : out std_logic;
        MIE                 : out std_logic;
        DLC                 : out std_logic;
        NV                  : out std_logic;
        RESET               : out std_logic;
        SEND_ABORT_A        : out std_logic;
        EN_INT_RxCHAR_A     : out std_logic;
        RES_EXT_STAT_INT_A  : out std_logic;
        RES_TxINT_A         : out std_logic;
        RES_ERR_A           : out std_logic;
        RES_IUS_A           : out std_logic;
        RES_Rx_CRC_A        : out std_logic;
        RES_Tx_CRC_A        : out std_logic;
        RES_Tx_UR_EOM_A     : out std_logic;
        SEND_ABORT_B        : out std_logic;
        EN_INT_RxCHAR_B     : out std_logic;
        RES_EXT_STAT_INT_B  : out std_logic;
        RES_TxINT_B         : out std_logic;
        RES_ERR_B           : out std_logic;
        RES_IUS_B           : out std_logic;
        RES_Rx_CRC_B        : out std_logic;
        RES_Tx_CRC_B        : out std_logic;
        RES_Tx_UR_EOM_B     : out std_logic;
        BUFFER_A_IN         : in std_logic_vector(7 downto 0);
        BUFFER_A_OUT        : out std_logic_vector(7 downto 0);
        BUFFER_B_IN         : in std_logic_vector(7 downto 0);
        BUFFER_B_OUT        : out std_logic_vector(7 downto 0);
        RRA0_RD             : out std_logic;
        RRB0_RD             : out std_logic;
        RRA1_RD             : out std_logic;
        RRB1_RD             : out std_logic;
        RRA6_RD             : out std_logic;
        RRB6_RD             : out std_logic;
        RRA7_RD             : out std_logic;
        RRB7_RD             : out std_logic;
        RRA8_RD             : out std_logic;
        RRB8_RD             : out std_logic;
        WRA8_WR             : out std_logic;
        WRB8_WR             : out std_logic
    );
end component REGISTERS;

component TRANSCEIVER
    port(
        CLK                 : in std_logic;

        RxD                 : in std_logic;
        TxD                 : out std_logic;

        TRxC_INn            : in std_logic;
        TRxC_OUTn           : out std_logic;
        TRxC_EN             : out std_logic;
        RTxCn               : in std_logic;

        SYNC_IN             : in std_logic;
        SYNC_OUT            : out std_logic;
        SYNC_EN             : out std_logic;
        Wn_REQn             : out std_logic;

        ONE_CLK_MISS        : out std_logic;
        TWO_CLK_MISS        : out std_logic;
        LOOP_SEND           : out std_logic;
        ON_LOOP             : out std_logic;
        DCDn                : in std_logic;
        CTSn                : in std_logic;
        Rx_IP               : out std_logic;
        Tx_IP               : out std_logic;
        EXT_STAT_IP         : out std_logic;

        BREAK_ABORT_IE      : in std_logic;
        EOM_IE              : in std_logic;
        CTS_IE              : in std_logic;
        SYNC_HUNT_IE        : in std_logic;
        DCD_IE              : in std_logic;
        FRAME_FIFO_EN       : in std_logic;
        ZCOUNT_IE           : in std_logic;
        SDLC_HDLC           : in std_logic;
        DPLL_COMMAND        : in std_logic_vector(2 downto 0);
        LOOPBACK            : in std_logic;
        AUTO_ECHO           : in std_logic;
        BR_GEN_SRC          : in std_logic;
        BR_GEN_EN           : in std_logic;
        XTAL                : in std_logic;
        Rx_CLK_SEL          : in std_logic_vector(1 downto 0);
        Tx_CLK_SEL          : in std_logic_vector(1 downto 0);
        TRXCn_SEL           : in std_logic_vector(2 downto 0);
        CRC_PRES            : in std_logic;
        NRZ_FM              : in std_logic_vector(1 downto 0);
        GO_ACTIVE_ON_POLL   : in std_logic;
        MARK_FLAGn          : in std_logic;
        ABORT_FLAGn         : in std_logic;
        LOOP_MODE           : in std_logic;
        B6_B8n              : in std_logic;
        RES                 : in std_logic;
        AUTO_Tx_FLAG        : in std_logic;
        AUTO_EOM_LRES       : in std_logic;
        AUTO_RTS            : in std_logic;
        TxD_PULLED_HIGH     : in std_logic;
        FAST_DTR            : in std_logic;
        CRC_CHECK_RCVD      : in std_logic;
        SYNC_SDLC_ADR       : in std_logic_vector(7 downto 0);
        SYNC_SDLC_FLAG      : in std_logic_vector(7 downto 0);
        Tx_CRC_EN           : in std_logic;
        RTS                 : in std_logic;
        RTSn                : out std_logic;
        CRC16_SDLCn         : in std_logic;
        Tx_EN               : in std_logic;
        SEND_BREAK          : in std_logic;
        Tx_BITS             : in std_logic_vector(1 downto 0);
        DTRn_REQn           : out std_logic;
        PAR_EN              : in std_logic;
        PAR_EVEN_ODDn       : in std_logic;
        SYNC_MODE           : in std_logic_vector(1 downto 0);
        SYNC_CHAR           : in std_logic_vector(1 downto 0);
        CLK_MODE            : in std_logic_vector(1 downto 0);
        EXT_INT_EN          : in std_logic;
        Tx_INT_EN           : in std_logic;
        PAR_S_COND          : in std_logic;
        Rx_INT_MODE         : in std_logic_vector(1 downto 0);
        DTRn_REQ            : in std_logic;
        DMA_REQ_MODE        : in std_logic_vector(2 downto 0);
        Rx_EN               : in std_logic;
        SYNC_CHAR_INH       : in std_logic;
        ADR_SEARCH_MODE     : in std_logic;
        Rx_CRC_EN           : in std_logic;
        ENTER_HUNT_MODE     : in std_logic;
        AUTO_EN             : in std_logic;
        Rx_BITS             : in std_logic_vector(1 downto 0);
        TC                  : in std_logic_vector(15 downto 0);
        INTACKn_INH         : in std_logic;
        MIE                 : in std_logic;
        DLC                 : in std_logic;
        INT_ACK             : in std_logic;
        IEI                 : in std_logic;
        INT                 : out std_logic;
        STATUS              : out std_logic_vector(1 downto 0);
        RESET               : in std_logic;
        SEND_ABORT          : in std_logic;
        EN_INT_RxCHAR       : in std_logic;
        RES_EXT_STAT_INT    : in std_logic;
        RES_TxINT           : in std_logic;
        RES_ERR             : in std_logic;
        RES_IUS             : in std_logic;
        RES_Rx_CRC          : in std_logic;
        RES_Tx_CRC          : in std_logic;
        RES_Tx_UR_EOM       : in std_logic;
        BUFFER_IN           : in std_logic_vector(7 downto 0);
        BUFFER_OUT          : out std_logic_vector(7 downto 0);
        RR0_RD              : in std_logic;
        RR1_RD              : in std_logic;
        RR6_RD              : in std_logic;
        RR7_RD              : in std_logic;
        RR8_RD              : in std_logic;
        WR8_WR              : in std_logic
    );
end component TRANSCEIVER;

signal CLK                  : std_logic;
signal ONE_CLK_MISS_A       : std_logic;
signal TWO_CLK_MISS_A       : std_logic;
signal LOOP_SEND_A          : std_logic;
signal ON_LOOP_A            : std_logic;
signal DATA_OUT_REG         : std_logic_vector(7 downto 0);
signal DATA_EN_REG          : std_logic;
signal Rx_IP_A              : std_logic;
signal Tx_IP_A              : std_logic;
signal EXT_STAT_IP_A        : std_logic;
signal ONE_CLK_MISS_B       : std_logic;
signal TWO_CLK_MISS_B       : std_logic;
signal LOOP_SEND_B          : std_logic;
signal ON_LOOP_B            : std_logic;
signal Rx_IP_B              : std_logic;
signal Tx_IP_B              : std_logic;
signal EXT_STAT_IP_B        : std_logic;
signal BREAK_ABORT_IE_A     : std_logic;
signal EOM_IE_A             : std_logic;
signal CTS_IE_A             : std_logic;
signal SYNC_HUNT_IE_A       : std_logic;
signal DCD_IE_A             : std_logic;
signal FRAME_FIFO_EN_A      : std_logic;
signal ZCOUNT_IE_A          : std_logic;
signal SDLC_HDLC_A          : std_logic;
signal DPLL_COMMAND_A       : std_logic_vector(2 downto 0);
signal LOOPBACK_A           : std_logic;
signal AUTO_ECHO_A          : std_logic;
signal DTRn_REQ_A           : std_logic;
signal BR_GEN_SRC_A         : std_logic;
signal BR_GEN_EN_A          : std_logic;
signal BUFFER_A_IN          : std_logic_vector(7 downto 0);
signal BUFFER_A_OUT         : std_logic_vector(7 downto 0);
signal BUFFER_B_IN          : std_logic_vector(7 downto 0);
signal BUFFER_B_OUT         : std_logic_vector(7 downto 0);
signal XTAL_A               : std_logic;
signal Rx_CLK_SEL_A         : std_logic_vector(1 downto 0);
signal Tx_CLK_SEL_A         : std_logic_vector(1 downto 0);
signal TRXCn_SEL_A          : std_logic_vector(2 downto 0);
signal CRC_PRES_A           : std_logic;
signal NRZ_FM_A             : std_logic_vector(1 downto 0);
signal GO_ACTIVE_ON_POLL_A  : std_logic;
signal MARK_FLAGn_A         : std_logic;
signal ABORT_FLAGn_A        : std_logic;
signal LOOP_MODE_A          : std_logic;
signal B6_B8n_A             : std_logic;
signal RES_A                : std_logic;
signal AUTO_Tx_FLAG_A       : std_logic;
signal AUTO_EOM_LRES_A      : std_logic;
signal AUTO_RTS_A           : std_logic;
signal TxD_PULLED_HIGH_A    : std_logic;
signal FAST_DTR_A           : std_logic;
signal CRC_CHECK_RCVD_A     : std_logic;
signal SYNC_SDLC_ADR_A      : std_logic_vector(7 downto 0);
signal SYNC_SDLC_FLAG_A     : std_logic_vector(7 downto 0);
signal Tx_CRC_EN_A          : std_logic;
signal RTS_A                : std_logic;
signal CRC16_SDLCn_A        : std_logic;
signal Tx_EN_A              : std_logic;
signal SEND_BREAK_A         : std_logic;
signal Tx_BITS_A            : std_logic_vector(1 downto 0);
signal DTR_A                : std_logic;
signal PAR_EN_A             : std_logic;
signal PAR_EVEN_ODDn_A      : std_logic;
signal SYNC_MODE_A          : std_logic_vector(1 downto 0);
signal SYNC_CHAR_A          : std_logic_vector(1 downto 0);
signal CLK_MODE_A           : std_logic_vector(1 downto 0);
signal EXT_INT_EN_A         : std_logic;
signal Tx_INT_EN_A          : std_logic;
signal PAR_S_COND_A         : std_logic;
signal Rx_INT_MODE_A        : std_logic_vector(1 downto 0);
signal DMA_REQ_MODE_A       : std_logic_vector(2 downto 0);
signal Rx_EN_A              : std_logic;
signal SYNC_CHAR_INH_A      : std_logic;
signal ADR_SEARCH_MODE_A    : std_logic;
signal Rx_CRC_EN_A          : std_logic;
signal ENTER_HUNT_MODE_A    : std_logic;
signal AUTO_EN_A            : std_logic;
signal Rx_BITS_A            : std_logic_vector(1 downto 0);
signal TCA                  : std_logic_vector(15 downto 0);
signal BREAK_ABORT_IE_B     : std_logic;
signal EOM_IE_B             : std_logic;
signal CTS_IE_B             : std_logic;
signal SYNC_HUNT_IE_B       : std_logic;
signal DCD_IE_B             : std_logic;
signal FRAME_FIFO_EN_B      : std_logic;
signal FRAME_FIFO_EN_CHB    : std_logic;
signal ZCOUNT_IE_B          : std_logic;
signal SDLC_HDLC_B          : std_logic;
signal DPLL_COMMAND_B       : std_logic_vector(2 downto 0);
signal LOOPBACK_B           : std_logic;
signal AUTO_ECHO_B          : std_logic;
signal DTRn_REQ_B           : std_logic;
signal BR_GEN_SRC_B         : std_logic;
signal BR_GEN_EN_B          : std_logic;
signal XTAL_B               : std_logic;
signal Rx_CLK_SEL_B         : std_logic_vector(1 downto 0);
signal Tx_CLK_SEL_B         : std_logic_vector(1 downto 0);
signal TRXCn_SEL_B          : std_logic_vector(2 downto 0);
signal CRC_PRES_B           : std_logic;
signal NRZ_FM_B             : std_logic_vector(1 downto 0);
signal GO_ACTIVE_ON_POLL_B  : std_logic;
signal MARK_FLAGn_B         : std_logic;
signal ABORT_FLAGn_B        : std_logic;
signal LOOP_MODE_B          : std_logic;
signal B6_B8n_B             : std_logic;
signal RES_B                : std_logic;
signal AUTO_Tx_FLAG_B       : std_logic;
signal AUTO_EOM_LRES_B      : std_logic;
signal AUTO_RTS_B           : std_logic;
signal TxD_PULLED_HIGH_B    : std_logic;
signal FAST_DTR_B           : std_logic;
signal CRC_CHECK_RCVD_B     : std_logic;
signal SYNC_SDLC_ADR_B      : std_logic_vector(7 downto 0);
signal SYNC_SDLC_FLAG_B     : std_logic_vector(7 downto 0);
signal Tx_CRC_EN_B          : std_logic;
signal RTS_B                : std_logic;
signal CRC16_SDLCn_B        : std_logic;
signal Tx_EN_B              : std_logic;
signal SEND_BREAK_B         : std_logic;
signal Tx_BITS_B            : std_logic_vector(1 downto 0);
signal DTR_B                : std_logic;
signal PAR_EN_B             : std_logic;
signal PAR_EVEN_ODDn_B      : std_logic;
signal SYNC_MODE_B          : std_logic_vector(1 downto 0);
signal SYNC_CHAR_B          : std_logic_vector(1 downto 0);
signal CLK_MODE_B           : std_logic_vector(1 downto 0);
signal EXT_INT_EN_B         : std_logic;
signal Tx_INT_EN_B          : std_logic;
signal PAR_S_COND_B         : std_logic;
signal Rx_INT_MODE_B        : std_logic_vector(1 downto 0);
signal DMA_REQ_MODE_B       : std_logic_vector(2 downto 0);
signal Rx_EN_B              : std_logic;
signal SYNC_CHAR_INH_B      : std_logic;
signal ADR_SEARCH_MODE_B    : std_logic;
signal Rx_CRC_EN_B          : std_logic;
signal ENTER_HUNT_MODE_B    : std_logic;
signal AUTO_EN_B            : std_logic;
signal Rx_BITS_B            : std_logic_vector(1 downto 0);
signal TCB                  : std_logic_vector(15 downto 0);
signal INT_VECT             : std_logic_vector(7 downto 0);
signal INT_ACK              : std_logic;
signal INTACKn_INH          : std_logic;
signal MIE                  : std_logic;
signal DLC                  : std_logic;
signal NV                   : std_logic;
signal RESET                : std_logic;
signal DTRn_REQn_A          : std_logic;
signal DTRn_REQn_B          : std_logic;
signal INT_A                : std_logic;
signal INT_B                : std_logic;
signal STATUS_A             : std_logic_vector(1 downto 0);
signal STATUS_B             : std_logic_vector(1 downto 0);
signal SEND_ABORT_A         : std_logic;
signal EN_INT_RxCHAR_A      : std_logic;
signal RES_EXT_STAT_INT_A   : std_logic;
signal RES_TxINT_A          : std_logic;
signal RES_ERR_A            : std_logic;
signal RES_IUS_A            : std_logic;
signal RES_Rx_CRC_A         : std_logic;
signal RES_Tx_CRC_A         : std_logic;
signal RES_Tx_UR_EOM_A      : std_logic;
signal SEND_ABORT_B         : std_logic;
signal EN_INT_RxCHAR_B      : std_logic;
signal RES_EXT_STAT_INT_B   : std_logic;
signal RES_TxINT_B          : std_logic;
signal RES_ERR_B            : std_logic;
signal RES_IUS_B            : std_logic;
signal RES_Rx_CRC_B         : std_logic;
signal RES_Tx_CRC_B         : std_logic;
signal RES_Tx_UR_EOM_B      : std_logic;
signal RRA0_RD              : std_logic;
signal RRB0_RD              : std_logic;
signal RRA1_RD              : std_logic;
signal RRB1_RD              : std_logic;
signal RRA6_RD              : std_logic;
signal RRA7_RD              : std_logic;
signal RRB6_RD              : std_logic;
signal RRB7_RD              : std_logic;
signal RRA8_RD              : std_logic;
signal WRA8_WR              : std_logic;
signal RRB8_RD              : std_logic;
signal WRB8_WR              : std_logic;
begin

    DTRn_REQAn <= not DTR_A when DTRn_REQ_A = '0' else DTRn_REQn_A;
    DTRn_REQBn <= not DTR_B when DTRn_REQ_B = '0' else DTRn_REQn_B;
    
    IEO <= '0' when DLC = '1' else -- Disable lower chain.
           '1' when IEI = '1' and INT_A = '0' and INT_B = '0' else '0';

    INTn <= not INT_A and not INT_B;
        
    INT_ACK <= '1' when INTACKn = '0' and RDn = '0' else '0';

    DATA_OUT <= INT_VECT when INTACKn = '0' and RDn = '0' else 
                DATA_OUT_REG when DATA_EN_REG = '1' else x"00";

    DATA_EN <= '1' when DATA_EN_REG = '1' else
               '1' when IEI = '1' and NV = '0' and INTACKn = '0' and RDn = '0' else '0';

    -- The frame FIFO enable logic refers to the CMOS version of the 8530.
    FRAME_FIFO_EN_CHB <= '1' when FRAME_FIFO_EN_A = '1' and FRAME_FIFO_EN_B = '0' else -- Not independantly.
                         '1' when FRAME_FIFO_EN_B = '1' else '0'; -- Independantly.

    TxDA_EN <= Tx_EN_A;

    I_REGISTERS: REGISTERS
        port map(
            CLK                 => PCLK,
                                
            DATA_IN             => DATA_IN,
            DATA_OUT            => DATA_OUT_REG,
            DATA_EN             => DATA_EN_REG,
            CEn                 => CEn,
            RDn                 => RDn,
            WRn                 => WRn,
            ABn                 => A_Bn,
            DCn                 => D_Cn,
                                
            ONE_CLK_MISS_A      => ONE_CLK_MISS_A,
            TWO_CLK_MISS_A      => TWO_CLK_MISS_A,
            LOOP_SEND_A         => LOOP_SEND_A,
            ON_LOOP_A           => ON_LOOP_A,
            Rx_IP_A             => Rx_IP_A,
            Tx_IP_A             => Tx_IP_A,
            EXT_STAT_IP_A       => EXT_STAT_IP_A,
                                
            ONE_CLK_MISS_B      => ONE_CLK_MISS_B,
            TWO_CLK_MISS_B      => TWO_CLK_MISS_B,
            LOOP_SEND_B         => LOOP_SEND_B,
            ON_LOOP_B           => ON_LOOP_B,
            Rx_IP_B             => Rx_IP_B,
            Tx_IP_B             => Tx_IP_B,
            EXT_STAT_IP_B       => EXT_STAT_IP_B,
                                
            BREAK_ABORT_IE_A    => BREAK_ABORT_IE_A,
            EOM_IE_A            => EOM_IE_A,
            CTS_IE_A            => CTS_IE_A,
            SYNC_HUNT_IE_A      => SYNC_HUNT_IE_A,
            DCD_IE_A            => DCD_IE_A,
            FRAME_FIFO_EN_A     => FRAME_FIFO_EN_A,
            ZCOUNT_IE_A         => ZCOUNT_IE_A,
            SDLC_HDLC_A         => SDLC_HDLC_A,
            DPLL_COMMAND_A      => DPLL_COMMAND_A,
            LOOPBACK_A          => LOOPBACK_A,
            AUTO_ECHO_A         => AUTO_ECHO_A,
            DTRn_REQ_A          => DTRn_REQ_A,
            BR_GEN_SRC_A        => BR_GEN_SRC_A,
            BR_GEN_EN_A         => BR_GEN_EN_A,
            XTAL_A              => XTAL_A,
            Rx_CLK_SEL_A        => Rx_CLK_SEL_A,
            Tx_CLK_SEL_A        => Tx_CLK_SEL_A,
            TRXCn_SEL_A         => TRXCn_SEL_A,
            CRC_PRES_A          => CRC_PRES_A,
            NRZ_FM_A            => NRZ_FM_A,
            GO_ACTIVE_ON_POLL_A => GO_ACTIVE_ON_POLL_A,
            MARK_FLAGn_A        => MARK_FLAGn_A,
            ABORT_FLAGn_A       => ABORT_FLAGn_A,
            LOOP_MODE_A         => LOOP_MODE_A,
            B6_B8n_A            => B6_B8n_A,
            RES_A               => RES_A,
            AUTO_Tx_FLAG_A      => AUTO_Tx_FLAG_A,
            AUTO_EOM_LRES_A     => AUTO_EOM_LRES_A,
            AUTO_RTS_A          => AUTO_RTS_A,
            TxD_PULLED_HIGH_A   => TxD_PULLED_HIGH_A,
            FAST_DTR_A          => FAST_DTR_A,
            CRC_CHECK_RCVD_A    => CRC_CHECK_RCVD_A,
            SYNC_SDLC_ADR_A     => SYNC_SDLC_ADR_A,
            SYNC_SDLC_FLAG_A    => SYNC_SDLC_FLAG_A,
            Tx_CRC_EN_A         => Tx_CRC_EN_A,
            RTS_A               => RTS_A,
            CRC16_SDLCn_A       => CRC16_SDLCn_A,
            Tx_EN_A             => Tx_EN_A,
            SEND_BREAK_A        => SEND_BREAK_A,
            Tx_BITS_A           => Tx_BITS_A,
            DTR_A               => DTR_A,
            PAR_EN_A            => PAR_EN_A,
            PAR_EVEN_ODDn_A     => PAR_EVEN_ODDn_A,
            SYNC_MODE_A         => SYNC_MODE_A,
            SYNC_CHAR_A         => SYNC_CHAR_A,
            CLK_MODE_A          => CLK_MODE_A,
            EXT_INT_EN_A        => EXT_INT_EN_A,
            Tx_INT_EN_A         => Tx_INT_EN_A,
            PAR_S_COND_A        => PAR_S_COND_A,
            Rx_INT_MODE_A       => Rx_INT_MODE_A,
            DMA_REQ_MODE_A      => DMA_REQ_MODE_A,
            Rx_EN_A             => Rx_EN_A,
            SYNC_CHAR_INH_A     => SYNC_CHAR_INH_A,
            ADR_SEARCH_MODE_A   => ADR_SEARCH_MODE_A,
            Rx_CRC_EN_A         => Rx_CRC_EN_A,
            ENTER_HUNT_MODE_A   => ENTER_HUNT_MODE_A,
            AUTO_EN_A           => AUTO_EN_A,
            Rx_BITS_A           => Rx_BITS_A,
            TCA                 => TCA,
                                
            BREAK_ABORT_IE_B    => BREAK_ABORT_IE_B,
            EOM_IE_B            => EOM_IE_B,
            CTS_IE_B            => CTS_IE_B,
            SYNC_HUNT_IE_B      => SYNC_HUNT_IE_B,
            DCD_IE_B            => DCD_IE_B,
            FRAME_FIFO_EN_B     => FRAME_FIFO_EN_B,
            ZCOUNT_IE_B         => ZCOUNT_IE_B,
            SDLC_HDLC_B         => SDLC_HDLC_B,
            DPLL_COMMAND_B      => DPLL_COMMAND_B,
            LOOPBACK_B          => LOOPBACK_B,
            AUTO_ECHO_B         => AUTO_ECHO_B,
            DTRn_REQ_B          => DTRn_REQ_B,
            BR_GEN_SRC_B        => BR_GEN_SRC_B,
            BR_GEN_EN_B         => BR_GEN_EN_B,
            XTAL_B              => XTAL_B,
            Rx_CLK_SEL_B        => Rx_CLK_SEL_B,
            Tx_CLK_SEL_B        => Tx_CLK_SEL_B,
            TRXCn_SEL_B         => TRXCn_SEL_B,
            CRC_PRES_B          => CRC_PRES_B,
            NRZ_FM_B            => NRZ_FM_B,
            GO_ACTIVE_ON_POLL_B => GO_ACTIVE_ON_POLL_B,
            MARK_FLAGn_B        => MARK_FLAGn_B,
            ABORT_FLAGn_B       => ABORT_FLAGn_B,
            LOOP_MODE_B         => LOOP_MODE_B,
            B6_B8n_B            => B6_B8n_B,
            RES_B               => RES_B,
            AUTO_Tx_FLAG_B      => AUTO_Tx_FLAG_B,
            AUTO_EOM_LRES_B     => AUTO_EOM_LRES_B,
            AUTO_RTS_B          => AUTO_RTS_B,
            TxD_PULLED_HIGH_B   => TxD_PULLED_HIGH_B,
            FAST_DTR_B          => FAST_DTR_B,
            CRC_CHECK_RCVD_B    => CRC_CHECK_RCVD_B,
            SYNC_SDLC_ADR_B     => SYNC_SDLC_ADR_B,
            SYNC_SDLC_FLAG_B    => SYNC_SDLC_FLAG_B,
            Tx_CRC_EN_B         => Tx_CRC_EN_B,
            RTS_B               => RTS_B,
            CRC16_SDLCn_B       => CRC16_SDLCn_B,
            Tx_EN_B             => Tx_EN_B,
            SEND_BREAK_B        => SEND_BREAK_B,
            Tx_BITS_B           => Tx_BITS_B,
            DTR_B               => DTR_B,
            PAR_EN_B            => PAR_EN_B,
            PAR_EVEN_ODDn_B     => PAR_EVEN_ODDn_B,
            SYNC_MODE_B         => SYNC_MODE_B,
            SYNC_CHAR_B         => SYNC_CHAR_B,
            CLK_MODE_B          => CLK_MODE_B,
            EXT_INT_EN_B        => EXT_INT_EN_B,
            Tx_INT_EN_B         => Tx_INT_EN_B,
            PAR_S_COND_B        => PAR_S_COND_B,
            Rx_INT_MODE_B       => Rx_INT_MODE_B,
            DMA_REQ_MODE_B      => DMA_REQ_MODE_B,
            Rx_EN_B             => Rx_EN_B,
            SYNC_CHAR_INH_B     => SYNC_CHAR_INH_B,
            ADR_SEARCH_MODE_B   => ADR_SEARCH_MODE_B,
            Rx_CRC_EN_B         => Rx_CRC_EN_B,
            ENTER_HUNT_MODE_B   => ENTER_HUNT_MODE_B,
            AUTO_EN_B           => AUTO_EN_B,
            Rx_BITS_B           => Rx_BITS_B,
            TCB                 => TCB,
                                
            STATUS_A            => STATUS_A,
            STATUS_B            => STATUS_B,
            INT_VECT            => INT_VECT,
            INTACKn_INH         => INTACKn_INH,
            MIE                 => MIE,
            DLC                 => DLC,
            NV                  => NV,
            RESET               => RESET,
            SEND_ABORT_A        => SEND_ABORT_A,
            EN_INT_RxCHAR_A     => EN_INT_RxCHAR_A,
            RES_EXT_STAT_INT_A  => RES_EXT_STAT_INT_A,
            RES_TxINT_A         => RES_TxINT_A,
            RES_ERR_A           => RES_ERR_A,         
            RES_IUS_A           => RES_IUS_A,         
            RES_Rx_CRC_A        => RES_Rx_CRC_A,      
            RES_Tx_CRC_A        => RES_Tx_CRC_A,      
            RES_Tx_UR_EOM_A     => RES_Tx_UR_EOM_A,
            SEND_ABORT_B        => SEND_ABORT_B,
            EN_INT_RxCHAR_B     => EN_INT_RxCHAR_B,
            RES_EXT_STAT_INT_B  => RES_EXT_STAT_INT_B,
            RES_TxINT_B         => RES_TxINT_B,
            RES_ERR_B           => RES_ERR_B,         
            RES_IUS_B           => RES_IUS_B,         
            RES_Rx_CRC_B        => RES_Rx_CRC_B,      
            RES_Tx_CRC_B        => RES_Tx_CRC_B,      
            RES_Tx_UR_EOM_B     => RES_Tx_UR_EOM_B,
            BUFFER_A_IN         => BUFFER_A_IN,
            BUFFER_A_OUT        => BUFFER_A_OUT,
            BUFFER_B_IN         => BUFFER_B_IN,
            BUFFER_B_OUT        => BUFFER_B_OUT,
            RRA0_RD             => RRA0_RD,
            RRB0_RD             => RRB0_RD,
            RRA1_RD             => RRA1_RD,
            RRB1_RD             => RRB1_RD,
            RRA6_RD             => RRA6_RD,
            RRA7_RD             => RRA7_RD,
            RRB6_RD             => RRB6_RD,
            RRB7_RD             => RRB7_RD,
            RRA8_RD             => RRA8_RD,
            WRA8_WR             => WRA8_WR,
            RRB8_RD             => RRB8_RD,
            WRB8_WR             => WRB8_WR
        );


    I_TRANSCEIVER_A: TRANSCEIVER
        port map(
            CLK                 => PCLK,

            RxD                 => RxDA,
            TxD                 => TxDA,

            TRxC_INn            => TRxCA_INn,
            TRxC_OUTn           => TRxCA_OUTn,
            TRxC_EN             => TRxCA_EN,
            RTxCn               => RTxCAn,

            SYNC_IN             => SYNCA_IN,
            SYNC_OUT            => SYNCA_OUT,
            SYNC_EN             => SYNCA_EN,
            Wn_REQn             => Wn_REQAn,

            ONE_CLK_MISS        => ONE_CLK_MISS_A,
            TWO_CLK_MISS        => TWO_CLK_MISS_A,
            LOOP_SEND           => LOOP_SEND_A,
            ON_LOOP             => ON_LOOP_A,
            DCDn                => DCDAn,
            CTSn                => CTSAn,
            Rx_IP               => Rx_IP_A,
            Tx_IP               => Tx_IP_A,
            EXT_STAT_IP         => EXT_STAT_IP_A,

            BREAK_ABORT_IE      => BREAK_ABORT_IE_A,
            EOM_IE              => EOM_IE_A,
            CTS_IE              => CTS_IE_A,
            SYNC_HUNT_IE        => SYNC_HUNT_IE_A,
            DCD_IE              => DCD_IE_A,
            FRAME_FIFO_EN       => FRAME_FIFO_EN_B,
            ZCOUNT_IE           => ZCOUNT_IE_A,
            SDLC_HDLC           => SDLC_HDLC_A,
            DPLL_COMMAND        => DPLL_COMMAND_A,
            LOOPBACK            => LOOPBACK_A,
            AUTO_ECHO           => AUTO_ECHO_A,
            BR_GEN_SRC          => BR_GEN_SRC_A,
            BR_GEN_EN           => BR_GEN_EN_A,
            XTAL                => XTAL_A,
            Rx_CLK_SEL          => Rx_CLK_SEL_A,
            Tx_CLK_SEL          => Tx_CLK_SEL_A,
            TRXCn_SEL           => TRXCn_SEL_A,
            CRC_PRES            => CRC_PRES_A,
            NRZ_FM              => NRZ_FM_A,
            GO_ACTIVE_ON_POLL   => GO_ACTIVE_ON_POLL_A,
            MARK_FLAGn          => MARK_FLAGn_A,
            ABORT_FLAGn         => ABORT_FLAGn_A,
            LOOP_MODE           => LOOP_MODE_A,
            B6_B8n              => B6_B8n_A,
            RES                 => RES_A,
            AUTO_Tx_FLAG        => AUTO_Tx_FLAG_A,
            AUTO_EOM_LRES       => AUTO_EOM_LRES_A,
            AUTO_RTS            => AUTO_RTS_A,
            TxD_PULLED_HIGH     => TxD_PULLED_HIGH_A,
            FAST_DTR            => FAST_DTR_A,
            CRC_CHECK_RCVD      => CRC_CHECK_RCVD_A,
            SYNC_SDLC_ADR       => SYNC_SDLC_ADR_A,
            SYNC_SDLC_FLAG      => SYNC_SDLC_FLAG_A,
            Tx_CRC_EN           => Tx_CRC_EN_A,
            RTS                 => RTS_A,
            RTSn                => RTSAn,
            CRC16_SDLCn         => CRC16_SDLCn_A,
            Tx_EN               => Tx_EN_A,
            SEND_BREAK          => SEND_BREAK_A,
            Tx_BITS             => Tx_BITS_A,
            DTRn_REQn           => DTRn_REQn_A,
            PAR_EN              => PAR_EN_A,
            PAR_EVEN_ODDn       => PAR_EVEN_ODDn_A,
            SYNC_MODE           => SYNC_MODE_A,
            SYNC_CHAR           => SYNC_CHAR_A,
            CLK_MODE            => CLK_MODE_A,
            EXT_INT_EN          => EXT_INT_EN_A,
            Tx_INT_EN           => Tx_INT_EN_A,
            PAR_S_COND          => PAR_S_COND_A,
            Rx_INT_MODE         => Rx_INT_MODE_A,
            DTRn_REQ            => DTRn_REQ_A,
            DMA_REQ_MODE        => DMA_REQ_MODE_A,
            Rx_EN               => Rx_EN_A,
            SYNC_CHAR_INH       => SYNC_CHAR_INH_A,
            ADR_SEARCH_MODE     => ADR_SEARCH_MODE_A,
            Rx_CRC_EN           => Rx_CRC_EN_A,
            ENTER_HUNT_MODE     => ENTER_HUNT_MODE_A,
            AUTO_EN             => AUTO_EN_A,
            Rx_BITS             => Rx_BITS_A,
            TC                  => TCA,
            INTACKn_INH         => INTACKn_INH,
            MIE                 => MIE,
            DLC                 => DLC,
            INT_ACK             => INT_ACK,
            IEI                 => IEI,
            INT                 => INT_A,
            STATUS              => STATUS_A,
            RESET               => RESET,
            SEND_ABORT          => SEND_ABORT_A,
            EN_INT_RxCHAR       => EN_INT_RxCHAR_A,
            RES_EXT_STAT_INT    => RES_EXT_STAT_INT_A,
            RES_TxINT           => RES_TxINT_A,
            RES_ERR             => RES_ERR_A,         
            RES_IUS             => RES_IUS_A,         
            RES_Rx_CRC          => RES_Rx_CRC_A,      
            RES_Tx_CRC          => RES_Tx_CRC_A,      
            RES_Tx_UR_EOM       => RES_Tx_UR_EOM_A,
            BUFFER_IN           => BUFFER_A_OUT,
            BUFFER_OUT          => BUFFER_A_IN,
            RR0_RD              => RRA0_RD,
            RR1_RD              => RRA1_RD,
            RR6_RD              => RRA6_RD,
            RR7_RD              => RRA7_RD,
            RR8_RD              => RRA8_RD,
            WR8_WR              => WRA8_WR
        );

    I_TRANSCEIVER_B: TRANSCEIVER
        port map(
            CLK                 => PCLK,

            RxD                 => RxDB,
            TxD                 => TxDB,

            TRxC_INn            => TRxCB_INn,
            TRxC_OUTn           => TRxCB_OUTn,
            TRxC_EN             => TRxCB_EN,
            RTxCn               => RTxCBn,

            SYNC_IN             => SYNCB_IN,
            SYNC_OUT            => SYNCB_OUT,
            SYNC_EN             => SYNCB_EN,
            Wn_REQn             => Wn_REQBn,

            ONE_CLK_MISS        => ONE_CLK_MISS_B,
            TWO_CLK_MISS        => TWO_CLK_MISS_B,
            LOOP_SEND           => LOOP_SEND_B,
            ON_LOOP             => ON_LOOP_B,
            DCDn                => DCDBn,
            CTSn                => CTSBn,
            Rx_IP               => Rx_IP_B,
            Tx_IP               => Tx_IP_B,
            EXT_STAT_IP         => EXT_STAT_IP_B,

            BREAK_ABORT_IE      => BREAK_ABORT_IE_B,
            EOM_IE              => EOM_IE_B,
            CTS_IE              => CTS_IE_B,
            SYNC_HUNT_IE        => SYNC_HUNT_IE_B,
            DCD_IE              => DCD_IE_B,
            FRAME_FIFO_EN       => FRAME_FIFO_EN_CHB,
            ZCOUNT_IE           => ZCOUNT_IE_B,
            SDLC_HDLC           => SDLC_HDLC_B,
            DPLL_COMMAND        => DPLL_COMMAND_B,
            LOOPBACK            => LOOPBACK_B,
            AUTO_ECHO           => AUTO_ECHO_B,
            BR_GEN_SRC          => BR_GEN_SRC_B,
            BR_GEN_EN           => BR_GEN_EN_B,
            XTAL                => XTAL_B,
            Rx_CLK_SEL          => Rx_CLK_SEL_B,
            Tx_CLK_SEL          => Tx_CLK_SEL_B,
            TRXCn_SEL           => TRXCn_SEL_B,
            CRC_PRES            => CRC_PRES_B,
            NRZ_FM              => NRZ_FM_B,
            GO_ACTIVE_ON_POLL   => GO_ACTIVE_ON_POLL_B,
            MARK_FLAGn          => MARK_FLAGn_B,
            ABORT_FLAGn         => ABORT_FLAGn_B,
            LOOP_MODE           => LOOP_MODE_B,
            B6_B8n              => B6_B8n_B,
            RES                 => RES_B,
            AUTO_Tx_FLAG        => AUTO_Tx_FLAG_B,
            AUTO_EOM_LRES       => AUTO_EOM_LRES_B,
            AUTO_RTS            => AUTO_RTS_B,
            TxD_PULLED_HIGH     => TxD_PULLED_HIGH_B,
            FAST_DTR            => FAST_DTR_B,
            CRC_CHECK_RCVD      => CRC_CHECK_RCVD_B,
            SYNC_SDLC_ADR       => SYNC_SDLC_ADR_B,
            SYNC_SDLC_FLAG      => SYNC_SDLC_FLAG_B,
            Tx_CRC_EN           => Tx_CRC_EN_B,
            RTS                 => RTS_B,
            RTSn                => RTSBn,
            CRC16_SDLCn         => CRC16_SDLCn_B,
            Tx_EN               => Tx_EN_B,
            SEND_BREAK          => SEND_BREAK_B,
            Tx_BITS             => Tx_BITS_B,
            DTRn_REQn           => DTRn_REQn_B,
            PAR_EN              => PAR_EN_B,
            PAR_EVEN_ODDn       => PAR_EVEN_ODDn_B,
            SYNC_MODE           => SYNC_MODE_B,
            SYNC_CHAR           => SYNC_CHAR_B,
            CLK_MODE            => CLK_MODE_B,
            EXT_INT_EN          => EXT_INT_EN_B,
            Tx_INT_EN           => Tx_INT_EN_B,
            PAR_S_COND          => PAR_S_COND_B,
            Rx_INT_MODE         => Rx_INT_MODE_B,
            DTRn_REQ            => DTRn_REQ_B,
            DMA_REQ_MODE        => DMA_REQ_MODE_B,
            Rx_EN               => Rx_EN_B,
            SYNC_CHAR_INH       => SYNC_CHAR_INH_B,
            ADR_SEARCH_MODE     => ADR_SEARCH_MODE_B,
            Rx_CRC_EN           => Rx_CRC_EN_B,
            ENTER_HUNT_MODE     => ENTER_HUNT_MODE_B,
            AUTO_EN             => AUTO_EN_B,
            Rx_BITS             => Rx_BITS_B,
            TC                  => TCB,
            INTACKn_INH         => INTACKn_INH,
            MIE                 => MIE,
            DLC                 => DLC,
            INT_ACK             => INT_ACK,
            IEI                 => IEI,
            INT                 => INT_B,
            STATUS              => STATUS_B,
            RESET               => RESET,
            SEND_ABORT          => SEND_ABORT_B,
            EN_INT_RxCHAR       => EN_INT_RxCHAR_B,
            RES_EXT_STAT_INT    => RES_EXT_STAT_INT_B,
            RES_TxINT           => RES_TxINT_B,
            RES_ERR             => RES_ERR_B,         
            RES_IUS             => RES_IUS_B,         
            RES_Rx_CRC          => RES_Rx_CRC_B,      
            RES_Tx_CRC          => RES_Tx_CRC_B,      
            RES_Tx_UR_EOM       => RES_Tx_UR_EOM_B,
            BUFFER_IN           => BUFFER_B_OUT,
            BUFFER_OUT          => BUFFER_B_IN,
            RR0_RD              => RRB0_RD,
            RR1_RD              => RRB1_RD,
            RR6_RD              => RRB6_RD,
            RR7_RD              => RRB7_RD,
            RR8_RD              => RRB8_RD,
            WR8_WR              => WRB8_WR
        );
end architecture STRUCTURE;
