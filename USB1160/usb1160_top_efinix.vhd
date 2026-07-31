------------------------------------------------------------------------
----                                                                ----
---- USB1160 IP Core                                                ----
----                                                                ----
---- Description:                                                   ----
---- This a wrapper for the USB1160_TOP to meet the requirements of ----
---- the Efinity Integrated Development Environment.                ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2024... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K224A  20240620 WF
--   Initial release.
--

library work;
use work.USB1160_PKG.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity USB1160_TOP_EFINIX is
    port (
        -- System controls:
        CLK_48MHz   : in std_logic;
        RESETn      : in std_logic;
        CLKOUT      : out std_logic;

        ALIVE       : out std_logic;

        -- Address and data:
        A0          : in std_logic;
        DATA_IN     : in  std_logic_vector(15 downto 0);
        DATA_OUT    : out std_logic_vector(15 downto 0);
        DATA_EN     : out std_logic_vector(15 downto 0);

        -- Bus controls:
        CSn         : in std_logic; -- Chip select.
        RDn         : in std_logic; -- Read data.
        WRn         : in std_logic; -- Write data.
        INT         : out std_logic; -- Interrupt.

        -- USB host:
        PSW1n       : out std_logic; -- Power switch.
        PSW2n       : out std_logic; -- Power switch.
        OC1n        : in std_logic; -- Overcurrent detection.
        OC2n        : in std_logic; -- Overcurrent detection.
        DM1_IN      : in std_logic; -- Data line.
        DM1_OUT     : out std_logic; -- Data line.
        DM1_EN      : out std_logic; -- Data line.
        DP1_IN      : in std_logic; -- Data line.
        DP1_OUT     : out std_logic; -- Data line.
        DP1_EN      : out std_logic; -- Data line.
        DM2_IN      : in std_logic; -- Data line.
        DM2_OUT     : out std_logic; -- Data line.
        DM2_EN      : out std_logic; -- Data line.
        DP2_IN      : in std_logic; -- Data line.
        DP2_OUT     : out std_logic; -- Data line.
        DP2_EN      : out std_logic; -- Data line.
        DP15K       : out std_logic -- Switch for four 15K pull down resistors
    );
end entity USB1160_TOP_EFINIX;

architecture STRUCTURE of USB1160_TOP_EFINIX is
component USB1160_TOP is
    port(
        -- System controls:
        CLK_48MHz   : in std_logic;
        RESETn      : in std_logic;

        -- Address and data:
        A0          : in std_logic;
        DATA_IN     : in  std_logic_vector(15 downto 0);
        DATA_OUT    : out std_logic_vector(15 downto 0);
        DATA_EN     : out std_logic;

        -- Bus controls:
        CSn         : in std_logic; -- Chip select.
        RDn         : in std_logic; -- Read data.
        WRn         : in std_logic; -- Write data.
        EOT         : in std_logic; -- End of DMA Transfer.
        DACKn       : in std_logic; -- DMA data acknowledge.
        DREQ        : out std_logic; -- DMA data request.
        INT         : out std_logic; -- Interrupt.

        -- USB host:
        WAKEUP      : in std_logic; -- Wakeup from suspend.
        SUSPEND     : out std_logic; -- Suspend status.
        AOCEN       : out std_logic; -- Analog OC enable, HcHardwareCon?guration register(10).
        CLKNS       : out std_logic; -- Suspend CLK not stop, HcHardwareCon?guration register(11).
        NDP_SEL     : in std_logic; -- Number of data ports.
        PSW1n       : out std_logic; -- Power switch.
        PSW2n       : out std_logic; -- Power switch.
        OC1n        : in std_logic; -- Overcurrent detection.
        OC2n        : in std_logic; -- Overcurrent detection.
        DM1_IN      : in std_logic; -- Data line.
        DM1_OUT     : out std_logic; -- Data line.
        DP1_IN      : in std_logic; -- Data line.
        DP1_OUT     : out std_logic; -- Data line.
        DPM1_EN     : out std_logic;
        DM2_IN      : in std_logic; -- Data line.
        DM2_OUT     : out std_logic; -- Data line.
        DP2_IN      : in std_logic; -- Data line.
        DP2_OUT     : out std_logic; -- Data line.
        DPM2_EN     : out std_logic;
        DP15K       : out std_logic -- Switch for four 15K pull down resistors
    );
end component USB1160_TOP;
signal DATA_EN_I    : std_logic;
signal DPM1_EN      : std_logic;
signal DPM2_EN      : std_logic;
begin
    P_ALIVE: process
    variable COUNTER    : std_logic_vector(24 downto 0);
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        COUNTER := COUNTER + '1';
        ALIVE <= COUNTER(24);
    end process P_ALIVE;

    DATA_EN <= x"FFFF" when DATA_EN_I = '1' else x"0000";

    DM1_EN <= DPM1_EN;
    DP1_EN <= DPM1_EN;
    DM2_EN <= DPM2_EN;
    DP2_EN <= DPM2_EN;

    CLKOUT <= CLK_48MHz;

    I_USB_TOP: USB1160_TOP

        port map(
            -- System controls:
            CLK_48MHz       => CLK_48MHz,
            RESETn          => RESETn,

            -- Address and data:
            A0              => A0,
            DATA_IN         => DATA_IN,
            DATA_OUT        => DATA_OUT,
            DATA_EN         => DATA_EN_I,

            -- Bus controls:
            CSn             => CSn,
            RDn             => RDn,
            WRn             => WRn,
            EOT             => '0',
            DACKn           => '1',
            --DREQ          => ,
            INT             => INT,

            -- USB host:
            WAKEUP          => '1',
            --SUSPEND       => ,
            --AOCEN         => ,
            --CLKNS         => ,
            NDP_SEL         => '0',
            PSW1n           => PSW1n,
            PSW2n           => PSW2n,
            OC1n            => OC1n,
            OC2n            => OC2n,
            DM1_IN          => DM1_IN,
            DM1_OUT         => DM1_OUT,
            DP1_IN          => DP1_IN,
            DP1_OUT         => DP1_OUT,
            DPM1_EN         => DPM1_EN,
            DM2_IN          => DM2_IN,
            DM2_OUT         => DM2_OUT,
            DP2_IN          => DP2_IN,
            DP2_OUT         => DP2_OUT,
            DPM2_EN         => DPM2_EN,
            DP15K           => DP15K
        );
end STRUCTURE;
