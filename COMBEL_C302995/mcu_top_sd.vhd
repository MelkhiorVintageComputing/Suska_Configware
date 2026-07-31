------------------------------------------------------------------------
----                                                                ----
---- SD-RAM memory control unit (MCU).                              ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- This MCU is an enhanced version of the original ATARI MCU to   ----
---- meet the requirements for modern SD-RAM chips. In detail,      ----
---- this MCU is well suited for the Alliance Memory device type    ----
---- AS4C16M32C synchronous DRAM or compatible. This controller     ----
---- meets the Atari Falcon COMBEL MCU. In addition it features     ----
---- burst mode operation to handle the required data rate of the   ----
---- Falcon VIDEL. Due this feature, this IP core handles all Falcon----
---- video resolutions without an impact to CPU speed. Generally    ----
---- spoken this outperforms the original Atari Falcon hardware.    ----
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
--   Initial release.
-- Revision 2K21A 20211224 WF
--   This is a complete code lifting with several changes and bug fixes.
--   Implemented additional RAM of 48MB.
-- Revision 2K22A 20221224 WF
--   The MCU has now fully 32 bit adress bus width to meet the requirements to handle misaligned long RAM access.
--

library work;
use work.COMBEL_PKG.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity MCU_TOP is
    generic(RAM_16              : boolean := false); -- Set true, if we have a 16 bit RAM data bus, false for 32 bit.
    port(
        CLK                     : in std_logic; -- System clock, 32 MHz.

        SYS_RESET_INn           : in std_logic;
        SYS_RESET_OUTn          : out std_logic;
        RESET                   : in std_logic;

        ASn                     : in std_logic; -- Bus control signals.
        LDSn                    : in std_logic; -- Bus control signals.
        UDSn                    : in std_logic; -- Bus control signals.
        RWn                     : in std_logic; -- Bus control signals.

        ADR                     : in std_logic_vector(31 downto 0); -- The Falcon address bus.

        RAMn                    : in std_logic;

        VREQ                    : in std_logic;
        EVENn_ODD               : in std_logic;

        RDATn                   : out std_logic; -- Buffer control.
        WDATn                   : out std_logic; -- Buffer control.
        RAMH                    : out std_logic; -- Buffer control.

        VINT                    : in std_logic; -- Vertical sync.

        VIDEO_BASE_HIWORD_RS    : in std_logic;
        VIDEO_BASE_LOWORD_RS    : in std_logic;
        VIDEO_COUNT_HIWORD_RS   : in std_logic;
        VIDEO_COUNT_LOWORD_RS   : in std_logic;

        VIDEO_BASE_HI_RS        : in std_logic;
        VIDEO_BASE_MID_RS       : in std_logic;
        VIDEO_BASE_LOW_RS       : in std_logic;
        VIDEO_COUNT_HI_RS       : in std_logic;
        VIDEO_COUNT_MID_RS      : in std_logic;
        VIDEO_COUNT_LOW_RS      : in std_logic;
        R8006_SHADOW_RS         : in std_logic;
        SHMOD_ST_SHADOW_RS      : in std_logic;
        VMODE_SHADOW_RS         : in std_logic;
        MEM_CONFIG_RS           : in std_logic;
        LINE_OFFS_RS            : in std_logic;
        LINE_WIDTH_RS           : in std_logic;

        DTACKn                  : out std_logic; -- Data acknowledge signal.

        DATA_IN                 : in std_logic_vector(15 downto 0);
        DATA_OUT                : out std_logic_vector(15 downto 0);
        DATA_EN                 : out std_logic;

        -- RAM interface:
        CKE                     : out std_logic; -- RAM clock enable.
        CSn                     : out std_logic; -- RAM chip enable.
        BA                      : out std_logic_vector(1 downto 0); -- SD-RAM bank select.
        MAD                     : out std_logic_vector(12 downto 0); -- SD-RAM address bus.
        MAD_32                  : out std_logic_vector(31 downto 2); -- SD-RAM address bus.
        WEn                     : out std_logic;
        RASn                    : out std_logic; -- This is for 512Mb chips.
        CASn                    : out std_logic; -- This is for 512Mb chips.
        RAS0n                   : out std_logic; -- This is for 256Mb chips.
        CAS0n                   : out std_logic; -- This is for 256Mb chips.
        RAS1n                   : out std_logic; -- This is for 256Mb chips.
        CAS1n                   : out std_logic; -- This is for 256Mb chips.
        RAM_16MB                : in std_logic; -- RAM size.
        BUS_WIDTH               : in RAMWIDTH_TYPE; -- RAM bus width.
        SIZE                    : in std_logic_vector(1 downto 0); -- Data size control.
        DQMn                    : out std_logic_vector(3 downto 0); -- SD-RAM output buffer controls.

        VLDn                    : out std_logic -- Video data load signal.
    );
end entity MCU_TOP;

architecture STRUCTURE of MCU_TOP is
signal DATA_OUT_CTRL        : std_logic_vector(7 downto 0);
signal DATA_OUT_VCNT        : std_logic_vector(15 downto 0);
signal DATA_EN_CTRL         : std_logic;
signal DATA_EN_VCNT         : std_logic;

signal RAS0n_I              : std_logic;
signal RAS1n_I              : std_logic;
signal CAS0n_I              : std_logic;
signal CAS1n_I              : std_logic;

signal WE_CTRLn             : std_logic;

signal VIDEO_CNT_EN         : std_logic;
signal VIDEO_CNT_LOAD       : std_logic;

signal MADRSEL_I            : MADR_TYPE;

signal RAM_ADR_I            : std_logic_vector(12 downto 0);
signal M_ADR_I              : std_logic_vector(25 downto 1);
signal VIDEO_ADR_I          : std_logic_vector(31 downto 1);

signal MCU_PHASE            : MCU_PHASE_TYPE;

signal REF_EN_I             : std_logic;

signal SOUND_CTRL_CS_I              : std_logic;
signal SOUND_FRAME_START_HI_CS_I    : std_logic;
signal SOUND_FRAME_START_MID_CS_I   : std_logic;
signal SOUND_FRAME_START_LOW_CS_I   : std_logic;
signal SOUND_FRAME_ADR_HI_CS_I      : std_logic;
signal SOUND_FRAME_ADR_MID_CS_I     : std_logic;
signal SOUND_FRAME_ADR_LOW_CS_I     : std_logic;
signal SOUND_FRAME_END_HI_CS_I      : std_logic;
signal SOUND_FRAME_END_MID_CS_I     : std_logic;
signal SOUND_FRAME_END_LOW_CS_I     : std_logic;

signal INIT_STATE                   : integer range 0 to 1023;

begin
    P_SDINIT: process(SYS_RESET_INn, CLK)
    -- This process provides the control for the initialisation of the SD-RAM.
    -- Since it is clocked by a 32MHz clock, the period is 31.25ns. There is a
    -- predivider, so that the INIT_STATE increments every eigths clock, means
    -- every 250ns. To meet the requirement of a 200us idle period, the INIT_STATE
    -- requires a value of 800. All other init steps work on the 250ns time step.
    -- The initialisation of the command respective to the INIT_STATE works as
    -- follows:
        -- <= 800 : IDLE.
        -- 801    : PRECHARGE_ALL command.
        -- 802    : NOP command.
        -- 803    : AUTO_REFRESH command.
        -- 804    : NOP command.
        -- 805    : AUTO_REFRESH command.
        -- 806    : NOP command.
        -- 807    : AUTO_REFRESH command.
        -- 808    : NOP command.
        -- 809    : AUTO_REFRESH command.
        -- 810    : NOP command.
        -- 811    : AUTO_REFRESH command.
        -- 812    : NOP command.
        -- 813    : AUTO_REFRESH command.
        -- 814    : NOP command.
        -- 815    : AUTO_REFRESH command.
        -- 816    : NOP command.
        -- 817    : AUTO_REFRESH command.
        -- 818    : NOP command.
        -- 819    : Write to the mode register.
        -- 820    : NOP command.
        -- 821    : Stay in this mode, normal SD-RAM operation.
    variable TMP : std_logic_vector(2 downto 0);
    begin
        if SYS_RESET_INn = '0' then
            INIT_STATE <= 0;
            TMP := "000"; -- Init ready, do nothing.
        elsif CLK = '1' and CLK' event then
            if init_STATE < 800 and TMP = "111" then
                INIT_STATE <= INIT_STATE + 1;
                TMP := "000";
            elsif INIT_STATE < 821 then
                INIT_STATE <= INIT_STATE + 1;
            else
                TMP := TMP + '1';
            end if;
        end if;
    end process P_SDINIT;

    SYS_RESET_OUTn <= '1' when INIT_STATE = 821 else '0'; -- This reset controls the CPU.

    M_ADR_I <= ADR(25 downto 1) when MCU_PHASE = RAM else
               "00" & VIDEO_ADR_I(23 downto 1) when MCU_PHASE = VIDEO else (others => '0');

    -- Select column and row with MADRSEL_I:
    RAM_ADR_I <= M_ADR_I(23 downto 11) when MADRSEL_I = MEM_HI_ADR and RAM_16 = false else
                 x"0" & M_ADR_I(10 downto 2) when RAM_16 = false else
                 M_ADR_I(22 downto 10) when MADRSEL_I = MEM_HI_ADR else x"0" & M_ADR_I(9 downto 1); -- 16 bit wide RAM.

    BA <= M_ADR_I(25 downto 24) when RAM_16 = false else M_ADR_I(24 downto 23); -- In each bank we use 4Mx32 from the 16Mx32 or 4Mx16 from the 16M*16 SDRAM.

    MAD <= --'0' & x"220" when INIT_STATE = 819 else -- Command: CAS latency = 2, single location access, burst length = 1.
           '0' & x"221" when INIT_STATE = 819 else -- Command: busrt length = 2, burts type sequential, CAS latency = 2, write burst = 1.
           '0' & x"400" when INIT_STATE /= 821 else -- Used for PRECHARGE_ALL (A10 must be high).
           RAM_ADR_I when RAS1n_I = '0' or RAS0n_I = '0' else -- Row address programming.
           x"2" & RAM_ADR_I(8 downto 0); -- Select auto precharge and column address.

    MAD_32 <= ADR(31 downto 2) when MCU_PHASE = RAM else VIDEO_ADR_I(31 downto 2); -- This is the 4GB linear memory address (LONG32).

    CSn <= '0';
    CKE <= '1';

    WEn <= '0' when INIT_STATE = 801 else -- PRECHARGE_ALL.
           '0' when INIT_STATE = 819 else -- Write mode register.
           '0' when WE_CTRLn = '0' and INIT_STATE = 821 else '1';

    RAS0n <= '0' when INIT_STATE = 801 else -- PRECHARGE_ALL.
             '0' when INIT_STATE = 803 else -- Auto refresh.
             '0' when INIT_STATE = 805 else -- Auto refresh.
             '0' when INIT_STATE = 807 else -- Auto refresh.
             '0' when INIT_STATE = 809 else -- Auto refresh.
             '0' when INIT_STATE = 811 else -- Auto refresh.
             '0' when INIT_STATE = 813 else -- Auto refresh.
             '0' when INIT_STATE = 815 else -- Auto refresh.
             '0' when INIT_STATE = 817 else -- Auto refresh.
             '0' when INIT_STATE = 819 else -- Write mode register.
             '0' when REF_EN_I = '1' and INIT_STATE = 821 else -- Auto refresh.
             '0' when RAS0n_I = '0' and INIT_STATE = 821 else '1';

    RAS1n <= '0' when INIT_STATE = 801 else -- PRECHARGE_ALL.
             '0' when INIT_STATE = 803 else -- Auto refresh.
             '0' when INIT_STATE = 805 else -- Auto refresh.
             '0' when INIT_STATE = 807 else -- Auto refresh.
             '0' when INIT_STATE = 809 else -- Auto refresh.
             '0' when INIT_STATE = 811 else -- Auto refresh.
             '0' when INIT_STATE = 813 else -- Auto refresh.
             '0' when INIT_STATE = 815 else -- Auto refresh.
             '0' when INIT_STATE = 817 else -- Auto refresh.
             '0' when INIT_STATE = 819 else -- Write mode register.
             '0' when REF_EN_I = '1' and INIT_STATE = 821 else -- Auto refresh.
             '0' when RAS1n_I = '0' and INIT_STATE = 821 else '1';

    RASn <= '0' when INIT_STATE = 801 else -- PRECHARGE_ALL.
            '0' when INIT_STATE = 803 else -- Auto refresh.
            '0' when INIT_STATE = 805 else -- Auto refresh.
            '0' when INIT_STATE = 807 else -- Auto refresh.
            '0' when INIT_STATE = 809 else -- Auto refresh.
            '0' when INIT_STATE = 811 else -- Auto refresh.
            '0' when INIT_STATE = 813 else -- Auto refresh.
            '0' when INIT_STATE = 815 else -- Auto refresh.
            '0' when INIT_STATE = 817 else -- Auto refresh.
            '0' when INIT_STATE = 819 else -- Write mode register.
            '0' when REF_EN_I = '1' and INIT_STATE = 821 else -- Auto refresh.
            '0' when RAS0n_I = '0' and INIT_STATE = 821 else
            '0' when RAS1n_I = '0' and INIT_STATE = 821 else '1';

    CAS0n <= '0' when INIT_STATE = 803 else -- Auto refresh.
             '0' when INIT_STATE = 805 else -- Auto refresh.
             '0' when INIT_STATE = 807 else -- Auto refresh.
             '0' when INIT_STATE = 809 else -- Auto refresh.
             '0' when INIT_STATE = 811 else -- Auto refresh.
             '0' when INIT_STATE = 813 else -- Auto refresh.
             '0' when INIT_STATE = 815 else -- Auto refresh.
             '0' when INIT_STATE = 817 else -- Auto refresh.
             '0' when INIT_STATE = 819 else -- Write mode register.
             '0' when REF_EN_I = '1' and INIT_STATE = 821 else -- Auto refresh.
             '0' when CAS0n_I = '0' and INIT_STATE = 821 else '1';

    CAS1n <= '0' when INIT_STATE = 803 else -- Auto refresh.
             '0' when INIT_STATE = 805 else -- Auto refresh.
             '0' when INIT_STATE = 807 else -- Auto refresh.
             '0' when INIT_STATE = 809 else -- Auto refresh.
             '0' when INIT_STATE = 811 else -- Auto refresh.
             '0' when INIT_STATE = 813 else -- Auto refresh.
             '0' when INIT_STATE = 815 else -- Auto refresh.
             '0' when INIT_STATE = 817 else -- Auto refresh.
             '0' when INIT_STATE = 819 else -- Write mode register.
             '0' when REF_EN_I = '1' and INIT_STATE = 821 else -- Auto refresh.
             '0' when CAS1n_I = '0' and INIT_STATE = 821 else '1';

    CASn <= '0' when INIT_STATE = 803 else -- Auto refresh.
            '0' when INIT_STATE = 805 else -- Auto refresh.
            '0' when INIT_STATE = 807 else -- Auto refresh.
            '0' when INIT_STATE = 809 else -- Auto refresh.
            '0' when INIT_STATE = 811 else -- Auto refresh.
            '0' when INIT_STATE = 813 else -- Auto refresh.
            '0' when INIT_STATE = 815 else -- Auto refresh.
            '0' when INIT_STATE = 817 else -- Auto refresh.
            '0' when INIT_STATE = 819 else -- Write mode register.
            '0' when REF_EN_I = '1' and INIT_STATE = 821 else -- Auto refresh.
            '0' when CAS0n_I = '0' and INIT_STATE = 821 else
            '0' when CAS1n_I = '0' and INIT_STATE = 821 else '1';

    -- SD-RAM output buffer controls.
    -- Be aware: we need a 32bit wide RAM. The BUS_WIDTH is used to control the access between RAM and 68K30 which
    -- is selectable via BUS_WIDTH in LONG, WORD or BYTE portions. This feature is for 68K30 bus controller debugging purpose.
    DQMn <= "1111" when INIT_STATE /= 821 else
            "0000" when MCU_PHASE = VIDEO else -- 32 bit wide.
            "0000" when RWn = '1' else -- During read from RAM all outputs enabled to feed any RAM data multiplexers correctly.
            "0000" when BUS_WIDTH = L32 and SIZE = "00" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "00" else -- Long.
            "1000" when BUS_WIDTH = L32 and SIZE = "00" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "01" else -- Long.
            "1100" when BUS_WIDTH = L32 and SIZE = "00" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "10" else -- Long.
            "1110" when BUS_WIDTH = L32 and SIZE = "00" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "11" else -- Long.
            "0001" when BUS_WIDTH = L32 and SIZE = "11" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "00" else -- Three bytes.
            "1000" when BUS_WIDTH = L32 and SIZE = "11" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "01" else -- Three bytes.
            "1100" when BUS_WIDTH = L32 and SIZE = "11" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "10" else -- Three bytes.
            "1110" when BUS_WIDTH = L32 and SIZE = "11" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "11" else -- Three bytes.
            "0011" when BUS_WIDTH = L32 and SIZE = "10" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "00" else -- Word.
            "1001" when BUS_WIDTH = L32 and SIZE = "10" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "01" else -- Word.
            "1100" when BUS_WIDTH = L32 and SIZE = "10" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "10" else -- Word.
            "1110" when BUS_WIDTH = L32 and SIZE = "10" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "11" else -- Word.
            "0111" when BUS_WIDTH = L32 and SIZE = "01" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "00" else -- Byte.
            "1011" when BUS_WIDTH = L32 and SIZE = "01" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "01" else -- Byte.
            "1101" when BUS_WIDTH = L32 and SIZE = "01" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "10" else -- Byte.
            "1110" when BUS_WIDTH = L32 and SIZE = "01" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "11" else -- Byte.
            "0011" when BUS_WIDTH = W16 and SIZE /= "01" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "00" else -- Long, three bytes or word.
            "1001" when BUS_WIDTH = W16 and SIZE /= "01" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "01" else -- Long, three bytes or word.
            "1100" when BUS_WIDTH = W16 and SIZE /= "01" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "10" else -- Long, three bytes or word.
            "1110" when BUS_WIDTH = W16 and SIZE /= "01" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "11" else -- Long, three bytes or word.
            "0111" when BUS_WIDTH = W16 and SIZE = "01" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "00" else -- Byte.
            "1011" when BUS_WIDTH = W16 and SIZE = "01" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "01" else -- Byte.
            "1101" when BUS_WIDTH = W16 and SIZE = "01" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "10" else -- Byte.
            "1110" when BUS_WIDTH = W16 and SIZE = "01" and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "11" else -- Byte.
            "0111" when BUS_WIDTH = B8 and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "00" else -- Byte.
            "1011" when BUS_WIDTH = B8 and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "01" else -- Byte.
            "1101" when BUS_WIDTH = B8 and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "10" else -- Byte.
            "1110"; -- when BUS_WIDTH = B8 and (CAS0n_I = '0' or CAS1n_I = '0') and ADR(1 downto 0) = "11" else -- Byte.

    DATA_EN <= '0' when INIT_STATE /= 821  else
               DATA_EN_CTRL or DATA_EN_VCNT;

    DATA_OUT <= DATA_OUT_CTRL & DATA_OUT_CTRL when DATA_EN_CTRL = '1' else
    DATA_OUT_VCNT when DATA_EN_VCNT = '1' else (others => '0');

    I_CONTROL: MCU_CTRL
        port map(
            CLK                     => CLK,
            RESET                   => RESET,

            LDSn                    => LDSn,
            UDSn                    => UDSn,
            RWn                     => RWn,

            M_ADR                   => M_ADR_I,

            RAMn                    => RAMn,

            MEM_CONFIG_RS           => MEM_CONFIG_RS,
            RAM_16MB                => RAM_16MB,

            MCU_PHASE               => MCU_PHASE,

            VINT                    => VINT,
            VREQ                    => VREQ,
            VLDn                    => VLDn,

            RAS0n                   => RAS0n_I,
            RAS1n                   => RAS1n_I,

            CAS0n                   => CAS0n_I,
            --CAS0Ln                =>,
            --CAS0Hn                =>,

            CAS1n                   => CAS1n_I,
            --CAS1Ln                =>,
            --CAS1Hn                =>,

            WEn                     => WE_CTRLn,

            RDATn                   => RDATn,
            WDATn                   => WDATn,
            RAMH                    => RAMH,

            REF_EN                  => REF_EN_I,
            VIDEO_CNT_EN            => VIDEO_CNT_EN,
            VIDEO_CNT_LOAD          => VIDEO_CNT_LOAD,
            MADRSEL                 => MADRSEL_I,
            DTACKn                  => DTACKn,
            DATA_IN                 => DATA_IN(7 downto 0),
            DATA_OUT                => DATA_OUT_CTRL,
            DATA_EN                 => DATA_EN_CTRL
        );

    I_VIDEO: MCU_VIDEO_COUNTER
        generic map(RAM_16          => RAM_16)
        port map(
            CLK                     => CLK,
            RESET                   => RESET,

            RWn                     => RWn,

            VIDEO_BASE_HIWORD_RS    => VIDEO_BASE_HIWORD_RS,
            VIDEO_BASE_LOWORD_RS    => VIDEO_BASE_LOWORD_RS,
            VIDEO_COUNT_HIWORD_RS   => VIDEO_COUNT_HIWORD_RS,
            VIDEO_COUNT_LOWORD_RS   => VIDEO_COUNT_LOWORD_RS,

            VIDEO_BASE_HI_RS        => VIDEO_BASE_HI_RS,
            VIDEO_BASE_MID_RS       => VIDEO_BASE_MID_RS,
            VIDEO_BASE_LOW_RS       => VIDEO_BASE_LOW_RS,

            VIDEO_COUNT_HI_RS       => VIDEO_COUNT_HI_RS,
            VIDEO_COUNT_MID_RS      => VIDEO_COUNT_MID_RS,
            VIDEO_COUNT_LOW_RS      => VIDEO_COUNT_LOW_RS,

            R8006_SHADOW_RS         => R8006_SHADOW_RS,
            SHMOD_ST_SHADOW_RS      => SHMOD_ST_SHADOW_RS,
            VMODE_SHADOW_RS         => VMODE_SHADOW_RS,

            EVENn_ODD               => EVENn_ODD,
            VIDEO_COUNT_EN          => VIDEO_CNT_EN,
            VIDEO_COUNT_LOAD        => VIDEO_CNT_LOAD,

            LINE_OFFS_RS            => LINE_OFFS_RS,
            LINE_WIDTH_RS           => LINE_WIDTH_RS,

            VIDEO_ADR_OUT           => VIDEO_ADR_I,

            DATA_IN                 => DATA_IN,
            DATA_OUT                => DATA_OUT_VCNT,
            DATA_EN                 => DATA_EN_VCNT
        );
end architecture STRUCTURE;
