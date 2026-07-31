------------------------------------------------------------------------
----                                                                ----
---- ATARI MCU compatible IP Core                                   ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- This entity is part of the memory management controller with   ----
---- all features to reach Atari Falcon compatibility.              ----
---- This controller meets the requirements for SD-RAMs. See the    ----
---- top level file for more information. Video access is burst     ----
---- orientated to meet the requirements of the video bandwidth     ----
---- when VIDEL is operated in true colour- or 8 bitplane modes.    ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2006... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K6A  2006/06/03 WF
--   Initial Release.
-- Revision 2K21A 20211224 WF
--   This is a complete code lifting with several changes and bug fixes.
--

library work;
use work.COMBEL_PKG.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity MCU_CTRL is
    port(
        CLK                     : in std_logic;
        RESET                   : in std_logic;

        LDSn                    : in std_logic; -- Lower data strobe.
        UDSn                    : in std_logic; -- Upper data strobe.
        RWn                     : in std_logic; -- Bus control signals.

        M_ADR                   : in std_logic_vector(25 downto 1); -- Non multiplexed DRAM addresses.

        RAMn                    : in std_logic;

        MEM_CONFIG_RS           : in std_logic; -- Memory config register control.

        MCU_PHASE               : out MCU_PHASE_TYPE;

        VINT                    : in std_logic; -- Vertical sync signal, formerly VSYNCn.
        VREQ                    : in std_logic; -- Formerly this signal was DE.
        VLDn                    : out std_logic; -- Shifter load signal.

        RAS0n                   : out std_logic; -- Memory bank 1 row address strobe.
        CAS0n                   : out std_logic; -- Memory bank 1 column address strobe.
        CAS0Hn                  : out std_logic; -- Memory bank 1 column address strobe.
        CAS0Ln                  : out std_logic; -- Memory bank 1 column address strobe.

        RAS1n                   : out std_logic; -- Memory bank 2 row address strobe.
        CAS1n                   : out std_logic; -- Memory bank 2 column address strobe.
        CAS1Hn                  : out std_logic; -- Memory bank 2 column address strobe.
        CAS1Ln                  : out std_logic; -- Memory bank 2 column address strobe.

        WEn                     : out std_logic; -- Memory write control, low active.

        RDATn                   : out std_logic; -- Buffer control.
        WDATn                   : out std_logic; -- Buffer control.
        RAMH                    : out std_logic; -- Buffer control, formerly LATCHn.

        REF_EN                  : out std_logic; -- Refresh counter enable.

        VIDEO_CNT_EN            : out std_logic; -- Video control.
        VIDEO_CNT_LOAD          : out std_logic; -- Video control.

        MADRSEL                 : out MADR_TYPE; -- Address multiplexer control.

        DTACKn                  : out std_logic; -- Data acknowledge signal.

        DATA_IN                 : in std_logic_vector(7 downto 0);
        DATA_OUT                : out std_logic_vector(7 downto 0);
        DATA_EN                 : out std_logic
    );
end MCU_CTRL;

architecture BEHAVIOR of MCU_CTRL is
type BANKS is (BANK1, BANK0);
type MATRIX_ELEMENTS is array (1 to 11, 0 to 7) of std_logic;
constant TIME_MATRIX : MATRIX_ELEMENTS :=
    (('0','1','1','1','0','1','1','1'),     -- RASn.
     --('1','0','0','1','1','0','0','1'),     -- CASn, no burst timing. 
     ('1','0','0','1','1','0','1','1'),     -- CASn video burst timing.
     ('1','0','0','1','1','1','1','1'),     -- WEn.
     ('0','0','0','0','1','1','1','1'),     -- RDATn.
     ('0','0','0','0','1','1','1','1'),     -- WDATn.
     ('1','1','0','0','1','1','1','1'),     -- RAMH.
     ('1','1','1','1','1','1','1','0'),     -- VLDn.
     ('1','0','1','0','0','0','0','0'),     -- REF_EN.
     ('0','0','0','0','0','0','0','1'),     -- VIDEO_CNT_EN.
     ('1','0','0','0','1','1','1','1'),     -- DTACKn.
     ('1','0','0','0','1','0','0','0'));    -- MADRSEL.
signal MCU_PHASE_I          : MCU_PHASE_TYPE;
signal MADRSEL_I            : std_logic; -- Control signal for the high low data multiplexer.
signal MEMCONFIG            : std_logic_vector(7 downto 0);
signal SLICE_NUMBER         : integer range 0 to 7;
signal BANK_SWITCH          : BANKS;
signal M_ADR_I              : std_logic_vector(25 downto 0);
signal RASn                 : std_logic;
signal CASLn                : std_logic;
signal CASHn                : std_logic;
begin
    MEMCONFIG_REG: process
    -- This is the legacy memory configuration register. It has no effect
    -- in the Falcon hardware and can be used as general purpose register.
    begin
        wait until CLK = '1' and CLK' event;
        if MEM_CONFIG_RS = '1' and RWn = '0' then
            MEMCONFIG <= DATA_IN; -- Write to register.
        end if;
    end process MEMCONFIG_REG;

    -- Read memory config register:
    DATA_OUT <= MEMCONFIG when MEM_CONFIG_RS = '1' and RWn = '1' else (others => '0');
    DATA_EN <= MEM_CONFIG_RS and RWn;

    -- Address control:
    MADRSEL <= MEM_HI_ADR when MADRSEL_I = '1' else MEM_LOW_ADR;
    M_ADR_I <= M_ADR & '0';

    MCU_PHASE <= MCU_PHASE_I;

    BANK_SWITCH <= BANK0 when M_ADR_I < x"2000000" else BANK1; -- 32768 Kbytes in bank 0.

    VIDEO_CNT_LOAD <= '1' when VINT = '1' else '0';

    -- RAM control signals:
    RAS0n <= RASn when BANK_SWITCH = BANK0 else '1';
    RAS1n <= RASn when BANK_SWITCH = BANK1 else '1';
    CAS0n <= CASHn and CASLn when BANK_SWITCH = BANK0 else '1';
    CAS1n <= CASHn and CASLn when BANK_SWITCH = BANK1 else '1';
    CAS0Ln <= CASLn when BANK_SWITCH = BANK0 else '1';
    CAS1Ln <= CASLn when BANK_SWITCH = BANK1 else '1';
    CAS0Hn <= CASHn when BANK_SWITCH = BANK0 else '1';
    CAS1Hn <= CASHn when BANK_SWITCH = BANK1 else '1';

    -- Bus, memory and system control signals:
    RASn <= TIME_MATRIX(1, SLICE_NUMBER) when MCU_PHASE_I = REFRESH or MCU_PHASE_I = RAM or MCU_PHASE_I = VIDEO else '1';
    CASLn <= TIME_MATRIX(2, SLICE_NUMBER) when MCU_PHASE_I = RAM and LDSn = '0' else
             TIME_MATRIX(2, SLICE_NUMBER) when MCU_PHASE_I = VIDEO else '1';
    CASHn <= TIME_MATRIX(2, SLICE_NUMBER) when MCU_PHASE_I = RAM and UDSn = '0' else
             TIME_MATRIX(2, SLICE_NUMBER) when MCU_PHASE_I = VIDEO else '1';
    WEn <= TIME_MATRIX(3, SLICE_NUMBER) when MCU_PHASE_I = RAM and RWn = '0' else '1'; -- Write is valid in RAM mode.

    RDATn <= TIME_MATRIX(4, SLICE_NUMBER) when MCU_PHASE_I = RAM and RWn = '1' else '1';
    WDATn <= TIME_MATRIX(5, SLICE_NUMBER) when MCU_PHASE_I = RAM and RWn = '0' else '1';
    RAMH <= TIME_MATRIX(6, SLICE_NUMBER) when MCU_PHASE_I = RAM else '0';

    VLDn <= TIME_MATRIX(7, SLICE_NUMBER) when MCU_PHASE_I = VIDEO else '1';
    REF_EN <= TIME_MATRIX(8, SLICE_NUMBER) when MCU_PHASE_I = REFRESH else '0';

    VIDEO_CNT_EN <= TIME_MATRIX(9, SLICE_NUMBER) when MCU_PHASE_I = VIDEO else '0'; -- Video data.

    DTACKn <= TIME_MATRIX(10, SLICE_NUMBER) when MCU_PHASE_I = RAM else '1'; -- This is regular RAM access.

    MADRSEL_I <= TIME_MATRIX(11, SLICE_NUMBER);

    MCU_PHASE_SWITCH: process
    -- This memory management controls the access to the RAM. Video has the
    -- highest priority and takes 50% of the possible band width using the 
    -- first half of the Slice counter. The second half the RAM access is 
    -- foreseen for other bus participants such as CPU, DMA or blitter. 
    -- If no bus access takes place here, VIDEO can take over this time slot.
    -- If neither bus access ir required the the REFRESH becomes active to 
    -- keep RAM data alive.
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            MCU_PHASE_I <= REFRESH;
        elsif SLICE_NUMBER = 3 then
            if VREQ = '1' then
                MCU_PHASE_I <= VIDEO;
            else
                MCU_PHASE_I <= IDLE;
            end if;
        elsif SLICE_NUMBER = 7 then
            if RAMn = '0' then
                MCU_PHASE_I <= RAM;
            else
                MCU_PHASE_I <= REFRESH;
            end if;
        end if;
    end process MCU_PHASE_SWITCH;

    TIME_SLICES: process
    -- This is a simple counter for the generation of signal
    -- timing for bus control.
    variable TIME_SLICE_CNT : std_logic_vector(2 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        TIME_SLICE_CNT := TIME_SLICE_CNT + '1';
        SLICE_NUMBER <= conv_integer(TIME_SLICE_CNT);
    end process TIME_SLICES;
end architecture BEHAVIOR;
