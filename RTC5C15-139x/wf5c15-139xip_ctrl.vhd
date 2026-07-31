------------------------------------------------------------------------
----                                                                ----
---- ATARI Real Time Clock (RTC) interface.                         ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Interface to connect a DS1392 or DS1393 SPI timekeeper chip    ----
---- to the Atari IP core. The interface is on the system side      ----
---- compatible with the original used RP5C15 chip.                 ----
----                                                                ----
---- This files is the control state machine between the RTC's      ----
---- SPI interface and and the registers.                           ----
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
---- Copyright © 2007... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- This source file may be used and distributed without           ----
---- restriction provided that this copyright statement is not      ----
---- removed from the file and that any derivative work contains    ----
---- the original copyright notice and the associated               ----
---- diSPI_SCLaimer.                                                ----
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
-- Revision 2K7A  2007/01/05 WF
-- Initial Release.
-- Revision 2K8A  2008/07/14 WF
--   Minor changes.
-- Revision 2K9A  2009/06/20 WF
--   Process BITCNT has now synchronous reset to meet preset requirements.
--   SPI_EN has now synchronous reset to meet preset requirement.
-- Revision 2K10A  2010/06/20 WF
--   Several Fixes to get the things running.
-- Revision 2K11B  20111226 WF
--   Minor changes to improve data integrity.
-- Revision 2K12A  20120620 WF
--   Minor changes to improve data integrity.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF5C15_139xIP_CTRL is
    port(
        CLK             : in std_logic;
        RESETn          : in std_logic;
        SPI_PENDING     : in std_logic_vector(10 downto 0);
        CLR_PENDING     : out std_logic;
        SPI_STORE       : out std_logic;
        SPI_DATASEL     : out std_logic_vector(3 downto 0);
        SPI_DATA_IN     : in std_logic_vector(7 downto 0);
        SPI_DATA_OUT    : out std_logic_vector(7 downto 0);

        DATA_VALID      : in std_logic;

        -- SPI interface:
        SPI_IN          : in std_logic;
        SPI_OUT         : out std_logic;
        SPI_EN          : out std_logic;
        SPI_SCL         : out std_logic;
        SPI_CE          : out std_logic
    );
end WF5C15_139xIP_CTRL;
architecture BEHAVIOR of WF5C15_139xIP_CTRL is
type CTRL_STATES is (TEST_PENDING, SPI_WR, STORE, SPI_RD, UPDT_PND, WAIT_SCLK);
signal CTRL_STATE       : CTRL_STATES;
signal NEXT_CTRL_STATE  : CTRL_STATES;
signal SPI_DATASELECT   : std_logic_vector(3 downto 0);
signal REG_PNT          : integer range 0 to 10;
signal SPI_RDY          : std_logic;
signal SPI_TX           : std_logic_vector(15 downto 0);
signal SPI_RX           : std_logic_vector(7 downto 0);
signal SPI_SCLK         : std_logic;
signal BIT_CNT          : std_logic_vector(4 downto 0);
begin
    ------------------------------- Control Section ----------------------------------  
    REG_POINTER:
    process
    -- The REG_PNT is a pointer which indicates a register to be read or written.
    -- This pointer is incremented after a SPI read or write operation. This mechanism
    -- is used for setting up the correct write address to the SPI interface and the
    -- correct read address for reading out registers to the SPI interface. Additionally
    -- it is used to check the pending register in the register file for necessity of
    -- write data to the SPI. It is important, that the REG_PNT, the process P_PENDING
    -- in the register file and the SPI_DATASELECT correlate to handle the appropriate
    -- registers.
    begin
        wait until CLK = '1' and CLK' event;
        if RESETn = '0' and CTRL_STATE = TEST_PENDING then
            REG_PNT <= 0;
        elsif CTRL_STATE = STORE or CTRL_STATE = UPDT_PND then
            if REG_PNT < 10 then
                REG_PNT <= REG_PNT + 1;
            else
                REG_PNT <= 0;
            end if;
        end if;
    end process REG_POINTER;

    with REG_PNT select
        SPI_DATASELECT <= x"1" when 0, -- Seconds.
                          x"2" when 1, -- Minutes.
                          x"3" when 2, -- Hours.
                          x"4" when 3, -- Day.
                          x"5" when 4, -- Date.
                          x"6" when 5, -- Month.
                          x"7" when 6, -- Year.
                          x"A" when 7, -- Alarm minutes.
                          x"B" when 8, -- Alarm hours.
                          x"C" when 9, -- Alarm day/date.
                          x"D" when 10, -- Control.
                          x"0" when others;

    SPI_DATASEL <= SPI_DATASELECT;
    SPI_STORE <= '1' when CTRL_STATE = STORE and SPI_PENDING(REG_PNT) = '0' else '0'; -- Do not store, if the register has become pending.
    --SPI_STORE <= '1' when CTRL_STATE = STORE and SPI_PENDING = "00000000000" else '0'; -- Do not store, if either register has become pending.
    CLR_PENDING <= '1' when CTRL_STATE = UPDT_PND else '0';

    CTRL_REG: process
    begin
        wait until CLK = '1' and CLK' event;
        CTRL_STATE <= NEXT_CTRL_STATE;
    end process CTRL_REG;

    CTRL_DEC: process(RESETn, CTRL_STATE, SPI_PENDING, DATA_VALID, REG_PNT, SPI_RDY, SPI_SCLK)
    -- The control decoder works together with the SPI decoder in a way,
    -- that one data is read or written from or to the SPI interface.
    -- No multiple byte mode of the SPI is required/supported.
    -- The RESETn logic avoids writing or reading of the RTC during system shutdown.
    -- This means, partly serially read or written RTC registers will never occur.
    begin
        case CTRL_STATE is
            when TEST_PENDING =>
                if RESETn = '0' then
                    NEXT_CTRL_STATE <= TEST_PENDING;
                elsif SPI_PENDING(REG_PNT) = '1' and DATA_VALID = '1' and SPI_SCLK = '0' then
                    NEXT_CTRL_STATE <= SPI_WR;
                elsif SPI_SCLK = '0' then -- Do not read if any register is pending for write access.
                    NEXT_CTRL_STATE <= SPI_RD;
                else
                    NEXT_CTRL_STATE <= TEST_PENDING;
                end if;
            when SPI_WR =>
                if SPI_RDY = '1' and SPI_SCLK = '0' then
                    NEXT_CTRL_STATE <= UPDT_PND;
                else
                    NEXT_CTRL_STATE <= SPI_WR; -- Wait.
                end if;
            when UPDT_PND =>
                NEXT_CTRL_STATE <= WAIT_SCLK;
            when SPI_RD =>
                if SPI_RDY = '1' and SPI_SCLK = '0' then
                    NEXT_CTRL_STATE <= STORE;
                else
                    NEXT_CTRL_STATE <= SPI_RD; -- Wait.
                end if;
            when STORE =>
                NEXT_CTRL_STATE <= WAIT_SCLK;
            when WAIT_SCLK =>
                -- This state is introduced to give the SPI device enough
                -- time to detect a SPI_CE break between the data bytes.
                if SPI_SCLK = '1' then
                    NEXT_CTRL_STATE <= TEST_PENDING;
                else
                    NEXT_CTRL_STATE <= WAIT_SCLK;
                end if;
        end case;
    end process CTRL_DEC;

    ------------------------------- SPI Section ----------------------------------  
    SPI_CLOCK: process
    -- This process generates SPI_SCL with a sixteenth of the clock frequency.
    -- This results in 500kHz for 8MHz CPU clock and 1MHz for 16MHz CPU clock.
    variable CLK_COUNT: std_logic_vector(3 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        CLK_COUNT := CLK_COUNT + '1';
        SPI_SCLK <= CLK_COUNT(3);   -- 1/16 of CLK.
    end process SPI_CLOCK;

    SPI_SCL <= SPI_SCLK when CTRL_STATE = SPI_WR or CTRL_STATE = SPI_RD else '0';
    SPI_CE <= '1' when CTRL_STATE = SPI_WR or CTRL_STATE = SPI_RD else '0';

    BITCNT: process(CLK, BIT_CNT)
    -- This process provides information about the already transmitted or received
    -- SPI bits.
    variable LOCK   : boolean;
    begin
        if CLK = '1' and CLK' event then
            if CTRL_STATE /= SPI_WR and CTRL_STATE /= SPI_RD then
                BIT_CNT <= "00000";
                LOCK := true;
            elsif CTRL_STATE = SPI_WR and SPI_SCLK = '1' and LOCK = false then
                LOCK := true;
                BIT_CNT <= BIT_CNT + '1';
            elsif CTRL_STATE = SPI_RD and SPI_SCLK = '1' and LOCK = false then
                LOCK := true;
                BIT_CNT <= BIT_CNT + '1';
            elsif SPI_SCLK = '0' then
                LOCK := false;
            end if;
        end if;
        --
        -- Break after the 16th rising edge of SPI_SCLK:
        case BIT_CNT is
            when "10000" => SPI_RDY <= '1';
            when others => SPI_RDY <= '0';
        end case;
    end process BITCNT;

    TX_SHIFT: process(CLK, SPI_TX)
    -- This is the transmitting shift register. The data is
    -- shifted out on the negative SPI_SCLK clock edge and will
    -- be sampled on the positive SPI_SCLK clock edge. The
    -- shift register is shifted right. The LOCK variable
    -- is initiated 'true' because the SPI_SCLK enters the
    -- write state with '0' (avoid initial shifting).
    variable LOCK   : boolean;
    begin
        if CLK = '1' and CLK' event then
            if CTRL_STATE = TEST_PENDING and NEXT_CTRL_STATE = SPI_WR then
                SPI_TX <= SPI_DATA_IN & x"8" & SPI_DATASELECT;
                LOCK := true;
            elsif CTRL_STATE = TEST_PENDING and NEXT_CTRL_STATE = SPI_RD then
                SPI_TX <= x"000" & SPI_DATASELECT;
                LOCK := true;
            elsif CTRL_STATE = SPI_WR or CTRL_STATE = SPI_RD then
                if SPI_SCLK = '0' and LOCK = false then
                    LOCK := true;
                    SPI_TX <= '0' & SPI_TX(15 downto 1); -- Shift right, LSB first.
                elsif SPI_SCLK = '1' then
                    LOCK := false;
                end if;
            end if;
        end if;
        --
        SPI_OUT <= SPI_TX(0);
    end process TX_SHIFT;

    SPI_EN <= '1' when CTRL_STATE = SPI_RD and BIT_CNT < "01000" else
              '1' when CTRL_STATE = SPI_WR else '0';

    RX_SHIFT: process
    -- The receiver shift register is only 8 bit wide. This is sufficient
    -- for the data not required is shifted through the register. The last
    -- 8 bits are the interesting data. These are stored in the receiver
    -- shift register until the next read cycle starts. The register is
    -- shifted right due to the LSB first. The received data is sampled
    -- on the rising SPI_SCLK clock edge.
    variable LOCK   : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if CTRL_STATE /= SPI_RD then
            LOCK := false;
        elsif CTRL_STATE = SPI_RD then
            if SPI_SCLK = '1' and LOCK = false then
                LOCK := true;
                SPI_RX <= SPI_IN & SPI_RX(7 downto 1); -- Shift right, LSB first.
            elsif SPI_SCLK = '0' then
                LOCK := false;
            end if;
        end if;
    end process RX_SHIFT;

    SPI_DATA_OUT <= SPI_RX;
end architecture BEHAVIOR;
