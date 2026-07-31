----------------------------------------------------------------------------
----                                                                    ----
---- Suska boot loader unit                                             ----
----                                                                    ----
---- This file is part of the SUSKA ATARI clone project.                ----
---- http://www.experiment-s.de                                         ----
----                                                                    ----
---- Description:                                                       ----
---- This boot loader is written for flash memory type M29W800 or       ----
---- similar.                                                           ----
---- The boot loader unit provides the programming of the operating     ----
---- system flash ROM during a boot sequence. The working principle of  ----
---- the boot loader is as follows:                                     ----
---- Enter the boot loader by asserting the RESET_INn and then          ----
---- RESET_COREn button. Then release first the RESET_COREn button then ----
---- the RESET_INn button. The BOOT_LED begins blinking for about 5     ----
---- seconds. If the RESET_INn button is asserted again during this     ----
---- time, the boot loader routine is active. If not, the boot loader   ----
---- routine finishes without any action and the system is ready to     ----
---- boot normally.                                                     ----
---- Once entered the flash routine, the boot loader controls via the   ----
---- handshake signal BOOT_REQ the interaction with the microcontroller ----
---- (MCU). With the first BOOT_REQ the 16 bit base address is          ----
---- requested from the MCU. This address is sent via the serial        ----
---- peripheral interface (SPI). It is controlled by the MCU. During    ----
---- the shift operation via the SPI interface, the most significant    ----
---- bit is first shifted out and in. Be aware, that the data in the    ----
---- shift register is sampled on the negative clock edge and the       ----
---- SPI_CLK should be '0' when inactive.                               ----
--   The SPI transfer must be acknowledged by the SPI host (the MCU)    ----
---- asserting the BOOT_ACK signal. If not so, the boot loader hangs    ----
---- and ends up only by a new system reset. The start address is 16    ----
---- bit wide and mactches the upper bits of the flash memory for       ----
---- example (A23 ... A8). After the start address is acknowledged,     ----
---- the boot loader requests the command byte. This is transfered in   ----
---- the same way as the base address and is acknowledged with BOOT_ACK ----
---- currently the following commands are valid, invalid commands       ----
---- inactivate the boot loader:                                        ----
---- x"10" : Erase only.                                                ----
---- x"17" : Read only.                                                 ----
---- x"20" : Program, read.                                             ----
---- x"23" : Erase, program, read.                                      ----
---- x"99" : Get version.                                               ----
---- Depending on the command the boot loader optionally erases the     ----
---- flash device writes and or reads it or send a verion number to the ----
---- MCU.                                                               ----
---- The read or write section is controlled by request acknowledge and ----
---- ends up in a time out of about 1 second means if a request is not  ----
---- acknowledged after the time out, the current state is finished.    ----
---- After the read state finishes, the system is in normal operation.  ----
---- During the write section the boot loader requests data from the    ----
---- SPI interface via BOOT_REQ. If the data is received and BOOT_ACK   ----
---- is asserted the data is written to the flash chip and next data is ----
---- requested. The address of the flash is incremented automatically.  ----
---- It starts at zero and ends up at the maximum address for the chip  ----
---- which is given by the number of the address lines. The data        ----
---- written is always 16 bit wide which results in shifting in 16 bits ----
---- for each data via the SPI interface. If the maximum address is     ----
---- acknowledged, the address counter rolls over and starts again with ----
---- address zero. Be aware, that writing a flash twice with different  ----
---- data normally results in corrupted data. The read process and read ----
---- version works similar with reading out 16 bits after the request   ----
---- is asserted.                                                       ----
---- Remark: for compatibility reasons with older boot loader versions  ----
---- there is a need for a dummy base address also in case of the       ----
---- SEND_VERSION command. This address does not affect anything.       ----
----                                                                    ----
---- Since core verion 2K20A the boot loader features seamlessly inte-  ----
---- grated slave support. The SPI slaves channels are selected via the ----
---- SPI_SSn signal as follows, coded in the SPI_STATE IDLE:            ----
----   SPI_SSn = "000": AVR sends OSD Command (Mist) or SDCard (CPM)    ----
----   SPI_SSn = "001": Currently unused;                               ----
----   SPI_SSn = "010": Currently unused;                               ----
----   SPI_SSn = "011": AVR requests FPGA core version.                 ----
----   SPI_SSn = "100": AVR sends PS/2-keyboard data.                    ----
----   SPI_SSn = "101": AVR sends joystick data.                        ----
----   SPI_SSn = "110": Currently unused;                               ----
----   SPI_SSn = "111": Currently unused;                               ----
---- The respective data from core to AVR is coded in the SHFT process. ----
---- Be aware, that the transfer of the core VERSION can be achieved    ----
---- by execution of command x"98" or by using the slave channel 3.     ----
---- So the bootloader works in bootloading operation by invoking it as ----
---- usual or works in a slave mode by invoking it via SPI_SSn.         ----
---- An example for the is given for the VERSION in the following:      ----
---- elsif SPI_STATE /= SEND_VERSION and NEXT_SPI_STATE = SEND_VERSION then-
----     D_SHIFTREG <= VERSION;                                         ----
----                                                                    ----
---- Author(s):                                                         ----
----  - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de        ----
----  - Udo Matthe, umatthe@web.de                                      ----
----                                                                    ----
----------------------------------------------------------------------------
----                                                                    ----
---- Copyright © 2007... Wolfgang Foerster - Inventronik GmbH.          ----
----                                                                    ----
---- This source file may be used and distributed without               ----
---- restriction provided that this copyright statement is not          ----
---- removed from the file and that any derivative work contains        ----
---- the original copyright notice and the associated disclaimer.       ----
----                                                                    ----
---- This source file is free software; you can redistribute it         ----
---- and/or modify it under the terms of the GNU Lesser General         ----
---- Public License as published by the Free Software Foundation;       ----
---- either version 2.1 of the License, or (at your option) any         ----
---- later version.                                                     ----
----                                                                    ----
---- This source is distributed in the hope that it will be             ----
---- useful, but WITHOUT ANY WARRANTY; without even the implied         ----
---- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR            ----
---- PURPOSE. See the GNU Lesser General Public License for more        ----
---- details.                                                           ----
----                                                                    ----
---- You should have received a copy of the GNU Lesser General          ----
---- Public License along with this source; if not, download it         ----
---- from http://www.gnu.org/licenses/lgpl.html                         ----
----                                                                    ----
----------------------------------------------------------------------------
--
-- Revision History
--
-- Revision 2K7A  2007/01/22 WF
--   Initial Release.
-- Revision 2K7B  2007/12/21 WF
--   Fixed a bug in the boot state machine.
--   Changes to meet 16bit SPI / 8bit MCU interface.
--   Changes to get the controller working with the
--   M29W800 flash.
-- Revision 2K8A  2007/12/31 WF
--   Introduced generic test mode.
--   Adaptions to meet the microcontroller bus timing.
-- Revision 2K9A  2009/06/20 WF
--   SHIFTREG has now synchronous reset to meeet preset behaviour.
--   Modified FLASH_RESETn.
--   Added flash erase only and flash write only modes.
--   Set STARTUP to 250ms.
-- Revision 2K15B  20151224 WF
--   VERSION can be read by the microcontroller.
--   Replaced the data type bit by std_logic.
-- Revision 2K19B  20191224 WF
--   Extended ACK_TIMEOUT to meet the requirements for several flash devices.
-- Revision 2K19B  20200620 WF
--   Removed the legacy TESTPATTERNS.
--   Removed command 99 and merged GET_VERSION_HI and GET_VERSION_LO to GET_VERSION.
--   Merged SPI code from Udo Matthe into the WF_FLASHBOOT resulting in FLASHBOOT_UMASPI.
-- Revision 2K20A  20200620 UMA, WF
--   SPI slave enhancements done by Udo results in the following changes:
--   Implemented new feature SEND_CORETYPE.
--   Implemented new feature GET_JOYSTICK.
--   Implemented new feature GET_KEY.
--   Change of SEND_ANYDYTA: is now SEND_VERSION.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity FLASHBOOT_UMASPI is
    port(
        CLK             : in std_logic; -- Use 16MHz.
        PLL_LOCK        : in std_logic;
        RESET_COREn     : in std_logic;
        RESET_INn       : in std_logic;
        RESET_OUTn      : out std_logic;

        -- Versioning:
        CORETYPE        : in std_logic_vector(15 downto 0);
        VERSION         : in std_logic_vector(31 downto 0);

        -- Bus control:
        ROM_CEn         : in std_logic;

        -- Data and address bus:
        ADR_OUT         : out std_logic_vector(23 downto 0);
        ADR_EN          : out std_logic;
        DATA_IN         : in std_logic_vector(15 downto 0);
        DATA_OUT        : out std_logic_vector(15 downto 0);
        DATA_EN         : out std_logic;

        -- Flash interface:
        FLASH_RDY       : in std_logic;

        FLASH_RESETn    : out std_logic;
        FLASH_WEn       : out std_logic;
        FLASH_OEn       : out std_logic;
        FLASH_CEn       : out std_logic;

        -- Microcontroller interface:
        SPI_CLK         : in std_logic;
        SPI_SSn         : in std_logic_vector(2 downto 0); -- Slave select.
        SPI_DIN         : in std_logic;
        SPI_DOUT        : out std_logic;

        BOOT_ACK        : in std_logic;
        BOOT_REQ        : out std_logic;

         -- Joystick PS2-Keyboard Data:
        JOY             : out std_logic_vector(7 downto 0);
        KEY             : out std_logic_vector(15 downto 0);

        -- RAM Interface:
        RAMADDR			: out std_logic_vector(31 downto 0);
        RAMDATA			: out std_logic_vector(15 downto 0);
        RAMWE           : out std_logic;

        -- Status:
        BOOT_LED        : out std_logic
    );
end entity FLASHBOOT_UMASPI;

architecture BEHAVIOR of FLASHBOOT_UMASPI is
type FLASH_CMD_A is array (1 to 3, 0 to 5) of std_logic_vector(11 downto 0);
type FLASH_CMD_D is array (1 to 3, 0 to 5) of std_logic_vector(7 downto 0);
constant FLASH_CMDS_A : FLASH_CMD_A :=
    ((x"555", x"2AA", x"555", x"555", x"2AA", x"555"), -- Erase entire chip.
     (x"555", x"2AA", x"555", x"000", x"000", x"000"), --  Program.
     (x"555", x"2AA", x"555", x"000", x"000", x"000") -- Chip reset.
     -- (x"555", x"2AA", x"555", x"555", x"2AA", BA) -- Block erase (BA = block address);
    );
constant FLASH_CMDS_D : FLASH_CMD_D :=
    ((x"AA", x"55", x"80", x"AA", x"55", x"10"), -- Erase entire chip.
     (x"AA", x"55", x"A0", x"00", x"00", x"00"), -- Program.
     (x"AA", x"55", x"F0", x"00", x"00", x"00") -- Chip reset.
     -- (x"AA", x"55", x"80", x"AA", x"55", x"30") -- Block erase.
    );
type SPI_STATES is (WAIT_PLL_LOCK, ATTENTION, WAIT_KEYRELEASE, ACTIVATE, IDLE, WAITVERSION, SEND_CORETYPE,
                    SEND_VERSION, GET_JOYSTICK, GET_KEY,GET_RAMADDR, GET_RAMDATA, WE_PULSE,
                    FLASH_ERASE_1, FLASH_ERASE_2, ADR_REQ, CMD_REQ, WAIT_MC_1, FLASH_WR, WAIT_MC_2, FLASH_RD);

type ERASE_STATES is (IDLE, FLASH_INIT, WRITE_CMD, READY);
type WRITE_STATES is(IDLE, FLASH_INIT, WRITE_CMD, WAIT_ACK, WRITE_DATA, WRITE_END);
type READ_STATES is(IDLE, FLASH_INIT, WRITE_CMD, WAIT_ACK, DATA_LOAD);
signal SPI_STATE        : SPI_STATES;
signal NEXT_SPI_STATE   : SPI_STATES;
signal ERASE_STATE      : ERASE_STATES;
signal NEXT_ERASE_STATE : ERASE_STATES;
signal WRITE_STATE      : WRITE_STATES;
signal NEXT_WRITE_STATE : WRITE_STATES;
signal READ_STATE       : READ_STATES;
signal NEXT_READ_STATE  : READ_STATES;
signal ADR_OUT_I        : std_logic_vector(23 downto 0);
signal DATA_OUT_I       : std_logic_vector(15 downto 0);
signal D_SHIFTREG       : std_logic_vector(31 downto 0);
signal ADR_REG          : std_logic_vector(23 downto 0);
signal TIME_5           : boolean;
signal T_DELAY          : boolean;
signal ACK_TIMEOUT      : boolean;
signal CMD_PNTR         : integer range 0 to 7;
signal INIT_RDY         : boolean;
signal SPI_CLK_S        : std_logic;
signal SPI_DIN_S        : std_logic;
signal BOOT_ACK_I       : std_logic;
signal MC_WAITSTATE     : std_logic;
signal SPI_SSn_I        : std_logic_vector(2 downto 0);
signal STARTUP          : boolean;
begin
    P_SYNC: process
    -- This synchronizing filter is important due to the different
    -- clock domains of the system microcontroller and the FPGA.
    variable SPI_CLK_TMP    : integer range 0 to 3;
    variable SPI_DIN_TMP    : integer range 0 to 3;
    variable BOOT_ACK_TMP   : integer range 0 to 3;
    variable SPI_SSn_V      : std_logic_vector(2 downto 0);
    variable LOCK: boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if SPI_CLK = '1' and SPI_CLK_TMP < 3 then
            SPI_CLK_TMP := SPI_CLK_TMP + 1;
        elsif SPI_CLK = '1' then
            SPI_CLK_S <= '1';
        elsif SPI_CLK = '0' and SPI_CLK_TMP > 0 then
            SPI_CLK_TMP := SPI_CLK_TMP - 1;
        elsif SPI_CLK = '0' then
            SPI_CLK_S <= '0';
        end if;
        --
        if SPI_DIN = '1' and SPI_DIN_TMP < 3 then
            SPI_DIN_TMP := SPI_DIN_TMP + 1;
        elsif SPI_DIN = '1' then
            SPI_DIN_S <= '1';
        elsif SPI_DIN = '0' and SPI_DIN_TMP > 0 then
            SPI_DIN_TMP := SPI_DIN_TMP - 1;
        elsif SPI_DIN = '0' then
            SPI_DIN_S <= '0';
        end if;
        --
        if BOOT_ACK = '1' and BOOT_ACK_TMP < 3 then
            BOOT_ACK_TMP := BOOT_ACK_TMP + 1;
            BOOT_ACK_I <= '0';
        elsif BOOT_ACK = '1' and LOCK = false then
            BOOT_ACK_I <= '1';
            LOCK := true;
        elsif BOOT_ACK = '1' then
            BOOT_ACK_I <= '0';
        elsif BOOT_ACK = '0' and BOOT_ACK_TMP > 0 then
            BOOT_ACK_TMP := BOOT_ACK_TMP - 1;
            BOOT_ACK_I <= '0';
        elsif BOOT_ACK = '0' then
            BOOT_ACK_I <= '0';
            LOCK := false;
        end if;
        --
        if SPI_SSn_V = SPI_SSn then
            SPI_SSn_I <= SPI_SSn;
        end if;
        SPI_SSn_V := SPI_SSn;
    end process P_SYNC;

    P_STARTUP: process(RESET_COREn, CLK)
    -- This process provides a timeout for the
    -- detection of the boot sequence initiated
    -- by RESET_INn to prevent the start of the
    -- boot loader after power up sequence.
    variable TMP : std_logic_vector(23 downto 0);
    begin
        if RESET_COREn = '0' then
            STARTUP <= false;
            TMP := (others => '0');
        elsif CLK = '1' and CLK' event then
            if TMP < x"4FFFFF" then
                STARTUP <= false;
                TMP := TMP + '1';
            else
                STARTUP <= true;
            end if;
        end if;
    end process P_STARTUP;

    STATE_REGs: process(RESET_COREn, CLK)
    begin
        if RESET_COREn = '0' then
            SPI_STATE <= WAIT_PLL_LOCK;
            ERASE_STATE <= IDLE;
            WRITE_STATE <= IDLE;
            READ_STATE <= IDLE;
        elsif CLK = '1' and CLK' event then
            SPI_STATE <= NEXT_SPI_STATE;
            ERASE_STATE <= NEXT_ERASE_STATE;
            WRITE_STATE <= NEXT_WRITE_STATE;
            READ_STATE <= NEXT_READ_STATE;
        end if;
    end process STATE_REGs;

    SPI_STATE_DEC: process(SPI_STATE, PLL_LOCK, RESET_INn, TIME_5, ERASE_STATE, BOOT_ACK_I,
                           SPI_SSn_I, D_SHIFTREG, ACK_TIMEOUT, WRITE_STATE, READ_STATE, MC_WAITSTATE, STARTUP)
    begin
        case SPI_STATE is
            when WAIT_PLL_LOCK => -- PLLs must be locked first.
                if PLL_LOCK = '1' and STARTUP = true then
                    NEXT_SPI_STATE <= ATTENTION;
                else
                    NEXT_SPI_STATE <= WAIT_PLL_LOCK;
                end if;
            when ATTENTION =>
                if RESET_INn = '1' then -- No boot mode.
                    NEXT_SPI_STATE <= IDLE;
                else -- enter boot mode.
                    NEXT_SPI_STATE <= WAIT_KEYRELEASE;
                end if;
            when WAIT_KEYRELEASE =>
                if RESET_INn = '1' then
                    NEXT_SPI_STATE <= ACTIVATE;
                else
                    NEXT_SPI_STATE <= WAIT_KEYRELEASE;
                end if;
            when ACTIVATE => -- A second RESET_INn enters the Flash routine.
                if RESET_INn = '0' then
                    NEXT_SPI_STATE <= ADR_REQ;
                elsif TIME_5 = true then
                    NEXT_SPI_STATE <= IDLE;
                else
                    NEXT_SPI_STATE <= ACTIVATE;
                end if;
            when ADR_REQ =>
                if BOOT_ACK_I = '1' then
                    NEXT_SPI_STATE <= WAIT_MC_1;
                else
                    NEXT_SPI_STATE <= ADR_REQ;
                end if;
            when WAIT_MC_1 =>
                if MC_WAITSTATE = '1' then
                    NEXT_SPI_STATE <= CMD_REQ;
                else
                    NEXT_SPI_STATE <= WAIT_MC_1;
                end if;
            when CMD_REQ =>
                if BOOT_ACK_I = '1' and D_SHIFTREG(7 downto 0) = x"10" then -- Erase only.
                    NEXT_SPI_STATE <= FLASH_ERASE_1;
                elsif BOOT_ACK_I = '1' and D_SHIFTREG(7 downto 0) = x"17" then -- Read only.
                    NEXT_SPI_STATE <= WAIT_MC_2;
                elsif BOOT_ACK_I = '1' and D_SHIFTREG(7 downto 0) = x"20" then -- Program, read.
                    NEXT_SPI_STATE <= FLASH_WR;
                elsif BOOT_ACK_I = '1' and D_SHIFTREG(7 downto 0) = x"23" then -- Erase, program, read.
                    NEXT_SPI_STATE <= FLASH_ERASE_2;
                elsif BOOT_ACK_I = '1' and D_SHIFTREG(7 downto 0) = x"98" then -- Get version.
                    NEXT_SPI_STATE <= WAIT_MC_2;
                elsif BOOT_ACK_I = '1' then -- Wrong command.
                    NEXT_SPI_STATE <= IDLE;
                else
                    NEXT_SPI_STATE <= CMD_REQ;
                end if;
            when GET_JOYSTICK =>
                if BOOT_ACK_I = '1' or SPI_SSn_I = "111" then
                    NEXT_SPI_STATE <= IDLE;
                else
                    NEXT_SPI_STATE <= GET_JOYSTICK;
                end if;
            when GET_KEY =>
                if BOOT_ACK_I = '1' or SPI_SSn_I = "111" then
                    NEXT_SPI_STATE <= IDLE;
                else
                    NEXT_SPI_STATE <= GET_KEY;
                end if;
            when GET_RAMADDR =>
                if BOOT_ACK_I = '1' or SPI_SSn_I = "111" then
                    NEXT_SPI_STATE <= IDLE;
                else
                    NEXT_SPI_STATE <= GET_RAMADDR;
                end if;
            when GET_RAMDATA =>
                if BOOT_ACK_I = '1' or SPI_SSn_I = "111" then
                    NEXT_SPI_STATE <= WE_PULSE;
                else
                    NEXT_SPI_STATE <= GET_RAMDATA;
                end if;
            when WE_PULSE =>
                NEXT_SPI_STATE <= IDLE;				
            when SEND_CORETYPE =>
                if BOOT_ACK_I = '1' or SPI_SSn_I = "111" then
                    NEXT_SPI_STATE <= WAITVERSION;
                else
                    NEXT_SPI_STATE <= SEND_CORETYPE;
                end if;
            when WAITVERSION =>
                if SPI_SSn_I = "011" then
                    NEXT_SPI_STATE <= SEND_VERSION;
                else
                    NEXT_SPI_STATE <= WAITVERSION;
                end if;
            when SEND_VERSION =>
                if BOOT_ACK_I = '1' or SPI_SSn_I = "111" then
                    NEXT_SPI_STATE <= IDLE;
                else
                    NEXT_SPI_STATE <= SEND_VERSION;
                end if;
            when FLASH_ERASE_1 =>
                if ERASE_STATE = IDLE then
                    NEXT_SPI_STATE <= IDLE;
                else
                    NEXT_SPI_STATE <= FLASH_ERASE_1;
                end if;
            when FLASH_ERASE_2 =>
                if ERASE_STATE = IDLE then
                    NEXT_SPI_STATE <= FLASH_WR;
                else
                    NEXT_SPI_STATE <= FLASH_ERASE_2;
                end if;
            when FLASH_WR =>
                if WRITE_STATE = IDLE then -- Finished writing, go on.
                    NEXT_SPI_STATE <= WAIT_MC_2;
                else
                    NEXT_SPI_STATE <= FLASH_WR;
                end if;
            when WAIT_MC_2 =>
                if MC_WAITSTATE = '1' and D_SHIFTREG(7 downto 0) = x"98" then -- Get version.
                    NEXT_SPI_STATE <= SEND_VERSION;
                elsif MC_WAITSTATE = '1' then
                    NEXT_SPI_STATE <= FLASH_RD;
                else
                    NEXT_SPI_STATE <= WAIT_MC_2;
                end if;
            when FLASH_RD =>
                if READ_STATE = IDLE then -- Finished reading, go on.
                    NEXT_SPI_STATE <= IDLE;
                else
                    NEXT_SPI_STATE <= FLASH_RD;
                end if;
            when IDLE =>
                if SPI_SSn_I = "011" then
                    NEXT_SPI_STATE <= SEND_CORETYPE;
                elsif SPI_SSn_I = "101" then
                    NEXT_SPI_STATE <= GET_JOYSTICK;
                elsif SPI_SSn_I = "100" then
                    NEXT_SPI_STATE <= GET_KEY;
				elsif SPI_SSn_I = "110" then
                    NEXT_SPI_STATE <= GET_RAMADDR;
				elsif SPI_SSn_I = "010" then
                    NEXT_SPI_STATE <= GET_RAMDATA;
                else
                    NEXT_SPI_STATE <= IDLE; -- Bootmode finished, stay here.
                end if;
        end case;
    end process SPI_STATE_DEC;

    ERASE_DEC: process(ERASE_STATE, SPI_STATE, NEXT_SPI_STATE, INIT_RDY, FLASH_RDY, BOOT_ACK_I, T_DELAY)
    begin
        case ERASE_STATE is
            when IDLE =>
                if SPI_STATE /= FLASH_ERASE_1 and NEXT_SPI_STATE = FLASH_ERASE_1 then
                    NEXT_ERASE_STATE <= FLASH_INIT;
                elsif SPI_STATE /= FLASH_ERASE_2 and NEXT_SPI_STATE = FLASH_ERASE_2 then
                    NEXT_ERASE_STATE <= FLASH_INIT;
                else
                    NEXT_ERASE_STATE <= IDLE;
                end if;
            when FLASH_INIT =>
                -- Be aware, that the chip erase time can last upto 60s!
                if INIT_RDY = true and FLASH_RDY = '1' then
                    NEXT_ERASE_STATE <= READY;
                elsif FLASH_RDY = '1' then
                    NEXT_ERASE_STATE <= WRITE_CMD;
                else
                    NEXT_ERASE_STATE <= FLASH_INIT;
                end if;
            when WRITE_CMD =>
                NEXT_ERASE_STATE <= FLASH_INIT;
            when READY =>
                if T_DELAY = true then
                    NEXT_ERASE_STATE <= IDLE;
                else
                    NEXT_ERASE_STATE <= READY;
                end if;
        end case;
    end process ERASE_DEC;

    WRITE_DEC: process(WRITE_STATE, SPI_STATE, NEXT_SPI_STATE, INIT_RDY, FLASH_RDY, BOOT_ACK_I, ACK_TIMEOUT, T_DELAY)
    begin
        case WRITE_STATE is
            when IDLE =>
                if SPI_STATE /= FLASH_WR and NEXT_SPI_STATE = FLASH_WR then
                    NEXT_WRITE_STATE <= WAIT_ACK;
                else
                    NEXT_WRITE_STATE <= IDLE;
                end if;
            when WAIT_ACK =>
                if ACK_TIMEOUT = true then
                    NEXT_WRITE_STATE <= WRITE_END;
                elsif BOOT_ACK_I = '1' then
                    NEXT_WRITE_STATE <= FLASH_INIT;
                else
                    NEXT_WRITE_STATE <= WAIT_ACK;
                end if;
            when FLASH_INIT => -- Send PROGRAM command.
                if INIT_RDY = true and FLASH_RDY = '1' then
                    NEXT_WRITE_STATE <= WRITE_DATA;
                elsif FLASH_RDY = '1' then
                    NEXT_WRITE_STATE <= WRITE_CMD;
                else
                    NEXT_WRITE_STATE <= FLASH_INIT;
                end if;
            when WRITE_CMD =>
                NEXT_WRITE_STATE <= FLASH_INIT;
            when WRITE_DATA =>
                NEXT_WRITE_STATE <= WAIT_ACK;
            when WRITE_END =>
                if T_DELAY = true then
                    NEXT_WRITE_STATE <= IDLE;
                else
                    NEXT_WRITE_STATE <= WRITE_END;
                end if;
        end case;
    end process WRITE_DEC;

    READ_DEC: process(READ_STATE, SPI_STATE, NEXT_SPI_STATE, ACK_TIMEOUT, BOOT_ACK_I, INIT_RDY, FLASH_RDY)
    begin
        case READ_STATE is
            when IDLE =>
                if SPI_STATE /= FLASH_RD and NEXT_SPI_STATE = FLASH_RD then
                    NEXT_READ_STATE <= FLASH_INIT;
                else
                    NEXT_READ_STATE <= IDLE;
                end if;
            when FLASH_INIT => -- Send READ/RESET command.
                if INIT_RDY = true and FLASH_RDY = '1' then
                    NEXT_READ_STATE <= DATA_LOAD;
                elsif FLASH_RDY = '1' then
                    NEXT_READ_STATE <= WRITE_CMD;
                else
                    NEXT_READ_STATE <= FLASH_INIT;
                end if;
            when WRITE_CMD =>
                NEXT_READ_STATE <= FLASH_INIT;
            when DATA_LOAD =>
                NEXT_READ_STATE <= WAIT_ACK;
            when WAIT_ACK =>
                if ACK_TIMEOUT = true then
                    NEXT_READ_STATE <= IDLE;
                elsif BOOT_ACK_I = '1' then
                    NEXT_READ_STATE <= DATA_LOAD;
                else
                    NEXT_READ_STATE <= WAIT_ACK;
                end if;
        end case;
    end process READ_DEC;

    LED_BLNK: process
    -- During the ACTIVATE state the LED blinks with
    -- a frequency of 1Hz.
    variable TMP : std_logic_vector(23 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        case SPI_STATE is
            when ACTIVATE | ADR_REQ | CMD_REQ | FLASH_ERASE_1 | FLASH_ERASE_2 | FLASH_WR | FLASH_RD =>
                TMP := TMP + '1';
            when others =>
                TMP := (others => '0');
        end case;
        --
        case SPI_STATE is
            when ACTIVATE | ADR_REQ | CMD_REQ =>
                BOOT_LED <= TMP(22);
            when FLASH_ERASE_1 | FLASH_ERASE_2 =>
                BOOT_LED <= TMP(23);
            when FLASH_WR =>
                BOOT_LED <= TMP(21);
            when FLASH_RD =>
                BOOT_LED <= TMP(20);
            when others =>
                BOOT_LED <= '0';
        end case;
    end process LED_BLNK;

    TIMER_5: process
    -- This process provides a delay of 5 seconds.
    variable TMP : std_logic_vector(25 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        TIME_5 <= false;
        if SPI_STATE /= ACTIVATE then
            TMP := (others => '0');
        elsif TMP < "11" & x"FFFFFF" then
            TMP := TMP + '1';
        else
            TIME_5 <= true;
        end if;
    end process TIMER_5;

    P_MC_WAIT: process
    -- This process provides a delay of about 2 microseconds.
    -- During this time, the BOOT_REQ is released to insure
    -- proper communication between boot loader and MC.
    variable TMP : std_logic_vector(4 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        if (SPI_STATE = WAIT_MC_1 or SPI_STATE = WAIT_MC_2) and TMP < "11111" then
            TMP := TMP + '1';
            MC_WAITSTATE <= '0';
        elsif SPI_STATE = WAIT_MC_1 or SPI_STATE = WAIT_MC_2 then
            MC_WAITSTATE <= '1';
        else
            TMP := "00000";
            MC_WAITSTATE <= '0';
        end if;
    end process P_MC_WAIT;

    P_TIMEOUT: process
    -- This process provides a delay of about 1 second
    -- in the WAIT_ACK states, the timeout occurs after
    -- this time. In other states the timeout timer
    -- is disabled
    variable TMP : std_logic_vector(27 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        ACK_TIMEOUT <= false;
        if WRITE_STATE = WAIT_ACK and TMP < x"FFFFFFF" then
            TMP := TMP + '1';
        elsif READ_STATE = WAIT_ACK and TMP < x"FFFFFFF" then
            TMP := TMP + '1';
        elsif WRITE_STATE = WAIT_ACK then
            ACK_TIMEOUT <= true;
        elsif READ_STATE = WAIT_ACK then
            ACK_TIMEOUT <= true;
        else
            TMP := (others => '0');
        end if;
    end process P_TIMEOUT;

    P_DELAY: process
    -- This delay improves the timing of the flash controls after
    -- a single pulse program mode and after the erase procedure.
    -- The delay is 16 clock cycles.
    variable TMP : std_logic_vector(3 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        T_DELAY <= false;
        if ERASE_STATE = READY and TMP < x"F" then
            TMP := TMP + '1';
        elsif ERASE_STATE = READY then
            T_DELAY <= true;
        elsif WRITE_STATE = WRITE_END and TMP < x"F" then
            TMP := TMP + '1';
        elsif WRITE_STATE = WRITE_END then
            T_DELAY <= true;
        else
            TMP := (others => '0');
        end if;
    end process P_DELAY;

    SEQ_CNT: process
    -- This process controls during the respective states the
    -- writing of the correct number of commands to the flash device.
    variable CNT : std_logic_vector(2 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        if SPI_STATE = ACTIVATE or SPI_STATE = ADR_REQ then
            CNT := "000";
        elsif WRITE_STATE = WRITE_DATA or WRITE_STATE = WRITE_END then
            CNT := "000";
        elsif ERASE_STATE = WRITE_CMD or WRITE_STATE = WRITE_CMD or READ_STATE = WRITE_CMD then
            CNT := CNT + '1';
        end if;
        --
        if SPI_STATE = FLASH_ERASE_1 and CNT = "110" then
            INIT_RDY <= true; -- 6 command words for erasing the chip.
        elsif SPI_STATE = FLASH_ERASE_2 and CNT = "110" then
            INIT_RDY <= true; -- 6 command words for erasing the chip.
        elsif SPI_STATE = FLASH_WR and CNT = "011" then
            INIT_RDY <= true; -- 3 command words for writing data.
        elsif SPI_STATE = FLASH_RD and CNT = "011" then
            INIT_RDY <= true; -- 3 command words switching to read.
        else
            INIT_RDY <= false;
        end if;
        --
        CMD_PNTR <= To_Integer(unsigned(CNT));
    end process SEQ_CNT;

    ADR_COUNTER: process(RESET_COREn, CLK)
    variable BASE_ADR_REG : std_logic_vector(23 downto 8);
    begin
        if RESET_COREn = '0' then
            ADR_REG <= x"000000";
        elsif CLK = '1' and CLK' event then
            if SPI_STATE = ADR_REQ and BOOT_ACK_I = '1' then
                BASE_ADR_REG := D_SHIFTREG(15 downto 0); -- Store the start address.
                ADR_REG <= BASE_ADR_REG & x"00"; -- Init.
            elsif SPI_STATE /= FLASH_WR and NEXT_SPI_STATE = FLASH_WR then
                ADR_REG <= BASE_ADR_REG & x"00"; -- Init.
            elsif SPI_STATE /= FLASH_RD and NEXT_SPI_STATE = FLASH_RD then
                ADR_REG <= BASE_ADR_REG & x"00"; -- Init.
            elsif WRITE_STATE = WRITE_DATA then
                ADR_REG <= ADR_REG + '1';
            elsif READ_STATE = DATA_LOAD then
                ADR_REG <= ADR_REG + '1';
            end if;
        end if;
    end process ADR_COUNTER;

    SHFT: process
    -- This is the SPI receiver transmitter shift
    -- register.
    variable LOCK : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if RESET_COREn = '0' then
            D_SHIFTREG <= x"55AA55AA"; -- Initial stamp.
        elsif SPI_STATE /= SEND_CORETYPE and NEXT_SPI_STATE = SEND_CORETYPE and SPI_SSn_I = "011" then -- Slave mode get version.
            D_SHIFTREG(31 downto 16) <= CORETYPE;
        elsif SPI_STATE /= SEND_VERSION and NEXT_SPI_STATE = SEND_VERSION and SPI_SSn_I = "011" then -- Slave mode get version.
            D_SHIFTREG <= VERSION;
        elsif SPI_STATE = WAIT_MC_2  and NEXT_SPI_STATE = SEND_VERSION  and D_SHIFTREG(7 downto 0) = x"98" then -- Get version.
            D_SHIFTREG <= VERSION;
        elsif SPI_STATE = GET_JOYSTICK and (BOOT_ACK_I = '1' or SPI_SSn_I = "111") then
            JOY <= D_SHIFTREG(7 downto 0);
        elsif SPI_STATE = GET_KEY and (BOOT_ACK_I = '1' or SPI_SSn_I = "111") then
            KEY <= D_SHIFTREG(15 downto 0);
        elsif SPI_STATE = GET_RAMADDR and (BOOT_ACK_I = '1' or SPI_SSn_I = "111") then
            RAMADDR <= D_SHIFTREG(31 downto 0);
        elsif SPI_STATE = GET_RAMDATA and (BOOT_ACK_I = '1' or SPI_SSn_I = "111") then
            RAMDATA <= D_SHIFTREG(15 downto 0);
        elsif READ_STATE = DATA_LOAD then
            D_SHIFTREG(31 downto 16) <= DATA_IN; -- Load flash data.
        else -- Boot mode, we shift on the negative clock edge.
            if SPI_CLK_S = '0' and LOCK = false then
                D_SHIFTREG <= D_SHIFTREG(30 downto 0) & SPI_DIN_S;
                LOCK := true;
            elsif SPI_CLK_S = '1' then
                LOCK := false;
            end if;
        end if;
    end process SHFT;

    RAMWE <= '1' when SPI_STATE = WE_PULSE else '0';

    SPI_DOUT <= D_SHIFTREG(31); -- MSB first out.

    ADR_OUT <= ADR_OUT_I;
    ADR_OUT_I <= x"000" & FLASH_CMDS_A(1, CMD_PNTR) when ERASE_STATE = FLASH_INIT else
                 x"000" & FLASH_CMDS_A(1, CMD_PNTR) when ERASE_STATE = WRITE_CMD and INIT_RDY = false else
                 x"000" & FLASH_CMDS_A(2, CMD_PNTR) when WRITE_STATE = FLASH_INIT else
                 x"000" & FLASH_CMDS_A(2, CMD_PNTR) when WRITE_STATE = WRITE_CMD and INIT_RDY = false else
                 x"000" & FLASH_CMDS_A(3, CMD_PNTR) when READ_STATE = FLASH_INIT else
                 x"000" & FLASH_CMDS_A(3, CMD_PNTR) when READ_STATE = WRITE_CMD and INIT_RDY = false else ADR_REG;

    ADR_EN <= '1' when SPI_STATE = FLASH_ERASE_1 or SPI_STATE = FLASH_ERASE_2 or SPI_STATE = FLASH_WR or SPI_STATE = FLASH_RD else '0';

    DATA_EN <= '1' when SPI_STATE = FLASH_ERASE_1 or SPI_STATE = FLASH_ERASE_2 or SPI_STATE = FLASH_WR or READ_STATE = FLASH_INIT or READ_STATE = WRITE_CMD else '0';
    DATA_OUT <= DATA_OUT_I;
    DATA_OUT_I <=   x"00" & FLASH_CMDS_D(1, CMD_PNTR) when ERASE_STATE = FLASH_INIT else
                    x"00" & FLASH_CMDS_D(1, CMD_PNTR) when ERASE_STATE = WRITE_CMD and INIT_RDY = false else
                    x"00" & FLASH_CMDS_D(2, CMD_PNTR) when WRITE_STATE = FLASH_INIT else
                    x"00" & FLASH_CMDS_D(2, CMD_PNTR) when WRITE_STATE = WRITE_CMD and INIT_RDY = false else
                    x"00" & FLASH_CMDS_D(3, CMD_PNTR) when READ_STATE = FLASH_INIT else
                    x"00" & FLASH_CMDS_D(3, CMD_PNTR) when READ_STATE = WRITE_CMD and INIT_RDY = false else D_SHIFTREG(15 downto 0);

    BOOT_REQ <= '1' when SPI_STATE = ADR_REQ else
                '1' when SPI_STATE = CMD_REQ else
                '1' when SPI_STATE = SEND_VERSION and SPI_SSn_I = "111" else -- Boot mode command.
                '1' when WRITE_STATE = WAIT_ACK else
                '1' when READ_STATE = WAIT_ACK else '0';

    RESET_OUTn <= '0' when SPI_STATE = ADR_REQ or SPI_STATE = CMD_REQ or SPI_STATE = FLASH_ERASE_1 or SPI_STATE = FLASH_ERASE_2 else
                  '0' when SPI_STATE = FLASH_WR or SPI_STATE = FLASH_RD else
                  '0' when SPI_STATE = WAIT_MC_1 or SPI_STATE = WAIT_MC_2 else '1'; -- System reset during boot sequence.

    FLASH_RESETn <= '0' when SPI_STATE = ADR_REQ or SPI_STATE = WAIT_MC_1 else '1';

    FLASH_WEn <= '0' when ERASE_STATE = WRITE_CMD else
                 '0' when WRITE_STATE = WRITE_CMD else
                 '0' when WRITE_STATE = WRITE_DATA else
                 '0' when READ_STATE = WRITE_CMD else '1'; -- Do never write in normal operation.

    FLASH_OEn <= ROM_CEn when SPI_STATE = IDLE else -- Only Read enabled in normal operation.
                 ROM_CEn when SPI_STATE = SEND_CORETYPE else
                 ROM_CEn when SPI_STATE = WAITVERSION else
                 ROM_CEn when SPI_STATE = SEND_VERSION else
                 ROM_CEn when SPI_STATE = GET_JOYSTICK else
                 ROM_CEn when SPI_STATE = GET_KEY else
                 ROM_CEn when SPI_STATE = GET_RAMADDR else
                 ROM_CEn when SPI_STATE = GET_RAMDATA else
                 '0' when READ_STATE = WAIT_ACK else
                 '0' when READ_STATE = DATA_LOAD else '1';

    FLASH_CEn <= ROM_CEn when SPI_STATE = IDLE else
                 ROM_CEn when SPI_STATE = SEND_CORETYPE else
                 ROM_CEn when SPI_STATE = WAITVERSION   else
                 ROM_CEn when SPI_STATE = SEND_VERSION else
                 ROM_CEn when SPI_STATE = GET_JOYSTICK else
                 ROM_CEn when SPI_STATE = GET_KEY else
                 ROM_CEn when SPI_STATE = GET_RAMADDR else
                 ROM_CEn when SPI_STATE = GET_RAMDATA else
                 '0' when SPI_STATE = FLASH_ERASE_1 else
                 '0' when SPI_STATE = FLASH_ERASE_2 else
                 '0' when SPI_STATE = FLASH_WR else
                 '0' when SPI_STATE = FLASH_RD else '1';
end architecture BEHAVIOR;
