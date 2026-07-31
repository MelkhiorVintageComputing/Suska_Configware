------------------------------------------------------------------------
----                                                                ----
---- ATARI GLUE compatible IP Core					                ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Atari's COMBEL with all features to reach                      ----
---- ATARI Falcon compatibility.                                    ----
----                                                                ----
---- Bus error handler / timeout unit.                              ----
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
-- Revision 2K9B  2009/12/2 WF
--   Initial Release.
-- Revision 2K21A 20211224 WF
--   BERRn is now asserted after 128 instead of 256 clock cycles.
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ERRHANDLER is
	port(
		RESET 	: in std_logic;
		CLK		: in std_logic;
		ASn		: in std_logic;

		BERRn	: out std_logic
	);
end entity ERRHANDLER;
	
architecture BEHAVIOR of ERRHANDLER is
begin
	P1: process
	variable WATCHDOG: std_logic_vector(6 downto 0); -- 7 bit -> 128 steps.
	begin
		wait until CLK = '1' and CLK' event;
		if RESET = '1' then
			WATCHDOG := (others =>'1'); -- Load the counter.
		-- After DTACKn is released by the target, the bus master deasserts
		-- ASn and herewith reloads the watchdog.
		elsif ASn = '1' then
			WATCHDOG := (others =>'1'); -- Load the counter.
		elsif WATCHDOG > "0000000" then
			WATCHDOG := WATCHDOG - '1';
		end if;

		-- Error released if there is no response from a target after
		-- 128 clock cycles.
		if WATCHDOG = "0000000" then
			BERRn <= '0'; -- No answer after 128 clock periods after request. 
		else
			BERRn <= '1';
		end if;
	end process P1;
end BEHAVIOR;
