------------------------------------------------------------------------
----                                                                ----
---- ATARI compatible IP Core             			                ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Atari's COMBEL with all features to reach                      ----
---- ATARI Falcon compatibility.                                    ----
----                                                                ----
---- Interrupt control system.                                      ----
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

entity INTERRUPTS is
	port(
		RESET 			: in std_logic;
		CLK				: in std_logic;
		ADR_HI			: in std_logic_vector(19 downto 16);
		ADR_LO			: in std_logic_vector(3 downto 1);
		FC				: in std_logic_vector(2 downto 0);
		ASn				: in std_logic;

		EINT1 			: in std_logic;
		EINT3 			: in std_logic;
		EINT5n			: in std_logic;
		EINT7n			: in std_logic;
		MFPINTn			: in std_logic;
		HINT 			: in std_logic;
		VINT 			: in std_logic;

		AVECn			: out std_logic;

		IACKn			: out std_logic;
		SCCIACKn		: out std_logic;
		IPLn			: out std_logic_vector(2 downto 0)
	);
end entity INTERRUPTS;
	
architecture BEHAVIOR of INTERRUPTS is
signal GI_In		: std_logic_vector(2 downto 1);
signal HINT_In	    : std_logic;
signal VINT_In	    : std_logic;
begin
	IPL1n_CONTROL: process
	-- Process for storing interrupt information of the vertical- and 
	-- horizontal blanking interrupt. This process is enhanced for the
	-- video hi modes in a way, that only every second horizontal
	-- synchronisation pulse causes an interrupt. This is for software
	-- timing compatibility reasons.
	variable EDGE_LOCK_H, EDGE_LOCK_V : boolean;
	begin
		wait until CLK = '1' and CLK' event;
		if RESET = '1' then
			HINT_In <= '1';  -- Initial conditions.
			VINT_In <= '1';
		elsif HINT = '1' and EDGE_LOCK_H = false then
			HINT_In <= '0';  -- Interrupt request.
			EDGE_LOCK_H := true;
		elsif ASn = '0' and FC = "111" and ADR_HI = "1111" and 
			ADR_LO = "010" then
			HINT_In <= '1';  -- Interrupt request reset.
		elsif HINT = '0' then
			EDGE_LOCK_H := false;
		end if;
		--
		if VINT = '1' and EDGE_LOCK_V = false then
			VINT_In <= '0';  -- Interrupt request.
			EDGE_LOCK_V := true;
		elsif ASn = '0' and FC = "111" and ADR_HI = "1111" and 
			ADR_LO = "100" then
			VINT_In <= '1';  -- Interrupt request reset.
		elsif VINT = '0' then
			EDGE_LOCK_V := false;
		end if;
	end process IPL1n_CONTROL;
	
	GI_In <= "00" when MFPINTn = '0' else
			 "01" when VINT_In = '0' else
			 "10" when HINT_In = '0' else
			 "11"; -- No interrupts.

	-- The following two statements generate the AVECn signal for the auto vectoring 
	-- interrupts. In the ST these are H-Blank and V-Blank. The MFP is not auto
	-- vectoring and do not need AVECn.
	-- Other IRQ-levels: 7: external, 6: MFP, 5: external, 3: external, 1: none, 0: none
	-- 7 is the highest IRQ-level.
	AVECn <= '0' when ASn = '0' and FC = "111" and ADR_HI = "1111" and ADR_LO = "010" else -- V-Blank IRQ-level 2.
			 '0' when ASn = '0' and FC = "111" and ADR_HI = "1111" and ADR_LO = "100" else '1'; -- H-Blank IRQ-level 4.

    -- The following statements assigns an interrupt acknowledge CPU space cycles with interrupt
    -- level 6 for the MFP and 5 for the SCC:
	IACKn <= '0' when ASn = '0' and FC = "111" and ADR_HI = x"F" and ADR_LO = "110" else '1'; -- MFP
    SCCIACKn <= '0' when ASn = '0' and FC = "111" and ADR_HI = x"F" and ADR_LO = "101" else '1'; -- SCC

	PRIODECODER: process(EINT1, EINT3, EINT5n, EINT7n, GI_In)
	begin
		if EINT7n = '0' then -- Highest priority.
			IPLn <= "000";
		elsif GI_In = "00" then -- MFPINT.
			IPLn <= "001";
		elsif EINT5n = '0' then
			IPLn <= "010";
		elsif GI_In = "01" then -- V-Blank.
			IPLn <= "011";
		elsif EINT3 = '1' then -- Active hi.
			IPLn <= "100";
		elsif GI_In = "10" then -- H-Blank.
			IPLn <= "101";
		elsif EINT1 = '1' then -- Active hi.
			IPLn <= "110";
		else
			IPLn <= "111";
		end if;		
	end process PRIODECODER;
end BEHAVIOR;
