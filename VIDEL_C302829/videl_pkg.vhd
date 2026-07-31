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
---- This is the package file containing the component              ----
---- declarations and type definitions.                             ----
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
-- Revision 2K14B  20141224 WF
--   Initial Release.
-- Revision 2K21A 20211224 WF
--   Several changes due to the code liftings.
-- 

library ieee;
use ieee.std_logic_1164.all;

package VIDEL_PKG is
type VIDEO_MODES is(STE_MONO, STE_MID, STE_LOW, F_MONO, F_TRUEC, F_8BITPL, F_4BITPL);

component VIDEO_CORE
    generic(RAM_16      : boolean := false; -- Set true, if we have a 16 bit RAM data bus, false for 32 bit.
            HDMI        : boolean := false); -- HDMI requires a different timing.
    port(
        CLK_32M0        : in std_logic;
        CLK_25M175      : in std_logic;
        CLK_EXT         : in std_logic;
        RESET    		: in std_logic;
        RWn				: in std_logic;
        VCS             : in std_logic;
        ADR             : in std_logic_vector(11 downto 1);
        DATA_IN			: in std_logic_vector(15 downto 0);
        DATA_OUT		: out std_logic_vector(15 downto 0);
        DATA_EN			: out std_logic;
        WAITSTATE       : out std_logic;
        VDATA_IN		: in std_logic_vector(63 downto 0);
        DE              : out std_logic;
        VDATA_REQ       : out std_logic;
        VDATA_ACK       : in std_logic;
        EVENn_ODD       : out std_logic;
        HSYNC           : out std_logic;
        HSYNC_EN        : out std_logic;
        HSYNC_POL       : out std_logic;
        VSYNC           : out std_logic;
        VSYNC_EN        : out std_logic;
        VSYNC_POL       : out std_logic;
        CSYNC           : out std_logic;
        COLOR           : out std_logic;
        HINT            : out std_logic;
        VINT            : out std_logic;
        DOTCK           : out std_logic;
        MONO            : out std_logic;        
        R               : out std_logic_vector(7 downto 0);
        G               : out std_logic_vector(7 downto 0);
        B               : out std_logic_vector(7 downto 0)
    );
end component VIDEO_CORE;

component JOY_PEN
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
end component JOY_PEN;
end VIDEL_PKG;
