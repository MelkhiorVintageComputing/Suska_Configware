------------------------------------------------------------------------
----                                                                ----
---- ATARI Falcon COMBEL compatible IP Core                         ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Atari's TTSCU.                      ----
----                                                                ----
----                                                                ----
---- Author(s):                                                     ----
----   Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2025... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K25A 20250620
--   Initial release.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity TTSCU is
    port (
        -- System and core control:
        RESET                   : in std_logic;
        CLK                     : in std_logic;

        -- Adress and data bus:
        ADR                     : in std_logic_vector(31 downto 0);
        ASn                     : in std_logic;
        FC                      : in std_logic_vector(2 downto 0);

        DATA_IN                 : in std_logic_vector(7 downto 0);
        DATA_OUT                : out std_logic_vector(7 downto 0);
        DATA_EN                 : buffer std_logic;

        -- Bus control:
        RWn                     : in std_logic;
        LDSn                    : in std_logic;
        SIZE                    : in std_logic_vector(1 downto 0);
        DTACKn                  : out std_logic;
        BERRn                   : out std_logic;

        FPUn                    : out std_logic;
        IOCS1n                  : out std_logic;
        IOCS2n                  : out std_logic;
        MFP1n                   : out std_logic;
        MFP2n                   : out std_logic;

        AVECn                   : out std_logic;
        IPLn                    : out std_logic_vector(2 downto 0);
        IACK5n                  : out std_logic;
        IACK6n                  : out std_logic;

        SYSIn                   : out std_logic; -- System interrupt.
        SIRQn                   : out std_logic; -- Software interrupt.

        SIR7n                   : in std_logic;
        SIR6n                   : in std_logic;
        SIR5n                   : in std_logic;
        SIR3n                   : in std_logic;

        HSYNCn                  : in std_logic;
        VSYNCn                  : in std_logic;

        BIRn                    : in std_logic_vector(7 downto 1)
    );
end entity TTSCU;

architecture BEHAVIOUR of TTSCU is
signal SYS_MASK         : std_logic_vector(7 downto 1);
signal SYS_STAT         : std_logic_vector(7 downto 1);
signal VME_MASK         : std_logic_vector(7 downto 1);
signal VME_STAT         : std_logic_vector(7 downto 1);
signal SYS_INT          : std_logic;
signal VME_INT          : std_logic;
signal SCU_GP1          : std_logic_vector(7 downto 0);
signal SCU_GP2          : std_logic_vector(7 downto 0);
signal SU               : boolean; -- Superuser.
signal US               : boolean; -- Normal user.
begin
    SU <= true when FC = "101" or FC = "110" else false; -- Superuser mode.
    US <= true when FC = "001" or FC = "010" else false; -- User mode.

    SCU_REGISTER: process
    variable VSYNC_TMPn : std_logic;
    variable HSYNC_TMPn : std_logic;    
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            SYS_MASK <= (others => '0');
            VME_MASK <= (others => '0');
            SCU_GP1 <= (others => '0');
            SCU_GP2 <= (others => '0');
            SYS_INT <= '0';
            VME_INT <= '0';
        end if;

        if ASn = '0' and ADR = x"FFFF8E01" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '0' then
            SYS_MASK <= DATA_IN(7 downto 1);
        elsif ASn = '0' and ADR = x"FFFF8E05" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '0' then
            SYS_INT <= DATA_IN(0);
        elsif ASn = '0' and ADR = x"FFFF8E07" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '0' then
            VME_INT <= DATA_IN(0);
        elsif ASn = '0' and ADR = x"FFFF8E09" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '0' then
            SCU_GP1 <= DATA_IN;
        elsif ASn = '0' and ADR = x"FFFF8E0B" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '0' then
            SCU_GP2 <= DATA_IN;
        elsif ASn = '0' and ADR = x"FFFF8E0D" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '0' then
            VME_MASK <= DATA_IN(7 downto 1);
        end if;

        if ASn = '0' and ADR = x"FFFF8E01" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' then
            SYS_STAT <= (others => '0');
        elsif ASn = '0' and ADR = x"FFFF8E0F" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' then
            VME_STAT <= (others => '0');
        end if;

        SYS_STAT(7) <= SIR7n;
        SYS_STAT(6) <= SIR6n;
        SYS_STAT(5) <= SIR5n;

        if HSYNC_TMPn = '1' and HSYNCn = '0' then -- Falling edge.
            SYS_STAT(4) <= '1';
        end if;

        SYS_STAT(3) <= SIR3n;

        if VSYNC_TMPn = '1' and VSYNCn = '0' then -- Falling edge.
            SYS_STAT(2) <= '1';
        end if;

        if ASn = '0' and ADR = x"FFFF8E05" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '0' and SYS_INT = '0' and DATA_IN(0) = '1' then
            SYS_STAT(1) <= '1'; -- SYS_INT.
        end if;

        VME_STAT <= BIRn;

        if ASn = '0' and ADR = x"FFFF8E07" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '0' and VME_INT = '0' and DATA_IN(0) = '1' then
            VME_STAT(3) <= '1'; -- VME_INT.
        end if;

        VSYNC_TMPn := VSYNCn;
        HSYNC_TMPn := HSYNCn;
    end process SCU_REGISTER;

    DATA_OUT <= SYS_MASK & '0' when ASn = '0' and ADR = x"FFFF8E01" and LDSn = '0' and SIZE = "01" else
                SYS_STAT & '0' when ASn = '0' and ADR = x"FFFF8E03" and LDSn = '0' and SIZE = "01" else
                "0000000" & SYS_INT when ASn = '0' and ADR = x"FFFF8E05" and LDSn = '0' and SIZE = "01" else
                "0000000" & VME_INT when ASn = '0' and ADR = x"FFFF8E07" and LDSn = '0' and SIZE = "01" else
                SCU_GP1 when ASn = '0' and ADR = x"FFFF8E09" and LDSn = '0' and SIZE = "01" else
                SCU_GP2 when ASn = '0' and ADR = x"FFFF8E0B" and LDSn = '0' and SIZE = "01" else
                VME_MASK & '0' when ASn = '0' and ADR = x"FFFF8E0D" and LDSn = '0' and SIZE = "01" else
                VME_STAT & '0'; -- when ASn = '0' and ADR = x"FFFF8E0F" and LDSn = '0' and SIZE = "01";

    DATA_EN <= '1' when ASn = '0' and ADR = x"FFFF8E01" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else
               '1' when ASn = '0' and ADR = x"FFFF8E03" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else
               '1' when ASn = '0' and ADR = x"FFFF8E05" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else
               '1' when ASn = '0' and ADR = x"FFFF8E07" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else
               '1' when ASn = '0' and ADR = x"FFFF8E09" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else
               '1' when ASn = '0' and ADR = x"FFFF8E0B" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else
               '1' when ASn = '0' and ADR = x"FFFF8E0D" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else
               '1' when ASn = '0' and ADR = x"FFFF8E0F" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else '0';

    DTACKn <= '0' when ASn = '0' and ADR = x"FFFF8E01" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else
              '0' when ASn = '0' and ADR = x"FFFF8E03" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else
              '0' when ASn = '0' and ADR = x"FFFF8E05" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else
              '0' when ASn = '0' and ADR = x"FFFF8E07" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else
              '0' when ASn = '0' and ADR = x"FFFF8E09" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else
              '0' when ASn = '0' and ADR = x"FFFF8E0B" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else
              '0' when ASn = '0' and ADR = x"FFFF8E0D" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else
              '0' when ASn = '0' and ADR = x"FFFF8E0F" and (SU = true or US = true) and LDSn = '0' and SIZE = "01" and RWn = '1' else
              '0' when ASn = '0' and ADR = x"FFFF8E01" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '0' else
              '0' when ASn = '0' and ADR = x"FFFF8E05" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '0' else
              '0' when ASn = '0' and ADR = x"FFFF8E07" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '0' else
              '0' when ASn = '0' and ADR = x"FFFF8E09" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '0' else
              '0' when ASn = '0' and ADR = x"FFFF8E0B" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '0' else
              '0' when ASn = '0' and ADR = x"FFFF8E0D" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '0' else '1';

    IPLn <= "000" when VME_MASK(7) = '1' and VME_STAT(7) = '1' else -- Level 7.
            "000" when SYS_MASK(7) = '1' and SYS_STAT(7) = '1' else -- Level 7.
            "001" when VME_MASK(6) = '1' and VME_STAT(6) = '1' else -- Level 6.
            "001" when SYS_MASK(6) = '1' and SYS_STAT(6) = '1' else -- Level 6.
            "010" when VME_MASK(5) = '1' and VME_STAT(5) = '1' else -- Level 5.
            "010" when SYS_MASK(5) = '1' and SYS_STAT(5) = '1' else -- Level 5.
            "011" when VME_MASK(4) = '1' and VME_STAT(4) = '1' else -- Level 4.
            "011" when SYS_MASK(4) = '1' and SYS_STAT(4) = '1' else -- Level 4.
            "100" when VME_MASK(3) = '1' and VME_STAT(3) = '1' else -- Level 3.
            "100" when SYS_MASK(3) = '1' and SYS_STAT(3) = '1' else -- Level 3.
            "101" when VME_MASK(2) = '1' and VME_STAT(2) = '1' else -- Level 2.
            "101" when SYS_MASK(2) = '1' and SYS_STAT(2) = '1' else -- Level 2.
            "110" when VME_MASK(1) = '1' and VME_STAT(1) = '1' else -- Level 1.
            "110" when SYS_MASK(1) = '1' and SYS_STAT(1) = '1' else "111"; -- Level 1.

    -- Software interrupts:
    SIRQn <= '0' when ASn = '0' and ADR = x"FFFF8E05" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '1' and DATA_IN(0) = '1' else
             '0' when ASn = '0' and ADR = x"FFFF8E07" and SU = true and LDSn = '0' and SIZE = "01" and RWn = '1' and DATA_IN(0) = '1' else '1';

    SYSIn <= '0' when SYS_MASK(7) = '1' and SYS_STAT(7) = '1' and (VME_MASK(7) = '0' or VME_STAT(7) = '0') else -- VME has priority over SYS.
             '0' when SYS_MASK(6) = '1' and SYS_STAT(6) = '1' and (VME_MASK(6) = '0' or VME_STAT(6) = '0') else -- VME has priority over SYS.
             '0' when SYS_MASK(5) = '1' and SYS_STAT(5) = '1' and (VME_MASK(5) = '0' or VME_STAT(5) = '0') else -- VME has priority over SYS.
             '0' when SYS_MASK(4) = '1' and SYS_STAT(4) = '1' and (VME_MASK(4) = '0' or VME_STAT(4) = '0') else -- VME has priority over SYS.
             '0' when SYS_MASK(3) = '1' and SYS_STAT(3) = '1' and (VME_MASK(3) = '0' or VME_STAT(3) = '0') else -- VME has priority over SYS.
             '0' when SYS_MASK(2) = '1' and SYS_STAT(2) = '1' and (VME_MASK(2) = '0' or VME_STAT(2) = '0') else '1'; -- VME has priority over SYS.

    AVECn <= '0' when ASn = '0' and FC = "111" and ADR(19 downto 16) = x"F" and SYS_MASK(7) = '1' and SYS_STAT(7) = '1' and (VME_MASK(7) = '0' or VME_STAT(7) = '0') else -- EINT7, VME has priority over SYS.
             '0' when ASn = '0' and FC = "111" and ADR(19 downto 16) = x"F" and SYS_MASK(4) = '1' and SYS_STAT(4) = '1' and (VME_MASK(4) = '0' or VME_STAT(4) = '0') else -- HSYNC, VME has priority over SYS.
             '0' when ASn = '0' and FC = "111" and ADR(19 downto 16) = x"F" and SYS_MASK(2) = '1' and SYS_STAT(2) = '1' and (VME_MASK(2) = '0' or VME_STAT(2) = '0') else -- VSYNC, VME has priority over SYS.
             '0' when ASn = '0' and FC = "111" and ADR(19 downto 16) = x"F" and VME_MASK(3) = '1' and VME_STAT(3) = '1' else '1';

    IACK6n <= '0' when ASn = '0' and FC = "111" and ADR(19 downto 16) = x"F" and ADR(3 downto 1) = "110" else '1'; -- MFP
    IACK5n <= '0' when ASn = '0' and FC = "111" and ADR(19 downto 16) = x"F" and ADR(3 downto 1) = "101" else '1'; -- SCC

    -- Floating point coprocessor:
    FPUn <= '0' when ASn = '0' and ADR(31 downto 4) = x"FFFFFA4" and SU = true else
            '0' when ASn = '0' and ADR(31 downto 4) = x"FFFFFA5" and SU = true else '1';

    -- Select MFP (8 bit access), write access in superuser mode:
    MFP1n <= '0' when ASn = '0' and ADR >= x"FFFFFA00" and LDSn = '0' and SIZE = "01" and ADR < x"FFFFFA40" and RWn = '0' and SU = true else
             '0' when ASn = '0' and ADR >= x"FFFFFA00" and LDSn = '0' and SIZE = "01" and ADR < x"FFFFFA40" and RWn = '1' and (SU = true or US = true) else '1';

    MFP2n <= '0' when ASn = '0' and ADR >= x"FFFFFA80" and LDSn = '0' and SIZE = "01" and ADR < x"FFFFFAB0" and RWn = '0' and SU = true else
             '0' when ASn = '0' and ADR >= x"FFFFFA80" and LDSn = '0' and SIZE = "01" and ADR < x"FFFFFAB0" and RWn = '1' and (SU = true or US = true) else '1';

    IOCS1n <= '1'; -- Sorry, no information about the address.
    IOCS2n <= '1'; -- Sorry, no information about the address.

    ERRHANDLER: process
    variable WATCHDOG: std_logic_vector(6 downto 0); -- 7 bit -> 128 steps.
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            WATCHDOG := (others =>'1'); -- Load the counter.
        -- After DTACKn is released by the target, the bus master deasserts
        -- ASn and herewith reloads the watchdog.
        elsif ASn = '1' then
            WATCHDOG := (others =>'1'); -- Load the counter.
        elsif WATCHDOG > "0000000" then
            WATCHDOG := WATCHDOG - '1';
        end if;

        -- Error released if there is no response from a target after
        -- 128 clock cycles.
        if WATCHDOG = "0000000" then
            BERRn <= '0'; -- No answer after 128 clock periods after request.
        else
            BERRn <= '1';
        end if;
    end process ERRHANDLER;
end architecture BEHAVIOUR;
