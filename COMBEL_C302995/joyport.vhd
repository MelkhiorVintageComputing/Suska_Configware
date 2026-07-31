----------------------------------------------------------------------
----                                                              ----
---- ATARI GLUE compatible IP Core					              ----
----                                                              ----
---- This file is part of the SUSKA ATARI clone project.          ----
---- http://www.experiment-s.de                                   ----
----                                                              ----
---- Description:                                                 ----
---- Atari's COMBEL with all features to reach                    ----
---- ATARI Falcon compatibility.                                  ----
----                                                              ----
---- This file contains the Joyport logic for the paddles and the ----
---- Button. The Joyport logic for the pen is located in the      ----
---- VIDEL.                                                       ----
----                                                              ----
----                                                              ----
---- To Do:                                                       ----
---- -                                                            ----
----                                                              ----
---- Author(s):                                                   ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de   ----
----                                                              ----
----------------------------------------------------------------------
----                                                              ----
---- Copyright © 2009... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- All rights reserved. No portion of this sourcecode may be    ----
---- reproduced or transmitted in any form by any means, whether  ----
---- by electronic, mechanical, photocopying, recording or        ----
---- otherwise, without my written permission.                    ----
----                                                              ----
----------------------------------------------------------------------
-- 
-- Revision History
-- 
-- Revision 2K9B  2009/12/24 WF
--   Initial Release.
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity JOYPORT_PADDLES is
	port(
		CLK             : in std_logic;
		KHz_500	        : in std_logic;
		RESET 			: in std_logic;
		DATA_OUT		: out std_logic_vector(15 downto 0);
		DATA_EN			: out std_logic;

		PAD0X_RS		: in std_logic; -- Paddle counter register chip select.
		PAD0Y_RS		: in std_logic; -- Paddle counter register chip select.
		PAD1X_RS		: in std_logic; -- Paddle counter register chip select.
		PAD1Y_RS		: in std_logic; -- Paddle counter register chip select.
		
		PAD0X_INHn		: in std_logic; -- counter input for the Paddle 0X.
		PAD0Y_INHn		: in std_logic; -- counter input for the Paddle 0Y.
		PAD1X_INHn		: in std_logic; -- counter input for the Paddle 1X.
		PAD1Y_INHn		: in std_logic; -- counter input for the Paddle 1Y.
		PADRSTn			: out std_logic -- Paddle monoflops reset.
	);
end entity JOYPORT_PADDLES;

architecture BEHAVIOUR of JOYPORT_PADDLES is
signal PAD0X_REG	: std_logic_vector(7 downto 0);
signal PAD0Y_REG	: std_logic_vector(7 downto 0);
signal PAD1X_REG	: std_logic_vector(7 downto 0);
signal PAD1Y_REG	: std_logic_vector(7 downto 0);
signal RESET_CNT	: std_logic_vector(7 downto 0);
signal COUNT_RESET	: std_logic;
begin
	COUNTER_RESET: process
	variable EDGE_LOCK: boolean;
	begin
		wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            RESET_CNT <= x"00";
            EDGE_LOCK := false;
        elsif KHz_500 = '1' and EDGE_LOCK = false then
            RESET_CNT <= RESET_CNT + '1';
            EDGE_LOCK := true;
        elsif KHz_500 = '0' then
            EDGE_LOCK := false;
        end if;
	end process COUNTER_RESET;
		
	PADDLECOUNTER: process
	variable EDGE_LOCK: boolean;
	begin
		wait until CLK = '1' and CLK' event;
		if RESET = '1' then
			PAD0X_REG <= x"00";
			PAD0Y_REG <= x"00";
			PAD1X_REG <= x"00";
			PAD1Y_REG <= x"00";
			EDGE_LOCK := false;
        elsif KHz_500 = '1' and EDGE_LOCK = false then
            EDGE_LOCK := true;
            if COUNT_RESET = '1' then
                PAD0X_REG <= x"00";
            elsif 	PAD0X_INHn = '1' and PAD0X_REG < x"FF" then -- Stop at x"FF".
                PAD0X_REG <= PAD0X_REG + '1';			
            end if;
            if COUNT_RESET = '1' then
                PAD0Y_REG <= x"00";
            elsif 	PAD0Y_INHn = '1' and PAD0Y_REG < x"FF" then -- Stop at x"FF".
                PAD0Y_REG <= PAD0Y_REG + '1';			
            end if;
            if COUNT_RESET = '1' then
                PAD1X_REG <= x"00";
            elsif 	PAD1X_INHn = '1' and PAD1X_REG < x"FF" then -- Stop at x"FF".
                PAD1X_REG <= PAD1X_REG + '1';			
            end if;
            if COUNT_RESET = '1' then
                PAD1Y_REG <= x"00";
            elsif 	PAD1Y_INHn = '1' and PAD1Y_REG < x"FF" then -- Stop at x"FF".
                PAD1Y_REG <= PAD1Y_REG + '1';			
            end if;
        elsif KHz_500 = '0' then
            EDGE_LOCK := false;
        end if;
	end process PADDLECOUNTER;

	-- Controls:
	COUNT_RESET <= '1' when RESET_CNT = x"FF" else '0'; -- Reset after about 0.52ms.
	PADRSTn <= '1' when RESET_CNT = x"FF" else '0'; -- Reset after about 0.52ms.

	-- Read registers:
	-- Unused bits read back as '0'.
	DATA_OUT <= x"00" & PAD0X_REG when PAD0X_RS = '1' else
				x"00" & PAD0Y_REG when PAD0Y_RS = '1' else
				x"00" & PAD1X_REG when PAD1X_RS = '1' else
				x"00" & PAD1Y_REG when PAD1Y_RS = '1' else (others => '0');
	DATA_EN <=  '1' when PAD0X_RS = '1' or PAD0Y_RS = '1' else
				'1' when PAD1X_RS = '1' or PAD1Y_RS = '1' else '0';
end architecture BEHAVIOUR;
