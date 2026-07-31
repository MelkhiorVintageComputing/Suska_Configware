------------------------------------------------------------------------
----                                                                ----
---- ATARI SHADOW compatible IP Core                                ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- This is the SUSKA SHADOW IP core package file.                 ----
----                                                                ----
---- Description:                                                   ----
---- Controller to connect a LCD panel with VGA solution to the     ----
---- STE machine.                                                   ----
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
-- Revision 2K6B  2006/11/06 WF
--   Modified Source to compile with the Xilinx ISE.
-- Revision 2K8A  2008/07/14 WF
--   Minor changes.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package WF_SHD101775IP_PKG is
    component WF_SHD101775IP_CTRL
        port (
            RESETn          : in std_logic;
            CLK             : in std_logic;
            SEL_640x400     : in std_logic;
            DE              : in std_logic;
            LOAD_STRB       : in std_logic;
            R_ADR           : out std_logic_vector(14 downto 0);
            R_DATA_EN       : out std_logic;
            R_OEn           : out std_logic;
            R_WRn           : out std_logic;
            R_D_SEL         : out std_logic;
            UDS_FIFO_EMPTY  : in std_logic;
            UDS_FIFO_FULL   : in std_logic;
            LDS_FIFO_EMPTY  : in std_logic;
            LDS_FIFO_FULL   : in std_logic;
            U_FIFO_WR       : out std_logic;
            L_FIFO_WR       : out std_logic;
            U_FIFO_RD       : out std_logic;
            L_FIFO_RD       : out std_logic;
            LCD_DATASEL     : out std_logic;
            LCD_UD_EN       : out std_logic;
            LCD_LD_EN       : out std_logic;
            LCD_S           : out std_logic;
            LCD_CP2         : out std_logic;
            LCD_CP1         : out std_logic
        );
    end component;

    component WF_SHD101775IP_FIFO
        port(
            CLK         : in std_logic;
            CLRn        : in std_logic;
            WR_ENA      : in std_logic;
            DATA_IN     : in std_logic_vector(7 downto 0);
            DATA_OUT    : out std_logic_vector(7 downto 0);
            RD_ENA      : in std_logic;
            FIFO_FULL   : out std_logic;
            FIFO_EMPTY  : out std_logic;
            ERR         : out std_logic
        );
    end component;
end WF_SHD101775IP_PKG;
