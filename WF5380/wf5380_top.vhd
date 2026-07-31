------------------------------------------------------------------------
----                                                                ----
---- WF5380 IP Core                                                 ----
----                                                                ----
---- Description:                                                   ----
---- This model provides an asynchronous SCSI interface compa-      ----
---- tible to the DP5380 from National Semiconductor and others.    ----
----                                                                ----
---- This file is the top level file with tree state buses.         ----
----                                                                ----
----                                                                ----
----                                                                ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2009... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K9A  2009/06/20 WF
--   Initial Release.
-- Revision 2K15B 20151224 WF
--   Changed the lisence for this file.
--

library work;
use work.wf5380_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF5380_TOP is
    port (
        -- System controls:
        CLK         : in std_logic;
        RESETn      : in std_logic;

        -- Address and data:
        ADR         : in std_logic_vector(2 downto 0);
        DATA        : inout std_logic_vector(7 downto 0);

        -- Bus and DMA controls:
        CSn         : in std_logic;
        RDn         : in std_logic;
        WRn         : in std_logic;
        EOPn        : in std_logic;
        DACKn       : in std_logic;
        DRQ         : out std_logic;
        INT         : out std_logic;
        READY       : out std_logic;

        -- SCSI bus:
        DBn         : inout std_logic_vector(7 downto 0);
        DBPn        : inout std_logic;
        RSTn        : inout std_logic;
        BSYn        : inout std_logic;
        SELn        : inout std_logic;
        ACKn        : inout std_logic;
        ATNn        : inout std_logic;
        REQn        : inout std_logic;
        IOn         : inout std_logic;
        CDn         : inout std_logic;
        MSGn        : inout std_logic
    );
end entity WF5380_TOP;

architecture STRUCTURE of WF5380_TOP is
component WF5380_TOP_SOC
    port (
        -- System controls:
        CLK         : in std_logic;
        RESET       : in std_logic;
        ADR         : in std_logic_vector(2 downto 0);
        DATA_IN     : in std_logic_vector(7 downto 0);
        DATA_OUT    : out std_logic_vector(7 downto 0);
        DATA_EN     : out std_logic;
        CSn         : in std_logic;
        RDn         : in std_logic;
        WRn         : in std_logic;
        EOPn        : in std_logic;
        DACKn       : in std_logic;
        DRQ         : out std_logic;
        INT         : out std_logic;
        READY       : out std_logic;
        DB_INn      : in std_logic_vector(7 downto 0);
        DB_OUTn     : out std_logic_vector(7 downto 0);
        DB_EN       : out std_logic;
        DBP_INn     : in std_logic;
        DBP_OUTn    : out std_logic;
        DBP_EN      : out std_logic;
        RST_INn     : in std_logic;
        RST_OUTn    : out std_logic;
        RST_EN      : out std_logic;
        BSY_INn     : in std_logic;
        BSY_OUTn    : out std_logic;
        BSY_EN      : out std_logic;
        SEL_INn     : in std_logic;
        SEL_OUTn    : out std_logic;
        SEL_EN      : out std_logic;
        ACK_INn     : in std_logic;
        ACK_OUTn    : out std_logic;
        ACK_EN      : out std_logic;
        ATN_INn     : in std_logic;
        ATN_OUTn    : out std_logic;
        ATN_EN      : out std_logic;
        REQ_INn     : in std_logic;
        REQ_OUTn    : out std_logic;
        REQ_EN      : out std_logic;
        IOn_IN      : in std_logic;
        IOn_OUT     : out std_logic;
        IO_EN       : out std_logic;
        CDn_IN      : in std_logic;
        CDn_OUT     : out std_logic;
        CD_EN       : out std_logic;
        MSG_INn     : in std_logic;
        MSG_OUTn    : out std_logic;
        MSG_EN      : out std_logic
    );
end component;
--
signal DATA_OUT     : std_logic_vector(7 downto 0);
signal DATA_EN      : std_logic;
signal DB_OUTn      : std_logic_vector(7 downto 0);
signal DB_EN        : std_logic;
signal DBP_OUTn     : std_logic;
signal DBP_EN       : std_logic;
signal RST_OUTn     : std_logic;
signal RST_EN       : std_logic;
signal BSY_OUTn     : std_logic;
signal BSY_EN       : std_logic;
signal SEL_OUTn     : std_logic;
signal SEL_EN       : std_logic;
signal ACK_OUTn     : std_logic;
signal ACK_EN       : std_logic;
signal ATN_OUTn     : std_logic;
signal ATN_EN       : std_logic;
signal REQ_OUTn     : std_logic;
signal REQ_EN       : std_logic;
signal IOn_OUT      : std_logic;
signal IO_EN        : std_logic;
signal CDn_OUT      : std_logic;
signal CD_EN        : std_logic;
signal MSG_OUTn     : std_logic;
signal MSG_EN       : std_logic;
begin
    DATA <= DATA_OUT when DATA_EN = '1' else (others => 'Z');
    DBn <= DB_OUTn when DB_EN = '1' else (others => 'Z');

    DBPn <= DBP_OUTn when DBP_EN = '1' else 'Z';
    RSTn <= RST_OUTn when RST_EN = '1' else 'Z';
    BSYn <= BSY_OUTn when BSY_EN = '1' else 'Z';
    SELn <= SEL_OUTn when SEL_EN = '1' else 'Z';
    ACKn <= ACK_OUTn when ACK_EN = '1' else 'Z';
    ATNn <= ATN_OUTn when ATN_EN = '1' else 'Z';
    REQn <= REQ_OUTn when REQ_EN = '1' else 'Z';
    IOn <= IOn_OUT when IO_EN = '1' else 'Z';
    CDn <= CDn_OUT when CD_EN = '1' else 'Z';
    MSGn <= MSG_OUTn when MSG_EN = '1' else 'Z';

    I_5380: WF5380_TOP_SOC
        port map(
            CLK         => CLK,
            RESET       => not RESETn,
            ADR         => ADR,
            DATA_IN     => DATA,
            DATA_OUT    => DATA_OUT,
            DATA_EN     => DATA_EN,
            CSn         => CSn,
            RDn         => RDn,
            WRn         => WRn,
            EOPn        => EOPn,
            DACKn       => DACKn,
            DRQ         => DRQ,
            INT         => INT,
            READY       => READY,
            DB_INn      => DBn,
            DB_OUTn     => DB_OUTn,
            DB_EN       => DB_EN,
            DBP_INn     => DBPn,
            DBP_OUTn    => DBP_OUTn,
            DBP_EN      => DBP_EN,
            RST_INn     => RSTn,
            RST_OUTn    => RST_OUTn,
            RST_EN      => RST_EN,
            BSY_INn     => BSYn,
            BSY_OUTn    => BSY_OUTn,
            BSY_EN      => BSY_EN,
            SEL_INn     => SELn,
            SEL_OUTn    => SEL_OUTn,
            SEL_EN      => SEL_EN,
            ACK_INn     => ACKn,
            ACK_OUTn    => ACK_OUTn,
            ACK_EN      => ACK_EN,
            ATN_INn     => ATNn,
            ATN_OUTn    => ATN_OUTn,
            ATN_EN      => ATN_EN,
            REQ_INn     => REQn,
            REQ_OUTn    => REQ_OUTn,
            REQ_EN      => REQ_EN,
            IOn_IN      => IOn,
            IOn_OUT     => IOn_OUT,
            IO_EN       => IO_EN,
            CDn_IN      => CDn,
            CDn_OUT     => CDn_OUT,
            CD_EN       => CD_EN,
            MSG_INn     => MSGn,
            MSG_OUTn    => MSG_OUTn,
            MSG_EN      => MSG_EN
        );
end STRUCTURE;
