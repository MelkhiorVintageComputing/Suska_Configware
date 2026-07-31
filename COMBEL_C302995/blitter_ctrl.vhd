------------------------------------------------------------------------
----                                                                ----
---- ATARI ST BLITTER compatible IP Core                            ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- ATARI COMBEL compatible Bit Block Transfer Processor           ----
---- (BLITTER) IP core.                                             ----
----                                                                ----
---- Control unit with adress logic and bus arbitration.            ----
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
---- Copyright © 2009... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- All rights reserved. No portion of this sourcecode may be      ----
---- reproduced or transmitted in any form by any means, whether    ----
---- by electronic, mechanical, photocopying, recording or          ----
---- otherwise, without my written permission.                      ----
----                                                                ----
------------------------------------------------------------------------
--
-- Revision History
--
-- Revision 2K9B  2009/12/24 WF
--   Initial Release.
-- Revision 2K21A 20211224 WF
--   Minor fixes and changes to meet Falcon core requirements.
--   The function code is now supervisor mode. The changes result from the MiSTery project.
--   The HOG = '0' cycle counter works now correct on bus cycles. The changes result from the MiSTery project.
--   Bus timing optimizations. The changes result from the MiSTery project.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity BLITTER_CTRL is
port (  CLK         : in std_logic;
        RESET       : in std_logic;

        -- Bus control:
        BERRn       : in std_logic; -- Bus error.
        BMODE       : in std_logic; -- '1' = 68000 bus timing, '0' = 68030 bus timing.
        DTACKn      : in std_logic;
        AS_INn      : in std_logic;
        AS_OUTn     : buffer std_logic;
        UDSn        : out std_logic;
        LDSn        : out std_logic;
        RWn         : out std_logic;
        BUSCTRL_EN  : out std_logic;
        FC_OUT      : out std_logic_vector(2 downto 0);

        -- Bus arstd_logicration:
        BGIn        : in std_logic;
        BRn         : out std_logic;
        BGACK_INn   : in std_logic;
        BGACK_OUTn  : out std_logic;
        BGOn        : out std_logic;

        -- The flags:
        OP      : in std_logic_vector(3 downto 0);
        HOP     : in std_logic_vector(1 downto 0);
        HOG     : in std_logic;
        BUSY    : in std_logic;
        SMUDGE  : in std_logic;

        -- Adress counter controls (DMA mode).
        ADR_SEL         : out std_logic;
        ADR_OUT_EN      : out std_logic;

        -- Data processing controls:
        BLT_BSY         : in std_logic; -- '0' if Y counter is x"0000".
        FORCE_DEST      : in std_logic; -- Force a read modify write cycle.
        FXSR            : in std_logic;
        NFSR            : in std_logic;
        XCNT_RELOAD     : in std_logic_vector(15 downto 0);
        XCNT_VALUE      : in std_logic_vector(15 downto 0);
        BLT_RESTART     : in std_logic;
        SWAPSRC         : out std_logic;
        FETCHSRC        : out std_logic;
        FETCHDEST       : out std_logic;
        PUSHDEST        : out std_logic;
        FORCE_X         : out boolean;
        SRCADR_MODIFY   : out boolean;
        DESTADR_MODIFY  : out boolean;
        X_COUNT_DEC     : out boolean
      );
end BLITTER_CTRL;

architecture BEHAVIOR of BLITTER_CTRL is
type BLITTER_STATES is (IDLE, BUSREQUEST, SELECT_CMD, T1_RD_DEST, T1_WR, T1_CHECK, T2_RD_DEST, T2_RD_SRC_1,
                        T2_RD_SRC_2, T2_WR, T2_CHECK, T3_RD_SRC_1, T3_RD_SRC_2, T3_RD_DEST, T3_WR, T3_CHECK);
type TIME_SLICES is (IDLE, S0, S1, S2, S3, S4, S5, S6, S7);
signal BLT_STATE        : BLITTER_STATES;
signal NEXT_BLT_STATE   : BLITTER_STATES;
signal BUS_FREE         : boolean;
signal CYC_END          : boolean;
signal SLICE_CNT        : std_logic_vector(2 downto 0);
signal T_SLICE          : TIME_SLICES;
signal UDS_WR_EN        : std_logic;
signal LDS_WR_EN        : std_logic;
signal UDS_RD_EN        : std_logic;
signal LDS_RD_EN        : std_logic;
signal AS_EN            : std_logic;
signal DATA_EN          : std_logic;
signal ADDRESS_EN       : std_logic;
signal WAITSTATES       : std_logic;
signal HOG_START        : std_logic;
signal HOG_STOP         : std_logic;
signal PRE_FETCH        : std_logic;
signal POST_FLUSH       : std_logic;
signal SKIP_CALC        : std_logic;

begin
    -- Declare the BLITTER video data as user data. This is achieved by a value of "101" for FC during
    -- active bus cycles. This functionality is necessary not to produce interrupt requests in the GLUE
    -- chip (FC = "111") during bus accesses.
    FC_OUT <= "101" when T_SLICE /= IDLE else "000"; -- Default is dummy.
    BUSCTRL_EN <= '1' when BLT_STATE /= IDLE and BLT_STATE /= BUSREQUEST else '0';

    -- Bus arbitration:
    BRn         <=  '0' when BLT_STATE = BUSREQUEST else '1';
    BGOn        <=  '0' when BGIn = '0' and BUSY = '0' else '1'; -- External bus request if BLITTER is not busy.
    BGACK_OUTn  <=  '1' when BUSY = '0' else
                    '1' when BUSY = '1' and BLT_STATE = IDLE else
                    '1' when BUSY = '1' and BLT_STATE = BUSREQUEST and BUS_FREE = false else '0';

    -- Address controlling ('1' = SRC_ADR, '0' = DEST_ADR.):
    ADR_SEL  <= '0' when BLT_STATE = T1_RD_DEST else    -- Read from destination.
                '0' when BLT_STATE = T1_WR else         -- Write to destination.
                '0' when BLT_STATE = T2_RD_DEST else    -- Read from destination.
                '0' when BLT_STATE = T2_WR else         -- Write to destination.
                '0' when BLT_STATE = T3_RD_DEST else    -- Read from destination.
                '0' when BLT_STATE = T3_WR else '1';    -- Source is default.

    ADR_OUT_EN   <= '1' when BLT_STATE = T1_RD_DEST and ADDRESS_EN = '1' else
                    '1' when BLT_STATE = T1_WR and ADDRESS_EN = '1' else
                    '1' when BLT_STATE = T2_RD_DEST and ADDRESS_EN = '1' else
                    '1' when BLT_STATE = T2_RD_SRC_1 and ADDRESS_EN = '1' else
                    '1' when BLT_STATE = T2_RD_SRC_2 and ADDRESS_EN = '1' else
                    '1' when BLT_STATE = T2_WR and ADDRESS_EN = '1' else
                    '1' when BLT_STATE = T3_RD_SRC_1 and ADDRESS_EN = '1' else
                    '1' when BLT_STATE = T3_RD_SRC_2 and ADDRESS_EN = '1' else
                    '1' when BLT_STATE = T3_RD_DEST and ADDRESS_EN = '1' else
                    '1' when BLT_STATE = T3_WR and ADDRESS_EN = '1' else '0';

    AS_OUTn  <= '0' when BLT_STATE = T1_RD_DEST and AS_EN = '1' else
                '0' when BLT_STATE = T1_WR and AS_EN = '1' else
                '0' when BLT_STATE = T2_RD_DEST and AS_EN = '1' else
                '0' when BLT_STATE = T2_RD_SRC_1 and AS_EN = '1' else
                '0' when BLT_STATE = T2_RD_SRC_2 and AS_EN = '1' else
                '0' when BLT_STATE = T2_WR and AS_EN = '1' else
                '0' when BLT_STATE = T3_RD_SRC_1 and AS_EN = '1' else
                '0' when BLT_STATE = T3_RD_SRC_2 and AS_EN = '1' else
                '0' when BLT_STATE = T3_RD_DEST and AS_EN = '1' else
                '0' when BLT_STATE = T3_WR and AS_EN = '1' else '1';

    UDSn     <= '0' when BLT_STATE = T1_RD_DEST and UDS_RD_EN = '1' else
                '0' when BLT_STATE = T1_WR and UDS_WR_EN = '1' else
                '0' when BLT_STATE = T2_RD_DEST and UDS_RD_EN = '1' else
                '0' when BLT_STATE = T2_RD_SRC_1 and UDS_RD_EN = '1' else
                '0' when BLT_STATE = T2_RD_SRC_2 and UDS_RD_EN = '1' else
                '0' when BLT_STATE = T2_WR and UDS_WR_EN = '1' else
                '0' when BLT_STATE = T3_RD_SRC_1 and UDS_RD_EN = '1' else
                '0' when BLT_STATE = T3_RD_SRC_2 and UDS_RD_EN = '1' else
                '0' when BLT_STATE = T3_RD_DEST and UDS_RD_EN = '1' else
                '0' when BLT_STATE = T3_WR and UDS_WR_EN = '1' else '1';
    LDSn     <= '0' when BLT_STATE = T1_RD_DEST and LDS_RD_EN = '1' else
                '0' when BLT_STATE = T1_WR and LDS_WR_EN = '1' else
                '0' when BLT_STATE = T2_RD_DEST and LDS_RD_EN = '1' else
                '0' when BLT_STATE = T2_RD_SRC_1 and LDS_RD_EN = '1' else
                '0' when BLT_STATE = T2_RD_SRC_2 and LDS_RD_EN = '1' else
                '0' when BLT_STATE = T2_WR and LDS_WR_EN = '1' else
                '0' when BLT_STATE = T3_RD_SRC_1 and LDS_RD_EN = '1' else
                '0' when BLT_STATE = T3_RD_SRC_2 and LDS_RD_EN = '1' else
                '0' when BLT_STATE = T3_RD_DEST and LDS_RD_EN = '1' else
                '0' when BLT_STATE = T3_WR and LDS_WR_EN = '1' else '1';

    RWn      <= '0' when BLT_STATE = T1_WR else
                '0' when BLT_STATE = T2_WR else
                '0' when BLT_STATE = T3_WR else '1'; -- Default is read.

    -- NFSR / FXSR controls:
    PRE_FETCH <= '1' when XCNT_VALUE = XCNT_RELOAD and FXSR = '1' else '0'; -- Read twice at the beginning of a line.
    POST_FLUSH <= '1' when XCNT_VALUE = x"0001" and NFSR = '1' else '0'; -- Do not read the last data word of each line.

    -- The SKIP_CALC control covers several special conditions:
    -- During FXSR = '0' and NFSR = '1' (post flushing data), the second last source read must occur without
    -- source address modification to handle correct source address incrementing with SRC_Y_INCR.
    -- During FXSR = '1' and NFSR = '1' (pre fetching and post flushing data), a special case is the
    -- writing of just two destination words (XCNT_RELOAD = x"0002"). The second source read must happen
    -- in this case without source address modification.
    -- In case of XCNT_RELOAD less than x"0002" there will result unpredictionable behavior of the BLITTER,
    -- if both, FXSR and NFSR are asserted. Nevertheless these settings does not make sense.
    SKIP_CALC <= '1' when XCNT_VALUE = x"0002" and NFSR = '1' and FXSR = '1' and XCNT_RELOAD > x"0002" else
                 '1' when XCNT_VALUE = x"0002" and NFSR = '1' and FXSR = '0' else
                 '1' when XCNT_RELOAD = x"0002" and NFSR = '1' and FXSR = '1' and BLT_STATE = T2_RD_SRC_2 else
                 '1' when XCNT_RELOAD = x"0002" and NFSR = '1' and FXSR = '1' and BLT_STATE = T3_RD_SRC_2 else '0';

    -- The FORCE_X is a special case of the FXSR (Force Extra Source Read) mode:
    -- When a force extra source read is required and the first data word is read, the source address
    -- must in any case be incremented with the SRC_X_INCR value even if the value of XCNT_RELOAD is one.
    -- Means a source address calculation error would occur, because the XCNT_RELOAD value of one would
    -- force the source address counter to increment with the SRC_Y_INCR value.
    FORCE_X <=  true when BLT_STATE = T2_RD_SRC_1 and XCNT_VALUE = XCNT_RELOAD and FXSR = '1' else
                true when BLT_STATE = T3_RD_SRC_1 and XCNT_VALUE = XCNT_RELOAD and FXSR = '1' else false;

    SRCADR_MODIFY <= true when BLT_STATE = T2_RD_SRC_1 and SKIP_CALC = '0' and CYC_END = true else
                     true when BLT_STATE = T2_RD_SRC_2 and SKIP_CALC = '0' and CYC_END = true else
                     true when BLT_STATE = T3_RD_SRC_1 and SKIP_CALC = '0' and CYC_END = true else
                     true when BLT_STATE = T3_RD_SRC_2 and SKIP_CALC = '0' and CYC_END = true else
                     -- Pay attention here to assert the control in odd time slices due to the
                     -- rising edge of the register process in the core file!
                     true when BLT_STATE = T2_WR and OP = x"3" and POST_FLUSH = '1' and T_SLICE = S1 else
                     true when BLT_STATE = T2_WR and OP = x"C" and POST_FLUSH = '1' and T_SLICE = S1 else
                     true when BLT_STATE = T3_WR and POST_FLUSH = '1' and T_SLICE = S1 else false;

    -- Fetch the source data in the end of the time cycle S4/S6. This is
    -- rather late but ensures valid data on the bus. The even time slices
    -- require the source process working on the negative clock edge!
    FETCHSRC <= '1' when BLT_STATE = T2_RD_SRC_1 and BMODE = '1' and T_SLICE = S6 else
                '1' when BLT_STATE = T2_RD_SRC_2 and BMODE = '1' and T_SLICE = S6 else
                '1' when BLT_STATE = T3_RD_SRC_1 and BMODE = '1' and T_SLICE = S6 else
                '1' when BLT_STATE = T3_RD_SRC_2 and BMODE = '1' and T_SLICE = S6 else
                '1' when BLT_STATE = T2_RD_SRC_1 and BMODE = '0' and T_SLICE = S4 else
                '1' when BLT_STATE = T2_RD_SRC_2 and BMODE = '0' and T_SLICE = S4 else
                '1' when BLT_STATE = T3_RD_SRC_1 and BMODE = '0' and T_SLICE = S4 else
                '1' when BLT_STATE = T3_RD_SRC_2 and BMODE = '0' and T_SLICE = S4 else '0';

    -- The following control provides source buffer swapping without bus read access. This is necessary
    -- for some combinations of NFSR, FXSR and SKEW. The even time slices require the source process
    -- working on the negative clock edge!
    SWAPSRC <=  '1' when BLT_STATE = T2_WR and OP = x"3" and POST_FLUSH = '1' and T_SLICE = S0 else
                '1' when BLT_STATE = T2_WR and OP = x"C" and POST_FLUSH = '1' and T_SLICE = S0 else
                '1' when BLT_STATE = T3_WR and POST_FLUSH = '1' and T_SLICE = S0 else '0';

    DESTADR_MODIFY   <= true when BLT_STATE = T1_WR and CYC_END = true else
                        true when BLT_STATE = T2_WR and CYC_END = true else
                        true when BLT_STATE = T3_WR and CYC_END = true else false;

    -- Fetch the destination data in the end of the time cycle S6. This is
    -- rather late but ensures valid data on the bus. The even time slices
    -- require the destination process working on the negative clock edge!
    FETCHDEST       <= '1' when BLT_STATE = T1_RD_DEST and BMODE = '1' and T_SLICE = S6 else
                       '1' when BLT_STATE = T2_RD_DEST and BMODE = '1' and T_SLICE = S6 else
                       '1' when BLT_STATE = T3_RD_DEST and BMODE = '1' and T_SLICE = S6 else
                       '1' when BLT_STATE = T1_RD_DEST and BMODE = '0' and T_SLICE = S4 else
                       '1' when BLT_STATE = T2_RD_DEST and BMODE = '0' and T_SLICE = S4 else
                       '1' when BLT_STATE = T3_RD_DEST and BMODE = '0' and T_SLICE = S4 else '0';

    PUSHDEST        <= '1' when BLT_STATE = T1_WR and DATA_EN = '1' else
                       '1' when BLT_STATE = T2_WR and DATA_EN = '1' else
                       '1' when BLT_STATE = T3_WR and DATA_EN = '1' else '0';

    X_COUNT_DEC  <= true when BLT_STATE = T1_WR and CYC_END = true else
                    true when BLT_STATE = T2_WR and CYC_END = true else
                    true when BLT_STATE = T3_WR and CYC_END = true else false;

    P_CYCLE_CNT: process
    -- This process provides counting the read or read modify write cycles. This is required
    -- for the HOG = '0' operation. After 64 clock cycles, the BLITTER stops operation and releases
    -- the bus. It is restarted again by setting the BUSY flag or after HOG_START.
    -- For further details see the Atari related bit block transfer processor documentation.
    variable CYCLE_CNT  : std_logic_vector(5 downto 0);
    variable LOCK       : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            CYCLE_CNT := (others => '0');
            HOG_STOP <= '0';
            HOG_START <= '0';
            LOCK := false;
        elsif BUSY = '0' or BLT_RESTART = '1' then
            CYCLE_CNT := (others => '0');
            LOCK := false;
        elsif (AS_INn = '0' or AS_OUTn = '0') and LOCK = false then
            CYCLE_CNT := CYCLE_CNT + '1';
            LOCK := true;
        elsif AS_INn = '1' and AS_OUTn = '1' then
            LOCK := false;
        end if;
    
        if BUSY = '0' or BLT_RESTART = '1' then
            HOG_START <= '0';
            HOG_STOP <= '0';
        elsif CYCLE_CNT = x"00" then
            HOG_START <= not HOG;
            HOG_STOP <= '0';
        elsif CYCLE_CNT = x"40" then
            HOG_STOP <= not HOG;
            HOG_START <= '0';
        end if;
    end process P_CYCLE_CNT;

    BLT_STATE_MEM: process
    -- Main state machine register.
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            BLT_STATE <= IDLE;
        elsif BERRn = '0' then
            BLT_STATE <= IDLE; -- Break!
        else
            BLT_STATE <= NEXT_BLT_STATE;
        end if;
    end process BLT_STATE_MEM;

    BLT_STATE_LOGIC: process(BLT_STATE, BUSY, BUS_FREE, CYC_END, HOG, HOG_START, HOG_STOP, 
                             BLT_RESTART, BLT_BSY, OP, HOP, FORCE_DEST, SMUDGE, PRE_FETCH, POST_FLUSH)
    begin
        case BLT_STATE is
            when IDLE =>
                if HOG = '1' and BUSY = '1' then
                    -- Start in HOG mode after BUSY is set:
                    NEXT_BLT_STATE <= BUSREQUEST;
                elsif HOG = '0' and BUSY = '1' and HOG_START = '1' then
                    -- Restart in cooperative mode after cycle enable:
                    NEXT_BLT_STATE <= BUSREQUEST;
                elsif HOG = '0' and BUSY = '1' and BLT_RESTART = '1' then
                    -- Restart in cooperative mode by processor launch (immediately):
                    NEXT_BLT_STATE <= BUSREQUEST;
                else
                    NEXT_BLT_STATE <= IDLE;
                end if;
            when BUSREQUEST =>
                if BUS_FREE = true then -- The bus is now free for data transfer.
                    NEXT_BLT_STATE <= SELECT_CMD;
                else
                    NEXT_BLT_STATE <= BUSREQUEST;
                end if;
            when SELECT_CMD =>
                -- Type1 commands are characterized by writing just a fixed value '0' or '1' or halftone
                -- patterns to the destination.
                -- Type2 commands need the destination data or the source data for new data processing.
                -- Type 3 commands need all, the source and destination (and halftone) data for new data
                -- processing.
                -- The determination which kind of data is necessary for the bit block transfer operation
                -- is done exclusively here because a running bit block transfer uses always the same
                -- type of data which can only change after wrapping the 'IDLE' state.
                case OP is
                    when x"0" | x"F" =>
                        if FORCE_DEST = '1' then
                             NEXT_BLT_STATE <= T1_RD_DEST; -- Data required.
                        else
                             NEXT_BLT_STATE <= T1_WR; -- No data required.
                        end if;
                    when x"5" | x"A" => NEXT_BLT_STATE <= T2_RD_DEST; -- Destination data processing.
                    when x"3" | x"C" =>
                        case HOP is
                            when "00" | "01" => -- Halftone processing.
                                if SMUDGE = '1' then
                                    if FORCE_DEST = '1' then
                                         NEXT_BLT_STATE <= T2_RD_DEST; -- Destination data required.
                                    elsif POST_FLUSH = '1' then
                                         NEXT_BLT_STATE <= T2_WR; -- Skip source data read.
                                    else
                                         NEXT_BLT_STATE <= T2_RD_SRC_1; -- Source data required.
                                    end if;
                                else
                                    if FORCE_DEST = '1' then
                                        NEXT_BLT_STATE <= T1_RD_DEST; -- Destination data required.
                                    else
                                        NEXT_BLT_STATE <= T1_WR; -- Only halftone data required.
                                    end if;
                                end if;
                            when others => -- Sorce data processing.
                                if FORCE_DEST = '1' then
                                     NEXT_BLT_STATE <= T2_RD_DEST; -- Destination data required.
                                elsif POST_FLUSH = '1' then
                                     NEXT_BLT_STATE <= T2_WR; -- Skip source data read.
                                else
                                     NEXT_BLT_STATE <= T2_RD_SRC_1; -- Source data required.
                                end if;
                        end case;
                    when others =>
                        case HOP is
                            when "00" | "01" => -- Halftone processing.
                                if SMUDGE = '1' and POST_FLUSH = '0' then
                                    NEXT_BLT_STATE <= T3_RD_SRC_1; -- All data required.
                                else
                                    NEXT_BLT_STATE <= T2_RD_DEST; -- Halftone and destination data required.
                                end if;
                            when others =>
                                if POST_FLUSH = '1' then
                                    NEXT_BLT_STATE <= T3_RD_DEST; -- Skip source data read.
                                else
                                    NEXT_BLT_STATE <= T3_RD_SRC_1; -- All data required.
                                end if;
                        end case;
                end case;
            ---------------------------------- TYPE I COMMANDS -----------------------------------------
            when T1_RD_DEST =>
                if CYC_END = true then
                    NEXT_BLT_STATE <= T1_WR; -- Read cycle finished.
                else
                    NEXT_BLT_STATE <= T1_RD_DEST;
                end if;
            when T1_WR =>
                if CYC_END = true then
                    NEXT_BLT_STATE <= T1_CHECK; -- Write cycle finished.
                else
                    NEXT_BLT_STATE <= T1_WR;
                end if;
            when T1_CHECK =>
                if HOG_STOP = '1' or BLT_BSY = '0' then
                    NEXT_BLT_STATE <= IDLE; -- BLITTER finished.
                elsif FORCE_DEST = '1' then
                     NEXT_BLT_STATE <= T1_RD_DEST; -- Data required.
                else
                     NEXT_BLT_STATE <= T1_WR; -- No data required.
                end if;
            ---------------------------------- TYPE II COMMANDS -----------------------------------------
            when T2_RD_DEST =>
                if CYC_END = true then
                    case OP is
                        when x"3" | x"C" => -- Go on processing source data.
                            if POST_FLUSH = '0' then
                                NEXT_BLT_STATE <= T2_RD_SRC_1;
                            else -- Post-flush source data:
                                NEXT_BLT_STATE <= T2_WR; -- Do not read further source data.
                            end if;
                        when others =>  NEXT_BLT_STATE <= T2_WR; -- Read cycle finished.
                    end case;
                else
                    NEXT_BLT_STATE <= T2_RD_DEST;
                end if;
            when T2_RD_SRC_1 =>
                if CYC_END = true and PRE_FETCH = '1' then
                    NEXT_BLT_STATE <= T2_RD_SRC_2; -- Read two words at the beginning of the line.
                elsif CYC_END = true then
                    NEXT_BLT_STATE <= T2_WR; -- Read cycle finished by no final source read.
                else
                    NEXT_BLT_STATE <= T2_RD_SRC_1;
                end if;
            when T2_RD_SRC_2 =>
                if CYC_END = true then
                    NEXT_BLT_STATE <= T2_WR; -- Read cycle finished.
                else
                    NEXT_BLT_STATE <= T2_RD_SRC_2;
                end if;
            -- The complete data processing delay of the BLITTER core is exactly one clock
            -- cycle. Therefore there is no need for an extra delay between reading and
            -- writing the modified video data.
            when T2_WR =>
                if CYC_END = true then
                    NEXT_BLT_STATE <= T2_CHECK; -- Write cycle finished.
                else
                    NEXT_BLT_STATE <= T2_WR;
                end if;
            when T2_CHECK =>
                if HOG_STOP = '1' or BLT_BSY = '0' then
                    NEXT_BLT_STATE <= IDLE; -- BLITTER finished.
                else
                    case OP is
                        when x"3" | x"C" => -- Go on processing source data.
                            if FORCE_DEST = '1' then
                                 NEXT_BLT_STATE <= T2_RD_DEST; -- Destination data required.
                            elsif POST_FLUSH = '0' then
                                NEXT_BLT_STATE <= T2_RD_SRC_1;
                            else -- Post-flush source data:
                                NEXT_BLT_STATE <= T2_WR; -- Do not read further source data.
                            end if;
                        when others =>  NEXT_BLT_STATE <= T2_RD_DEST; -- Go on processing destination / halftone.
                    end case;
                end if;
            ---------------------------------- TYPE III COMMANDS -----------------------------------------
            when T3_RD_SRC_1 =>
                if CYC_END = true and PRE_FETCH = '1' then
                    NEXT_BLT_STATE <= T3_RD_SRC_2; -- Read two words at the beginning of the line.
                elsif CYC_END = true then
                    NEXT_BLT_STATE <= T3_RD_DEST; -- Source read cycle finished.
                else
                    NEXT_BLT_STATE <= T3_RD_SRC_1;
                end if;
            when T3_RD_SRC_2 =>
                if CYC_END = true then
                    NEXT_BLT_STATE <= T3_RD_DEST; -- Source read cycle finished.
                else
                    NEXT_BLT_STATE <= T3_RD_SRC_2;
                end if;
            when T3_RD_DEST =>
                if CYC_END = true then
                    NEXT_BLT_STATE <= T3_WR; -- Read cycle finished.
                else
                    NEXT_BLT_STATE <= T3_RD_DEST;
                end if;
            -- The complete data processing delay of the BLITTER core is exactly one clock
            -- cycle. Therefore there is no need for an extra delay between reading and
            -- writing the modified video data.
            when T3_WR =>
                if CYC_END = true then
                    NEXT_BLT_STATE <= T3_CHECK; -- Write cycle finished.
                else
                    NEXT_BLT_STATE <= T3_WR;
                end if;
            when T3_CHECK =>
                if HOG_STOP = '1' or BLT_BSY = '0' then
                    NEXT_BLT_STATE <= IDLE; -- BLITTER finished.
                elsif POST_FLUSH = '1' then
                    NEXT_BLT_STATE <= T3_RD_DEST; -- Post-flush source data.
                else
                    NEXT_BLT_STATE <= T3_RD_SRC_1; -- Go on, cycle not finished.
                end if;
        end case;
    end process BLT_STATE_LOGIC;

    BUS_REQUEST: process
    begin
        wait until CLK = '1' and CLK' event;
        -- BUSYn is used to distinguish between internal or external bus requests.
        if BUSY = '1' and BGIn = '0' and BGACK_INn = '1' and AS_INn = '1' and DTACKn = '1' then
            BUS_FREE <= true;
        else
            BUS_FREE <= false;
        end if;
    end process BUS_REQUEST;

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
            case BLT_STATE is
                when T1_RD_DEST | T1_WR | T2_RD_DEST | T2_RD_SRC_1 | 
                     T2_RD_SRC_2 | T2_WR | T3_RD_SRC_1 | T3_RD_SRC_2 | T3_RD_DEST | T3_WR =>
                    if BMODE = '0' and SLICE_CNT = "010" then
                        SLICE_CNT <= "000"; -- 68030 timing.
                    elsif SLICE_CNT = "011" then
                        SLICE_CNT <= "000"; -- 68000 timing.
                    elsif WAITSTATES = '0' then
                        SLICE_CNT <= SLICE_CNT + '1';
                    end if;
                when T1_CHECK | T2_CHECK | T3_CHECK =>
                    if NEXT_BLT_STATE = IDLE then
                        SLICE_CNT <= "111";
                    elsif POST_FLUSH = '1' then
                        SLICE_CNT <= "000";
                    else -- Skip the wasted cycles spent in XX_CHECK state.
                        SLICE_CNT <= "001";
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

    CYC_END <= true when T_SLICE = S5 and BMODE = '0' else
               true when T_SLICE = S7 else false;

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
    
    DATA_EN <= '1' when BMODE = '1' and (T_SLICE = S3 or T_SLICE = S4 or T_SLICE = S5 or T_SLICE = S6 or T_SLICE = S7) else
               '1' when BMODE = '0' and (T_SLICE = S2 or T_SLICE = S3 or T_SLICE = S4 or T_SLICE = S5)  else '0';
    
    ADDRESS_EN <= '0' when T_SLICE = IDLE or T_SLICE = S0 else '1';
end architecture BEHAVIOR;
