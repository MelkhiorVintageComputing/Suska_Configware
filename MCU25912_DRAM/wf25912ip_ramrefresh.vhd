------------------------------------------------------------------------
----                                                                ----
---- ATARI MCU compatible IP Core                                   ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Memory management controller with all features to reach        ----
---- ATARI STE compatibility.                                       ----
----                                                                ----
---- The refresh for the RAMs is done by a row address counter.     ----
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
---- Copyright © 2005... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Initial Release.
-- Revision 2K15B  20151224 WF
--   Replaced data type bit by std_logic.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF25912IP_RAMREFRESH is
port (  CLK         : in std_logic;
        REFCNT_EN   : in std_logic; -- Counter enable.

        REF_ADR     : out std_logic_vector(9 downto 0) -- Refresh row adress.
      );
end WF25912IP_RAMREFRESH;

architecture BEHAVIOR of WF25912IP_RAMREFRESH is
-- The refresh counter width is not adjusted dependant on the memory
-- which is equipped on the board. Therefore the lower adresses of 
-- the smaller rams are refreshed more often. This implementation is
-- correct and causes no limitations in any way.
begin
    CNT: process(CLK)
    variable TMP: std_logic_vector(9 downto 0);
    begin
        if CLK = '1' and CLK' event then
            if REFCNT_EN = '1' then
                TMP := TMP + '1';
            end if;
        end if;
        REF_ADR <= TMP;
    end process CNT;
end architecture BEHAVIOR;

