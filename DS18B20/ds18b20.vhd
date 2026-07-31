------------------------------------------------------------------------
----                                                                ----
----  DS18B20 One-Wire controller.                                  ----
----                                                                ----
----  Author: Jens Carroll, Wolfgang Foerster                       ----
----          support@inventronk.de                                 ----
----          www.inventronik.de                                    ----
----                                                                ----
----                                                                ----
---- Description:                                                   ----
----  This module provides a controller for ONEWIRE devices. It is  ----
----  written to control a DS18B20 thermometer with unique serial   ----
----  number. The core does not support devices in the parasite     ----
----  power mode. The controller accesses the DS18B20 via several   ----
----  8 bit wide read only and write only registers. The device is  ----
----  operated by sending ROM commands (ROM_CMD) and Function       ----
----  commands (FCT_CMD). If there are data or control bytes requi- ----
----  red it is important to write the respective registers first.  ----
----  Address "100" is written last and executes the one wire       ----
----  transaction automatically unaffected of the other registers.  ----
----  The address map is as follows (word addresses):               ----
----   Transmitter registers (write only):                          ----
----    "100" = ROM_CMD - FCT_CMD                                   ----
----    "011" downto "000" = ROM_ID(63 downto 0) for MATCH_ROM.     ----
----    "001" = "--------" - Configuration.                         ----
----    "000" = TL - TH                                             ----
----   Receiver registers (read only):                              ----
----    "011" downto "000" = ROM_ID(63 downto 0) for READ_ROM.      ----
----    "100" = "00000" - CRC_ERR - RX_REG(0) - BUSY - CRC (Rd SCP) ----
----    "011" = RESERVED (10h) - RESERVED (Read Scratchpad).        ----
----    "010" = RESERVED (FFh) - CONFIGURATION (Read Scratchpad).   ----
----    "001" = TL -TH (Read Scratchpad).                           ----
----    "000" = TEMPH - TEMPL (Read Scratchpad).                    ----
----    "000" = "--------" - "------" - RX_REG(1 downto 0) for the  ----
----     SEARCH_ROM and ALARM_SEARCH commands.                      ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2015... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- straﬂe 48, 70199 Stuttgart, wf@inventronik.de.                 ----
---- All rights reserved. No portion of this sourcecode may be      ----
---- reproduced or transmitted in any form by any means, whether    ----
---- by electronic, mechanical, photocopying, recording or          ----
---- otherwise, without my written permission.                      ----
----                                                                ----
------------------------------------------------------------------------
-- 
-- Revision History:
-- 
-- Revision 2K15B  20151224 WF
--   Initial release.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity DS18B20 is
    generic (USED_FREQ   : integer range 0 to 128 := 32); -- Use a clock frequency in integer range 8MHz to 128MHz.
    port(
        CLK         : in std_logic; -- Use 32MHz.
        RESET       : in std_logic;

        ADR         : in std_logic_vector(2 downto 0);
        CSn         : in std_logic;
        RWn         : in std_logic;
        DATA_IN     : in std_logic_vector(15 downto 0);
        DATA_OUT    : out std_logic_vector(15 downto 0);
        DATA_EN     : out std_logic;
        
        SD_IN       : in std_logic;
        SD_OUT      : out std_logic -- Is an open collector in the toplevel.
        );
end entity DS18B20;

architecture BEHAVIOUR of DS18B20 is
type OW_STATES is (IDLE, MRESET, BUSRELEASE_1, CHECK_CONDITION, WAIT_OW, BUSRELEASE_2, SEND_ROM_CMD, BUSRELEASE_3, RECEIVE_ROM_ID,
                   SEND_ROM_ID, SEARCH_READ, SEARCH_WRITE, BUSRELEASE_4, SEND_FUNCTION_CMD, READ_SCRATCHPAD, WRITE_SCRATCHPAD);
type FCT_CMDs is(NONE, CONVERT, COPY_SCRP, RECALL_E2, READ_SCRP, WRITE_SCRP, READ_PS);
type ROM_CMDs is(NONE, READ_ROM, MATCH_ROM, SKIP_ROM, SEARCH_ROM, ALARM_SEARCH);
signal FCT_CMD              : FCT_CMDs;
signal FCT_CODE             : std_logic_vector(7 downto 0);
signal ROM_CMD              : ROM_CMDs;
signal ROM_CODE             : std_logic_vector(7 downto 0);
signal OW_STATE             : OW_STATES;
signal NEXT_OW_STATE        : OW_STATES;
signal BUSY                 : std_logic;
signal CRC_ERR              : std_logic;
signal DATA_READ            : boolean;
signal DATA_WRITTEN         : boolean;
signal DATA_WRITTEN_64      : boolean;
signal MPULSE               : boolean;
signal RX_INIT              : std_logic;
signal RX_REG               : std_logic_vector(71 downto 0);
signal STATUS_REG           : std_logic_vector(7 downto 0);
signal STRB_1us             : std_logic;
signal TX_CMD_D               : std_logic;
signal TX_REG               : std_logic_vector(63 downto 0);
begin

    SD_OUT <= '0' when OW_STATE = MRESET else TX_CMD_D and RX_INIT;

    TIMEBASE: process
    -- This is the timer which provides strobe pulse with a period
    -- of 1 us.
    variable TIMESTAMP : integer range 1 to USED_FREQ;
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            TIMESTAMP := 1;
        elsif TIMESTAMP = USED_FREQ then
            TIMESTAMP := 1;
            STRB_1us <= '1';
        else
            TIMESTAMP := TIMESTAMP + 1;
            STRB_1us <= '0';
        end if;
    end process TIMEBASE;

    P_MPULSE: process
    -- This logic provides a pulse duration counter
    -- for issuing the master reset pulse of 1.023us.
    variable COUNTER    : integer range 0 to 1023;
    begin
        wait until CLK = '1' and CLK' event;
        if OW_STATE /= MRESET then
            COUNTER := 0; 
        elsif STRB_1us = '1' and COUNTER < 1023 then
            COUNTER := COUNTER + 1;
        end if;
        --
        case COUNTER is
            when 1022 | 1023 => MPULSE <= true;
            when others => MPULSE <= false;
        end case;
    end process P_MPULSE;

    P_REGISTERS: process
    -- These are the bus registers. After a reset pulse the 
    -- Read Rom Command is issued once. Further commands 
    -- are issued when there is written a valid ROM command 
    -- to the register at address 0. The command is written
    -- last. So if there is for example need for a MATCH_ROM,
    -- the respective registers for the ROM ID have to be
    -- written first. Otherwise non predictable behaviour
    -- will occur.
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            ROM_CMD <= READ_ROM;
            FCT_CMD <= NONE;
        elsif CSn = '0' and RWn = '0' and ADR = "100" then
            case DATA_IN(15 downto 8) is
                when x"33" => ROM_CMD <= READ_ROM;
                when x"55" => ROM_CMD <= MATCH_ROM;
                when x"F0" => ROM_CMD <= SEARCH_ROM;
                when x"CC" => ROM_CMD <= SKIP_ROM;
                when x"EC" => ROM_CMD <= ALARM_SEARCH;
                when others => ROM_CMD <= NONE;
            end case;
            --
            case DATA_IN(7 downto 0) is
                when x"44" => FCT_CMD <= CONVERT;
                when x"48" => FCT_CMD <= COPY_SCRP;
                when x"4E" => FCT_CMD <= WRITE_SCRP;
                when x"BE" => FCT_CMD <= READ_SCRP;
                when x"B8" => FCT_CMD <= RECALL_E2;
                when x"B4" => FCT_CMD <= READ_PS;
                when others => FCT_CMD <= NONE;
            end case;
            --
            ROM_CODE <= DATA_IN(15 downto 8);
            FCT_CODE <= DATA_IN(7 downto 0);
        elsif CSn = '0' and RWn = '0' and ADR = "011" then
            TX_REG(63 downto 48) <= DATA_IN;
        elsif CSn = '0' and RWn = '0' and ADR = "010" then
            TX_REG(47 downto 32) <= DATA_IN;
        elsif CSn = '0' and RWn = '0' and ADR = "001" then
            TX_REG(31 downto 16) <= DATA_IN;
        elsif CSn = '0' and RWn = '0' and ADR = "000" then
            TX_REG(15 downto 0) <= DATA_IN;
        elsif OW_STATE /= IDLE and NEXT_OW_STATE = IDLE then
            ROM_CMD <= NONE;
            FCT_CMD <= NONE;
        end if;
    end process P_REGISTERS;

    DATA_OUT <= "00000" & CRC_ERR & RX_REG(0) & BUSY & RX_REG(71 downto 64) when CSn = '0' and RWn = '1' and ADR = "100" else 
                RX_REG(63 downto 48) when CSn = '0' and RWn = '1' and ADR = "011" else
                RX_REG(47 downto 32) when CSn = '0' and RWn = '1' and ADR = "010" else
                RX_REG(31 downto 16) when CSn = '0' and RWn = '1' and ADR = "001" else RX_REG(15 downto 0);

    DATA_EN <= '1' when CSn = '0' and RWn = '1' else '0';

    BUSY <= '1' when OW_STATE /= IDLE else '0';
    
    STATE_REG: process
    begin
        wait until CLK = '1' and CLK' event;
        if STRB_1us = '1' then
            OW_STATE <= NEXT_OW_STATE;
        end if;
    end process STATE_REG;

    STATE_DEC: process(OW_STATE, RESET, MPULSE, SD_IN, DATA_WRITTEN, DATA_READ, ROM_CMD, CSn, DATA_WRITTEN_64, FCT_CMD, RX_REG)
    begin
        case OW_STATE is
            when IDLE => -- Do nothing.
                if ROM_CMD /= NONE and CSn = '1' then -- Start if there is written any ROM command and the bus is released.
                    NEXT_OW_STATE <= MRESET;
                else
                    NEXT_OW_STATE <= IDLE;
                end if;
            when MRESET => -- Issue a master reset pulse.
                if MPULSE = true then
                    NEXT_OW_STATE <= BUSRELEASE_1;
                else
                    NEXT_OW_STATE <= MRESET;
                end if;
            when BUSRELEASE_1 => -- Wait until the bus is free.
                if SD_IN = '1' then
                    NEXT_OW_STATE <= WAIT_OW;
                else
                    NEXT_OW_STATE <= BUSRELEASE_1;
                end if;
            when WAIT_OW => -- Wait for the presence pulse of the onewire device.
                if SD_IN = '0' then
                    NEXT_OW_STATE <= BUSRELEASE_2;
                else
                    NEXT_OW_STATE <= WAIT_OW;
                end if;
            when BUSRELEASE_2 => -- Wait until the bus is free.
                if SD_IN = '1' then
                    NEXT_OW_STATE <= SEND_ROM_CMD;
                else
                    NEXT_OW_STATE <= BUSRELEASE_2;
                end if;
            when SEND_ROM_CMD =>
                if DATA_WRITTEN = true then
                    NEXT_OW_STATE <= BUSRELEASE_3;
                else
                    NEXT_OW_STATE <= SEND_ROM_CMD;
                end if;
            when BUSRELEASE_3 => -- Wait until the bus is free.
                if ROM_CMD = READ_ROM and SD_IN = '1' then
                    NEXT_OW_STATE <= RECEIVE_ROM_ID;
                elsif ROM_CMD = MATCH_ROM and SD_IN = '1' then
                    NEXT_OW_STATE <= SEND_ROM_ID;
                elsif ROM_CMD = SKIP_ROM and SD_IN = '1' then
                    NEXT_OW_STATE <= SEND_FUNCTION_CMD;
                elsif ROM_CMD = ALARM_SEARCH and SD_IN = '1' then
                    NEXT_OW_STATE <= SEARCH_READ;
                elsif ROM_CMD = SEARCH_ROM and SD_IN = '1' then
                    NEXT_OW_STATE <= SEARCH_READ;
                else
                    NEXT_OW_STATE <= BUSRELEASE_3;
                end if;
            when RECEIVE_ROM_ID =>
                if DATA_READ = true then
                    NEXT_OW_STATE <= BUSRELEASE_4;
                else
                    NEXT_OW_STATE <= RECEIVE_ROM_ID;
                end if;
            when SEND_ROM_ID =>
                if DATA_WRITTEN = true then
                    NEXT_OW_STATE <= BUSRELEASE_4;
                else
                    NEXT_OW_STATE <= SEND_ROM_ID;
                end if;
            when SEARCH_READ =>
                if DATA_READ = true then
                    NEXT_OW_STATE <= SEARCH_WRITE;
                else
                    NEXT_OW_STATE <= SEARCH_READ;
                end if;
            when SEARCH_WRITE =>
                if DATA_WRITTEN_64 = true then
                    NEXT_OW_STATE <= IDLE;
                elsif DATA_WRITTEN = true then
                    NEXT_OW_STATE <= SEARCH_READ;
                else
                    NEXT_OW_STATE <= SEARCH_WRITE;
                end if;
            when BUSRELEASE_4 => -- Wait until the bus is free.
                if SD_IN = '1' then
                    NEXT_OW_STATE <= SEND_FUNCTION_CMD;
                else
                    NEXT_OW_STATE <= BUSRELEASE_4;
                end if;
            when SEND_FUNCTION_CMD =>
                if DATA_WRITTEN = false then
                    NEXT_OW_STATE <= SEND_FUNCTION_CMD;
                elsif FCT_CMD = CONVERT then
                    NEXT_OW_STATE <= CHECK_CONDITION;
                elsif FCT_CMD = COPY_SCRP then
                    NEXT_OW_STATE <= CHECK_CONDITION;
                elsif FCT_CMD = READ_PS then
                    NEXT_OW_STATE <= CHECK_CONDITION;
                elsif FCT_CMD = RECALL_E2 then
                    NEXT_OW_STATE <= CHECK_CONDITION;
                elsif FCT_CMD = READ_SCRP and DATA_WRITTEN = true then
                    NEXT_OW_STATE <= READ_SCRATCHPAD;
                else -- FCT_CMD = WRITE_SCRP.
                    NEXT_OW_STATE <= WRITE_SCRATCHPAD;
                end if;
            when CHECK_CONDITION =>
                if FCT_CMD = CONVERT and DATA_READ = true and RX_REG(0) = '1' then
                    NEXT_OW_STATE <= IDLE;
                elsif FCT_CMD = COPY_SCRP and DATA_READ = true and RX_REG(0) = '1' then
                    NEXT_OW_STATE <= IDLE;
                elsif FCT_CMD = RECALL_E2 and DATA_READ = true and RX_REG(0) = '1' then
                    NEXT_OW_STATE <= IDLE;
                elsif FCT_CMD = READ_PS and DATA_READ = true then
                    NEXT_OW_STATE <= IDLE;
                else
                    NEXT_OW_STATE <= CHECK_CONDITION;
                end if;
            when READ_SCRATCHPAD =>
                if DATA_READ = true then
                    NEXT_OW_STATE <= IDLE;
                else
                    NEXT_OW_STATE <= READ_SCRATCHPAD;
                end if;
            when WRITE_SCRATCHPAD =>
                if DATA_WRITTEN = true then
                    NEXT_OW_STATE <= IDLE;
                else
                    NEXT_OW_STATE <= WRITE_SCRATCHPAD;
                end if;
        end case;
    end process STATE_DEC;

    P_TRANSMIT: process
    -- This process sends the respective command patterns
    -- for 'write one' and 'write zero' time slots.
    -- The start pulse of a slot is 1us and the data is
    -- on the bus for 60us. Then the Bus is released for 
    -- 3 us. 
    variable SLOT_TIMING    : integer range 0 to 63;
    variable TX_SHIFT       : std_logic_vector(7 downto 0);
    variable BITCNT         : integer range 0 to 63;
    begin
        wait until CLK = '1' and CLK' event;
        if OW_STATE /= SEND_ROM_CMD and OW_STATE /= SEND_FUNCTION_CMD and OW_STATE /= WRITE_SCRATCHPAD and OW_STATE /= SEARCH_WRITE then
            SLOT_TIMING := 0;
        elsif STRB_1us = '1' then
            if SLOT_TIMING = 63 then
                SLOT_TIMING := 0;
            else
                SLOT_TIMING := SLOT_TIMING + 1;
            end if;
        end if;
        
        if OW_STATE /= SEND_ROM_CMD and NEXT_OW_STATE = SEND_ROM_CMD then
            TX_SHIFT := ROM_CODE;
            BITCNT := 0;
        elsif OW_STATE /= SEND_ROM_ID and NEXT_OW_STATE = SEND_ROM_ID then
            TX_SHIFT := TX_REG(7 downto 0);
            BITCNT := 0;
        elsif OW_STATE /= WRITE_SCRATCHPAD and NEXT_OW_STATE = WRITE_SCRATCHPAD then
            TX_SHIFT := TX_REG(7 downto 0);
            BITCNT := 0;
        elsif OW_STATE /= SEARCH_WRITE and NEXT_OW_STATE = SEARCH_WRITE then
            TX_SHIFT := TX_REG(7 downto 0);
            -- No BITCNT clear here.
        elsif OW_STATE /= SEND_FUNCTION_CMD and NEXT_OW_STATE = SEND_FUNCTION_CMD then
            TX_SHIFT(7 downto 0) := FCT_CODE;
            BITCNT := 0;
        elsif STRB_1us = '1' and SLOT_TIMING = 63 and BITCNT < 63 then
            BITCNT := BITCNT + 1;
            case BITCNT is
                when 7 => TX_SHIFT := TX_REG(15 downto 8);
                when 15 => TX_SHIFT := TX_REG(23 downto 16);
                when 23 => TX_SHIFT := TX_REG(31 downto 24);
                when 31 => TX_SHIFT := TX_REG(39 downto 32);
                when 39 => TX_SHIFT := TX_REG(47 downto 40);
                when 47 => TX_SHIFT := TX_REG(55 downto 48);
                when 55 => TX_SHIFT := TX_REG(63 downto 56);
                when others => TX_SHIFT := '0' & TX_SHIFT(7 downto 1); -- Shift LSB first.
            end case;
        end if;

        if OW_STATE /= SEND_ROM_CMD and OW_STATE /= SEND_FUNCTION_CMD and OW_STATE /= WRITE_SCRATCHPAD then
            TX_CMD_D <= '1';
        elsif SLOT_TIMING < 1 then
            TX_CMD_D <= '0'; -- Start the slot.
        elsif SLOT_TIMING > 60 then
            TX_CMD_D <= '1'; -- Release.
        else
            TX_CMD_D <= TX_SHIFT(0);
        end if;

        -- For the SEARCH_ROM and the SEARCH_ALARM commands we have to
        -- finish the write time slot after each bit but must count the
        -- total number of 64 bits to end up correctly.
        if OW_STATE = BUSRELEASE_3 and NEXT_OW_STATE = SEARCH_READ then
            DATA_WRITTEN_64 <= false;
            BITCNT := 0;
        elsif SLOT_TIMING = 63 and BITCNT = 63 then
            DATA_WRITTEN_64 <= true;
        end if;
        
        if OW_STATE = WRITE_SCRATCHPAD and BITCNT = 24 then
            DATA_WRITTEN <= true;
        elsif OW_STATE = SEND_ROM_CMD and BITCNT = 8 then
            DATA_WRITTEN <= true;
        elsif OW_STATE = SEARCH_WRITE and BITCNT > 0 then
            DATA_WRITTEN <= true; -- Send one bit only.
        elsif BITCNT = 64 then
            DATA_WRITTEN <= true;
        else
            DATA_WRITTEN <= false;
        end if;
    end process P_TRANSMIT;

    P_RECEIVE: process
    -- This process provides the read time slots. The
    -- start pulse of a slot is 1us and the data is sampled
    -- after 12us. Then the Bus is released for 51us. 
    variable SLOT_TIMING    : integer range 0 to 63;
    variable BITCNT         : integer range 0 to 71;
    variable CRC_SHIFT      : std_logic_vector(8 downto 1);
    begin
        wait until CLK = '1' and CLK' event;
        
        if OW_STATE /= READ_SCRATCHPAD and NEXT_OW_STATE = READ_SCRATCHPAD then
            SLOT_TIMING := 0;
        elsif OW_STATE /= RECEIVE_ROM_ID and NEXT_OW_STATE = RECEIVE_ROM_ID then
            SLOT_TIMING := 0;
        elsif OW_STATE /= CHECK_CONDITION and NEXT_OW_STATE = CHECK_CONDITION then
            SLOT_TIMING := 0;
        elsif OW_STATE /= SEARCH_READ and NEXT_OW_STATE = SEARCH_READ then
            SLOT_TIMING := 0;
        elsif STRB_1us = '1' then
            if SLOT_TIMING = 63 then
                SLOT_TIMING := 0;
            else
                SLOT_TIMING := SLOT_TIMING + 1;
            end if;
        end if;
        
        if OW_STATE /= READ_SCRATCHPAD and NEXT_OW_STATE = READ_SCRATCHPAD then
            -- CRC-CCITT (x00):
            CRC_SHIFT := (others => '0');
        elsif OW_STATE /= RECEIVE_ROM_ID and NEXT_OW_STATE = RECEIVE_ROM_ID then
            -- CRC-CCITT (x00):
            CRC_SHIFT := (others => '0');
        elsif OW_STATE = RECEIVE_ROM_ID and STRB_1us = '1' and SLOT_TIMING = 12 then
            RX_REG <= SD_IN & RX_REG(71 downto 1); -- LSB first.
            -- The polynomial is G(x) = x^8 + x^5 + x^4 + 1
            CRC_SHIFT := (CRC_SHIFT(1) xor SD_IN) & CRC_SHIFT(8 downto 6) & (CRC_SHIFT(5) xor CRC_SHIFT(1) xor SD_IN) & 
                         (CRC_SHIFT(4) xor CRC_SHIFT(1) xor SD_IN) & CRC_SHIFT(3 downto 2);
        elsif OW_STATE = CHECK_CONDITION and STRB_1us = '1' and SLOT_TIMING = 12 then
            RX_REG(0) <= SD_IN;
        elsif OW_STATE = SEARCH_READ and STRB_1us = '1' and SLOT_TIMING = 12 then
            RX_REG(1 downto 0) <= SD_IN & RX_REG(1);
        end if;

        if OW_STATE /= READ_SCRATCHPAD and NEXT_OW_STATE = READ_SCRATCHPAD then
            BITCNT := 0;
        elsif OW_STATE /= RECEIVE_ROM_ID and NEXT_OW_STATE = RECEIVE_ROM_ID then
            BITCNT := 0;
        elsif OW_STATE /= CHECK_CONDITION and NEXT_OW_STATE = CHECK_CONDITION then
            BITCNT := 0;
        elsif OW_STATE /= SEARCH_READ and NEXT_OW_STATE = SEARCH_READ then
            BITCNT := 0;
        elsif STRB_1us = '1' and SLOT_TIMING = 63 and BITCNT < 71 then
            BITCNT := BITCNT + 1;
        end if;

        if OW_STATE = READ_SCRATCHPAD and BITCNT = 71 then
            DATA_READ <= true;
        elsif OW_STATE = RECEIVE_ROM_ID and BITCNT = 64 then
            DATA_READ <= true;
        elsif OW_STATE = CHECK_CONDITION and BITCNT >= 1 then
            DATA_READ <= true;
        elsif OW_STATE = SEARCH_READ and BITCNT = 2 then
            DATA_READ <= true;
        else
            DATA_READ <= false;
        end if;

        if OW_STATE = READ_SCRATCHPAD and NEXT_OW_STATE /= READ_SCRATCHPAD and CRC_SHIFT /= x"00" then
            CRC_ERR <= '1';
        elsif OW_STATE = RECEIVE_ROM_ID and NEXT_OW_STATE /= RECEIVE_ROM_ID and CRC_SHIFT /= x"00" then
            CRC_ERR <= '1';
        else
            CRC_ERR <= '0';
        end if;

        if OW_STATE /= RECEIVE_ROM_ID and OW_STATE /= CHECK_CONDITION and OW_STATE /= READ_SCRATCHPAD and OW_STATE /= SEARCH_READ then
            RX_INIT <= '1';
        elsif SLOT_TIMING < 1 then
            RX_INIT <= '0'; -- Start pulse;
        else
            RX_INIT <= '1';
        end if;
    end process P_RECEIVE;
end architecture BEHAVIOUR;
