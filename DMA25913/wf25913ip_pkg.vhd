------------------------------------------------------------------------
----                                                                ----
---- ATARI DMA compatible IP Core                                   ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- ATARI ST and STE compatible DMA controller IP core.            ----
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
-- Revision 2K9B  2009/12/24 WF
--   Changes concerning the revised registers.
--   Changes concerning the new control section.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--

library ieee;
use ieee.std_logic_1164.all;

package WF25913IP_PKG is
-- Component declarations:
component WF25913IP_REGISTERS
    port (
        CLK             : in std_logic;
        RESETn          : in std_logic;
        FCSn            : in std_logic;
        RWn             : in std_logic;
        A1              : in std_logic;

        FIFO_ERROR      : in std_logic;
        ACSI_DATA_REQ   : in std_logic;
        SECTOR_CNT_EN   : in std_logic;

        DATA_IN         : in std_logic_vector (9 downto 0);
        DATA_OUT        : out std_logic_vector (15 downto 0);
        DATA_EN         : out std_logic;
        CD_IN           : in std_logic_vector (7 downto 0);
        CD_OUT          : out std_logic_vector (7 downto 0);
        CD_EN           : out std_logic;

        CTRL_SRC_SEL    : out std_logic_vector(1 downto 0);
        DMA_SRC_SEL     : out std_logic_vector(1 downto 0);
        DMA_EN          : out std_logic;

        EOPn            : out std_logic;
        DMA_RWn         : out std_logic;
        HDCSn           : out std_logic;
        SCSICSn         : out std_logic;
        SDCSn           : out std_logic;
        FDCSn           : out std_logic;
        CA              : out std_logic_vector(2 downto 0);
        CTRL_ACC        : out std_logic
    );
end component;

component WF25913IP_FIFO
    port(
        CLK         : in std_logic;

        CLRn        : in std_logic;

        WR_ENA      : in std_logic;
        DATA_IN     : in std_logic_vector (15 downto 0);
        DATA_OUT    : out std_logic_vector(15 downto 0);
        RD_ENA      : in std_logic;

        FIFO_FULL   : out std_logic;
        FIFO_HI     : out std_logic;
        FIFO_LOW    : out std_logic;
        FIFO_EMPTY  : out std_logic;
        ERR         : out std_logic
    );
end component;

component WF25913IP_FIFO_UNIT
    port(
        CLK     : in std_logic;
        CLRn    : in std_logic;
        IN_A    : in std_logic_vector(15 downto 0);
        IN_B    : in std_logic_vector(15 downto 0);
        SEL     : in std_logic;
        ENA     : in std_logic;
        D_OUT   : out std_logic_vector(15 downto 0)
    );
end component;

component WF25913IP_FIFO_CTRL
    port(
        CLK         : in std_logic;
        CLRn        : in std_logic;
        WR_ENA      : in std_logic;
        RD_ENA      : in std_logic;
        FIFO_FULL   : out std_logic;
        FIFO_HI     : out std_logic;
        FIFO_LOW    : out std_logic;
        FIFO_EMPTY  : out std_logic;
        FIFO_ERR    : out std_logic;
        SEL         : out std_logic_vector(16 downto 1);
        ENA         : out std_logic_vector(16 downto 1)
    );
end component;

component WF25913IP_FIFO_DATAMUX
    port(
        CLK, CLRn       : in std_logic;
        DATA_IN         : in std_logic_vector (15 downto 0);
        DATA_OUT        : out std_logic_vector (15 downto 0);
        CD_IN           : in std_logic_vector (7 downto 0);
        CD_OUT          : out std_logic_vector (7 downto 0);
        FIFO_DATA_OUT   : in std_logic_vector(15 downto 0);
        FIFO_DATA_IN    : out std_logic_vector(15 downto 0);
        DATA_EN         : in std_logic;
        DMA_RWn         : in std_logic;
        CD_HIBUF_EN     : in std_logic;
        CD_RD_HIn       : in std_logic;
        CD_RD_LOWn      : in std_logic
    );
end component;

component WF25913IP_CTRL
    port (
        CLK             : in std_logic;
        RESETn          : in std_logic;

        RDY_INn         : in std_logic;
        FCSn            : in std_logic;
        DMA_EN          : in std_logic;
        CTRL_ACC        : in std_logic;

        DMA_RWn         : in std_logic;
        DMA_SRC_SEL     : in std_logic_vector(1 downto 0);
        HDRQ            : in std_logic;
        FDCRQ           : in std_logic;

        FIFO_FULL       : in std_logic;
        FIFO_HI         : in std_logic;
        FIFO_LOW        : in std_logic;
        FIFO_EMPTY      : in std_logic;

        CLRn            : out std_logic;

        FIFO_RD_ENA     : out std_logic;
        FIFO_WR_ENA     : out std_logic;

        DATA_EN         : out std_logic;

        CD_HIBUF_EN     : out std_logic;
        CD_RD_HIn       : out std_logic;
        CD_RD_LOWn      : out std_logic;

        ACSI_DATA_REQ   : out std_logic;
        SECTOR_CNT_EN   : out std_logic;

        FDCS_DMA_ACCn   : out std_logic;
        HD_ACKn         : out std_logic;
        RDY_OUTn        : out std_logic
    );
end component;
end WF25913IP_PKG;