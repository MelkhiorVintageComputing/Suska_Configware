------------------------------------------------------------------------
----                                                                ----
---- Serial Communication Controller SCC_85C30 IP Core              ----
----                                                                ----
---- This model provides an asynchronous SCSI interface compa-      ----
---- tible to the Am85C30 from AMD or ESCC 85C30 from Zilog.        ----
---- This core features all functions of their originals except the ----
---- oscillator for external crystals.                              ----
----                                                                ----
---- This file covers the transceiver section of the SCC chip.      ----
----                                                                ----
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
use ieee.numeric_std.all;

entity TRANSCEIVER is

    port(
        CLK                 : in std_logic;

        -- Serial Data:
        RxD                 : in std_logic;
        TxD                 : out std_logic;

        -- Channel clocks:
        TRxC_INn            : in std_logic;
        TRxC_OUTn           : out std_logic;
        TRxC_EN             : out std_logic;
        RTxCn               : in std_logic;

        -- Channel controls:CRC_SHIFT_16
        SYNC_IN             : in std_logic;
        SYNC_OUT            : out std_logic;
        SYNC_EN             : out std_logic;
        Wn_REQn             : out std_logic;

        -- Control signals:
        ONE_CLK_MISS        : buffer std_logic;
        TWO_CLK_MISS        : out std_logic;
        LOOP_SEND           : out std_logic;
        ON_LOOP             : buffer std_logic;

        DCDn                : in std_logic;
        CTSn                : in std_logic;
        Rx_IP               : buffer std_logic;
        Tx_IP               : buffer std_logic;
        EXT_STAT_IP         : buffer std_logic;

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
        CRC_PRES            : in std_logic;
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
end entity TRANSCEIVER;

architecture BEHAVIOUR of TRANSCEIVER is
type CLK_MULTIPLIER is(CLK_64, CLK_32, CLK_16, CLK_1);
type OPMODES is(ASYNC, MSYNC, BSYNC, SDLC);
type FIFOTYPE is array(1 to 3) of std_logic_vector(15 downto 0);
type FRAME_FIFO_TYPE is array(0 to 9) of std_logic_vector(18 downto 0);
type Rx_STATES is(IDLE, Rx_HUNT, Rx_CLKSYNC, PIPE_3B, Rx_LOOP_INIT, Rx_SHIFTIN, Rx_SHIFTIN_3B, Rx_CHECK_FRAME);
type Tx_STATES is(IDLE, Tx_START, Tx_MARK_IDLE, Tx_SYNC_1, Tx_SYNC_2, Tx_SHIFTOUT, Tx_STOP_1, Tx_STOP_2, Tx_CRC, Tx_ABORT_FLAG, Tx_ABORT, Tx_CLOSE);
signal Rx_STATE             : Rx_STATES;
signal Rx_NSTATE            : Rx_STATES; -- Next state.
signal Tx_STATE             : Tx_STATES;
signal Tx_NSTATE            : Tx_STATES; -- Next state.
signal OPMODE               : OPMODES;
signal ABORT                : std_logic;
signal ALL_SENT             : std_logic;
signal BREAK                : std_logic;
signal BREAK_ABORT          : std_logic;
signal BRG_OUT              : std_logic;
signal CLK_MUL              : CLK_MULTIPLIER;
signal CRC_ERR              : std_logic;
signal CRC_FRAME_ERR        : std_logic;
signal CTS                  : std_logic;
signal DCD                  : std_logic;
signal EOF                  : std_logic;
signal EOP                  : std_logic;
signal EXT_SYNC             : std_logic;
signal EXT_STATUS_INT       : std_logic;
signal FIFO_EMPTY           : std_logic;
signal FIFO_WR              : std_logic;
signal FIFO_WR_SYNCMODES    : std_logic;
signal FIFO_REG             : FIFOTYPE;
signal FIFO_WR_PNT          : natural range 0 to 3;
signal FRAME_BYTE_COUNTER   : std_logic_vector(13 downto 0);
signal FRAME_FIFO           : FRAME_FIFO_TYPE;
signal FRAME_FIFO_ADR       : std_logic_vector(3 downto 0);
signal FRAME_FIFO_DIN       : std_logic_vector(18 downto 0);
signal FRAME_FIFO_DOUT      : std_logic_vector(18 downto 0);
signal FRAME_FIFO_EMPTY     : std_logic;
signal FRAME_FIFO_HEAD      : std_logic_vector(3 downto 0);
signal FRAME_FIFO_TAIL      : std_logic_vector(3 downto 0);
signal FRAME_FIFO_WR        : std_logic;
signal FRAME_FIFO_RD        : std_logic;
signal FRAME_FIFO_OVERFLOW  : std_logic;
signal IUS                  : std_logic;
signal NRZI_IN              : std_logic;
signal PARITY_ERR           : std_logic;
signal RESIDUE_BITS         : std_logic_vector(2 downto 0);
signal RTxC_I               : std_logic;
signal Rx_CLK               : std_logic;
signal Rx_DPLL_OUT          : std_logic;
signal Rx_ERROR             : std_logic_vector(7 downto 0);
signal Rx_INH               : std_logic;
signal Rx_LEN               : integer range 1 to 8;
signal Rx_OVR               : std_logic;
signal Rx_PARITY            : std_logic;
signal Rx_SCOND             : std_logic;
signal Rx_SHFT_RDY          : std_logic;
signal Rx_SHIFTREG          : std_logic_vector(7 downto 0); -- Data and parity.
signal RxD_D                : std_logic;
signal RxD_I                : std_logic;
signal RxD_NRZI             : std_logic;
signal RxD_SR               : std_logic;
signal Rx_STRB              : std_logic;
signal RxD_SR_3B            : std_logic;
signal SDLC_ADDRESS_FAIL    : std_logic;
signal SOF                  : std_logic;
signal SYNC_HUNT            : std_logic;
signal SYNC_IN_I            : std_logic;
signal Tx_PARITY            : std_logic;
signal TRxC_I               : std_logic;
signal Tx_BUFFER            : std_logic_vector(7 downto 0);
signal Tx_BUFFER_EMPTY      : std_logic;
signal Tx_CLK               : std_logic;
signal Tx_DPLL_OUT          : std_logic;
signal Tx_INH               : std_logic;
signal Tx_LEN               : integer range 1 to 8;
signal Tx_NRZI              : std_logic;
signal Tx_SHFT_RDY          : std_logic;
signal Tx_SR_DATAIN         : std_logic_vector(15 downto 0);
signal Tx_STRB              : std_logic;
signal Tx_UNDERRUN_EOM      : std_logic;
signal TxD_I                : std_logic;
signal TxD_SR               : std_logic;
signal ZCOUNT               : std_logic;
begin
    P_SYNC: process
    begin
        wait until CLK = '1' and CLK' event;
        if AUTO_EN = '1' and LOOPBACK = '0' then
            Rx_INH <= DCDn;
            Tx_INH <= CTSn;
        else -- Always on.
            Rx_INH <= '0';
            Tx_INH <= '0';
        end if;

        if AUTO_ECHO = '1' then
            Tx_INH <= '0';
        end if;

        if RESET = '1' or RES = '1' then
            RTxC_I <= '0';
            TRxC_I <= '0';
        end if;

        RxD_D <= RxD; -- One bit input synchronization.
        RTxC_I <= not RTxCn;
        TRxC_I <= not TRxC_INn;
        SYNC_IN_I <= SYNC_IN;
    end process P_SYNC;

    SYNC_OUT <= not RTxCn when XTAL = '1' else -- This is the crystal oscillator feedback.
                '1' when OPMODE = SDLC and (SOF or EOF) = '1' else
                '1' when (OPMODE = BSYNC or OPMODE = MSYNC) and (SOF or EOF) = '1' else '0';

    SYNC_EN <= '1' when XTAL = '1' else -- Crystal oscillator is enabled.
               '1' when OPMODE /= ASYNC and SYNC_CHAR /= "11" else '0'; -- Synchronous mode except external sync.

    -- Echo mode:
    TRxC_EN <= TRXCn_SEL(2);

    with TRXCn_SEL(1 downto 0) select
        TRxC_OUTn <= not RTxC_I when "00",
                     not Tx_CLK when "01",
                     not BRG_OUT when "10",
                     not Rx_DPLL_OUT when others;

    CLK_MUL <= CLK_1 when OPMODE /= ASYNC and SYNC_CHAR /= "11" else -- Synchronous mode except external sync.
               CLK_64 when CLK_MODE = "11" else
               CLK_32 when CLK_MODE = "10" else
               CLK_16 when CLK_MODE = "01" else CLK_1;

    with Rx_CLK_SEL select
        Rx_CLK <= RTxC_I when "00",
                  TRxC_I when "01",
                  BRG_OUT when "10",
                  Rx_DPLL_OUT when others;

    with Tx_CLK_SEL select
        Tx_CLK <= RTxC_I when "00",
                  TRxC_I when "01",
                  BRG_OUT when "10",
                  Tx_DPLL_OUT when others;

    Rx_STROBE: process
    -- This is the clock strobe for the receive shift register.
    -- The data is sampled on the rising edge of the receive
    -- clock. The sampling time is in the middle of the bit cell
    -- when the clock multiplier is 16, 32 or 64. In case of a
    -- clock multiplier of 1 the strobe reflects the rising edge
    -- of the receiver clock.
    variable LOCK           : boolean;
    variable Rx_PRESCALE    : std_logic_vector(5 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        Rx_STRB <= '0';

        if Rx_STATE = IDLE then
            case CLK_MUL is
                when CLK_64 => Rx_PRESCALE := "011111"; -- Half the selected period.
                when CLK_32 => Rx_PRESCALE := "001111"; -- Half the selected period.
                when CLK_16 => Rx_PRESCALE := "000111"; -- Half the selected period.
                when CLK_1 =>  Rx_PRESCALE := "000000"; -- Dummy, not used.
            end case;
        elsif Rx_CLK = '1' and LOCK = false then
            LOCK := true;
            case CLK_MUL is
                when CLK_64 =>
                    Rx_PRESCALE := Rx_PRESCALE - '1';
                    if Rx_PRESCALE = "000000" then
                        Rx_STRB <= '1';
                    end if;
                when CLK_32 =>
                    if Rx_PRESCALE = "000000" then
                        Rx_STRB <= '1';
                        Rx_PRESCALE := "011111";
                    else
                        Rx_PRESCALE := Rx_PRESCALE - '1';
                    end if;
                when CLK_16 =>
                    if Rx_PRESCALE = "000000" then
                        Rx_STRB <= '1';
                        Rx_PRESCALE := "001111";
                    else
                        Rx_PRESCALE := Rx_PRESCALE - '1';
                    end if;
                when CLK_1 =>
                    Rx_STRB <= '1';
            end case;
        elsif Rx_CLK = '0' then
            LOCK := false;
        end if;
    end process Rx_STROBE;

    Tx_STROBE: process
    -- This is the clock strobe for the transmit shift register.
    -- The data is shifted on the falling edge of the transmit
    -- clock.
    variable LOCK           : boolean;
    variable Tx_PRESCALE    : std_logic_vector(5 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        Tx_STRB <= '0';
        if Tx_EN = '0' then
            Tx_PRESCALE := "000000";
        elsif Tx_CLK = '0' and LOCK = false then
            LOCK := true;
            case CLK_MUL is
                when CLK_64 =>
                    Tx_PRESCALE := Tx_PRESCALE - '1';
                    if Tx_STATE = Tx_STOP_2 and SYNC_MODE = "10" and Tx_PRESCALE = "011111" then -- 1.5 stop bits.
                        Tx_STRB <= '1';
                    elsif Tx_PRESCALE = "000000" then
                        Tx_STRB <= '1';
                    end if;
                when CLK_32 =>
                    if Tx_STATE = Tx_STOP_2 and SYNC_MODE = "10" and Tx_PRESCALE = "001111" then -- 1.5 stop bits.
                        Tx_STRB <= '1';
                        Tx_PRESCALE := Tx_PRESCALE - '1';
                    elsif Tx_PRESCALE = "000000" then
                        Tx_STRB <= '1';
                        Tx_PRESCALE := "011111";
                    else
                        Tx_PRESCALE := Tx_PRESCALE - '1';
                    end if;
                when CLK_16 =>
                    if Tx_STATE = Tx_STOP_2 and SYNC_MODE = "10" and Tx_PRESCALE = "000111" then -- 1.5 stop bits.
                        Tx_STRB <= '1';
                        Tx_PRESCALE := Tx_PRESCALE - '1';
                    elsif Tx_PRESCALE = "000000" then
                        Tx_STRB <= '1';
                        Tx_PRESCALE := "001111";
                    else
                        Tx_PRESCALE := Tx_PRESCALE - '1';
                    end if;
                when CLK_1 =>
                    Tx_STRB <= '1';
            end case;
        elsif Tx_CLK = '1' then
            LOCK := false;
        end if;
    end process Tx_STROBE;

    BAUDRATE_GENERATOR: process
    -- This is the SCCs baude rate generator.
    variable BRG_CNT    : std_logic_vector(15 downto 0);
    variable LOCK       : boolean;
    variable STARTLOCK  : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if (RESET or RES) = '1' then
            ZCOUNT <= '0';
            BRG_OUT <= '1';
            STARTLOCK := false;
        elsif BR_GEN_EN = '0' then
            BRG_CNT := TC;
            ZCOUNT <= '0';
            BRG_OUT <= '1';
            LOCK := true;
            STARTLOCK := false;
        elsif BR_GEN_SRC = '0' and RTxC_I = '0' and STARTLOCK = false then
                STARTLOCK := true; -- Wait for initial condition.
        elsif BR_GEN_SRC = '0' and STARTLOCK = true then -- Use RTxC as clock source.
            if RTxC_I = '1' and LOCK = false and BRG_CNT > x"0000" then
                BRG_CNT := BRG_CNT - '1';
                ZCOUNT <= '0';
                LOCK := true;
            elsif RTxC_I = '1' and LOCK = false then
                BRG_CNT := TC;
                ZCOUNT <= '1';
                BRG_OUT <= not BRG_OUT;
                LOCK := true;
            elsif RTxC_I = '0' then
                LOCK := false;
            end if;
        elsif BR_GEN_SRC = '1' then -- Use CLK as clock source.
            if BRG_CNT > x"0000" then
                BRG_CNT := BRG_CNT - '1';
                ZCOUNT <= '0';
            else
                BRG_CNT := TC;
                ZCOUNT <= '1';
                BRG_OUT <= not BRG_OUT;
            end if;
        end if;

        if ZCOUNT_IE = '0' then
            ZCOUNT <= '0'; -- Disable ZCOUNT interrupt source.
        end if;
    end process BAUDRATE_GENERATOR;

    P_DPLL: process
    -- This is the digital phase locked loop section of the SCC.
    -- It is provided to handle the baud rate clock or the receiver
    -- clock smaller than the system clock. For 32MHz receiver
    -- clock operation stated out in the original data sheet, the core
    -- clock is for example 48MHz or 64 MHz. The reason for this is
    -- to meet the rules for setup / hold times which are handled in
    -- this case in one common clock domain and to avoid asynchronous
    -- settings and latches.

    -- The DPLL commands are as follows:
    -- "000" = Null command.
    -- "001" = Enter search mode.
    -- "010" = Reset missing clock.
    -- "011" = Disable DPLL.
    -- "100" = Set source = baud rate generator.
    -- "101" = Set source = RTxC.
    -- "110" = Set FM mode.
    -- "111" = Set NRZI mode.
    variable SRC_BRG_RTxCn  : std_logic;
    variable MODE_FM_NRZIn  : std_logic;
    variable DPLL_EN        : std_logic;
    variable EDGE_DETECT    : std_logic_vector(1 downto 0);
    variable SEARCHMODE     : std_logic;
    variable LOCK           : boolean;
    variable SWITCH         : std_logic;
    variable COUNTER        : std_logic_vector(4 downto 0);
    variable MODIFIER       : std_logic_vector(1 downto 0);
    variable FM_EDGE        : std_logic;
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' or RES = '1' then
            DPLL_EN := '0';
        end if;

        case DPLL_COMMAND is
            when "000" => -- Null command.
                if SWITCH = '1' then
                    DPLL_EN := '1'; -- Switch right in the end of command "001".
                end if;
                SWITCH := '0';
            when "001" => -- Enter search mode.
                SWITCH := '1';
                if DPLL_EN = '1' then
                    SEARCHMODE := '1';
                end if;
                ONE_CLK_MISS <= '0';
                TWO_CLK_MISS <= '0';
            when "010" => -- Reset missing clock.
                ONE_CLK_MISS <= '0';
                TWO_CLK_MISS <= '0';
            when "011" => -- Disable DPLL.
                DPLL_EN := '0';
            when "100" => -- Set source = baud rate generator.
                SRC_BRG_RTxCn := '1';
            when "101" => -- Set source = RTxC.
                SRC_BRG_RTxCn := '0';
            when "110" => -- Set FM mode.
                MODE_FM_NRZIn := '1';
            when "111" => -- Set NRZI mode.
                MODE_FM_NRZIn := '0';
            when others =>
                null; -- Do nothing.
        end case;

        if DPLL_EN = '0' then
            EDGE_DETECT := "00";
            SEARCHMODE := '0';
            Rx_DPLL_OUT <= '0';
            Tx_DPLL_OUT <= '0';
            COUNTER := "00000";
            MODIFIER := "00";
            ONE_CLK_MISS <= '0';
            TWO_CLK_MISS <= '0';
            SRC_BRG_RTxCn := '0';
            MODE_FM_NRZIn := '0';
        elsif SEARCHMODE = '1' and (EDGE_DETECT(1) xor EDGE_DETECT(0)) = '1' then -- Detect positive or negative edge.
            SEARCHMODE := '0';
            Rx_DPLL_OUT <= '1';
            Tx_DPLL_OUT <= '1';
            COUNTER := "10000";
            MODIFIER := "00";
        elsif SEARCHMODE = '1' then
            EDGE_DETECT := EDGE_DETECT(0) & RxD_D;
            COUNTER := "10000";
            MODIFIER := "00";
            FM_EDGE := '0';
            if MODE_FM_NRZIn = '0' then -- NRZI.
                Rx_DPLL_OUT <= '1';
                Tx_DPLL_OUT <= '1';
            else -- FM.
                Rx_DPLL_OUT <= '0';
                Tx_DPLL_OUT <= '0';
            end if;
        else
            if (EDGE_DETECT(1) xor EDGE_DETECT(0)) = '1' then -- Adjust phase.
                if MODE_FM_NRZIn = '0' then -- NRZI.
                    if COUNTER > "10000" then
                        MODIFIER := "01";  -- Add one.
                    elsif COUNTER < "01111" then
                        MODIFIER := "11";  -- Subtract one.
                    end if;
                else -- FM.
                    case COUNTER is
                        when "10001" | "10010" | "10011" =>
                            MODIFIER := "01";  -- Add one.
                        when "01100" | "01101" | "01110" =>
                            MODIFIER := "11";  -- Subtract one.
                        when others => null;
                    end case;
                end if;
            elsif ((SRC_BRG_RTxCn = '1' and BRG_OUT = '1') or (SRC_BRG_RTxCn = '0' and RTXC_I = '1')) and LOCK = false then
                if MODIFIER = "01" and COUNTER = "00100" then -- Add.
                    COUNTER := "00110"; -- Delete count five.
                    MODIFIER := "00";
                elsif MODIFIER = "11" and COUNTER = "00101" then -- Sub.
                    COUNTER := "00101"; -- Double count five.
                    MODIFIER := "00";
                else
                    COUNTER := COUNTER + '1';
                end if;

                if MODE_FM_NRZIn = '0' then -- This logic is exclusively for FM.
                    SEARCHMODE := '0';
                elsif COUNTER >= "01100" and COUNTER < "10011" and (EDGE_DETECT(1) xor EDGE_DETECT(0)) = '1' then
                    FM_EDGE := '1'; -- Edge detected.
                elsif COUNTER = "10100" and FM_EDGE = '0' and ONE_CLK_MISS = '0' then -- No edge detected.
                    ONE_CLK_MISS <= '1'; -- First missing edge.
                    FM_EDGE := '0'; -- Re-initialize.
                elsif COUNTER = "11111" and FM_EDGE = '0' then -- No edge detected.
                    SEARCHMODE := '1'; -- Two bitcells without edge, enter searchmode.
                    TWO_CLK_MISS <= '1';
                end if;
                LOCK := true;
            elsif (SRC_BRG_RTxCn = '1' and BRG_OUT = '0') or (SRC_BRG_RTxCn = '0' and RTXC_I = '0') then
                LOCK := false;
            end if;

            if MODE_FM_NRZIn = '0' then -- NRZI.
                if COUNTER < "10000" then
                    Rx_DPLL_OUT <= '0';
                    Tx_DPLL_OUT <= '0';
                else
                    Rx_DPLL_OUT <= '1';
                    Tx_DPLL_OUT <= '1';
                end if;
            else -- FM.
                case COUNTER is
                    when "00000" | "00001" | "00010" | "00011" | "10000" | "10001" | "10010" | "10011" =>
                        Rx_DPLL_OUT <= '0';
                        Tx_DPLL_OUT <= '0';
                    when "00100" | "00101" | "00110" | "00111" | "10100" | "10101" | "10110" | "10111" =>
                        Rx_DPLL_OUT <= '1';
                        Tx_DPLL_OUT <= '0';
                    when "01000" | "01001" | "01010" | "01011" | "11000" | "11001" | "11010" | "11011" =>
                        Rx_DPLL_OUT <= '1';
                        Tx_DPLL_OUT <= '1';
                    when others =>
                        Rx_DPLL_OUT <= '0';
                        Tx_DPLL_OUT <= '1';
                end case;
            end if;

            EDGE_DETECT := EDGE_DETECT(0) & RxD_D;
        end if;
    end process P_DPLL;

    STATE_REGISTERS: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' or RES = '1' or Rx_EN = '0' then
            Rx_STATE <= IDLE;
        else
            Rx_STATE <= Rx_NSTATE;
        end if;

        if RESET = '1' or RES = '1' then
            Tx_STATE <= IDLE;
        else
            Tx_STATE <= Tx_NSTATE;
        end if;
    end process STATE_REGISTERS;

    Rx_STATE_DECODER: process(ABORT, CRC_CHECK_RCVD, ENTER_HUNT_MODE, EOF, EOP, EXT_SYNC, LOOP_MODE, GO_ACTIVE_ON_POLL, Rx_STATE, Rx_EN, OPMODE, RxD, RxD_D, Rx_STRB, 
                              Rx_SHFT_RDY, SDLC_ADDRESS_FAIL, Rx_LEN, RxD_SR_3B, SOF, SYNC_IN_I)
    begin
        case Rx_STATE is
            when IDLE =>
                if OPMODE = ASYNC and RxD = '0' and RxD_D = '1' then -- Falling edge detected.
                    Rx_NSTATE <= Rx_CLKSYNC;
                elsif ENTER_HUNT_MODE = '1' then
                    Rx_NSTATE <= Rx_HUNT;
                elsif OPMODE = SDLC and LOOP_MODE = '1' then
                    Rx_NSTATE <= Rx_LOOP_INIT;
                else
                    Rx_NSTATE <= IDLE;
                end if;
            when Rx_LOOP_INIT =>
                if LOOP_MODE = '0' then
                    Rx_NSTATE <= IDLE;
                elsif GO_ACTIVE_ON_POLL = '1' and (EOP = '1' or ABORT = '1') then -- Seven consecutive ones detected.
                    Rx_NSTATE <= Rx_HUNT;
                else
                    Rx_NSTATE <= Rx_LOOP_INIT;
                end if;
            when Rx_HUNT =>
                if OPMODE = ASYNC then
                    Rx_NSTATE <= IDLE;
                elsif (OPMODE = MSYNC or OPMODE = SDLC) and EXT_SYNC = '1' and SYNC_IN_I = '0' then
                    Rx_NSTATE <= Rx_SHIFTIN;
                elsif (OPMODE = MSYNC or OPMODE = SDLC) and EXT_SYNC = '1' then
                    Rx_NSTATE <= Rx_HUNT;
                elsif SOF = '1' then
                    Rx_NSTATE <= Rx_SHIFTIN;
                else
                    Rx_NSTATE <= Rx_HUNT;
                end if;
            when Rx_CLKSYNC => -- Wait half a bit cell.
                if Rx_STRB = '1' and RxD_D = '1' then
                    Rx_NSTATE <= IDLE; -- Not a start bit.
                elsif Rx_STRB = '1' and Rx_LEN > 6 then
                    Rx_NSTATE <= PIPE_3B;
                elsif Rx_STRB = '1' then
                    Rx_NSTATE <= Rx_SHIFTIN;
                else
                    Rx_NSTATE <= Rx_CLKSYNC;
                end if;
            -- PIPE_3B is intended for initially filling the three bit
            -- pipe after enabling the receiver unit. Once filled, the
            -- this state is used for detecting the start bit in case of
            -- multi byte transfer.
            when PIPE_3B =>
                if Rx_STRB = '1' and RxD_SR_3B = '0' then -- Startbit detected
                    Rx_NSTATE <= Rx_SHIFTIN;
                else
                    Rx_NSTATE <= PIPE_3B;
                end if;
            when Rx_SHIFTIN =>
                if OPMODE = ASYNC and Rx_SHFT_RDY = '1' then
                    Rx_NSTATE <= Rx_CHECK_FRAME;
                elsif (OPMODE = BSYNC or OPMODE = MSYNC) and ENTER_HUNT_MODE = '1' then
                    Rx_NSTATE <= Rx_HUNT;
                elsif OPMODE = SDLC and SDLC_ADDRESS_FAIL = '1' then
                    Rx_NSTATE <= Rx_HUNT;
                elsif OPMODE = SDLC and EXT_SYNC = '1' and SYNC_IN_I = '1' then
                    Rx_NSTATE <= IDLE;
                elsif OPMODE = SDLC and EXT_SYNC = '1' then
                    Rx_NSTATE <= Rx_SHIFTIN;
                elsif OPMODE = SDLC and EOP = '1' then
                    Rx_NSTATE <= Rx_HUNT;
                elsif OPMODE = SDLC and ABORT = '1' then
                    Rx_NSTATE <= Rx_HUNT;
                elsif OPMODE = SDLC and EOF = '1' and CRC_CHECK_RCVD = '1' then
                    Rx_NSTATE <= Rx_SHIFTIN_3B;
                elsif OPMODE = SDLC and EOF = '1' then
                    Rx_NSTATE <= Rx_HUNT;
                else
                    Rx_NSTATE <= Rx_SHIFTIN;
                end if;
            when Rx_SHIFTIN_3B => -- Shift in the last SDLC bits.
                if Rx_SHFT_RDY = '1' then
                    Rx_NSTATE <= Rx_HUNT;
                else
                    Rx_NSTATE <= Rx_SHIFTIN_3B;
                end if;
            when Rx_CHECK_FRAME => -- Used in asynchronous mode.
                if Rx_STRB = '1' and Rx_LEN > 6 then
                    Rx_NSTATE <= PIPE_3B;
                elsif Rx_STRB = '1' then
                    Rx_NSTATE <= IDLE;
                else
                    Rx_NSTATE <= Rx_CHECK_FRAME;
                end if;
        end case;
    end process Rx_STATE_DECODER;

    Tx_STATE_DECODER: process(ABORT_FLAGn, AUTO_Tx_FLAG, EOP, LOOP_MODE, MARK_FLAGn, OPMODE, Rx_STATE, SEND_ABORT, SYNC_MODE, Tx_BUFFER_EMPTY, Tx_CRC_EN, Tx_EN, Tx_SHFT_RDY, Tx_STATE, Tx_STRB, Tx_UNDERRUN_EOM)
    begin
        case Tx_STATE is
            when IDLE =>
                if Tx_EN = '0' then
                    Tx_NSTATE <= IDLE;
                elsif LOOP_MODE = '1' and Rx_STATE = Rx_HUNT and EOP = '1' then
                    Tx_NSTATE <= Tx_MARK_IDLE;
                elsif LOOP_MODE = '1' then
                    Tx_NSTATE <= IDLE;
                elsif OPMODE = ASYNC and Tx_BUFFER_EMPTY = '0' and Tx_STRB = '1' then
                    Tx_NSTATE <= Tx_START;
                elsif (OPMODE = BSYNC or OPMODE = MSYNC) and Tx_STRB = '1' then
                    Tx_NSTATE <= Tx_SYNC_1;
                elsif OPMODE = SDLC and Tx_STRB = '1' then
                    Tx_NSTATE <= Tx_MARK_IDLE;
                else
                    Tx_NSTATE <= IDLE;
                end if;
            when Tx_START =>
                if Tx_EN = '0' then
                    Tx_NSTATE <= IDLE;
                elsif Tx_STRB = '1' then
                    Tx_NSTATE <= Tx_SHIFTOUT;
                else
                    Tx_NSTATE <= Tx_START;
                end if;
            when Tx_MARK_IDLE =>
                if Tx_SHFT_RDY = '1' and Tx_EN = '0' then
                    Tx_NSTATE <= IDLE;
                elsif Tx_SHFT_RDY = '1' and MARK_FLAGn = '0' and LOOP_MODE = '0' then
                    Tx_NSTATE <= Tx_SYNC_1;
                elsif Tx_SHFT_RDY = '1' and AUTO_Tx_FLAG = '1' and Tx_BUFFER_EMPTY = '0' then
                    Tx_NSTATE <= Tx_SYNC_1;
                else
                    Tx_NSTATE <= Tx_MARK_IDLE;
                end if;
            when Tx_SYNC_1 =>
                if Tx_SHFT_RDY = '1' and Tx_EN = '0' then
                    Tx_NSTATE <= IDLE;
                elsif Tx_SHFT_RDY = '1' and OPMODE = BSYNC and Tx_BUFFER_EMPTY = '0' then
                    Tx_NSTATE <= Tx_SYNC_2;
                elsif Tx_SHFT_RDY = '1' and Tx_BUFFER_EMPTY = '0' then
                    Tx_NSTATE <= Tx_SHIFTOUT;
                else
                    Tx_NSTATE <= Tx_SYNC_1;
                end if;
            when Tx_SYNC_2 => -- Used by BSYNC
                if Tx_SHFT_RDY = '1' and Tx_EN = '0' then
                    Tx_NSTATE <= IDLE;
                elsif Tx_SHFT_RDY = '1' then
                    Tx_NSTATE <= Tx_SHIFTOUT;
                else
                    Tx_NSTATE <= Tx_SYNC_2;
                end if;
            when Tx_SHIFTOUT =>
                if Tx_SHFT_RDY = '1' and Tx_EN = '0' then
                    Tx_NSTATE <= IDLE;
                elsif OPMODE = ASYNC and Tx_SHFT_RDY = '1' then
                    Tx_NSTATE <= Tx_STOP_1;
                elsif OPMODE = SDLC and SEND_ABORT = '1' then
                    Tx_NSTATE <= Tx_ABORT;
                elsif OPMODE = SDLC and Tx_SHFT_RDY = '1' and Tx_BUFFER_EMPTY = '1' and Tx_UNDERRUN_EOM = '1' then
                    Tx_NSTATE <= Tx_CLOSE;
                elsif OPMODE = SDLC and Tx_SHFT_RDY = '1' and Tx_BUFFER_EMPTY = '1' and ABORT_FLAGn = '0' and LOOP_MODE = '0' then
                    Tx_NSTATE <= Tx_ABORT_FLAG;
                elsif OPMODE = SDLC and Tx_SHFT_RDY = '1' and Tx_BUFFER_EMPTY = '1' and Tx_CRC_EN = '0' then
                    Tx_NSTATE <= Tx_CLOSE;
                elsif OPMODE = SDLC and Tx_SHFT_RDY = '1' and Tx_BUFFER_EMPTY = '1' then
                    Tx_NSTATE <= Tx_CRC;
                elsif (OPMODE = BSYNC or OPMODE = MSYNC) and Tx_SHFT_RDY = '1' and Tx_BUFFER_EMPTY = '1' and Tx_CRC_EN = '0' then
                    Tx_NSTATE <= Tx_CLOSE;
                elsif (OPMODE = BSYNC or OPMODE = MSYNC) and Tx_SHFT_RDY = '1' and Tx_BUFFER_EMPTY = '1'  and Tx_UNDERRUN_EOM = '1' then
                    Tx_NSTATE <= Tx_CLOSE;
                elsif (OPMODE = BSYNC or OPMODE = MSYNC) and Tx_SHFT_RDY = '1' and Tx_BUFFER_EMPTY = '1'  then
                    Tx_NSTATE <= Tx_CRC;
                else
                    Tx_NSTATE <= Tx_SHIFTOUT;
                end if;
            when Tx_STOP_1 =>
                if Tx_STRB = '1' and SYNC_MODE = "01" then -- One stop bit.
                    Tx_NSTATE <= IDLE;
                elsif Tx_STRB = '1' then -- 1.5 or 2 stop bits.
                    Tx_NSTATE <= Tx_STOP_2;
                else
                    Tx_NSTATE <= Tx_STOP_1;
                end if;
            when Tx_STOP_2 =>
                if Tx_STRB = '1' then
                    Tx_NSTATE <= IDLE;
                else
                    Tx_NSTATE <= Tx_STOP_2;
                end if;
            when Tx_CRC =>
                if Tx_SHFT_RDY = '1' and Tx_EN = '0' then
                    Tx_NSTATE <= IDLE;
                elsif Tx_SHFT_RDY = '1' then
                    Tx_NSTATE <= Tx_CLOSE;
                else
                    Tx_NSTATE <= Tx_CRC;
                end if;
            when Tx_ABORT_FLAG =>
                if Tx_SHFT_RDY = '1' and Tx_EN = '0' then
                    Tx_NSTATE <= IDLE;
                elsif Tx_SHFT_RDY = '1' then
                    Tx_NSTATE <= Tx_CLOSE;
                else
                    Tx_NSTATE <= Tx_ABORT_FLAG;
                end if;
            when Tx_ABORT =>
                if Tx_SHFT_RDY = '1' and Tx_EN = '0' then
                    Tx_NSTATE <= IDLE;
                elsif Tx_SHFT_RDY = '1' and MARK_FLAGn = '0' and LOOP_MODE = '0' then
                    Tx_NSTATE <= Tx_SYNC_1;
                elsif Tx_SHFT_RDY = '1' then
                    Tx_NSTATE <= Tx_MARK_IDLE;
                else
                    Tx_NSTATE <= Tx_ABORT;
                end if;
            when Tx_CLOSE =>
                if Tx_SHFT_RDY = '1' and Tx_EN = '0' then
                    Tx_NSTATE <= IDLE;
                elsif OPMODE = SDLC and Tx_SHFT_RDY = '1' and MARK_FLAGn = '0' and LOOP_MODE = '0' then
                    Tx_NSTATE <= Tx_SYNC_1;
                elsif OPMODE = SDLC and Tx_SHFT_RDY = '1' then
                    Tx_NSTATE <= Tx_MARK_IDLE;
                elsif (OPMODE = BSYNC or OPMODE = MSYNC) and Tx_SHFT_RDY = '1' and Tx_BUFFER_EMPTY = '0' then
                    Tx_NSTATE <= Tx_SHIFTOUT;
                else
                    Tx_NSTATE <= Tx_CLOSE;
                end if;
                
        end case;
    end process Tx_STATE_DECODER;

    OPMODE <= SDLC when SYNC_CHAR = "10" and SYNC_MODE = "00" else
              SDLC when SYNC_CHAR = "11" and SYNC_MODE = "00" and CLK_MODE = "11" else -- SDLC with external sync.
              BSYNC when SYNC_CHAR = "01" and SYNC_MODE = "00" else
              MSYNC when SYNC_CHAR = "00" and SYNC_MODE = "00" else
              MSYNC when SYNC_CHAR = "11" and SYNC_MODE = "00" and CLK_MODE /= "11" else ASYNC; -- Monosync with externyl sync.

    EXT_SYNC <= '1' when SYNC_CHAR = "11" and SYNC_MODE = "00" else '0'; -- External SYNC pin is used.

    P_RTS: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            RTSn <= '1';
        elsif RTS = '1' then
            RTSn <= '0';
        elsif OPMODE = ASYNC and AUTO_EN = '1' and Tx_STATE /= IDLE and Tx_NSTATE = IDLE then -- Auto disable in asynchronous mode.
            RTSn <= '1';
        elsif OPMODE = ASYNC and AUTO_EN = '0' and RTS = '0' then
            RTSn <= '1';
        elsif OPMODE = SDLC and SDLC_HDLC = '1' and AUTO_RTS = '1' and Tx_STATE /= IDLE and Tx_NSTATE = IDLE then -- Auto disable in SDLC mode.
            RTSn <= '1';
        elsif OPMODE = SDLC and SDLC_HDLC = '1' and AUTO_RTS = '0' then -- SDLC mode.
            null; -- Wait.
        elsif OPMODE /= ASYNC and RTS = '0' then
            RTSn <= '1';
        end if;
    end process P_RTS;

    P_INTERRUPTS: process
    variable Rx_IP_D        : std_logic;
    variable Tx_IP_D        : std_logic;
    variable EXT_STAT_IP_D  : std_logic;
    variable Rx_CHAR_1      : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if (RESET or RES) = '1' or MIE = '0' then
            Rx_IP <= '0';
            Rx_CHAR_1 := false;
            STATUS <= "00";
        elsif Rx_INT_MODE = "11" and Rx_SCOND = '1' and RR1_RD = '1' then -- Receive interrupt on special condition.
            Rx_IP <= '1';
            if IUS = '0' then
                STATUS <= "11";
            end if;
        elsif Rx_INT_MODE = "10" then  -- Receive Interrupt on all characters or special condition.
            if FRAME_FIFO_EMPTY = '0' then
                Rx_IP <= '1';
                if IUS = '0' and Rx_SCOND = '1' then
                    STATUS <= "11";
                elsif IUS = '0' then
                    STATUS <= "10";
                end if;
            elsif FRAME_FIFO_EMPTY = '1' then
                Rx_IP <= '0';
            end if;
        elsif Rx_INT_MODE = "01" then -- Receive Interrupt on first character or special condition.
            if EN_INT_RxCHAR = '1' then
                Rx_CHAR_1 := false;
            end if;
            if Rx_SCOND = '1' and RR1_RD = '1' then
                Rx_IP <= '1';
                if IUS = '0' then
                    STATUS <= "11";
                end if;
            elsif FRAME_FIFO_EMPTY = '0' and Rx_CHAR_1 = false then
                Rx_CHAR_1 := true;
                Rx_IP <= '1';
                if IUS = '0' then
                    STATUS <= "10";
                end if;
            elsif FRAME_FIFO_EMPTY = '1' then
                Rx_IP <= '0';
            end if;
        end if;

        if IUS = '1' then
            null; -- Store the current status.
        elsif Tx_BUFFER_EMPTY = '1' then
            STATUS <= "00";
        elsif EXT_STATUS_INT = '1' then
            STATUS <= "01";
        end if;

        if (RESET or RES) = '1' or MIE = '0' then
            INT <= '0';
        elsif INT_ACK = '1' then
            INT <= '0';
        elsif IEI = '0' and DLC = '0' then
            INT <= '0'; -- Daisy chain: inhibit interrupt processing.
        elsif IUS = '1' then
            null; -- Store the current status.
        elsif Rx_IP = '1' then
            INT <= '1'; -- Receiver interrupt.
        elsif Tx_INT_EN = '1' and Tx_BUFFER_EMPTY = '1' then
            INT <= '1'; -- Transmit buffer empty.
        elsif EXT_INT_EN = '1' and EXT_STATUS_INT = '1' then
            INT <= '1'; -- External or status interrupt.
        end if;

        if (RESET or RES) = '1' or MIE = '0' then
            Tx_IP <= '0';
        elsif Tx_INT_EN = '1' then
            Tx_IP <= Tx_BUFFER_EMPTY;
        end if;

        if (RESET or RES) = '1' or MIE = '0' or EXT_INT_EN = '0' then
            EXT_STAT_IP <= '0';
        else
            EXT_STAT_IP <= EXT_STATUS_INT;
        end if;

        if (RESET or RES) = '1' or MIE = '0' then
            IUS <= '0'; -- Interrupt under service.
        elsif IEI = '0' and DLC = '0' then
            IUS <= '0'; -- No service at all.
        elsif INT_ACK = '1' then
            IUS <= '1'; -- IUS with interrupt acknowledge cycle.
        elsif (Rx_IP or Tx_IP or EXT_STAT_IP) = '1' and INTACKn_INH = '1' then
            IUS <= '1'; -- IUS without interrupt acknowledge cycle.
            Rx_IP_D := Rx_IP;
            Tx_IP_D := Tx_IP;
            EXT_STAT_IP_D := EXT_STAT_IP;
        elsif RES_IUS = '1' then
            IUS <= '0'; -- Clear.
        elsif Rx_IP_D = '1' and Rx_IP = '0' and INTACKn_INH = '1' then
            IUS <= '0'; -- Clear.
            Rx_IP_D := '0';
        elsif Tx_IP_D = '1' and Tx_IP = '0' and INTACKn_INH = '1' then
            IUS <= '0'; -- Clear.
            Tx_IP_D := '0';
        elsif EXT_STAT_IP_D = '1' and EXT_STAT_IP = '0' and INTACKn_INH = '1' then
            IUS <= '0'; -- Clear.
            EXT_STAT_IP_D := '0';
        end if;
    end process P_INTERRUPTS;

    EXTERNAL_INTERRUPT_LATCHES: process
    variable CMD_LOCK           : boolean;
    variable LATCH_LOCK         : boolean;

    variable CTS_Dn             : std_logic;
    variable DCD_Dn             : std_logic;
    variable SYNC_HUNT_D        : std_logic;
    variable ZCOUNT_D           : std_logic;

    variable BREAK_ABORT_HEAD   : std_logic;
    variable BREAK_ABORT_TAIL   : std_logic;
    variable BREAK_ABORT_LATCH  : std_logic;
    variable CTS_LATCH          : std_logic;
    variable DCD_LATCH          : std_logic;
    variable EOM_LATCH          : std_logic;

    begin
        wait until CLK = '1' and CLK' event;
        if EXT_INT_EN = '0' then
            BREAK_ABORT_HEAD := '0';
            BREAK_ABORT_TAIL := '0';
            BREAK_ABORT_LATCH := '0';
            DCD_LATCH := '0';
            EOM_LATCH := '0';
            LATCH_LOCK := false;
        elsif RES_EXT_STAT_INT = '1' then
            DCD_LATCH := '0';
            EOM_LATCH := '0';
            if BREAK_ABORT_HEAD = '1' then
                BREAK_ABORT_LATCH := '1';
                EXT_STATUS_INT <= '1';
                BREAK_ABORT_HEAD := '0';
            elsif BREAK_ABORT_TAIL = '1' then
                BREAK_ABORT_LATCH := '0';
                EXT_STATUS_INT <= '1';
                BREAK_ABORT_TAIL := '0';
            else
                BREAK_ABORT_LATCH := '0';
                EXT_STATUS_INT <= '0';
            end if;
            LATCH_LOCK := false;
        elsif LATCH_LOCK = true then -- The latches are closed.
            if BREAK_ABORT_IE = '1' and OPMODE = ASYNC and BREAK_ABORT_LATCH = '1' and BREAK = '0' then
                BREAK_ABORT_TAIL := '1';
            elsif BREAK_ABORT_IE = '1' and OPMODE = ASYNC and BREAK_ABORT_LATCH = '0' and BREAK = '1' then
                BREAK_ABORT_HEAD := '1';
            elsif BREAK_ABORT_IE = '1' and OPMODE = SDLC and BREAK_ABORT_LATCH = '1' and ABORT = '0' then
                BREAK_ABORT_TAIL := '1';
            elsif BREAK_ABORT_IE = '1' and OPMODE = SDLC and BREAK_ABORT_LATCH = '0' and ABORT = '1' then
                BREAK_ABORT_HEAD := '1';
            end if;

            if OPMODE = ASYNC then -- Asynchronous sync mode.
                BREAK_ABORT_LATCH := BREAK;
            elsif OPMODE = SDLC then
                BREAK_ABORT_LATCH := ABORT;
            end if;
        elsif BREAK_ABORT_IE = '1' and OPMODE = ASYNC and BREAK_ABORT_LATCH = '1' and BREAK = '0' then
            BREAK_ABORT_LATCH := '0';
            EXT_STATUS_INT <= '1';
            LATCH_LOCK := true;
        elsif BREAK_ABORT_IE = '1' and OPMODE = ASYNC and BREAK_ABORT_LATCH = '0' and BREAK = '1' then
            BREAK_ABORT_LATCH := '1';
            EXT_STATUS_INT <= '1';
            LATCH_LOCK := true;
        elsif BREAK_ABORT_IE = '1' and OPMODE = SDLC and BREAK_ABORT_LATCH = '1' and ABORT = '0' then
            BREAK_ABORT_LATCH := '0';
            EXT_STATUS_INT <= '1';
            LATCH_LOCK := true;
        elsif BREAK_ABORT_IE = '1' and OPMODE = SDLC and BREAK_ABORT_LATCH = '0' and ABORT = '1' then
            BREAK_ABORT_LATCH := '0';
            EXT_STATUS_INT <= '1';
            LATCH_LOCK := true;
        elsif SYNC_HUNT_IE = '1' and SYNC_HUNT = '1' and SYNC_HUNT_D = '0' then -- Rising edge detected.
            EXT_STATUS_INT <= '1';
            LATCH_LOCK := true;
        elsif SYNC_HUNT_IE = '1' and SYNC_HUNT = '0' and SYNC_HUNT_D = '1' then -- Falling edge detected.
            EXT_STATUS_INT <= '1';
            LATCH_LOCK := true;
        elsif ZCOUNT_IE = '1' and ZCOUNT_D = '0' and ZCOUNT = '1' then -- Rising edge.
            -- ZCOUNT_LATCH: ZCOUNT is not latched.
            EXT_STATUS_INT <= '1';
            LATCH_LOCK := true;
        elsif EOM_IE = '1' and (OPMODE = MSYNC or OPMODE = BSYNC or OPMODE = SDLC) and Tx_BUFFER_EMPTY = '1' then
            EOM_LATCH := '1';
            EXT_STATUS_INT <= '1';
            LATCH_LOCK := true;
        elsif CTS_IE = '1' and EXT_INT_EN = '1' and (CTS_Dn xor CTSn) = '1' then -- Edge detected (any edge).
            CTS_LATCH := '1';
            EXT_STATUS_INT <= '1';
            LATCH_LOCK := true;
        elsif DCD_IE = '1' and EXT_INT_EN = '1' and (DCD_Dn xor DCDn) = '1' then -- Edge detected (any edge).
            DCD_LATCH := '1';
            EXT_STATUS_INT <= '1';
            LATCH_LOCK := true;
        end if;

        if EXT_INT_EN = '1' and CTS_IE = '1' then
            CTS <= CTS_LATCH;
        else
            CTS <= not CTSn;
        end if;

        if EXT_INT_EN = '1' and DCD_IE = '1' then
            DCD <= DCD_LATCH;
        else
            DCD <= not DCDn;
        end if;

        if RESET = '1' or RES = '1' then
            SYNC_HUNT <= '0';
        elsif OPMODE = ASYNC and XTAL = '1' then -- Crystal oscillator enabled.
            SYNC_HUNT <= '0';
        elsif OPMODE = ASYNC then
            SYNC_HUNT <= SYNC_IN_I;
        elsif OPMODE /= ASYNC and SYNC_CHAR = "11" and XTAL = '1' then -- External sync mode, crystal oscillator enabled.
            SYNC_HUNT <= '0';
        elsif OPMODE /= ASYNC and SYNC_CHAR = "11" then -- External sync mode.
            SYNC_HUNT <= SYNC_IN_I;
        elsif Rx_EN = '0' then -- MSYNC, BSYNC, SDLC.
            SYNC_HUNT <= '1';
        elsif Rx_STATE /= Rx_HUNT and Rx_NSTATE = Rx_HUNT then -- MSYNC, BSYNC, SDLC.
            SYNC_HUNT <= '1';
        elsif Rx_STATE = Rx_HUNT and Rx_NSTATE /= Rx_HUNT then -- MSYNC, BSYNC, SDLC.
            SYNC_HUNT <= '0';
        end if;

        if (OPMODE = MSYNC or OPMODE = BSYNC or OPMODE = SDLC) and SYNC_CHAR /= "01" then
            BREAK_ABORT <= '0';
        elsif EXT_INT_EN = '1' and BREAK_ABORT_IE = '1' then
            BREAK_ABORT <= BREAK_ABORT_LATCH;
        elsif OPMODE = SDLC then
            BREAK_ABORT <= ABORT;
        elsif OPMODE = ASYNC then
            BREAK_ABORT <= BREAK;
        end if;

        if RESET = '1' or RES = '1' then -- Reset or channel reset.
            Tx_UNDERRUN_EOM <= '1';
        elsif Tx_EN = '0' or TX_INH = '1' then -- Transmitter disabled.
            Tx_UNDERRUN_EOM <= '1';
        elsif SEND_ABORT = '1' then -- Send abort command.
            Tx_UNDERRUN_EOM <= '1';
        elsif RES_Tx_UR_EOM = '1' then -- Reset transmit underrun command.
            Tx_UNDERRUN_EOM <= '0';
        elsif SDLC_HDLC = '1' and AUTO_EOM_LRES = '1' and Tx_STATE = Tx_SYNC_1 then
            Tx_UNDERRUN_EOM <= '0';
        elsif OPMODE = SDLC and Tx_STATE = Tx_SHIFTOUT and Tx_SHFT_RDY = '1' and Tx_BUFFER_EMPTY = '1' then
            Tx_UNDERRUN_EOM <= '1';
        elsif (OPMODE = BSYNC or OPMODE = MSYNC) and Tx_STATE = Tx_SHIFTOUT and Tx_SHFT_RDY = '1' and Tx_BUFFER_EMPTY = '1' then
            Tx_UNDERRUN_EOM <= '1';
        elsif OPMODE = ASYNC then
            Tx_UNDERRUN_EOM <= '1';
        elsif EXT_INT_EN = '1' and EOM_IE = '1' and (OPMODE = MSYNC or OPMODE = BSYNC or OPMODE = SDLC) then
            Tx_UNDERRUN_EOM <= EOM_LATCH;
        end if;

        CTS_Dn := CTSn;
        DCD_Dn := DCDn;
        SYNC_HUNT_D := SYNC_HUNT;
        ZCOUNT_D := ZCOUNT;
    end process EXTERNAL_INTERRUPT_LATCHES;

    IO_CONTROL: process(CLK, DMA_REQ_MODE, FAST_DTR, FIFO_REG, OPMODE, Rx_INT_MODE, SDLC_HDLC, Tx_STATE, Tx_NSTATE)
    variable W_REQ_P        : std_logic;
    variable DTR_REQ_P      : std_logic;
    variable W_REQ_N        : std_logic;
    variable DTR_REQ_N      : std_logic;
    variable DTR_REQ_DELAY  : std_logic_vector(2 downto 0);
    begin
        if CLK = '1' and CLK' event then
            if RESET = '1' or RES = '1' then
                W_REQ_P := '0';
            elsif DMA_REQ_MODE = "100" and WR8_WR = '1' and Tx_BUFFER_EMPTY = '0' then -- Wait on transmit mode.
                W_REQ_P := '1';
            elsif DMA_REQ_MODE = "101" and RR8_RD = '1' and FRAME_FIFO_EMPTY = '1' then -- Wait on receive mode.
                W_REQ_P := '1';
            elsif DMA_REQ_MODE = "110" and DTRn_REQ = '1' and Tx_BUFFER_EMPTY = '1' then -- DMA request on transmit mode.
                W_REQ_P := '1';
            elsif DMA_REQ_MODE = "111" and FRAME_FIFO_EMPTY = '0' then -- DMA request on receive mode.
                W_REQ_P := '1';
            else
                W_REQ_P := '0';
            end if;

            if RESET = '1' or RES = '1' then
                DTR_REQ_P := '0';
            elsif DMA_REQ_MODE = "110" and DTRn_REQ = '0' and Tx_BUFFER_EMPTY = '1' then -- DMA request on transmit mode using DMA_REQ.
                DTR_REQ_P := '1';
            end if;

            if DTRn_REQ = '1' then
                DTR_REQ_DELAY := "111";
            else
                DTR_REQ_DELAY := DTR_REQ_DELAY(1 downto 0) & '0'; -- NMOS SCC delay, refer to the CMOS SCC data sheet.
            end if;
        end if;

        if CLK = '0' and CLK' event then
            W_REQ_N := not W_REQ_P;
            DTR_REQ_N := DTR_REQ_P;
        end if;

        if (OPMODE = MSYNC or OPMODE = BSYNC or OPMODE = SDLC) and DMA_REQ_MODE = "110" and Tx_STATE /= Tx_CLOSE and Tx_NSTATE = Tx_CLOSE then
            Wn_REQn <= '1'; -- See 3.9.3.1 of the AMD datasheet.
        elsif DMA_REQ_MODE = "111" and (Rx_INT_MODE = "11" or Rx_INT_MODE = "01") and FIFO_REG(1)(7 downto 0) /= x"00" then -- Receive.
            Wn_REQn <= '1'; -- See 3.9.3.4 of the AMD datasheet.
        elsif DMA_REQ_MODE = "110" then -- Transmit.
            Wn_REQn <= not W_REQ_N;
        elsif DMA_REQ_MODE = "111" then -- Receive.
            Wn_REQn <= not W_REQ_N;
        else
            Wn_REQn <= '1';
        end if;

        if (OPMODE = MSYNC or OPMODE = BSYNC or OPMODE = SDLC) and DMA_REQ_MODE = "110" and Tx_STATE /= Tx_CLOSE and Tx_NSTATE = Tx_CLOSE then
            DTRn_REQn <= '1'; -- See 3.9.3.2 of the AMD datasheet.
        elsif OPMODE = SDLC and SDLC_HDLC = '1' and DMA_REQ_MODE = "110" and FAST_DTR = '0' then
            DTRn_REQn <= not DTR_REQ_DELAY(2);
        elsif (OPMODE = MSYNC or OPMODE = BSYNC or OPMODE = SDLC) and DMA_REQ_MODE = "110" then
            DTRn_REQn <= not DTR_REQ_P;
        elsif OPMODE = ASYNC and DMA_REQ_MODE = "110" then -- Transmit.
            DTRn_REQn <= not DTR_REQ_N;
        else
            DTRn_REQn <= '1';
        end if;
    end process IO_CONTROL;

    BUFFER_OUT <= BREAK_ABORT &  Tx_UNDERRUN_EOM & CTS & SYNC_HUNT & DCD & Tx_BUFFER_EMPTY & ZCOUNT & not FRAME_FIFO_EMPTY when RR0_RD = '1' else
                Rx_ERROR when OPMODE = SDLC and (FRAME_FIFO_EN = '0' or FRAME_FIFO_EMPTY = '1') and RR1_RD = '1' else -- Frame FIFO disabled or empty.
                '1' & FRAME_FIFO_DOUT(18 downto 17) & Rx_ERROR(4) & FRAME_FIFO_DOUT(16 downto 14) & Rx_ERROR(0) when OPMODE = SDLC and RR1_RD = '1' else -- Frame FIFO enabled.
                FRAME_FIFO_DOUT(7 downto 0) when RR6_RD = '1' else
                FRAME_FIFO_OVERFLOW & '1' & FRAME_FIFO_DOUT(13 downto 8) when RR7_RD = '1' else
                FIFO_REG(1)(15 downto 8) when RR8_RD = '1' else -- This is the character FIFO.
                FIFO_REG(1)(7 downto 0) when RR1_RD = '1' else x"00"; -- This is the Rx error FIFO.

    -- These are the receiver data input multiplexers.
    RxD_I <= TxD_I when LOOPBACK = '1' else RxD_D; -- This is the loopback multiplexer.

    RxD_SR <= RxD_I when OPMODE = ASYNC else
              RxD_NRZI; -- This is the NRZI multiplexer.

    SYNCHRONIZER: process
    -- This is sync pattern detector and the three bit 
    -- delay which is connected to the input of the 
    -- receiver shift register.
    variable DELAY_CNT      : integer range 0 to 8;
    variable SYNC_REGISTER  : std_logic_vector(7 downto 0);
    variable PIPE           : std_logic_vector(2 downto 0);
    variable RxD_SDLC       : std_logic;
    variable SOF_VAR        : std_logic;
    begin
        wait until CLK = '1' and CLK' event;
        if Rx_STATE = IDLE then
            SYNC_REGISTER := x"00";
            RxD_SDLC := '0';
        elsif Rx_STRB = '1' then
            SYNC_REGISTER := RxD_SR & SYNC_REGISTER(7 downto 1); -- Shift right.
        end if;

        if Rx_STATE /= Rx_HUNT then
            DELAY_CNT := 0;
        elsif Rx_STRB = '1' and DELAY_CNT < 8 and SOF_VAR = '1' then
            DELAY_CNT := DELAY_CNT + 1;
        elsif RX_STRB = '1' and (OPMODE = BSYNC or OPMODE = MSYNC) and B6_B8n = '1' and DELAY_CNT = 6 then -- Rescan.
            DELAY_CNT := 0;
        elsif RX_STRB = '1' and DELAY_CNT = 8 then -- Rescan.
            DELAY_CNT := 0;
        end if;

        if Rx_STATE /= Rx_HUNT then
            SOF_VAR := '0';
        elsif (OPMODE = MSYNC or OPMODE = BSYNC) and B6_B8n = '1' and RX_STRB = '1' and SYNC_REGISTER(7 downto 2) = SYNC_SDLC_FLAG(7 downto 2) then
            SOF_VAR := '1'; -- Flag detected.
        elsif (OPMODE = MSYNC or OPMODE = BSYNC) and B6_B8n = '1' and RX_STRB = '1' and DELAY_CNT = 6 and SYNC_REGISTER(7 downto 2) /= SYNC_SDLC_FLAG(7 downto 2) then -- Rescan.
            SOF_VAR := '0';
        elsif (OPMODE = MSYNC or OPMODE = BSYNC) and RX_STRB = '1' and SYNC_REGISTER = SYNC_SDLC_FLAG then
            SOF_VAR := '1'; -- Flag detected.
        elsif (OPMODE = MSYNC or OPMODE = BSYNC) and RX_STRB = '1' and DELAY_CNT = 8 and SYNC_REGISTER /= SYNC_SDLC_FLAG then -- Rescan.
            SOF_VAR := '0';
        elsif OPMODE = SDLC and RX_STRB = '1' and DELAY_CNT = 8 and SYNC_REGISTER /= "01111110" then -- Rescan.
            SOF_VAR := '0';
        elsif OPMODE = SDLC and RX_STRB = '1' and SYNC_REGISTER = "01111110" then
            SOF_VAR := '1'; -- Flag detected.
        end if;

        if OPMODE = BSYNC and Rx_STRB = '1' and B6_B8n = '1' and SOF_VAR = '1' and DELAY_CNT = 6 and SYNC_REGISTER(7 downto 2) = SYNC_SDLC_ADR(7 downto 2) then
            SOF <= '1';
        elsif OPMODE = BSYNC and Rx_STRB = '1' and SOF_VAR = '1' and DELAY_CNT = 8 and SYNC_REGISTER = SYNC_SDLC_ADR then
            SOF <= '1';
        elsif OPMODE = MSYNC and Rx_STRB = '1' and B6_B8n = '1' and SOF_VAR = '1' and DELAY_CNT = 6 then
            SOF <= '1';
        elsif OPMODE = MSYNC and Rx_STRB = '1' and SOF_VAR = '1' and DELAY_CNT = 8 then
            SOF <= '1';
        elsif OPMODE = SDLC and RX_STRB = '1' and SOF_VAR = '1' and ADR_SEARCH_MODE = '0' and DELAY_CNT = 8 and SYNC_REGISTER /= "01111110" then -- Stay in Rx_HUNT when there is another SYNC.
            SOF <= '1'; -- Delayed until sync register is filled up with data.
        elsif RX_STRB = '1' then
            SOF <= '0';
        end if;

        if OPMODE = SDLC and RX_STRB = '1' and Rx_STATE = Rx_SHIFTIN and SYNC_REGISTER = "01111110" then
            EOF <= '1';
        elsif OPMODE = SDLC and RX_STRB = '1' and SYNC_REGISTER = "11111110" then
            EOP <= '1';
        elsif OPMODE = SDLC and RX_STRB = '1' and SYNC_REGISTER(6 downto 0) = "1111111" then -- Any seven consecutive ones.
            ABORT <= '1';
        elsif RX_STRB = '1' then
            EOF <= '0';
            EOP <= '0';
            ABORT <= '0';
        end if;

        if OPMODE = ASYNC and Rx_STATE = IDLE then
            PIPE := "111"; -- Pipe must not contain a startbit.
            RxD_SR_3B <= '1';
        elsif Rx_STATE = IDLE or Rx_STATE = Rx_HUNT then
            PIPE := "000";
            RxD_SDLC := '0';
        elsif Rx_STRB = '1' then
            if OPMODE = SDLC then
                PIPE := RxD_SDLC & PIPE(2 downto 1);
            else
                PIPE := RxD_SR & PIPE(2 downto 1);
            end if;
            RxD_SDLC := SYNC_REGISTER(0);
            RxD_SR_3B <= PIPE(0);
        end if;
    end process SYNCHRONIZER;

    Rx_LEN <= 8 when Rx_BITS = "11" else
              7 when Rx_BITS = "01" else
              6 when Rx_BITS = "10" else 5;

    -- Error logic;
    -- Be aware that the ALL_SENT is a transmitter status information an not stored in the
    -- receive status fifo.
    Rx_ERROR <= EOF & CRC_FRAME_ERR & Rx_OVR & PARITY_ERR & RESIDUE_BITS & ALL_SENT;

    -- No framing error for a BREAK condition is decoded by an empty shift register and the framing condition.
    CRC_FRAME_ERR <= '1' when OPMODE = ASYNC and Rx_STATE = Rx_CHECK_FRAME and Rx_STRB = '1' and Rx_LEN = 8 and RxD_SR_3B = '0' and Rx_SHIFTREG /= x"00" else
                     '1' when OPMODE = ASYNC and Rx_STATE = Rx_CHECK_FRAME and Rx_STRB = '1' and Rx_LEN = 7 and RxD_SR_3B = '0' and Rx_SHIFTREG /= x"00" else
                     '1' when OPMODE = ASYNC and Rx_STATE = Rx_CHECK_FRAME and Rx_STRB = '1' and RxD_SR = '0' and Rx_SHIFTREG /= x"00" else 
                     CRC_ERR when OPMODE = SDLC else '0';

    -- RxD_SR_3B is the received parity in 8 bit or 7 bit per character mode.
    -- RxD_SR is the received parity in less than 7 bit per character mode.
    -- The parity error is valid when all bits are shifted into the receiver shift register.
    PARITY_ERR <= '1' when PAR_EN = '1' and Rx_LEN = 8 and Rx_PARITY /= RxD_SR_3B else
                  '1' when PAR_EN = '1' and Rx_LEN = 7 and Rx_PARITY /= RxD_SR_3B else
                  '1' when PAR_EN = '1' and Rx_LEN = 8 and Rx_PARITY /= RxD_SR else '0';

    Rx_SCOND <= '1' when FIFO_REG(1)(4) = '1' and PAR_S_COND = '1' and PAR_EN = '1' else -- Parity.
                '1' when FIFO_REG(1)(5) = '1' else -- Rx_OVR.
                '1' when FIFO_REG(1)(6) = '1' else -- CRC_FRAME_ERR.
                '1' when FIFO_REG(1)(7) = '1' else '0'; -- EOF.

    Rx_FIFO: process
    -- This is the ^16 bit wide receiver FIFO. It is flushed 
    -- during a hardware or channel reset. This feature is 
    -- an enhancement over the original hardware.
    subtype T_01 is natural range 0 to 1;
    variable WRITE      : T_01;
    variable READ       : T_01;
    variable FIFO_RD    : std_logic;
    variable RR8_LOCK   : boolean;
    variable FIFO_LOCK  : boolean;
    begin
        wait until CLK = '1' and CLK' event;

        if RESET = '1' or RES = '1' then
            FIFO_REG <= (others => (others => '0'));
        elsif FIFO_LOCK = true then
            null;
        else
            for i in 1 to 3 loop
                if i > FIFO_WR_PNT then
                    FIFO_REG(i) <= Rx_SHIFTREG & Rx_ERROR;
                elsif FIFO_RD = '1' then
                    if i = FIFO_WR_PNT then
                        FIFO_REG(i) <= Rx_SHIFTREG & Rx_ERROR;
                    end if;
                    if i > 1 then
                        FIFO_REG(i-1) <= FIFO_REG(i);
                    end if;
                end if;
            end loop;
        end if;

        if RESET ='1' or RES = '1' then
            FIFO_WR_PNT <= 0;
        else
            if FIFO_WR = '1' and FIFO_LOCK = false then
                WRITE := 1;
            elsif FIFO_WR = '0' then
                WRITE := 0;
            end if;
            if FIFO_RD = '1' and FIFO_LOCK = false then
                READ := 1;
            elsif FIFO_RD = '0' then
                READ := 0;
            end if;
            if FIFO_WR_PNT = 3 and WRITE = 1 and READ = 0 then
                null; -- FIFO full.
            elsif FIFO_WR_PNT = 0 and WRITE = 0 and READ = 1 then
                null; -- FIFO empty.
            else
                FIFO_WR_PNT <= FIFO_WR_PNT + WRITE - READ;
            end if;
        end if;

        FIFO_RD := '0';

        -- This logic change the FIFO after RR8 read access.
        if RR8_RD = '1' then
            RR8_LOCK := false;
        elsif RR8_RD = '0' and RR8_LOCK = false then
            FIFO_RD := '1';
            RR8_LOCK := true;
        end if;

        if FIFO_WR = '1' and FIFO_RD = '0' and Rx_OVR = '1' then
            FIFO_REG(3) <= Rx_SHIFTREG & Rx_ERROR; -- Overflow condition.
        end if;

        if FIFO_WR_PNT = 3 then
            Rx_OVR <= '1'; -- Overflow on next write.
        else
            Rx_OVR <= '0';
        end if;

        if RESET ='1' or RES = '1' then
            FIFO_LOCK := false;
        elsif RES_ERR = '1' then
            FIFO_LOCK := false;
        elsif Rx_INT_MODE /= "00" and FIFO_RD = '1' and FIFO_REG(2)(7 downto 0) /= x"00" then -- After FIFO_RD the error is on the top of the FIFO.
            FIFO_LOCK := true;
        end if;
    end process Rx_FIFO;

    -- FIFO_FULL <= '1' when FIFO_WR_PNT = 3 else '0';
    FIFO_EMPTY <= '1' when FIFO_WR_PNT = 0 else '0';

    FIFO_WR <= '1' when OPMODE = ASYNC and Rx_STATE = Rx_CHECK_FRAME and Rx_STRB = '1' else 
               FIFO_WR_SYNCMODES when OPMODE = BSYNC or OPMODE = MSYNC or OPMODE = SDLC else '0';
    
    FRAME_FIFO_WR <= EOF;

    FRAME_FIFO_CTRL: process
    variable ENTRY_CNT  : std_logic_vector(3 downto 0);
    variable READ_LOCK  : boolean;
    begin
        wait until CLK = '1' and CLK' event;

        if RESET = '1' or RES = '1' then
            FRAME_FIFO_HEAD <= x"0";
            FRAME_FIFO_TAIL <= x"0";
            FRAME_FIFO_OVERFLOW <= '0';
            ENTRY_CNT := x"0";
        elsif OPMODE /= SDLC or FRAME_FIFO_EN = '0' then -- Frame FIFO disabled.
            FRAME_FIFO_HEAD <= x"0";
            FRAME_FIFO_TAIL <= x"0";
            FRAME_FIFO_OVERFLOW <= '0';
            ENTRY_CNT := x"0";
        else
            if FRAME_FIFO_WR = '1' and FRAME_FIFO_HEAD = x"9" then -- Rollover.
                FRAME_FIFO_HEAD <= x"0";
                ENTRY_CNT := ENTRY_CNT + '1';
            elsif FRAME_FIFO_WR = '1' then
                FRAME_FIFO_HEAD <= FRAME_FIFO_HEAD + '1'; -- One entry written.
                ENTRY_CNT := ENTRY_CNT + '1';
            end if;

            if FIFO_EMPTY = '1' then
                null; -- Do not read from an empty FIFO.
            elsif FRAME_FIFO_RD = '1' and FRAME_FIFO_TAIL = x"9" then -- Rollover.
                FRAME_FIFO_TAIL <= x"0";
                ENTRY_CNT := ENTRY_CNT - '1';
            elsif FRAME_FIFO_RD = '1' then
                FRAME_FIFO_TAIL <= FRAME_FIFO_TAIL + '1'; -- One entry written.
                ENTRY_CNT := ENTRY_CNT - '1';
            end if;

            if ENTRY_CNT > x"A" then
                FRAME_FIFO_OVERFLOW <= '1';
            end if;
        end if;

        -- This logic change the FIFO after RR1 read access.
        if RR1_RD = '1' then
            READ_LOCK := false;
        elsif RR1_RD = '0' and READ_LOCK = false then
            READ_LOCK := true;
            FRAME_FIFO_RD <= '1';
        end if;
    end process FRAME_FIFO_CTRL;

    FRAME_FIFO_RAM: process(CLK, FRAME_FIFO)
    variable ADR_PNTR  : integer range 0 to 15;
    begin
        if CLK = '1' and CLK' event then
            ADR_PNTR := To_Integer(unsigned(FRAME_FIFO_ADR));

            if OPMODE = SDLC and FRAME_FIFO_EN = '1' and FRAME_FIFO_WR = '1' then -- Frame FIFO enabled.
                FRAME_FIFO(ADR_PNTR) <= FRAME_FIFO_DIN;
            end if;
        end if;
        FRAME_FIFO_DOUT <= FRAME_FIFO(ADR_PNTR);
    end process FRAME_FIFO_RAM;

    FRAME_FIFO_DIN <= Rx_ERROR(6 downto 5) & Rx_ERROR(3 downto 1) & FRAME_BYTE_COUNTER;
    FRAME_FIFO_ADR <= FRAME_FIFO_TAIL when FRAME_FIFO_RD = '1' else FRAME_FIFO_HEAD;

    FRAME_FIFO_EMPTY <= '1' when FRAME_FIFO_TAIL = FRAME_FIFO_HEAD else '0';

    P_FRAME_BYTE_COUNTER: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' or RES = '1' then
            FRAME_BYTE_COUNTER <= (others => '0');
        elsif OPMODE /= SDLC or FRAME_FIFO_EN = '0' or SOF = '1' then -- Frame FIFO disabled.
            FRAME_BYTE_COUNTER <= (others => '0');
        elsif FRAME_FIFO_WR = '1' then
            FRAME_BYTE_COUNTER <= FRAME_BYTE_COUNTER + '1';
        end if;
    end process P_FRAME_BYTE_COUNTER;

    NRZI_DECODER: process
    -- This logic provides a NRZI logic. It works
    -- on the positive and the negative receiver
    -- clock edges. To handle this we use two edge
    -- detectors (LOCK_N, LOCK_P).
    variable BMC_D      : std_logic;
    variable LOCK_P     : boolean;
    variable LOCK_N     : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if Rx_CLK = '1' and LOCK_P = false then
            LOCK_P := true;
            if RESET = '1' or RES = '1' then
                NRZI_IN <= '0';
                RxD_NRZI <= '0';
            elsif NRZ_FM = "00" then -- NRZ.
                RxD_NRZI <= RxD_I;
            elsif NRZ_FM = "01" then -- NRZI.
                RxD_NRZI <= RxD_NRZI xnor NRZI_IN;
                NRZI_IN <= RxD_I;
            elsif NRZ_FM = "10" then -- FM1 (biphase mark).
                RxD_NRZI <= BMC_D;
            else -- FM0 (biphase space).
                RxD_NRZI <= BMC_D;
            end if;
        elsif Rx_CLK = '0' then
            LOCK_P := false;
        end if;

        if Rx_CLK = '0' and LOCK_N = false then
            LOCK_N := true;
            if RESET = '1' or RES = '1' then
                BMC_D := '0';
            elsif NRZ_FM = "10" then -- FM1 (biphase mark).
                BMC_D := BMC_D xnor RxD_I;
            else -- FM0 (biphase space).
                BMC_D := BMC_D xor RxD_I;
            end if;
        elsif Rx_CLK = '1' then
            LOCK_N := false;
        end if;            
    end process NRZI_DECODER;

	RECEIVER_SHIFTREG: process
    -- This is the receiver shift register. It is shifted in LSB first (right shift).
    variable ADDRESS_FAIL   : std_logic;
    variable BITCNT         : std_logic_vector(3 downto 0);
    variable BITCNT_R       : std_logic_vector(2 downto 0);
    variable CRC_DELAY      : std_logic_vector(7 downto 0);
    variable ONE_CNT_R      : integer range 0 to 7;
    variable CRC_SHIFT_16   : std_logic_vector(16 downto 1);
    variable BYTELOCK       : boolean;
    variable CRC_EN         : std_logic;
    variable SHIFTREG_FULL  : boolean;
	begin
		wait until CLK = '1' and CLK' event;
        
        FIFO_WR_SYNCMODES <= '0'; -- Default.
        Rx_SHFT_RDY <= '0';

        if (RES_Rx_CRC = '1' or Rx_STATE = Rx_HUNT) and CRC_PRES = '1' then
            CRC_SHIFT_16 := (others => '1');
        elsif RES_Rx_CRC = '1' or Rx_STATE = Rx_HUNT then
            CRC_SHIFT_16 := (others => '0');
        end if;

        if Rx_STATE = IDLE or Rx_STATE = PIPE_3B then
			Rx_SHIFTREG <= (others => '0');
            BITCNT := x"0";
            BITCNT_R := "000";
            BREAK <= '0';
            ONE_CNT_R := 0; 
            RESIDUE_BITS <= "000";
            ADDRESS_FAIL := '0';
            BYTELOCK := false;
            CRC_DELAY := (others => '0');
            CRC_EN := '0';
            SHIFTREG_FULL := false;
		elsif Rx_STATE = Rx_HUNT then
			Rx_SHIFTREG <= (others => '0');
            BITCNT := x"0";
            BITCNT_R := "000";
            ONE_CNT_R := 0; 
            RESIDUE_BITS <= "000";
            ADDRESS_FAIL := '0';
            BYTELOCK := false;            
            CRC_DELAY := (others => '0');
            CRC_EN := '0';
            SHIFTREG_FULL := false;
        elsif Rx_STATE = Rx_SHIFTIN and Rx_INH = '1' then
            null;  -- Stop shifting.
        elsif Rx_STATE = Rx_SHIFTIN and OPMODE = ASYNC and Rx_STRB = '1' then
            BITCNT := BITCNT + '1';
            case Rx_LEN is
                when 8 =>
                    Rx_SHIFTREG <= RxD_SR_3B & Rx_SHIFTREG(7 downto 1);
                when 7 =>
                    Rx_SHIFTREG <= '0' & RxD_SR_3B & Rx_SHIFTREG(6 downto 1);
                when 6 =>
                    Rx_SHIFTREG <= "00" & RxD_SR & Rx_SHIFTREG(5 downto 1);
                when others => -- 5 bits per character.
                    Rx_SHIFTREG <= "000" & RxD_SR & Rx_SHIFTREG(4 downto 1);
            end case;

            if Rx_LEN = 8 and BITCNT = x"8" then -- 8 bits per character.
                Rx_SHFT_RDY <= '1';
            elsif Rx_LEN = 7 and BITCNT = x"7" then -- 7 bits per character.
                Rx_SHFT_RDY <= '1';
            elsif Rx_LEN = 6 and BITCNT = x"6" then -- 6 bits per character.
                Rx_SHFT_RDY <= '1';
            elsif Rx_LEN = 5 and BITCNT = x"5" then -- 5 bits per character.
                Rx_SHFT_RDY <= '1';
            end if;
        elsif Rx_STATE = Rx_SHIFTIN and (OPMODE = BSYNC or OPMODE = MSYNC) and Rx_STRB = '1' then

            Rx_SHIFTREG <= RxD_SR_3B & Rx_SHIFTREG(7 downto 1); -- Shift right.

            if BITCNT = x"8" then
                BITCNT := (others => '0');
                if SYNC_CHAR_INH = '0' or Rx_SHIFTREG /= SYNC_SDLC_ADR then
                    FIFO_WR_SYNCMODES <= '1';
                end if;
            else
                BITCNT := BITCNT + '1';
            end if;

            if BITCNT = x"8" and Rx_CRC_EN = '0' then
                CRC_EN := '0';
            elsif BITCNT = x"8" and SHIFTREG_FULL = true then
                CRC_EN := '1'; -- Character is now completely in the CRC_DELAY.
            end if;

            if BITCNT = x"8" then
                SHIFTREG_FULL := true; -- At least 8 bits shifted in.
            end if;

            if CRC_EN = '0' then
                null; -- CRC checker disabled.
            elsif CRC16_SDLCn = '1' then
                -- The CRC polynomial is G(x) = x^16 + x^15 + x^2 + 1; right shift.
                CRC_SHIFT_16 := (CRC_SHIFT_16(15) xor CRC_SHIFT_16(16) xor CRC_DELAY(0)) & CRC_SHIFT_16(14 downto 3) & 
                                (CRC_SHIFT_16(2) xor CRC_SHIFT_16(16) xor CRC_DELAY(0)) & CRC_SHIFT_16(1) & (CRC_SHIFT_16(16) xor CRC_DELAY(0));
            else
                -- The CRC polynomial is G(x) = x^16 + x^12 + x^5 + 1; right shift.
                CRC_SHIFT_16 := CRC_SHIFT_16(15 downto 13) & (CRC_SHIFT_16(12) xor CRC_SHIFT_16(16) xor CRC_DELAY(0)) & CRC_SHIFT_16(11 downto 6) & 
                                (CRC_SHIFT_16(5) xor CRC_SHIFT_16(16) xor CRC_DELAY(0)) & CRC_SHIFT_16(4 downto 1) & (CRC_SHIFT_16(16) xor CRC_DELAY(0));
            end if;

            CRC_DELAY := Rx_SHIFTREG(0) & CRC_DELAY(7 downto 1); -- Delay line shifted right.
            
            if Rx_CRC_EN = '1' and CRC_SHIFT_16 /= x"0000" then
                CRC_ERR <= '1';
            else
                CRC_ERR <= '0';
            end if;    
        elsif Rx_STATE = Rx_SHIFTIN and OPMODE = SDLC and Rx_STRB = '1' then
            if BYTELOCK = true then
                null;
            elsif ADR_SEARCH_MODE = '1' and BITCNT = x"8" and SYNC_CHAR_INH = '1' and Rx_SHIFTREG(7 downto 4) /= SYNC_SDLC_ADR(7 downto 4)  and Rx_SHIFTREG /= x"FF" then
                ADDRESS_FAIL := '1';
                BYTELOCK := true;
            elsif ADR_SEARCH_MODE = '1' and BITCNT = x"8" and SYNC_CHAR_INH = '0' and Rx_SHIFTREG /= SYNC_SDLC_ADR and Rx_SHIFTREG /= x"FF" then
                ADDRESS_FAIL := '1';
                BYTELOCK := true;
            elsif BITCNT = x"8" then
                BYTELOCK := false;
            end if;

            if ONE_CNT_R = 5 then
                null; -- Strip the stuffed zero.
            else
                Rx_SHIFTREG <= RxD_SR_3B & Rx_SHIFTREG(7 downto 1); -- Shift right.
                -- Be aware, that the 3 bit delay is taken into account in case of asynchronous
                -- 8 bit and 7 bit per character.
                if BITCNT = x"8" then
                    BITCNT := x"0";
                    FIFO_WR_SYNCMODES <= not ADDRESS_FAIL;
                else
                    BITCNT := BITCNT + '1';
                end if;

                -- The CRC polynomial is G(x) = x^16 + x^12 + x^5 + 1; right shift.
                CRC_SHIFT_16 := CRC_SHIFT_16(15 downto 13) & (CRC_SHIFT_16(12) xor CRC_SHIFT_16(16) xor RxD_SR_3B) & CRC_SHIFT_16(11 downto 6) &
                (CRC_SHIFT_16(5) xor CRC_SHIFT_16(16) xor RxD_SR_3B) & CRC_SHIFT_16(4 downto 1) & (CRC_SHIFT_16(16) xor RxD_SR_3B);

                if CRC_SHIFT_16 /= "0001110100001111" then
                    CRC_ERR <= '1';
                else
                    CRC_ERR <= '0';
                end if;    
            end if;

            FIFO_WR_SYNCMODES <= EOF and not CRC_CHECK_RCVD; -- This is the last package of a frame regardless of its size when CRC_CHECK_RCVD is not active.
            
            SDLC_ADDRESS_FAIL <= ADDRESS_FAIL;

            RESIDUE_BITS <= BITCNT(2 downto 0);

            if ONE_CNT_R < 5 and RxD_SR_3B = '1' then
                ONE_CNT_R := ONE_CNT_R + 1;
            else
                ONE_CNT_R := 0;
            end if;
        elsif Rx_STATE = Rx_SHIFTIN_3B and Rx_STRB = '1' then -- This state is for SDLC CRC bits completely shifted in.
            if ONE_CNT_R = 5 then
                null; -- Strip the stuffed zero.
            else
                Rx_SHIFTREG <= RxD_SR_3B & Rx_SHIFTREG(7 downto 1); -- Shift right.
                BITCNT_R := BITCNT_R + '1';
            end if;
            if BITCNT_R = "011" then
                Rx_SHFT_RDY <= '1';
                FIFO_WR_SYNCMODES <= '1';
            end if;
        end if;

        if Rx_STATE = Rx_CHECK_FRAME and OPMODE = ASYNC and Rx_SHIFTREG = "000000000" and Rx_STRB = '1' and Rx_LEN = 8 and RxD_SR_3B = '0' then -- 8 bits per character.
            BREAK <= '1'; -- Break condition detected.
        elsif Rx_STATE = Rx_CHECK_FRAME and OPMODE = ASYNC and Rx_SHIFTREG = "000000000" and Rx_STRB = '1' and Rx_LEN = 7 and RxD_SR_3B = '0' then -- 7 bits per character.
            BREAK <= '1'; -- Break condition detected.
        elsif Rx_STATE = Rx_CHECK_FRAME and OPMODE = ASYNC and Rx_SHIFTREG = "000000000" and Rx_STRB = '1' and Rx_LEN = 6 and RxD_SR = '0' then -- 6 bits per character.
            BREAK <= '1'; -- Break condition detected.
        elsif Rx_STATE = Rx_CHECK_FRAME and OPMODE = ASYNC and Rx_SHIFTREG = "000000000" and Rx_STRB = '1' and Rx_LEN = 5 and RxD_SR = '0' then -- 5 bits per character.
            BREAK <= '1'; -- Break condition detected.
        elsif OPMODE = ASYNC and Rx_STRB = '1' and Rx_LEN = 8 and RxD_SR_3B = '1' then -- 8 bits per character.
            BREAK <= '0'; -- Break condition detected.
        elsif OPMODE = ASYNC and Rx_STRB = '1' and Rx_LEN = 7 and RxD_SR_3B = '1' then -- 7 bits per character.
            BREAK <= '0'; -- Break condition detected.
        elsif OPMODE = ASYNC and Rx_STRB = '1' and Rx_LEN = 6 and RxD_SR = '1' then -- 6 bits per character.
            BREAK <= '0'; -- Break condition detected.
        elsif OPMODE = ASYNC and Rx_STRB = '1' and Rx_LEN = 5 and RxD_SR = '1' then -- 5 bits per character.
            BREAK <= '0'; -- Break condition detected.
        end if;
	end process RECEIVER_SHIFTREG;	

	Rx_PARITY_GEN: process(Rx_SHIFTREG, PAR_EN, PAR_EVEN_ODDn, Rx_LEN)
	variable EVEN	: std_logic;
    variable PAR01  : std_logic;
    variable PAR23  : std_logic;
    variable PAR45  : std_logic;
    variable PAR67  : std_logic;
    variable PAR03  : std_logic;
    variable PAR47  : std_logic;
	begin
        PAR01 := Rx_SHIFTREG(0) xor Rx_SHIFTREG(1);
        PAR23 := Rx_SHIFTREG(2) xor Rx_SHIFTREG(3);
        PAR45 := Rx_SHIFTREG(4) xor Rx_SHIFTREG(5);
        PAR67 := Rx_SHIFTREG(6) xor Rx_SHIFTREG(7);
        PAR03 := PAR01 xor PAR23;
        PAR47 := PAR45 xor PAR67;

        case Rx_LEN is
            when 8 =>
                EVEN := PAR03 xor PAR47;
            when 7 =>
                EVEN := PAR03 xor PAR45 xor Rx_SHIFTREG(6);
            when 6 =>
                EVEN := PAR03 xor PAR45;
            when others => -- 5 bits per character plus parity.
                EVEN := PAR03 xor Rx_SHIFTREG(4);
        end case;

        if PAR_EN = '0' then
            Rx_PARITY <= '0';
        elsif PAR_EVEN_ODDn = '1' then -- Even parity.
            Rx_PARITY <= EVEN; 
        else -- Odd parity.
            Rx_PARITY <= not EVEN;
        end if;
	end process Rx_PARITY_GEN;

    Tx_LEN <= 8 when Tx_BITS = "11" else
              7 when Tx_BITS = "01" else
              6 when Tx_BITS = "10" else
              5 when Tx_BITS = "00" and Tx_BUFFER(7 downto 5) = "000" else
              4 when Tx_BITS = "00" and Tx_BUFFER(7 downto 4) = "1000" else
              3 when Tx_BITS = "00" and Tx_BUFFER(7 downto 3) = "11000" else
              2 when Tx_BITS = "00" and Tx_BUFFER(7 downto 2) = "111000" else 
              1; -- Tx_BITS = "00" and Tx_BUFFER(7 downto 1) = "1111000".

    P_TRANSMIT_BUFFER: process
    variable LOCK       : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if (RESET or RES) = '1' then
            Tx_BUFFER_EMPTY <= '1';
        elsif SEND_ABORT = '1' then
            Tx_BUFFER_EMPTY <= '1';
        elsif Tx_STATE /= Tx_SHIFTOUT and Tx_NSTATE = Tx_SHIFTOUT then
            Tx_BUFFER_EMPTY <= '1';
        elsif WR8_WR = '1' and LOCK = false then
            Tx_BUFFER <= BUFFER_IN;
            Tx_BUFFER_EMPTY <= '0';
            LOCK := true;
        elsif WR8_WR = '0' then
            LOCK := false;
        end if;
    end process P_TRANSMIT_BUFFER;

    Tx_PARITY_GEN: process (PAR_EN, PAR_EVEN_ODDn, Tx_LEN, Tx_BUFFER)
	variable EVEN	: std_logic;
    variable PAR01  : std_logic;
    variable PAR23  : std_logic;
    variable PAR45  : std_logic;
    variable PAR67  : std_logic;
    variable PAR03  : std_logic;
    variable PAR47  : std_logic;
	begin
        PAR01 := Tx_BUFFER(0) xor Tx_BUFFER(1);
        PAR23 := Tx_BUFFER(2) xor Tx_BUFFER(3);
        PAR45 := Tx_BUFFER(4) xor Tx_BUFFER(5);
        PAR67 := Tx_BUFFER(6) xor Tx_BUFFER(7);
        PAR03 := PAR01 xor PAR23;
        PAR47 := PAR45 xor PAR67;

        case Tx_LEN is
            when 8 => EVEN := PAR03 xor PAR47;
            when 7 => EVEN := PAR03 xor PAR45 xor Tx_BUFFER(6);
            when 6 => EVEN := PAR03 xor PAR45;
            when 5 => EVEN := PAR03 xor Tx_BUFFER(4);
            when 4 => EVEN := PAR03;
            when 3 => EVEN := PAR01 xor Tx_BUFFER(2);
            when 2 => EVEN := PAR01;
            when 1 => EVEN := Tx_BUFFER(0);
        end case;

        if PAR_EN = '0' then
            Tx_PARITY <= '0';
        elsif PAR_EVEN_ODDn = '1' then -- Even parity.
            Tx_PARITY <= EVEN; 
        else -- Odd parity.
            Tx_PARITY <= not EVEN;
        end if;
	end process Tx_PARITY_GEN;

    -- This is the transmit shift register parallel data. Be aware that the start bits '0' is adjusted right hand side and the
    -- stop bits '1' are adjusted left hand side.
    Tx_SR_DATAIN <= "000111" & Tx_PARITY & Tx_BUFFER & '0' when OPMODE = ASYNC and Tx_LEN = 8 and SYNC_MODE = "01" else
                    "0000111" & Tx_PARITY & Tx_BUFFER(6 downto 0) & '0' when OPMODE = ASYNC and Tx_LEN = 7 and PAR_EN = '1' else
                    "00000111" & Tx_PARITY & Tx_BUFFER(5 downto 0) & '0' when OPMODE = ASYNC and Tx_LEN = 6 and PAR_EN = '1' else
                    "000000111" & Tx_PARITY & Tx_BUFFER(4 downto 0) & '0' when OPMODE = ASYNC and Tx_LEN = 5 and PAR_EN = '1' else
                    "0000000111" & Tx_PARITY & Tx_BUFFER(3 downto 0) & '0' when OPMODE = ASYNC and Tx_LEN = 4 and PAR_EN = '1' else
                    "00000000111" & Tx_PARITY & Tx_BUFFER(2 downto 0) & '0' when OPMODE = ASYNC and Tx_LEN = 3 and PAR_EN = '1' else
                    "000000000111" & Tx_PARITY & Tx_BUFFER(1 downto 0) & '0' when OPMODE = ASYNC and Tx_LEN = 2 and PAR_EN = '1' else
                    "0000000000111" & Tx_PARITY & Tx_BUFFER(0) & '0' when OPMODE = ASYNC and Tx_LEN = 1 and PAR_EN = '1' else
                    "0000111" & Tx_BUFFER & '0' when OPMODE = ASYNC and Tx_LEN = 8 and SYNC_MODE = "01" else
                    "00000111" & Tx_BUFFER(6 downto 0) & '0' when OPMODE = ASYNC and Tx_LEN = 7 else
                    "000000111" & Tx_BUFFER(5 downto 0) & '0' when OPMODE = ASYNC and Tx_LEN = 6 else
                    "0000000111" & Tx_BUFFER(4 downto 0) & '0' when OPMODE = ASYNC and Tx_LEN = 5 else
                    "00000000111" & Tx_BUFFER(3 downto 0) & '0' when OPMODE = ASYNC and Tx_LEN = 4 else
                    "000000000111" & Tx_BUFFER(2 downto 0) & '0' when OPMODE = ASYNC and Tx_LEN = 3 else
                    "0000000000111" & Tx_BUFFER(1 downto 0) & '0' when OPMODE = ASYNC and Tx_LEN = 2 else
                    "00000000000111" & Tx_BUFFER(0) & '0' when OPMODE = ASYNC and Tx_LEN = 1 else
                    "00000000" & Tx_BUFFER; -- This is for the modes BSYNC, MSYNC and SDLC.
                    
	TRANSMITTER_SHIFTREG: process
    variable Tx_SHIFTREG    : std_logic_vector(15 downto 0);
    variable BITCNT         : integer range 0 to 15;
    variable CRC_SHIFT_16   : std_logic_vector(16 downto 1);
    variable ONE_CNT_T      : integer range 0 to 7;
    variable CRC_EN         : std_logic;
	begin
		wait until CLK = '1' and CLK' event;
        if RES_Tx_CRC = '1' and CRC_PRES = '1' then
            CRC_SHIFT_16 := (others => '1');
        elsif RES_Tx_CRC = '1' then
            CRC_SHIFT_16 := (others => '0');
        elsif SDLC_HDLC = '1' and Tx_STATE = Tx_SYNC_1 and CRC_PRES = '1' then
            CRC_SHIFT_16 := (others => '1');
        elsif SDLC_HDLC = '1' and Tx_STATE = Tx_SYNC_1 then
            CRC_SHIFT_16 := (others => '0');
        end if;
    
        if RESET = '1' then
            ONE_CNT_T := 0;
        elsif Tx_STRB = '1' and ONE_CNT_T < 5 and RxD_SR = '1' then
            ONE_CNT_T := ONE_CNT_T + 1;
        elsif Tx_STRB = '1' then
            ONE_CNT_T := 0;
        end if;

		if Tx_STATE = IDLE and Tx_NSTATE = IDLE then
			Tx_SHIFTREG := (others => '0');
            BITCNT := 0;
            CRC_SHIFT_16 := (others => '1');
        elsif Tx_STATE = IDLE and Tx_NSTATE = Tx_START then -- Asynchronous operation.
            Tx_SHIFTREG := Tx_SR_DATAIN;
        elsif Tx_STATE /= Tx_MARK_IDLE and Tx_NSTATE = Tx_MARK_IDLE then
            Tx_SHIFTREG := (others => '1');
        elsif Tx_STATE /= Tx_SYNC_1 and Tx_NSTATE = Tx_SYNC_1 then
            Tx_SHIFTREG(7 downto 0) := SYNC_SDLC_FLAG;
        elsif Tx_STATE /= Tx_SYNC_2 and Tx_NSTATE = Tx_SYNC_2 then
            Tx_SHIFTREG(7 downto 0) := SYNC_SDLC_ADR;
        elsif (Tx_STATE = Tx_SYNC_1 or Tx_STATE = Tx_SYNC_2) and Tx_NSTATE = Tx_SHIFTOUT then
            Tx_SHIFTREG := Tx_SR_DATAIN;
        elsif Tx_STATE /= Tx_ABORT_FLAG and Tx_NSTATE = Tx_ABORT_FLAG then
            Tx_SHIFTREG(7 downto 0) := (others => '1');
        elsif Tx_STATE /= Tx_ABORT and Tx_NSTATE = Tx_ABORT then
            Tx_SHIFTREG(7 downto 0) := (others => '1');
        elsif Tx_STATE /= Tx_CRC and Tx_NSTATE = Tx_CRC then
            Tx_SHIFTREG(15 downto 0) := CRC_SHIFT_16;
        elsif Tx_STATE /= Tx_CLOSE and Tx_NSTATE = Tx_CLOSE then
            Tx_SHIFTREG(7 downto 0) := SYNC_SDLC_FLAG;
        elsif Tx_INH = '1' or SEND_BREAK = '1' then
            null; -- Stop shifting.
        elsif Tx_STATE = Tx_START and Tx_STRB = '1' then
            Tx_SHIFTREG := '0' & Tx_SHIFTREG(15 downto 1); -- Shift right.
        elsif Tx_STATE = Tx_MARK_IDLE and  Tx_STRB = '1' then
            if BITCNT = 8 then
                Tx_SHIFTREG(7 downto 0) := x"FF"; -- Reload idle pattern.
            else
                Tx_SHIFTREG := '0' & Tx_SHIFTREG(15 downto 1); -- Shift right.
            end if;
            BITCNT := (BITCNT + 1) mod 8;
        elsif Tx_STATE = Tx_CLOSE and  Tx_STRB = '1' then
            if BITCNT = 8 then
                Tx_SHIFTREG(7 downto 0) := SYNC_SDLC_FLAG; -- Reload SYNC pattern.
            else
                Tx_SHIFTREG := '0' & Tx_SHIFTREG(15 downto 1); -- Shift right.
            end if;
            BITCNT := (BITCNT + 1) mod 8;
        elsif Tx_STATE = Tx_SYNC_1 and  Tx_STRB = '1' then
            if BITCNT = 8 then
                Tx_SHIFTREG(7 downto 0) := SYNC_SDLC_FLAG; -- Reload sync character.
            else
                Tx_SHIFTREG := '0' & Tx_SHIFTREG(15 downto 1); -- Shift right.
            end if;
            BITCNT := (BITCNT + 1) mod 8;
        elsif Tx_STATE = Tx_SHIFTOUT and  Tx_STRB = '1' then
            if OPMODE = SDLC and ONE_CNT_T = 5 and Tx_SHIFTREG(0) = '1' then
                null; -- Wait and stuff a zero.
            else
                Tx_SHIFTREG := '0' & Tx_SHIFTREG(15 downto 1); -- Shift right.
            end if;

            if OPMODE = ASYNC then
                BITCNT := (BITCNT + 1) mod 16;
            else
                BITCNT := (BITCNT + 1) mod 8;
            end if;
        elsif Tx_STATE = Tx_STOP_1 and  Tx_STRB = '1' then
            Tx_SHIFTREG := '0' & Tx_SHIFTREG(15 downto 1); -- Shift right.
            BITCNT := (BITCNT + 1) mod 8;
        elsif Tx_STATE = Tx_STOP_2 and  Tx_STRB = '1' then
            Tx_SHIFTREG := '0' & Tx_SHIFTREG(15 downto 1); -- Shift right.
            BITCNT := (BITCNT + 1) mod 8;
        elsif Tx_STATE = Tx_ABORT_FLAG and  Tx_STRB = '1' then
            Tx_SHIFTREG := '0' & Tx_SHIFTREG(15 downto 1); -- Shift right.
            BITCNT := (BITCNT + 1) mod 8;
        elsif Tx_STATE = Tx_ABORT and  Tx_STRB = '1' then
            Tx_SHIFTREG := '0' & Tx_SHIFTREG(15 downto 1); -- Shift right.
            BITCNT := (BITCNT + 1) mod 8;
        elsif Tx_STATE = Tx_CRC and  Tx_STRB = '1' then
            if OPMODE = SDLC and ONE_CNT_T = 5 and Tx_SHIFTREG(0) = '1' then
                null; -- Wait and stuff a zero.
            else
                Tx_SHIFTREG := '0' & Tx_SHIFTREG(15 downto 1); -- Shift right.
            end if;
            BITCNT := (BITCNT + 1) mod 8;
        elsif Tx_STATE = Tx_CLOSE and  Tx_STRB = '1' then
            Tx_SHIFTREG := '0' & Tx_SHIFTREG(15 downto 1); -- Shift right.
            BITCNT := (BITCNT + 1) mod 8;
        end if;
        
        -- This is the transmitter multiplexer.
        if SEND_BREAK = '1' and Tx_STRB = '1' then
            TxD_SR <= '0';
        elsif OPMODE = ASYNC and Tx_STATE = IDLE then
            TxD_SR <= '1';
        elsif OPMODE = ASYNC then
            TxD_SR <= Tx_SHIFTREG(0);
        elsif OPMODE = SDLC and Tx_STATE = Tx_SHIFTOUT and ONE_CNT_T = 5 and Tx_SHIFTREG(0) = '1' and Tx_STRB = '1' then
            TxD_SR <= '0'; -- Stuff a zero.
        elsif OPMODE = SDLC and Tx_STATE = Tx_CRC and ONE_CNT_T = 5 and Tx_SHIFTREG(0) = '1' and Tx_STRB = '1' then
            TxD_SR <= '0'; -- Stuff a zero.
        elsif Tx_STRB = '1' then
            TxD_SR <= Tx_SHIFTREG(0);
        end if;

        if Tx_STATE = IDLE then
            CRC_EN := '0';
        elsif (OPMODE = BSYNC or OPMODE = MSYNC) and Tx_STATE = Tx_SHIFTOUT and Tx_STRB = '1' and BITCNT = 8 then -- Switch at character boundaries.
            CRC_EN := Tx_CRC_EN;
        end if;

        if (OPMODE = BSYNC or OPMODE = MSYNC) and CRC_EN = '0' then
            null; -- CRC checker disabled.
        elsif Tx_STATE = Tx_SHIFTOUT and Tx_STRB = '1' and CRC16_SDLCn = '1' then
            -- The CRC polynomial is G(x) = x^16 + x^15 + x^2 + 1; right shift.
            CRC_SHIFT_16 := (CRC_SHIFT_16(15) xor CRC_SHIFT_16(16) xor Tx_SHIFTREG(0)) & CRC_SHIFT_16(14 downto 3) & 
                            (CRC_SHIFT_16(2) xor CRC_SHIFT_16(16) xor Tx_SHIFTREG(0)) & CRC_SHIFT_16(1) & (CRC_SHIFT_16(16) xor Tx_SHIFTREG(0));
        elsif Tx_STATE = Tx_SHIFTOUT and Tx_STRB = '1' then
            -- The CRC polynomial is G(x) = x^16 + x^12 + x^5 + 1; right shift.
            CRC_SHIFT_16 := CRC_SHIFT_16(15 downto 13) & (CRC_SHIFT_16(12) xor CRC_SHIFT_16(16) xor Tx_SHIFTREG(0)) & CRC_SHIFT_16(11 downto 6) &
                            (CRC_SHIFT_16(5) xor CRC_SHIFT_16(16) xor Tx_SHIFTREG(0)) & CRC_SHIFT_16(4 downto 1) & (CRC_SHIFT_16(16) xor Tx_SHIFTREG(0));
        end if;

		if Tx_STATE = IDLE then
        elsif OPMODE = ASYNC and PAR_EN = '1' and Tx_LEN = BITCNT then -- Character plus parity bit.
            Tx_SHFT_RDY <= '1';
        elsif OPMODE = ASYNC and PAR_EN = '0' and Tx_LEN + 1 = BITCNT then -- Character only.
            Tx_SHFT_RDY <= '1';
        elsif BITCNT = 8 then -- For BSYNC, MSYNC and SDLC.
            Tx_SHFT_RDY <= '1';
        end if;

        if (RESET or RES) = '1' then
            ALL_SENT <= '0';
        elsif OPMODE /= ASYNC then
            ALL_SENT <= '1';
        elsif WR8_WR = '1' then
            ALL_SENT <= '0';
        elsif OPMODE = ASYNC and Tx_STATE /= IDLE and Tx_NSTATE = IDLE and Tx_BUFFER_EMPTY = '1' then
            ALL_SENT <= '1';
        end if;
	end process TRANSMITTER_SHIFTREG;	

    NRZI_ENCODER: process
    -- This logic provides a NRZI logic. It works
    -- on the positive and the negative transmitter
    -- clock edges. To handle this we use two edge
    -- detectors (LOCK_N, LOCK_P).
    variable BMC_C  : std_logic;
    variable BMC_D  : std_logic;
    variable LOCK_P : boolean;
    variable LOCK_N : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if Tx_CLK = '1' and LOCK_P = false then
            LOCK_P := true;
            if RESET = '1' or RES = '1' then
                BMC_C := '0';
                Tx_NRZI <= '0';
            elsif NRZ_FM = "00" then -- NRZ.
                Tx_NRZI <= TxD_SR;
            elsif NRZ_FM = "01" then -- NRZI.
                Tx_NRZI <= Tx_NRZI xnor TxD_SR;
            elsif NRZ_FM = "10" then -- FM1 (biphase mark).
                Tx_NRZI <= BMC_D xor BMC_C;
                BMC_C := not BMC_C;
            else -- FM0 (biphase space).
                Tx_NRZI <= BMC_D xor BMC_C;
                BMC_C := not BMC_C;
            end if;
        elsif Rx_CLK = '0' then
            LOCK_P := false;
        end if;

        if Tx_CLK = '0' and LOCK_N = false then
            LOCK_N := true;
            if RESET = '1' or RES = '1' then
                BMC_D := '0';
            elsif NRZ_FM = "10" then -- FM1 (biphase mark).
                BMC_D := BMC_D xor NRZI_IN;
            else -- FM0 (biphase space).
                BMC_D := BMC_D xnor NRZI_IN;
            end if;
        elsif Tx_CLK = '1' then
            LOCK_N := false;
        end if;
    end process NRZI_ENCODER;

    -- This is the final Transmitter multiplexer and tri state control.
    TxD <= TxD_I;
    TxD_I <= RxD when LOOP_MODE = '1' and Rx_STATE = Rx_LOOP_INIT else
             '1' when OPMODE = SDLC and Tx_STATE = IDLE else
             '1' when OPMODE = SDLC and NRZ_FM = "01" and TxD_PULLED_HIGH = '1' else -- SDLC with NRZI.
             RxD_D when OPMODE = SDLC and LOOP_MODE = '1' and Rx_STATE = Rx_HUNT else
             RxD_D when AUTO_ECHO = '1' else 
             TxD_SR when OPMODE = ASYNC else Tx_NRZI;

    ON_LOOP <= '1' when Rx_STATE = RX_HUNT or Rx_STATE = Rx_SHIFTIN else '0';
    LOOP_SEND <= '1' when ON_LOOP = '1' and (Tx_STATE = Tx_SHIFTOUT or Tx_STATE = Tx_CRC or Tx_STATE = Tx_ABORT_FLAG) else '0';
end architecture BEHAVIOUR;
