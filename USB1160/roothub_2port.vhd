------------------------------------------------------------------------
----                                                                ----
---- USB1160 IP Core                                                ----
----                                                                ----
---- Description:                                                   ----
---- This model provides an embedded Universal Serial Bus host      ----
---- controller compatible to the Philips ISP1160.                  ----
----                                                                ----
---- This entity is the two port root hub.                          ----
----                                                                ----
----                                                                ----
---- Lo speed device  Control sign   Hi speed device                ----
----                                                                ----
---- DP  DM           CTRL           DP  DM                         ----
----  0   0           SE0             0   0  -- Single ended zero.  ----
----  0   1            J              1   0                         ----
----  1   0            K              0   1                         ----
----  1   1           SE1             1   1  -- Single ended one.   ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
----                                                                ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2020... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K20B  20201224 WF
--   Draft version.
-- Revision 2K22A  20221224 WF
--   Debugging version.
-- Revision 2K23A  20230620 WF
--   Initial release.
-- Revision 2K23B  20231224 WF
--   Loads of updates, fixes and improvements.
-- Revision 2K24A  20240620 WF
--   UPSTREAM_x glitch filter improvements.
--   Minor changes.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ROOTHUB_2PORT is
    port(
        CLK_48MHz           : in std_logic;
        RESET               : in std_logic;

        -- Downstream Ports:
        DP1_IN              : in std_logic;
        DM1_IN              : in std_logic;
        DP2_IN              : in std_logic;
        DM2_IN              : in std_logic;
        DP1_OUT             : out std_logic;
        DM1_OUT             : out std_logic;
        DPM1_EN             : buffer std_logic;
        DP2_OUT             : out std_logic;
        DM2_OUT             : out std_logic;
        DPM2_EN             : buffer std_logic;

        -- Upstream Port:
        DP_IN               : in std_logic; -- Data line.
        DM_IN               : in std_logic; -- Data line.
        DP_OUT              : out std_logic; -- Data line.
        DM_OUT              : out std_logic; -- Data line.

        -- Power switches:
        PSW1n               : buffer std_logic;
        PSW2n               : buffer std_logic;
        OC1n                : in std_logic;
        OC2n                : in std_logic;

        -- Port1 controls:
        CCS_1               : out std_logic; -- Current connect status.
        LSDA_1              : out std_logic; -- Low speed device attached.
        POCI_1              : out std_logic; -- Port overcurrent indicator.
        PESC_1              : out std_logic; -- Port enable status change.
        PRSC_1              : out std_logic; -- Port reset status change.
        PSSC_1              : out std_logic; -- Port suspend status change.
        PES_1               : in std_logic; -- Port enable status.
        PPS_1               : in std_logic; -- Port power switch.
        PRS_1               : in std_logic; -- Port reset status.

        -- Port2 controls:
        CCS_2               : out std_logic; -- Current connect status.
        LSDA_2              : out std_logic; -- Low speed device attached.
        POCI_2              : out std_logic; -- Port overcurrent indicator.
        PESC_2              : out std_logic; -- Port enable status change.
        PRSC_2              : out std_logic; -- Port reset status change.
        PSSC_2              : out std_logic; -- Port suspend status change.
        PES_2               : in std_logic; -- Port enable status.
        PPS_2               : in std_logic; -- Port power switch.
        PRS_2               : in std_logic; -- Port reset status.
        
        UPSTREAM_P1_P2n     : out std_logic -- Indicates active port.
    );
end ROOTHUB_2PORT;

architecture BEHAVIOUR of ROOTHUB_2PORT is
type PORT_STATES is(UNPLUGGED, PORT_RESET, PORT_SETUP, PORT_RESET_RECOVERY, PLUGGED);
type PORT_SWITCHSTATES is(DISABLED, ENABLED, SUSPENDED, RESUME, RESUME_EOP_SE0, RESUME_EOP_J);
signal DPM_EN                   : std_logic;
signal EN_LOWSPEED              : std_logic;
signal KEEP_ALIVE_SE0           : boolean;
signal KEEP_ALIVE_J             : boolean;
signal PORT_I_STATE             : PORT_STATES;
signal PORT_I_NSTATE            : PORT_STATES;
signal PORT_II_STATE            : PORT_STATES;
signal PORT_II_NSTATE           : PORT_STATES;
signal PORT_I_SWITCHSTATE       : PORT_SWITCHSTATES;
signal PORT_I_NSWITCHSTATE      : PORT_SWITCHSTATES;
signal PORT_II_SWITCHSTATE      : PORT_SWITCHSTATES;
signal PORT_II_NSWITCHSTATE     : PORT_SWITCHSTATES;
signal P1_Txx                   : std_logic;
signal P2_Txx                   : std_logic;
signal PORT_I_ATTACHED          : boolean;
signal PORT_II_ATTACHED         : boolean;
signal SPEED_I                  : std_logic;
signal SPEED_II                 : std_logic;
signal TRIGGER_1                : std_logic;
signal TRIGGER_2                : std_logic;
signal UPSTREAM_I               : std_logic;
signal UPSTREAM_II              : std_logic;
begin
    TIMING : process
    -- This is the logic providing a strobe signal
    -- every 1ms and the required Timings for USB
    -- operation as also resume suspend timing.
    variable CNT_1ms    : integer range 0 to 65535;
    variable CNT_10us   : integer range 0 to 511;
    variable STRB_1ms   : std_logic;
    variable STRB_10us  : std_logic;
    variable TIMER_1    : integer range 0 to 127;
    variable TIMER_2    : integer range 0 to 127;
    variable TIMER_3    : integer range 0 to 63;
    variable TIMER_4    : integer range 0 to 63;
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if CNT_1ms < 47999 then
            CNT_1ms := CNT_1ms + 1;
            STRB_1ms := '0';
        else
            CNT_1ms := 0;
            STRB_1ms := '1';
        end if;

        if CNT_10us < 479 then
            CNT_10us := CNT_10us + 1;
            STRB_10us := '0';
        else
            CNT_10us := 0;
            STRB_10us := '1';
        end if;

        P1_Txx <= '0'; -- Strobe.
        P2_Txx <= '0'; -- Strobe.

        TRIGGER_1 <= '0'; -- Strobe.
        TRIGGER_2 <= '0'; -- Strobe.

        --
        if PORT_I_STATE /= PORT_SETUP and PORT_I_NSTATE = PORT_SETUP then
            TIMER_1 := 0;
        elsif PORT_I_STATE /= PORT_RESET and PORT_I_NSTATE = PORT_RESET then
            TIMER_1 := 0;
        elsif PORT_I_STATE /= PORT_RESET_RECOVERY and PORT_I_NSTATE = PORT_RESET_RECOVERY then
            TIMER_1 := 0;
        elsif STRB_1ms = '1' and PORT_I_STATE = PORT_SETUP and TIMER_1 < 20 then
            TIMER_1 := TIMER_1 + 1; -- We use 20ms from max. 100ms for connection dejittering. See USB spec.
        elsif STRB_1ms = '1' and PORT_I_STATE = PORT_SETUP then
            P1_Txx <= '1';
        elsif STRB_1ms = '1' and PORT_I_STATE = PORT_RESET and TIMER_1 < 15 then
            TIMER_1 := TIMER_1 + 1;
        elsif STRB_1ms = '1' and PORT_I_STATE = PORT_RESET then
            P1_Txx <= '1';
        elsif STRB_10us = '1' and PORT_I_STATE = PORT_RESET_RECOVERY and TIMER_1 < 9 then
            TIMER_1 := TIMER_1 + 1; -- 90us.
        elsif STRB_10us = '1' and PORT_I_STATE = PORT_RESET_RECOVERY then
            P1_Txx <= '1';
        end if;

        if PORT_II_STATE /= PORT_SETUP and PORT_II_NSTATE = PORT_SETUP then
            TIMER_2 := 0;
        elsif PORT_II_STATE /= PORT_RESET and PORT_II_NSTATE = PORT_RESET then
            TIMER_2 := 0;
        elsif PORT_II_STATE /= PORT_RESET_RECOVERY and PORT_II_NSTATE = PORT_RESET_RECOVERY then
            TIMER_2 := 0;
        elsif STRB_1ms = '1' and PORT_II_STATE = PORT_SETUP and TIMER_2 < 20 then
            TIMER_2 := TIMER_2 + 1; -- We use 20ms from max. 100ms for connection dejittering. See USB spec.
        elsif STRB_1ms = '1' and PORT_II_STATE = PORT_SETUP then
            P2_Txx <= '1';
        elsif STRB_1ms = '1' and PORT_II_STATE = PORT_RESET and TIMER_2 < 15 then
            TIMER_2 := TIMER_2 + 1;
        elsif STRB_1ms = '1' and PORT_II_STATE = PORT_RESET then
            P2_Txx <= '1';
        elsif STRB_10us = '1' and PORT_II_STATE = PORT_RESET_RECOVERY and TIMER_2 < 9 then
            TIMER_2 := TIMER_2 + 1;
        elsif STRB_10us = '1' and PORT_II_STATE = PORT_RESET_RECOVERY then
            P2_Txx <= '1';
        end if;

        if RESET = '1' or PORT_I_SWITCHSTATE = DISABLED then
            TIMER_3 := 0;
        elsif PORT_I_SWITCHSTATE = ENABLED and STRB_1ms = '1' and DP_IN = '1' and DM_IN = '0' and TIMER_3 < 3 then -- J-STATE.
            TIMER_3 := TIMER_3 + 1;
        elsif PORT_I_SWITCHSTATE = ENABLED and STRB_1ms = '1' and DP_IN = '1' and DM_IN = '0' then
            TIMER_3 := 0;
            TRIGGER_1 <= '1'; -- 3ms Timeout.
        elsif PORT_I_SWITCHSTATE = ENABLED and DP_IN = '0' and DM_IN = '1' then -- K-STATE.
            TIMER_3 := 0;
        elsif PORT_I_SWITCHSTATE = ENABLED and DP_IN = '0' and DM_IN = '0' then -- SE0.
            TIMER_3 := 0;
        elsif PORT_I_SWITCHSTATE = SUSPENDED and SPEED_I = '1' and STRB_1ms = '1' and DP1_IN = '1' and DM1_IN = '0' then -- Low speed K-State.
            TRIGGER_1 <= '1';        
        elsif PORT_I_SWITCHSTATE = SUSPENDED and SPEED_I = '0' and STRB_1ms = '1' and DP1_IN = '0' and DM1_IN = '1' then -- Full speed K-State.
            TRIGGER_1 <= '1';        
        elsif PORT_I_SWITCHSTATE = RESUME and STRB_1ms = '1' and TIMER_3 < 20 then -- 20ms RESUME.
            TIMER_3 := TIMER_3 + 1;
        elsif PORT_I_SWITCHSTATE = RESUME and STRB_1ms = '1' then
            TIMER_3 := 0;
            TRIGGER_1 <= '1';        
        elsif PORT_I_SWITCHSTATE = RESUME_EOP_SE0 and TIMER_3 < 63 then -- Two lowspeed EOPs.
            TIMER_3 := TIMER_3 + 1;
        elsif PORT_I_SWITCHSTATE = RESUME_EOP_SE0 then
            TIMER_3 := 0;
            TRIGGER_1 <= '1';
        elsif PORT_I_SWITCHSTATE = RESUME_EOP_J and TIMER_3 < 31 then -- One lowspeed J.
            TIMER_3 := TIMER_3 + 1;
        elsif PORT_I_SWITCHSTATE = RESUME_EOP_J then
            TIMER_3 := 0;
            TRIGGER_1 <= '1';
        end if;

        if RESET = '1' or PORT_II_SWITCHSTATE = DISABLED then
            TIMER_4 := 0;
        elsif PORT_II_SWITCHSTATE = ENABLED and STRB_1ms = '1' and DP_IN = '1' and DM_IN = '0' and TIMER_4 < 3 then -- J-STATE.
            TIMER_4 := TIMER_4 + 1;
        elsif PORT_II_SWITCHSTATE = ENABLED and STRB_1ms = '1' and DP_IN = '1' and DM_IN = '0' then
            TIMER_4 := 0;
            TRIGGER_2 <= '1'; -- 3ms Timeout.
        elsif PORT_II_SWITCHSTATE = ENABLED and DP_IN = '0' and DM_IN = '1' then -- K-STATE.
            TIMER_4 := 0;
        elsif PORT_II_SWITCHSTATE = ENABLED and DP_IN = '0' and DM_IN = '0' then -- SE0.
            TIMER_4 := 0;
        elsif PORT_II_SWITCHSTATE = SUSPENDED and SPEED_II = '1' and STRB_1ms = '1' and DP2_IN = '1' and DM2_IN = '0' then -- Low speed K-State.
            TRIGGER_2 <= '1';        
        elsif PORT_II_SWITCHSTATE = SUSPENDED and SPEED_II = '0' and STRB_1ms = '1' and DP2_IN = '0' and DM2_IN = '1' then -- Full speed K-State.
            TRIGGER_2 <= '1';        
        elsif PORT_II_SWITCHSTATE = RESUME and STRB_1ms = '1' and TIMER_4 < 20 then -- 20ms RESUME.
            TIMER_4 := TIMER_4 + 1;
        elsif PORT_II_SWITCHSTATE = RESUME and STRB_1ms = '1' then
            TIMER_4 := 0;
            TRIGGER_2 <= '1';        
        elsif PORT_II_SWITCHSTATE = RESUME_EOP_SE0 and TIMER_4 < 63 then -- Two lowspeed EOPs.
            TIMER_4 := TIMER_4 + 1;
        elsif PORT_II_SWITCHSTATE = RESUME_EOP_SE0 then
            TIMER_4 := 0;
            TRIGGER_2 <= '1';
        elsif PORT_II_SWITCHSTATE = RESUME_EOP_J and TIMER_4 < 31 then -- One lowspeed J.
            TIMER_4 := TIMER_4 + 1;
        elsif PORT_II_SWITCHSTATE = RESUME_EOP_J then
            TIMER_4 := 0;
            TRIGGER_2 <= '1';
        end if;
    end process TIMING;

    ATTACHMENT: process
    -- This logic detects the attachment of a USB device.
    -- If the attachment is stable for 2.5us, the devices
    -- are assumed attached. If the devices are attached
    -- and the signals indicate detachment for 2.5us, the
    -- respective devices are assumed detached.
    variable DELAY_I    : integer range 0 to 127;
    variable DELAY_II   : integer range 0 to 127;
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if PPS_1 = '0' or RESET = '1' then
            DELAY_I := 0;
            PORT_I_ATTACHED <= false;
        elsif PORT_I_STATE = UNPLUGGED and (DP1_IN or DM1_IN) = '0' then -- SE0.
            DELAY_I := 0;
            PORT_I_ATTACHED <= false;
        elsif PORT_I_STATE = UNPLUGGED and (DP1_IN xor DM1_IN) = '1' then
            if DELAY_I < 120 then -- 2.5us @48MHz.
                DELAY_I := DELAY_I + 1;
            else
                PORT_I_ATTACHED <= true;
            end if;
        elsif PORT_I_STATE = PLUGGED and DPM1_EN = '0' and (DP1_IN xor DM1_IN) = '1' then
            DELAY_I := 120;
        elsif PORT_I_STATE = PLUGGED and DPM1_EN = '0' and DP1_IN = '0' and DM1_IN = '0' then
            if DELAY_I > 0 then -- 2.5us @48MHz.
                DELAY_I := DELAY_I - 1;
            else
                PORT_I_ATTACHED <= false;
            end if;
        end if;
        --
        if PPS_2 = '0' or RESET = '1' then
            DELAY_II := 0;
            PORT_II_ATTACHED <= false;
        elsif PORT_II_STATE = UNPLUGGED and (DP2_IN or DM2_IN) = '0' then -- SE0.
            DELAY_II := 0;
            PORT_II_ATTACHED <= false;
        elsif PORT_II_STATE = UNPLUGGED and (DP2_IN xor DM2_IN) = '1' then
            if DELAY_II < 120 then -- 2.5us @48MHz.
                DELAY_II := DELAY_II + 1;
            else
                PORT_II_ATTACHED <= true;
            end if;
        elsif PORT_II_STATE = PLUGGED and DPM2_EN = '0' and (DP2_IN xor DM2_IN) = '1' then
            DELAY_II := 120;
        elsif PORT_II_STATE = PLUGGED and DPM2_EN = '0' and DP2_IN = '0' and DM2_IN = '0' then
            if DELAY_II > 0 then -- 2.5us @48MHz.
                DELAY_II := DELAY_II - 1;
            else
                PORT_II_ATTACHED <= false;
            end if;
        end if;
    end process ATTACHMENT;

    SPEED_CTRL: process
    -- This signal switches the PHY to the respective
    -- operation mode.
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if PORT_I_STATE = UNPLUGGED then
            SPEED_I <= '0'; -- Full speed.
        elsif PORT_I_STATE = PORT_SETUP and PORT_I_NSTATE = PLUGGED and DP1_IN = '1' and DM1_IN = '0' then
            SPEED_I <= '0'; -- Full speed.
        elsif PORT_I_STATE = PORT_SETUP and PORT_I_NSTATE = PLUGGED then
            SPEED_I <= '1'; -- Lo speed.
        elsif PORT_I_STATE = PORT_RESET_RECOVERY and PORT_I_NSTATE = PLUGGED and DP1_IN = '1' and DM1_IN = '0' then
            SPEED_I <= '0'; -- Full speed.
        elsif PORT_I_STATE = PORT_RESET_RECOVERY and PORT_I_NSTATE = PLUGGED then
            SPEED_I <= '1'; -- Lo speed.
        end if;
        --
        if PORT_II_STATE = UNPLUGGED then
            SPEED_II <= '0'; -- Full speed.
        elsif PORT_II_STATE = PORT_SETUP and PORT_II_NSTATE = PLUGGED and DP2_IN = '1' and DM2_IN = '0' then
            SPEED_II <= '0'; -- Full speed.
        elsif PORT_II_STATE = PORT_SETUP and PORT_II_NSTATE = PLUGGED then
            SPEED_II <= '1'; -- Lo speed.
        elsif PORT_II_STATE = PORT_RESET_RECOVERY and PORT_II_NSTATE = PLUGGED and DP2_IN = '1' and DM2_IN = '0' then
            SPEED_II <= '0'; -- Full speed.
        elsif PORT_II_STATE = PORT_RESET_RECOVERY and PORT_II_NSTATE = PLUGGED then
            SPEED_II <= '1'; -- Lo speed.
        end if;
    end process SPEED_CTRL;

    DOWNSTREAM_CTRL: process
    -- This logic scans the transmitter data stream for the SYNC pattern
    -- and right after it for the high speed PID. If this PID meets the
    -- value for the low speed preamble, the low speed transmission is
    -- enabled until the low speed EOP.
    -- When after the SYNC pattern a SOF PID is detected, then the keep
    -- alive for the low speed attached devices is released.    
    variable ALIVE_CNT      : std_logic_vector(4 downto 0);
    variable BITCNT         : std_logic_vector(3 downto 0);
    variable DELAY_CNT      : std_logic_vector(2 downto 0);
    variable EOP_SE0        : boolean;
    variable LOWSPEED_EOP   : std_logic;
    variable NRZI_IN        : std_logic;
    variable PID_SHIFTER    : std_logic_vector(7 downto 0);
    variable TIMER_Tx       : std_logic_vector(1 downto 0);
    variable Tx_ACTIVE      : std_logic;
    variable Tx_STRB        : std_logic;
    variable USB_D_IN       : std_logic;
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;

        if RESET = '1' or DPM_EN = '0' then
            PID_SHIFTER := x"00";
            BITCNT := x"0";
            Tx_ACTIVE := '0';
            EN_LOWSPEED <= '0';
        elsif Tx_STRB = '1' then
            if Tx_ACTIVE = '0' then -- Search for SYNC pattern (two zeros in incoming NRZI data stream).
                PID_SHIFTER := x"00";
                if BITCNT = x"0" and NRZI_IN = '0' then -- This is a full speed K.
                    BITCNT := BITCNT + '1';
                elsif BITCNT = x"1" and NRZI_IN = '0' then -- This is a second full speed K.
                    BITCNT := x"0";
                    Tx_ACTIVE := '1'; -- Sync pattern detected.
                else
                    BITCNT := x"0";
                end if;
            elsif EOP_SE0 = true and (DM_IN xor DP_IN) = '1' then -- J state in full or low speed detected.
                Tx_ACTIVE := '0';
            elsif EN_LOWSPEED = '1' then
                null;
            elsif Tx_ACTIVE = '1' and BITCNT < x"8" then
                BITCNT := BITCNT + '1';
                PID_SHIFTER := USB_D_IN & PID_SHIFTER(7 downto 1); -- LSB comes first.
            elsif Tx_ACTIVE = '1' and BITCNT = x"8" and PID_SHIFTER = x"3C" then -- This is the Low speed preamble.
                EN_LOWSPEED <= '1';
                BITCNT := BITCNT + '1';
            elsif Tx_ACTIVE = '1' and BITCNT = x"8" and PID_SHIFTER = x"A5" then -- This is the SOF PID.
                null; -- Just wait.
            end if;
        end if;

        if RESET = '1' then
            DPM_EN <= '0';
            DELAY_CNT := "000";
            EOP_SE0 := false;
            LOWSPEED_EOP := '0';
        elsif DM_IN = '0' and DP_IN = '1' and LOWSPEED_EOP = '1' then -- This is the full speed J state.
            LOWSPEED_EOP := '0'; -- Release the low speed EOP here.
        elsif DM_IN = '1' and DP_IN = '0' and LOWSPEED_EOP = '0' then -- This is the full speed K state.
            DPM_EN <= '1'; -- DPM is always enabled in full speed.
        elsif DM_IN = '0' and DP_IN = '0' then -- SE0 detected.
            EOP_SE0 := true;
        elsif Tx_STRB = '1' and EOP_SE0 = true and (DM_IN xor DP_IN) = '1' and EN_LOWSPEED = '1' and DELAY_CNT < "111" then -- J state in full or low speed detected.
            DELAY_CNT := DELAY_CNT + '1'; -- 8 full speed bit times delay for the low speed J after SE0.
        elsif Tx_STRB = '1' and EOP_SE0 = true and (DM_IN xor DP_IN) = '1' then -- J state in full or low speed detected.
            DPM_EN <= '0';
            DELAY_CNT := "000";
            EOP_SE0 := false;
            LOWSPEED_EOP := EN_LOWSPEED; -- This detects a low speed EOP.
        end if;

        if RESET = '1' then
            ALIVE_CNT := "00000"; 
            KEEP_ALIVE_SE0 <= false;
            KEEP_ALIVE_J <= false;
        elsif Tx_STRB = '1' then
            if PID_SHIFTER = x"A5" and ALIVE_CNT = "00000" then -- This is the SOF PID.
                KEEP_ALIVE_SE0 <= true;
                ALIVE_CNT := "11000";
            elsif ALIVE_CNT > "01001" then
                ALIVE_CNT := ALIVE_CNT -'1';
            elsif ALIVE_CNT = "01001" then
                KEEP_ALIVE_SE0 <= false;
                KEEP_ALIVE_J <= true;
                ALIVE_CNT := ALIVE_CNT -'1';
            elsif ALIVE_CNT > "00001" then
                ALIVE_CNT := ALIVE_CNT -'1';
            elsif ALIVE_CNT = "00001" then
                KEEP_ALIVE_J <= false;
                ALIVE_CNT := ALIVE_CNT -'1';
            end if;
        end if;

        if DPM_EN = '0' or EN_LOWSPEED = '1' then
            NRZI_IN := '1';
            USB_D_IN := '1';
        elsif Tx_STRB = '1' then
            -- Receiver:
            USB_D_IN := (DP_IN and not DM_IN) xnor NRZI_IN; -- NRZI-S decoding.
            NRZI_IN := DP_IN and not DM_IN;
        end if;

        if DPM_EN = '0' and ALIVE_CNT = "00000" then
            TIMER_Tx := "00";
            Tx_STRB := '0';
        else
            TIMER_Tx := TIMER_Tx + '1';
            case TIMER_Tx is -- 12Mb/s.
                when "10" => Tx_STRB := '1';
                when others => Tx_STRB := '0';
            end case;
        end if;
    end process DOWNSTREAM_CTRL;

    UPSTREAM_CTRL: process
    -- This logic provides information, when data is sent from a device to the host.
    -- The start of a transmission is detected when the J-state, which is the IDLE state,
    -- switches to the K state (start of a package, SOP). It ends, if the J-state after
    -- a detected SE0-state is detected. To avoid misfunction due to setup and hold issues,
    -- the SE0 lock is also controlled by UPSTREAM_x = '1' means may only occur in the
    -- end of a package.
    -- The SE0_FLT are filters to avoid runningg into clock domain crossing issues due to
    -- setup hold violations.
    variable SE0_LOCK_I     : boolean;
    variable SE0_LOCK_II    : boolean;
    variable SE0_FLT_I      : std_logic_vector(4 downto 0);
    variable SE0_FLT_II     : std_logic_vector(4 downto 0);
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if PORT_I_STATE = UNPLUGGED then
            UPSTREAM_I <= '0';
            SE0_LOCK_I := false;
        elsif DPM_EN = '0' and DM_IN = '1' and DP_IN = '0' then -- Avoid release of UPSTREAM in the beginning of transmitting (DPM_EN is one clock late).
            UPSTREAM_I <= '0';
            SE0_LOCK_I := false;
        elsif SPEED_I = '1' and DPM_EN = '0' and DP1_IN = '1' and DM1_IN = '0' then -- K state for Lo speed device.
            UPSTREAM_I <= '1';
            SE0_LOCK_I := false;
        elsif SPEED_I = '0' and DPM_EN = '0' and DP1_IN = '0' and DM1_IN = '1' then -- K state for Hi speed device.
            UPSTREAM_I <= '1';
            SE0_LOCK_I := false;
        elsif UPSTREAM_I = '1' and SE0_LOCK_I = false then -- SE0 detected.
            -- This is a glitch filter:
            if SPEED_I = '0' and DP1_IN = '0' and DM1_IN = '0' and SE0_FLT_I < "00011" then -- Full speed.
                SE0_FLT_I := SE0_FLT_I + '1';
            elsif SPEED_I = '1' and DP1_IN = '0' and DM1_IN = '0' and SE0_FLT_I < "11111" then -- Low speed.
                SE0_FLT_I := SE0_FLT_I + '1';
            elsif DP1_IN = '0' and DM1_IN = '0' then
                SE0_FLT_I := "00000";
                SE0_LOCK_I := true;
            else
                SE0_FLT_I := "00000";
            end if;
        elsif SPEED_I = '1' and DP1_IN = '0' and DM1_IN = '1' and SE0_LOCK_I = true then -- J state for Lo speed device.
            UPSTREAM_I <= '0';
        elsif SPEED_I = '0' and DP1_IN = '1' and DM1_IN = '0' and SE0_LOCK_I = true then -- J state for Hi speed device.
            UPSTREAM_I <= '0';
        end if;
        --
        if PORT_II_STATE = UNPLUGGED then
            UPSTREAM_II <= '0';
            SE0_LOCK_II := false;
        elsif DPM_EN = '0' and DM_IN = '1' and DP_IN = '0' then -- Avoid release of UPSTREAM in the beginning of transmitting (DPM_EN is one clock late).
            UPSTREAM_II <= '0';
            SE0_LOCK_II := false;
        elsif SPEED_II = '1' and DPM_EN = '0' and DP2_IN = '1' and DM2_IN = '0' then -- K state for Lo speed device.
            UPSTREAM_II <= '1';
            SE0_LOCK_II := false;
        elsif SPEED_II = '0' and DPM_EN = '0' and DP2_IN = '0' and DM2_IN = '1' then -- K state for Hi speed device.
            UPSTREAM_II <= '1';
            SE0_LOCK_II := false;
        elsif UPSTREAM_II = '1' and DP2_IN = '0' and DM2_IN = '0' and SE0_LOCK_II = false then -- SE0 detected.
            -- This is a glitch filter:
            if SPEED_II = '0' and DP2_IN = '0' and DM2_IN = '0' and SE0_FLT_II < "00011" then -- Full speed.
                SE0_FLT_II := SE0_FLT_II + '1';
            elsif SPEED_II = '1' and DP2_IN = '0' and DM2_IN = '0' and SE0_FLT_II < "11111" then -- Low speed.
                SE0_FLT_II := SE0_FLT_II + '1';
            elsif DP2_IN = '0' and DM2_IN = '0' then
                SE0_FLT_II := "00000";
                SE0_LOCK_II := true;
            else
                SE0_FLT_II := "00000";
            end if;
        elsif SPEED_II = '1' and DP2_IN = '0' and DM2_IN = '1' and SE0_LOCK_II = true then -- J state for Lo speed device.
            UPSTREAM_II <= '0';
        elsif SPEED_II = '0' and DP2_IN = '1' and DM2_IN = '0' and SE0_LOCK_II = true then -- J state for Hi speed device.
            UPSTREAM_II <= '0';
        end if;
    end process UPSTREAM_CTRL;

    USB_STATEREGS: process
    -- This is the USB state machines register.
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if RESET = '1' then
            PORT_I_SWITCHSTATE <= DISABLED;
            PORT_I_STATE <= UNPLUGGED;
            PORT_II_SWITCHSTATE <= DISABLED;
            PORT_II_STATE <= UNPLUGGED;
        else
            PORT_I_SWITCHSTATE <= PORT_I_NSWITCHSTATE;
            PORT_I_STATE <= PORT_I_NSTATE;
            PORT_II_SWITCHSTATE <= PORT_II_NSWITCHSTATE;
            PORT_II_STATE <= PORT_II_NSTATE;
        end if;
    end process USB_STATEREGS;

    PORT_I_STATEDEC: process(P1_Txx, PORT_I_STATE, PORT_I_SWITCHSTATE, PORT_I_ATTACHED, PRS_1)
    -- This is the USB next state decoder for USB_I.
    begin
        case PORT_I_STATE is
            when UNPLUGGED =>
                if PORT_I_ATTACHED = true then
                    PORT_I_NSTATE <= PORT_SETUP; -- Device detected.
                else
                    PORT_I_NSTATE <= UNPLUGGED;
                end if;
            when PORT_SETUP =>
                if P1_Txx = '1' and PORT_I_ATTACHED = true then -- 50ms.
                    PORT_I_NSTATE <= PLUGGED;
                elsif P1_Txx = '1' then -- 50ms.
                    PORT_I_NSTATE <= UNPLUGGED;
                else
                    PORT_I_NSTATE <= PORT_SETUP;
                end if;
            when PORT_RESET =>
                if P1_Txx = '1' then -- 15ms.
                    PORT_I_NSTATE <= PORT_RESET_RECOVERY;
                else
                    PORT_I_NSTATE <= PORT_RESET;
                end if;
            when PORT_RESET_RECOVERY =>
                -- This is a 100us delay to evaluate the
                -- device speed.
                if P1_Txx = '1' then
                    PORT_I_NSTATE <= PLUGGED;
                else
                    PORT_I_NSTATE <= PORT_RESET_RECOVERY;
                end if;
            when PLUGGED =>
                if PRS_1 = '1' then
                    PORT_I_NSTATE <= PORT_RESET;
                elsif PORT_I_ATTACHED = false then
                    PORT_I_NSTATE <= UNPLUGGED; -- Disconnection detected.
                else
                    PORT_I_NSTATE <= PLUGGED;
                end if;
        end case;
    end process PORT_I_STATEDEC;

    PORTSWITCH_I_STATEDEC: process(DP_IN, DM_IN, PORT_I_STATE, PORT_I_SWITCHSTATE, PES_1, TRIGGER_1)
    begin
        case PORT_I_SWITCHSTATE is
            when DISABLED =>
                if PES_1 = '1' then
                    PORT_I_NSWITCHSTATE <= ENABLED;
                else
                    PORT_I_NSWITCHSTATE <= DISABLED;
                end if;
            when ENABLED =>
                if PES_1 = '0' then
                    PORT_I_NSWITCHSTATE <= DISABLED;
                elsif TRIGGER_1 = '1' then
                    PORT_I_NSWITCHSTATE <= SUSPENDED;
                else
                    PORT_I_NSWITCHSTATE <= ENABLED;
                end if;
            when SUSPENDED =>
                if PES_1 = '0' then
                    PORT_I_NSWITCHSTATE <= DISABLED;
                elsif DP_IN = '0' and DM_IN = '1' then -- K-State.
                    PORT_I_NSWITCHSTATE <= RESUME;
                elsif DP_IN = '0' and DM_IN = '0' then -- SE0.
                    PORT_I_NSWITCHSTATE <= RESUME;
                elsif TRIGGER_1 = '1' then -- RESUME by Device.
                    PORT_I_NSWITCHSTATE <= RESUME;
                else
                    PORT_I_NSWITCHSTATE <= SUSPENDED;
                end if;
            when RESUME =>
                if TRIGGER_1 = '1' then
                    PORT_I_NSWITCHSTATE <= RESUME_EOP_SE0;
                else
                    PORT_I_NSWITCHSTATE <= RESUME;
                end if;
            when RESUME_EOP_SE0 =>
                if TRIGGER_1 = '1' then
                    PORT_I_NSWITCHSTATE <= RESUME_EOP_J;
                else
                    PORT_I_NSWITCHSTATE <= RESUME_EOP_SE0;
                end if;
            when RESUME_EOP_J =>
                if TRIGGER_1 = '1' then
                    PORT_I_NSWITCHSTATE <= ENABLED;
                else
                    PORT_I_NSWITCHSTATE <= RESUME_EOP_J;
                end if;
        end case;
    end process PORTSWITCH_I_STATEDEC;

    PORT_II_STATEDEC: process(P2_Txx, PORT_II_STATE, PORT_II_SWITCHSTATE, PORT_II_ATTACHED, PRS_2)
    -- This is the USB next state decoder for USB_II.
    begin
        case PORT_II_STATE is
            when UNPLUGGED =>
                if PORT_II_ATTACHED = true then
                    PORT_II_NSTATE <= PORT_SETUP; -- Device detected.
                else
                    PORT_II_NSTATE <= UNPLUGGED;
                end if;
            when PORT_SETUP =>
                if P2_Txx = '1' and PORT_II_ATTACHED = true then -- 20ms.
                    PORT_II_NSTATE <= PLUGGED;
                elsif P2_Txx = '1' then -- 20ms.
                    PORT_II_NSTATE <= UNPLUGGED;
                else
                    PORT_II_NSTATE <= PORT_SETUP;
                end if;
            when PORT_RESET =>
                if P2_Txx = '1' then -- 10ms.
                    PORT_II_NSTATE <= PORT_RESET_RECOVERY;
                else
                    PORT_II_NSTATE <= PORT_RESET;
                end if;
            when PORT_RESET_RECOVERY =>
                -- This is a 100us delay to evaluate the
                -- device speed.
                if P2_Txx = '1' then
                    PORT_II_NSTATE <= PLUGGED;
                else
                    PORT_II_NSTATE <= PORT_RESET_RECOVERY;
                end if;
            when PLUGGED =>
                if PRS_2 = '1' then
                    PORT_II_NSTATE <= PORT_RESET;
                elsif PORT_II_ATTACHED = false then
                    PORT_II_NSTATE <= UNPLUGGED; -- Disconnection detected.
                else
                    PORT_II_NSTATE <= PLUGGED;
                end if;
        end case;
    end process PORT_II_STATEDEC;

    PORTSWITCH_II_STATEDEC: process(DP_IN, DM_IN, PORT_II_STATE, PORT_II_SWITCHSTATE, PES_2, TRIGGER_2)
    begin
        case PORT_II_SWITCHSTATE is
            when DISABLED =>
                if PES_2 = '1' then
                    PORT_II_NSWITCHSTATE <= ENABLED;
                else
                    PORT_II_NSWITCHSTATE <= DISABLED;
                end if;
            when ENABLED =>
                if PES_2 = '0' then
                    PORT_II_NSWITCHSTATE <= DISABLED;
                elsif TRIGGER_2 = '1' then
                    PORT_II_NSWITCHSTATE <= SUSPENDED;
                else
                    PORT_II_NSWITCHSTATE <= ENABLED;
                end if;
            when SUSPENDED =>
                if PES_2 = '0' then
                    PORT_II_NSWITCHSTATE <= DISABLED;
                elsif DP_IN = '0' and DM_IN = '1' then -- K-State.
                    PORT_II_NSWITCHSTATE <= RESUME;
                elsif DP_IN = '0' and DM_IN = '0' then -- SE0.
                    PORT_II_NSWITCHSTATE <= RESUME;
                elsif TRIGGER_2 = '1' then -- RESUME by Device.
                    PORT_II_NSWITCHSTATE <= RESUME;
                else
                    PORT_II_NSWITCHSTATE <= SUSPENDED;
                end if;
            when RESUME =>
                if TRIGGER_2 = '1' then
                    PORT_II_NSWITCHSTATE <= RESUME_EOP_SE0;
                else
                    PORT_II_NSWITCHSTATE <= RESUME;
                end if;
            when RESUME_EOP_SE0 =>
                if TRIGGER_2 = '1' then
                    PORT_II_NSWITCHSTATE <= RESUME_EOP_J;
                else
                    PORT_II_NSWITCHSTATE <= RESUME_EOP_SE0;
                end if;
            when RESUME_EOP_J =>
                if TRIGGER_2 = '1' then
                    PORT_II_NSWITCHSTATE <= ENABLED;
                else
                    PORT_II_NSWITCHSTATE <= RESUME_EOP_J;
                end if;
        end case;
    end process PORTSWITCH_II_STATEDEC;

    -- Broadcast for downstreaming:
    -- The Upstream port always have full speed polarity.
    -- The reset signaling is SE0.
    DP1_OUT <= '0' when PORT_I_STATE = PORT_RESET else
               '0' when SPEED_I = '1' and KEEP_ALIVE_SE0 = true else -- SE0.
               '0' when SPEED_I = '1' and KEEP_ALIVE_J = true else -- SE0.
               '0' when DP_IN = '0' and DM_IN = '0' else -- SE0.
               '1' when PORT_I_SWITCHSTATE = RESUME and SPEED_I = '1' else -- Low speed K.
               '0' when PORT_I_SWITCHSTATE = RESUME else -- FULL speed K.
               '0' when PORT_I_SWITCHSTATE = RESUME_EOP_SE0 else
               '0' when PORT_I_SWITCHSTATE = RESUME_EOP_J and SPEED_I = '1' else -- Low speed J.
               '1' when PORT_I_SWITCHSTATE = RESUME_EOP_J else -- Full speed J.
               DP_IN when SPEED_I = '0' else not DP_IN;

    DM1_OUT <= '0' when PORT_I_STATE = PORT_RESET else
               '0' when SPEED_I = '1' and KEEP_ALIVE_SE0 = true else -- SE0.
               '1' when SPEED_I = '1' and KEEP_ALIVE_J = true else -- SE0.
               '0' when DP_IN = '0' and DM_IN = '0' else -- SE0.
               '0' when PORT_I_SWITCHSTATE = RESUME and SPEED_I = '1' else -- Low speed K.
               '1' when PORT_I_SWITCHSTATE = RESUME else -- FULL speed K.
               '0' when PORT_I_SWITCHSTATE = RESUME_EOP_SE0 else
               '1' when PORT_I_SWITCHSTATE = RESUME_EOP_J and SPEED_I = '1' else -- Low speed J.
               '0' when PORT_I_SWITCHSTATE = RESUME_EOP_J else -- Full speed J.
               DM_IN when SPEED_I = '0' else not DM_IN;

    DP2_OUT <= '0' when PORT_II_STATE = PORT_RESET else
               '0' when SPEED_II = '1' and KEEP_ALIVE_SE0 = true else -- SE0.
               '0' when SPEED_II = '1' and KEEP_ALIVE_J = true else -- SE0.
               '0' when DP_IN = '0' and DM_IN = '0' else -- SE0.
               '1' when PORT_II_SWITCHSTATE = RESUME and SPEED_II = '1' else -- Low speed K.
               '0' when PORT_II_SWITCHSTATE = RESUME else -- FULL speed K.
               '0' when PORT_II_SWITCHSTATE = RESUME_EOP_SE0 else
               '0' when PORT_II_SWITCHSTATE = RESUME_EOP_J and SPEED_II = '1' else -- Low speed J.
               '1' when PORT_II_SWITCHSTATE = RESUME_EOP_J else -- Full speed J.
               DP_IN when SPEED_II = '0' else not DP_IN;

    DM2_OUT <= '0' when PORT_II_STATE = PORT_RESET else
               '0' when SPEED_II = '1' and KEEP_ALIVE_SE0 = true else -- SE0.
               '1' when SPEED_II = '1' and KEEP_ALIVE_J = true else -- SE0.
               '0' when DP_IN = '0' and DM_IN = '0' else -- SE0.
               '0' when PORT_II_SWITCHSTATE = RESUME and SPEED_II = '1' else -- Low speed K.
               '1' when PORT_II_SWITCHSTATE = RESUME else -- FULL speed K.
               '0' when PORT_II_SWITCHSTATE = RESUME_EOP_SE0 else
               '1' when PORT_II_SWITCHSTATE = RESUME_EOP_J and SPEED_II = '1' else -- Low speed J.
               '0' when PORT_II_SWITCHSTATE = RESUME_EOP_J else -- Full speed J.
               DM_IN when SPEED_II = '0' else not DM_IN;

    DPM1_EN <= '1' when PORT_I_STATE = PORT_RESET else -- Reset is highest prioritized.
               '0' when PORT_I_SWITCHSTATE = DISABLED or PORT_I_SWITCHSTATE = SUSPENDED else
               '0' when PORT_I_STATE = PORT_RESET_RECOVERY else
               '1' when PORT_I_SWITCHSTATE = RESUME else
               '1' when PORT_I_SWITCHSTATE = RESUME_EOP_SE0 else
               '1' when PORT_I_SWITCHSTATE = RESUME_EOP_J else
               '1' when SPEED_I = '1' and KEEP_ALIVE_SE0 = true else
               '1' when SPEED_I = '1' and KEEP_ALIVE_J = true else
               '1' when PORT_I_STATE = PLUGGED and SPEED_I = '0' and DPM_EN = '0' and DM_IN = '1' and DP_IN = '0' else -- This improves the first bit timing of the SYNC.
               DPM_EN when PORT_I_STATE = PLUGGED and SPEED_I = '0' else -- Broadcast low speed and full speed data to full speed devices.
               DPM_EN when PORT_I_STATE = PLUGGED and EN_LOWSPEED = '1' else '0'; -- Broadcast low speed data to low speed devices.

    DPM2_EN <= '1' when PORT_II_STATE = PORT_RESET else -- Reset is highest prioritized.
               '0' when PORT_II_SWITCHSTATE = DISABLED or PORT_II_SWITCHSTATE = SUSPENDED else
               '0' when PORT_II_STATE = PORT_RESET_RECOVERY else
               '1' when PORT_II_SWITCHSTATE = RESUME else
               '1' when PORT_II_SWITCHSTATE = RESUME_EOP_SE0 else
               '1' when PORT_II_SWITCHSTATE = RESUME_EOP_J else
               '1' when SPEED_II = '1' and KEEP_ALIVE_SE0 = true else
               '1' when SPEED_II = '1' and KEEP_ALIVE_J = true else
               '1' when PORT_II_STATE = PLUGGED and SPEED_II = '0' and DPM_EN = '0' and DM_IN = '1' and DP_IN = '0' else -- This improves the first bit timing of the SYNC.
               DPM_EN when PORT_II_STATE = PLUGGED and SPEED_II = '0' else -- Broadcast low speed and full speed data to full speed devices.
               DPM_EN when PORT_II_STATE = PLUGGED and EN_LOWSPEED = '1' else '0'; -- Broadcast low speed data to low speed devices.

    -- The Upstream port always has full speed polarity.
    DP_OUT <= '0' when PORT_I_SWITCHSTATE = SUSPENDED and PORT_I_NSWITCHSTATE = RESUME and UPSTREAM_II = '0' else -- Send K.
              '0' when PORT_II_SWITCHSTATE = SUSPENDED and PORT_II_NSWITCHSTATE = RESUME and UPSTREAM_I = '0' else -- Send K.
              '0' when UPSTREAM_I = '1' and UPSTREAM_II = '1' else -- send K due to a collision.
              '0' when UPSTREAM_I = '1' and DP1_IN = '0' and DM1_IN = '0' else -- SE0.
              '0' when UPSTREAM_II = '1' and DP2_IN = '0' and DM2_IN = '0' else -- SE0.
              DP1_IN when UPSTREAM_I = '1' and SPEED_I = '0' else -- High speed.
              DP2_IN when UPSTREAM_II = '1' and SPEED_II = '0' else -- High speed.
              not DP1_IN when UPSTREAM_I = '1' and SPEED_I = '1' else -- Low speed.
              not DP2_IN when UPSTREAM_II = '1' and SPEED_II = '1' else '1'; -- Low speed.

    DM_OUT <= '1' when PORT_I_SWITCHSTATE = SUSPENDED and PORT_I_NSWITCHSTATE = RESUME and UPSTREAM_II = '0' else -- Send K.
              '1' when PORT_II_SWITCHSTATE = SUSPENDED and PORT_II_NSWITCHSTATE = RESUME and UPSTREAM_I = '0' else -- Send K.    
              '1' when UPSTREAM_I = '1' and UPSTREAM_II = '1' else -- send K due to a collision.
              '0' when UPSTREAM_I = '1' and DP1_IN = '0' and DM1_IN = '0' else -- SE0.
              '0' when UPSTREAM_II = '1' and DP2_IN = '0' and DM2_IN = '0' else -- SE0.
              DM1_IN when UPSTREAM_I = '1' and SPEED_I = '0' else -- High speed.
              DM2_IN when UPSTREAM_II = '1' and SPEED_II = '0' else -- High speed.
              not DM1_IN when UPSTREAM_I = '1' and SPEED_I = '1' else -- Low speed.
              not DM2_IN when UPSTREAM_II = '1' and SPEED_II = '1' else '0'; -- Low speed.

    UPSTREAM_P1_P2n <= UPSTREAM_I;

    POWER_SWITCHES: process
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;

        if RESET = '1' then
            PSW1n <= '1'; -- Off.
        elsif OC1n = '0' then
            PSW1n <= '1'; -- Overcurrent!
        else
            PSW1n <= not PPS_1;
        end if;

        if RESET = '1' then
            PSW2n <= '1'; -- Off.
        elsif OC2n = '0' then
            PSW2n <= '1'; -- Overcurrent!
        else
            PSW2n <= not PPS_2;
        end if;
    end process POWER_SWITCHES;

    PESC_1 <= '1' when PORT_I_SWITCHSTATE = ENABLED and PORT_I_NSWITCHSTATE = SUSPENDED else '0';
    PESC_2 <= '1' when PORT_II_SWITCHSTATE = ENABLED and PORT_II_NSWITCHSTATE = SUSPENDED else '0';
    PSSC_1 <= '1' when PORT_I_SWITCHSTATE = RESUME_EOP_J and PORT_I_NSWITCHSTATE = ENABLED else '0';
    PSSC_2 <= '1' when PORT_II_SWITCHSTATE = RESUME_EOP_J and PORT_II_NSWITCHSTATE = ENABLED else '0';
    CCS_1 <= '0' when PORT_I_STATE = UNPLUGGED else '1';
    CCS_2 <= '0' when PORT_II_STATE = UNPLUGGED else '1';
    PRSC_1 <= '1' when PORT_I_STATE = PORT_RESET and PORT_I_NSTATE = PORT_RESET_RECOVERY else '0';
    PRSC_2 <= '1' when PORT_II_STATE = PORT_RESET and PORT_II_NSTATE = PORT_RESET_RECOVERY else '0';
    LSDA_1 <= '1' when SPEED_I = '1' else '0';
    LSDA_2 <= '1' when SPEED_II = '1' else '0';
    POCI_1 <= not OC1n;
    POCI_2 <= not OC2n;
end architecture BEHAVIOUR;
