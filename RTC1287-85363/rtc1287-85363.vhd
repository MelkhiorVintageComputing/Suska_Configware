------------------------------------------------------------------------
----                                                                ----
---- ATARI Real Time Clock interface for DS1287 and PCF85363.       ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- This core provides a DS1287 to PCF85363 translation and also   ----
---- native access to the PCF85363 real time chip. The DS1287 or    ----
---- the PCF85363 access is handled via the address space as        ----
---- follows:                                                       ----
----    The native Registers of the PCF85363 are mapped to the      ----
----      address space x"80" to x"FF". in This case all features   ----
----      of the PCF85363 can be used.                              ----
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
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
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
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.Conv_Std_Logic_Vector;
use ieee.numeric_std.To_Integer;
use ieee.numeric_std.Unsigned;

entity RTC1287_85363 is
    port(
        CLK                 : in std_logic; -- < 32MHz.
        RESET               : in std_logic;

        -- The bus interface:
        RTC_AD_IN           : in std_logic_vector(7 downto 0);
        RTC_D_OUT           : buffer std_logic_vector(7 downto 0);
        RTC_D_EN            : out std_logic;
        RTCCS               : in std_logic;
        RTCAS               : in std_logic; -- Address strobe.
        RTCDS               : in std_logic; -- Data strobe.
        RTC_RWn             : in std_logic;
        RTC_ACK             : out std_logic;

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
type BCD_TABLE is array(0 to 99) of std_logic_vector(7 downto 0);
constant BINARY_TO_BCD      : BCD_TABLE := 
         (x"00", x"01", x"01", x"03", x"04", x"05", x"06", x"07", x"08", x"09",
          x"10", x"11", x"12", x"13", x"14", x"15", x"16", x"17", x"18", x"19",
          x"20", x"21", x"22", x"23", x"24", x"25", x"26", x"27", x"28", x"29",
          x"30", x"31", x"32", x"33", x"34", x"35", x"36", x"37", x"38", x"39",
          x"40", x"41", x"42", x"43", x"44", x"45", x"46", x"47", x"48", x"49",
          x"50", x"51", x"52", x"53", x"54", x"55", x"56", x"57", x"58", x"59",
          x"60", x"61", x"62", x"63", x"64", x"65", x"66", x"67", x"68", x"69",
          x"70", x"71", x"72", x"73", x"74", x"75", x"76", x"77", x"78", x"79",
          x"80", x"81", x"82", x"83", x"84", x"85", x"86", x"87", x"88", x"89",
          x"90", x"91", x"92", x"93", x"94", x"95", x"96", x"97", x"98", x"99");

type RTC_RAMTYPE is array(0 to 78) of std_logic_vector(7 downto 0);
signal RTC_RAM              : RTC_RAMTYPE; -- C1287.

type I2C_STATETYPE is (IDLE, START_11, START_12, START_13, START_21, START_22, START_23, WAIT_ACK_1, WAIT_ACK_2, WAIT_ACK_3, 
                       WAIT_ACK_4, SND_NACK, CONTROL_1, CONTROL_2, I2C_ADR, SND_DATA, RCV_DATA, STOP_11, STOP_12, STOP_13);
signal I2C_STATE            : I2C_STATETYPE;
signal NEXT_I2C_STATE       : I2C_STATETYPE;

type RTC_STATES is (IDLE, RTC_RD, RTC_WR);
signal RTC_STATE            : RTC_STATES;
signal NEXT_RTC_STATE       : RTC_STATES;

signal RTC_ADR_PNTR         : integer range 0 to 127; -- C1287.
signal RTC_85363_PNTR       : integer range 0 to 127; -- 85363.

signal PENDING              : std_logic_vector(78 downto 0);

signal RTC_RAM_85363_IN     : std_logic_vector(7 downto 0);
signal RTC_RAM_AD_IN        : std_logic_vector(7 downto 0);
signal RTC_RAM_Q            : std_logic_vector(7 downto 0);
signal DATA_85363_OUT       : std_logic_vector(7 downto 0);

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
signal PCF_DIRECT           : std_logic;
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
                TMP := x"34";
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
            if TMP > x"7" and TMP < x"24" then
                SCL_OUT <= '1';
            else
                SCL_OUT <= '0';
            end if;
        end if;
    end process TIMEBASE;
    
    RTC_RAM_AD_IN <= BINARY_TO_BCD(RTC_ADR_PNTR) when BCD_MODE = '0' and (RTC_ADR_PNTR < 10 or RTC_ADR_PNTR = 50) else RTC_AD_IN;
    RTC_RAM_85363_IN <= (DATA_85363_OUT(7 downto 4) * "1010") + DATA_85363_OUT(3 downto 0) when BCD_MODE = '0' and (RTC_ADR_PNTR < 10 or RTC_ADR_PNTR = 50) else DATA_85363_OUT;

    P_PENDING: process
    -- Theseflip flops indicate the need of the respected RAM
    -- bytes to be written back to the PCF85363 RAM.
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            PENDING <= (others => '0');
        elsif PCF_DIRECT = '0' and RTCCS = '1' and RTCDS = '1' and RTC_RWn = '0' then -- Write.
            PENDING(RTC_ADR_PNTR) <= '1';
        elsif RTC_STATE = RTC_WR and DATA_RDY = '1' then
            PENDING(RTC_ADR_PNTR) <= '0';
        end if;
    end process P_PENDING;

    RTC_1287_REGISTERS: process
    -- These are the registers in the C1287 address map.
    begin
        wait until CLK = '1' and CLK' event;
        if RTCCS = '0' and RTC_STATE = IDLE then
            -- This is the mapping of the DS1287 registers  to
            -- the PCF85363 registers.
            case RTC_85363_PNTR is
                when 1 => RTC_ADR_PNTR <= 0; -- Seconds.
                when 2 => RTC_ADR_PNTR <= 2; -- Minutes.
                when 3 => RTC_ADR_PNTR <= 4; -- Hours.
                when 4 => RTC_ADR_PNTR <= 7; -- Day of the Month.
                when 5 => RTC_ADR_PNTR <= 6; -- Day of the Week.
                when 6 => RTC_ADR_PNTR <= 8; -- Month.
                when 7 => RTC_ADR_PNTR <= 9; -- Year.
                when 8 => RTC_ADR_PNTR <= 1; -- Seconds Alarm.
                when 9 => RTC_ADR_PNTR <= 3; -- Minutes Alarm.
                when 10 => RTC_ADR_PNTR <= 5; -- Hours Alarm.
                when 37 => RTC_ADR_PNTR <= 11; -- Used for DM and 25_12 settings.
                when 44 => RTC_ADR_PNTR <= 50; -- Century.
                when 100 => RTC_ADR_PNTR <= 78; -- RAM space.
                when others => 
                    -- Map the PCF85363 address range 64 to 99 to the DS1287 address range 14 to 49.
                    -- Map the PCF85363 address range 101 to 127 to the DS1287 address range 51 to 77.
                    RTC_ADR_PNTR <= RTC_85363_PNTR - 50;
            end case;
        elsif RTCCS = '1' and RTCAS = '1' and RTC_STATE = IDLE then
            PCF_DIRECT <= RTC_AD_IN(7);
            RTC_ADR_PNTR <= To_Integer(unsigned(RTC_AD_IN(6 downto 0)));
        elsif PCF_DIRECT = '0' and RTCCS = '1' and RTCDS = '1' and RTC_RWn = '0' and RTC_STATE = IDLE and RTC_ADR_PNTR < 79 then -- Write, RAM space < 79!
            BCD_MODE <= RTC_RAM_AD_IN(2);
            RTC_RAM(RTC_ADR_PNTR) <= RTC_RAM_AD_IN;
        elsif PCF_DIRECT = '0' and RTC_STATE = RTC_RD and DATA_RDY = '1' and PENDING(RTC_ADR_PNTR) = '0' then -- Do not ovverwrite pending registers.
            case RTC_ADR_PNTR is
                when 0 =>
                    RTC_RAM(RTC_ADR_PNTR) <= '0' & RTC_RAM_85363_IN(6 downto 0);
                when 1 =>
                    RTC_RAM(RTC_ADR_PNTR) <= '0' & RTC_RAM_85363_IN(6 downto 0);
                when 11 => -- DS1287 control register B.
                    BCD_MODE <= RTC_RAM_85363_IN(7);
                    RTC_RAM(RTC_ADR_PNTR) <= "00000" & RTC_RAM_85363_IN(7) & RTC_RAM_85363_IN(5) & '0'; -- Write, RAM space < 79!
                when others =>
                    RTC_RAM(RTC_ADR_PNTR) <= RTC_RAM_85363_IN;
            end case;
        end if;
    end process RTC_1287_REGISTERS;

    RTC_RAM_Q <=  RTC_RAM(RTC_ADR_PNTR) when RTC_ADR_PNTR <= 79 else x"00";
    RTC_D_OUT <=  RTC_RAM_Q when PCF_DIRECT = '0' else DATA_85363_OUT;
    RTC_D_EN <= '1' when RTCCS = '1' and RTCDS = '1' and RTC_RWn = '1' else '0';

    RTC_ACK <= '1' when RTCCS = '1' and RTCAS = '1' and RTC_STATE = IDLE else
               '1' when PCF_DIRECT = '0' and RTCCS = '1' and RTCDS = '1' and RTC_STATE = IDLE else
               '1' when PCF_DIRECT = '1' and I2C_STATE /= I2C_ADR and NEXT_I2C_STATE = I2C_ADR else
               '1' when PCF_DIRECT = '1' and I2C_STATE /= SND_DATA and NEXT_I2C_STATE = SND_DATA else '0';

    RD_BYTE <= '1' when RTC_STATE = RTC_RD else '0';
    WR_BYTE <= '1' when RTC_STATE = RTC_WR else '0';

    POINTER_85363: process
    begin
        wait until CLK = '1' and CLK' event;
        if (RTC_STATE = RTC_RD or RTC_STATE = RTC_WR) and NEXT_RTC_STATE = IDLE then
            case RTC_85363_PNTR is
                when 10 => RTC_85363_PNTR <= 37;
                when 37 => RTC_85363_PNTR <= 44;
                when 44 => RTC_85363_PNTR <= 64;
                when 127 => RTC_85363_PNTR <= 1;
                when others => RTC_85363_PNTR <= RTC_85363_PNTR + 1;
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

    STATE_DECODER: process(DATA_RDY, RTC_STATE, PENDING, RTC_ADR_PNTR, RTCCS, PCF_DIRECT, RTC_RWn, RTCDS)
    begin
        case RTC_STATE is
            when IDLE =>
                if PCF_DIRECT = '0' and RTCCS = '0' and PENDING(RTC_ADR_PNTR) = '1' then
                    NEXT_RTC_STATE <= RTC_WR;
                elsif PCF_DIRECT = '0' and RTCCS = '0' then
                    NEXT_RTC_STATE <= RTC_RD;
                elsif PCF_DIRECT = '1' and RTCCS = '1' and RTCDS = '1' and RTC_RWn = '0' then
                    NEXT_RTC_STATE <= RTC_WR;
                elsif PCF_DIRECT = '1' and RTCCS = '1' and RTCDS = '1' then
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
            elsif PCF_DIRECT = '0' and I2C_STATE /= I2C_ADR and NEXT_I2C_STATE = I2C_ADR then -- Load address to be sent.
                SHIFT_REG := Conv_Std_Logic_Vector(RTC_85363_PNTR, 8);
            elsif PCF_DIRECT = '1' and I2C_STATE /= I2C_ADR and NEXT_I2C_STATE = I2C_ADR then -- Load address to be sent.
                SHIFT_REG := Conv_Std_Logic_Vector(RTC_ADR_PNTR, 8);
            elsif PCF_DIRECT = '0' and I2C_STATE /= SND_DATA and NEXT_I2C_STATE = SND_DATA then -- Load data to be sent.
                case RTC_85363_PNTR is
                    when 37 => -- Control register B of the DS1287.
                        SHIFT_REG := RTC_RAM_Q(2) & '0' & RTC_RAM_Q(1) & "00000";
                    when others =>
                        SHIFT_REG := RTC_RAM_Q;
                end case;
            elsif PCF_DIRECT = '1' and I2C_STATE /= SND_DATA and NEXT_I2C_STATE = SND_DATA then -- Load data to be sent.
                SHIFT_REG := RTC_RAM_AD_IN;
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
