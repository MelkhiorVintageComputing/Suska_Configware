------------------------------------------------------------------------
----                                                                ----
---- ATARI IP Core peripheral Add-On                                ----
----                                                                ----
---- This file is part of the FPGA-ATARI project.                   ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- This hardware provides limeted SCSI functionality. It works    ----
---- as an add-on to the ACSI bus (ACSI-SCSI bridge).               ----
----                                                                ----
---- This moddeling is inspired by a sketch (unknown author) of a   ----
---- ACSI to SCSI bridge. This sketch can be found in the docu-     ----
---- mentation of this core under 'ACSI-SCSI-Bridge'. It is also    ----
---- inspired by the original Atari ACSI-SCSI controller. The       ----
---- document is entitled "Atari ACSI/DMA Integration Guide".       ----
---- Thanks to Miroslav Nohaj 'Jookie' which did give me the        ----
---- information to find these documents.                           ----
---- The main difference of this core to all other known approa-    ----
---- ches is it's synchronous design. The core works well with      ----
---- for example 32MHz. This frequency is not necessarily syn-      ----
---- chronous to other system clocks. So use a system clock for     ----
---- it or produce the clock for example from a phase locked loop.  ----
---- The bridge features initiator identification and parity.       ----
---- Since version 2K12A the core also is compatible with the ICT   ----
---- or LINK97 protocol. This features true SCSI compatibility      ----
---- sending the opcode x"1F" as a first command byte. After this   ----
---- the initiator must send 6 / 10 or 12 further commands to the   ----
---- target. This results in a byte sequence of 6 bytes for ACSI    ----
---- compatibility or of 7 / 11 or 13 bytes for SCSI compatibili-   ----
---- ty. In the latter case, the first byte x"1F" is abandoned.     ----
---- Be aware, that new command data is required after HDINTn is    ----
---- asserted for ACSI or SCSI mode. In both modes, the A1 input    ----
---- is asserted (low) only for the first byte; in case of SCSI     ----
---- commands during the abandoned byte x"1F".                      ----
---- Note: it is even possible tro send the command x"1F" to a      ----
---- target, when the first two bytes of a command sequence are     ----
---- x"1F".                                                         ----
----                                                                ----
---- The SCSI_IDn is a switch to select the initiator ID of the     ----
---- SCSI controller of this core. It is inverted, so use weak      ----
---- pull up resistors for it and connect the switch to GND. In     ----
---- this case (all switches on) the SCSI_IDn of "000" will         ----
---- indicate the highest initiator id of 7.                        ----
----                                                                ----
---- It is possible to use ACSI and SCSI devices together if the    ----
---- SCSI and ACSI switch settings are correct. For this purpose    ----
---- the SCSI-Command x"1F" is used to toggle between ACSI- or      ----
---- SCSI command compatibility. The initial state after a system   ----
---- reset is ACSI command compatibility (SCSI class 0). Once the   ----
---- command x"1F" is issued, this controller switches to SCSI      ----
---- command compatibility and so on. The adapter usage is          ----
---- identical to the original Atari ACSI-SCSI adapters.            ----
----                                                                ----
----   Recommendings for the hardware target concerning the SCSI    ----
----    interface:                                                  ----
----     Use for the outputs non inverting buffers ('541).          ----
----     Use for the data in/outputs tri state buffers ('245).      ----
----     Select for the input / output buffers a supply of 3.3V.    ----
----     The VCCIO voltage of the selected FPGAs should also be     ----
----     at 3.3V for the related interface lines.                   ----
----                                                                ----
---- To Do:                                                         ----
---- -                                                              ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2005... Wolfgang Foerster - Inventronik GmbH.      ----
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
----                                                                ----
----    SCSI connector pinout:                                      ----
----    Pin-Nr.     Name        Remarks                             ----
----      50        I_On                                            ----
----      48        REQn                                            ----
----      46        D_Cn                                            ----
----      44        SELn                                            ----
----      42        MSGn                                            ----
----      40        RSTn                                            ----
----      38        ACKn                                            ----
----      36        BUSYn                                           ----
----      34        reserved    no connection                       ----
----      32        ATNn        Pullup 220 Ohm to VCC               ----
----      30        reserved    no connection                       ----
----      28        reserved    no connection                       ----
----      26        TERMPWR     Hardwired to VCC                    ----
----      24        reserved    no connection                       ----
----      22        reserved    no connection                       ----
----      20        reserved    no connection                       ----
----      18        DPn         open drain                          ----
----      16        SCSI_D7n    open drain                          ----
----      14        SCSI_D6n    open drain                          ----
----      12        SCSI_D5n    open drain                          ----
----      10        SCSI_D4n    open drain                          ----
----      8         SCSI_D3n    open drain                          ----
----      6         SCSI_D2n    open drain                          ----
----      4         SCSI_D1n    open drain                          ----
----      2         SCSI_D0n    open drain                          ----
----                                                                ----
----      25        reserved    no connection                       ----
----      1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 27 GND         ----
----      29, 31, 33, 35, 37, 39, 41, 43, 46, 47, 49    GND         ----
----                                                                ----
------------------------------------------------------------------------
---- This hardware works with the original ATARI                    ----
---- hard dik driver.                                               ----
------------------------------------------------------------------------
-- 
-- Revision History
-- 
-- Revision 1.0  2005/09/10 WF
--   Initial Release.
-- Revision 1.1  2007/01/05 WF
--   Introduced SCSI parity.
--   Introduced Initiator identification.
--   Minor corrections.
-- Revision 2K8A  2008/07/14 WF
--   Minor changes.
-- Revision 2K9A  2009/06/20 WF
--   SCSI_ACKn has now synchronous reset.
--   HDRQn and HDINTn have now synchronous reset to meet preset requirements.
-- Revision 2K10A  2010/06/20 WF
--   Several changes to meet better compatibility with SCSI-II devices.
-- Revision 2K12A 20120620 WF
--   Implementation of selection timeout.
--   Provided LINK97 compatibility (see ACSI data x"1F").
-- Revision 2K12B 20121224 WF
--   Introduced the SLOW_MODE to achieve boot capability with TOS.
-- Revision 2K13A 20130620 WF
--   Minor changes to improve data integrity (DATA_BUFFER).
--   Improvements concerning compatibility to devices using the message phases.
--   Changed DATA_EN logic for ACSI and SCSI.
-- Revision 2K13A 20130620 WF
--   Changed the selection timeout to work without TIMEOUT.
--   Some additional minor changes.
-- Revision 2K14A 20140620 WF
--   Rearranged the complete selection timeout to improve drive compatibility.
-- Revision 2K15A 20150620 WF
--   Several code optimizations.
--   Fixed a bug in the ACSI_CTRL_ENn logic: enabled also in WAIT_1stBYTE.
--   Implemented a message out system for rejection of all messages except 'COMMAND COMPLETE'.
--   Remark: 1) the SCSI control signals MSGn, IOn, DCn are used delayed or direct to meet the
--              requirements of the clock domain crossing between the target and this adapter.
-- Revision 2K15B 20151224 WF
--   Replaced the data type bit by std_logic.
-- Revision 2K16A 20161224
--   Removed the MESSAGE_OUT phase. There is no message system support from the initiator (ACSI bus).
--   Introduced the HANDSHAKING module for test purposes.
--   The interrupt is suppressed, if the data request for the first command byte occurs
--     simultaneously with the phase change signals. See the null statement in the INTn_CTRL process.
--   Withdrawn the logic responsible for Remark: 1) in Revision 2K15A 20150620.
--   Fixed a bug in the P_SYNC module concerning the PHASE_CHANGE.
-- Revision 2K19B 20191224 WF
--   Switched the P_SYNC process from negative to positive clock edge.
--   Use SCSI_DCn instead of SCSI_DC_In in the state machine decoder COMMAND state.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF_ACSI_SCSI_IF_SOC is
    port (  
        RESETn          : in std_logic; -- ST's reset signal low active.
        CLK             : in std_logic; -- 32MHz recommended.

        -- ACSI section:        
        CR_Wn           : in std_logic;
        CA1             : in std_logic;
        HDCSn           : in std_logic;
        HDACKn          : in std_logic;
        HDINTn          : out std_logic;
        HDRQn           : out std_logic;
        ACSI_D_IN       : in std_logic_vector(7 downto 0);
        ACSI_D_OUT      : out std_logic_vector(7 downto 0);
        ACSI_D_EN       : out std_logic;
        ACSI_CTRL_ENn   : out std_logic;

        -- SCSI section:
        -- Recommendations for the hardware target:
        -- Use for the outputs non inverting buffers ('34).
        -- Use for the data outputs tri state buffers ('540).
        -- Use for the inputs non inverting buffers ('34).
        -- Select for the output buffers a supply of +5V.
        -- Select for the data output buffers a supply of +5V.
        -- Select for the input buffers a supply of VCCIO of the
        --   selected programmable logic device.
        SCSI_BUSYn      : in std_logic;
        SCSI_MSGn       : in std_logic;
        SCSI_REQn       : in std_logic;
        SCSI_DCn        : in std_logic;
        SCSI_IOn        : in std_logic;
        SCSI_RSTn       : out std_logic;
        SCSI_ACKn       : out std_logic;
        SCSI_SELn       : out std_logic;
        SCSI_ATNn       : out std_logic;
        SCSI_DP_IN      : in std_logic; -- Not used so far.
        SCSI_DP_OUT     : out std_logic;
        SCSI_D_IN       : in std_logic_vector(7 downto 0);
        SCSI_D_OUT      : out std_logic_vector(7 downto 0);
        SCSI_D_EN       : out std_logic;
        SCSI_CTRL_EN    : out std_logic;

        -- Others:
        SCSI_IDn        : in std_logic_vector(2 downto 0); -- This is the initiator's ID switch.
        P24             : out std_logic; -- Debugging.
        P25             : out std_logic -- Debugging.
    );
end WF_ACSI_SCSI_IF_SOC;

architecture BEHAVIOR of WF_ACSI_SCSI_IF_SOC is
type CTRL_STATES is (IDLE, SCSI_BUS_FREE, CHECK_MODE, ACSI_BUS_RELEASE, WAIT_1stBYTE, SELCT, WAIT_TARGET, COMMAND, DATA_IO, STATUS, MESSAGE_IN);
signal CTRL_STATE       : CTRL_STATES;
signal NEXT_CTRL_STATE  : CTRL_STATES;
signal ACSI_DATA        : std_logic_vector(7 downto 0);
signal SCSI_D_OUT_I     : std_logic_vector(7 downto 0);
signal TARGET_No        : std_logic_vector(2 downto 0);
signal TARGET_ID        : std_logic_vector(7 downto 0);
signal INITIATOR_ID     : std_logic_vector(7 downto 0);
signal RES_I            : std_logic;
signal CR_Wn_I          : std_logic;
signal CA1_I            : std_logic;
signal HDCS_In          : std_logic;
signal HDACK_In         : std_logic;
signal SCSI_BUSY_In     : std_logic;
signal SCSI_MSG_In      : std_logic;
signal SCSI_REQ_In      : std_logic;
signal SCSI_DCn_I       : std_logic;
signal SCSI_IOn_I       : std_logic;
signal SLOW_MODE        : std_logic;
begin
    P24 <= '1' when TARGET_No = "001" else '0';    
    P25 <= '1' when CTRL_STATE = IDLE else '0';    

    SLOWMODE: process
    -- This switch is responsible to provide boot capability 
    -- of the TOS 2.06 operating system. Due to a race condition
    -- in the operating system booting from fast harddrives is
    -- not possible. For this reaon, the SD cards are slowed down
    -- after a system reset until the first Inquiry command will
    -- be executed.
    begin
        wait until CLK = '1' and CLK' event;
        if RES_I = '1' then
            SLOW_MODE <= '1';
        elsif CA1 = '0' and HDCS_In = '0' and ACSI_D_IN(4 downto 0) = "10010" then -- Inquiry.
            SLOW_MODE <= '0';
        elsif CTRL_STATE = WAIT_1stBYTE and HDCS_In = '0' and ACSI_D_IN(4 downto 0) = "10010" then -- Inquiry.
            SLOW_MODE <= '0';
        end if;
    end process SLOWMODE;

    P_SYNC: process
    -- This module synchronizes the control signals to the
    -- internal used clock. This is important for the state
    -- machine. This process works on the negative CLK edge.
    variable PHASE_CHANGE     : std_logic;
    variable SCSI_MSG_Vn      : std_logic;
    variable SCSI_DCn_V       : std_logic;
    variable SCSI_IOn_V       : std_logic;
    begin
        wait until CLK = '1' and CLK' event;
        RES_I           <= not RESETn;
        CR_Wn_I         <= CR_Wn;
        CA1_I           <= CA1;
        HDCS_In         <= HDCSn;
        HDACK_In        <= HDACKn;

        PHASE_CHANGE := (SCSI_MSG_Vn xor SCSI_MSGn) or (SCSI_DCn_V xor SCSI_DCn) or (SCSI_IOn_V xor SCSI_IOn);

        SCSI_MSG_Vn := SCSI_MSGn;
        SCSI_DCn_V := SCSI_DCn;
        SCSI_IOn_V := SCSI_IOn;
        
        if PHASE_CHANGE = '0' then
            SCSI_MSG_In <= SCSI_MSGn;
            SCSI_DCn_I <= SCSI_DCn;
            SCSI_IOn_I <= SCSI_IOn;
        end if;

        SCSI_REQ_In <= SCSI_REQn or PHASE_CHANGE;
        SCSI_BUSY_In <= SCSI_BUSYn;
    end process P_SYNC;

    CONTROLLER_REG: process
    -- This is the ACSI-SCSI state machine register.
    begin
        wait until CLK = '1' and CLK' event;
        if RES_I = '1' then
            CTRL_STATE <= IDLE;
        else
            CTRL_STATE <= NEXT_CTRL_STATE;
        end if;
    end process CONTROLLER_REG;

    CONTROLLER_DEC: process (CTRL_STATE, CR_Wn_I, CA1_I, ACSI_DATA, HDCS_In, SCSI_IOn_I, SCSI_MSG_In, SCSI_BUSY_In, SCSI_DCn_I, SCSI_DCn)
    -- This is the ACSI-SCSI state machine decoder.
    begin
        case CTRL_STATE is
            when IDLE =>
                if CR_Wn_I = '0' and CA1_I = '0' and HDCS_In = '0' then
                    NEXT_CTRL_STATE <= SCSI_BUS_FREE; -- Start SCSI access.
                else
                    NEXT_CTRL_STATE <= IDLE;
                end if;
            when SCSI_BUS_FREE =>
                -- The SCSI_BUSY_In must be released to guarantee a free bus.
                if CA1_I = '1' and HDCS_In = '1' and SCSI_BUSY_In = '1' then
                    NEXT_CTRL_STATE <= CHECK_MODE;
                else
                    NEXT_CTRL_STATE <= SCSI_BUS_FREE;
                end if;
            -- We have exactly one initiator (the ACSI port). So we do not need
            -- an arbitration procedure.
            when CHECK_MODE => -- Determine ACSI or SCSI mode.
                if ACSI_DATA = x"1F" then -- This is the SCSI mode.
                    NEXT_CTRL_STATE <= WAIT_1stBYTE;
                else
                    NEXT_CTRL_STATE <= SELCT; -- And this is ACSI (SCSI class 0).
                end if;
            when WAIT_1stBYTE =>
                if CR_Wn_I = '0' and HDCS_In = '0' then -- Wait for the first command byte.
                    NEXT_CTRL_STATE <= ACSI_BUS_RELEASE;
                else
                    NEXT_CTRL_STATE <= WAIT_1stBYTE;
                end if;
            when ACSI_BUS_RELEASE =>
                if CA1_I = '1' and HDCS_In = '1' then
                    NEXT_CTRL_STATE <= SELCT;
                else
                    NEXT_CTRL_STATE <= ACSI_BUS_RELEASE;
                end if;
            when SELCT =>
                if HDCS_In = '0' and CR_Wn_I = '0' and CA1_I = '0' then -- Next target.
                    NEXT_CTRL_STATE <= SCSI_BUS_FREE; -- Timeout, no target is here.
                elsif HDCS_In = '0' then
                    NEXT_CTRL_STATE <= IDLE; -- Timeout, no target is here.
                elsif SCSI_BUSY_In = '0' then
                    NEXT_CTRL_STATE <= WAIT_TARGET;
                else
                    NEXT_CTRL_STATE <= SELCT;
                end if;
            when WAIT_TARGET =>
                if SCSI_MSG_In = '0' and SCSI_IOn_I = '0' then 
                    NEXT_CTRL_STATE <= MESSAGE_IN;
                elsif SCSI_DCn_I = '0' then
                    NEXT_CTRL_STATE <= COMMAND;
                else
                    NEXT_CTRL_STATE <= WAIT_TARGET;
                end if;
            when COMMAND =>
                if SCSI_BUSY_In = '1' then
                    NEXT_CTRL_STATE <= IDLE;
                elsif SCSI_MSG_In = '0' and SCSI_IOn_I = '0' then
                    NEXT_CTRL_STATE <= MESSAGE_IN;
                -- elsif SCSI_DCn_I = '0' and SCSI_IOn_I = '0' then
                elsif SCSI_DCn = '0' and SCSI_IOn_I = '0' then -- Do not use SCSI_DCn_I here, see 1).
                    NEXT_CTRL_STATE <= STATUS;
                elsif SCSI_DCn_I = '1' then
                    NEXT_CTRL_STATE <= DATA_IO;
                else
                    NEXT_CTRL_STATE <= COMMAND;
                end if;
            when DATA_IO =>
                if SCSI_BUSY_In = '1' then
                    NEXT_CTRL_STATE <= IDLE;
                elsif SCSI_MSG_In = '0' and SCSI_IOn_I = '0' then
                    NEXT_CTRL_STATE <= MESSAGE_IN;
                elsif SCSI_DCn_I = '0' and SCSI_IOn_I = '0' then
                    NEXT_CTRL_STATE <= STATUS;
                else
                    NEXT_CTRL_STATE <= DATA_IO;
                end if;
            when STATUS =>
                if SCSI_BUSY_In = '1' then
                    NEXT_CTRL_STATE <= IDLE;
                elsif SCSI_MSG_In = '0' and SCSI_IOn_I = '0' then
                    NEXT_CTRL_STATE <= MESSAGE_IN;
                else
                    NEXT_CTRL_STATE <= STATUS;
                end if;
            when MESSAGE_IN =>
                if SCSI_BUSY_In = '1' then
                    NEXT_CTRL_STATE <= IDLE;
                elsif SCSI_MSG_In = '1' and SCSI_DCn_I = '0' and SCSI_IOn_I = '1' then
                    NEXT_CTRL_STATE <= COMMAND;
                elsif SCSI_MSG_In = '1' and SCSI_DCn_I = '0' and SCSI_IOn_I = '0' then
                    NEXT_CTRL_STATE <= STATUS;
                elsif SCSI_MSG_In = '1' and SCSI_DCn_I = '1' then
                    NEXT_CTRL_STATE <= DATA_IO;
                else
                    NEXT_CTRL_STATE <= MESSAGE_IN;
                end if;
        end case;
    end process CONTROLLER_DEC;

    INTn_CTRL: process
    -- The LOCK and FIRST registers affect, that the first SCSI_REQ_In
    -- in the command phase does not release an interrupt. This is 
    -- important because the first command have already loaded in
    -- SCSI BUS_FREE and/or WAIT_1stBYTE. In the command state the
    -- target takes over the control and requests the second and
    -- the following command bytes by releasing an interrupt. 
    variable FIRST  : boolean;
    variable LOCK   : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if CTRL_STATE = IDLE or CTRL_STATE = SCSI_BUS_FREE then
            HDINTn <= '1';
            FIRST := false;
            LOCK := false;
        elsif CTRL_STATE = CHECK_MODE and NEXT_CTRL_STATE = WAIT_1stBYTE then
            HDINTn <= '0'; -- Request the first command byte in ICD mode.
        elsif CTRL_STATE = COMMAND and NEXT_CTRL_STATE /= COMMAND then
            -- Do not release the interrupt for the first data 
            -- request which occurs in the end of the COMMAND phase.
            null;
        elsif CTRL_STATE = COMMAND and SCSI_REQ_In = '0' and FIRST = false then
            FIRST := true;
            LOCK := true;
        elsif CTRL_STATE = COMMAND and SCSI_REQ_In = '0' and FIRST = true and LOCK = false then
            HDINTn <= '0';
            LOCK := true;
        elsif CTRL_STATE = COMMAND and SCSI_REQ_In = '1' then
            LOCK := false;
        elsif CTRL_STATE = STATUS and SCSI_REQ_In = '1' then
            LOCK := false;
        elsif CTRL_STATE = STATUS and SCSI_REQ_In = '0' and LOCK = false then
            HDINTn <= '0';
            LOCK := true;
        elsif HDCS_In = '0' then
            HDINTn <= '1';
        end if;
    end process INTn_CTRL;      

    -- HANDSHAKING: process
    -- -- This logic controls the two handshaking signals HDRQn and SCSI_ACKn.
    -- -- This HANDSHAKING logic does not work as proper as the HDRQn_CTRL and the SCSI_ACKn_REG. 
    -- -- It is intended for test purposes.
    -- variable DATA_VALID     : boolean;
    -- variable TMP            : std_logic_vector(7 downto 0);
    -- begin
    --     wait until CLK = '1' and CLK' event;
    --     --
    --     HDRQn <= '1';
    --     SCSI_ACKn <= '1';
    --     --
    --     case CTRL_STATE is
    --         when SCSI_BUS_FREE =>
    --             DATA_VALID := true; -- HDCS_In = '0': this is the first command byte.
    --         when COMMAND | STATUS =>
    --             if HDCS_In = '0' then
    --                 DATA_VALID := true;
    --             elsif SCSI_DCn_I = '0' and SCSI_REQ_In = '0' and HDCS_In = '1' and DATA_VALID = true then
    --                 SCSI_ACKn <= '0';
    --                 DATA_VALID := false;
    --             end if;
    --         when DATA_IO =>
    --             if SCSI_DCn_I = '1' and SLOW_MODE = '1' and SCSI_REQ_In = '0' and TMP < x"3F" then -- x"1F" is already too fast.
    --                 TMP := TMP + '1';
    --             elsif SCSI_DCn_I = '1' and SLOW_MODE = '1' then
    --                 if SCSI_REQ_In = '1' then
    --                     TMP := x"00";
    --                 end if;
    --                 SCSI_ACKn <= HDACK_In;
    --                 HDRQn <= SCSI_REQ_In;
    --             elsif SCSI_DCn_I = '1' then
    --                 SCSI_ACKn <= HDACK_In;
    --                 HDRQn <= SCSI_REQ_In;
    --             end if;
    --         when MESSAGE_IN =>
    --             SCSI_ACKn <= SCSI_REQ_In; -- Simulate the acknowledge.
    --         when others => null;
    --     end case;
    -- end process HANDSHAKING;

    HDRQn_CTRL: process
    -- This logic provides the hard drive request signal
    -- on the ACSI bus during tha data I/O phase.
    variable TMP    : std_logic_vector(7 downto 0);
    variable LOCK   : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if CTRL_STATE /= DATA_IO then
            HDRQn <= '1';
            TMP := x"00";
            LOCK := false;
        elsif CTRL_STATE = DATA_IO and HDACK_In = '0' then
            HDRQn <= '1';
        elsif CTRL_STATE = DATA_IO and SCSI_REQ_In = '0' and LOCK = false then
            if SLOW_MODE = '1' and TMP < x"3F" then -- x"1F" is already too fast.
                TMP := TMP + '1';
            elsif SLOW_MODE = '1' then
                TMP := x"00";
                HDRQn <= '0';
                LOCK := true;
            else
                HDRQn <= '0';
                LOCK := true;
            end if;
        elsif CTRL_STATE = DATA_IO and SCSI_REQ_In = '1' then
            LOCK := false;
        end if;
    end process HDRQn_CTRL;     

    SCSI_ACKn_REG: process
    -- This module controls the SCSI acknowledge signal.
    variable DATA_VALID     : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        case CTRL_STATE is
            when IDLE =>
                SCSI_ACKn <= '1';
                DATA_VALID := false;
            when SCSI_BUS_FREE =>
                if HDCS_In = '0' then
                    DATA_VALID := true; -- This is the first command byte.
                end if;
            when COMMAND | STATUS =>
                if HDCS_In = '0' then
                    DATA_VALID := true;
                elsif SCSI_REQ_In = '0' and HDCS_In = '1' and DATA_VALID = true then
                    SCSI_ACKn <= '0';
                    DATA_VALID := false;
                elsif SCSI_REQ_In = '1' then
                    SCSI_ACKn <= '1';
                end if;
            when DATA_IO =>
                if HDACK_In = '0' then
                    DATA_VALID := true;
                elsif SCSI_REQ_In = '0' and HDACK_In = '1' and DATA_VALID = true then
                    SCSI_ACKn <= '0';
                    DATA_VALID := false;
                elsif SCSI_REQ_In = '1' then
                    SCSI_ACKn <= '1';
                end if;
            when MESSAGE_IN =>
                SCSI_ACKn <= SCSI_REQ_In; -- Simulate the acknowledge.
            when others => null;
        end case;
    end process SCSI_ACKn_REG;      


    PARITY: process(SCSI_D_OUT_I, SCSI_IOn_I)
    -- This process provides the parity checking of the SCSI data.
    -- SCSI uses 'odd parity'. An even number of 1s
    -- lead to DPn = '0' on the external SCSI bus. 
    variable PAR_VAR : std_logic;
    begin
        PAR_VAR := '1'; -- We need odd parity.
        for i in 7 downto 0 loop
            if SCSI_D_OUT_I(i) = '1' then
                PAR_VAR := not PAR_VAR;
            end if; 
        end loop;
        --
        case SCSI_IOn_I is
            when '1' => SCSI_DP_OUT  <= not PAR_VAR; -- SCSI bus is inverted.
            when others => SCSI_DP_OUT  <= '1'; -- Hi impedant (use Tri-State).
        end case;
    end process PARITY;

    -- ACSI target ID:
    with TARGET_No select
        TARGET_ID <= "01111111" when "111",
                     "10111111" when "110",
                     "11011111" when "101",
                     "11101111" when "100",
                     "11110111" when "011",
                     "11111011" when "010",
                     "11111101" when "001",
                     "11111110" when "000";

    -- SCSI initiator ID:
    -- The SCSI_IDn switch is inverted.
    with SCSI_IDn select
        INITIATOR_ID <= "01111111" when "000",
                        "10111111" when "001",
                        "11011111" when "010",
                        "11101111" when "011",
                        "11110111" when "100",
                        "11111011" when "101",
                        "11111101" when "110",
                        "11111110" when "111";

    DATA_BUFFER: process
    -- The ACSI_DATA register stores the ACSI data during the ACSI command and
    -- data out phase. Important!! The Data is valid right after the falling
    -- edge of HDCSn or HDACK_In. So we use a locking feature to meet data 
    -- integrity.
    -- ACSI_D_OUT is the register for the incoming SCDI data from the targets.
    variable LOCK   : boolean;
    begin
        wait until CLK = '1' and CLK' event;
if CTRL_STATE = IDLE then
    LOCK := false;
        elsif CTRL_STATE = SCSI_BUS_FREE and CA1_I = '0' and HDCS_In = '0' and LOCK = false then
            -- Control byte 0, rip the target number. The MSB's zeroes
            -- indicate an SCSI command of the group 0 with 6 control bytes.
            ACSI_DATA <= "000" & ACSI_D_IN(4 downto 0); -- Group 0 command byte if not x"1F" (x"1F" is the ICD control byte).
            TARGET_No <= ACSI_D_IN(7 downto 5); -- Store the target number separately.
            LOCK := true;
        elsif CTRL_STATE = WAIT_1stBYTE and HDCS_In = '0' and CR_Wn_I = '0' and LOCK = false then
            ACSI_DATA <= ACSI_D_IN; -- This is the group 0, 1, 2 or 5 command byte 0. 
            LOCK := true;
        elsif CTRL_STATE = COMMAND and HDCS_In = '0' and CR_Wn_I = '0' and LOCK = false then
            ACSI_DATA <= ACSI_D_IN; -- Control bytes.
            LOCK := true;
        elsif CTRL_STATE = DATA_IO and HDACK_In = '0' and LOCK = false then
            ACSI_DATA <= ACSI_D_IN; -- Data bytes.
            LOCK := true;
        elsif HDCS_In = '1' and HDACK_In = '1' then
            LOCK := false;
        end if;
        --
        if SCSI_REQ_In = '0' then
            ACSI_D_OUT <= not SCSI_D_IN;
        end if;
    end process DATA_BUFFER;

    ACSI_D_EN <= '1' when CTRL_STATE = DATA_IO and SCSI_IOn_I = '0' else
                 '1' when CTRL_STATE = STATUS else '0';

    with CTRL_STATE select
        ACSI_CTRL_ENn <= '0' when WAIT_1stBYTE | COMMAND | DATA_IO | STATUS | MESSAGE_IN, not RES_I when others;
    SCSI_D_OUT <= SCSI_D_OUT_I;
    SCSI_D_OUT_I <= TARGET_ID and INITIATOR_ID when CTRL_STATE = SELCT else not ACSI_DATA; -- Initiator ID and the target ID or data.
    SCSI_D_EN <= '1' when CTRL_STATE = SELCT else SCSI_IOn_I;

    with CTRL_STATE select
        SCSI_CTRL_EN <= '0' when IDLE | SCSI_BUS_FREE | CHECK_MODE | WAIT_1stBYTE | ACSI_BUS_RELEASE,
                        '1' when others;
    
    SCSI_SELn <= '0' when CTRL_STATE = SELCT else '1';
    SCSI_RSTn <= '0' when RES_I = '1' else '1';

    SCSI_ATNn <= '1'; -- We do not provide initiator messages.
end BEHAVIOR;
