------------------------------------------------------------------------
----                                                                ----
----  Atari Falcon compatible direct memory access coprocessor.     ----
----  This file is part of the SUSKA-ATARI clone project.           ----
----                                                                ----
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
----  Author: Wolfgang Foerster                                     ----
----          support@inventronk.de                                 ----
----          www.inventronik.de                                    ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright Â© 2012... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- All rights reserved. No portion of this sourcecode may be      ----
---- reproduced or transmitted in any form by any means, whether    ----
---- by electronic, mechanical, photocopying, recording or          ----
---- otherwise, without my written permission.                      ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Description:                                                   ----
----                                                                ----
------------------------------------------------------------------------
-- 
-- Revision History
-- 
-- Revision 2K12A  20120620 WF
--   Initial Release.
-- Revision 2K15B  20151224 WF
--   Removed BGACK_INn. BGACK_OUTn is now BGAn.
-- Revision 2K21A 20211224 WF
--   Several changes / optimizations to meet the requirements for the new Falcon IP core.
-- Revision 2K24A 20240620 WF
--   Implemented a mechanism to operate 16 byte packages (see PKG_16).
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity FDMA_CTRL is
    port (
        CLK                 : in std_logic;
        RESET               : in std_logic;

        -- Bus control:
        BMODE               : in std_logic; -- '0' = 68030 bus timing '1' = 68000 bus timing.
        FC_OUT              : out std_logic_vector(2 downto 0);
        AS_INn              : in std_logic;
        AS_OUTn             : out std_logic;
        ADR_EN_ACSI         : out std_logic;
        ADR_EN_REPLAY       : out std_logic;
        ADR_EN_CAPTURE      : out std_logic;
        UDSn                : out std_logic;
        LDSn                : out std_logic;
        RWn                 : out std_logic;
        BERRn               : in std_logic; -- Bus error.
        DTACKn              : in std_logic;
        DATA_EN_ACSI        : out std_logic; -- Switch to connect the ACSI FIFO data to the bus.
        DATA_EN_CAPTURE     : out std_logic; -- Switch to connect the capture FIFO data to the bus.
        
        -- Bus arstd_logicration:
        BRn                 : out std_logic;
        BGIn                : in std_logic;
        BGOn                : out std_logic;
        BGAn                : out std_logic;

        -- Control signals for ACSI:
        ACSI_FIFO_CLRn      : out std_logic; -- Invalidate the FIFO entries.
        ACSI_FIFO_WR        : out std_logic;
        ACSI_FIFO_RD        : out std_logic;
        ACSI_FIFO_FULL      : in std_logic;
        ACSI_FIFO_LOW       : in std_logic;
        ACSI_FIFO_EMPTY     : in std_logic;

        -- Control signals for the PCM out:
        REPLAY_FIFO_CLRn    : out std_logic; -- Invalidate the FIFO entries.
        REPLAY_FIFO_WR      : out std_logic;
        REPLAY_FIFO_RD      : out std_logic;
        REPLAY_FIFO_FULL    : in std_logic;
        REPLAY_FIFO_LOW     : in std_logic;

        -- Control signals for the PCM in:
        CAPTURE_FIFO_CLRn   : out std_logic; -- Invalidate the FIFO entries.
        CAPTURE_FIFO_WR     : out std_logic;
        CAPTURE_FIFO_RD     : out std_logic;
        CAPTURE_FIFO_LOW    : in std_logic;
        CAPTURE_FIFO_EMPTY  : in std_logic;

        -- Handshaking:
        HDRQ                : in std_logic; -- Data request from the sound device.
        HD_ACKn             : out std_logic;
        FDCRQ               : in std_logic; -- Data request from the sound device.
        FDCSn               : out std_logic;      
        ACSI_DATA_REQ       : out std_logic; -- Status register stuff.
        REPLAY_DATAREQ      : in std_logic; -- Data request from the sound device.
        REPLAY_DATACK       : out std_logic; -- Data request from the sound device.
        CAPTURE_DATAREQ     : in std_logic; -- Data request from the sound device.
        CAPTURE_DATACK      : out std_logic; -- Data request from the sound device.

        -- Counter controls:
        SECTOR_CNT_EN       : out std_logic;
        DMA_FRAME_CNT_EN    : out std_logic;
        RP_FRAME_CNT_EN     : out std_logic;
        CA_FRAME_CNT_EN     : out std_logic;

        -- Control signals for the ACSI multiplexer:
        CD_HIBUF_EN         : out std_logic; -- Writes ACSI_BUF_HI.
        CD_RD_HIn           : out std_logic; -- Reads high FIFO byte to CD.
        CD_RD_LOWn          : out std_logic;  -- Reads low FIFO byte to CD.

        -- Other controls:
        DMA_EN              : in std_logic;
        PCM_REPLAY          : in std_logic;
        PCM_CAPTURE         : in std_logic;
        
        DMA_RWn             : in std_logic; -- FIFO direction '1' is peripherals to RAM.
        DMA_SRC_SEL         : in std_logic_vector(1 downto 0)
    );
end entity FDMA_CTRL;

architecture BEHAVIOUR of FDMA_CTRL is
type TIME_SLICES is (IDLE, S0, S1, S2, S3, S4, S5, S6, S7);
type DMA_STATES is (IDLE, ACSI_BUSREQUEST, ACSI_READ, ACSI_WRITE, PCM_BUSREQUEST, PCM_READ, PCM_WRITE);
type PCM_STATES is (IDLE, IDLE_WR, IDLE_RD, PCM_WRITE, PCM_READ);
type ACSI_STATES is (IDLE_BYTE1, IDLE_BYTE2, IDLE_WR_HI, IDLE_WR_LOW, IDLE_RD_HI,
                     IDLE_RD_LOW, WRITE_HI, WRITE_LOW, READ_HI, READ_LOW);
signal T_SLICE          : TIME_SLICES;
signal DMA_STATE        : DMA_STATES;
signal ACSI_STATE       : ACSI_STATES;
signal NEXT_ACSI_STATE  : ACSI_STATES;
signal PCM_STATE        : PCM_STATES;
signal NEXT_PCM_STATE   : PCM_STATES;

signal ACSI_DATAREQ     : std_logic; -- Data request from the ACSI bus or Floppy disk.
signal BUS_FREE         : boolean;
signal BGACK_In         : std_logic;
signal DATA_EN_I        : std_logic;
signal ADR_EN_I         : std_logic;
signal SLICE_CNT        : std_logic_vector(2 downto 0);

signal HDRQ_I           : std_logic;
signal FDCRQ_I          : std_logic;

signal WORDCNT_EN       : std_logic;
signal ACSI_FIFO_CD_RD  : std_logic;
signal ACSI_FIFO_CD_WR  : std_logic;
signal ACSI_FIFO_SYS_RD : std_logic;
signal ACSI_FIFO_SYS_WR : std_logic;
signal ACSI_CLR_In      : std_logic;
signal UDS_WR_EN        : std_logic;
signal LDS_WR_EN        : std_logic;
signal UDS_RD_EN        : std_logic;
signal LDS_RD_EN        : std_logic;
signal AS_EN            : std_logic;
signal WAITSTATES       : std_logic;
signal PKG_16           : boolean;
begin
    SYNC: process
    begin
        wait until CLK = '1' and CLK' event;
        FDCRQ_I <= FDCRQ;
        HDRQ_I <= HDRQ; -- The ACSI devices may work in their own clock domain...
    end process SYNC;

    REPLAY_FIFO_CLRn <= '0' when PCM_REPLAY = '0' else '1';
    CAPTURE_FIFO_CLRn <= '0' when PCM_CAPTURE = '0' else '1';

    DMA_CONTROL: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' or ACSI_CLR_In = '0' then
            DMA_STATE <= IDLE; -- Initial IDLE condition.
        else
            case DMA_STATE is
                when IDLE =>
                    -- Start in read from disk mode after the FIFO is half filled.
                    if DMA_EN = '1' and DMA_RWn = '1' and ACSI_FIFO_LOW = '0' then
                        DMA_STATE <= ACSI_BUSREQUEST; -- ACSI, read from target.
                    -- Start in write to disk mode if the FIFO is less than half full.
                    elsif DMA_EN = '1' and DMA_RWn = '0' and ACSI_FIFO_LOW = '1' and ACSI_DATAREQ = '1' then
                        DMA_STATE <= ACSI_BUSREQUEST; -- ACSI, write to target.
                    elsif PCM_REPLAY = '1' and REPLAY_FIFO_LOW = '0' then
                        DMA_STATE <= PCM_BUSREQUEST; -- PCM replay.
                    elsif PCM_CAPTURE = '1' and CAPTURE_FIFO_LOW = '1' then
                        DMA_STATE <= PCM_BUSREQUEST; -- PCM capture.
                    else
                        DMA_STATE <= IDLE;
                    end if;
                when ACSI_BUSREQUEST =>
                    if BUS_FREE = true and DMA_RWn = '1' then
                        DMA_STATE <= ACSI_READ; -- Read from target.
                    elsif BUS_FREE = true then
                        DMA_STATE <= ACSI_WRITE; -- Write to target.
                    else
                        DMA_STATE <= ACSI_BUSREQUEST;
                    end if;
                when ACSI_READ =>
                    if ACSI_FIFO_EMPTY = '1' and T_SLICE = IDLE then
                        DMA_STATE <= IDLE;
                    elsif PKG_16 = true and ACSI_FIFO_LOW = '1' and T_SLICE = IDLE then
                        DMA_STATE <= IDLE;
                    else
                        DMA_STATE <= ACSI_READ;
                    end if;
                when ACSI_WRITE =>
                    if ACSI_FIFO_FULL = '1' then
                        DMA_STATE <= IDLE;
                    else
                        DMA_STATE <= ACSI_WRITE;
                    end if;
                when PCM_BUSREQUEST =>
                    if BUS_FREE = true and PCM_CAPTURE = '1' and CAPTURE_FIFO_LOW = '1' then
                        DMA_STATE <= PCM_READ; -- For Read from target.
                    elsif BUS_FREE = true and PCM_REPLAY = '1' and REPLAY_FIFO_LOW = '0' then
                        DMA_STATE <= PCM_WRITE; -- For write to target.
                    else
                        DMA_STATE <= PCM_BUSREQUEST;
                    end if;
                when PCM_READ =>
                    if CAPTURE_FIFO_EMPTY = '1' then
                        DMA_STATE <= IDLE;
                    else
                        DMA_STATE <= PCM_READ;
                    end if;
                when PCM_WRITE =>
                    if REPLAY_FIFO_FULL = '1' then
                        DMA_STATE <= IDLE;
                    else
                        DMA_STATE <= PCM_WRITE;
                    end if;
            end case;
        end if;
    end process DMA_CONTROL;                

    BUS_REQUEST: process
    begin
        wait until CLK = '1' and CLK' event;
        -- BUSYn is used to distinguish between internal or external bus requests.
        if DMA_STATE /= IDLE and BGIn = '0' and AS_INn = '1' and DTACKn = '1' and BERRn = '1' then
            BUS_FREE <= true;
        else
            BUS_FREE <= false;
        end if;
    end process BUS_REQUEST;

    -- Bus arbitration:
    BRn <=  '0' when DMA_STATE = ACSI_BUSREQUEST or DMA_STATE = PCM_BUSREQUEST else '1';
    BGOn <= '0' when BGIn = '0' and DMA_STATE = IDLE else '1'; -- External bus request if DMA is not busy.
    BGACK_In <= '1' when DMA_STATE = IDLE else
                '1' when DMA_STATE = ACSI_BUSREQUEST and BUS_FREE = false else
                '1' when DMA_STATE = PCM_BUSREQUEST and BUS_FREE = false else '0';
    BGAn <= '0' when BGIn = '0' and DMA_STATE = IDLE else -- Transparent.
            '0' when BGACK_In = '0' else '1'; -- DMA acknowledge.

    CLEAR_DETECT: process(CLK, ACSI_CLR_In)
    -- This process detects any toggling of the DMA_RWn signal
    -- and releases a FIFO clear.
    variable LOCK   : boolean;
    begin
        -- Positive or negative edge detector.
        if CLK = '1' and CLK' event then
            if RESET = '1' then
                ACSI_CLR_In <= '0';
            ELSif DMA_RWn = '0' and LOCK = false then
                LOCK := true;
                ACSI_CLR_In <= '0';
            elsif DMA_RWn = '1' and LOCK = true then
                LOCK := false;
                ACSI_CLR_In <= '0';
            else
                ACSI_CLR_In <= '1';
            end if;
        end if;
        ACSI_FIFO_CLRn <= ACSI_CLR_In;
    end process CLEAR_DETECT;

    WORDCNT_EN <= '1' when ACSI_FIFO_SYS_RD = '1' else
                  '1' when ACSI_FIFO_SYS_WR = '1' else '0';

    WORD_CNT: process (CLK, WORDCNT_EN)
    -- This process counts the transferred double-bytes. The counter
    -- releases the SECTOR_CNT_EN when it counts 256 words (512 bytes).
    variable WORDCNT : std_logic_vector (7 downto 0);
    begin
        if CLK = '1' and CLK' event then
            if ACSI_CLR_In = '0' then -- During DMA initialisation ...
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

    with DMA_RWn select
        ACSI_FIFO_RD <= ACSI_FIFO_CD_RD when '0', -- Write to target.
                        ACSI_FIFO_SYS_RD when others; -- Read from target.
    with DMA_RWn select
        ACSI_FIFO_WR <= ACSI_FIFO_SYS_WR when '0', -- Write to target.
                        ACSI_FIFO_CD_WR when others; -- Read from target.
    -------------------------------------------------------------------------------------------------------------
    --                                 Memory to target DMA control section.                                   --
    -------------------------------------------------------------------------------------------------------------
    P_WAITSTATES: process
    -- This flip flop provides a slow bus access if no DTACKn
    -- signal is asserted by time. For more information refer
    -- to the MC68000 data sheet for the BMODE = '1' bus timing
    -- or the MC68030 data sheet for the BMODE = '0' bus timing.
    begin
        wait until CLK = '0' and CLK' event;
        if BMODE = '0' and SLICE_CNT = "001" then
            WAITSTATES <= DTACKn;
        elsif BMODE = '1' and SLICE_CNT = "010" then
            WAITSTATES <= DTACKn;
        else
            WAITSTATES <= '0';
        end if;
    end process P_WAITSTATES;

    SLICES: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            SLICE_CNT <= "111";
        else
            case DMA_STATE is
                when ACSI_READ | ACSI_WRITE | PCM_READ | PCM_WRITE =>
                    if BMODE = '0' and SLICE_CNT = "010" then
                        SLICE_CNT <= "111"; -- 68030 timing.
                    elsif SLICE_CNT = "011" then
                        SLICE_CNT <= "111"; -- 68000 timing.
                    elsif WAITSTATES = '0' then
                        SLICE_CNT <= SLICE_CNT + '1';
                    end if;
                when others => SLICE_CNT <= "111"; -- IDLE.
            end case;
        end if;
    end process SLICES;

    T_SLICE <=  S0 when SLICE_CNT = "000" and CLK = '1' else
                S1 when SLICE_CNT = "000" and CLK = '0' else
                S3 when BMODE = '0' and SLICE_CNT = "001" and WAITSTATES = '1' and CLK = '1' else
                S2 when SLICE_CNT = "001" and CLK = '1' else
                S3 when SLICE_CNT = "001" and CLK = '0' else
                S4 when SLICE_CNT = "010" and CLK = '1' else
                S4 when BMODE = '1' and SLICE_CNT = "010" and WAITSTATES = '1' and CLK = '0' else
                S5 when SLICE_CNT = "010" and CLK = '0' else
                S6 when SLICE_CNT = "011" and CLK = '1' else
                S7 when SLICE_CNT = "011" and CLK = '0' else IDLE;

    -- Bus timing:
    -- BMODE = '1' reflects 68000 bus timing, BMODE = '0' reflects 68030 bus timing.
    -- UDSn and LDSn are always asserted together for the read and write access to the source and destination is 
    -- always word wide. Read and write controls have different timings!
    UDS_WR_EN <= '1' when BMODE = '1' and (T_SLICE = S4 or T_SLICE = S5 or T_SLICE = S6) else
                 '1' when BMODE = '0' and (T_SLICE = S3 or T_SLICE = S4 or T_SLICE = S5) else '0';
    LDS_WR_EN <= '1' when BMODE = '1' and (T_SLICE = S4 or T_SLICE = S5 or T_SLICE = S6) else
                 '1' when BMODE = '0' and (T_SLICE = S3 or T_SLICE = S4 or T_SLICE = S5) else '0';
                
    UDS_RD_EN <= '1' when BMODE = '1' and (T_SLICE = S2 or T_SLICE = S3 or T_SLICE = S4 or T_SLICE = S5 or T_SLICE = S6) else
                 '1' when BMODE = '0' and (T_SLICE = S1 or T_SLICE = S2 or T_SLICE = S3 or T_SLICE = S4) else '0';
    LDS_RD_EN <= '1' when BMODE = '1' and (T_SLICE = S2 or T_SLICE = S3 or T_SLICE = S4 or T_SLICE = S5 or T_SLICE = S6) else
                 '1' when BMODE = '0' and (T_SLICE = S1 or T_SLICE = S2 or T_SLICE = S3 or T_SLICE = S4) else '0';
                
    AS_EN <= '1' when BMODE = '1' and (T_SLICE = S2 or T_SLICE = S3 or T_SLICE = S4 or T_SLICE = S5 or T_SLICE = S6) else
             '1' when BMODE = '0' and (T_SLICE = S1 or T_SLICE = S2 or T_SLICE = S3 or T_SLICE = S4) else '0';
    
    DATA_EN_I <= '1' when BMODE = '1' and (T_SLICE = S3 or T_SLICE = S4 or T_SLICE = S5 or T_SLICE = S6 or T_SLICE = S7) else
                 '1' when BMODE = '0' and (T_SLICE = S2 or T_SLICE = S3 or T_SLICE = S4 or T_SLICE = S5)  else '0';
    
    ADR_EN_I <= '0' when T_SLICE = IDLE or T_SLICE = S0 else '1';

    FC_OUT <= "001" when T_SLICE /= IDLE else "110"; -- DMA data is user data.

    ADR_EN_ACSI <= ADR_EN_I when DMA_STATE = ACSI_READ or DMA_STATE = ACSI_WRITE else '0';
    ADR_EN_CAPTURE <= ADR_EN_I when DMA_STATE = PCM_READ else '0';
    ADR_EN_REPLAY <= ADR_EN_I when DMA_STATE = PCM_WRITE else '0';

    AS_OUTn <= '0' when DMA_STATE = ACSI_READ and AS_EN = '1' else
               '0' when DMA_STATE = ACSI_WRITE and AS_EN = '1' else
               '0' when DMA_STATE = PCM_READ and AS_EN = '1' else
               '0' when DMA_STATE = PCM_WRITE and AS_EN = '1' else '1';

    UDSn <= '0' when DMA_STATE = ACSI_WRITE and UDS_RD_EN = '1' else
            '0' when DMA_STATE = ACSI_READ and UDS_WR_EN = '1' else
            '0' when DMA_STATE = PCM_WRITE and UDS_RD_EN = '1' else
            '0' when DMA_STATE = PCM_READ and UDS_WR_EN = '1' else '1';

    LDSn <= '0' when DMA_STATE = ACSI_WRITE and LDS_RD_EN = '1' else
            '0' when DMA_STATE = ACSI_READ and LDS_WR_EN = '1' else
            '0' when DMA_STATE = PCM_WRITE and LDS_RD_EN = '1' else
            '0' when DMA_STATE = PCM_READ and LDS_WR_EN = '1' else '1';

    RWn <= '0' when DMA_STATE = ACSI_READ else
           '0' when DMA_STATE = PCM_WRITE else '1'; -- Default is read.

    DATA_EN_ACSI <= DATA_EN_I when DMA_STATE = ACSI_READ else '0';
    DATA_EN_CAPTURE <= DATA_EN_I when DMA_STATE = PCM_READ else '0';

    ACSI_FIFO_SYS_RD <= '1' when DMA_STATE = ACSI_READ and T_SLICE = S1 else '0';
    ACSI_FIFO_SYS_WR <= '1' when DMA_STATE = ACSI_WRITE and T_SLICE = S5 and BMODE = '0' else
                        '1' when DMA_STATE = ACSI_WRITE and T_SLICE = S7 else '0';
    CAPTURE_FIFO_RD <= '1' when DMA_STATE = PCM_READ and T_SLICE = S1 else '0';
    REPLAY_FIFO_WR <= '1' when DMA_STATE = PCM_WRITE and T_SLICE = S5 and BMODE = '0' else
                      '1' when DMA_STATE = PCM_WRITE and T_SLICE = S7 else '0';

    DMA_FRAME_CNT_EN <= '1' when DMA_STATE = ACSI_READ and T_SLICE = S5 and BMODE = '0' else
                        '1' when DMA_STATE = ACSI_READ and T_SLICE = S7 else
                        '1' when DMA_STATE = ACSI_WRITE and T_SLICE = S5 and BMODE = '0' else 
                        '1' when DMA_STATE = ACSI_WRITE and T_SLICE = S7 else '0';
    CA_FRAME_CNT_EN <= '1' when DMA_STATE = PCM_READ and T_SLICE = S5 and BMODE = '0' else
                       '1' when DMA_STATE = PCM_READ and T_SLICE = S7 else '0';
    RP_FRAME_CNT_EN <= '1' when DMA_STATE = PCM_WRITE and T_SLICE = S5 and BMODE = '0' else 
                       '1' when DMA_STATE = PCM_WRITE and T_SLICE = S7 else '0';

    -------------------------------------------------------------------------------------------------------------
    --                                 Target to memory DMA control section.                                   --
    -------------------------------------------------------------------------------------------------------------
    ACSI_DATAREQ <= FDCRQ_I when DMA_SRC_SEL = "10" else HDRQ_I;
    ACSI_DATA_REQ <= ACSI_DATAREQ;
     
    STATE_MEMs: process
    -- State machine register of the ACSI side state machine.
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then -- DMA initialisation.
            ACSI_STATE <= IDLE_BYTE1;
        -- Normally there is no need for clearing the ASCI state machine. But in case of
        -- a bad DATAREQ the machine can hang. The CLRn does initialize it every time the
        -- FIFO is cleared.
        elsif ACSI_CLR_In = '0' then
            ACSI_STATE <= IDLE_BYTE1;
        else
            ACSI_STATE <= NEXT_ACSI_STATE;
        end if;

        if RESET = '1' then -- DMA initialisation.
            PCM_STATE <= IDLE;
        elsif PCM_REPLAY = '0' and PCM_CAPTURE = '0' then -- Off.
            PCM_STATE <= IDLE;
        else
            PCM_STATE <= NEXT_PCM_STATE;
        end if;
    end process STATE_MEMs;
    
    ACSI_STATE_LOGIC: process(ACSI_STATE, DMA_RWn, ACSI_FIFO_FULL, ACSI_FIFO_EMPTY, ACSI_DATAREQ)
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
                if DMA_RWn = '0' and ACSI_FIFO_EMPTY = '0' and ACSI_DATAREQ = '1' then
                    NEXT_ACSI_STATE <= WRITE_HI;
                -- Transfer data from target to FIFO if it is not full.
                elsif DMA_RWn = '1' and ACSI_FIFO_FULL = '0' and ACSI_DATAREQ = '1' then
                    NEXT_ACSI_STATE <= READ_HI;
                else
                    NEXT_ACSI_STATE <= IDLE_BYTE1;
                end if;
            when IDLE_BYTE2 =>
                if DMA_RWn = '0' and ACSI_DATAREQ = '1' then
                    NEXT_ACSI_STATE <= WRITE_LOW;
                elsif DMA_RWn = '1' and ACSI_DATAREQ = '1' then
                    NEXT_ACSI_STATE <= READ_LOW;
                else
                    NEXT_ACSI_STATE <= IDLE_BYTE2;
                end if;
            --------------------------------
            -- Section write data to target:
            --------------------------------
            when WRITE_HI =>
                NEXT_ACSI_STATE <= IDLE_WR_HI;
            when IDLE_WR_HI =>
                if ACSI_DATAREQ = '0' then      
                    NEXT_ACSI_STATE <= IDLE_BYTE2;
                else
                    NEXT_ACSI_STATE <= IDLE_WR_HI;
                end if;
            when WRITE_LOW =>
                NEXT_ACSI_STATE <= IDLE_WR_LOW;
            when IDLE_WR_LOW =>
                if ACSI_DATAREQ = '0' then
                    NEXT_ACSI_STATE <= IDLE_BYTE1;
                else
                    NEXT_ACSI_STATE <= IDLE_WR_LOW;
                end if;
            ---------------------------------
            -- Section read data from target:
            ---------------------------------
            when READ_HI =>
                NEXT_ACSI_STATE <= IDLE_RD_HI;
            when IDLE_RD_HI =>
                if ACSI_DATAREQ = '0' then      
                    NEXT_ACSI_STATE <= IDLE_BYTE2;
                else
                    NEXT_ACSI_STATE <= IDLE_RD_HI;
                end if;
            when READ_LOW =>
                NEXT_ACSI_STATE <= IDLE_RD_LOW;
            when IDLE_RD_LOW =>
                if ACSI_DATAREQ = '0' then      
                    NEXT_ACSI_STATE <= IDLE_BYTE1;
                else
                    NEXT_ACSI_STATE <= IDLE_RD_LOW;
                end if;
        end case;
    end process ACSI_STATE_LOGIC;
    -- ACSI_STATE_OUTLOGIC:
    FDCSn <= '0' when ACSI_STATE = IDLE_WR_HI and DMA_SRC_SEL = "10" else
             '0' when ACSI_STATE = IDLE_WR_LOW and DMA_SRC_SEL = "10" else
             '0' when ACSI_STATE = READ_HI and DMA_SRC_SEL = "10" else -- Early select to enable data from FDC.
             '0' when ACSI_STATE = IDLE_RD_HI and DMA_SRC_SEL = "10" else
             '0' when ACSI_STATE = READ_LOW and DMA_SRC_SEL = "10" else -- Early select to enable data from FDC.
             '0' when ACSI_STATE = IDLE_RD_LOW and DMA_SRC_SEL = "10" else '1';

    HD_ACKn <= '0' when ACSI_STATE = IDLE_WR_HI and DMA_SRC_SEL /= "10" else
               '0' when ACSI_STATE = IDLE_WR_LOW and DMA_SRC_SEL /= "10" else
               '0' when ACSI_STATE = IDLE_RD_HI and DMA_SRC_SEL /= "10" else
               '0' when ACSI_STATE = IDLE_RD_LOW and DMA_SRC_SEL /= "10" else '1';

    -- ACSI read from target:
    CD_HIBUF_EN <= '1' when ACSI_STATE = READ_HI else '0'; -- Sample.
    ACSI_FIFO_CD_WR <= '1' when ACSI_STATE = READ_LOW else '0';
    
    -- ACSI write to target:
    ACSI_FIFO_CD_RD <= '1' when ACSI_STATE = WRITE_HI else '0';
    CD_RD_HIn <= '0' when ACSI_STATE = IDLE_WR_HI else '1';
    CD_RD_LOWn <= '0' when ACSI_STATE = IDLE_WR_LOW else '1';

    PCM_STATE_LOGIC: process(PCM_STATE, PCM_REPLAY, PCM_CAPTURE, REPLAY_DATAREQ, CAPTURE_DATAREQ, REPLAY_FIFO_LOW, CAPTURE_FIFO_LOW)
    begin
        case PCM_STATE is
            when IDLE =>
                if PCM_REPLAY = '1' and REPLAY_FIFO_LOW = '0' and REPLAY_DATAREQ = '1' then
                    NEXT_PCM_STATE <= PCM_WRITE;
                elsif PCM_CAPTURE = '1' and CAPTURE_FIFO_LOW = '1' and CAPTURE_DATAREQ = '1' then
                    NEXT_PCM_STATE <= PCM_READ;
                else
                    NEXT_PCM_STATE <= IDLE;
                end if;
            --------------------------------
            -- Section write data to target:
            --------------------------------
            when PCM_WRITE =>
                NEXT_PCM_STATE <= IDLE_WR;
            when IDLE_WR =>
                if REPLAY_DATAREQ = '0' then
                    NEXT_PCM_STATE <= IDLE;
                else
                    NEXT_PCM_STATE <= IDLE_WR;
                end if;
            ---------------------------------
            -- Section read data from target:
            ---------------------------------
            when PCM_READ =>
                NEXT_PCM_STATE <= IDLE_RD;
            when IDLE_RD =>
                if CAPTURE_DATAREQ = '0' then       
                    NEXT_PCM_STATE <= IDLE;
                else
                    NEXT_PCM_STATE <= IDLE_RD;
                end if;
        end case;
    end process PCM_STATE_LOGIC;
    
    -- PCM in/out:
    REPLAY_FIFO_RD <= '1' when PCM_STATE = PCM_WRITE else '0'; 
    CAPTURE_FIFO_WR <= '1' when PCM_STATE = PCM_READ else '0';
    
    REPLAY_DATACK <= '1' when PCM_STATE = IDLE_WR else '0';
    CAPTURE_DATACK <= '1' when PCM_STATE = IDLE_RD else '0';    
end architecture BEHAVIOUR;
