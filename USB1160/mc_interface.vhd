------------------------------------------------------------------------
----                                                                ----
---- WF1160 IP Core                                                 ----
----                                                                ----
---- Description:                                                   ----
---- This model provides an embedded Universal Serial Bus host      ----
---- controller compatible to the Philips ISP1160.                  ----
----                                                                ----
---- This entity is the microprocessor interface section.           ----
----                                                                ----
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
---- This source Fle may be used and distributed without            ----
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
--   Minor changes.
-- Revision 2K24A  20240620 WF
--   Minor changes.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity MC_INTERFACE is
    generic(REVISION        : std_logic_vector(31 downto 0) := x"00000010"; -- Revision is 1.0
            ChipID          : std_logic_vector(15 downto 0) :=x"6122"); -- BD and BM.
    port (
        -- System controls:
        CLK_48MHz           : in std_logic;
        RESET               : in std_logic;

        -- MC interface signals:
        A0                  : in std_logic;
        CSn                 : in std_logic;
        RDn                 : in std_logic;
        WRn                 : in std_logic;
        DATA_IN             : in  std_logic_vector(15 downto 0);
        DATA_OUT            : out std_logic_vector(15 downto 0);
        DATA_EN             : out std_logic;

        NDP_SEL             : in std_logic; -- Number of data ports.

        HCFS_IN             : in std_logic_vector(1 downto 0); -- Host controller functional state.
        HCFS_OUT            : out std_logic_vector(1 downto 0); -- Host controller functional state.

        HCR                 : out std_logic; -- Host controller reset.
        SOFTWARE_RESET      : out std_logic;

        UE                  : in std_logic; -- Unrecoverable error.
        RD                  : in std_logic; -- Resume detected.
        SO                  : in std_logic; -- Scheduling overrun.
        SOF                 : out std_logic; -- Start of frame.
        FRAME_NUMBER        : out std_logic_vector(10 downto 0);

        FSMPS               : out std_logic_vector(14 downto 0); -- Frame Space Maximum Packet Size.
        FR                  : out std_logic_vector(13 downto 0); -- Frame interval.
        FR_DEC              : in std_logic; -- Decrement frame remaining.
        LST                 : out std_logic_vector(10 downto 0); -- LSThreshold.

        -- RhPortStatus port 1:
        CCS_1               : in std_logic; -- Current connect status.
        LSDA_1              : in std_logic; -- Low speed device attached.
        OPBERR_1            : in std_logic; -- Operational bus error.
        POCI_1              : in std_logic; -- Port overcurrent indicator.
        PESC_1              : in std_logic; -- Port enable status change.
        PRSC_1              : in std_logic; -- Port reset status change.
        PSSC_1              : in std_logic; -- Port suspend status change.
        PES_1               : out std_logic; -- Port enable status.
        PPS_1               : out std_logic; -- Port power switch.
        PRS_1               : out std_logic; -- Port reset status.

        -- RhPortStatus port 2:
        CCS_2               : in std_logic; -- Current connect status.
        LSDA_2              : in std_logic; -- Low speed device attached.
        OPBERR_2            : in std_logic; -- Operational bus error.
        POCI_2              : in std_logic; -- Port overcurrent indicator.
        PESC_2              : in std_logic; -- Port enable status change.
        PRSC_2              : in std_logic; -- Port reset status change.
        PSSC_2              : in std_logic; -- Port suspend status change.
        PES_2               : out std_logic; -- Port enable status.
        PPS_2               : out std_logic; -- Port power switch.
        PRS_2               : out std_logic; -- Port reset status.

        DP15K               : out std_logic; -- Downstream port 15K resistor select.
        CLKNS               : out std_logic; -- Suspend CLK not stop.
        AOCEN               : out std_logic; -- Analog OC enable.
        INT                 : out std_logic;

        DACKn               : in std_logic; -- DMA data acknowledge.
        DREQ                : out std_logic; -- DMA data request.
        EOT                 : in std_logic; -- End of DMA Transfer.

        -- Port Status and control:
        WAKEUP              : in std_logic; -- Wakeup from suspend.
        SUSPEND             : out std_logic; -- Suspend status.

        ATL_INT             : in std_logic; -- ATL data to be read.
        ITL_INT             : in std_logic; -- ATL data to be read.

        ITL_BUFF_LEN        : out std_logic_vector(11 downto 0); -- ITL buffer size.
        RD_ITL0_BUFF_LENGTH : in std_logic_vector(15 downto 0); -- Buffer data information.
        RD_ITL1_BUFF_LENGTH : in std_logic_vector(15 downto 0); -- Buffer data information.

        ATL_BUFF_DONE       : in std_logic; -- Buffer status information.
        ITL1_BUFF_DONE      : in std_logic; -- Buffer status information.
        ITL0_BUFF_DONE      : in std_logic; -- Buffer status information.

        ATL_BUFF_FULL       : out std_logic; -- Buffer status information.
        ITL1_BUFF_FULL      : out std_logic; -- Buffer status information.
        ITL0_BUFF_FULL      : out std_logic; -- Buffer status information.

        BUFFER_IN           : in std_logic_vector(15 downto 0);
        BUFFER_OUT          : out std_logic_vector(15 downto 0);
        ITL_RD              : out std_logic;
        ITL_WR              : out std_logic;
        ATL_RD              : out std_logic;
        ATL_WR              : out std_logic;
        HC_ITL1             : in std_logic
    );
end entity MC_INTERFACE;

architecture BEHAVIOUR of MC_INTERFACE is
type BUS_CYCLES is (IDLE, COMMAND, WRITE_LO, READ_LO, CYCLE_2, WRITE_HI, READ_HI);
type DMA_STATES is (IDLE, ATL_READ, ATL_WRITE, ITL_READ, ITL_WRITE);
signal BUS_CYCLE                : BUS_CYCLES;
signal NEXT_BUS_CYCLE           : BUS_CYCLES;
signal DATA_I                   : std_logic_vector(15 downto 0);
signal DMA_STATE                : DMA_STATES;
signal NEXT_DMA_STATE           : DMA_STATES;
signal ADDRESS                  : std_logic_vector(7 downto 0);
signal BufferStatus             : std_logic_vector(5 downto 0);
signal Control                  : std_logic_vector(31 downto 0);
signal CommandStatus            : std_logic_vector(31 downto 0);
signal DRWE                     : std_logic;
signal InterruptStatus          : std_logic_vector(31 downto 0);
signal InterruptEnable          : std_logic_vector(31 downto 0);
signal FmInterval               : std_logic_vector(31 downto 0);
signal FmRemaining              : std_logic_vector(31 downto 0);
signal FmNumber                 : std_logic_vector(15 downto 0);
signal FmNumber_MSB             : std_logic;
signal FIT                      : std_logic;
signal FNO                      : std_logic;
signal LSThreshold              : std_logic_vector(31 downto 0);
signal RhDescriptorA            : std_logic_vector(31 downto 0);
signal RhDescriptorB            : std_logic_vector(31 downto 0);
signal RhStatus                 : std_logic_vector(31 downto 0);
signal RhPortStatus_1           : std_logic_vector(31 downto 0);
signal RhPortStatus_2           : std_logic_vector(31 downto 0);
signal HardwareConfiguration    : std_logic_vector(15 downto 0);
signal DMAConfiguration         : std_logic_vector(15 downto 0);
signal TransferCounter          : std_logic_vector(15 downto 0);
signal uPInterrupt              : std_logic_vector(15 downto 0);
signal uPInterruptEnable        : std_logic_vector(15 downto 0);
signal Scratch                  : std_logic_vector(15 downto 0);
signal SoftwareReset            : std_logic;
signal ITLBufferLength          : std_logic_vector(15 downto 0);
signal ATLBufferLength          : std_logic_vector(15 downto 0);
signal DMA_BURSTLEN             : std_logic_vector(1 downto 0);
signal DMA_EN                   : std_logic;
signal IO_COUNT                 : std_logic_vector(15 downto 0);
signal DMA_CSEL                 : std_logic;
signal DMA_ITL_ATL              : std_logic;
signal DMA_RWSEL                : std_logic;
signal EOTIP                    : std_logic;
signal DRQOP                    : std_logic;
signal EOT_I                    : std_logic;
signal DACK_I                   : std_logic;
signal DREQ_I                   : std_logic;
signal DMA_ATL_RD               : std_logic;
signal DMA_ATL_WR               : std_logic;
signal DMA_ITL_RD               : std_logic;
signal DMA_ITL_WR               : std_logic;
signal BURSTCNT                 : std_logic_vector(3 downto 0);

signal CLK_RDY                  : std_logic;
signal INTOP                    : std_logic; -- Interrupt output polarity.
signal INTPT                    : std_logic; -- Interrupt pin trigger.
signal INTPE                    : std_logic; -- Interrupt pin enable.
signal INT_I                    : std_logic;
signal W32                      : boolean; -- Indicates 32 bit register access.
begin
    P_SYNC: process
    variable SETUP          : integer range 0 to 6249;
    variable HOLD           : integer range 0 to 5471999;
    -- This logic emulates the clock ready behaviour of the
    -- PLL located in the original isp160.
    -- The WAKEUP pin must be stable for 160us to release
    -- CLK_RDY. When in USB_SUSPEND wakeup goes low for 
    -- more than 1.14ms, then clock is switched off again.
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if HCFS_IN = "00" then -- Reset.
            SETUP := 0;
            HOLD := 0;
            CLK_RDY <= '1';
        elsif HCFS_IN /= "11" then -- Not supended.
            SETUP := 0;
            HOLD := 0;
            CLK_RDY <= '0';
        elsif BUS_CYCLE = IDLE and CSn = '0' then -- Software wake up.
            CLK_RDY <= '1';
        elsif DRWE = '1' and RhPortStatus_1(16) = '1' then -- Wake up by resume of USB device.
            CLK_RDY <= '1';
        elsif DRWE = '1' and RhPortStatus_2(16) = '1' then -- Wake up by resume of USB device.
            CLK_RDY <= '1';
        elsif WAKEUP = '0' and HOLD < 5471999 then
            SETUP := 0;
        elsif WAKEUP = '0' then
            CLK_RDY <= '0';
        elsif WAKEUP = '1' and SETUP < 6249 then -- 160us delay.
            SETUP := SETUP + 1;
            HOLD := 0;
        elsif WAKEUP = '1' then -- Wake up by pin.
            CLK_RDY <= '1';
        end if;
    end process P_SYNC;

    SUSPEND <= '1' when HCFS_IN = "11" else '0';

    STATE_REGs: process
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if RESET  = '1' then
            BUS_CYCLE <= IDLE;
            DMA_STATE <= IDLE;
        else
            BUS_CYCLE <= NEXT_BUS_CYCLE;
            DMA_STATE <= NEXT_DMA_STATE;
        end if;
    end process STATE_REGs;

    BUS_STATE_DEC: process(BUS_CYCLE, A0, CSn, RDn, W32, WRn)
    -- This is the MC bus interface logic. A command initiates a read or
    -- a write access. The access is valid as long as chip select is asserted
    -- along with either RDn or WRn. The access terminates exclusively by
    -- asserting CSn.
    begin
        case BUS_CYCLE is
            when IDLE =>
                if CSn = '0' and A0 = '1' and WRn = '0' then
                    NEXT_BUS_CYCLE <= COMMAND;
                elsif CSn = '0' and A0 = '0' and WRn = '0' then
                    NEXT_BUS_CYCLE <= WRITE_LO;
                elsif CSn = '0' and A0 = '0' and RDn = '0' then
                    NEXT_BUS_CYCLE <= READ_LO;
                else
                    NEXT_BUS_CYCLE <= IDLE;
                end if;
            when COMMAND =>
                if CSn = '1' then
                    NEXT_BUS_CYCLE <= IDLE;
                else
                    NEXT_BUS_CYCLE <= COMMAND;
                end if;
            when WRITE_LO =>
                if CSn = '1' and W32 = true then
                    NEXT_BUS_CYCLE <= CYCLE_2; -- 32 bit access.
                elsif CSn = '1' then
                    NEXT_BUS_CYCLE <= IDLE; -- 16 bit access.
                else
                    NEXT_BUS_CYCLE <= WRITE_LO;
                end if;
            when READ_LO =>
                if CSn = '1' and W32 = true then
                    NEXT_BUS_CYCLE <= CYCLE_2; -- 32 bit access.
                elsif CSn = '1' then
                    NEXT_BUS_CYCLE <= IDLE; -- 16 bit access.
                else
                    NEXT_BUS_CYCLE <= READ_LO;
                end if;
            when CYCLE_2 =>
                if CSn = '0' and A0 = '1' and WRn = '0' then
                    NEXT_BUS_CYCLE <= IDLE; -- Wrong sequence.
                elsif CSn = '0' and A0 = '0' and WRn = '0' then
                    NEXT_BUS_CYCLE <= WRITE_HI;
                elsif CSn = '0' and A0 = '0' and RDn = '0' then
                    NEXT_BUS_CYCLE <= READ_HI;
                else
                    NEXT_BUS_CYCLE <= CYCLE_2;
                end if;
            when WRITE_HI =>
                if CSn = '1' then
                    NEXT_BUS_CYCLE <= IDLE;
                else
                    NEXT_BUS_CYCLE <= WRITE_HI;
                end if;
            when READ_HI =>
                if CSn = '1' then
                    NEXT_BUS_CYCLE <= IDLE;
                else
                    NEXT_BUS_CYCLE <= READ_HI;
                end if;
        end case;
    end process BUS_STATE_DEC;

    DMA_STATE_DEC: process(DMA_STATE, DMA_EN, DMA_ITL_ATL, DMA_RWSEL, EOT_I, TransferCounter)
    begin
        case DMA_STATE is
            when IDLE =>
                if TransferCounter = x"0000" then
                    NEXT_DMA_STATE <= IDLE; -- Nothing to do.
                elsif DMA_EN = '1' and DMA_ITL_ATL = '1' and DMA_RWSEL = '0' then
                    NEXT_DMA_STATE <= ATL_READ;
                elsif DMA_EN = '1' and DMA_ITL_ATL = '1' then
                    NEXT_DMA_STATE <= ATL_WRITE;
                elsif DMA_EN = '1' and DMA_ITL_ATL = '0' and DMA_RWSEL = '0' then
                    NEXT_DMA_STATE <= ITL_READ;
                elsif DMA_EN = '1' and DMA_ITL_ATL = '0' then
                    NEXT_DMA_STATE <= ITL_WRITE;
                else
                    NEXT_DMA_STATE <= IDLE;
                end if;
            when ATL_READ =>
                if EOT_I = '1' then
                    NEXT_DMA_STATE <= IDLE;
                else
                    NEXT_DMA_STATE <= ATL_READ;
                end if;
            when ATL_WRITE =>
                if EOT_I = '1' then
                    NEXT_DMA_STATE <= IDLE;
                else
                    NEXT_DMA_STATE <= ATL_WRITE;
                end if;
            when ITL_READ =>
                if EOT_I = '1' then
                    NEXT_DMA_STATE <= IDLE;
                else
                    NEXT_DMA_STATE <= ITL_READ;
                end if;
            when ITL_WRITE =>
                if EOT_I = '1' then
                    NEXT_DMA_STATE <= IDLE;
                else
                    NEXT_DMA_STATE <= ITL_WRITE;
                end if;
        end case;
    end process DMA_STATE_DEC;

    DREQ <= DREQ_I when DRQOP = '1' else not DREQ_I;

    DACK_I <= not DACKn; -- Always active low.

    DREQ_I <= not DACK_I when DMA_STATE /= IDLE and DMA_BURSTLEN = "00" else
              '1' when DMA_STATE /= IDLE and DMA_BURSTLEN = "01" and BURSTCNT < x"4" else -- 4 cycle bursts.
              '1' when DMA_STATE /= IDLE and DMA_BURSTLEN = "10" and BURSTCNT < x"8" else -- 8 cycle bursts.
              not DACK_I when DMA_STATE /= IDLE and (DMA_BURSTLEN = "01" or DMA_BURSTLEN = "10") else '0';

    DMA: process
    variable LOCK       : boolean;
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;

        DMA_ATL_RD <= '0'; -- This signal is a strobe.
        DMA_ATL_WR <= '0'; -- This signal is a strobe.
        DMA_ITL_RD <= '0'; -- This signal is a strobe.
        DMA_ITL_WR <= '0'; -- This signal is a strobe.

        if DMA_STATE = IDLE then
            LOCK := false;
            BURSTCNT <= x"0";
        elsif DMA_STATE = ATL_READ or DMA_STATE = ITL_READ then
            if RDn = '1' and DMA_ITL_ATL = '1' and LOCK = false then
                DMA_ATL_RD <= '1';
                LOCK := true;
            elsif RDn = '1' and DMA_ITL_ATL = '0' and LOCK = false then
                DMA_ITL_RD <= '1';
                LOCK := true;
            elsif RDn = '0' and LOCK = true then
                if DMA_BURSTLEN = "01" and BURSTCNT = x"4" then -- 4 cycle bursts.
                    BURSTCNT <= x"1";
                elsif DMA_BURSTLEN = "10" and BURSTCNT = x"8" then -- 4 cycle bursts.
                    BURSTCNT <= x"1";
                else
                    BURSTCNT <= BURSTCNT + '1';
                end if;
                LOCK := false;
            end if;
        elsif DMA_STATE = ATL_WRITE or DMA_STATE = ITL_WRITE then
            if WRn = '0' and DMA_ITL_ATL = '1' and LOCK = false then
                DMA_ATL_WR <= '1';
                if DMA_BURSTLEN = "01" and BURSTCNT = x"4" then -- 4 cycle bursts.
                    BURSTCNT <= x"1";
                elsif DMA_BURSTLEN = "10" and BURSTCNT = x"8" then -- 4 cycle bursts.
                    BURSTCNT <= x"1";
                else
                    BURSTCNT <= BURSTCNT + '1';
                end if;
                LOCK := true;
            elsif WRn = '0' and DMA_ITL_ATL = '0' and LOCK = false then
                DMA_ITL_WR <= '1';
                if DMA_BURSTLEN = "01" and BURSTCNT = x"4" then -- 4 cycle bursts.
                    BURSTCNT <= x"1";
                elsif DMA_BURSTLEN = "10" and BURSTCNT = x"8" then -- 4 cycle bursts.
                    BURSTCNT <= x"1";
                else
                    BURSTCNT <= BURSTCNT + '1';
                end if;
                LOCK := true;
            elsif WRn = '1' then
                LOCK := false;
            end if;
        end if;
    end process DMA;

    EOT_I <= EOT when DMA_EN = '1' and DMA_CSEL = '0' and EOTIP = '1' else
             not EOT when DMA_EN = '1' and DMA_CSEL = '0' else
             -- The compare operator is >= to meet byte requirements (example: 9 bytes -> IO_COUNT = x"A").
             '1' when DMA_EN = '1' and DMA_CSEL = '1' and IO_COUNT >= TransferCounter else 
             '1' when DMA_EN = '0' and ADDRESS = x"40" and IO_COUNT >= TransferCounter else -- Read ITL buffer.
             '1' when DMA_EN = '0' and ADDRESS = x"C0" and IO_COUNT >= TransferCounter else -- Write ITL buffer.
             '1' when DMA_EN = '0' and ADDRESS = x"41" and IO_COUNT >= TransferCounter else -- Read ATL buffer.
             '1' when DMA_EN = '0' and ADDRESS = x"C1" and IO_COUNT >= TransferCounter else '0'; -- Write ATL buffer.
             
    COMMAND_DATA: process
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if RESET = '1' then
            ADDRESS <= x"FF"; -- This is a non existing command.
        elsif BUS_CYCLE = IDLE and NEXT_BUS_CYCLE = COMMAND then
            ADDRESS <= DATA_IN(7 downto 0);
        elsif BUS_CYCLE = IDLE and NEXT_BUS_CYCLE = WRITE_LO then
            DATA_I <= DATA_IN;
        elsif BUS_CYCLE = CYCLE_2 and NEXT_BUS_CYCLE = WRITE_HI then
            DATA_I <= DATA_IN;
        end if;

        -- The following is the logic for the determination of the amount of already transfered FIFO data.
        if EOT_I = '1' or RESET = '1' or SoftwareReset = '1' then -- Initialise after use.
            IO_COUNT <= x"0000";
        elsif DMA_EN = '1' and DMA_STATE = IDLE then
            IO_COUNT <= x"0000";
        elsif DMA_EN = '0' and BUS_CYCLE = COMMAND then
            IO_COUNT <= x"0000";
        elsif ADDRESS = x"40" and BUS_CYCLE = READ_LO and NEXT_BUS_CYCLE /= READ_LO then -- Read ITL in PIO mode.
            IO_COUNT <= IO_COUNT + "10"; -- Two bytes read.
        elsif ADDRESS = x"41" and BUS_CYCLE = READ_LO and NEXT_BUS_CYCLE /= READ_LO then -- Read ATL in PIO mode.
            IO_COUNT <= IO_COUNT + "10"; -- Two bytes read.
        elsif ADDRESS = x"C0" and BUS_CYCLE = WRITE_LO and NEXT_BUS_CYCLE /= WRITE_LO then -- Write ITL in PIO mode.
            IO_COUNT <= IO_COUNT + "10"; -- Two bytes written.
        elsif ADDRESS = x"C1" and BUS_CYCLE = WRITE_LO and NEXT_BUS_CYCLE /= WRITE_LO then -- Write ATL in PIO mode.
            IO_COUNT <= IO_COUNT + "10"; -- Two bytes written.
        elsif DMA_ATL_RD = '1' or DMA_ITL_RD = '1' then
            IO_COUNT <= IO_COUNT + "10"; -- Two bytes read.
        elsif DMA_ATL_WR = '1' or DMA_ITL_WR = '1' then
            IO_COUNT <= IO_COUNT + "10"; -- Two bytes written.
        end if;
    end process COMMAND_DATA;

    with ADDRESS select
        W32 <= true when x"00" | x"01" | x"02" | x"03" | x"04" | x"05" | x"0D" | x"0E" | x"0F" | x"11" | x"12" | x"13" | x"14" | x"15" | x"16", -- Read access.
               true when x"81" | x"82" | x"83" | x"84" | x"85" | x"8D" | x"91" | x"92" | x"93" | x"94" | x"95" | x"96", -- Write access.
               false when others;

    HCFS_OUT <= "01" when HCFS_IN = "11" and CSn = '0' else -- Software wake up.
                "01" when HCFS_IN = "11" and WAKEUP = '1' else -- Remote wake up.
                "01" when HCFS_IN = "11" and RD = '1' else -- Wake up by device.
                Control(7 downto 6);

    HCR <= CommandStatus(0) when BUS_CYCLE /= WRITE_LO else '0';
    SOFTWARE_RESET <= SoftwareReset;

    FNO <= '1' when FmNumber(15) /= FmNumber_MSB else '0';

    FIT <= FmInterval(31);
    FSMPS <= FmInterval(30 downto 16);
    FR <= FmRemaining(13 downto 0);
    LST <= LSThreshold(10 downto 0);

    DRWE <= RhStatus(15);

    PPS_1 <= RhPortStatus_1(8);
    PRS_1 <= RhPortStatus_1(4);
    PES_1 <= RhPortStatus_1(1);

    PPS_2 <= RhPortStatus_2(8);
    PRS_2 <= RhPortStatus_2(4);
    PES_2 <= RhPortStatus_2(1);

    DP15K <= HardwareConfiguration(12);
    CLKNS <= HardwareConfiguration(11);
    AOCEN <= HardwareConfiguration(10);
    --DACKM <= HardwareConfiguration(8);
    EOTIP <= HardwareConfiguration(7);
    --DACKIP <= HardwareConfiguration(6);
    DRQOP <= HardwareConfiguration(5);
    --DBWID <= HardwareConfiguration(4 downto 3);
    INTOP <= HardwareConfiguration(2);
    INTPT <= HardwareConfiguration(1);
    INTPE <= HardwareConfiguration(0);

    DMA_BURSTLEN <= DMAConfiguration(6 downto 5);
    DMA_EN <= DMAConfiguration(4);
    DMA_CSEL <= DMAConfiguration(2);
    DMA_ITL_ATL <= DMAConfiguration(1);
    DMA_RWSEL <= DMAConfiguration(0);

    ITL_BUFF_LEN <= ITLBufferLength(11 downto 0);
    --ATL_BUFF_LEN <= ATLBufferLength(11 downto 0); -- No need for this.

    FRAME_NUMBER <= FmNumber(10 downto 0);

    P_REGISTERS: process
    variable LOCK_SUSPEND   : boolean;
    variable OPR            : std_logic;
    variable SOF_VAR        : std_logic;
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;

        OPR := '0'; -- Strobe.
        SOF_VAR := '0'; -- Strobe.
        SOF <= '0'; -- Strobe.

        if RESET = '1' or SoftwareReset = '1' then
            BufferStatus          <= "000000";
            Control               <= x"00000000";
            CommandStatus         <= x"00000000";
            InterruptStatus       <= x"00000000";
            InterruptEnable       <= x"00000000";
            FmInterval            <= x"00002EDF";
            FmRemaining           <= x"00000000";
            FmNumber              <= x"0000";
            LSThreshold           <= x"00000628";
            RhDescriptorA         <= x"00000000";
            RhDescriptorB         <= x"00000000";
            RhStatus              <= x"00000000";
            RhPortStatus_1        <= x"00000000";
            RhPortStatus_2        <= x"00000000";
            HardwareConfiguration <= x"0028";
            DMAConfiguration      <= x"0000";
            TransferCounter       <= x"0000";
            uPInterrupt           <= x"0000";
            uPInterruptEnable     <= x"0000";
            Scratch               <= x"0000";
            ITLBufferLength       <= x"0000";
            ATLBufferLength       <= x"0000";
        end if;

        if ADDRESS = x"81" and BUS_CYCLE = WRITE_HI then
            Control(31 downto 16) <= DATA_I;
        elsif ADDRESS = x"81" and BUS_CYCLE = WRITE_LO then
            Control(15 downto 0) <= DATA_I;
        else
            if HCFS_IN = "11" and DRWE = '1' and RhPortStatus_1(16) = '1' then -- Resume by USB devices, go to USB_RESUME.
                Control(7 downto 6) <= "01";
            elsif HCFS_IN = "11" and DRWE = '1' and RhPortStatus_2(16) = '1' then -- Resume by USB devices, go to USB_RESUME.
                Control(7 downto 6) <= "01";
            end if;
        end if;

        if ADDRESS = x"82" and BUS_CYCLE = WRITE_HI then
            CommandStatus(31 downto 16) <= DATA_I;
        elsif ADDRESS = x"82" and BUS_CYCLE = WRITE_LO then
            CommandStatus(15 downto 0) <= DATA_I;
        else

        if HCFS_IN /= "10" then
            CommandStatus(17 downto 16) <= "00"; -- Clear SOC.
        elsif SO = '1' then
            CommandStatus(17 downto 16) <= CommandStatus(17 downto 16) + '1'; -- SOC.
        end if;

        if HCFS_IN  = "11" then -- Host controller is in USB_SUSPEND
                CommandStatus(0) <= '0';
            end if;
        end if;

        if ADDRESS = x"83" and BUS_CYCLE = WRITE_HI then
            for i in 15 downto 0 loop
                if DATA_I(i) = '1' then
                    InterruptStatus(i + 16) <= '0'; -- Clear respective bits.
                end if;
            end loop;
        elsif ADDRESS = x"83" and BUS_CYCLE = WRITE_LO then
            for i in 15 downto 0 loop
                if DATA_I(i) = '1' then
                    InterruptStatus(i) <= '0'; -- Clear respective bits.
                end if;
            end loop;
        else
            if FNO = '1' then -- Signal is a strobe;
                InterruptStatus(5) <= '1';
                if InterruptEnable(5) = '1' then
                    OPR := '1';
                end if;
            end if;

            if UE = '1' then -- Signal is a strobe;
                InterruptStatus(4) <= '1';
                if InterruptEnable(4) = '1' then
                    OPR := '1';
                end if;
            end if;

            if RD = '1' then -- Signal is a strobe.
                InterruptStatus(3) <= '1';
                if InterruptEnable(3) = '1' then
                    OPR := '1';
                end if;
            end if;

            if SOF_VAR = '1' then -- Signal is a strobe;
                InterruptStatus(2) <= '1';
                if InterruptEnable(2) = '1' then
                    OPR := '1';
                end if;
            end if;

            if SO = '1' then -- Signal is a strobe;
                InterruptStatus(0) <= '1';
                if InterruptEnable(0) = '1' then
                    OPR := '1';
                end if;
            end if;
        end if;

        if ADDRESS = x"84" and BUS_CYCLE = WRITE_HI then
            for i in 15 downto 0 loop
                if DATA_I(i) = '1' then
                    InterruptEnable(i + 16) <= '1';
                end if;
            end loop;
        elsif ADDRESS = x"84" and BUS_CYCLE = WRITE_LO then
            for i in 15 downto 0 loop
                if DATA_I(i) = '1' then
                    InterruptEnable(i) <= '1';
                end if;
            end loop;
        end if;

        if ADDRESS = x"85" and BUS_CYCLE = WRITE_HI then -- Interrupt disable.
            for i in 15 downto 0 loop
                if DATA_I(i) = '1' then
                    InterruptEnable(i + 16) <= '0';
                end if;
            end loop;
        elsif ADDRESS = x"85" and BUS_CYCLE = WRITE_LO then -- Interrupt disable.
            for i in 15 downto 0 loop
                if DATA_I(i) = '1' then
                    InterruptEnable(i) <= '0';
                end if;
            end loop;
        end if;

        if ADDRESS = x"8D" and BUS_CYCLE = WRITE_HI then
            FmInterval(31 downto 16) <= DATA_I;
        elsif ADDRESS = x"8D" and BUS_CYCLE = WRITE_LO then
            FmInterval(15 downto 0) <= DATA_I;
        end if;

        if HCFS_IN /= "10" and Control(7 downto 6) = "10" then -- Enter USB_OPERATIONAL.
            FmRemaining(31) <= FIT; -- This is FRT.
            FmRemaining(13 downto 0) <= FmInterval(13 downto 0); -- Reload frame interval.
            FmNumber <= (others => '0'); -- Frame number.
        elsif FR_DEC = '1' and FmRemaining(13 downto 0) = "00000000000000" then
            FmRemaining(31) <= FIT; -- This is FRT.
            FmRemaining(13 downto 0) <= FmInterval(13 downto 0); -- Reload frame interval.
            FmNumber <= FmNumber + '1'; -- Increment frame number.
            SOF_VAR := '1';
            SOF <= '1';
        elsif FR_DEC = '1' then
            FmRemaining(13 downto 0) <= FmRemaining(13 downto 0) - '1'; -- Decrease one bit time.
        end if;

        FmNumber_MSB <= FmNumber(15); -- See FNO.

        if ADDRESS = x"91" and BUS_CYCLE = WRITE_HI then
            LSThreshold(31 downto 16) <= DATA_I;
        elsif ADDRESS = x"91" and BUS_CYCLE = WRITE_LO then
            LSThreshold(15 downto 0) <= DATA_I;
        end if;

        if ADDRESS = x"92" and BUS_CYCLE = WRITE_HI then
            RhDescriptorA(31 downto 16) <= DATA_I; -- POTPGT, x"dd".
        elsif ADDRESS = x"92" and BUS_CYCLE = WRITE_LO then
            RhDescriptorA(12 downto 11) <= DATA_I(12 downto 11); -- NOCP, OCPM.
            RhDescriptorA(9 downto 8) <= DATA_I(9 downto 8); -- NPS, PSM.
        elsif NDP_SEL = '0' then
            RhDescriptorA(1 downto 0) <= "01"; -- NDP = 1
        else
            RhDescriptorA(1 downto 0) <= "10"; -- NDP = 2.
        end if;

        if ADDRESS = x"93" and BUS_CYCLE = WRITE_HI then
            RhDescriptorB(18 downto 16) <= DATA_I(2 downto 0); -- PPCM.
        elsif ADDRESS = x"93" and BUS_CYCLE = WRITE_LO then
            RhDescriptorB(2 downto 0) <= DATA_I(2 downto 0); -- DR.
        end if;

        if ADDRESS = x"94" and BUS_CYCLE = WRITE_HI and HCFS_IN = "10" then -- HCFS indicates USBOperational.
            if DATA_I(15) = '1' then
                RhStatus(15) <= '0'; -- Clear Device Remote Wakeup Enable (CRWE).
            end if;

            if DATA_I(1) = '1' then
                RhStatus(17) <= '0'; -- Clear OCIC.
            end if;

            if DATA_I (0) = '1' and RhDescriptorA(8) = '0' then
                if RhDescriptorB(17) = '0' then
                    RhPortStatus_1(8) <= '1'; -- Set port power status.
                end if;
                if RhDescriptorB(18) = '0' then
                    RhPortStatus_2(8) <= '1'; -- Set port power status.
                end if;
            end if;
        elsif ADDRESS = x"94" and BUS_CYCLE = WRITE_LO and HCFS_IN = "10" then -- HCFS indicates USBOperational.
            if DATA_I(15) = '1' then
                RhStatus(15) <= '1'; -- Set Device Remote Wakeup Enable (DRWE).
            end if;
            if DATA_I(0) = '1' and RhDescriptorA(8) = '0' then
                RhPortStatus_1(8) <= '0'; -- Clear port power status.
                RhPortStatus_2(8) <= '0'; -- Clear port power status.
            end if;
            if DATA_I(0) = '1' and RhDescriptorB(17) = '0' then -- Global power mode.
                RhPortStatus_1(8) <= '0'; -- Clear port power status.
            end if;
            if DATA_I(0) = '1' and RhDescriptorB(18) = '0' then -- Per port power mode.
                RhPortStatus_2(8) <= '0'; -- Clear port power status.
            end if;
        else
            if RhDescriptorA(12 downto 11) = "01" then -- OCPM is on per port basis.
                RhStatus(17) <= '0';
            elsif (POCI_1 or POCI_2) = '1' and RhStatus(1) = '0' then
                RhStatus(17) <= '1'; -- Set OCIC.
                InterruptStatus(6) <= '1'; -- RHSC.
                if InterruptEnable(6) = '1' then
                    OPR := '1';
                end if;
            end if;

            -- OCI is detected as long as the respective ports are enabled.
            if RhDescriptorA(12 downto 11) = "01" then -- OCPM is on per port basis.
                RhStatus(1) <= '0'; -- OCI always '0';
            else
                RhStatus(1) <= POCI_1 or POCI_2;
            end if;
        end if;

        if ADDRESS = x"95" and BUS_CYCLE = WRITE_HI and HCFS_IN = "10" then -- HCFS indicates USBOperational.
            RhPortStatus_1(31 downto 21) <= DATA_I(15 downto 5);

            if DATA_I(4) = '1' then
                RhPortStatus_1(20) <= '0'; -- Clear PRSC.
            end if;

            if DATA_I(3) = '1' then
                RhPortStatus_1(19) <= '0'; -- Clear OCIC.
            end if;

            if DATA_I(2) = '1' then
                RhPortStatus_1(18) <= '0'; -- Clear PSSC.
            end if;

            if DATA_I(1) = '1' then
                RhPortStatus_1(17) <= '0'; -- Clear PESC.
            end if;

            if DATA_I(0) = '1' then
                RhPortStatus_1(16) <= '0'; -- Clear CSC.
            end if;
        elsif ADDRESS = x"95" and BUS_CYCLE = WRITE_LO and HCFS_IN = "10" then -- HCFS indicates USBOperational.
            RhPortStatus_1(15 downto 10) <= DATA_I(15 downto 10);

            if DATA_I(9) = '1' and RhDescriptorA(8) = '1' then -- Individual power switching.
                RhPortStatus_1(8) <= '0'; -- Clear port power status.
            end if;

            if DATA_I(8) = '1' and RhDescriptorA(8) = '1' then -- Individual power switching.
                RhPortStatus_1(8) <= '1'; -- Set port power status.
            end if;

            RhPortStatus_1(7 downto 5) <= DATA_I(7 downto 5);

            if DATA_I(4) = '1' and RhPortStatus_1(0) = '1' then -- RhPortStatus(0) = CCS.
                RhPortStatus_1(4) <= '1'; -- Set PRS.
            elsif DATA_I(4) = '1' and RhPortStatus_1(0) = '0' then -- RhPortStatus(0) = CCS.
                RhPortStatus_1(16) <= '1'; -- Set CSC.
            end if;

            if DATA_I(3) = '1' and RhPortStatus_1(2) = '1' then
                RhPortStatus_1(2) <= '0'; -- Clear port suspend status.
                Control(7 downto 6) <= "01"; -- Initiate a resume.
            end if;

            if DATA_I(2) = '1' and RhPortStatus_1(0) = '1' then -- RhPortStatus(0) = CCS.
                RhPortStatus_1(2) <= '1'; -- Set PSS.
            elsif DATA_I(2) = '1' and RhPortStatus_1(0) = '0' and RhDescriptorB(1) = '0' then -- RhPortStatus(0) = CCS, RhDescriptorB(1) = DR.
                RhPortStatus_1(16) <= '1'; -- Set CSC.
            end if;

            if DATA_I(1) = '1' and RhPortStatus_1(0) = '1' and CCS_1 = '1' then -- RhPortStatus(0) = CCS.
                RhPortStatus_1(1) <= '1'; -- Set PES.
            elsif DATA_I(1) = '1' and RhPortStatus_1(0) = '0' and RhDescriptorB(1) = '0' then -- RhPortStatus(0) = CCS, RhDescriptorB(1) = DR.
                RhPortStatus_1(16) <= '1'; -- Set CSC.
            end if;

            if DATA_I(0) = '1' then
                RhPortStatus_1(1) <= '0'; -- Clear PES.
            end if;
        else
            if PRSC_1 = '1' then
                RhPortStatus_1(20) <= '1'; -- Set PRSC.
                InterruptStatus(6) <= '1'; -- RHSC.
                if InterruptEnable(6) = '1' then
                    OPR := '1';
                end if;
            end if;

            if RhDescriptorA(12 downto 11) = "01" and POCI_1 /= RhPortStatus_1(3) then -- OCPM is on per port basis.
                RhPortStatus_1(19) <= '1'; -- Set OCIC.
                InterruptStatus(6) <= '1'; -- RHSC.
                if InterruptEnable(6) = '1' then
                    OPR := '1';
                end if;
            end if;

            if PSSC_1 = '1' then
                RhPortStatus_1(18) <= '1'; -- Set PSSC.
                InterruptStatus(6) <= '1'; -- RHSC.
                if InterruptEnable(6) = '1' then
                    OPR := '1';
                end if;
            end if;

            if (RhPortStatus_1(0) xor CCS_1) = '1' then -- Connect or disconnect event.
                RhPortStatus_1(16) <= '1'; -- Set CSC.
                InterruptStatus(6) <= '1'; -- RHSC.
                if InterruptEnable(6) = '1' then
                    OPR := '1';
                end if;
            end if;

            RhPortStatus_1(9) <= LSDA_1;

            if RhDescriptorA(9) = '1' then -- Power switching not supported.
                RhPortStatus_1(8) <= '1'; -- Always hi.
            elsif POCI_1 = '1' then -- Overcurrent.
                RhPortStatus_1(8) <= '0'; -- Clear PPS.
            end if;

            if PRSC_1 = '1' then
                RhPortStatus_1(4) <= '0'; -- Clear PRS.
            end if;

            -- OCI is detected as long as the respective port is enabled.
            if RhDescriptorA(12 downto 11) = "01" then -- Overcurrent detection is per port basis.
                RhPortStatus_1(3) <= POCI_1; -- Port overcurrent indicator.
            else
                RhPortStatus_1(3) <= '0';
            end if;

            if PSSC_1 = '1' then -- End of resume interval.
                RhPortStatus_1(2) <= '0'; -- Clear PSS.
            elsif PRSC_1 = '1' then -- End of port reset.
                RhPortStatus_1(2) <= '0'; -- Clear PSS.
            elsif HCFS_IN = "01" then -- USB resume state.
                RhPortStatus_1(2) <= '0'; -- Clear PSS.
            end if;

            if PESC_1 = '1' then
                RhPortStatus_1(17) <= '1'; -- Set PESC.
            elsif POCI_1 = '1' then
                RhPortStatus_1(1) <= '0'; -- Overcurrent condition.
                RhPortStatus_1(17) <= '1'; -- Set PESC.
                InterruptStatus(6) <= '1'; -- RHSC.
                if InterruptEnable(6) = '1' then
                    OPR := '1';
                end if;
            elsif RhPortStatus_1(0) = '1' and CCS_1 = '0' then
                RhPortStatus_1(1) <= '0'; -- Disconnect event.
                RhPortStatus_1(17) <= '1'; -- Set PESC.
            elsif OPBERR_1 = '1' then
                RhPortStatus_1(1) <= '0'; -- Operational bus error.
                RhPortStatus_1(17) <= '1'; -- Set PESC.
                InterruptStatus(6) <= '1'; -- RHSC.
                if InterruptEnable(6) = '1' then
                    OPR := '1';
                end if;
            elsif RhPortStatus_1(8) = '0' then
                RhPortStatus_1(1) <= '0'; -- Switched off power.
            elsif PRSC_1 = '1' then
                RhPortStatus_1(1) <= '1'; -- Set PES by end of port reset when PRSC is set.
            elsif PSSC_1 = '1' then
                RhPortStatus_1(1) <= '1'; -- Set PES by end of resume when PSSC is set.
            end if;

            RhPortStatus_1(0) <= CCS_1; -- Current connect status.
        end if;

        if ADDRESS = x"96" and BUS_CYCLE = WRITE_HI and HCFS_IN = "10" then -- HCFS indicates USBOperational.
            RhPortStatus_2(31 downto 21) <= DATA_I(15 downto 5);

            if DATA_I(4) = '1' then
                RhPortStatus_2(20) <= '0'; -- Clear PRSC.
            end if;

            if DATA_I(3) = '1' then
                RhPortStatus_2(19) <= '0'; -- Clear OCIC.
            end if;

            if DATA_I(2) = '1' then
                RhPortStatus_2(18) <= '0'; -- Clear PSSC.
            end if;

            if DATA_I(1) = '1' then
                RhPortStatus_2(17) <= '0'; -- Clear PESC.
            end if;

            if DATA_I(0) = '1' then
                RhPortStatus_2(16) <= '0'; -- Clear CSC.
            end if;
        elsif ADDRESS = x"96" and BUS_CYCLE = WRITE_LO and HCFS_IN = "10" then -- HCFS indicates USBOperational.
            RhPortStatus_2(15 downto 10) <= DATA_I(15 downto 10);

            if DATA_I(9) = '1' and RhDescriptorA(8) = '1' then -- Individual power switching.
                RhPortStatus_2(8) <= '0'; -- Clear port power status.
            end if;

            if DATA_I(8) = '1' and RhDescriptorA(8) = '1' then -- Individual power switching.
                RhPortStatus_2(8) <= '1'; -- Set port power status.
            end if;

            RhPortStatus_2(7 downto 5) <= DATA_I(7 downto 5);

            if DATA_I(4) = '1' and RhPortStatus_2(0) = '1' then -- RhPortStatus(0) = CCS.
                RhPortStatus_2(4) <= '1'; -- Set PRS.
            elsif DATA_I(4) = '1' and RhPortStatus_2(0) = '0' then -- RhPortStatus(0) = CCS.
                RhPortStatus_2(16) <= '1'; -- Set CSC.
            end if;

            if DATA_I(3) = '1' and RhPortStatus_2(2) = '1' then
                RhPortStatus_2(2) <= '0'; -- Clear port suspend status.
                Control(7 downto 6) <= "01"; -- Initiate a resume.
            end if;

            if DATA_I(2) = '1' and RhPortStatus_2(0) = '1' then -- RhPortStatus(0) = CCS.
                RhPortStatus_2(2) <= '1'; -- Set PSS.
            elsif DATA_I(2) = '1' and RhPortStatus_2(0) = '0' and RhDescriptorB(2) = '0' then -- RhPortStatus(0) = CCS, RhDescriptorB(2) = DR.
                RhPortStatus_2(16) <= '1'; -- Set CSC.
            end if;

            if DATA_I(1) = '1' and RhPortStatus_2(0) = '1' and CCS_2 = '1' then -- RhPortStatus(0) = CCS.
                RhPortStatus_2(1) <= '1'; -- Set PES.
            elsif DATA_I(1) = '1' and RhPortStatus_2(0) = '0' and RhDescriptorB(2) = '0' then -- RhPortStatus(0) = CCS, RhDescriptorB(2) = DR.
                RhPortStatus_2(16) <= '1'; -- Set CSC.
            end if;

            if DATA_I(0) = '1' then
                RhPortStatus_2(1) <= '0'; -- Clear PES.
            end if;
        else
            if PRSC_2 = '1' then
                RhPortStatus_2(20) <= '1'; -- Set PRSC.
                InterruptStatus(6) <= '1'; -- RHSC.
                if InterruptEnable(6) = '1' then
                    OPR := '1';
                end if;
            end if;

            if RhDescriptorA(12 downto 11) = "01" and POCI_2 /= RhPortStatus_2(3) then -- OCPM is on per port basis.
                RhPortStatus_2(19) <= '1'; -- Set OCIC.
                InterruptStatus(6) <= '1'; -- RHSC.
                if InterruptEnable(6) = '1' then
                    OPR := '1';
                end if;
            end if;

            if PSSC_2 = '1' then
                RhPortStatus_2(18) <= '1'; -- Set PSSC.
                InterruptStatus(6) <= '1'; -- RHSC.
                if InterruptEnable(6) = '1' then
                    OPR := '1';
                end if;
            end if;

            if (RhPortStatus_2(0) xor CCS_2) = '1' then -- Connect or disconnect event.
                RhPortStatus_2(16) <= '1'; -- Set CSC.
                InterruptStatus(6) <= '1'; -- RHSC.
                if InterruptEnable(6) = '1' then
                    OPR := '1';
                end if;
            end if;
            
            RhPortStatus_2(9) <= LSDA_2;

            if RhDescriptorA(9) = '1' then -- Power switching not supported.
                RhPortStatus_2(8) <= '1'; -- Always hi.
            elsif POCI_2 = '1' then -- Overcurrent.
                RhPortStatus_2(8) <= '0'; -- Clear PPS.
            end if;

            if PRSC_2 = '1' then
                RhPortStatus_2(4) <= '0'; -- Clear PRS.
            end if;

            -- OCI is detected as long as the respective port is enabled.
            if RhDescriptorA(12 downto 11) = "01" then -- Overcurrent detection is per port basis.
                RhPortStatus_2(3) <= POCI_2; -- Port overcurrent indicator.
            else
                RhPortStatus_2(3) <= '0';
            end if;

            if PSSC_2 = '1' then -- End of resume interval.
                RhPortStatus_2(2) <= '0'; -- Clear PSS.
            elsif PRSC_2 = '1' then -- End of port reset.
                RhPortStatus_2(2) <= '0'; -- Clear PSS.
            elsif HCFS_IN = "01" then -- USB resume state.
                RhPortStatus_2(2) <= '0'; -- Clear PSS.
            end if;

            if PESC_2 = '1' then
                RhPortStatus_2(17) <= '1'; -- Set PESC.
            elsif POCI_2 = '1' then
                RhPortStatus_2(1) <= '0'; -- Overcurrent condition.
                RhPortStatus_2(17) <= '1'; -- Set PESC.
                InterruptStatus(6) <= '1'; -- RHSC.
                if InterruptEnable(6) = '1' then
                    OPR := '1';
                end if;
            elsif RhPortStatus_2(0) = '1' and CCS_2 = '0' then
                RhPortStatus_2(1) <= '0'; -- Disconnect event.
                RhPortStatus_2(17) <= '1'; -- Set PESC.
            elsif OPBERR_2 = '1' then
                RhPortStatus_2(1) <= '0'; -- Operational bus error.
                RhPortStatus_2(17) <= '1'; -- Set PESC.
                InterruptStatus(6) <= '1'; -- RHSC.
                if InterruptEnable(6) = '1' then
                    OPR := '1';
                end if;
            elsif RhPortStatus_2(8) = '0' then
                RhPortStatus_2(1) <= '0'; -- Switched off power.
            elsif PRSC_2 = '1' then
                RhPortStatus_2(1) <= '1'; -- Set PES by end of port reset when PRSC is set.
            elsif PSSC_2 = '1' then
                RhPortStatus_2(1) <= '1'; -- Set PES by end of resume when PSSC is set.
            end if;

            RhPortStatus_2(0) <= CCS_2; -- Current connect status.
        end if;

        if ADDRESS = x"A0" and BUS_CYCLE = WRITE_LO then
             HardwareConfiguration <= DATA_I;
        end if;

        if ADDRESS = x"A1" and BUS_CYCLE = WRITE_LO then
             DMAConfiguration <= DATA_I;
        else
            if EOT_I = '1' then
                DMAConfiguration(4) <= '0'; --Reset of the DMA_EN bit.
            end if;
        end if;

        if ADDRESS = x"A2" and BUS_CYCLE = WRITE_LO then
             TransferCounter <= DATA_I;
        end if;

        if ADDRESS = x"A4" and BUS_CYCLE = WRITE_LO then
            for i in 15 downto 0 loop
                if DATA_I(i) = '1' then
                    uPInterrupt(i) <= '0'; -- Reset respective bits.
                end if;
            end loop;
        else
            uPInterrupt(6) <= CLK_RDY;

             -- USB_SUSPEND is released when the host controller
             -- enters the USB_SUSPEND state.
            if HCFS_IN /= "11" then
                LOCK_SUSPEND := false;
            elsif HCFS_IN = "11" and LOCK_SUSPEND = false then
                uPInterrupt(5) <= '1';
                LOCK_SUSPEND := true;
            end if;

            if OPR = '1' and InterruptEnable(31) = '1' then -- OPR is a strobe.
                uPInterrupt(4) <= '1';
            end if;

            if EOT_I = '1' then -- AllEOT Interrupt.
                uPInterrupt(2) <= '1';
            end if;

            if ATL_INT = '1' then -- Signal is a strobe.
                uPInterrupt(1) <= '1';
            end if;

            if ITL_INT = '1' then -- SOFITLInt is a strobe.
                uPInterrupt(0) <= '1';
            end if;
        end if;

        if ADDRESS = x"A5" and BUS_CYCLE = WRITE_LO then
             uPInterruptEnable <= DATA_I;
        end if;

        if ADDRESS = x"A8" and BUS_CYCLE = WRITE_LO then
             Scratch <= DATA_I;
        end if;

        if ADDRESS = x"A9" and BUS_CYCLE = WRITE_LO and DATA_I = x"00F6" then
            SoftwareReset <= '1';
        else
            SoftwareReset <= '0';
        end if;

        if ADDRESS = x"AA" and BUS_CYCLE = WRITE_LO then
             ITLBufferLength <= DATA_I;
        end if;

        if ADDRESS = x"AB" and BUS_CYCLE = WRITE_LO then
             ATLBufferLength <= DATA_I;
        end if;

        -- ATL buffer done:
        if ATL_BUFF_DONE = '1' then
            BufferStatus(5) <= '1'; -- ATL buffer done by the host controller.
        elsif ADDRESS = x"41" and EOT_I = '1' then -- PIO mode read.
            BufferStatus(5) <= '0';
        elsif DMA_STATE = ATL_READ and NEXT_DMA_STATE = IDLE and DMA_ITL_ATL = '1' then -- DMA read access.
            BufferStatus(5) <= '0';
        end if;

        -- ITL1 buffer done:
        if ITL1_BUFF_DONE = '1' then
            BufferStatus(4) <= '1'; -- ITL1 buffer done.
        elsif ADDRESS = x"40" and EOT_I = '1' and HC_ITL1 = '1' then -- PIO mode read.
            BufferStatus(4) <= '0';
        elsif DMA_STATE = ITL_READ and NEXT_DMA_STATE = IDLE and DMA_ITL_ATL = '0' and HC_ITL1 = '1' then -- DMA read access.
            BufferStatus(4) <= '0';
        end if;

        -- ITL0 buffer done:
        if ITL0_BUFF_DONE = '1' then
            BufferStatus(3) <= '1'; -- ITL1 buffer done.
        elsif ADDRESS = x"40" and EOT_I = '1' and HC_ITL1 = '0' then -- PIO mode read.
            BufferStatus(3) <= '0';
        elsif DMA_STATE = ITL_READ and NEXT_DMA_STATE = IDLE and DMA_ITL_ATL = '0' and HC_ITL1 = '0' then -- DMA read access.
            BufferStatus(3) <= '0';
        end if;

        -- ATL buffer full/empty:
        if ADDRESS = x"C1" and EOT_I = '1' then -- PIO mode write.
            BufferStatus(2) <= '1'; -- ATL buffer full.
        elsif DMA_STATE = ATL_WRITE and NEXT_DMA_STATE = IDLE and DMA_ITL_ATL = '1' then -- DMA write access.
            BufferStatus(2) <= '1'; -- ATL buffer full.
        elsif ATL_BUFF_DONE = '1' then
            BufferStatus(2) <= '0'; -- ATL buffer empty.
        end if;

        -- ITL1 buffer full/empty:
        if ADDRESS = x"C0" and EOT_I = '1' and HC_ITL1 = '1' then -- PIO mode write.
            BufferStatus(1) <= '1'; -- ITL1 buffer full.
        elsif DMA_STATE = ITL_WRITE and NEXT_DMA_STATE = IDLE and DMA_ITL_ATL = '0' and HC_ITL1 = '0' then -- DMA write access.
            BufferStatus(1) <= '1'; -- ITL1 buffer full.
        elsif ITL1_BUFF_DONE = '1' then
            BufferStatus(1) <= '0'; -- ITL1 buffer empty.
        end if;

        -- ITL0 buffer full/empty:
        if ADDRESS = x"C0" and EOT_I = '1' and HC_ITL1 = '0' then -- PIO mode write.
            BufferStatus(0) <= '1'; -- ITL0 buffer full.
        elsif DMA_STATE = ITL_WRITE and NEXT_DMA_STATE = IDLE and DMA_ITL_ATL = '0' and HC_ITL1 = '0' then -- DMA write access.
            BufferStatus(0) <= '1'; -- ITL0 buffer full.
        elsif ITL0_BUFF_DONE = '1' then
            BufferStatus(0) <= '0'; -- ITL0 buffer empty.
        end if;
    end process P_REGISTERS;

    -- Be aware: all control signals are modelled as strobes.
    ITL_RD <= '1' when ADDRESS = x"40" and BUS_CYCLE /= READ_LO and NEXT_BUS_CYCLE = READ_LO else
              DMA_ITL_RD when DMA_STATE = ITL_READ else '0';

    ATL_RD <= '1' when ADDRESS = x"41" and BUS_CYCLE /= READ_LO and NEXT_BUS_CYCLE = READ_LO else
              DMA_ATL_RD when DMA_STATE = ATL_READ else '0';

    ITL_WR <= '1' when ADDRESS = x"C0" and BUS_CYCLE = WRITE_LO and NEXT_BUS_CYCLE /= WRITE_LO else
              DMA_ITL_WR when DMA_STATE = ITL_WRITE else '0';

    ATL_WR <= '1' when ADDRESS = x"C1" and BUS_CYCLE = WRITE_LO and NEXT_BUS_CYCLE /= WRITE_LO else
              DMA_ATL_WR when DMA_STATE = ATL_WRITE else '0';

    BUFFER_OUT <= DATA_I;

    ATL_BUFF_FULL <= BufferStatus(2);
    ITL1_BUFF_FULL <= BufferStatus(1);
    ITL0_BUFF_FULL <= BufferStatus(0);

    DATA_EN <= '1' when BUS_CYCLE = READ_HI or BUS_CYCLE = READ_LO else '0';

    DATA_OUT <= REVISION(31 downto 16) when ADDRESS = x"00" and BUS_CYCLE = READ_HI  else
                REVISION(15 downto 0) when ADDRESS = x"00" else
                Control(31 downto 16) when ADDRESS = x"01" and BUS_CYCLE = READ_HI else
                Control(15 downto 0) when ADDRESS = x"01" else
                CommandStatus(31 downto 16) when ADDRESS = x"02" and BUS_CYCLE = READ_HI else
                CommandStatus(15 downto 0) when ADDRESS = x"02" else
                InterruptStatus(31 downto 16) when ADDRESS = x"03" and BUS_CYCLE = READ_HI else
                InterruptStatus(15 downto 0) when ADDRESS = x"03" else
                InterruptEnable(31 downto 16) when ADDRESS = x"04" and BUS_CYCLE = READ_HI else
                InterruptEnable(15 downto 0) when ADDRESS = x"04" else
                InterruptEnable(31 downto 16) when ADDRESS = x"05" and BUS_CYCLE = READ_HI else
                InterruptEnable(15 downto 0) when ADDRESS = x"05" else
                FmInterval(31 downto 16) when ADDRESS = x"0D" and BUS_CYCLE = READ_HI else
                FmInterval(15 downto 0) when ADDRESS = x"0D" else
                FmRemaining(31 downto 16) when ADDRESS = x"0E" and BUS_CYCLE = READ_HI else
                FmRemaining(15 downto 0) when ADDRESS = x"0E" else
                x"0000" when ADDRESS = x"0F" and BUS_CYCLE = READ_HI else
                FmNumber when ADDRESS = x"0F" else
                LSThreshold(31 downto 16) when ADDRESS = x"11" and BUS_CYCLE = READ_HI else
                LSThreshold(15 downto 0) when ADDRESS = x"11" else
                RhDescriptorA(31 downto 16) when ADDRESS = x"12" and BUS_CYCLE = READ_HI else
                RhDescriptorA(15 downto 0) when ADDRESS = x"12" else
                RhDescriptorB(31 downto 16) when ADDRESS = x"13" and BUS_CYCLE = READ_HI else
                RhDescriptorB(15 downto 0) when ADDRESS = x"13" else
                '0' & RhStatus(30 downto 17) & '0' when ADDRESS = x"14" and BUS_CYCLE = READ_HI else
                RhStatus(15 downto 1) & '0' when ADDRESS = x"14" else
                RhPortStatus_1(31 downto 16) when ADDRESS = x"15" and BUS_CYCLE = READ_HI else
                RhPortStatus_1(15 downto 0) when ADDRESS = x"15" else
                RhPortStatus_2(31 downto 16) when ADDRESS = x"16" and BUS_CYCLE = READ_HI else
                RhPortStatus_2(15 downto 0) when ADDRESS = x"16" else
                HardwareConfiguration when ADDRESS = x"20" else
                DMAConfiguration when ADDRESS = x"21" else
                TransferCounter when ADDRESS = x"22" else
                uPInterrupt when ADDRESS = x"24" else
                uPInterruptEnable when ADDRESS = x"25" else
                ChipID when ADDRESS = x"27" else
                Scratch when ADDRESS = x"28" else
                ITLBufferLength when ADDRESS = x"2A" else
                ATLBufferLength when ADDRESS = x"2B" else
                "0000000000" & BufferStatus when ADDRESS = x"2C" else
                RD_ITL0_BUFF_LENGTH when ADDRESS = x"2D" else
                RD_ITL1_BUFF_LENGTH when ADDRESS = x"2E" else
                BUFFER_IN when ADDRESS = x"40" else
                BUFFER_IN when ADDRESS = x"41" else
                BUFFER_IN when DMA_STATE = ITL_READ else
                BUFFER_IN when DMA_STATE = ATL_READ else x"0000";

    INT_I <= '1' when (uPInterrupt(6 downto 4) and uPInterruptEnable(6 downto 4)) /= "000" else
             '1' when (uPInterrupt(2 downto 0) and uPInterruptEnable(2 downto 0)) /= "000" else '0';

    P_INT: process
    variable LOCK       : boolean;
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if RESET = '1' then
            LOCK := false;
            INT <= '0';
        elsif INTPE = '0' then
            null; -- Latch last value.
        elsif INTOP = '1' and INTPT = '0' then -- Active high level triggered.
            INT <= INT_I;
        elsif INTOP = '0' and INTPT = '0' then -- Active low level triggered.
            INT <= not INT_I;
        elsif INTOP = '1' and INTPT = '1' then -- Active high edge triggered.
            if INT_I = '1' and LOCK = false then
                INT <= '1';
                LOCK := true;
            elsif INT_I = '1' then
                INT <= '0';
            else
                INT <= '0';
                LOCK := false;
            end if;
        elsif INTOP = '0' and INTPT = '1' then -- Active low edge triggered.
            if INT_I = '1' and LOCK = false then
                INT <= '0';
                LOCK := true;
            elsif INT_I = '1' then
                INT <= '1';
            else
                INT <= '1';
                LOCK := false;
            end if;
        end if;
    end process P_INT;
end BEHAVIOUR;
