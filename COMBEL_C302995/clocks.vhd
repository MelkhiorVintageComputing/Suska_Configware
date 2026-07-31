------------------------------------------------------------------------
----                                                                ----
---- ATARI COMBEL compatible IP Core	    		                ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Atari's COMBEL with all features to reach                      ----
---- ATARI Falcon compatibility.                                    ----
----                                                                ----
---- Auxiliary clock system.                                        ----
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
---- Copyright © 2009... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- All rights reserved. No portion of this sourcecode may be      ----
---- reproduced or transmitted in any form by any means, whether    ----
---- by electronic, mechanical, photocopying, recording or          ----
---- otherwise, without my written permission.                      ----
----                                                                ----
------------------------------------------------------------------------
-- 
-- Revision History
-- 
-- Revision 2K9B  2009/12/24 WF
--   Initial Release.
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity CLOCKS is
port (
  CLK	    : in std_logic;

  CLK_04	: out std_logic;
  CLK_08	: out std_logic;
  CLK_064	: out std_logic
);
end CLOCKS;

architecture DIVIDER of CLOCKS is
begin
  P1: process (CLK)
	variable CLKTMP: std_logic_vector(5 downto 0);
    begin
      	if CLK = '1' and CLK' event then
        	CLKTMP := CLKTMP + '1';
      	end if;
      CLK_04 <= CLKTMP(1); -- One quarter of the clock input.
      CLK_08 <= CLKTMP(2); -- One eights of the clock input.
      CLK_064 <= CLKTMP(5); -- One sixtyfourth of CLK.
  end process P1;
end DIVIDER;
