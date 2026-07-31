------------------------------------------------------------------------
----                                                                ----
---- ATARI DMA compatible IP Core                                   ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- ATARI ST and STE compatible DMA controller IP core.            ----
---- Remark 1): The DMA read from target operation starts if the    ----
----   FIFO is half filled. In case of the operation with a fast    ----
----   ACSI target device, the FIFO is written and read the same    ----
----   time resulting in unpredictable filling degree. In this      ----
----   case, the hard disk driver should take this into account.    ----
----   If not so and as of core version 2K24A there is a mechanism  ----
----   which operates DMA in packages of 16 bytes (8 words). So the ----
----   usual block transfers with a multiple of 16 bytes (256, 512, ----
----   1024...) are handled always correct.                         ----
----                                                                ----
---- This file contains the complete DMA control state machine      ----
---- which handles all DMA internal control signals for the FIFO,   ----
---- the registers and also for the port control signals.           ----
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
---- Copyright © 2006... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K6A  2006/06/03 WF
--   Initial Release.
-- Revision 2K6B  2006/11/06 WF
--   Modified Source to compile with the Xilinx ISE.
-- Revision 2K8A  2008/07/14 WF
-- Revision 2K8B  2008/12/24 WF
--   Introduced DMA_SRC_SEL as a bit vector.
--   Further (minor) changes.
-- Revision 2K9A  2009/06/20 WF
--   Process P_DATA_ENA has now synchronous reset to meet preset requirements.
--   Process FIFO_RD_CTRL has now synchronous reset to meet preset requirements.
-- Revision 2K9B  2009/12/24 WF
--   Archieved the old control file with entity / architecture WF25913IP_CTRL_V1.
--   Partially rewritten this section due to new wf25915ip_bus_arbiter resulting
--     in entity / architecture WF25913IP_CTRL_V2.
-- Revision 2K12B  20121224 WF
--   Removed some old stuff (package counter).
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
-- Revision 2K20A  20200620 WF
--   Minor changes to meet requirements for the new bus arbiter (GLUE) and memory control (MCU).
-- Revision 2K21A 20211224 WF
--   Improved FDCS_DMA_ACCn timing to meet 1772 with slow clock rates.
-- Revision 2K24A 20240620 WF
--   Implemented a mechanism to operate 16 byte packages (see PKG_16).
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF25913IP_CTRL is
    port (
        CLK             : in std_logic;
        RESETn          : in std_logic;

        FCSn            : in std_logic;
        RDY_INn         : in std_logic;
        DMA_EN          : in std_logic;

        CTRL_ACC        : in std_logic;

        DMA_RWn         : in std_logic;
        DMA_SRC_SEL     : in std_logic_vector(1 downto 0);
        HDRQ            : in std_logic;
        FDCRQ           : in std_logic;

        FIFO_FULL       : in std_logic;
        FIFO_HI         : in std_logic;
        FIFO_LOW        : in std_logic;
        FIFO_EMPTY      : in std_logic;

        CLRn            : out std_logic;

        FIFO_RD_ENA     : out std_logic;
        FIFO_WR_ENA     : out std_logic;

        DATA_EN         : out std_logic;

        CD_HIBUF_EN     : out std_logic;
        CD_RD_HIn       : out std_logic;
        CD_RD_LOWn      : out std_logic;

        ACSI_DATA_REQ   : out std_logic;
        SECTOR_CNT_EN   : out std_logic;

        FDCS_DMA_ACCn   : out std_logic;
        HD_ACKn         : out std_logic;
        RDY_OUTn        : out std_logic
    );
end entity WF25913IP_CTRL;

architecture BEHAVIOR of WF25913IP_CTRL is
type DMA_PHASES is (IDLE, READ, WRITE);
type ACSI_STATES is (IDLE_BYTE1, IDLE_BYTE2, IDLE_WR_HI, IDLE_WR_LOW, IDLE_RD_HI,
                     IDLE_RD_LOW, WRITE_HI, WRITE_LOW, READ_HI, READ_LOW);
signal DMA_PHASE        : DMA_PHASES;
signal ACSI_STATE       : ACSI_STATES;
signal ACSI_NEXT_STATE  : ACSI_STATES;
signal CLR_In           : std_logic;
signal HDRQ_I           : std_logic;
signal FDCRQ_I          : std_logic;
signal DATAREQ          : std_logic; -- Data request from the ACSI bus or Floppy disk.
signal FIFO_ACSI_RD     : std_logic;
signal FIFO_ACSI_WR     : std_logic;
signal FIFO_EMPTY_D     : std_logic;
signal FIFO_SYS_RD      : std_logic;
signal FIFO_SYS_WR      : std_logic;
signal PKG_16           : boolean;
signal WORDCNT_EN       : std_logic;
begin
    SYNC: process(CLK)
    -- The ACSI devices may work in their own clock domain. Therefore it is
    -- necessary to synchronize the incoming handshake signals to the DMA
    -- controller's clock domain. Otherwise there will result unpredictable
    -- behavior. Use the negative clock edge to provide proper operation
    -- of the fast DMA controller even with slow target devices.
    --
    -- We need FIFO_EMPTY_D to delay the RDY_OUTn signal and the DMA state
    -- to meet the timing requirements of the MCU state machine. The DMA
    -- operation ends in this way exactly in the end of the MCU DMA state.
    begin
        if CLK = '0' and CLK' event then
            HDRQ_I <= HDRQ;
        end if;
        --
        if CLK = '1' and CLK' event then
            FDCRQ_I <= FDCRQ;
            FIFO_EMPTY_D <= FIFO_EMPTY;
        end if;
    end process SYNC;

    CLRn <= CLR_In;

    DATAREQ <= FDCRQ_I when DMA_SRC_SEL = "10" else HDRQ_I;
    ACSI_DATA_REQ <= DATAREQ;

    with DMA_RWn select
        FIFO_RD_ENA <=  FIFO_ACSI_RD when '0', -- Write to target.
                        FIFO_SYS_RD when '1'; -- Read from target.

    with DMA_RWn select
        FIFO_WR_ENA <=  FIFO_SYS_WR when '0', -- Write to target.
                        FIFO_ACSI_WR when '1'; -- Read from target.

    CLEAR_DETECT: process(CLK, RESETn)
    -- This process detects any toggling of the DMA_RWn signal
    -- and releases a FIFO clear.
    variable LOCK   : boolean;
    begin
        -- Positive or negative edge detector.
        if RESETn = '0' then
            CLR_In <= '0';
            LOCK := false;
        elsif CLK = '1' and CLK' event then
            if DMA_RWn = '0' and LOCK = false then
                LOCK := true;
                CLR_In <= '0';
            elsif DMA_RWn = '1' and LOCK = true then
                LOCK := false;
                CLR_In <= '0';
            else
                CLR_In <= '1';
            end if;
        end if;
    end process CLEAR_DETECT;

    P_DMA_STATE: process(RESETn, CLK)
    begin
        if RESETn = '0' then -- DMA initialisation.
            DMA_PHASE <= IDLE; -- Initial IDLE condition.
        elsif CLK = '1' and CLK' event then
            if CLR_In = '0' then
                DMA_PHASE <= IDLE;
            else
                case DMA_PHASE is
                    when IDLE =>
                        -- Start in read from disk mode after the FIFO is half filled.
                        if DMA_EN = '1' and DMA_RWn = '1' and FIFO_LOW = '0' then
                            DMA_PHASE <= READ; -- For read from target.
                        -- Start in write to disk mode if the FIFO is less than half full.
                        elsif DMA_EN = '1' and DMA_RWn = '0' and FIFO_LOW = '1' and DATAREQ = '1' then
                            DMA_PHASE <= WRITE; -- For write to target.
                        else
                            DMA_PHASE <= IDLE;
                        end if;
                    when READ =>
                        if FIFO_EMPTY_D = '1' then
                            DMA_PHASE <= IDLE;
                        elsif PKG_16 = true and FIFO_LOW = '1' then
                            DMA_PHASE <= IDLE;
                        else
                            DMA_PHASE <= READ;
                        end if;
                    when WRITE =>
                        if FIFO_HI = '1' then
                            DMA_PHASE <= IDLE;
                        else
                            DMA_PHASE <= WRITE;
                        end if;
                end case;
            end if;
        end if;
    end process P_DMA_STATE;

    P_RDYOUT: process(CLK, RESETn, DMA_PHASE, FIFO_HI, FIFO_EMPTY_D, CTRL_ACC)
    -- The RDYn signal has two different functions. On the one hand, in non DMA mode it is the data
    -- acknowledge signal for the DMA register access. On the other hand, in DMA mode, it controls the
    -- DMA machine and interrupts the transfer when necessary.
    -- The timing of the RDY_OUTn must be correlated with the CTRL_MASK timing in the register file!
    variable TMP            : std_logic_vector(1 downto 0);
    begin
        if RESETn = '0' then
            TMP := "00";
        elsif CLK = '1' and CLK' event then
            if FCSn = '0' then
                if TMP < "11" then
                    TMP := TMP + '1';
                end if;
            else
                TMP := "00";
            end if;
        end if;
        --
        -- Be aware that these signals are asserted immediately and not on the rising clock edge.
        if DMA_PHASE = IDLE and TMP < "01" and CTRL_ACC = '0' then -- DMA register access and DMA read timing.
            RDY_OUTn <= '0'; -- Active hi for register access timing, active low for DMA read.
        elsif DMA_PHASE = IDLE and TMP < "11" and CTRL_ACC = '1' then -- Controller access timing.
            RDY_OUTn <= '0'; -- Active hi.
        elsif DMA_PHASE = READ and FIFO_EMPTY_D = '1' then
            RDY_OUTn <= '0';
        elsif DMA_PHASE = WRITE and FIFO_HI = '1' then
            RDY_OUTn <= '0';
        else
            RDY_OUTn <= '1';
        end if;
    end process P_RDYOUT;

    WORDCNT_EN <=   '1' when FIFO_SYS_RD = '1' else
                    '1' when FIFO_SYS_WR = '1' else '0';

    WORD_CNT: process (CLK, WORDCNT_EN)
    -- This process counts the transferred double-bytes. The counter
    -- releases the SECTOR_CNT_EN when it counts 256 words (512 bytes).
    variable WORDCNT : std_logic_vector (7 downto 0);
    begin
        if CLK = '1' and CLK' event then
            if CLR_In = '0' then -- During DMA initialisation ...
                WORDCNT := (others => '0');
            elsif WORDCNT_EN = '1' then
                WORDCNT := WORDCNT + '1';
            end if;
        end if;
        --
        if WORDCNT(2 downto 0) = "000" then
            PKG_16 <= true;
        else
           PKG_16 <= false;
        end if;
        --
        if WORDCNT = x"FF" and WORDCNT_EN = '1' then
            SECTOR_CNT_EN <= '1';
        else
            SECTOR_CNT_EN <= '0';
        end if;
    end process WORD_CNT;

  FIFO_RD_CTRL: process
  -- This is the read control logic. While reading from a target
  -- this logic controls the FIFO read access. Due to the FIFO's
  -- output is registered, there must be a first read access for
  -- valid data on the data bus.
    variable LOCK : boolean;
  begin
      wait until CLK = '1' and CLK' event;
      if RESETn = '0' then
          DATA_EN <= '0';
          FIFO_SYS_RD <= '0';
          LOCK := false;
      elsif DMA_PHASE = READ and RDY_INn = '1' then
          FIFO_SYS_RD <= '0';
          LOCK := false;
      elsif DMA_PHASE = READ and RDY_INn = '0' and LOCK = false then
          DATA_EN <= '1'; -- Activate the data bus.
          FIFO_SYS_RD <= '1'; -- Bring new data right after the falling edge of RDYn.
          LOCK := true;
      elsif DMA_PHASE = READ then
          FIFO_SYS_RD <= '0';
      else
          DATA_EN <= '0'; -- Disable 1 CLK after entering IDLE.
          FIFO_SYS_RD <= '0';
          LOCK := false;
      end if;
    end process FIFO_RD_CTRL;

    P_FIFO_WR_CTRL: process
    -- SYS_STATE_OUTLOGIC: ... is responsible to control the system side write process (memory via DMA to
    -- peripheral components). To achieve correct read timing, this process must operate on the rising
    -- clock edge!
    variable LOCK   : boolean;
    begin
        wait until CLK = '1' and CLK' event;
		if DMA_PHASE = WRITE and RDY_INn = '0' and LOCK = false then
            FIFO_SYS_WR <= '1';
            LOCK := true;
		elsif DMA_PHASE = WRITE and RDY_INn = '1' then
            FIFO_SYS_WR <= '0';
            LOCK := false;
        else
            FIFO_SYS_WR <= '0';
            LOCK := true;
        end if;
     end process P_FIFO_WR_CTRL;

    ACSI_STATE_MEM: process(RESETn, CLK)
    -- State machine register of the ACSI side state machine.
    begin
        if RESETn = '0' then -- DMA initialisation.
            ACSI_STATE <= IDLE_BYTE1;
        elsif CLK = '1' and CLK' event then
            -- Normally there is no need for clearing the ASCI state machine. But in case of
            -- a bad DATAREQ the machine can hang. The CLRn does initialize it every time the
            -- FIFO is cleared.
            if CLR_In = '0' then
                ACSI_STATE <= IDLE_BYTE1;
            else
                ACSI_STATE <= ACSI_NEXT_STATE;
            end if;
        end if;
    end process ACSI_STATE_MEM;

    ACSI_STATE_LOGIC: process(ACSI_STATE, DMA_RWn, FIFO_FULL, FIFO_EMPTY, DATAREQ)
    begin
        case ACSI_STATE is
        -------------------------------------
        -- Section wait for start conditions:
        -------------------------------------
            -- The ACSI bus is 8 bit wide where the FIFO is 16 bit. Therefore two read
            -- or write cycles are at least possible. This is the reason for the
            -- FIFO_EMPTY and FIFO_FULL regarded only during IDLE_BYTE1.
            when IDLE_BYTE1 =>
                -- Transfer data from FIFO to target if FIFO is not empty.
                if DMA_RWn = '0' and FIFO_EMPTY = '0' and DATAREQ = '1' then
                    ACSI_NEXT_STATE <= WRITE_HI;
                -- Transfer data from target to FIFO if it is not full.
                elsif DMA_RWn = '1' and FIFO_FULL = '0' and DATAREQ = '1' then
                    ACSI_NEXT_STATE <= READ_HI;
                else
                    ACSI_NEXT_STATE <= IDLE_BYTE1;
                end if;
            when IDLE_BYTE2 =>
                if DMA_RWn = '0' and DATAREQ = '1' then
                    ACSI_NEXT_STATE <= WRITE_LOW;
                elsif DMA_RWn = '1' and DATAREQ = '1' then
                    ACSI_NEXT_STATE <= READ_LOW;
                else
                    ACSI_NEXT_STATE <= IDLE_BYTE2;
                end if;
        --------------------------------
        -- Section write data to target:
        --------------------------------
            when WRITE_HI =>
                ACSI_NEXT_STATE <= IDLE_WR_HI;
            when IDLE_WR_HI =>
                if DATAREQ = '0' then
                    ACSI_NEXT_STATE <= IDLE_BYTE2;
                else
                    ACSI_NEXT_STATE <= IDLE_WR_HI;
                end if;
            when WRITE_LOW =>
                ACSI_NEXT_STATE <= IDLE_WR_LOW;
            when IDLE_WR_LOW =>
                if DATAREQ = '0' then
                    ACSI_NEXT_STATE <= IDLE_BYTE1;
                else
                    ACSI_NEXT_STATE <= IDLE_WR_LOW;
                end if;
        ---------------------------------
        -- Section read data from target:
        ---------------------------------
            when READ_HI =>
                ACSI_NEXT_STATE <= IDLE_RD_HI;
            when IDLE_RD_HI =>
                if DATAREQ = '0' then
                    ACSI_NEXT_STATE <= IDLE_BYTE2;
                else
                    ACSI_NEXT_STATE <= IDLE_RD_HI;
                end if;
            when READ_LOW =>
                ACSI_NEXT_STATE <= IDLE_RD_LOW;
            when IDLE_RD_LOW =>
                if DATAREQ = '0' then
                    ACSI_NEXT_STATE <= IDLE_BYTE1;
                else
                    ACSI_NEXT_STATE <= IDLE_RD_LOW;
                end if;
        end case;
    end process ACSI_STATE_LOGIC;

    -- ACSI_STATE_OUTLOGIC:
    FDCS_DMA_ACCn <= '0' when ACSI_STATE = IDLE_WR_HI and DMA_SRC_SEL = "10" else
                     '0' when ACSI_STATE = IDLE_WR_LOW and DMA_SRC_SEL = "10" else
                      -- The data of the floppy disk controller is switched to the ACSI
                      -- bus during FDCS_DMAn = '0'. The data is transfered in the ACSI
                      -- states READ_LOW and READ_HI.
                     '0' when ACSI_STATE = READ_HI and DMA_SRC_SEL = "10" else
                     '0' when ACSI_STATE = IDLE_RD_HI and DMA_SRC_SEL = "10" else
                     '0' when ACSI_STATE = READ_LOW and DMA_SRC_SEL = "10" else
                     '0' when ACSI_STATE = IDLE_RD_LOW and DMA_SRC_SEL = "10" else '1';

    HD_ACKn <= '0' when ACSI_STATE = IDLE_WR_HI and DMA_SRC_SEL /= "10" else
               '0' when ACSI_STATE = IDLE_WR_LOW and DMA_SRC_SEL /= "10" else
               '0' when ACSI_STATE = IDLE_RD_HI and DMA_SRC_SEL /= "10" else
               '0' when ACSI_STATE = IDLE_RD_LOW and DMA_SRC_SEL /= "10" else '1';

    -- Read from target:
    CD_HIBUF_EN <= '1' when ACSI_STATE = READ_HI else '0'; -- Sample.
    FIFO_ACSI_WR <= '1' when ACSI_STATE = READ_LOW else '0';

    -- Write to target:
    FIFO_ACSI_RD <= '1' when ACSI_STATE = WRITE_HI else '0';
    CD_RD_HIn <= '0' when ACSI_STATE = IDLE_WR_HI else '1';
    CD_RD_LOWn <= '0' when ACSI_STATE = IDLE_WR_LOW else '1';
end architecture BEHAVIOR;
