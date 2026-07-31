------------------------------------------------------------------------
----                                                                ----
---- YM2149 compatible sound generator.				                ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Model of the ST or STE's YM2149 sound generator.               ----
----                                                                ----
---- This is the package file containing the component              ----
---- declarations.                                                  ----
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
-- Revision 2K6A  2006/06/03 WF
--   Initial Release.
-- Revision 2K6B  2006/11/07 WF
--   Modified Source to compile with the Xilinx ISE.
-- Revision 2K8A  2008/07/14 WF
--   Minor changes.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--

library ieee;
use ieee.std_logic_1164.all;

package WF2149IP_DIGOUT_PKG is
type BUSCYCLES is (INACTIVE, R_READ, R_WRITE, ADDRESS);

component WF2149IP_WAVE_DIGOUT
	port(
		RESETn		: in std_logic;
		SYS_CLK		: in std_logic;

		WAV_STRB	: in std_logic;

		ADR			: in std_logic_vector(3 downto 0);
		DATA_IN		: in std_logic_vector(7 downto 0);
		DATA_OUT	: out std_logic_vector(7 downto 0);
		DATA_EN		: out std_logic;
		
		BUSCYCLE	: in BUSCYCLES;
		CTRL_REG	: in std_logic_vector(5 downto 0);

		OUT_ALL		: out std_logic_vector(7 downto 0)
	);
end component;
end WF2149IP_DIGOUT_PKG;