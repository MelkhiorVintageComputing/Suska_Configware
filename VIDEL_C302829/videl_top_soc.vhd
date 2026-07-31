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
---- This is the top level structural model of the VIDEL.           ----
----                                                                ----
---- Remarks:                                                       ----
---- The inputs pins RAMH, CAS1 and CAS0 of the original VIDEL chip ----
---- handle the 32 wide bit RAM data bus and the 16bit wide system  ----
---- data bus of the original Falcon hardware. Since we have a 32   ----
---- bit data bus RAMH latches the RAM data. CAS1 and CAS0 are not  ----
---- required and thus not modeled.                                 ----
---- The EXT pin which is a GENLOCK enable is not implemented. In   ----
---- Falcon machines this pin is unconnected (not used).            ----
---- The VIDEO_CTRL bit 7, means the video data bus width is not    ----
---- supported in this core. A 32 bit video data bus is assumed.    ----
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
--   This is a complete code lifting with several changes and bug fixes.
--

library work;
use work.VIDEL_PKG.all;

library ieee;
use ieee.std_logic_1164.all;

entity VIDEL_TOP is
    generic(RAM_16      : boolean := false; -- Set true, if we have a 16 bit RAM data bus, false for 32 bit.
            HDMI        : boolean := false); -- HDMI requires a different timing.
    port (
        -- System and core control:
        RESET    	    : in std_logic;
        CLK_32M0	    : in std_logic;  -- Originally 32.000MHz.
        CLK_25M175		: in std_logic;  -- Originally 25.175MHz.
        CLK_EXT         : in std_logic;  -- External clock (GENLOCK).

        -- System bus:
        ADR  		    : in std_logic_vector(11 downto 1);
        DATA_IN		    : in std_logic_vector(31 downto 0);
        DATA_OUT	    : out std_logic_vector(31 downto 0);
        DATA_EN		    : out std_logic;
        VCS             : in std_logic; -- Videl chip select.
        WAITSTATE       : out std_logic; -- Required for Falcon Palette clock switchover.
        VLDn            : in std_logic; -- Videl data load signal.
        VREQ            : out std_logic; -- Video data request.
        RWn		        : in std_logic;

        -- Memory bus:
        RDATn           : in std_logic;
        WDATn           : in std_logic;
        RAMH            : in std_logic; -- Latch ram data signal.
        -- CAS1         -- Not required, see remarks in the file header.
        -- CAS0         -- Not required, see remarks in the file header.
        MD_IN		    : in std_logic_vector(31 downto 0);
        MD_OUT	        : out std_logic_vector(31 downto 0);
        MD_EN		    : out std_logic;

        -- Videl control inputs:
        PEN             : in std_logic; -- Light pen.

        -- Video section:
        DE              : out std_logic; -- Display enable.
        VSYNC           : out std_logic;
        VSYNC_EN        : out std_logic;
        HSYNC           : out std_logic;
        HSYNC_EN        : out std_logic;
        CSYNC           : out std_logic;
        COLOR           : out std_logic;
        HINT            : out std_logic;
        VINT            : out std_logic;
        EVENn_ODD	    : out std_logic; -- Interlaced video frame indicator, '0' = even.
        DOTCK           : out std_logic; -- This is the video DAC clock.
        MONO            : out std_logic;
        R_OUT           : out std_logic_vector(7 downto 0);
        G_OUT           : out std_logic_vector(7 downto 0);
        B_OUT           : out std_logic_vector(7 downto 0)
    );
end entity VIDEL_TOP;
    
architecture STRUCTURE of VIDEL_TOP is
signal DATA_EN_JP           : std_logic;
signal DATA_EN_VCORE        : std_logic;
signal DATA_OUT_JP          : std_logic_vector(15 downto 0);
signal DATA_OUT_VCORE       : std_logic_vector(15 downto 0);
signal DE_I                 : std_logic;
signal HSYNC_I              : std_logic;
signal VSYNC_I              : std_logic;
signal HSYNC_POL            : std_logic;
signal VSYNC_POL            : std_logic;
signal RAM_DATA_BUFFER      : std_logic_vector(31 downto 0);
signal VIDEO_DATA_BUFFER    : std_logic_vector(63 downto 0);
signal VDATA_ACK            : std_logic;
signal VDATA_REQ            : std_logic;
begin
    DATA_BUFFERS: process
    -- The RAM data is buffered into the RAM_DATA_BUFFER 
    -- or the VIDEO_DATA_BUFFER depending RAMH and VLDn. 
    -- We use a 64 byte video buffer which is filled in
    -- bursts of two LONG words (32 bit each) for 32 bit
    -- RAM data bus or it is used 32 bit only if there
    -- is a 16 bit RAM data bus.
    variable BURST          : boolean;
    begin
        wait until CLK_32M0 = '1' and CLK_32M0' event;
        if RAMH = '0' then
            RAM_DATA_BUFFER <= MD_IN;
        end if;
        --
        if RESET = '1' then
            VIDEO_DATA_BUFFER <= (others => '1');
        elsif RAM_16 = true and VLDn = '0' and BURST = false then -- 16 bit RAM bus.
            VIDEO_DATA_BUFFER(31 downto 16) <= MD_IN(15 downto 0); -- First WORD.
            BURST := true;
        elsif RAM_16 = true and BURST = true then -- 16 bit RAM bus.
            VIDEO_DATA_BUFFER(15 downto 0) <= MD_IN(15 downto 0); -- Second WORD.
            BURST := false;
            VDATA_ACK <= '1';
        elsif RAM_16 = false and VLDn = '0' and BURST = false then -- 32 bit RAM bus.
            VIDEO_DATA_BUFFER(63 downto 32) <= MD_IN; -- First LONG.
            BURST := true;
        elsif RAM_16 = false and BURST = true then -- 32 bit RAM bus.
            VIDEO_DATA_BUFFER(31 downto 0) <= MD_IN; -- Second LONG.
            BURST := false;
            VDATA_ACK <= '1';
        elsif VDATA_REQ = '0' then
            VDATA_ACK <= '0';
        end if;
    end process DATA_BUFFERS;

    DATA_OUT <= DATA_OUT_JP & DATA_OUT_JP when DATA_EN_JP = '1' else 
                DATA_OUT_VCORE & DATA_OUT_VCORE when DATA_EN_VCORE = '1' else
                MD_IN when RAMH = '0' and RDATn = '0' else RAM_DATA_BUFFER;

    DATA_EN <= DATA_EN_JP or DATA_EN_VCORE or not RDATn;

    MD_OUT <= DATA_IN;
    MD_EN <= not WDATn;

    HSYNC <= HSYNC_I when HSYNC_POL = '1' else not HSYNC_I;
    VSYNC <= VSYNC_I when VSYNC_POL = '1' else not VSYNC_I;

    DE <= DE_I;

    VREQ <= VDATA_REQ;

    I_VIDEO_SYSTEM: VIDEO_CORE
        generic map(RAM_16          => RAM_16,
                    HDMI            => HDMI)
        port map(
            CLK_32M0                => CLK_32M0,
            CLK_25M175              => CLK_25M175,
            CLK_EXT                 => CLK_EXT,
            RESET    		        => RESET,
            RWn				        => RWn,
            VCS                     => VCS,
            ADR                     => ADR,
            DATA_IN			        => DATA_IN(31 downto 16),
            DATA_OUT		        => DATA_OUT_VCORE,
            DATA_EN			        => DATA_EN_VCORE,
            WAITSTATE               => WAITSTATE,
            VDATA_IN			    => VIDEO_DATA_BUFFER,
            DE                      => DE_I,
            VDATA_REQ               => VDATA_REQ,
            VDATA_ACK               => VDATA_ACK,
            EVENn_ODD               => EVENn_ODD,
            HSYNC                   => HSYNC_I,
            HSYNC_EN                => HSYNC_EN,
            HSYNC_POL               => HSYNC_POL,
            VSYNC                   => VSYNC_I,
            VSYNC_EN                => VSYNC_EN,
            VSYNC_POL               => VSYNC_POL,
            CSYNC                   => CSYNC,
            COLOR                   => COLOR,
            HINT                    => HINT,
            VINT                    => VINT,
            DOTCK                   => DOTCK,
            MONO                    => MONO,
            R                       => R_OUT,
            G                       => G_OUT,
            B                       => B_OUT
        );

    I_JOY_PEN: JOY_PEN
        port map(
            RESET 			        => RESET,
            CLK                     => CLK_32M0,
            ADR                     => ADR,
            VCS                     => VCS,
            RWn                     => RWn,
            DATA_OUT		        => DATA_OUT_JP,
            DATA_EN			        => DATA_EN_JP,
            HSYNC 			        => HSYNC_I,
            VSYNC 			        => VSYNC_I,
            DE				        => DE_I,
            PEN 			        => PEN 
        );
end STRUCTURE;
