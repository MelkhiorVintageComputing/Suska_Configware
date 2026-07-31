------------------------------------------------------------------------
----                                                                ----
---- ATARI Falcon VIDEL compatible IP Core	    	                ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
----   Atari VIDEL compatible IP core. Refer to the Atari Falcon    ----
----   documentation for further information. There are important   ----
----   informations in the following documents:                     ----
----   1. Atari-Falcon030-Service-Guide.                            ----
----   2. The Authoritative Guide To The Falcon Video Hardware.     ----
----   3. Falcon030_Tech_Doc_10-1-1992.                             ----
----   4. Falcon030DeveloperDocumentation.                          ----
----   5. Atari-Falcon030-Developer-Support-Package.                ----
----                                                                ----
---- This is the joyport and light pen logic.                       ----
----                                                                ----
---- Remarks:                                                       ----
---- -                                                              ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2014... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- All rights reserved. No portion of this sourcecode may be      ----
---- reproduced or transmitted in any form by any means, whether    ----
---- by electronic, mechanical, photocopying, recording or          ----
---- otherwise, without my written permission.                      ----
----                                                                ----
------------------------------------------------------------------------

-- Revision History
-- Revision 2K14B 20141224 WF
--   Initial Release.
-- Revision 2K25A 20150620 WF
--   XPEN_CNT is now incremented by the edge of DE.
--    this is required because DE period may be slower than CLK.
-- 

library work;
use work.VIDEL_PKG.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity JOY_PEN is
	port (
		RESET 			: in std_logic;
		CLK             : in std_logic;
        ADR             : in std_logic_vector(11 downto 1);
        VCS             : in std_logic;
        RWn             : in std_logic;
        
		DATA_OUT		: out std_logic_vector(15 downto 0);
		DATA_EN			: out std_logic;

		HSYNC 			: in std_logic;
		VSYNC 			: in std_logic;
		DE				: in std_logic;
		
		PEN 			: in std_logic -- Light pen input.
    );
end entity JOY_PEN;
	
architecture BEHAVIOUR of JOY_PEN is
signal ADR_I            : std_logic_vector(11 downto 0);
signal XPEN_REG_CS  	: std_logic;
signal YPEN_REG_CS  	: std_logic;
signal XPEN_REG		    : std_logic_vector(15 downto 0);
signal YPEN_REG		    : std_logic_vector(15 downto 0);
signal XPEN_CNT		    : std_logic_vector(16 downto 0);
signal YPEN_CNT		    : std_logic_vector(15 downto 0);
begin
    ADR_I <= ADR & '0';
	XPEN_REG_CS <= '1' when VCS = '1' and ADR_I = x"220" and RWn = '1' else '0'; -- Read only, 16 bit.
	YPEN_REG_CS <= '1' when VCS = '1' and ADR_I = x"222" and RWn = '1' else '0'; -- Read only, 16 bit.

	X_PEN_CNT: process
    variable LOCK   : boolean;
	begin
		wait until CLK = '1' and CLK' event;
		if RESET = '1' then
			XPEN_CNT <= (others => '0');
            LOCK := false;
        elsif DE = '1' and LOCK = false then
            XPEN_CNT <= XPEN_CNT + '1'; -- 8MHz or 16MHz.
            LOCK := true;
        elsif DE = '0' then
            LOCK := false;
        else
            XPEN_CNT <= (others => '0'); -- Erase counter during horizontal sync.
        end if;			
	end process X_PEN_CNT;
	
	Y_PEN_CNT: process
	variable EDGE_LOCK: boolean;
	begin
		wait until CLK = '1' and CLK' event;
		if RESET = '1' then
			YPEN_CNT <= x"0000";
			EDGE_LOCK := false;
        elsif HSYNC = '1' and EDGE_LOCK = false then -- Counter counts the lines.
            EDGE_LOCK := true;
            if VSYNC = '0' then
                YPEN_CNT <= YPEN_CNT + '1';
            else
                YPEN_CNT <= x"0000"; -- Erase counter in vertical sync.
            end if;			
        elsif HSYNC = '0' then
            EDGE_LOCK := false;
        end if;
	end process Y_PEN_CNT;

	PEN_REGS: process
	begin
		wait until CLK = '1' and CLK' event;
		if RESET = '1' then
			XPEN_REG <= x"0000";
			YPEN_REG <= x"0000";
        elsif PEN = '1' then
            XPEN_REG <= XPEN_CNT(16 downto 1);
            YPEN_REG <= YPEN_CNT;
        end if;			
    end process PEN_REGS;

	-- Read registers:
	DATA_OUT <= XPEN_REG when XPEN_REG_CS = '1' else
				YPEN_REG when YPEN_REG_CS = '1' else (others => '0');
	DATA_EN <= '1' when XPEN_REG_CS = '1' or YPEN_REG_CS = '1' else '0';
end architecture BEHAVIOUR;