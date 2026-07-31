------------------------------------------------------------------------
----                                                                ----
---- ATARI SHIFTER compatible IP Core                               ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- ST and STE compatible SHIFTER IP core.                         ----
----                                                                ----
---- This is the package file containing the component              ----
---- declarations.                                                  ----
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
--   Added the Stacy or STBook SHADOW register at address $FF827E.
-- Revision 2K6B  2006/11/06 WF
--   Modified Source to compile with the Xilinx ISE.
-- Revision 2K8A  2008/07/14 WF
--   Minor changes.
-- Revision 2K9A  2008/06/29 WF
--   Changes concerning the SH_MOD for multisync compatibility.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--

library ieee;
use ieee.std_logic_1164.all;

package WF25914IP_PKG is
-- Component declarations:
component WF25914IP_SH_CLOCKS
    port (
        CLK_32M: in std_logic;
        CLK_16M: out std_logic
    );
end component;

component WF25914IP_SHMOD_REG
    port (
        CLK         : in std_logic;
        RESETn      : in std_logic;
        ADR         : in std_logic_vector (6 downto 1);
        CSn         : in std_logic;
        RWn         : in std_logic;
        DATA_IN     : in std_logic_vector(7 downto 0); -- Data.
        DATA_OUT    : out std_logic_vector(7 downto 0);
        DATA_EN     : out std_logic;
        MULTISYNC   : in std_logic_vector(1 downto 0);
        SH_MOD      : out std_logic_vector(7 downto 0); -- Register output.
        xFF827E     : out std_logic_vector(7 downto 0)  -- Register output.
    );
end component;

component WF25914IP_CR_SHIFT_REG
    port(
        CLK             : in std_logic;
        RESETn          : in std_logic;
        ADR             : in std_logic_vector (6 downto 1);
        CSn             : in std_logic;
        RWn             : in std_logic;
        LOADn, DE       : in std_logic;
        SH_MOD          : in std_logic_vector(7 downto 0);
        DATA_IN         : in std_logic_vector(15 downto 0); -- Data.
        DATA_OUT        : out std_logic_vector(7 downto 0);
        DATA_EN         : out std_logic;
        SR              : out std_logic_vector(3 downto 0)
    );
end component;

component WF25914IP_CR_REGISTERS
    port(
        CLK, RESETn : in std_logic;
        ADR         : in std_logic_vector (6 downto 1);
        CSn         : in std_logic;
        RWn         : in std_logic;
        DATA_IN     : in std_logic_vector(15 downto 0); -- Data.
        DATA_OUT    : out std_logic_vector(15 downto 0);
        DATA_EN     : out std_logic;
        SH_MOD      : in std_logic_vector (7 downto 0);
        SR          : in std_logic_vector (3 downto 0);
        MONO_INV    : out std_logic;
        CHROMA      : out std_logic_vector(15 downto 0)
    );
end component;

component WF25914IP_CR_OUT
    port (
        CLK         : in std_logic;
        RESETn      : in std_logic;
        MONO_INV    : in std_logic; -- Inversion control bit.
        BLANKn      : in std_logic; -- Blanking signal.
        DE          : in std_logic; -- Blanking signal for the monochrome mode.
        LOADn       : in std_logic; -- Load control for the shift registers.
        SH_MOD1     : in std_logic;  -- Monochrome switch.
        SR0         : in std_logic; -- Monochrome information.
        CHROMA      : in std_logic_vector(15 downto 0); -- Chroma bus.
        CR_1512     : out std_logic_vector(3 downto 0); -- Hi nibble of the chroma out.
        R           : out std_logic_vector(3 downto 0); -- Red video output.
        G           : out std_logic_vector(3 downto 0); -- Green video output.
        B           : out std_logic_vector(3 downto 0); -- Blue video output.
        MONO        : out std_logic -- Monochrome video output.
    );
end component;

component WF25914IP_MICROWIRE
    port(
        RESETn      : in std_logic;
        CLK         : in std_logic;
        RWn         : in std_logic;
        CMPCSn      : in std_logic;
        ADR         : in std_logic_vector (6 downto 1);
        DATA_IN     : in std_logic_vector(15 downto 0); -- Data.
        DATA_OUT    : out std_logic_vector(15 downto 0);
        DATA_EN     : out std_logic;
        MWK         : out std_logic; -- Microwire clock (1MHz).
        MWD         : out std_logic; -- Microwire data.
        MWEn        : out std_logic -- Microwire enable (low active).
    );
end component;

component WF25914IP_DMASOUND
    port (
        RESETn      : in std_logic;
        CLK         : in std_logic;
        ADR         : in std_logic_vector (6 downto 1);
        CSn         : in std_logic;
        RWn         : in std_logic;
        DATA_IN     : in std_logic_vector(15 downto 0); -- Data.
        DATA_OUT    : out std_logic_vector(15 downto 0);
        DATA_EN     : out std_logic;
        SLOADn      : in std_logic;
        SREQ        : out std_logic;
        SCLK        : in std_logic;
        FCLK        : out std_logic;
        SDATA_L     : out std_logic_vector(7 downto 0); -- Buffers implemented here.
        SDATA_R     : out std_logic_vector(7 downto 0) -- Buffers implemented here.
        );
end component;      

end WF25914IP_PKG;
