------------------------------------------------------------------------
----                                                                ----
---- ATARI Real Time Clock interface for DS1287 and PCF85363.       ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- This core provides a DS1287 to PCF85363 translation with the   ----
---- following address mapping:                                     ----
----    The Registers of the DS1287 are mapped to the address space ----
----      x"00" to x"7F" with the following limitations:            ----
----      DS1287 RAM space 14 (x"0E") to 78 (x"4E") is supported.   ----
----      DS1287 RAM space 79 (x"4F") to 127 (x"7F") is not         ----
----        supported.                                              ----
----    No Register A, C and D support.                             ----
----    There is regsiter B support for the DM and 12/24 flags.     ----
----      Other register B bits are general purpose RAM bits and    ----
----      are not be stored in the PCF 85363. The DM bit is         ----
----      stored in the CLKIV flag of the PCF85363.                 ----
---- This core is written to meet the requirements of the INTEL bus ----
---- timing. This is with the MOT input of the original chip left   ----
---- unconnected or connected to GND.                               ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2015... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision History
-- 
-- Revision 2K15B  20151224 WF
--   Initial Release.
-- Revision 2K25A  20250612 WF
--   Debugging: ten years later :-)
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.Conv_Std_Logic_Vector;
use ieee.numeric_std.all;

entity RTC1287_85363 is
    port(
        CLK                 : in std_logic; -- < 32MHz.
        RESET               : in std_logic;

        -- The bus interface:
        RTC_AD_IN           : in std_logic_vector(7 downto 0);
        RTC_D_OUT           : out std_logic_vector(7 downto 0);
        RTC_D_EN            : out std_logic;
        RTCCS               : in std_logic;
        RTCAS               : in std_logic; -- Address strobe.
        RTCDS               : in std_logic; -- Data strobe.
        RTC_RWn             : in std_logic;

        -- The SPI signals:
        PCF85363_SDA_IN     : in std_logic;
        PCF85363_SDA_OUT    : out std_logic;
        PCF85363_SDA_EN     : out std_logic;
        PCF85363_SCL        : out std_logic;
        PCF85363_SCL_EN     : out std_logic;
        PCF85363_CLK        : in std_logic; -- Currently not in use.
        PCF85363_INTn       : in std_logic; -- Currently not in use.
        PCF85363_TS         : in std_logic -- Currently not in use.
    );
end entity RTC1287_85363;
    
architecture BEHAVIOUR of RTC1287_85363 is
type RTC_RAMTYPE is array(0 to 78) of std_logic_vector(7 downto 0);
signal RTC_RAM              : RTC_RAMTYPE; -- C1287.

type I2C_STATETYPE is (IDLE, START_11, START_12, START_13, START_21, START_22, START_23, WAIT_ACK_1, WAIT_ACK_2, WAIT_ACK_3, 
                       WAIT_ACK_4, SND_NACK, CONTROL_1, CONTROL_2, I2C_ADR, SND_DATA, RCV_DATA, STOP_11, STOP_12, STOP_13);
signal I2C_STATE            : I2C_STATETYPE;
signal NEXT_I2C_STATE       : I2C_STATETYPE;

type RTC_STATES is (IDLE, RTC_RD, RTC_WR);
signal RTC_STATE            : RTC_STATES;
signal NEXT_RTC_STATE       : RTC_STATES;

signal ADR_PNTR_1287        : integer range 0 to 127; -- C1287.
signal ADR_PNTR_RTC         : integer range 0 to 127; -- 85363->C1287.
signal ADR_PNTR_85363       : integer range 0 to 127; -- 85363.

signal PENDING              : std_logic_vector(78 downto 0); -- This is a write pending flag.

signal DATA_85363_OUT       : std_logic_vector(7 downto 0);
signal RTC_RAM_IN           : std_logic_vector(7 downto 0);

constant DEVICE_ADR         : std_logic_vector(6 downto 0) := "1010001"; -- This is the PCF85363 I2C address.
signal I2C_STRB             : std_logic;
signal BYTE_RDY             : std_logic;
signal DATA_RDY             : std_logic;
signal SCL_OUT              : std_logic;
signal SDA_IN               : std_logic;
signal SDA_OUT              : std_logic;

signal RD_BYTE              : std_logic;
signal WR_BYTE              : std_logic;

signal BCD_MODE             : std_logic; -- DS1287 DM flag.
begin
    TIMEBASE: process(CLK) -- Adjusted for 16MHz.
    -- This logic provides an adequate clock for the I2C device
    -- of about 300kHz. Adjust the SCL clock in this process. 
    -- Example: Input frequency is 20MHz, the output is 300kHz. 
    -- The divider is 20.000.000 / 300.000 = 66. Choose TMP
    -- to >= 7 bit. Adjust the TMP rollover to a value of 66.
    variable TMP    : std_logic_vector(7 downto 0);
    begin
        if CLK = '1' and CLK' event then
            if RESET = '1' or TMP = x"00" then
                TMP := x"52";
            else
                TMP := TMP - '1';
            end if;
            --
            case TMP is
                when x"00" => I2C_STRB <= '1';
                when others => I2C_STRB <= '0';
            end case;
            --
            -- The data is aligned to be stable during the rising 
            -- or the falling edge of SCL -> SCL is shifted versus
            -- I2C_STRB.
            if TMP > x"7" and TMP < x"26" then
                SCL_OUT <= '1';
            else
                SCL_OUT <= '0';
            end if;
        end if;
    end process TIMEBASE;
    
    BINARY_2_BCD: process(ADR_PNTR_RTC, BCD_MODE, RTC_AD_IN)
        -- This code is taken from https://piembsystech.com/binary-to-bcd-conversion-in-vhdl-programming-language/
        -- It is modified in a way that we have only two BCD digits (0...99). The conversion is necessary when we
        -- have the binary DS1287 mode and when data is time or date.
        variable BINARY : unsigned(7 downto 0);
        variable BCD    : unsigned(7 downto 0);
        variable i      : integer;
    begin
        BINARY := unsigned(RTC_AD_IN);
        BCD := (others => '0');
        
        -- Double Dabble algorithm
        for i in 0 to 7 loop
            if BCD(7 downto 4) > "0100" then
                BCD(7 downto 4) := BCD(7 downto 4) + "0011";
            end if;
            if BCD(3 downto 0) > "0100" then
                BCD(3 downto 0) := BCD(3 downto 0) + "0011";
            end if;
            
            BCD := BCD(6 downto 0) & BINARY(7); -- Shift left.
            BINARY := BINARY(6 downto 0) & '0';
        end loop;

        if BCD_MODE = '1' and (ADR_PNTR_RTC < 10 or ADR_PNTR_RTC = 50) then
            RTC_RAM_IN <= std_logic_vector(BCD);
        else
            RTC_RAM_IN <= RTC_AD_IN;
        end if;
    end process BINARY_2_BCD;

    P_PENDING: process
    -- These flip flops indicate the need of the respective RAM
    -- bytes to be written back to the PCF85363 RAM.
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            PENDING <= (others => '0');
        elsif RTCCS = '1' and RTCDS = '1' and RTC_RWn = '0' then -- Write.
            PENDING(ADR_PNTR_1287) <= '1';
        elsif RTC_STATE = IDLE and RTC_STATE = RTC_WR and NEXT_RTC_STATE = RTC_WR then
            PENDING(ADR_PNTR_RTC) <= '0';
        end if;
    end process P_PENDING;

    RTC_1287_REGISTERS: process
    -- These are the registers in the C1287 address map.
    -- The RAM is always BCD coded for the time and date registers.
    begin
        wait until CLK = '1' and CLK' event;
        if RTCCS = '1' and RTCAS = '1' and RTC_RWn = '0' then
            ADR_PNTR_1287 <= To_Integer(unsigned(RTC_AD_IN(6 downto 0)));
        elsif RTCCS = '1' and RTCDS = '1' and RTC_RWn = '0' and ADR_PNTR_1287 < 79 then -- Write, RAM space < 79!
            if ADR_PNTR_1287 = 11 then
                BCD_MODE <= RTC_AD_IN(2);
            end if;
            RTC_RAM(ADR_PNTR_1287) <= RTC_RAM_IN;
        elsif RTC_STATE = RTC_RD and DATA_RDY = '1' and PENDING(ADR_PNTR_RTC) = '0' and RTCCS = '0' then -- Do not ovverwrite pending registers.
            case ADR_PNTR_RTC is
                when 0 =>
                    RTC_RAM(ADR_PNTR_RTC) <= '0' & DATA_85363_OUT(6 downto 0);
                when 2 =>
                    RTC_RAM(ADR_PNTR_RTC) <= '0' & DATA_85363_OUT(6 downto 0);
                when 11 => -- DS1287 control register B.
                    RTC_RAM(ADR_PNTR_RTC) <= "00000" & DATA_85363_OUT(7) & DATA_85363_OUT(5) & '0'; -- Write, RAM space < 79!
                when others =>
                    RTC_RAM(ADR_PNTR_RTC) <= DATA_85363_OUT;
            end case;
        end if;
    end process RTC_1287_REGISTERS;

    -- Register decimal 13.7 is the battery control flag of the DS1287. The PCF85363A
    -- does not feature a battery control, so we fake this bit to always good.
    -- We need a BCD to Binary conversion when data  is time or date and we have binary DS1287 mode.
    RTC_D_OUT <= x"80" when ADR_PNTR_1287 = 13 else 
                 RTC_RAM(ADR_PNTR_1287)(7 downto 4) * "1010" + RTC_RAM(ADR_PNTR_1287)(3 downto 0) when BCD_MODE = '1' and (ADR_PNTR_RTC < 10 or ADR_PNTR_RTC = 50) else RTC_RAM(ADR_PNTR_1287);
    RTC_D_EN <= '1' when RTCCS = '1' and RTCDS = '1' and RTC_RWn = '1' else '0';

    RD_BYTE <= '1' when RTC_STATE = RTC_RD else '0';
    WR_BYTE <= '1' when RTC_STATE = RTC_WR else '0';

    -- This is the mapping of the DS1287 registers  to
    -- the PCF85363 registers.
    with ADR_PNTR_85363 select
        ADR_PNTR_RTC <= 0 when 1, -- Seconds.
                        2 when 2, -- Minutes.
                        4 when 3, -- Hours.
                        7 when 4, -- Day of the Month.
                        6 when 5, -- Day of the Week.
                        8 when 6, -- Month.
                        9 when 7, -- Year.
                        1 when 8, -- Seconds Alarm.
                        3 when 9, -- Minutes Alarm.
                        5 when 10, -- Hours Alarm.
                        11 when 37, -- Used for DM and 25_12 settings.
                        50 when 44, -- Century is not supported by PCF85363 and is now RAM.
                        78 when 100, -- RAM space.
                        -- Map the PCF85363 address range 64 to 99 to the DS1287 address range 14 to 49.
                        -- Map the PCF85363 address range 101 to 127 to the DS1287 address range 51 to 77.
                        ADR_PNTR_85363 - 50 when others;

    POINTER_85363: process
    begin
        wait until CLK = '1' and CLK' event;
        if (RTC_STATE = RTC_RD or RTC_STATE = RTC_WR) and NEXT_RTC_STATE = IDLE then
            case ADR_PNTR_85363 is
                when 10 => ADR_PNTR_85363 <= 37;
                when 37 => ADR_PNTR_85363 <= 44;
                when 44 => ADR_PNTR_85363 <= 64;
                when 127 => ADR_PNTR_85363 <= 1;
                when others => ADR_PNTR_85363 <= ADR_PNTR_85363 + 1;
            end case;
        end if;
    end process POINTER_85363;

    STATE_REGISTER: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            RTC_STATE <= IDLE;
        else
            RTC_STATE <= NEXT_RTC_STATE;
        end if;
    end process STATE_REGISTER;

    STATE_DECODER: process(DATA_RDY, RTC_STATE, PENDING, ADR_PNTR_RTC, RTCCS, RTC_RWn, RTCDS)
    begin
        case RTC_STATE is
            when IDLE =>
                if RTCCS = '0' and PENDING(ADR_PNTR_RTC) = '1' then
                    NEXT_RTC_STATE <= RTC_WR;
                elsif RTCCS = '0' then
                    NEXT_RTC_STATE <= RTC_RD;
                else
                    NEXT_RTC_STATE <= IDLE;
                end if;
            when RTC_RD =>
                if DATA_RDY = '1' then
                    NEXT_RTC_STATE <= IDLE;
                else
                    NEXT_RTC_STATE <= RTC_RD;
                end if;
            when RTC_WR =>
                if DATA_RDY = '1' then
                    NEXT_RTC_STATE <= IDLE;
                else
                    NEXT_RTC_STATE <= RTC_WR;
                end if;
        end case;
    end process STATE_DECODER;    

    PCF85363_SDA_EN <= '1' when I2C_STATE = START_11 or I2C_STATE = START_12 or I2C_STATE = START_13 else
                       '1' when I2C_STATE = START_21 or I2C_STATE = START_22 or I2C_STATE = START_23 else
                       '1' when I2C_STATE = CONTROL_1 or I2C_STATE = CONTROL_2 else
                       '1' when I2C_STATE = I2C_ADR else
                       '1' when I2C_STATE = SND_DATA else
                       '1' when I2C_STATE = SND_NACK else
                       '1' when I2C_STATE = STOP_11 or I2C_STATE = STOP_12 or I2C_STATE = STOP_13 else '0';

    PCF85363_SDA_OUT <= '1' when I2C_STATE = START_11 or I2C_STATE = START_21 else
                        '0' when I2C_STATE = START_12 or I2C_STATE = START_22 else
                        '0' when I2C_STATE = START_13 or I2C_STATE = START_23 else
                        '0' when I2C_STATE = STOP_11 or I2C_STATE = STOP_12 else
                        '1' when I2C_STATE = SND_NACK else
                        '1' when I2C_STATE = STOP_13 else SDA_OUT;
    
    PCF85363_SCL_EN <= '1' when I2C_STATE /= IDLE else '0';
    
    PCF85363_SCL <= '1' when I2C_STATE = START_11 or I2C_STATE = START_21 else
                    '1' when I2C_STATE = START_12 or I2C_STATE = START_22 else
                    '0' when I2C_STATE = START_13 or I2C_STATE = START_23 else
                    '0' when I2C_STATE = STOP_11 else
                    '1' when I2C_STATE = STOP_12 or I2C_STATE = STOP_13 else SCL_OUT;

    DATA_RDY <= '1' when RD_BYTE = '1' and I2C_STATE /= IDLE and NEXT_I2C_STATE = IDLE and I2C_STRB = '1' else
                '1' when WR_BYTE = '1' and I2C_STATE /= IDLE and NEXT_I2C_STATE = IDLE and I2C_STRB = '1' else '0';

    I2C_CTRL_REG: process
    -- This is the I2C's state machine register.
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            I2C_STATE <= IDLE;
        elsif I2C_STRB = '1' then
            I2C_STATE <= NEXT_I2C_STATE;
        end if;
    end process I2C_CTRL_REG;
    
    I2C_CTRL_DEC: process(I2C_STATE, RD_BYTE, WR_BYTE, BYTE_RDY, SDA_IN)
    -- This is the I2C's state machine decoder.
    begin
        case I2C_STATE is
            when IDLE =>
                if RD_BYTE = '1' or WR_BYTE = '1' then
                    NEXT_I2C_STATE <= START_11;
                else
                    NEXT_I2C_STATE <= IDLE;
                end if;
            when START_11 =>
                NEXT_I2C_STATE <= START_12;
            when START_12 =>
                NEXT_I2C_STATE <= START_13;
            when START_13 =>
                NEXT_I2C_STATE <= CONTROL_1;
            when CONTROL_1 =>
                if BYTE_RDY = '1' then
                    NEXT_I2C_STATE <= WAIT_ACK_1;
                else
                    NEXT_I2C_STATE <= CONTROL_1;
                end if;
            when WAIT_ACK_1 =>
                if SDA_IN = '0' then
                    NEXT_I2C_STATE <= I2C_ADR;
                else
                    NEXT_I2C_STATE <= START_11; -- Device is Busy!
                end if;
            when I2C_ADR =>
                if BYTE_RDY = '1' then
                    NEXT_I2C_STATE <= WAIT_ACK_2;
                else
                    NEXT_I2C_STATE <= I2C_ADR;
                end if;
            when WAIT_ACK_2 =>
                if SDA_IN = '0' and WR_BYTE = '1' then
                    NEXT_I2C_STATE <= SND_DATA;
                elsif SDA_IN = '0' and RD_BYTE = '1' then
                    NEXT_I2C_STATE <= START_21;
                else
                    NEXT_I2C_STATE <= IDLE; -- Error!
                end if;
            when SND_DATA =>
                if BYTE_RDY = '1' then
                    NEXT_I2C_STATE <= WAIT_ACK_3;
                else
                    NEXT_I2C_STATE <= SND_DATA;
                end if;
            when WAIT_ACK_3 =>
                if SDA_IN = '0' then -- Byte written.
                    NEXT_I2C_STATE <= STOP_11;
                else
                    NEXT_I2C_STATE <= IDLE; -- Error!
                end if;
            when START_21 =>
                NEXT_I2C_STATE <= START_22;
            when START_22 =>
                NEXT_I2C_STATE <= START_23;
            when START_23 =>
                NEXT_I2C_STATE <= CONTROL_2;
            when CONTROL_2 =>
                if BYTE_RDY = '1' then
                    NEXT_I2C_STATE <= WAIT_ACK_4;
                else
                    NEXT_I2C_STATE <= CONTROL_2;
                end if;
            when WAIT_ACK_4 =>
                if SDA_IN = '0' then
                    NEXT_I2C_STATE <= RCV_DATA;
                else
                    NEXT_I2C_STATE <= IDLE; -- Error!
                end if;
            when RCV_DATA =>
                if BYTE_RDY = '1' then -- Finish.
                    NEXT_I2C_STATE <= SND_NACK;
                else
                    NEXT_I2C_STATE <= RCV_DATA;
                end if;
            when SND_NACK =>
                NEXT_I2C_STATE <= STOP_11;
            when STOP_11 =>
                NEXT_I2C_STATE <= STOP_12;
            when STOP_12 =>
                NEXT_I2C_STATE <= STOP_13;
            when STOP_13 =>
                NEXT_I2C_STATE <= IDLE;
        end case;
    end process I2C_CTRL_DEC;

    P_SDA_IN: process(CLK)
    -- This flip flop stores the information of the SDA line
    -- when the SCLK is high.
    variable LOCK    : boolean;
    begin
        if CLK = '1' and CLK' event then
            if RESET = '1' then
                LOCK := false;
                SDA_IN <= '1';
            elsif SCL_OUT = '1' and LOCK = false then
                LOCK := true;
                SDA_IN <= PCF85363_SDA_IN;
            elsif SCL_OUT = '0' then
                LOCK := false;
            end if;
        end if;
    end process P_SDA_IN;

    BITCOUNT: process(CLK)
    -- This process controls the bits transfered from or to the slave.
    variable BIT_CNT    : integer range 0 to 7;
    begin
        if CLK = '1' and CLK' event then
            if RESET = '1' then
                BIT_CNT := 0;
            elsif I2C_STATE /= CONTROL_1 and NEXT_I2C_STATE = CONTROL_1 then
                BIT_CNT := 0;
            elsif I2C_STATE /= CONTROL_2 and NEXT_I2C_STATE = CONTROL_2 then
                BIT_CNT := 0;
            elsif I2C_STATE /= I2C_ADR and NEXT_I2C_STATE = I2C_ADR then
                BIT_CNT := 0;
            elsif I2C_STATE /= SND_DATA and NEXT_I2C_STATE = SND_DATA then
                BIT_CNT := 0;
            elsif I2C_STATE /= RCV_DATA and NEXT_I2C_STATE = RCV_DATA then
                BIT_CNT := 0;
            elsif I2C_STRB = '1' and BIT_CNT < 7 then
                BIT_CNT := BIT_CNT + 1;
            end if;
            --
            case BIT_CNT is
                when 7 => BYTE_RDY <= '1';
                when others => BYTE_RDY <= '0';
            end case;
        end if;
    end process BITCOUNT;

    SHIFTREG: process(CLK)
    variable SHIFT_REG          : std_logic_vector(7 downto 0);
    begin
        if CLK = '1' and CLK' event then
            if RESET = '1' then
                SHIFT_REG := x"00";
            elsif I2C_STATE /= CONTROL_1 and NEXT_I2C_STATE = CONTROL_1 then -- Load control data.
                SHIFT_REG := DEVICE_ADR & '0'; -- Write address (and data for write to slave).
            elsif I2C_STATE /= CONTROL_2 and NEXT_I2C_STATE = CONTROL_2 then -- Load control data.
                SHIFT_REG := DEVICE_ADR & '1'; -- Read from slave.
            elsif I2C_STATE /= I2C_ADR and NEXT_I2C_STATE = I2C_ADR then -- Load address to be sent.
                SHIFT_REG := Conv_Std_Logic_Vector(ADR_PNTR_85363, 8);
            elsif I2C_STATE /= SND_DATA and NEXT_I2C_STATE = SND_DATA then -- Load data to be sent.
                case ADR_PNTR_85363 is
                    when 37 => -- Control register B of the DS1287.
                        SHIFT_REG := RTC_RAM(ADR_PNTR_RTC)(2) & '0' & RTC_RAM(ADR_PNTR_RTC)(1) & "00000";
                    when others =>
                        SHIFT_REG := RTC_RAM(ADR_PNTR_RTC);
                end case;
            elsif I2C_STATE = CONTROL_1 and I2C_STRB = '1' then -- Shift out.
                SHIFT_REG := SHIFT_REG(6 downto 0) & '0';
            elsif I2C_STATE = CONTROL_2 and I2C_STRB = '1' then -- Shift out.
                SHIFT_REG := SHIFT_REG(6 downto 0) & '0';
            elsif I2C_STATE = I2C_ADR and I2C_STRB = '1' then -- Shift out.
                SHIFT_REG := SHIFT_REG(6 downto 0) & '0';
            elsif I2C_STATE = SND_DATA and I2C_STRB = '1' then -- Shift out.
                SHIFT_REG := SHIFT_REG(6 downto 0) & '0';
            elsif I2C_STATE = RCV_DATA and I2C_STRB = '1' then -- Shift in.
                SHIFT_REG := SHIFT_REG(6 downto 0) & SDA_IN;
            end if;
            --
            if BYTE_RDY = '1' then
                DATA_85363_OUT <= SHIFT_REG;
            end if;
            --
            SDA_OUT <= SHIFT_REG(7);
        end if;
    end process SHIFTREG;
end BEHAVIOUR;
