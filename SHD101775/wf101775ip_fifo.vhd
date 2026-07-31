------------------------------------------------------------------------
----                                                                ----
---- ATARI SHADOW compatible IP Core                                ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- The SHADOW FIFO consists of three parts: this file contains    ----
---- the iterative instantiation of the FIFO on the base of the     ----
---- FIFO units (the second part). Thirdly the FIFO requires a      ----
---- control mechanism which can be found in the FIFO control       ---- 
---- file.                                                          ----
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
-- Revision 2K10B  2010/12/27 WF
--   Changed the data output from pipelined to unpipelined.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--

library work;
use work.WF_SHD101775IP_PKG.all;

library ieee;
use ieee.std_logic_1164.all;

entity WF_SHD101775IP_FIFO is
    generic(WIDTH : natural := 8; -- Number of bits per FIFO cell.
            DEPTH : natural := 8); -- Number of FIFO cells.
    port(
        CLK         : in std_logic;
        -- Left side (input):
        CLRn        : in std_logic;
        WR_ENA      : in std_logic;
        DATA_IN     : in std_logic_vector(WIDTH-1 downto 0);
        -- Right side (output):
        DATA_OUT    : out std_logic_vector(WIDTH-1 downto 0);
        RD_ENA      : in std_logic;
        -- FIFO status:
        FIFO_FULL   : out std_logic;
        FIFO_EMPTY  : out std_logic;
        ERR         : out std_logic
    );
end entity WF_SHD101775IP_FIFO;

architecture STRUCTURE of WF_SHD101775IP_FIFO is
type DATA_ARRAY is array (DEPTH downto 0) of std_logic_vector(WIDTH-1 downto 0);
signal DATA     : DATA_ARRAY;
signal SEL_CELL : std_logic_vector(DEPTH downto 1);
signal ENA_CELL : std_logic_vector(DEPTH downto 1);

component WF_SHD101775IP_FIFO_CTRL
    port(
        CLK         : in std_logic; 
        CLRn        : in std_logic;
        WR_ENA      : in std_logic;
        RD_ENA      : in std_logic;
        FIFO_FULL   : out std_logic;
        FIFO_EMPTY  : out std_logic;
        FIFO_ERR    : out std_logic;
        SEL         : out std_logic_vector(DEPTH downto 1);
        ENA         : out std_logic_vector(DEPTH downto 1)
    );
end component;

component WF_SHD101775IP_FIFO_UNIT
    port(
        CLK     : in std_logic;
        CLRn    : in std_logic;
        IN_A    : in std_logic_vector(WIDTH-1 downto 0);
        IN_B    : in std_logic_vector(WIDTH-1 downto 0);
        SEL     : in std_logic;
        ENA     : in std_logic;
        D_OUT   : out std_logic_vector(WIDTH-1 downto 0)
    );
end component;
begin
    FIFO: for CELL in DEPTH downto 1 generate 
    begin
        I_DMA_FIFO_UNIT: WF_SHD101775IP_FIFO_UNIT
            port map(
                CLK => CLK,
                CLRn => CLRn,
                IN_A => DATA_IN,
                IN_B => DATA(CELL),
                D_OUT => DATA(CELL-1),
                SEL => SEL_CELL(CELL),
                ENA => ENA_CELL(CELL)
            );
    end generate FIFO;

    DATA(DEPTH) <= DATA_IN;
    DATA_OUT <= DATA(0); -- We need an unpipelined output (s. control section)!

    CONTROL: WF_SHD101775IP_FIFO_CTRL
        port map(
            CLK => CLK,
            CLRn => CLRn,
            WR_ENA => WR_ENA,
            RD_ENA => RD_ENA,
            FIFO_FULL => FIFO_FULL,
            FIFO_EMPTY => FIFO_EMPTY,
            FIFO_ERR => ERR,
            SEL => SEL_CELL,
            ENA => ENA_CELL
        );
end architecture STRUCTURE;
