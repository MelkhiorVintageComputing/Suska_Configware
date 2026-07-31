------------------------------------------------------------------------
----                                                                ----
---- ATARI DMA compatible IP Core					                ----
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

entity TT_FUNNEL is
	port (
	    RESET 		: in bit;
		CLK			: in bit;

		A 		    : inout std_logic_vector(15 downto 0);
		B 		    : inout std_logic_vector(15 downto 0);
		C 		    : inout std_logic_vector(15 downto 0);
		D 		    : inout std_logic_vector(15 downto 0);
		
		PDL_IN		: in std_logic_vector(15 downto 0);
		PDL_OUT	    : out std_logic_vector(15 downto 0);
		PDH_IN		: in std_logic_vector(15 downto 0);
		PDH_OUT	    : out std_logic_vector(15 downto 0);

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
end entity TT_FUNNEL;
	
architecture STRUCTURE of TT_FUNNEL is
component TT_FUNNEL_SOC
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
end component;
signal A_OUT		: std_logic_vector(15 downto 0);
signal A_EN 		: bit;
signal B_OUT		: std_logic_vector(15 downto 0);
signal B_EN 		: bit;
signal C_OUT		: std_logic_vector(15 downto 0);
signal C_EN 		: bit;
signal D_OUT		: std_logic_vector(15 downto 0);
signal D_EN 		: bit;
begin
    A <= A_OUT when A_EN = '1' else (others => 'Z');
    B <= B_OUT when B_EN = '1' else (others => 'Z');
    C <= C_OUT when C_EN = '1' else (others => 'Z');
    D <= D_OUT when D_EN = '1' else (others => 'Z');
    
    I_FUNNEL: TT_FUNNEL_SOC
        port map(
            RESET 		    => RESET,
            CLK			    => CLK,

            A_IN		    => A,
            A_OUT		    => A_OUT,
            A_EN 		    => A_EN,
            B_IN		    => B,
            B_OUT		    => B_OUT,
            B_EN 		    => B_EN,
            C_IN		    => C,
            C_OUT		    => C_OUT,
            C_EN 		    => C_EN,
            D_IN		    => D,
            D_OUT		    => D_OUT,
            D_EN 		    => D_EN,

            PDH_IN		    => PDH_IN,
            PDH_OUT		    => PDH_OUT,
            PDL_IN		    => PDL_IN,
            PDL_OUT		    => PDL_OUT,

            SD_OUT		    => SD_OUT,

            RDATn		    => RDATn,
            WDATn		    => WDATn,
            DLATCHn		    => DLATCHn,
            VLATCHn		    => VLATCHn,
            VLATCH2n	    => VLATCH2n,

            SEL0		    => SEL0,
            SEL1		    => SEL1,
            TSSOn		    => TSSOn
            );
end architecture STRUCTURE;