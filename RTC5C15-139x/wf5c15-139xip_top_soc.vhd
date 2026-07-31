------------------------------------------------------------------------
----                                                                ----
---- ATARI Real Time Clock (RTC) interface.                         ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Interface to connect a DS1392 or DS1393 SPI timekeeper chip    ----
---- to the Atari IP core. The interface is on the system side      ----
---- compatible with the original used RP5C15 chip.                 ----
----                                                                ----
---- This files is the SOC top level.                               ----
---- Top level file for use in systems on programmable chips.       ----
----                                                                ----
---- To Do:                                                         ----
---- -                                                              ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2007... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K7A  2007/01/05 WF
--   Initial Release.
-- Revision 2K8A  2008/07/14 WF
--   Minor changes.
-- Revision 2K10A  2010/06/20 WF
--   Several Fixes to get the things running.
-- Revision 2K17A  20171224 WF
--   Replaced the data type bit by std_logic.
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF5C15_139xIP_TOP is
    port(
        CLK             : in std_logic; -- 16MHz recommended.
        RESETn          : in std_logic;

        -- The bus interface:
        ADR             : in std_logic_vector(3 downto 0);
        DATA_IN         : in std_logic_vector(3 downto 0);
        DATA_OUT        : out std_logic_vector(3 downto 0);
        DATA_EN         : out std_logic;
        CS, CSn         : in std_logic;
        WRn, RDn        : in std_logic;

        -- The SPI signals:
        SPI_IN          : in std_logic;
        SPI_OUT         : out std_logic;
        SPI_EN          : out std_logic; -- SPI data enable.
        SPI_SCL         : out std_logic;
        SPI_CE          : out std_logic
        );
end entity WF5C15_139xIP_TOP;
    
architecture STRUCTURE of WF5C15_139xIP_TOP is
    component WF5C15_139xIP_REGISTERS
        port(
            CLK             : in std_logic;
            RESETn          : in std_logic;
            ADR             : in std_logic_vector(3 downto 0);
            DATA_IN         : in std_logic_vector(3 downto 0);
            DATA_OUT        : out std_logic_vector(3 downto 0);
            DATA_EN         : out std_logic;
            CS, CSn         : in std_logic;
            WRn, RDn        : in std_logic;

            DATA_VALID      : out std_logic;

            CLR_PENDING     : in std_logic;
            SPI_STORE       : in std_logic;
            SPI_DATASEL     : in std_logic_vector(3 downto 0);
            SPI_DATA_IN     : in std_logic_vector(7 downto 0);
            SPI_DATA_OUT    : out std_logic_vector(7 downto 0);
            SPI_PENDING     : out std_logic_vector(10 downto 0)
        );
    end component;

    component WF5C15_139xIP_CTRL
        port(
            CLK             : in std_logic;
            RESETn          : in std_logic;
            SPI_PENDING     : in std_logic_vector(10 downto 0);
            CLR_PENDING     : out std_logic;
            SPI_STORE       : out std_logic;
            SPI_DATASEL     : out std_logic_vector(3 downto 0);
            SPI_DATA_IN     : in std_logic_vector(7 downto 0);
            SPI_DATA_OUT    : out std_logic_vector(7 downto 0);

            DATA_VALID      : in std_logic;

            -- SPI interface:
            SPI_IN          : in std_logic;
            SPI_OUT         : out std_logic;
            SPI_EN          : out std_logic;
            SPI_SCL         : out std_logic;
            SPI_CE          : out std_logic
        );
    end component;

    signal DATA_VALID           : std_logic;
    signal SPI_PENDING          : std_logic_vector(10 downto 0);
    signal SPI_STORE            : std_logic;
    signal SPI_DATASEL          : std_logic_vector(3 downto 0);
    signal REG_DATA_OUT         : std_logic_vector(7 downto 0);
    signal SPI_DATA_OUT         : std_logic_vector(7 downto 0);
    signal CLR_PENDING          : std_logic;
    begin
        I_REGISTERS: WF5C15_139xIP_REGISTERS
        port map(
            CLK             => CLK,
            RESETn          => RESETn,

            ADR             => ADR,
            DATA_IN         => DATA_IN,
            DATA_OUT        => DATA_OUT,
            DATA_EN         => DATA_EN,
            CS              => CS,
            CSn             => CSn,
            RDn             => RDn,
            WRn             => WRn,

            DATA_VALID      => DATA_VALID,

            CLR_PENDING     => CLR_PENDING,
            SPI_STORE       => SPI_STORE,
            SPI_DATASEL     => SPI_DATASEL,
            SPI_DATA_IN     => SPI_DATA_OUT,
            SPI_DATA_OUT    => REG_DATA_OUT,
            SPI_PENDING     => SPI_PENDING
            );

        I_CTRL: WF5C15_139xIP_CTRL
        port map(
            CLK             => CLK,
            RESETn          => RESETn,
            SPI_PENDING     => SPI_PENDING,
            SPI_STORE       => SPI_STORE,
            SPI_DATASEL     => SPI_DATASEL,
            SPI_DATA_IN     => REG_DATA_OUT,
            SPI_DATA_OUT    => SPI_DATA_OUT,
            
            DATA_VALID      => DATA_VALID,

            CLR_PENDING     => CLR_PENDING,
            SPI_IN          => SPI_IN,
            SPI_OUT         => SPI_OUT,
            SPI_EN          => SPI_EN,
            SPI_SCL         => SPI_SCL,
            SPI_CE          => SPI_CE
        );
end STRUCTURE;
