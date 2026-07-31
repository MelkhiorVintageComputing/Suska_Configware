------------------------------------------------------------------------
----                                                                ----
---- Serial Communication Controller SCC_85C30 IP Core              ----
----                                                                ----
---- This model provides an asynchronous SCSI interface compa-      ----
---- tible to the Am85C30 from AMD or ESCC 85C30 from Zilog.        ----
---- This core features all functions of their originals except the ----
---- oscillator for external crystals.                              ----
----                                                                ----
---- This file covers the register section of the SCC chip.         ----
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
-- Revision 2K24A 20240620 WF
--   Minor code optimizations.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity REGISTERS is
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
        RES_A               : buffer std_logic;
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
        RES_B               : buffer std_logic;
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
        RESET               : buffer std_logic;
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
end entity REGISTERS;

architecture BEHAVIOUR of REGISTERS is
type REGISTERARRAY is array(1 to 15) of std_logic_vector(7 downto 0);
signal WRA              : REGISTERARRAY;
signal WRB              : REGISTERARRAY;
signal RRA15            : std_logic_vector(7 downto 0);
signal RRA13            : std_logic_vector(7 downto 0);
signal RRA12            : std_logic_vector(7 downto 0);
signal RRA10            : std_logic_vector(7 downto 0);
signal RRA7             : std_logic_vector(7 downto 0);
signal RRA6             : std_logic_vector(7 downto 0);
signal RRA3             : std_logic_vector(7 downto 0);
signal RRA2             : std_logic_vector(7 downto 0);
signal RRA1             : std_logic_vector(7 downto 0);
signal RRA0             : std_logic_vector(7 downto 0);
signal RRB15            : std_logic_vector(7 downto 0);
signal RRB13            : std_logic_vector(7 downto 0);
signal RRB12            : std_logic_vector(7 downto 0);
signal RRB10            : std_logic_vector(7 downto 0);
signal RRB7             : std_logic_vector(7 downto 0);
signal RRB6             : std_logic_vector(7 downto 0);
signal RRB3             : std_logic_vector(7 downto 0);
signal RRB2             : std_logic_vector(7 downto 0);
signal RRB1             : std_logic_vector(7 downto 0);
signal RRB0             : std_logic_vector(7 downto 0);
signal MIVE             : std_logic_vector(2 downto 0); -- Modified interrupt vector entry.
signal VIS              : std_logic;
signal ADR_PNTR         : integer range 0 to 15;
signal EXTEND_READ_EN_A : std_logic;
signal EXTEND_READ_EN_B : std_logic;
begin
    P_REGISTERS: process
    variable ADR_VAR        : integer range 0 to 15;
    variable LOCK           : boolean;
    variable RESET_DELAY    : std_logic_vector(2 downto 0);
    begin
        wait until CLK = '1' and CLK' event;

        -- The following forces the respective register bits to 
        -- act as a command rather than a flip flop.
        WRA(13)(7 downto 5) <= "000"; -- This is the PLL command.
        WRA(3)(4) <= '0'; -- Etner SYNC/HUNT mode channel A.
        WRB(3)(4) <= '0'; -- Etner SYNC/HUNT mode channel B.

        SEND_ABORT_A <= '0';
        EN_INT_RxCHAR_A <= '0';
        RES_EXT_STAT_INT_A <= '0';
        RES_TxINT_A <= '0';
        RES_ERR_A <= '0';
        RES_IUS_A <= '0';
        RES_Rx_CRC_A <= '0';
        RES_Tx_CRC_A <= '0';
        RES_Tx_UR_EOM_A <= '0';

        SEND_ABORT_B <= '0';
        EN_INT_RxCHAR_B <= '0';
        RES_EXT_STAT_INT_B <= '0';
        RES_TxINT_B <= '0';
        RES_ERR_B <= '0';
        RES_IUS_B <= '0';
        RES_Rx_CRC_B <= '0';
        RES_Tx_CRC_B <= '0';
        RES_Tx_UR_EOM_B <= '0';

        if RESET_DELAY < "101" then -- 5 cycles.
            RESET_DELAY := RESET_DELAY + '1';
        else
            WRB(2)(7) <= '0'; -- Channel A reset.
            WRB(2)(6) <= '0'; -- Channel B reset.
        end if;

        -- This is the address pointer logic. Writing to command register
        -- A or B sets the pointer right after this access. Writing or reading
        -- to any other register clears the pointer after the access.
        if RESET = '1' then -- Hardware reset.
            ADR_PNTR <= 0;
            LOCK := false;
        elsif (CEn = '1' or (RDn = '1' and WRn = '1')) and LOCK = false then
            ADR_PNTR <= 0; -- Reset the pointer after the secont read or write access with DCn low..
        elsif CEn = '1' or (RDn = '1' and WRn = '1') then -- LOCK is true here.
            ADR_PNTR <= ADR_VAR; -- Store the new pointer after the access to the command register.
        elsif CEn = '0' and WRn = '0' and DCn = '0' and ADR_PNTR = 0 and LOCK = false then -- Command register A or B.
            if DATA_IN(5 downto 3) = "001" then        
                ADR_VAR := To_Integer(unsigned(DATA_IN(3 downto 0))); -- Higher register portion.
            else
                ADR_VAR := To_Integer(unsigned('0' & DATA_IN(2 downto 0))); -- Lower register portion.
            end if;
            LOCK := true;
        elsif CEn = '0' and DCn = '0' and ADR_PNTR /= 0 then -- Read or write access to a control register.
            LOCK := false;
        end if;

        if CEn = '0' and WRn = '0' and DCn = '0' and ADR_PNTR = 0 and ABn = '1' then -- Command register A.
            case DATA_IN(5 downto 3) is
                when "011" => SEND_ABORT_A <= '1';
                when "100" => EN_INT_RxCHAR_A <= '1';
                when "010" => RES_EXT_STAT_INT_A <= '1';
                when "101" => RES_TxINT_A <= '1';
                when "110" => RES_ERR_A <= '1';
                when "111" => RES_IUS_A <= '1';
                when others => null;
            end case;

            case DATA_IN(7 downto 6) is
                when "01" => RES_Rx_CRC_A <= '1';
                when "10" => RES_Tx_CRC_A <= '1';
                when "11" => RES_Tx_UR_EOM_A <= '1';
                when others => null;
            end case;
        elsif CEn = '0' and WRn = '0' and DCn = '0' and ADR_PNTR = 0 and ABn = '0' then -- Command register B.
            case DATA_IN(5 downto 3) is
                when "011" => SEND_ABORT_B <= '1';
                when "100" => EN_INT_RxCHAR_B <= '1';
                when "010" => RES_EXT_STAT_INT_B <= '1';
                when "101" => RES_TxINT_B <= '1';
                when "110" => RES_ERR_B <= '1';
                when "111" => RES_IUS_B <= '1';
                when others => null;
            end case;

            case DATA_IN(7 downto 6) is
                when "01" => RES_Rx_CRC_B <= '1';
                when "10" => RES_Tx_CRC_B <= '1';
                when "11" => RES_Tx_UR_EOM_B <= '1';
                when others => null;
            end case;
        elsif CEn = '0' and WRn = '0' and DCn = '0' and ABn = '1' then
            case ADR_PNTR is
                when 2 => -- WRA(2) is the common register number 2.
                    WRA(ADR_PNTR) <= DATA_IN;
                when 7 =>
                    if WRA(15)(0) = '1' then
                        WRA(8) <= DATA_IN; -- This is WRA7'
                    else
                        WRA(ADR_PNTR) <= DATA_IN;
                    end if;
                when 9 => -- WRB(2) is the common register number 9.
                    WRB(2) <= DATA_IN;
                    RESET_DELAY := "000";
                when 10 | 11 | 12 | 13 | 14 | 15 =>
                    WRA(ADR_PNTR - 1) <= DATA_IN; -- Reallocate...
                when others =>
                    WRA(ADR_PNTR) <= DATA_IN;
            end case;
        elsif CEn = '0' and WRn = '0' and DCn = '0' and ABn = '0' then
            case ADR_PNTR is
                when 2 => -- WRA(2) is the common register number 2.
                    WRA(ADR_PNTR) <= DATA_IN;
                when 7 =>
                    if WRB(15)(0) = '1' then
                        WRB(8) <= DATA_IN; -- This is WRB7'
                    else
                        WRB(ADR_PNTR) <= DATA_IN;
                    end if;
                when 9 => -- WRB(2) is the common register number 9.
                    WRB(2) <= DATA_IN;
                when 10 | 11 | 12 | 13 | 14 | 15 =>
                    WRB(ADR_PNTR - 1) <= DATA_IN; -- Reallocate...
                when others =>
                    WRB(ADR_PNTR) <= DATA_IN;
            end case;
        end if;

        if (RESET = '1' or RES_A = '1') then -- Channel or hardware reset.
            ADR_PNTR <= 0;
            WRA(1)(7 downto 6) <= "00";
            WRA(1)(4 downto 3) <= "00";
            WRA(1)(2 downto 0) <= "000";
            WRA(3)(0) <= '0';
            WRA(4)(2) <= '1';
            WRA(5)(7) <= '0';
            WRA(5)(4 downto 1) <= "0000";
            WRA(15) <= x"F8";
        end if;

        if (RESET = '1' or RES_B = '1') then -- Channel or hardware reset.
            ADR_PNTR <= 0;
            WRB(1)(7 downto 6) <= "00";
            WRB(1)(4 downto 3) <= "00";
            WRB(1)(2 downto 0) <= "000";
            WRB(3)(0) <= '0';
            WRB(4)(2) <= '1';
            WRB(5)(7) <= '0';
            WRB(5)(4 downto 1) <= "0000";
            WRB(15) <= x"F8";    
        end if;

        if RESET = '1' then -- Hardware reset.
            WRA(9)(7 downto 2) <= "110000";
            WRA(10) <= X"00";
            WRA(14)(5 downto 0) <= "100000";
        elsif RES_A = '1' then -- Channel reset.
            WRA(9)(5) <= '0';
            WRA(10)(7) <= '0';
            WRA(10)(4 downto 0) <= "00000";
            WRA(14)(5 downto 2) <= "1000";
        end if;

        if RESET = '1' then -- Hardware reset.
            WRB(9)(7 downto 2) <= "110000";
            WRB(10) <= X"00";
            WRB(14)(5 downto 0) <= "100000";
        elsif RES_B = '1' then -- Channel reset.
            WRB(9)(5) <= '0';
            WRB(10)(7) <= '0';
            WRB(10)(4 downto 0) <= "00000";
            WRB(14)(5 downto 2) <= "1000";
        end if;
    end process P_REGISTERS;

    BUFFER_A_OUT <= DATA_IN;
    BUFFER_B_OUT <= DATA_IN;

    DATA_EN <= '1' when CEn = '0' and RDn = '0' else '0'; 
    DATA_OUT <= BUFFER_A_IN when DCn = '1' and ABn = '1' else
                BUFFER_B_IN when DCn = '1' and ABn = '0' else
                BUFFER_A_IN when ABn = '1' and ADR_PNTR = 8 else
                BUFFER_B_IN when ABn = '0' and ADR_PNTR = 8 else
                RRA15 when ABn = '1' and (ADR_PNTR = 11 or ADR_PNTR = 15) else
                RRB15 when ABn = '0' and (ADR_PNTR = 11 or ADR_PNTR = 15) else
                RRA13 when ABn = '1' and ADR_PNTR = 13 else
                RRB13 when ABn = '0' and ADR_PNTR = 13 else
                RRA12 when ABn = '1' and ADR_PNTR = 12 else
                RRB12 when ABn = '0' and ADR_PNTR = 12 else
                RRA10 when ABn = '1' and (ADR_PNTR = 10 or ADR_PNTR = 14) else
                RRB10 when ABn = '0' and (ADR_PNTR = 10 or ADR_PNTR = 14) else
                RRA7 when ABn = '1' and ADR_PNTR = 7 and WRA(4)(5 downto 2) = "1000" and WRA(15)(2) = '1' else -- Frame FIFO enabled.
                RRB7 when ABn = '0' and ADR_PNTR = 7 and WRB(4)(5 downto 2) = "1000" and WRB(15)(2) = '1' else -- Frame FIFO enabled.
                RRA6 when ABn = '1' and ADR_PNTR = 6 and WRA(4)(5 downto 2) = "1000" and WRA(15)(2) = '1' else -- Frame FIFO enabled.
                RRB6 when ABn = '0' and ADR_PNTR = 6 and WRB(4)(5 downto 2) = "1000" and WRB(15)(2) = '1' else -- Frame FIFO enabled.
                RRA3 when ABn = '1' and (ADR_PNTR = 3 or ADR_PNTR = 7) else
                RRB3 when ABn = '0' and (ADR_PNTR = 3 or ADR_PNTR = 7) else
                RRA2 when ABn = '1' and (ADR_PNTR = 2 or ADR_PNTR = 6) else
                RRB2 when ABn = '0' and (ADR_PNTR = 2 or ADR_PNTR = 6) else
                RRA1 when ABn = '1' and (ADR_PNTR = 1 or ADR_PNTR = 5) else
                RRB1 when ABn = '0' and (ADR_PNTR = 1 or ADR_PNTR = 5) else
                RRA0 when ABn = '1' and (ADR_PNTR = 0 or ADR_PNTR = 4) else
                RRB0 when ABn = '0' and (ADR_PNTR = 0 or ADR_PNTR = 4) else
                WRA(10) when ABn = '1' and ADR_PNTR = 11 and EXTEND_READ_EN_A = '1' else
                WRB(10) when ABn = '0' and ADR_PNTR = 11 and EXTEND_READ_EN_B = '1' else
                WRA(5) when ABn = '1' and ADR_PNTR = 5 and EXTEND_READ_EN_A = '1' else
                WRB(5) when ABn = '0' and ADR_PNTR = 5 and EXTEND_READ_EN_B = '1' else
                WRA(4) when ABn = '1' and ADR_PNTR = 4 and EXTEND_READ_EN_A = '1' else
                WRB(4) when ABn = '0' and ADR_PNTR = 4 and EXTEND_READ_EN_B = '1' else
                WRA(3) when ABn = '1' and ADR_PNTR = 9 and EXTEND_READ_EN_A = '1' else
                WRB(3) when ABn = '0' and ADR_PNTR = 9 and EXTEND_READ_EN_B = '1' else
                x"00"; -- Others are read back zero.

    RRA1_RD <= '1' when CEn = '0' and RDn = '0' and DCn = '0' and ABn = '1' and (ADR_PNTR = 1 or ADR_PNTR = 5)else '0';
    RRB1_RD <= '1' when CEn = '0' and RDn = '0' and DCn = '0' and ABn = '0' and (ADR_PNTR = 1 or ADR_PNTR = 5)else '0';
    RRA0_RD <= '1' when CEn = '0' and RDn = '0' and DCn = '0' and ABn = '1' and (ADR_PNTR = 0 or ADR_PNTR = 4)else '0';
    RRB0_RD <= '1' when CEn = '0' and RDn = '0' and DCn = '0' and ABn = '0' and (ADR_PNTR = 0 or ADR_PNTR = 4)else '0';
    RRA6_RD <= '1' when CEn = '0' and RDn = '0' and DCn = '0' and ABn = '1' and ADR_PNTR = 6 and WRA(4)(5 downto 2) = "1000" and WRA(15)(2) = '1' else '0';
    RRA7_RD <= '1' when CEn = '0' and RDn = '0' and DCn = '0' and ABn = '1' and ADR_PNTR = 7 and WRA(4)(5 downto 2) = "1000" and WRA(15)(2) = '1' else '0';
    RRB6_RD <= '1' when CEn = '0' and RDn = '0' and DCn = '0' and ABn = '0' and ADR_PNTR = 6 and WRB(4)(5 downto 2) = "1000" and WRB(15)(2) = '1' else '0'; -- Frame FIFO enabled.
    RRB7_RD <= '1' when CEn = '0' and RDn = '0' and DCn = '0' and ABn = '0' and ADR_PNTR = 7 and WRB(4)(5 downto 2) = "1000" and WRB(15)(2) = '1' else '0'; -- Frame FIFO enabled.

    WRA8_WR <= '1' when CEn = '0' and WRn = '0' and DCn = '1' and ABn = '1' else
               '1' when CEn = '0' and WRn = '0' and DCn = '0' and ABn = '1' and ADR_PNTR = 8 else '0';
    RRA8_RD <= '1' when CEn = '0' and RDn = '0' and DCn = '1' and ABn = '1' else
               '1' when CEn = '0' and RDn = '0' and DCn = '0' and ABn = '1' and ADR_PNTR = 8 else '0';

    WRB8_WR <= '1' when CEn = '0' and WRn = '0' and DCn = '1' and ABn = '0' else
               '1' when CEn = '0' and WRn = '0' and DCn = '0' and ABn = '0' and ADR_PNTR = 8 else '0';
    RRB8_RD <= '1' when CEn = '0' and RDn = '0' and DCn = '1' and ABn = '0' else
               '1' when CEn = '0' and RDn = '0' and DCn = '0' and ABn = '0' and ADR_PNTR = 8 else '0';

    -- These are the modified interrupt vector entries:
    MIVE <= '1' & STATUS_A when (Rx_IP_A or Tx_IP_A or EXT_STAT_IP_A) = '1' and WRB(2)(4) = '0' else
            '0' & STATUS_B when (Rx_IP_B or Tx_IP_B or EXT_STAT_IP_B) = '1' and WRB(2)(4) = '0' else
            STATUS_A(0) & STATUS_A(1) & '1' when (Rx_IP_A or Tx_IP_A or EXT_STAT_IP_A) = '1' else
            STATUS_B(0) & STATUS_B(1) & '0' when (Rx_IP_B or Tx_IP_B or EXT_STAT_IP_B) = '1' else "000";

    RRA15 <= WRA(15);
    RRA13 <= WRA(12); -- Timer constant high byte.
    RRA12 <= WRA(11); -- Timer constant low byte.
    RRA10 <= ONE_CLK_MISS_A & TWO_CLK_MISS_A & '0' & LOOP_SEND_A & "00" & ON_LOOP_A & '0';
    RRA7 <= BUFFER_A_IN; -- Status and byte counter high.
    RRA6 <= BUFFER_A_IN; -- Byte counter low.
    RRA3 <= "00" & Rx_IP_A & Tx_IP_A & EXT_STAT_IP_A & Rx_IP_B & Tx_IP_B & EXT_STAT_IP_B;
    RRA2 <= WRA(2); -- Interrupt vector.
    RRA1 <= BUFFER_A_IN; -- Status.
    RRA0 <= BUFFER_A_IN; -- RxTx status.
    RRB15 <= WRB(15);
    RRB13 <= WRB(12); -- Timer constant high byte.
    RRB12 <= WRB(11); -- Timer constant low byte.
    RRB10 <= ONE_CLK_MISS_B & TWO_CLK_MISS_B & '0' & LOOP_SEND_B & "00" & ON_LOOP_B & '0';
    RRB7 <= BUFFER_B_IN; -- Status and byte counter high.
    RRB6 <= BUFFER_B_IN; -- Byte counter low.
    RRB3 <= x"00";
    RRB2 <= WRA(2)(7 downto 4) & MIVE & WRA(2)(0) when WRB(2)(4) = '0' else WRA(2)(7) & MIVE & WRA(2)(3 downto 0); -- Modified interrupt vector.
    RRB1 <= BUFFER_B_IN; -- Status.
    RRB0 <= BUFFER_A_IN; -- RxTx status.

    -- Write register 15A:
    BREAK_ABORT_IE_A <= WRA(14)(7);
    EOM_IE_A <= WRA(14)(6);
    CTS_IE_A <= WRA(14)(5);
    SYNC_HUNT_IE_A <= WRA(14)(4);
    DCD_IE_A <= WRA(14)(3);
    FRAME_FIFO_EN_A <= WRA(14)(2);
    ZCOUNT_IE_A <= WRA(14)(1);
    SDLC_HDLC_A <= WRA(14)(0);
    
    -- Write register 15B:
    BREAK_ABORT_IE_B <= WRB(14)(7);
    EOM_IE_B <= WRB(14)(6);
    CTS_IE_B <= WRB(14)(5);
    SYNC_HUNT_IE_B <= WRB(14)(4);
    DCD_IE_B <= WRB(14)(3);
    FRAME_FIFO_EN_B <= WRB(14)(2);
    ZCOUNT_IE_B <= WRB(14)(1);
    SDLC_HDLC_B <= WRB(14)(0);

    -- Write register 14A:
    DPLL_COMMAND_A <= WRA(13)(7 downto 5);
    LOOPBACK_A <= WRA(13)(4);
    AUTO_ECHO_A <= WRA(13)(3);
    DTRn_REQ_A <= WRA(13)(2);
    BR_GEN_SRC_A <= WRA(13)(1);
    BR_GEN_EN_A <= WRA(13)(0);

    -- Write register 14B:
    DPLL_COMMAND_B <= WRB(13)(7 downto 5);
    LOOPBACK_B <= WRB(13)(4);
    AUTO_ECHO_B <= WRB(13)(3);
    DTRn_REQ_B <= WRB(13)(2);
    BR_GEN_SRC_B <= WRB(13)(1);
    BR_GEN_EN_B <= WRB(13)(0);

    -- Write register 13A:
    TCA(15 downto 8) <= WRA(12);

    -- Write register 12A:
    TCA(7 downto 0) <= WRA(11);

    -- Write register 13B:
    TCB(15 downto 8) <= WRB(12);

    -- Write register 12B:
    TCB(7 downto 0) <= WRB(11);

    -- Write register 11A:
    XTAL_A <= WRA(10)(7);
    Rx_CLK_SEL_A <= WRA(10)(6 downto 5);
    Tx_CLK_SEL_A <= WRA(10)(4 downto 3);
    TRXCn_SEL_A <= WRA(10)(2 downto 0);

    -- Write register 11B:
    XTAL_B <= WRB(10)(7);
    Rx_CLK_SEL_B <= WRB(10)(6 downto 5);
    Tx_CLK_SEL_B <= WRB(10)(4 downto 3);
    TRXCn_SEL_B <= WRB(10)(2 downto 0);

    -- Write register 10A:
    CRC_PRES_A <= WRA(9)(7);
    NRZ_FM_A <= WRA(9)(6 downto 5);
    GO_ACTIVE_ON_POLL_A <= WRA(9)(4);
    MARK_FLAGn_A <= WRA(9)(3);
    ABORT_FLAGn_A <= WRA(9)(2);
    LOOP_MODE_A <= WRA(9)(1);
    B6_B8n_A <= WRA(9)(0);

    -- Write register 10B:
    CRC_PRES_B <= WRB(9)(7);
    NRZ_FM_B <= WRB(9)(6 downto 5);
    GO_ACTIVE_ON_POLL_B <= WRB(9)(4);
    MARK_FLAGn_B <= WRB(9)(3);
    ABORT_FLAGn_B <= WRB(9)(2);
    LOOP_MODE_B <= WRB(9)(1);
    B6_B8n_B <= WRB(9)(0);

    -- Write register 9:
    RESET <= '1' when WRB(2)(7 downto 6) = "11" else 
             '1' when RDn = '0' and WRn = '0' else '0';
    RES_A <= '1' when WRB(2)(7 downto 6) = "10" else '0';
    RES_B <= '1' when WRB(2)(7 downto 6) = "01" else '0';
    INTACKn_INH <= WRB(2)(5);
    MIE <= WRB(2)(3);
    DLC <= WRB(2)(2);
    NV  <= WRB(2)(1);
    VIS <= WRB(2)(0);

    -- Write register 7A':
    EXTEND_READ_EN_A <= WRA(8)(6);
    CRC_CHECK_RCVD_A <= WRA(8)(5);
    FAST_DTR_A <= WRA(8)(4);
    TxD_PULLED_HIGH_A <= WRA(8)(3);
    AUTO_RTS_A <= WRA(8)(2);
    AUTO_EOM_LRES_A <= WRA(8)(1);
    AUTO_Tx_FLAG_A <= WRA(8)(0);

    -- Write register 7B':
    EXTEND_READ_EN_B <= WRB(8)(6);
    CRC_CHECK_RCVD_B <= WRB(8)(5);
    FAST_DTR_B <= WRB(8)(4);
    TxD_PULLED_HIGH_B <= WRB(8)(3);
    AUTO_RTS_B <= WRB(8)(2);
    AUTO_EOM_LRES_B <= WRB(8)(1);
    AUTO_Tx_FLAG_B <= WRB(8)(0);

    -- Write register 7A:
    SYNC_SDLC_FLAG_A <= WRA(7);

    -- Write register 7B:
    SYNC_SDLC_FLAG_B <= WRB(7);

    -- Write register 6A:
    SYNC_SDLC_ADR_A <= WRA(6);

    -- Write register 6B:
    SYNC_SDLC_ADR_B <= WRB(6);

    -- Write register 5A:
    DTR_A <= WRA(5)(7);
    Tx_BITS_A <= WRA(5)(6 downto 5);
    SEND_BREAK_A <= WRA(5)(4);
    Tx_EN_A <= WRA(5)(3);
    CRC16_SDLCn_A <= WRA(5)(2);
    RTS_A <= WRA(5)(1);
    Tx_CRC_EN_A <= WRA(5)(0);

    -- Write register 5B:
    DTR_B <= WRB(5)(7);
    Tx_BITS_B <= WRB(5)(6 downto 5);
    SEND_BREAK_B <= WRB(5)(4);
    Tx_EN_B <= WRB(5)(3);
    CRC16_SDLCn_B <= WRB(5)(2);
    RTS_B <= WRB(5)(1);
    Tx_CRC_EN_B <= WRB(5)(0);

    -- Write register 4A:
    CLK_MODE_A <= WRA(4)(7 downto 6);
    SYNC_CHAR_A <= WRA(4)(5 downto 4);
    SYNC_MODE_A <= WRA(4)(3 downto 2);
    PAR_EVEN_ODDn_A <= WRA(4)(1);
    PAR_EN_A <= WRA(4)(0);

    -- Write register 4B:
    CLK_MODE_B <= WRB(4)(7 downto 6);
    SYNC_CHAR_B <= WRB(4)(5 downto 4);
    SYNC_MODE_B <= WRB(4)(3 downto 2);
    PAR_EVEN_ODDn_B <= WRB(4)(1);
    PAR_EN_B <= WRB(4)(0);

    -- Write register 3A:
    Rx_BITS_A <= WRA(3)(7 downto 6);
    AUTO_EN_A <= WRA(3)(5);
    ENTER_HUNT_MODE_A <= WRA(3)(4);
    Rx_CRC_EN_A <= WRA(3)(3);
    ADR_SEARCH_MODE_A <= WRA(3)(2);
    SYNC_CHAR_INH_A <= WRA(3)(1);
    Rx_EN_A <= WRA(3)(0);

    -- Write register 3B:
    Rx_BITS_B <= WRB(3)(7 downto 6);
    AUTO_EN_B <= WRB(3)(5);
    ENTER_HUNT_MODE_B <= WRB(3)(4);
    Rx_CRC_EN_B <= WRB(3)(3);
    ADR_SEARCH_MODE_B <= WRB(3)(2);
    SYNC_CHAR_INH_B <= WRB(3)(1);
    Rx_EN_B <= WRB(3)(0);

    -- Write register 2A:
    INT_VECT <= WRA(2) when VIS = '0' else RRB2;

    -- Write register 1A:
    DMA_REQ_MODE_A <= WRA(1)(7 downto 5);
    Rx_INT_MODE_A <= WRA(1)(4 downto 3);
    PAR_S_COND_A <= WRA(1)(2);
    Tx_INT_EN_A <= WRA(1)(1);
    EXT_INT_EN_A <= WRA(1)(0);

    -- Write register 1B:
    DMA_REQ_MODE_B <= WRB(1)(7 downto 5);
    Rx_INT_MODE_B <= WRB(1)(4 downto 3);
    PAR_S_COND_B <= WRB(1)(2);
    Tx_INT_EN_B <= WRB(1)(1);
    EXT_INT_EN_B <= WRB(1)(0);
end architecture BEHAVIOUR;
