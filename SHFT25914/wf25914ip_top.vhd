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
---- This is the top level file.                                    ----
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
-- Revision 2K8B  2008/12/24 WF
--   Rewritten this top level file as a wrapper for the top_soc file.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--

library work;
use work.wf25914ip_pkg.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF25914IP_TOP is
    port (
        SH_CLK_32M      : in std_logic;
        SH_CLK_16M      : out std_logic;
        RESETn          : in std_logic;
        SH_A            : in std_logic_vector(6 downto 1);      -- Adress bus (without base adress).
        SH_D            : inout std_logic_vector(15 downto 0);  -- Data bus.
        SH_RWn          : in std_logic;                         -- Write to registers is low active.
        SH_CSn          : in std_logic;                         -- Base adress of the shifter is 0xFF82xx.

        MULTISYNC       : in std_logic_vector(1 downto 0);      -- Select multisync compatible video modi.
        SH_LOADn        : in std_logic;                         -- Load signal for the shift registers.
        SH_DE           : in std_logic;                         -- Shift switch for the shift registers.
        SH_BLANKn       : in std_logic;                         -- Blanking input.
        CR_1512         : out std_logic_vector(3 downto 0);     -- Hi nibble of the chroma out.
        SH_R            : out std_logic_vector(3 downto 0);     -- Red video output.
        SH_G            : out std_logic_vector(3 downto 0);     -- Green video output.
        SH_B            : out std_logic_vector(3 downto 0);     -- Blue video output.
        SH_MONO         : out std_logic;                        -- Monochrome video output.
        SH_CSYNCn       : out std_logic;                        -- COMP_SYNC signal of the ST.
        
        SH_SCLK         : in std_logic;                         -- Sample clock, 6.4 MHz.
        SH_FCLK         : out std_logic;                        -- Frame clock.
        SH_SLOADn       : in std_logic;                         -- DMA load control.
        SH_SREQ         : out std_logic;                        -- DMA load request.
        SH_SDATA_L      : out std_logic_vector(7 downto 0);     -- Left audio data.
        SH_SDATA_R      : out std_logic_vector(7 downto 0);     -- Right audio data.

        SH_MWK          : out std_logic;                        -- Microwire interface, clock.
        SH_MWD          : out std_logic;                        -- Microwire interface, data.
        SH_MWEn         : out std_logic;                        -- Microwire interface, enable.
        
        -- Port connections of xFF872E_D:
        -- Bit 7 = MTR_POWER_ON (Turns on IDE rive motor).
        -- Bit 6 not further specified.
        -- Bit 5 = RS232_OFF.
        -- Bit 4 = REFRESH_MACHINE.
        -- Bit 3 = LAMP (LCD backlight).
        -- Bit 2 = POWER_OFF.
        -- Bit 1 = SHFT output.
        -- Bit 0 = SHADOW chip off.
        xFF827E_D       : out std_logic_vector(7 downto 0)
    );
end WF25914IP_TOP;

architecture STRUCTURE of WF25914IP_TOP is
component WF25914IP_SH_CLOCKS
    port (
        CLK_32M     : in std_logic; 
        CLK_16M     : out std_logic
    );
end component;  

component WF25914IP_TOP_SOC
    port (
        CLK             : in std_logic;
        RESETn          : in std_logic;
        SH_A            : in std_logic_vector(6 downto 1);
        SH_D_IN         : in std_logic_vector(15 downto 0);
        SH_D_OUT        : out std_logic_vector(15 downto 0);
        SH_DATA_HI_EN   : out std_logic;
        SH_DATA_LO_EN   : out std_logic;
        SH_RWn          : in std_logic;
        SH_CSn          : in std_logic;
        MULTISYNC       : in std_logic_vector(1 downto 0);
        SH_LOADn        : in std_logic;
        SH_DE           : in std_logic;
        SH_BLANKn       : in std_logic;
        CR_1512         : out std_logic_vector(3 downto 0);
        SH_R            : out std_logic_vector(3 downto 0);
        SH_G            : out std_logic_vector(3 downto 0);
        SH_B            : out std_logic_vector(3 downto 0);
        SH_MONO         : out std_logic;
        SH_CSYNCn       : out std_logic;
        SH_SCLK         : in std_logic;
        SH_FCLK         : out std_logic;
        SH_SLOADn       : in std_logic;
        SH_SREQ         : out std_logic;
        SH_SDATA_L      : out std_logic_vector(7 downto 0);
        SH_SDATA_R      : out std_logic_vector(7 downto 0);
        SH_MWK          : out std_logic;
        SH_MWD          : out std_logic;
        SH_MWEn         : out std_logic;
        xFF827E_D       : out std_logic_vector(7 downto 0)
    );
end component;
signal SH_D_OUT         : std_logic_vector(15 downto 0);
signal SH_DATA_HI_EN    : std_logic;
signal SH_DATA_LO_EN    : std_logic;
begin
    SH_D(15 downto 8) <= SH_D_OUT(15 downto 8) when SH_DATA_HI_EN = '1' else (others => 'Z');
    SH_D(7 downto 0) <= SH_D_OUT(7 downto 0) when SH_DATA_LO_EN = '1' else (others => 'Z');

    I_SHCLOCKS: WF25914IP_SH_CLOCKS
        port map(CLK_32M        => SH_CLK_32M,
                 CLK_16M        => SH_CLK_16M
        );

    I_SHIFTER: WF25914IP_TOP_SOC
        port map(CLK                => SH_CLK_32M,
                 RESETn             => RESETn,
                 SH_A               => SH_A,
                 SH_D_IN            => SH_D,
                 SH_D_OUT           => SH_D_OUT,
                 SH_DATA_HI_EN      => SH_DATA_HI_EN,
                 SH_DATA_LO_EN      => SH_DATA_LO_EN,
                 SH_RWn             => SH_RWn,
                 SH_CSn             => SH_CSn,
                 MULTISYNC          => MULTISYNC,
                 SH_LOADn           => SH_LOADn,
                 SH_DE              => SH_DE,
                 SH_BLANKn          => SH_BLANKn,
                 CR_1512            => CR_1512,
                 SH_R               => SH_R,
                 SH_G               => SH_G,
                 SH_B               => SH_B,
                 SH_MONO            => SH_MONO,
                 SH_CSYNCn          => SH_CSYNCn,
                 SH_SCLK            => SH_SCLK,
                 SH_FCLK            => SH_FCLK,
                 SH_SLOADn          => SH_SLOADn,
                 SH_SREQ            => SH_SREQ,
                 SH_SDATA_L         => SH_SDATA_L,
                 SH_SDATA_R         => SH_SDATA_R,
                 SH_MWK             => SH_MWK,
                 SH_MWD             => SH_MWD,
                 SH_MWEn            => SH_MWEn,
                 xFF827E_D          => xFF827E_D
        );
end STRUCTURE;
