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
---- Top level file for use in systems on programmable chips.       ----
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
-- Revision 2K19B  20191224 WF
--   Minor Code cleanups.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity BLITTER_TOP is
    port (
        -- System controls:
        CLK         : in std_logic;
        RESET       : in std_logic;
        AS_INn      : in std_logic;
        AS_OUTn     : out std_logic;
        LDS_INn     : in std_logic;
        LDS_OUTn    : out std_logic;
        UDS_INn     : in std_logic;
        UDS_OUTn    : out std_logic;
        RWn_IN      : in std_logic;
        RWn_OUT     : out std_logic;
        DTACK_INn   : in std_logic;
        DTACK_OUTn  : out std_logic;
        BERRn       : in std_logic;
        BMODE       : in std_logic;
        FC_IN       : in std_logic_vector(2 downto 0);
        FC_OUT      : out std_logic_vector(2 downto 0);
        BUSCTRL_EN  : out std_logic;
        INTn        : out std_logic;

        -- The bus:
        ADR_IN      : in std_logic_vector(31 downto 1);
        ADR_OUT     : out std_logic_vector(31 downto 1);
        ADR_EN      : out std_logic;
        DATA_IN     : in std_logic_vector(15 downto 0);
        DATA_OUT    : out std_logic_vector(15 downto 0);
        DATA_EN     : out std_logic;

        -- Bus arstd_logicration:
        BGIn        : in std_logic;
        BRn         : out std_logic;
        BGACK_INn   : in std_logic;
        BGACK_OUTn  : out std_logic;
        BGOn        : out std_logic
    );
end entity BLITTER_TOP;

architecture STRUCTURE of BLITTER_TOP is
component BLITTER_CORE
port (  CLK             : in std_logic;
        RESET           : in std_logic;
        ADR_IN          : in std_logic_vector(31 downto 1);
        ADR_OUT         : out std_logic_vector(31 downto 1);
        ADR_SEL         : in std_logic;
        ASn             : in std_logic;
        LDSn            : in std_logic;
        UDSn            : in std_logic;
        RWn             : in std_logic;
        FC              : in std_logic_vector(2 downto 0);
        BERRn           : in std_logic;
        DATA_IN         : in std_logic_vector(15 downto 0);
        DATA_OUT        : out std_logic_vector(15 downto 0);
        DATA_EN         : out std_logic;
        SWAPSRC         : in std_logic;
        FETCHSRC        : in std_logic;
        FETCHDEST       : in std_logic;
        PUSHDEST        : in std_logic;
        FORCE_X         : in boolean;
        SRCADR_MODIFY   : in boolean;
        DESTADR_MODIFY  : in boolean;
        X_COUNT_DEC     : in boolean;
        BLT_RESTART     : out std_logic;
        BLT_BSY         : out std_logic;
        XCNT_RELOAD     : out std_logic_vector(15 downto 0);
        XCNT_VALUE      : out std_logic_vector(15 downto 0);
        FORCE_DEST      : out std_logic;
        FXSR            : out std_logic;
        NFSR            : out std_logic;
        OP              : out std_logic_vector(3 downto 0);
        HOP             : out std_logic_vector(1 downto 0);
        HOG             : out std_logic;
        BUSY            : out std_logic;
        SMUDGE          : out std_logic
      );
end component;
component BLITTER_CTRL
port (  CLK                 : in std_logic;
        RESET               : in std_logic;
        BERRn               : in std_logic;
        BMODE               : in std_logic;
        DTACKn              : in std_logic;
        AS_INn              : in std_logic;
        AS_OUTn             : out std_logic;
        UDSn                : out std_logic;
        LDSn                : out std_logic;
        RWn                 : out std_logic;
        BUSCTRL_EN          : out std_logic;
        FC_OUT              : out std_logic_vector(2 downto 0);
        OP                  : in std_logic_vector(3 downto 0);
        HOP                 : in std_logic_vector(1 downto 0);
        HOG                 : in std_logic;
        BUSY                : in std_logic;
        SMUDGE              : in std_logic;
        BGIn                : in std_logic;
        ADR_SEL             : out std_logic;
        ADR_OUT_EN          : out std_logic;
        BLT_BSY             : in std_logic;
        FORCE_DEST          : in std_logic;
        FXSR                : in std_logic;
        NFSR                : in std_logic;
        XCNT_RELOAD         : in std_logic_vector(15 downto 0);
        XCNT_VALUE          : in std_logic_vector(15 downto 0);
        BLT_RESTART         : in std_logic;
        SWAPSRC             : out std_logic;
        FETCHSRC            : out std_logic;
        FETCHDEST           : out std_logic;
        PUSHDEST            : out std_logic;
        FORCE_X             : out boolean;
        SRCADR_MODIFY       : out boolean;
        DESTADR_MODIFY      : out boolean;
        X_COUNT_DEC         : out boolean;
        BRn                 : out std_logic;
        BGACK_INn           : in std_logic;
        BGACK_OUTn          : out std_logic;
        BGOn                : out std_logic
      );
end component;

signal DTACK_In             : std_logic;
signal BGACK_OUT_In         : std_logic;
signal SU                   : boolean;
signal ADR_SEL_I            : std_logic;
signal SWAPSRC_I            : std_logic;
signal FETCHSRC_I           : std_logic;
signal FETCHDEST_I          : std_logic;
signal PUSHDEST_I           : std_logic;
signal FORCE_X_I            : boolean;
signal SRCADR_MODIFY_I      : boolean;
signal DESTADR_MODIFY_I     : boolean;
signal BLT_RESTART_I        : std_logic;
signal X_COUNT_DEC_I        : boolean;
signal OP_I                 : std_logic_vector(3 downto 0);
signal HOP_I                : std_logic_vector(1 downto 0);
signal HOG_I                : std_logic;
signal BUSY_I               : std_logic;
signal SMUDGE_I             : std_logic;
signal BLT_BSY_I            : std_logic;
signal FORCE_DEST_I         : std_logic;
signal FXSR_I               : std_logic;
signal NFSR_I               : std_logic;
signal XCNT_RELOAD_I        : std_logic_vector(15 downto 0);
signal XCNT_VALUE_I         : std_logic_vector(15 downto 0);
begin
    DTACK_In <= '0' when ADR_IN & '0' >= x"FFFF8A00" and ADR_IN & '0' <= x"FFFF8A3C" and AS_INn = '0' and SU = true else '1';
    SU <= true when FC_IN = "101" or FC_IN = "110" else false; -- Superuser access.
    INTn <= BUSY_I;

    DTACK_OUT: process
    -- The DTACKn port pin is released on the falling clock edge after the data
    -- acknowledge detect (DTACK_DELAY) is asserted. The DTACKn is deasserted
    -- immediately when there is no further register access DTACK_In = '1';
    variable DTACK_DELAY : boolean;
    begin
        wait until CLK = '0' and CLK' event;
        if RESET = '1' then
            DTACK_OUTn <= '1';
            DTACK_DELAY := false;
        elsif DTACK_In = '1' then
            DTACK_OUTn <= '1';
            DTACK_DELAY := false;
        elsif DTACK_DELAY = false then
            DTACK_DELAY := true;
        else
            DTACK_OUTn <= '0';
        end if;
    end process DTACK_OUT;

    I_CORE: BLITTER_CORE
        port map(
            CLK                     => CLK,
            RESET                   => RESET ,
            ADR_IN                  => ADR_IN,
            ADR_OUT                 => ADR_OUT,
            ADR_SEL                 => ADR_SEL_I,
            ASn                     => AS_INn,
            LDSn                    => LDS_INn,
            UDSn                    => UDS_INn,
            RWn                     => RWn_IN,
            FC                      => FC_IN,
            BERRn                   => BERRn,
            DATA_IN                 => DATA_IN,
            DATA_OUT                => DATA_OUT,
            DATA_EN                 => DATA_EN,
            SWAPSRC                 => SWAPSRC_I,
            FETCHSRC                => FETCHSRC_I,
            FETCHDEST               => FETCHDEST_I,
            PUSHDEST                => PUSHDEST_I,
            FORCE_X                 => FORCE_X_I,
            SRCADR_MODIFY           => SRCADR_MODIFY_I,
            DESTADR_MODIFY          => DESTADR_MODIFY_I,
            BLT_RESTART             => BLT_RESTART_I,
            X_COUNT_DEC             => X_COUNT_DEC_I,
            BLT_BSY                 => BLT_BSY_I,
            FORCE_DEST              => FORCE_DEST_I,
            XCNT_RELOAD             => XCNT_RELOAD_I,
            XCNT_VALUE              => XCNT_VALUE_I,
            FXSR                    => FXSR_I,
            NFSR                    => NFSR_I,
            OP                      => OP_I,
            HOP                     => HOP_I,
            HOG                     => HOG_I,
            BUSY                    => BUSY_I,
            SMUDGE                  => SMUDGE_I
        );

    I_CTRL: BLITTER_CTRL
        port map(
            CLK                     => CLK,
            RESET                   => RESET,
            BERRn                   => BERRn,
            BMODE                   => BMODE,
            DTACKn                  => DTACK_INn,
            AS_INn                  => AS_INn,
            AS_OUTn                 => AS_OUTn,
            UDSn                    => UDS_OUTn,
            LDSn                    => LDS_OUTn,
            RWn                     => RWn_OUT,
            BUSCTRL_EN              => BUSCTRL_EN,
            FC_OUT                  => FC_OUT,
            OP                      => OP_I,
            HOP                     => HOP_I,
            HOG                     => HOG_I,
            BUSY                    => BUSY_I,
            SMUDGE                  => SMUDGE_I,
            ADR_SEL                 => ADR_SEL_I,
            ADR_OUT_EN              => ADR_EN,
            SWAPSRC                 => SWAPSRC_I,
            FETCHSRC                => FETCHSRC_I,
            FETCHDEST               => FETCHDEST_I,
            PUSHDEST                => PUSHDEST_I,
            FORCE_X                 => FORCE_X_I,
            SRCADR_MODIFY           => SRCADR_MODIFY_I,
            DESTADR_MODIFY          => DESTADR_MODIFY_I,
            BLT_RESTART             => BLT_RESTART_I,
            X_COUNT_DEC             => X_COUNT_DEC_I,
            BLT_BSY                 => BLT_BSY_I,
            FORCE_DEST              => FORCE_DEST_I,
            FXSR                    => FXSR_I,
            NFSR                    => NFSR_I,
            XCNT_RELOAD             => XCNT_RELOAD_I,
            XCNT_VALUE              => XCNT_VALUE_I,
            BRn                     => BRn,
            BGIn                    => BGIn,
            BGACK_INn               => BGACK_INn,
            BGACK_OUTn              => BGACK_OUTn,
            BGOn                    => BGOn
        );
end architecture STRUCTURE;