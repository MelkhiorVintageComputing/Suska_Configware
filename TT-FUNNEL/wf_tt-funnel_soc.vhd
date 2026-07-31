------------------------------------------------------------------------
----                                                                ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- ATARI TT compatible Funnel chip IP core.                       ----
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

entity TT_FUNNEL_SOC is
	port (
	    RESET 		: in bit;
		CLK			: in bit;

		A_IN		: in std_logic_vector(15 downto 0);
		A_OUT		: out std_logic_vector(15 downto 0);
		A_EN 		: out bit;
		B_IN		: in std_logic_vector(15 downto 0);
		B_OUT		: out std_logic_vector(15 downto 0);
		B_EN 		: out bit;
		C_IN		: in std_logic_vector(15 downto 0);
		C_OUT		: out std_logic_vector(15 downto 0);
		C_EN 		: out bit;
		D_IN		: in std_logic_vector(15 downto 0);
		D_OUT		: out std_logic_vector(15 downto 0);
		D_EN 		: out bit;
		
		PDH_IN		: in std_logic_vector(15 downto 0);
		PDH_OUT		: out std_logic_vector(15 downto 0);
		PDL_IN		: in std_logic_vector(15 downto 0);
		PDL_OUT		: out std_logic_vector(15 downto 0);

		SD_OUT		: out std_logic_vector(15 downto 0);

		RDATn		: in bit;
		WDATn		: in bit;
		DLATCHn		: in bit;
		VLATCHn		: in bit;
		VLATCH2n	: in bit;

		SEL0		: in bit;
		SEL1		: in bit;
		TSSOn		: in bit
		);
end entity TT_FUNNEL_SOC;
	
architecture BEHAVIOUR of TT_FUNNEL_SOC is
signal MDAT_BUFFER	: std_logic_vector(63 downto 0);
signal VDAT_BUFFER	: std_logic_vector(63 downto 0);
signal SDAT_BUFFER	: std_logic_vector(63 downto 0);
signal SEL			: bit_vector(1 downto 0);
begin
	SEL <= SEL1 & SEL0;

	DATA_BUFFER: process
	begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            MDAT_BUFFER <= (others => '0');       
        elsif DLATCHn = '1' then
            MDAT_BUFFER <= A_IN & B_IN & C_IN & D_IN;
        end if;
	end process DATA_BUFFER;

	VIDEO_BUFFER: process
	begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            VDAT_BUFFER <= (others => '0');
        elsif VLATCHn = '1' then
            VDAT_BUFFER <= A_IN & B_IN & C_IN & D_IN;
        end if;
	end process VIDEO_BUFFER;

	SOUND_BUFFER: process
	begin
        wait until CLK = '1' and CLK' event;
		if RESET = '1' then
			SDAT_BUFFER <= (others => '0');
        elsif VLATCH2n = '1' then
            SDAT_BUFFER <= A_IN & B_IN & C_IN & D_IN;
        end if;
	end process SOUND_BUFFER;

	SD_OUT	<= 	VDAT_BUFFER(63 downto 48) when SEL = "11" and TSSOn = '1' else
                VDAT_BUFFER(47 downto 32) when SEL = "10" and TSSOn = '1' else
                VDAT_BUFFER(31 downto 16) when SEL = "01" and TSSOn = '1' else
                VDAT_BUFFER(15 downto 0) when SEL = "00" and TSSOn = '1' else
                SDAT_BUFFER(63 downto 48) when SEL = "11" else
                SDAT_BUFFER(47 downto 32) when SEL = "10" else
                SDAT_BUFFER(31 downto 16) when SEL = "01" else
                SDAT_BUFFER(15 downto 0); -- when SEL = "00";

    PDH_OUT <= 	MDAT_BUFFER(63 downto 48) when RDATn = '0' and SEL = "11" else
				MDAT_BUFFER(47 downto 32) when RDATn = '0' and SEL = "10" else
				MDAT_BUFFER(31 downto 16) when RDATn = '0' and SEL = "01" else
				MDAT_BUFFER(15 downto 0); -- when RDATn = '0' and SEL = "00"

	PDL_OUT <= 	MDAT_BUFFER(31 downto 16) when RDATn = '0' and SEL = "11" else
				MDAT_BUFFER(15 downto 0) when RDATn = '0' and SEL = "10" else
				MDAT_BUFFER(63 downto 48) when RDATn = '0' and SEL = "01" else
				MDAT_BUFFER(47 downto 32); -- when RDATn = '0' and SEL = "00"

	A_OUT <= PDH_IN;
	B_OUT <= PDL_IN;
	C_OUT <= PDH_IN;
	D_OUT <= PDL_IN;
    
    A_EN <= '1' when WDATn = '0' and SEL = "11" else '0';
    B_EN <= '1' when WDATn = '0' and SEL = "10" else '0';
    C_EN <= '1' when WDATn = '0' and SEL = "01" else '0';
    D_EN <= '1' when WDATn = '0' and SEL = "00" else '0';
end architecture BEHAVIOUR;