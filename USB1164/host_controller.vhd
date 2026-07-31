------------------------------------------------------------------------
----                                                                ----
---- USB1164 IP Core                                                ----
----                                                                ----
---- Description:                                                   ----
---- This model provides an embedded Universal Serial Bus host      ----
---- controller compatible to the Philips ISP1160. It features four ----
---- root hub ports.                                                ----
----                                                                ----
---- This entity is the USB host controller.                        ----
---- It implements the protocol layer of the USB 2.0 specification  ----
---- for low speed and full speed devices and attaches to the       ----
---- ISP160 fifo structure and its registers.                       ----
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
---- SOP = transition from J-State to K-State.                      ----
---- EOP = SE0 followed by J-State.                                 ----
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
---- Copyright © 2024... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K24A  20240620 WF
--   Initial release.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity HOST_CONTROLLER is
    port (
        CLK_48MHz           : in std_logic;
        RESET               : in std_logic;

        -- USB data:
        DP_IN               : in std_logic; -- Data line.
        DM_IN               : in std_logic; -- Data line.
        DP_OUT              : out std_logic; -- Data line.
        DM_OUT              : out std_logic; -- Data line.

        -- Buffer
        BUFFER_IN           : in std_logic_vector(15 downto 0);
        BUFFER_RDY          : in std_logic;
        BUFFER_OUT          : out std_logic_vector(15 downto 0);

        -- Buffer status:
        ATL_BUFF_FULL       : in std_logic;
        ITL0_BUFF_FULL      : in std_logic;
        ITL1_BUFF_FULL      : in std_logic;
        ATL_BUFF_DONE       : out std_logic;
        ITL0_BUFF_DONE      : out std_logic;
        ITL1_BUFF_DONE      : out std_logic;

        -- Buffer control:
        ATL_RD              : buffer std_logic;
        ATL_WR              : buffer std_logic;
        ITL_RD              : buffer std_logic;
        ITL_WR              : buffer std_logic;
        HC_ITL1             : buffer std_logic; -- ITL1 in use by the host controller when '1'.
        HC_ADR              : out std_logic_vector(11 downto 0);

        -- Controls:
        HCR                 : in std_logic; -- Host controller reset.
        SOFTWARE_RESET      : in std_logic;
        HCFS_IN             : in std_logic_vector(1 downto 0); -- Host controller functional state.
        HCFS_OUT            : out std_logic_vector(1 downto 0); -- Host controller functional state.

        FSMPS               : in std_logic_vector(14 downto 0); -- Frame Space Maximum Packet Size.
        FR                  : in std_logic_vector(13 downto 0); -- Frame interval.
        FR_DEC              : buffer std_logic; -- Decrement frame remaining.
        LST                 : in std_logic_vector(10 downto 0); -- LSThreshold.

        ATL_INT             : out std_logic; -- ATL data to be read.
        ITL_INT             : out std_logic; -- ATL data to be read.

        UE                  : out std_logic; -- Unrecoverable error.
        SO                  : out std_logic; -- Scheduling overrun.
        SOF                 : in std_logic; -- Start of frame.
        FRAME_NUMBER        : in std_logic_vector(10 downto 0);

        RD                  : out std_logic; -- Resume detected.
        OPBERR              : out std_logic -- Operational bus error.
    );
end entity HOST_CONTROLLER;

architecture BEHAVIOUR of HOST_CONTROLLER is
type PTD_HEADER_TYPE is array(0 to 7) of std_logic_vector(7 downto 0);
type HC_STATES is (USB_RESET, USB_RESUME, USB_SUSPEND, USB_OPERATIONAL, READ_ITL_PTD, CHECK_ITL_PTD, READ_ATL_PTD, CHECK_ATL_PTD, TRANSMIT_ATL_DATA,
                   TRANSMIT_ITL_DATA, RECEIVE_ATL_DATA, RECEIVE_ITL_DATA, TOKEN_SOF, WRITE_ITL_PTD, WRITE_ATL_PTD);
type SIE_STATES is(IDLE, HANDSHAKE_Rx, HANDSHAKE_Tx, HANDSHAKE_EOP, DATA_EOP, DATA_PID_Rx, DATA_PID_Tx, DATA_Rx, DATA_Tx, ITL_DELAY, PREAMBLE_PID, PREAMBLE_DATA, PREAMBLE_HS, SYNC_HS, SYNC_PHS, 
                   SYNC_DATA, SYNC_PDATA, SYNC_PID, SYNC_PPID, TOKEN_EOP, TOKEN_PID, TOKEN_Tx, WAIT_HUBSETUP_DATA, WAIT_HUBSETUP_HS, WAIT_HUBSETUP_PID);
signal ACTUAL_BYTES         : std_logic_vector(9 downto 0);
signal ATL_PENDING          : std_logic_vector(6 downto 0);
signal BABBLE               : std_logic;
signal BITCNT               : integer range 0 to 15;
signal BUFFER_BSY           : std_logic;
signal CRC_ERROR            : std_logic;
signal CRC16_HI             : boolean;
signal DATA_REQ_HI          : std_logic;
signal DATA_REQ_LO          : std_logic;
signal DELAY                : boolean;
signal HC_NSTATE            : HC_STATES; -- Next state.
signal HC_STATE             : HC_STATES;
signal HC_STOP              : std_logic;
signal MAX_PACKET_SIZE      : std_logic_vector(9 downto 0);
signal LOA                  : std_logic;
signal PACKET_BYTES         : std_logic_vector(9 downto 0);
signal PID                  : std_logic_vector(3 downto 0); -- Packet Identifier.
signal PTD_CNT              : std_logic_vector(2 downto 0);
signal PTD_HEADER           : PTD_HEADER_TYPE; -- This is the Philips Tranfer Descriptor Header.
signal Rx_HOLD_REG          : std_logic_vector(15 downto 0);
signal Rx_RDY               : std_logic;
signal Rx_STRB              : std_logic;
signal RxTx_SPEED           : std_logic;
signal SIE_NSTATE           : SIE_STATES;
signal SIE_STATE            : SIE_STATES;
signal SIE_RDY              : std_logic;
signal STUFF_CNT            : std_logic_vector(2 downto 0); -- Bit stuffing: counts '1's.
signal STUFF_ERR            : std_logic;
signal TOGGLE_MISMATCH      : boolean;
signal TOTAL_BYTES          : std_logic_vector(9 downto 0);
signal Tx_RDY               : std_logic;
signal Tx_STRB              : std_logic;
signal WRONG_EOP            : std_logic;

alias ACTIVE                : std_logic is PTD_HEADER(1)(3);
alias TOGGLE                : std_logic is PTD_HEADER(1)(2);
alias ENDPOINT_NUMBER       : std_logic_vector(3 downto 0) is PTD_HEADER(3)(7 downto 4);
alias LAST                  : std_logic is PTD_HEADER(3)(3);
alias SPEED                 : std_logic is PTD_HEADER(3)(2);
alias B5_5                  : std_logic is PTD_HEADER(5)(5);
alias DIRECTION_PID         : std_logic_vector(1 downto 0) is PTD_HEADER(5)(3 downto 2);
alias FORMAT                : std_logic is PTD_HEADER(6)(7); -- Isochronous = '1'.
alias FUNCTION_ADDRESS      : std_logic_vector(6 downto 0) is PTD_HEADER(6)(6 downto 0);
begin
    SIE_RDY <= '1' when SIE_STATE /= IDLE and SIE_NSTATE = IDLE else '0';

    HC_STATEREG: process
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if RESET  = '1' or SOFTWARE_RESET = '1' then
            HC_STATE <= USB_RESET;
        elsif HCR = '1' then
            HC_STATE <= USB_SUSPEND;
        else
            HC_STATE <= HC_NSTATE;
        end if;
    end process HC_STATEREG;

    HC_STATEDEC: process(ACTIVE, ATL_BUFF_FULL, ATL_PENDING, B5_5, DIRECTION_PID, FR, HC_STATE, HC_STOP, HCFS_IN, 
                         ITL0_BUFF_FULL, LAST, LST, BUFFER_RDY, SIE_RDY, SOF, ITL1_BUFF_FULL, PTD_CNT, DELAY, SPEED)
    begin
        case HC_STATE is
            when USB_RESET =>
                if HCFS_IN = "10" then
                    HC_NSTATE <= USB_OPERATIONAL;
                else
                    HC_NSTATE <= USB_RESET;
                end if;
            when USB_SUSPEND =>
                if HCFS_IN = "00" then
                    HC_NSTATE <= USB_RESET;
                elsif HCFS_IN = "01" then
                    HC_NSTATE <= USB_RESUME;
                elsif HCFS_IN = "10" then
                    HC_NSTATE <= USB_OPERATIONAL;
                else
                    HC_NSTATE <= USB_SUSPEND;
                end if;
            when USB_RESUME =>
                if HCFS_IN = "00" then
                    HC_NSTATE <= USB_RESET;
                elsif HCFS_IN = "10" then
                    HC_NSTATE <= USB_OPERATIONAL;
                else
                    HC_NSTATE <= USB_RESUME;
                end if;
            when USB_OPERATIONAL =>
                if HCFS_IN = "00" then
                    HC_NSTATE <= USB_RESET;
                elsif HCFS_IN = "11" then
                    HC_NSTATE <= USB_SUSPEND;
                elsif SOF = '1' then
                    HC_NSTATE <= TOKEN_SOF;
                else
                    HC_NSTATE <= USB_OPERATIONAL;
                end if;
            when TOKEN_SOF =>
                if SIE_RDY = '1' and ITL0_BUFF_FULL = '1' then
                    HC_NSTATE <= READ_ITL_PTD;
                elsif SIE_RDY = '1' and ITL1_BUFF_FULL = '1' then
                    HC_NSTATE <= READ_ITL_PTD;
                elsif SIE_RDY = '1' and ATL_BUFF_FULL = '1' then
                    HC_NSTATE <= READ_ATL_PTD;
                elsif SIE_RDY = '1' then
                    HC_NSTATE <= USB_OPERATIONAL;
                else
                    HC_NSTATE <= TOKEN_SOF;
                end if;
            when READ_ITL_PTD =>
                if PTD_CNT = "011" and BUFFER_RDY = '1' then
                    HC_NSTATE <= CHECK_ITL_PTD;
                else
                    HC_NSTATE <= READ_ITL_PTD;
                end if;
            when CHECK_ITL_PTD =>
                if ACTIVE = '0' and LAST = '1' and ATL_BUFF_FULL = '1' then
                    HC_NSTATE <= READ_ATL_PTD; -- Go on with ATL buffer.
                elsif ACTIVE = '0' and LAST = '1' then
                    HC_NSTATE <= USB_OPERATIONAL; -- Nothing to do.
                elsif ACTIVE = '0' then
                    HC_NSTATE <= READ_ITL_PTD; -- Next header.
                -- There are no isochronous low speed transfers in the USB
                -- specification.
                else
                    case DIRECTION_PID is
                        -- when "00" => -- No control tokens during ISO.
                        when "01" => HC_NSTATE <= TRANSMIT_ITL_DATA;
                        when "10" => HC_NSTATE <= RECEIVE_ITL_DATA;
                        when others => HC_NSTATE <= USB_OPERATIONAL; -- Reserved, never true or error.
                    end case;
                end if;
            when READ_ATL_PTD =>
                if PTD_CNT = "011" and BUFFER_RDY = '1' then
                    HC_NSTATE <= CHECK_ATL_PTD;
                else
                    HC_NSTATE <= READ_ATL_PTD;
                end if;
            when CHECK_ATL_PTD =>
                if HC_STOP = '1' then
                    HC_NSTATE <= USB_OPERATIONAL; -- Frametime!
                elsif LAST = '1' and ACTIVE = '0' and ATL_PENDING = "0000000" then
                    HC_NSTATE <= USB_OPERATIONAL; -- Nothing to do, go idle.
                elsif SPEED = '1' and FR < LST then -- Low speed device.
                    HC_NSTATE <= READ_ATL_PTD; -- Reject the access due to low speed threshold violation.
                elsif ACTIVE = '0' then
                    HC_NSTATE <= READ_ATL_PTD; -- Next header.
                else
                    case DIRECTION_PID is
                        when "00" => HC_NSTATE <= TRANSMIT_ATL_DATA; -- Control token.
                        when "01" => HC_NSTATE <= TRANSMIT_ATL_DATA;
                        when "10" => HC_NSTATE <= RECEIVE_ATL_DATA;
                        when others => HC_NSTATE <= USB_OPERATIONAL; -- Reserved, never true or error.
                    end case;
                end if;
            when TRANSMIT_ITL_DATA =>
                if SIE_RDY = '1' then
                    HC_NSTATE <= WRITE_ITL_PTD;
                else
                    HC_NSTATE <= TRANSMIT_ITL_DATA;
                end if;
            when TRANSMIT_ATL_DATA =>
                if SIE_RDY = '1' then
                    HC_NSTATE <= WRITE_ATL_PTD;
                else
                    HC_NSTATE <= TRANSMIT_ATL_DATA;
                end if;
            when RECEIVE_ITL_DATA =>
                if SIE_RDY = '1' then
                    HC_NSTATE <= WRITE_ITL_PTD;
                else
                    HC_NSTATE <= RECEIVE_ITL_DATA;
                end if;
            when RECEIVE_ATL_DATA =>
                if SIE_RDY = '1' then
                    HC_NSTATE <= WRITE_ATL_PTD;
                else
                    HC_NSTATE <= RECEIVE_ATL_DATA;
                end if;
            when WRITE_ITL_PTD =>
                if PTD_CNT = "100" and LAST = '1' and ATL_BUFF_FULL = '1' then
                    HC_NSTATE <= READ_ATL_PTD;
                elsif PTD_CNT = "100" and LAST = '1' then
                    HC_NSTATE <= USB_OPERATIONAL; -- Nothing to do.
                elsif PTD_CNT = "100" then
                    HC_NSTATE <= READ_ITL_PTD;
                else
                    HC_NSTATE <= WRITE_ITL_PTD;
                end if;
            when WRITE_ATL_PTD =>
                if PTD_CNT = "100" and HC_STOP = '1' then
                    HC_NSTATE <= USB_OPERATIONAL; -- Framtime!
                elsif PTD_CNT = "100" and B5_5 = '1' then
                    HC_NSTATE <= USB_OPERATIONAL; -- Only this transaction in 1ms frame.
                elsif PTD_CNT = "100" and LAST = '1' and ATL_PENDING = "0000000" then
                    HC_NSTATE <= USB_OPERATIONAL; -- Nothing to do, go idle.
                elsif PTD_CNT = "100" then -- Next transfer descriptor.
                    HC_NSTATE <= READ_ATL_PTD;
                else
                    HC_NSTATE <= WRITE_ATL_PTD;
                end if;
            end case;
    end process HC_STATEDEC;

    with HC_STATE select
        HCFS_OUT <= "00" when USB_RESET,
                    "01" when USB_RESUME,
                    "11" when USB_SUSPEND,
                    "10" when others;

    BUFFER_CONTROL: process
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if HC_STATE = USB_RESET or HC_STATE = USB_SUSPEND or HC_STATE = USB_RESUME then
            HC_ITL1 <= '0'; -- Host controller accesses ITL0.
        elsif ITL0_BUFF_FULL  = '1' and ITL1_BUFF_FULL  = '1' then
            HC_ITL1 <= '0'; -- Host controller accesses ITL0.
        elsif SOF = '1' then
            HC_ITL1 <= not HC_ITL1;
        end if;

        ITL1_BUFF_DONE <= '0'; -- Strobe;
        ITL0_BUFF_DONE <= '0'; -- Strobe;
        ATL_BUFF_DONE <= '0';  -- Strobe;

        if HC_STATE = WRITE_ITL_PTD and HC_NSTATE = USB_OPERATIONAL and HC_ITL1 = '1' then
            ITL1_BUFF_DONE <= '1';
        elsif HC_STATE = WRITE_ITL_PTD and HC_NSTATE = USB_OPERATIONAL then
            ITL0_BUFF_DONE <= '1';
        elsif HC_STATE = WRITE_ATL_PTD and HC_NSTATE = USB_OPERATIONAL then
            ATL_BUFF_DONE <= '1';
        end if;
    end process BUFFER_CONTROL;

    FIFO_DESCRIPTOR_CONTROL: process
    -- This logic controls the FIFO read and write signals for both,
    -- ITL and ATL. It also handles the PTD header related data such
    -- as the header data and the completion codes.
    variable ADR_VAR        : integer range 0 to 7;
    variable HC_ADRVAR      : std_logic_vector(11 downto 0);
    variable PTD_ENTRY      : std_logic_vector(11 downto 0);
    variable SCND_SCAN      : boolean;
    variable WRITE_LOCK     : boolean;
    variable CC_VAR         : std_logic_vector(3 downto 0);
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;

        ATL_RD <= '0'; -- Strobe.
        ATL_WR <= '0'; -- Strobe.
        ITL_RD <= '0'; -- Strobe.
        ITL_WR <= '0'; -- Strobe.

        -- Read/write controls:
        if HC_STATE /= READ_ATL_PTD and HC_NSTATE = READ_ATL_PTD then
            ATL_RD <= '1';
        elsif HC_STATE /= READ_ITL_PTD and HC_NSTATE = READ_ITL_PTD then
            ITL_RD <= '1';
        elsif HC_STATE = READ_ATL_PTD and HC_NSTATE = READ_ATL_PTD and BUFFER_RDY = '1' then
            ATL_RD <= '1';
        elsif HC_STATE = READ_ITL_PTD and HC_NSTATE = READ_ITL_PTD and BUFFER_RDY = '1' then
            ITL_RD <= '1';
        elsif HC_STATE /= TRANSMIT_ATL_DATA and HC_NSTATE = TRANSMIT_ATL_DATA then
            ATL_RD <= '1';
        elsif HC_STATE /= TRANSMIT_ITL_DATA and HC_NSTATE = TRANSMIT_ITL_DATA then
            ITL_RD <= '1';
        elsif HC_STATE = TRANSMIT_ATL_DATA and SIE_STATE = DATA_Tx and DATA_REQ_LO = '1' then
            ATL_RD <= '1';
        elsif HC_STATE = TRANSMIT_ITL_DATA and SIE_STATE = DATA_Tx and DATA_REQ_LO = '1' then
            ITL_RD <= '1';
        end if;

        if HC_STATE /= WRITE_ATL_PTD and HC_NSTATE = WRITE_ATL_PTD then
            ATL_WR <= '1';
        elsif HC_STATE = WRITE_ATL_PTD and HC_NSTATE = WRITE_ATL_PTD and BUFFER_RDY = '1' and PTD_CNT < "011" then
            ATL_WR <= '1';
        elsif HC_STATE /= WRITE_ITL_PTD and HC_NSTATE = WRITE_ITL_PTD then
            ITL_WR <= '1';
        elsif HC_STATE = WRITE_ITL_PTD and HC_NSTATE = WRITE_ITL_PTD and BUFFER_RDY = '1' and PTD_CNT < "011" then
            ITL_WR <= '1';
        elsif WRITE_LOCK = true then
            null; -- FIFO is full.
        elsif HC_STATE = RECEIVE_ATL_DATA and SIE_STATE = DATA_Rx and DATA_REQ_HI = '1' then
            ATL_WR <= '1';
        elsif HC_STATE = RECEIVE_ITL_DATA and SIE_STATE = DATA_Rx and DATA_REQ_HI = '1' then
            ITL_WR <= '1';
        end if;

        if SIE_STATE /= DATA_Rx and SIE_NSTATE = DATA_Rx then
            WRITE_LOCK := false;
        elsif ACTUAL_BYTES = TOTAL_BYTES and BUFFER_RDY = '1' then
            WRITE_LOCK := true;
        end if;

        if SIE_STATE /= DATA_Rx and SIE_STATE /= DATA_Tx then
            BUFFER_BSY <= '0';
        elsif BUFFER_RDY = '1' then
            BUFFER_BSY <= '0';
        elsif SIE_STATE = DATA_Tx and (ATL_RD = '1' or ITL_RD = '1') then
            BUFFER_BSY <= '1';
        elsif SIE_STATE = DATA_Rx and (ATL_WR = '1' or ITL_WR = '1') then
            BUFFER_BSY <= '1';
        end if;

        -- Address logic:
        if HC_STATE = USB_OPERATIONAL then
            HC_ADRVAR := x"000";
        elsif HC_STATE = CHECK_ITL_PTD and HC_NSTATE = READ_ITL_PTD then
            HC_ADRVAR := PTD_ENTRY + TOTAL_BYTES; -- Go to next header.
        elsif HC_STATE = CHECK_ITL_PTD and HC_NSTATE = READ_ATL_PTD then
            HC_ADRVAR := PTD_ENTRY + TOTAL_BYTES; -- Go to next header.
        elsif HC_STATE = CHECK_ATL_PTD and HC_NSTATE = READ_ATL_PTD and LAST = '1' then
            HC_ADRVAR := x"000"; -- Go to first header.
        elsif HC_STATE = CHECK_ATL_PTD and HC_NSTATE = READ_ATL_PTD then
            HC_ADRVAR := PTD_ENTRY + TOTAL_BYTES; -- Go to next header.
        elsif HC_STATE = WRITE_ITL_PTD and HC_NSTATE = READ_ITL_PTD then
            HC_ADRVAR := PTD_ENTRY + TOTAL_BYTES; -- Go to next header.
        elsif HC_STATE = WRITE_ITL_PTD and HC_NSTATE = READ_ATL_PTD then
            HC_ADRVAR := PTD_ENTRY + TOTAL_BYTES; -- Go to next header.
        elsif HC_STATE = WRITE_ATL_PTD and HC_NSTATE = READ_ATL_PTD and LAST = '1' then
            HC_ADRVAR := x"000"; -- Go to first header.
        elsif HC_STATE = WRITE_ATL_PTD and HC_NSTATE = READ_ATL_PTD then
            HC_ADRVAR := PTD_ENTRY + TOTAL_BYTES; -- Go to next header.
        -- The following is valid for TRANSMIT_ATL_DATA and for 
        -- RECEIVE_ATL_DATA. It adds the ACTUAL_BYTES value to the current
        -- FIFO address to get the correct address value in case of split transfers.
        elsif HC_STATE = CHECK_ATL_PTD and HC_NSTATE /= READ_ATL_PTD then
            HC_ADRVAR := HC_ADRVAR + (PTD_HEADER(1)(1 downto 0) & PTD_HEADER(0));
        elsif HC_STATE = READ_ATL_PTD and BUFFER_RDY = '1' then
            HC_ADRVAR := HC_ADRVAR + "10"; -- Word wide.
        elsif HC_STATE = READ_ITL_PTD and BUFFER_RDY = '1' then
            HC_ADRVAR := HC_ADRVAR + "10"; -- Word wide.
        elsif HC_STATE = RECEIVE_ATL_DATA and BUFFER_RDY = '1' then
            HC_ADRVAR := HC_ADRVAR + "10"; -- Word wide.
        elsif HC_STATE = TRANSMIT_ATL_DATA and DATA_REQ_LO = '1' then
            HC_ADRVAR := HC_ADRVAR + "10"; -- Word wide.
        elsif HC_STATE = RECEIVE_ITL_DATA and BUFFER_RDY = '1' then
            HC_ADRVAR := HC_ADRVAR + "10"; -- Word wide.
        elsif HC_STATE = TRANSMIT_ITL_DATA and DATA_REQ_LO = '1' then
            HC_ADRVAR := HC_ADRVAR + "10"; -- Word wide.
        end if;

        if HC_STATE /= READ_ATL_PTD and HC_NSTATE = READ_ATL_PTD then
            PTD_ENTRY := HC_ADRVAR; -- Store the entry point.
        elsif HC_STATE = WRITE_ATL_PTD and BUFFER_RDY = '1' then
            PTD_ENTRY := PTD_ENTRY + "10"; -- Word wide.
        elsif HC_STATE /= READ_ITL_PTD and HC_NSTATE = READ_ITL_PTD then
            PTD_ENTRY := HC_ADRVAR; -- Store the entry point.
        elsif HC_STATE = WRITE_ITL_PTD and BUFFER_RDY = '1' then
            PTD_ENTRY := PTD_ENTRY + "10"; -- Word wide.
        end if;

        case HC_STATE is
            when WRITE_ATL_PTD | WRITE_ITL_PTD => HC_ADR <= PTD_ENTRY;
            when others => HC_ADR <= HC_ADRVAR;
        end case;

        -- PTD header counter:
        if HC_STATE /= READ_ITL_PTD and HC_NSTATE = READ_ITL_PTD then
            PTD_CNT <= "000";
        elsif HC_STATE /= READ_ATL_PTD and HC_NSTATE = READ_ATL_PTD then
            PTD_CNT <= "000";
        elsif HC_STATE /= WRITE_ITL_PTD and HC_NSTATE = WRITE_ITL_PTD then
            PTD_CNT <= "000";
        elsif HC_STATE /= WRITE_ATL_PTD and HC_NSTATE = WRITE_ATL_PTD then
            PTD_CNT <= "000";
        elsif (HC_STATE = READ_ATL_PTD or HC_STATE = READ_ITL_PTD or HC_STATE = WRITE_ATL_PTD or HC_STATE = WRITE_ITL_PTD) and BUFFER_RDY = '1' then
            PTD_CNT <= PTD_CNT + '1';
        end if;

        -- PTD header data:
        ADR_VAR := To_Integer(unsigned(PTD_CNT));

        if HCR = '1' then
            PTD_HEADER <= (others => (others => '0'));
        elsif (HC_STATE = READ_ATL_PTD or HC_STATE = READ_ITL_PTD) and BUFFER_RDY = '1' then
            -- The buffer is written in little endian, so we meet
            -- the correct PTD header byte order.
            PTD_HEADER(2 * ADR_VAR) <= BUFFER_IN(7 downto 0);
            PTD_HEADER(2 * ADR_VAR + 1) <= BUFFER_IN(15 downto 8);
        end if;

        -- Total bytes:
        if SIE_STATE = HANDSHAKE_Tx and Tx_RDY = '1' then
            PTD_HEADER(0) <= ACTUAL_BYTES(7 downto 0);
            PTD_HEADER(1)(1 downto 0) <= ACTUAL_BYTES(9 downto 8);
        elsif SIE_STATE = HANDSHAKE_Rx and Rx_RDY = '1' and Rx_HOLD_REG(3 downto 0) = x"2" then -- Update only when ACK!
            PTD_HEADER(0) <= ACTUAL_BYTES(7 downto 0);
            PTD_HEADER(1)(1 downto 0) <= ACTUAL_BYTES(9 downto 8);
        end if;

        -- Completion code:
        if HC_STATE = CHECK_ATL_PTD and (HC_NSTATE = TRANSMIT_ATL_DATA or HC_NSTATE = RECEIVE_ATL_DATA) then
            PTD_HEADER(1)(7 downto 4) <= x"0"; -- Initialize.
            CC_VAR := PTD_HEADER(1)(7 downto 4); -- Store the initial value.
        elsif HC_STATE = CHECK_ITL_PTD and (HC_NSTATE = TRANSMIT_ITL_DATA or HC_NSTATE = Receive_ITL_DATA) then
            PTD_HEADER(1)(7 downto 4) <= x"0"; -- Initialize.
            CC_VAR := PTD_HEADER(1)(7 downto 4); -- Store the initial value.
        elsif CRC_ERROR = '1' then
            PTD_HEADER(1)(7 downto 4) <= x"1"; -- CRC.
        elsif STUFF_ERR = '1' then
            PTD_HEADER(1)(7 downto 4) <= x"2"; -- Bit stuffing.
        elsif LOA = '1' then -- Loss of activity.
            PTD_HEADER(1)(7 downto 4) <= x"5"; -- Device not responding.
        elsif SIE_STATE = DATA_PID_Rx and Rx_RDY = '1' and not Rx_HOLD_REG(7 downto 4) /= Rx_HOLD_REG(3 downto 0) then
            PTD_HEADER(1)(7 downto 4) <= x"6"; -- PID check failure.
        elsif SIE_STATE = DATA_PID_Rx and Rx_RDY = '1' and Rx_HOLD_REG(3 downto 0) = x"E" then
            PTD_HEADER(1)(7 downto 4) <= x"4"; -- Stall.
        elsif SIE_STATE = DATA_PID_Rx and Rx_RDY = '1' and Rx_HOLD_REG(3 downto 0) = x"A" and ACTUAL_BYTES = "0000000000" then
            PTD_HEADER(1)(7 downto 4) <= CC_VAR; -- NAK, restore the initial value (no access, no completion code).
        elsif HC_STATE = RECEIVE_ATL_DATA and SIE_STATE = DATA_PID_Rx and Rx_RDY = '1' and Rx_HOLD_REG(3 downto 0) /= x"B" and Rx_HOLD_REG(3 downto 0) /= x"3" and Rx_HOLD_REG(3 downto 0) /= x"A" then -- No valid PID.
            PTD_HEADER(1)(7 downto 4) <= x"7"; -- Unexpected PID.
        elsif HC_STATE = RECEIVE_ITL_DATA and SIE_STATE = DATA_PID_Rx and Rx_RDY = '1' and Rx_HOLD_REG(3 downto 0) /= x"3" then -- No valid ITL PID.
            PTD_HEADER(1)(7 downto 4) <= x"7"; -- Unexpected PID.
        elsif SIE_STATE = DATA_Rx and Rx_RDY = '1' and TOGGLE_MISMATCH = true then
            PTD_HEADER(1)(7 downto 4) <= x"3"; -- Data toggle mismatch (from endpoint).
        elsif SIE_STATE = HANDSHAKE_Rx and Rx_RDY = '1' and not Rx_HOLD_REG(7 downto 4) /= Rx_HOLD_REG(3 downto 0) then
            PTD_HEADER(1)(7 downto 4) <= x"6"; -- PID check failure.
        elsif SIE_STATE = HANDSHAKE_Rx and Rx_RDY = '1' and Rx_HOLD_REG(3 downto 0) = x"E" then
            PTD_HEADER(1)(7 downto 4) <= x"4"; -- Stall.
        elsif SIE_STATE = HANDSHAKE_Rx and Rx_RDY = '1' and Rx_HOLD_REG(3 downto 0) /= x"A" and Rx_HOLD_REG(3 downto 0) /= x"2" then -- No handshake PID.
            PTD_HEADER(1)(7 downto 4) <= x"7"; -- Unexpected PID.
        elsif HC_STATE = RECEIVE_ITL_DATA and HC_ITL1 = '0' and ITL_WR = '1' and BUFFER_BSY = '1' then
            PTD_HEADER(1)(7 downto 4) <= x"C"; -- Buffer overrun.
        elsif HC_STATE = RECEIVE_ITL_DATA and HC_ITL1 = '1' and ITL_WR = '1' and BUFFER_BSY = '1' then
            PTD_HEADER(1)(7 downto 4) <= x"C"; -- Buffer overrun.
        elsif HC_STATE = RECEIVE_ATL_DATA and ATL_WR = '1' and BUFFER_BSY = '1' then
            PTD_HEADER(1)(7 downto 4) <= x"C"; -- Buffer overrun.
        elsif HC_STATE = TRANSMIT_ITL_DATA and HC_ITL1 = '0' and ITL_RD = '1' and BUFFER_BSY = '1' then
            PTD_HEADER(1)(7 downto 4) <= x"D"; -- Buffer underrun.
        elsif HC_STATE = TRANSMIT_ITL_DATA and HC_ITL1 = '1' and ITL_RD = '1' and BUFFER_BSY = '1' then
            PTD_HEADER(1)(7 downto 4) <= x"D"; -- Buffer underrun.
        elsif HC_STATE = TRANSMIT_ATL_DATA and ATL_RD = '1' and BUFFER_BSY = '1' then
            PTD_HEADER(1)(7 downto 4) <= x"D"; -- Buffer underrun.
        elsif HC_STATE = RECEIVE_ATL_DATA and SIE_STATE = DATA_EOP and Rx_RDY = '1' and (PACKET_BYTES > MAX_PACKET_SIZE or ACTUAL_BYTES > TOTAL_BYTES) then
            PTD_HEADER(1)(7 downto 4) <= x"8"; -- Data overrun.
        elsif SIE_STATE = ITL_DELAY and (PACKET_BYTES > MAX_PACKET_SIZE or ACTUAL_BYTES > TOTAL_BYTES) then
            PTD_HEADER(1)(7 downto 4) <= x"8"; -- Data overrun.
        elsif HC_STATE = RECEIVE_ATL_DATA and SIE_STATE = HANDSHAKE_EOP and Tx_RDY = '1' and PACKET_BYTES < MAX_PACKET_SIZE and ACTUAL_BYTES < TOTAL_BYTES then
            PTD_HEADER(1)(7 downto 4) <= x"9"; -- Data underrun.
        elsif SIE_STATE = ITL_DELAY and PACKET_BYTES < MAX_PACKET_SIZE and ACTUAL_BYTES < TOTAL_BYTES then
            PTD_HEADER(1)(7 downto 4) <= x"9"; -- Data underrun.
        end if;

        -- This is the pending logic. The ATL_PENDING counter counts the active lists during the
        -- first list iteration. If the list is done, the counter is decremented by one. If there
        -- are pending lists after the last list, the host controller goes on with list processing.
        -- This logic is valid for ATL type lists.
        if SOF = '1' then
            ATL_PENDING <= "0000000";
            SCND_SCAN := false;
        elsif HC_STATE = CHECK_ATL_PTD and ACTIVE = '1' and SCND_SCAN = false then
            ATL_PENDING <= ATL_PENDING + '1'; -- Count the active lists during the first ATL list iteration.
        elsif HC_STATE = WRITE_ATL_PTD and HC_NSTATE /= WRITE_ATL_PTD and LAST = '1' then
            SCND_SCAN := true;
        end if;

        -- Active bit:
        if CRC_ERROR = '1' or LOA = '1' or WRONG_EOP = '1' or BABBLE = '1' then 
            ACTIVE <= '0'; -- Operational bus error.
            ATL_PENDING <= ATL_PENDING - '1';
        elsif SIE_STATE = HANDSHAKE_Rx and Rx_RDY = '1' and Rx_HOLD_REG(3 downto 0) /= x"2" then 
            ACTIVE <= '0'; -- NAK, Stall or invalid handshake, come again next frame.
            ATL_PENDING <= ATL_PENDING - '1';
        elsif SIE_STATE = DATA_PID_Rx and Rx_RDY = '1' and Rx_HOLD_REG(3 downto 0) = x"E" then 
            ACTIVE <= '0'; -- Stall, request not supported.
            if HC_STATE = RECEIVE_ATL_DATA then
                ATL_PENDING <= ATL_PENDING - '1';
            end if;
        elsif SIE_STATE = DATA_Rx and Rx_RDY = '1' and TOGGLE_MISMATCH = true then
            ACTIVE <= '0'; -- Done.
            ATL_PENDING <= ATL_PENDING - '1';
        elsif HC_STATE = RECEIVE_ATL_DATA and SIE_STATE = DATA_PID_Rx and Rx_RDY = '1' and Rx_HOLD_REG(3 downto 0) = x"A" then -- NAK.
            ACTIVE <= '0';
            ATL_PENDING <= ATL_PENDING - '1';
        elsif HC_STATE = RECEIVE_ATL_DATA and SIE_RDY = '1' and PACKET_BYTES < MAX_PACKET_SIZE then -- Device has no further data yet.
            ACTIVE <= '0';
            ATL_PENDING <= ATL_PENDING - '1';
        elsif HC_STATE /= WRITE_ATL_PTD and HC_NSTATE = WRITE_ATL_PTD and ACTUAL_BYTES >= TOTAL_BYTES then
            ACTIVE <= '0'; -- Done.
            ATL_PENDING <= ATL_PENDING - '1';
        elsif HC_STATE /= WRITE_ITL_PTD and HC_NSTATE = WRITE_ITL_PTD and ACTUAL_BYTES >= MAX_PACKET_SIZE then
            ACTIVE <= '0'; -- Done.
        end if;

        -- Toggle feature:
        -- This logic provides the toggle bit. During transmission of data the host controller 
        -- sends the toggle information in its PID. Every time a packet has been sent successfully,
        -- the toggle information gets updated. During reception of upstreaming data the PID
        -- determines the toggle information (wrong data PID -> no HANDSHAKE_Tx). So the TOGGLE is
        -- updated in the end of the HANDSHAKE_Tx state.
        -- For correct operation it is important to synchronize the receiver and the function toggle 
        -- bit at the start of a transaction (be aware that a device has several toggle bits for
        -- each of its function).
        if SIE_STATE = HANDSHAKE_Rx and Rx_RDY = '1' and Rx_HOLD_REG(7 downto 0) = x"D2" then -- Transmitter toggling.
            TOGGLE <= not TOGGLE;
        elsif SIE_STATE = DATA_PID_Rx and Rx_RDY = '1' and FORMAT = '0' and ACTUAL_BYTES = "000000000" and Rx_HOLD_REG(7 downto 0) = x"C3" then -- Synchronization.
            TOGGLE <= '1'; -- We initialize it with the invers value so that TOGGLE is synchronized after Handshake_Tx.
            TOGGLE_MISMATCH <= false;
        elsif SIE_STATE = DATA_PID_Rx and Rx_RDY = '1' and FORMAT = '0' and ACTUAL_BYTES = "000000000" and Rx_HOLD_REG(7 downto 0) = x"4B" then -- Synchronization.
            TOGGLE <= '0'; -- We initialize it with the invers value so that TOGGLE is synchronized after Handshake_Tx.
            TOGGLE_MISMATCH <= false;
        elsif SIE_STATE = DATA_PID_Rx and Rx_RDY = '1' and FORMAT = '0' and TOGGLE = '0' and Rx_HOLD_REG(7 downto 0) = x"C3" then
            TOGGLE_MISMATCH <= true;
        elsif SIE_STATE = DATA_PID_Rx and Rx_RDY = '1' and FORMAT = '0' and TOGGLE = '1' and Rx_HOLD_REG(7 downto 0) = x"4B" then
            TOGGLE_MISMATCH <= true;
        elsif SIE_STATE = HANDSHAKE_Tx and Tx_RDY = '1' then -- Receiver toggling.
            TOGGLE <= not TOGGLE;
        end if;
    end process FIFO_DESCRIPTOR_CONTROL;

    -- The lower byte of the access port register corresponds to the data byte at the even location of the buffer RAM, 
    -- and the upper byte corresponds to the next data byte at the odd location of the buffer RAM (little endian).
    BUFFER_OUT <= PTD_HEADER(1) & PTD_HEADER(0) when (HC_STATE = WRITE_ATL_PTD or HC_STATE = WRITE_ITL_PTD) and PTD_CNT = "000" else
                  PTD_HEADER(3) & PTD_HEADER(2) when (HC_STATE = WRITE_ATL_PTD or HC_STATE = WRITE_ITL_PTD) and PTD_CNT = "001" else
                  PTD_HEADER(5) & PTD_HEADER(4) when (HC_STATE = WRITE_ATL_PTD or HC_STATE = WRITE_ITL_PTD) and PTD_CNT = "010" else
                  PTD_HEADER(7) & PTD_HEADER(6) when (HC_STATE = WRITE_ATL_PTD or HC_STATE = WRITE_ITL_PTD) and PTD_CNT = "011" else Rx_HOLD_REG;

    STATUS: process
    -- This logic handles several system relevant signals.
    -- ACTUAL_BYTES is the integral number of bytes sent or received
    -- in the current frame.
    -- PACKET_BYTES is the number of bytes sent or received in the
    -- current transaction packet.
    variable ATL_INT_VAR    : std_logic;
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;

        if HC_STATE = CHECK_ITL_PTD or HC_STATE = CHECK_ATL_PTD then
            ACTUAL_BYTES <= PTD_HEADER(1)(1 downto 0) & PTD_HEADER(0);
            PACKET_BYTES <= (others => '0');
        elsif (SIE_STATE = DATA_Tx or SIE_STATE = DATA_Rx) and (DATA_REQ_HI = '1' or DATA_REQ_LO = '1') then
            ACTUAL_BYTES <= ACTUAL_BYTES + '1';
            PACKET_BYTES <= PACKET_BYTES + '1';
        elsif SIE_STATE = DATA_Rx and SIE_NSTATE /= DATA_Rx then
            -- This is the correction of the first half of 
            -- the CRC checksum we already counted. The
            -- second half we did not count due to the 
            -- postpone mechanism of DATA_REQ_HI.            
            ACTUAL_BYTES <= ACTUAL_BYTES - '1';
            PACKET_BYTES <= PACKET_BYTES - '1';
        end if;

        SO <= '0'; -- Strobe.

        if HC_STOP = '1' and HC_STATE = USB_OPERATIONAL and ATL_PENDING /= "0000000" then -- Scheduling overrun detected.
            SO <= '1';
        end if;

        ATL_INT <= '0'; -- ATL interrupt is a strobe;

        if HC_STATE /= WRITE_ATL_PTD and HC_NSTATE = WRITE_ATL_PTD then
            ATL_INT_VAR := '1';
        elsif HC_STATE /= USB_OPERATIONAL and HC_NSTATE = USB_OPERATIONAL then
            ATL_INT <= ATL_INT_VAR;
            ATL_INT_VAR := '0';
        end if;

        ITL_INT <= SOF;

        UE <= '0'; -- Unrecoverable error, not used currently.
        
        if HC_STATE = USB_SUSPEND and DP_IN = '0' and DM_IN = '1' then -- K detected.
            RD <= '1';
        else
            RD <= '0';
        end if;
    end process STATUS;

    MISC_CONTROLS: process
    -- This logic provides a counter and a flip flop.
    -- The counter is active when the serial interface engine is in one of the HUB setup states.
    -- In these states the delay is four full speed bit times.
    -- If the counter is active and provides an adequate delay between the end of the transfer
    -- list and its restart. The flip flop (HC_STOP) controls the correct timing in the end 
    -- of the time frame.
    variable FSMPS_CNT      : std_logic_vector(14 downto 0); -- Frame Space Maximum Packet Size.
    variable TIMER          : integer range 0 to 127;
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;

        if SIE_STATE /= WAIT_HUBSETUP_HS and SIE_STATE /= WAIT_HUBSETUP_DATA and SIE_STATE /= WAIT_HUBSETUP_PID then
            DELAY <= false;
            TIMER := 0;
        elsif (SIE_STATE = WAIT_HUBSETUP_HS or SIE_STATE = WAIT_HUBSETUP_DATA or SIE_STATE = WAIT_HUBSETUP_PID) and TIMER < 15 then
            TIMER := TIMER + 1;
        else
            DELAY <= true;
        end if;

        if HC_STATE = USB_OPERATIONAL or HC_STATE = USB_RESET or HC_STATE = USB_RESUME or HC_STATE = USB_SUSPEND then
            FSMPS_CNT := FSMPS; -- Initialize.
            HC_STOP <= '0';
        elsif FR_DEC = '1' and FSMPS_CNT /= "000000000000000" then
            FSMPS_CNT := FSMPS_CNT - '1';
        elsif FR_DEC = '1' then
            HC_STOP <= '1';
        end if;
    end process MISC_CONTROLS;

    -- Be aware: the PID is indicated early by SIE_NSTATE for correct shifter loading.
    PID <= "0101" when HC_STATE = TOKEN_SOF else -- Start of frame.
           "1100" when SIE_NSTATE = PREAMBLE_PID else -- Low speed preamble.
           "1100" when SIE_NSTATE = PREAMBLE_DATA else -- Low speed preamble.
           "1100" when SIE_NSTATE = PREAMBLE_HS else -- Low speed preamble.
           "0001" when SIE_NSTATE = TOKEN_PID and DIRECTION_PID = "01" else -- Token data out.
           "1001" when SIE_NSTATE = TOKEN_PID and DIRECTION_PID = "10" else -- Token data in.
           "1101" when SIE_NSTATE = TOKEN_PID else -- Token setup.
           "0011" when SIE_NSTATE = DATA_PID_Tx and FORMAT = '1' else -- Data0 for ISO data transfers.
           "0011" when SIE_NSTATE = DATA_PID_Tx and TOGGLE = '0' else -- Data0.
           "1011" when SIE_NSTATE = DATA_PID_Tx else -- Data1.
           "0010"; -- Default is the ACK handshake from host to function.

    MAX_PACKET_SIZE <= PTD_HEADER(3)(1 downto 0) & PTD_HEADER(2);
    TOTAL_BYTES <= PTD_HEADER(5)(1 downto 0) & PTD_HEADER(4);

    DATA_TIMING: process
    variable TIMER_Rx       : integer range 0 to 31;
    variable TIMER_Tx       : integer range 0 to 31;
    variable TIMER_DEC      : std_logic_vector(1 downto 0);
    variable REG            : std_logic;
    variable RCV_POSEDGE    : std_logic;
    variable RCV_STRB_EN    : boolean;
    begin
    wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if RESET  = '1' or SOFTWARE_RESET = '1' then
            RxTx_SPEED <= '0'; -- Default is full speed.
        elsif SIE_STATE = WAIT_HUBSETUP_PID and SIE_NSTATE /= WAIT_HUBSETUP_PID then
            RxTx_SPEED <= '1'; -- Switch to low speed.
        elsif SIE_STATE = WAIT_HUBSETUP_DATA and SIE_NSTATE /= WAIT_HUBSETUP_DATA then
            RxTx_SPEED <= '1'; -- Switch to low speed.
        elsif SIE_STATE = WAIT_HUBSETUP_HS and SIE_NSTATE /= WAIT_HUBSETUP_HS then
            RxTx_SPEED <= '1'; -- Switch to low speed.
        elsif SIE_STATE /= SYNC_PPID and SIE_NSTATE = SYNC_PPID then
            RxTx_SPEED <= '0'; -- Preamble is sent in full speed.
        elsif SIE_STATE /= SYNC_PDATA and SIE_NSTATE = SYNC_PDATA then
            RxTx_SPEED <= '0'; -- Preamble is sent in full speed.
        elsif SIE_STATE /= SYNC_PHS and SIE_NSTATE = SYNC_PHS then
            RxTx_SPEED <= '0'; -- Preamble is sent in full speed.
        elsif HC_STATE = TRANSMIT_ATL_DATA and SIE_RDY = '1' then
            RxTx_SPEED <= '0';
        elsif HC_STATE = RECEIVE_ATL_DATA and SIE_RDY = '1' then
            RxTx_SPEED <= '0';
        end if;

        -- Recever edge detector:
        RCV_POSEDGE := not REG and DP_IN;
        REG := DP_IN;

        -- Receive:
        if SIE_STATE /= HANDSHAKE_Rx and SIE_STATE /= DATA_PID_Rx and SIE_STATE /= DATA_Rx then
            TIMER_Rx := 0;
            Rx_STRB <= '0';
            RCV_STRB_EN := false;
        elsif RCV_STRB_EN = false and RCV_POSEDGE = '1' then
            RCV_STRB_EN := true;
        elsif RCV_STRB_EN = false then
            null; -- Do not release strobes before locking.
        elsif RxTx_SPEED = '0' then -- Full speed.
            if TIMER_Rx = 3 then
                TIMER_Rx := 0;
            else
                TIMER_Rx := TIMER_Rx + 1;
            end if;

            case TIMER_Rx is -- 12Mb/s.
                when 1 => Rx_STRB <= '1';
                when others => Rx_STRB <= '0';
            end case;
        elsif RxTx_SPEED = '1' then -- Lo speed.
            if TIMER_Rx = 31 then
                TIMER_Rx := 0;
            else
                TIMER_Rx := TIMER_Rx + 1;
            end if;

            case TIMER_Rx is -- 1.5Mb/s.
                when 15 => Rx_STRB <= '1';
                when others => Rx_STRB <= '0';
            end case;
        end if;

        -- Transmit:
        if RxTx_SPEED = '0' then -- Full speed.
            if TIMER_Tx = 3 then
                TIMER_Tx := 0;
            else
                TIMER_Tx := TIMER_Tx + 1;
            end if;

            case TIMER_Tx is -- 12Mb/s.
                when 3 => Tx_STRB <= '1';
                when others => Tx_STRB <= '0';
            end case;
        else
            if TIMER_Tx = 31 then
                TIMER_Tx := 0;
            else
                TIMER_Tx := TIMER_Tx + 1;
            end if;

            case TIMER_Tx is -- 1.5Mb/s.
                when 31 => Tx_STRB <= '1';
                when others => Tx_STRB <= '0';
            end case;
        end if;

        if HC_STATE = USB_RESET or HC_STATE = USB_RESUME or HC_STATE = USB_SUSPEND then
            FR_DEC <= '0';
            TIMER_DEC := "00";
        else
            TIMER_DEC := TIMER_DEC + '1';

            case TIMER_DEC is -- 12Mb/s.
                when "11" => FR_DEC <= '1';
                when others => FR_DEC <= '0';
            end case;
        end if;
    end process DATA_TIMING;

    SIE_STATEREG: process
    -- This is the serial interface engine (SIE)
    -- state machines register.
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if HC_STATE = USB_RESET or HC_STATE = USB_SUSPEND then
            SIE_STATE <= IDLE;
        elsif HCR = '1' then
            SIE_STATE <= IDLE;
        else
            SIE_STATE <= SIE_NSTATE;
        end if;
    end process SIE_STATEREG;

    SIE_STATEDEC: process(BABBLE, FORMAT, HC_STATE, Rx_RDY, Rx_HOLD_REG, DELAY, SIE_STATE, LOA, STUFF_ERR, TOGGLE_MISMATCH, Tx_RDY, Tx_STRB)
    -- This is the next state decoder of the serial interface engine (SIE)
    -- for the flow control of the four USB transactions (bulk, control,
    -- interrupt and isochronous).
    begin
        case SIE_STATE is
            when IDLE =>
                if Tx_STRB = '1' and HC_STATE = TOKEN_SOF then -- SOF is always at full speed.
                    SIE_NSTATE <= SYNC_PID;
                elsif Tx_STRB = '1' and (HC_STATE = TRANSMIT_ITL_DATA or HC_STATE = RECEIVE_ITL_DATA or HC_STATE = TRANSMIT_ATL_DATA or HC_STATE = RECEIVE_ATL_DATA) then
                    if SPEED = '1' then -- Low speed.
                        SIE_NSTATE <= SYNC_PPID;
                    else
                        SIE_NSTATE <= SYNC_PID;
                    end if;
                else
                    SIE_NSTATE <= IDLE;
                end if;
            when SYNC_PPID => -- Send Sync pattern.
                if Tx_RDY = '1' then
                    SIE_NSTATE <= PREAMBLE_PID;
                else
                    SIE_NSTATE <= SYNC_PPID;
                end if;
            when PREAMBLE_PID =>
                if Tx_RDY = '1' then
                    SIE_NSTATE <= WAIT_HUBSETUP_PID;
                else
                    SIE_NSTATE <= PREAMBLE_PID;
                end if;
            when WAIT_HUBSETUP_PID =>
                if DELAY = true then
                    SIE_NSTATE <= SYNC_PID;
                else
                    SIE_NSTATE <= WAIT_HUBSETUP_PID;
                end if;
            when SYNC_PID => -- Send Sync pattern.
                if Tx_RDY = '1' then
                    SIE_NSTATE <= TOKEN_PID;
                else
                    SIE_NSTATE <= SYNC_PID;
                end if;
            when TOKEN_PID =>
                if Tx_RDY = '1' then
                    SIE_NSTATE <= TOKEN_Tx;
                else
                    SIE_NSTATE <= TOKEN_PID;
                end if;
            when TOKEN_Tx =>
                if Tx_RDY = '1' then
                    SIE_NSTATE <= TOKEN_EOP;
                else
                    SIE_NSTATE <= TOKEN_Tx;
                end if;
            when TOKEN_EOP =>
                if Tx_RDY = '1' and HC_STATE = TOKEN_SOF then
                    SIE_NSTATE <= IDLE;
                elsif Tx_RDY = '1' and (HC_STATE = RECEIVE_ITL_DATA or HC_STATE = RECEIVE_ATL_DATA) then
                    SIE_NSTATE <= DATA_PID_Rx;
                elsif Tx_RDY = '1' and SPEED = '1' then -- Low speed.
                    SIE_NSTATE <= SYNC_PDATA;
                elsif Tx_RDY = '1' then
                    SIE_NSTATE <= SYNC_DATA;
                else
                    SIE_NSTATE <= TOKEN_EOP;
                end if;
            when SYNC_PDATA => -- Send Sync pattern.
                if Tx_RDY = '1' then
                    SIE_NSTATE <= PREAMBLE_DATA;
                else
                    SIE_NSTATE <= SYNC_PDATA;
                end if;
            when PREAMBLE_DATA =>
                if Tx_RDY = '1' then
                    SIE_NSTATE <= WAIT_HUBSETUP_DATA;
                else
                    SIE_NSTATE <= PREAMBLE_DATA;
                end if;
            when WAIT_HUBSETUP_DATA =>
                if DELAY = true then
                    SIE_NSTATE <= SYNC_DATA;
                else
                    SIE_NSTATE <= WAIT_HUBSETUP_DATA;
                end if;
            when SYNC_DATA =>
                if Tx_RDY = '1' then
                    SIE_NSTATE <= DATA_PID_Tx;
                else
                    SIE_NSTATE <= SYNC_DATA;
                end if;
            when DATA_PID_Tx =>
                if Tx_RDY = '1' then
                    SIE_NSTATE <= DATA_Tx;
                else
                    SIE_NSTATE <= DATA_PID_Tx;
                end if;
            when DATA_Tx =>
                if Tx_RDY = '1' then
                    SIE_NSTATE <= DATA_EOP;
                else
                    SIE_NSTATE <= DATA_Tx;
                end if;
            when DATA_EOP =>
                if Tx_RDY = '1' and HC_STATE = TRANSMIT_ITL_DATA then
                    SIE_NSTATE <= IDLE; -- ISO has no handshake.
                elsif Tx_RDY = '1' then
                    SIE_NSTATE <= HANDSHAKE_Rx;
                else
                    SIE_NSTATE <= DATA_EOP;
                end if;
            when HANDSHAKE_Rx =>
                if LOA = '1' or BABBLE = '1' then
                    SIE_NSTATE <= IDLE;
                elsif Rx_RDY = '1' then
                    SIE_NSTATE <= IDLE;
                else
                    SIE_NSTATE <= HANDSHAKE_Rx;
                end if;
            when DATA_PID_Rx =>
                if LOA = '1' or BABBLE = '1' then
                    SIE_NSTATE <= IDLE; -- Finish transaction.
                elsif Rx_RDY = '1' and STUFF_ERR = '1' then
                    SIE_NSTATE <= IDLE;
                elsif Rx_RDY = '1' and Rx_HOLD_REG(7 downto 0) = x"C3" then -- DATA0 PID.
                    SIE_NSTATE <= DATA_Rx;
                elsif Rx_RDY = '1' and Rx_HOLD_REG(7 downto 0) = x"4B" then -- DATA1 PID.
                    SIE_NSTATE <= DATA_Rx;
                elsif Rx_RDY = '1' then -- NAK, STALL.
                    SIE_NSTATE <= IDLE;
                else
                    SIE_NSTATE <= DATA_PID_Rx;
                end if;
            when DATA_Rx =>
                if LOA = '1' or BABBLE = '1' then
                    SIE_NSTATE <= IDLE; -- Finish transaction.
                elsif Rx_RDY = '1' and STUFF_ERR = '1' then
                    SIE_NSTATE <= IDLE;
                elsif Rx_RDY = '1' and HC_STATE = RECEIVE_ITL_DATA then
                    SIE_NSTATE <= ITL_DELAY;
                elsif Rx_RDY = '1' and TOGGLE_MISMATCH = true then
                    SIE_NSTATE <= IDLE;
                elsif Rx_RDY = '1' and SPEED = '1' then -- Low speed.
                    SIE_NSTATE <= SYNC_PHS;
                elsif Rx_RDY = '1' then
                    SIE_NSTATE <= SYNC_HS;
                else
                    SIE_NSTATE <= DATA_Rx;
                end if;
            when ITL_DELAY => -- ACTUAL_BYTES and PACKET_BYTES are valid here.
                SIE_NSTATE <= IDLE; -- ISO has no handshake.
            when SYNC_PHS => -- Send Sync pattern.
                if Tx_RDY = '1' then
                    SIE_NSTATE <= PREAMBLE_HS;
                else
                    SIE_NSTATE <= SYNC_PHS;
                end if;
            when PREAMBLE_HS =>
                if Tx_RDY = '1' then
                    SIE_NSTATE <= WAIT_HUBSETUP_HS;
                else
                    SIE_NSTATE <= PREAMBLE_HS;
                end if;
            when WAIT_HUBSETUP_HS =>
                if DELAY = true then
                    SIE_NSTATE <= SYNC_HS;
                else
                    SIE_NSTATE <= WAIT_HUBSETUP_HS;
                end if;
            when SYNC_HS => -- Send Sync pattern.
                if Tx_RDY = '1' then
                    SIE_NSTATE <= HANDSHAKE_Tx;
                else
                    SIE_NSTATE <= SYNC_HS;
                end if;
            when HANDSHAKE_Tx =>
                if Tx_RDY = '1' then
                    SIE_NSTATE <= HANDSHAKE_EOP;
                else
                    SIE_NSTATE <= HANDSHAKE_Tx;
                end if;
            when HANDSHAKE_EOP =>
                if Tx_RDY = '1' then
                    SIE_NSTATE <= IDLE;
                else
                    SIE_NSTATE <= HANDSHAKE_EOP;
                end if;
        end case;
    end process SIE_STATEDEC;

    NRZI_TRANSCEIVER: process
    -- This is the USB transceiver. The data is NRZI (Non Return to Zero Inverted)
    -- encoded and decoded. This transceiver features bit stuffing. The USB data is
    -- sent LSB first to the USB bus. The shift register is arranged accordingly.
    -- The transmission is controlled by the Tx_STRB strobe After each byte sent,
    -- the Rx_RDY strobe indicates the requirement for the next byte to be sent.
    -- After each byte received, the Rx_RDY strobe indicates valid received data.
    variable CRC_ERROR_VAR  : std_logic;
    variable CRC5           : std_logic_vector(5 downto 1);
    variable CRC16          : std_logic_vector(16 downto 1);
    variable CRC16_LO       : boolean;
    variable DATA_Rx_HI     : boolean;
    variable DATA_Rx_LO     : boolean;
    variable EOP_BIT        : integer range 0 to 3;
    variable NRZI_IN        : std_logic;
    variable NRZI_OUT       : std_logic;
    variable Rx_ACTIVE      : std_logic;
    variable SHIFTER        : std_logic_vector(7 downto 0);
    variable TIMEOUT_CNT    : std_logic_vector(4 downto 0);
    variable USB_D_IN       : std_logic;
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;

        CRC_ERROR <= '0'; -- Strobe.
        DATA_REQ_HI <= '0'; -- Strobe.
        DATA_REQ_LO <= '0'; -- Strobe.
        WRONG_EOP <= '0'; -- Strobe.
        BABBLE <= '0'; -- Strobe.
        LOA <= '0'; -- Strobe.
        OPBERR <= '0'; -- Strobe.
        Rx_RDY <= '0'; -- Strobe.

        -- Receiver data:
        if Rx_STRB = '1' and Rx_ACTIVE = '1' then
            USB_D_IN := NRZI_IN xnor DP_IN; -- NRZI-S decoding.
            NRZI_IN := DP_IN;
        end if;

         -- We scan the CRC error at byte boundaries not to run into 
         -- trouble right before the EOP-SE0 due to a possible dribble 
         -- bit. These extra bits must not falsify the CRC checker.
        if SIE_STATE /= DATA_Rx then
            CRC_ERROR_VAR := '0';
        elsif Rx_ACTIVE = '0' then
            null; -- Store.
        elsif Rx_STRB = '1' and (BITCNT = 0 or BITCNT = 8) then -- 8 is for an odd number of bytes.
            if CRC16 /= x"B001" then
                CRC_ERROR_VAR := '1';
            else
                CRC_ERROR_VAR := '0';
            end if;
        end if;

        -- This is the cyclic redundancy logic for CRC5 and CRC16 generation and validation. 
        -- The CRC is shifted right for USB implementation and will be inverted while loading
        -- into the shift register.
        -- Do not change the range in which this hardware is modeled. The CRC generation must 
        -- be placed prior to the SHIFTER assignment. The CRC5 generation must not be placed 
        -- beyond the SHIFTER assignment!
        if SIE_STATE = IDLE then
            CRC5 := "11111";
            CRC16 := x"FFFF";
        elsif STUFF_CNT = "110" then
            null; -- Wait one bit time.
        elsif SIE_STATE = TOKEN_Tx and Tx_STRB = '1' and BITCNT < 11 then
            -- The CRC5 polynomial is G(x) = x^5 + x^2 + 1.
            -- CRC5 := CRC5(4 downto 3) & (CRC5(2) xor CRC5(5) xor SHIFTER(0)) & CRC5(1) & (CRC5(5) xor SHIFTER(0)); -- Shift left.
            CRC5 := (CRC5(1) xor SHIFTER(0)) & CRC5(5) & (CRC5(4) xor CRC5(1) xor SHIFTER(0)) & CRC5(3 downto 2); -- Shift right.
        elsif SIE_STATE = DATA_Tx and Tx_STRB = '1' and CRC16_LO = false then
            -- The CRC16 polynomial is G(x) = x^16 + x^15 + x^2 + 1.
            -- CRC16 := (CRC16(15) xor CRC16(16) xor SHIFTER(0)) & CRC16(14 downto 3) & (CRC16(2) xor CRC16(16) xor SHIFTER(0)) & CRC16(1) & (CRC16(16) xor SHIFTER(0)); -- Shift left.
            CRC16 := (CRC16(1) xor SHIFTER(0)) & CRC16(16) & (CRC16(15) xor CRC16(1) xor SHIFTER(0)) & CRC16(14 downto 3) & (CRC16(2) xor CRC16(1) xor SHIFTER(0)); -- Shift right.
        elsif SIE_STATE = DATA_Rx and Rx_STRB = '1' and Rx_ACTIVE = '1' then
            -- The CRC16 polynomial is G(x) = x^16 + x^15 + x^2 + 1.
            -- CRC16 := (CRC16(15) xor CRC16(16) xor USB_D_IN) & CRC16(14 downto 3) & (CRC16(2) xor CRC16(16) xor USB_D_IN) & CRC16(1) & (CRC16(16) xor USB_D_IN); -- Shift left.
            CRC16 := (CRC16(1) xor USB_D_IN) & CRC16(16) & (CRC16(15) xor CRC16(1) xor USB_D_IN) & CRC16(14 downto 3) & (CRC16(2) xor CRC16(1) xor USB_D_IN); -- Shift right.
        end if;

        case SIE_STATE is
            when HANDSHAKE_Tx | DATA_PID_Tx | DATA_Tx | PREAMBLE_PID | PREAMBLE_DATA | PREAMBLE_HS | SYNC_HS | SYNC_PHS | SYNC_DATA | SYNC_PDATA | SYNC_PID | SYNC_PPID | TOKEN_PID | TOKEN_Tx =>
                if Tx_STRB = '1' then
                    if STUFF_CNT = "110" then
                        NRZI_OUT := not NRZI_OUT; -- Stuff a zero results in a change of NRZI data.
                    else
                        NRZI_OUT := NRZI_OUT xnor SHIFTER(0); -- NRZI-S encoding.
                    end if;
                end if;
            when others =>
                if Tx_STRB = '1' then
                    NRZI_OUT := '1'; -- IDLE.
                end if;
        end case;

        -- Transmitter bit stuffing:
        if SIE_STATE /= TOKEN_EOP and SIE_NSTATE = TOKEN_EOP then
            STUFF_CNT <= "000";
        elsif SIE_STATE /= DATA_EOP and SIE_NSTATE = DATA_EOP then
            STUFF_CNT <= "000";
        elsif SIE_STATE /= SYNC_HS and SIE_NSTATE = SYNC_HS then
            STUFF_CNT <= "000";
        elsif Tx_STRB = '1' and (SIE_STATE = SYNC_PID or SIE_STATE = TOKEN_PID or SIE_STATE = TOKEN_Tx or 
                                SIE_STATE = SYNC_DATA or SIE_STATE = DATA_PID_Tx or SIE_STATE = DATA_Tx or
                                SIE_STATE = SYNC_HS or SIE_STATE = HANDSHAKE_Tx) then
            if SHIFTER(0) = '1' and STUFF_CNT = "110" then
                STUFF_CNT <= "000";
            elsif SHIFTER(0) = '1' then
                STUFF_CNT <= STUFF_CNT + '1'; -- Count '1's.
            else
                STUFF_CNT <= "000";
            end if;
        -- Receiver bit stuffing:
        elsif SIE_STATE = IDLE then
            STUFF_ERR <= '0';
        elsif SIE_STATE /= HANDSHAKE_Rx and SIE_NSTATE = HANDSHAKE_Rx then
            STUFF_CNT <= "000";
        elsif SIE_STATE /= DATA_PID_Rx and SIE_NSTATE = DATA_PID_Rx then
            STUFF_CNT <= "000";
        elsif Rx_STRB = '0' or Rx_ACTIVE = '0' then
            null;
        elsif SIE_STATE = HANDSHAKE_Rx or SIE_STATE = DATA_PID_Rx or SIE_STATE = DATA_Rx then
            if STUFF_CNT = "110" and USB_D_IN = '1' then
                STUFF_ERR <= '1'; -- Bit stuffing error.
            elsif USB_D_IN = '1' then
                STUFF_CNT <= STUFF_CNT + '1'; -- Count '1's.
            else
                STUFF_CNT <= "000";
            end if;
        end if;

        -- Transmitter initialization:
        if SIE_STATE = IDLE and (SIE_NSTATE = SYNC_PID or SIE_NSTATE = SYNC_PPID) then
            SHIFTER := x"80"; -- This is the sync pattern.
            BITCNT <= 0;
        elsif SIE_STATE /= PREAMBLE_PID and SIE_NSTATE = PREAMBLE_PID then
            SHIFTER := not PID & PID;
        elsif SIE_STATE /= SYNC_PID and SIE_NSTATE = SYNC_PID then
            SHIFTER := x"80"; -- This is the sync pattern.
            BITCNT <= 0;
        elsif SIE_STATE /= TOKEN_PID and SIE_NSTATE = TOKEN_PID then
            SHIFTER := not PID & PID;
        elsif SIE_STATE /= TOKEN_Tx and SIE_NSTATE = TOKEN_Tx and PID = "0101" then -- Token start of frame.
            SHIFTER := FRAME_NUMBER(7 downto 0);
        elsif SIE_STATE /= TOKEN_Tx and SIE_NSTATE = TOKEN_Tx then -- Token: in out or setup.
            SHIFTER := ENDPOINT_NUMBER(0) & FUNCTION_ADDRESS;
        elsif SIE_STATE /= SYNC_PDATA and SIE_NSTATE = SYNC_PDATA then
            SHIFTER := x"80"; -- This is the sync pattern.
            BITCNT <= 0;
        elsif SIE_STATE /= PREAMBLE_DATA and SIE_NSTATE = PREAMBLE_DATA then
            SHIFTER := not PID & PID;
        elsif SIE_STATE /= SYNC_DATA and SIE_NSTATE = SYNC_DATA then
            SHIFTER := x"80"; -- This is the sync pattern.
            BITCNT <= 0;
        elsif SIE_STATE /= DATA_PID_Tx and SIE_NSTATE = DATA_PID_Tx then
            SHIFTER := not PID & PID;
        elsif SIE_STATE /= DATA_Tx and SIE_NSTATE = DATA_Tx and TOTAL_BYTES = "0000000000" then
            SHIFTER := not CRC16(8 downto 1);
            CRC16_HI <= false;
            CRC16_LO := true;
        elsif SIE_STATE /= DATA_Tx and SIE_NSTATE = DATA_Tx then
            -- Buffer is organized little endian.
            SHIFTER := BUFFER_IN(7 downto 0); -- This is the first byte to be sent.
            CRC16_HI <= false;
            CRC16_LO := false;
            DATA_REQ_HI <= '1'; -- First ACTUAL_BYTE.
        elsif SIE_STATE /= SYNC_PHS and SIE_NSTATE = SYNC_PHS then
            SHIFTER := x"80"; -- This is the sync pattern.
            BITCNT <= 0;
        elsif SIE_STATE /= PREAMBLE_HS and SIE_NSTATE = PREAMBLE_HS then
            SHIFTER := not PID & PID;
        elsif SIE_STATE /= SYNC_HS and SIE_NSTATE = SYNC_HS then
            SHIFTER := x"80"; -- This is the sync pattern.
            BITCNT <= 0;
        elsif SIE_STATE /= HANDSHAKE_Tx and SIE_NSTATE = HANDSHAKE_Tx then
            -- The host never issues NAK see USB1.1 specification 8.4.4
            SHIFTER := x"D2"; -- This is ACK.
        end if;

        case SIE_STATE is
            when  IDLE | HANDSHAKE_Rx | DATA_PID_Rx | DATA_Rx =>
                if HC_STATE = USB_SUSPEND and HC_NSTATE = USB_RESUME then
                    DP_OUT <= '0'; -- K-state: initiate the root hub resume sequence.
                    DM_OUT <= '1'; -- K-state: initiate the root hub resume sequence.
                else
                    DP_OUT <= '1'; -- Default is full speed J-State.
                    DM_OUT <= '0'; -- Default is full speed J-State.
                end if;
            when TOKEN_EOP | DATA_EOP | HANDSHAKE_EOP =>
                if Tx_STRB = '1' then
                    BITCNT <= BITCNT + 1;
                    case BITCNT is
                        when 0 | 1 => -- Send SE0.
                            DP_OUT <= '0';
                            DM_OUT <= '0';
                        when 2 => -- Send J (in full speed).
                            DP_OUT <= '1';
                            DM_OUT <= '0';
                        when others =>
                            BITCNT <= 0;
                    end case;
                end if;
            when others =>
                if Tx_STRB = '1' then
                    if STUFF_CNT = "110" and (SIE_STATE = TOKEN_Tx or SIE_STATE = DATA_Tx) then -- Stuff a zero after six detected data "ones".
                        null; -- Wait one bit time.
                    elsif (SIE_STATE = SYNC_HS or SIE_STATE = SYNC_PHS or SIE_STATE = SYNC_DATA or SIE_STATE = SYNC_PDATA or SIE_STATE = SYNC_PID or SIE_STATE = SYNC_PPID ) and BITCNT = 7 then
                        BITCNT <= 0;
                    elsif (SIE_STATE = PREAMBLE_PID or SIE_STATE = PREAMBLE_DATA or SIE_STATE = PREAMBLE_HS) and BITCNT = 7 then
                        BITCNT <= 0;
                    elsif (SIE_STATE = TOKEN_PID or SIE_STATE = DATA_PID_Tx) and BITCNT = 7 then
                        BITCNT <= 0;
                    elsif SIE_STATE = TOKEN_Tx and BITCNT = 7 then
                        case PID is
                            when "0101" => SHIFTER := "00000" & FRAME_NUMBER(10 downto 8); -- TOKEN_SOF.
                            when others => SHIFTER := "00000" & ENDPOINT_NUMBER(3 downto 1);
                        end case;
                        BITCNT <= BITCNT + 1;
                    elsif SIE_STATE = TOKEN_Tx and BITCNT = 10 then
                        SHIFTER := "000" & not CRC5;
                        BITCNT <= BITCNT + 1;
                    elsif SIE_STATE = TOKEN_Tx and BITCNT = 15 then
                        BITCNT <= 0;
                    elsif SIE_STATE = DATA_Tx and BITCNT = 7 then
                        if TOTAL_BYTES = "0000000000" then
                            SHIFTER := not CRC16(16 downto 9);
                            CRC16_HI <= true;
                        elsif CRC16_LO = true then
                            SHIFTER := not CRC16(16 downto 9);
                            CRC16_HI <= true;
                        elsif PACKET_BYTES = MAX_PACKET_SIZE or ACTUAL_BYTES = TOTAL_BYTES then
                            SHIFTER := not CRC16(8 downto 1);
                            CRC16_LO := true;
                        else
                            -- Buffer is organized little endian.
                            SHIFTER := BUFFER_IN(15 downto 8);
                            DATA_REQ_LO <= '1';
                        end if;

                        if CRC16_HI = true then
                            BITCNT <= 0; -- Ready.
                        else
                            BITCNT <= BITCNT + 1;
                        end if;
                    elsif SIE_STATE = DATA_Tx and BITCNT = 15 then
                        if CRC16_HI = true then
                            null; -- Ready!
                        elsif CRC16_LO = true then
                            SHIFTER := not CRC16(16 downto 9);
                            CRC16_HI <= true;
                        elsif PACKET_BYTES = MAX_PACKET_SIZE or ACTUAL_BYTES = TOTAL_BYTES then
                            SHIFTER := not CRC16(8 downto 1);
                            CRC16_LO := true;
                        else
                            -- Buffer is organized little endian.
                            SHIFTER := BUFFER_IN(7 downto 0);
                            DATA_REQ_HI <= '1';
                        end if;        
                        BITCNT <= 0;
                    elsif SIE_STATE = HANDSHAKE_Tx and BITCNT = 7 then
                        SHIFTER := '0' & SHIFTER(7 downto 1); -- Shift right.
                        BITCNT <= 0;
                    else
                        BITCNT <= BITCNT + 1;
                        SHIFTER := '0' & SHIFTER(7 downto 1); -- Shift right.
                    end if;

                    -- Be aware: the signaling between the host controller and the 
                    -- root hub uses always full speed conventions, even if the data 
                    -- rate is low speed. This is because the root hub is a full speed 
                    -- device. The low speed signaling from hub to low speed devices is 
                    -- inverted in the hub.
                    DP_OUT <= NRZI_OUT;
                    DM_OUT <= not NRZI_OUT;
                end if;
        end case;

        -- Receiver initialization:
        if SIE_STATE = IDLE then
            Rx_ACTIVE := '0'; -- Due to a break.
        elsif SIE_STATE /= HANDSHAKE_Rx and SIE_NSTATE = HANDSHAKE_Rx then
            BITCNT <= 0;
            SHIFTER := x"00"; -- Clear.
            Rx_ACTIVE := '0';        
            EOP_BIT := 0;
        elsif SIE_STATE /= DATA_PID_Rx and SIE_NSTATE = DATA_PID_Rx then
            BITCNT <= 0;
            SHIFTER := x"00"; -- Clear.
            Rx_ACTIVE := '0';
            EOP_BIT := 0;
        elsif SIE_STATE /= DATA_Rx and SIE_NSTATE = DATA_Rx then
            SHIFTER := x"00"; -- Clear.
            DATA_Rx_HI := false;
            DATA_Rx_LO := false;
        end if;

        -- Receieve:
        -- This logic controls the incoming data stream. The data is valid when
        -- the sync pattern has been detected and is valid until the EOP pattern
        -- is detected by this logic.
        if Rx_STRB = '0' then
            null;
        elsif (SIE_STATE = DATA_PID_Rx or SIE_STATE = HANDSHAKE_Rx) and Rx_ACTIVE = '0' then -- Search for SYNC pattern.
            -- Scan for two consecutive '0' to detect the SYNC pattern:
            if BITCNT = 0 and DP_IN = '0' and DM_IN = '1' then -- This is a full speed K.
                BITCNT <= BITCNT + 1;
            elsif BITCNT = 1 and DP_IN = '0' and DM_IN = '1' then -- This is a second full speed K.
                BITCNT <= 0;
                Rx_ACTIVE := '1'; -- Sync pattern detected.
            else
                BITCNT <= 0;
            end if;
        elsif DP_IN = '0' and DM_IN = '0' then -- SE0 detected.
            Rx_ACTIVE := '0';
        elsif Rx_ACTIVE = '0' then
            null; -- Receiver disabled.
        elsif STUFF_CNT = "110" and (SIE_STATE = DATA_Rx or SIE_STATE = HANDSHAKE_Rx) then
            null; -- Abandon the stuffed zero.
        elsif (SIE_STATE = DATA_PID_Rx or SIE_STATE = HANDSHAKE_Rx) and BITCNT = 7 then
            BITCNT <= 0;
            SHIFTER := USB_D_IN & SHIFTER(7 downto 1); -- LSB comes first.
            --
            Rx_HOLD_REG(7 downto 0) <= SHIFTER;
        elsif SIE_STATE = DATA_Rx and BITCNT = 7 then
            BITCNT <= BITCNT + 1;
            SHIFTER := USB_D_IN & SHIFTER(7 downto 1); -- LSB comes first.
            --
            Rx_HOLD_REG(7 downto 0) <= SHIFTER; -- Little endian.
            DATA_Rx_LO := true;
        elsif SIE_STATE = DATA_Rx and BITCNT = 15 then
            BITCNT <= 0;
            SHIFTER := USB_D_IN & SHIFTER(7 downto 1); -- LSB comes first.
            --
            Rx_HOLD_REG(15 downto 8) <= SHIFTER; -- Little endian.
            DATA_Rx_HI := true;
        else
            --
            BITCNT <= BITCNT + 1;
            SHIFTER := USB_D_IN & SHIFTER(7 downto 1); -- LSB comes first.
        end if;

        -- For DATA_Rx_HI: with this delay logic we postpone the writeback of the 
        -- Rx_HOLD_REG not to save back the CRC checksum in the end of the current 
        -- data packet.
        -- For DATA_Rx_LO: with this delay logic we postpone incrementing of 
        -- ACTUAL_BYTES not to count the CRC bytes twice in case of an odd number
        -- of received bytes.
        if STUFF_CNT = "110" then -- Postpone one bit time.
            null;
        elsif Rx_STRB = '1' and Rx_ACTIVE = '1' and DATA_Rx_HI = true and BITCNT = 1 then
            DATA_REQ_HI <= '1';
            DATA_Rx_HI := false;
        elsif Rx_STRB = '1' and Rx_ACTIVE = '1' and DATA_Rx_LO = true and BITCNT = 9 then
            DATA_REQ_LO <= '1';
            DATA_Rx_LO := false;
        end if;

        -- This logic controls the incoming data stream. The data is valid when
        -- the sync pattern has been detected and is valid until the EOP pattern
        -- is detected by this logic.
        if Rx_STRB = '1' and SIE_STATE = DATA_PID_Rx and BITCNT = 7 and STUFF_CNT /= "110" then
            Rx_RDY <= '1';
        elsif Rx_STRB = '1' and (SIE_STATE = DATA_Rx or SIE_STATE = HANDSHAKE_Rx) then
            if DP_IN = '0' and DM_IN = '0' and EOP_BIT = 0 then -- First SE0.
                EOP_BIT := 1;
            elsif (DP_IN xor DM_IN) = '1' and EOP_BIT = 1 then
                WRONG_EOP <= '1';
                OPBERR <= '1';
            elsif DP_IN = '0' and DM_IN = '0' and EOP_BIT = 1 then -- Second SE0.
                EOP_BIT := 2;
            elsif (DP_IN /= '1' or DM_IN /= '0') and EOP_BIT = 2 then
                WRONG_EOP <= '1';
                OPBERR <= '1';
            elsif DP_IN = '1' and DM_IN = '0' and EOP_BIT = 2 then -- Full speed J.
                Rx_RDY <= '1';
                CRC_ERROR <= CRC_ERROR_VAR; -- CRC_ERROR_VAR is active in DATA_Rx.
            end if;
        end if;

        if SOF = '1' and Rx_ACTIVE = '1' then
            BABBLE <= '1';
            OPBERR <= '1'; -- Babbling device.
        end if;

        -- Receiver timeout:
        -- We need Tx_STRB here because there is no Rx_STRB before any bus activity.
        -- This provides 32 full speed bit times timeout period. Refer to the "Universal 
        -- Serial Bus Specification Revision 1.1" paragrahp 7.1.19 where at least 18 full 
        -- speed bit times are required.
        if SIE_STATE /= DATA_PID_Rx and SIE_STATE /= DATA_Rx and SIE_STATE /= HANDSHAKE_Rx then
            TIMEOUT_CNT := "00000";
        elsif Rx_ACTIVE = '1' then
            TIMEOUT_CNT := "00000";
        elsif Tx_STRB = '1' and TIMEOUT_CNT < "11111" then
            TIMEOUT_CNT := TIMEOUT_CNT + '1';
        elsif Tx_STRB = '1' then -- 32 bit times.
            LOA <= '1';
        end if;
    end process NRZI_TRANSCEIVER;

    Tx_RDY <= '1' when Tx_STRB = '1' and (SIE_STATE = SYNC_HS or SIE_STATE = SYNC_PHS or SIE_STATE = SYNC_DATA or SIE_STATE = SYNC_PDATA or SIE_STATE = SYNC_PID or SIE_STATE = SYNC_PPID ) and BITCNT = 7 else
              '1' when Tx_STRB = '1' and (SIE_STATE = PREAMBLE_PID or SIE_STATE = PREAMBLE_DATA or SIE_STATE = PREAMBLE_HS) and BITCNT = 7 else
              '1' when Tx_STRB = '1' and (SIE_STATE = TOKEN_PID or SIE_STATE = DATA_PID_Tx or SIE_STATE = HANDSHAKE_Tx) and BITCNT = 7 and STUFF_CNT /= "110" else
              '1' when Tx_STRB = '1' and SIE_STATE = TOKEN_Tx and BITCNT = 15 and STUFF_CNT /= "110" else
              '1' when Tx_STRB = '1' and SIE_STATE = DATA_Tx and BITCNT = 7 and CRC16_HI = true and STUFF_CNT /= "110" else
              '1' when Tx_STRB = '1' and SIE_STATE = DATA_Tx and BITCNT = 15 and CRC16_HI = true and STUFF_CNT /= "110" else
              '1' when Tx_STRB = '1' and (SIE_STATE = TOKEN_EOP or SIE_STATE = DATA_EOP or SIE_STATE = HANDSHAKE_EOP) and BITCNT = 3 else '0';
end architecture BEHAVIOUR;
