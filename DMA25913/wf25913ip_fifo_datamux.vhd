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
---- This is the FIFO data multiplexer which controls the data      ----
---- flow from or to the FIFO during read or write access.          ----
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
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--

library ieee;
use ieee.std_logic_1164.all;

entity WF25913IP_FIFO_DATAMUX is
  port(
    -- System control:
    CLK, CLRn       : in std_logic;

    -- The data busses:
    DATA_IN         : in std_logic_vector (15 downto 0);
    DATA_OUT        : out std_logic_vector (15 downto 0);
    CD_IN           : in std_logic_vector (7 downto 0);
    CD_OUT          : out std_logic_vector (7 downto 0);

    -- DMA FIFO connections:
    FIFO_DATA_OUT   : in std_logic_vector(15 downto 0);
    FIFO_DATA_IN    : out std_logic_vector(15 downto 0);

    -- Control signals for the multiplexer:
    DATA_EN         : in std_logic; -- Switch to connect FIFO data to the bus.
    DMA_RWn         : in std_logic; -- FIFO direction '1' is ACSI to system.
    CD_HIBUF_EN     : in std_logic; -- writes CD_BUF_HI.
    CD_RD_HIn       : in std_logic; -- reads high FIFO byte to CD.
    CD_RD_LOWn      : in std_logic  -- reads low FIFO byte to CD.
  );
end WF25913IP_FIFO_DATAMUX;

architecture BEHAVIOR of WF25913IP_FIFO_DATAMUX is
signal CD_BUF_HI    : std_logic_vector(7 downto 0); -- CD byte buffer.
signal DATA_IN_I    : std_logic_vector(15 downto 0); -- CD byte buffer.
begin
    P_CD_BUF: process(CLRn, CLK)
    -- The ACSI data bus is 8 bits wide, where the system data bus is 16 bits.
    -- To read from disk, there must sampled two ACSI bytes per system word.
    -- This process works as data pipeline for the first byte.
    begin
        if CLRn = '0' then
            CD_BUF_HI <= (others => '0');
        elsif CLK = '1' and CLK' event then
            if CD_HIBUF_EN = '1' then
                CD_BUF_HI <= CD_IN;
            end if;
        end if;
    end process P_CD_BUF;

    FIFO_DATA_IN <= DATA_IN when DMA_RWn = '0' else CD_BUF_HI & CD_IN;
    CD_OUT <= FIFO_DATA_OUT(15 downto 8) when CD_RD_HIn = '0' else
              FIFO_DATA_OUT(7 downto 0) when CD_RD_LOWn = '0' else (others => '0');
    DATA_OUT <= FIFO_DATA_OUT when DATA_EN = '1' else (others => '0');
end architecture BEHAVIOR;