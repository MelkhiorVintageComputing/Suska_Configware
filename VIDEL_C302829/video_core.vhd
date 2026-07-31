------------------------------------------------------------------------
----                                                                ----
---- ATARI Falcon VIDEL compatible IP Core                          ----
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
---- This is the video core providing video data management and     ----
---- video timing.                                                  ----
---- The video resolution and screen refresh rate depend on the     ----
---- settings of the respective VIDEL registers. In principle there ----
---- are hundreds of settings possible. Practically the following   ----
---- settings are of interest to meet the specifications of various ----
---- Atari machines:                                                ----
---- ST-Low         : 320 * 200 pixel / 16 colors.                  ----
---- ST-Medium      : 640 * 200 pixel / 4 colors.                   ----
---- ST-High        : 640 * 400 pixel / 2 colors.                   ----
---- Falcon-Low     : 640 * 480 pixel / 16 colors.                  ----
---- Falcon-Medium  : 640 * 480 pixel / 256 colors.                 ----
---- Falcon-High 1  : 320 * 480 pixel / 65536 true color mode.      ----
---- Falcon-High 2  : 640 * 480 pixel / 65536 true color interlaced.----
---- Falcon-High 3  : 640 * 480 pixel / 65536 true color PAL.       ----
---- Falcon-High 4  : 640 * 400 pixel / 65536 true color NTSC.      ----
----                                                                ----
---- Remarks:                                                       ----
---- The VIDEO_CTRL bit 7, controls the video data bus width. This  ----
---- feature is not supported in this core. There is a generic      ----
---- switch RAM_16 to handle a 16 or a 32 bit wide RAM data bus.    ----
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
-- Revision 2K15B  20141224 WF
--   Removed the F_PALETTE instance.
--   Replaced conv_integer by to_integer.
-- Revision 2K21A 20211224 WF
--   This is a complete code lifting with several changes and bug fixes.
-- Revision 2K24A 20240620 WF
--   True Colour modes fixed.
--

library work;
use work.VIDEL_PKG.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity VIDEO_CORE is
    generic(RAM_16      : boolean := false); -- Set true, if we have a 16 bit RAM data bus, false for 32 bit.
    port(
        CLK_32M0        : in std_logic; -- 32MHz clock input.
        CLK_25M175      : in std_logic; -- 52.175MHz clock input.
        CLK_EXT         : in std_logic; -- External clock input.
        RESET           : in std_logic;
        RWn             : in std_logic;
        VCS             : in std_logic; -- Videl chip select.
        ADR             : in std_logic_vector(11 downto 1);
        DATA_IN         : in std_logic_vector(15 downto 0);
        DATA_OUT        : out std_logic_vector(15 downto 0);
        DATA_EN         : out std_logic;

        VDATA_IN        : in std_logic_vector(63 downto 0);
        DE              : out std_logic;
        VDATA_REQ       : out std_logic;
        VDATA_ACK       : in std_logic;

        EVENn_ODD       : out std_logic;

        HSYNC           : out std_logic; -- Horizontal sync pulse.
        HSYNC_EN        : out std_logic;
        HSYNC_POL       : out std_logic;
        VSYNC           : out std_logic; -- Vertical sync pulse.
        VSYNC_EN        : out std_logic;
        VSYNC_POL       : out std_logic;
        CSYNC           : out std_logic; -- Composite video sync signal.
        COLOR           : out std_logic; -- Composite video sync signal for NTSC.

        HINT            : out std_logic; -- Vertical interrupt strobe.
        VINT            : out std_logic; -- Vertical interrupt strobe.

        DOTCK           : out std_logic;

        MONO            : out std_logic;
        
        R               : out std_logic_vector(7 downto 0);
        G               : out std_logic_vector(7 downto 0);
        B               : out std_logic_vector(7 downto 0)      
    );
end entity VIDEO_CORE;

architecture BEHAVIOR of VIDEO_CORE is
type VTYPES is(FALCON, STE);
type F_PALETTE_TYPE is array(0 to 255) of std_logic_vector(15 downto 0);
type ST_PALETTE_TYPE is array(0 to 15) of std_logic_vector(11 downto 0);
type SHIFTREG_TYPE is array(0 to 7) of std_logic_vector(15 downto 0);
type VBUFFER_TYPE is array(0 to 16) of std_logic_vector(31 downto 0);
signal F_PALETTE_HI         : F_PALETTE_TYPE;
signal F_PALETTE_LO         : F_PALETTE_TYPE;
signal ST_PALETTE           : ST_PALETTE_TYPE;
signal VTYPE                : VTYPES;
signal ADR_I                : std_logic_vector(11 downto 0);
signal SYNCMODE             : std_logic;
signal F_PALETTE_WREN_HI    : std_logic;
signal F_PALETTE_WREN_LO    : std_logic;
signal F_PALETTE_ADR        : std_logic_vector(7 downto 0);
signal F_PALETTE_DOUT_HI    : std_logic_vector(15 downto 0);
signal F_PALETTE_DOUT_LO    : std_logic_vector(15 downto 0);
signal SHIFTMODE_ST         : std_logic_vector(1 downto 0);
signal SHIFTMODE_F          : std_logic_vector(10 downto 0);
signal HSCROLL              : std_logic_vector(3 downto 0);
signal VIDEO_CTRL           : std_logic_vector(8 downto 0);
signal V_MODE               : std_logic_vector(3 downto 0);
signal HHC                  : std_logic_vector(8 downto 0); -- Horizontal Hold Counter.
signal HHT                  : std_logic_vector(8 downto 0); -- Horizontal Hold Timer.
signal HBB                  : std_logic_vector(8 downto 0); -- Horizontal Boarder Begin.
signal HBE                  : std_logic_vector(8 downto 0); -- Horizontal Boarder End.
signal HDB                  : std_logic_vector(9 downto 0); -- Horizontal Display begin.
signal HDE                  : std_logic_vector(8 downto 0); -- Horizontal Display End.
signal HSS                  : std_logic_vector(8 downto 0); -- Horizontal Sync Start.
signal HFS                  : std_logic_vector(8 downto 0); -- Horizontal Frame Start.
signal HFE                  : std_logic_vector(8 downto 0); -- Horizontal EE.
signal VFC                  : std_logic_vector(10 downto 0); -- Vertical Frequency Counter.
signal VFT                  : std_logic_vector(10 downto 0); -- Vertical Frequency Timer.
signal VBB                  : std_logic_vector(10 downto 0); -- Vertical Boarder Begin.
signal VBE                  : std_logic_vector(10 downto 0); -- Vertical Boarder End.
signal VDB                  : std_logic_vector(10 downto 0); -- Vertical Display Begin.
signal VDE                  : std_logic_vector(10 downto 0); -- Vertical Display End.
signal VSS                  : std_logic_vector(10 downto 0); -- Vertical Sync Start.
signal LINEWIDTH            : std_logic_vector(9 downto 0);
signal EVENn_ODD_I          : std_logic;
signal SEL_STE              : integer range 0 to 15;
signal R_PALETTE            : std_logic_vector(7 downto 0);
signal G_PALETTE            : std_logic_vector(7 downto 0);
signal B_PALETTE            : std_logic_vector(7 downto 0);
signal VDATA_ACK_I          : std_logic;
signal VDATA_REQ_I          : std_logic;
signal VIDEO_MODE           : VIDEO_MODES;
signal VIDEO_BUFFER         : VBUFFER_TYPE;
signal PALETTE_SEL          : std_logic_vector(7 downto 0); -- Selector for palette registers.
signal SHFT_REQ             : std_logic;
signal VBASE_CLK            : std_logic;
signal VIDEO_STRB           : std_logic;
signal SHFT_STRB            : std_logic;
signal BOARDER              : std_logic;
signal DE_I                 : std_logic;
signal HILOn                : std_logic; -- HILOn = '0' is the first half line.
signal VF_50_60n            : std_logic;
signal SR0_MSB              : std_logic;
signal HSYNC_I              : std_logic;
signal VSYNC_I              : std_logic;
signal HINT_I               : std_logic;
signal VINT_I               : std_logic;
begin
    CLOCK_DOMAIN_CROSSING: process(VBASE_CLK, CLK_32M0, VDATA_ACK_I)
    -- These flip flops working on the negative clock edge 
    -- bring the handshake signals to the VBASE_CLK and the
    -- CLK_32M0 clock domains.
    variable VDATA_REQ_S          : std_logic;
    begin
        if VBASE_CLK = '0' and VBASE_CLK' event then
            VDATA_ACK_I <= VDATA_ACK;
        end if;

        VDATA_REQ <= VDATA_REQ_S and not VDATA_ACK_I;
 
        if CLK_32M0 = '0' and CLK_32M0' event then
            VDATA_REQ_S := VDATA_REQ_I; -- This is the request synchronized to the CLK_32M0 clock domain.
            DE <= DE_I;
            HINT <= HINT_I;
            VINT <= VINT_I;
            EVENn_ODD <= EVENn_ODD_I;
        end if;
    end process CLOCK_DOMAIN_CROSSING;

    DOTCK <= VBASE_CLK;
    VBASE_CLK <= CLK_EXT when SYNCMODE = '1' else
                 CLK_32M0 when VIDEO_CTRL(2) = '0' else CLK_25M175; -- Video base clock, '0' = 32MHz - '1' = 25.175MHz.

    ADR_I <= ADR & '0';

    F_PALETTE_WREN_HI <= '1' when VCS = '1' and RWn = '0' and ADR_I >= x"800" and ADR_I(3 downto 2) < x"C00" and ADR_I(1) = '0' else '0';
    F_PALETTE_WREN_LO <= '1' when VCS = '1' and RWn = '0' and ADR_I >= x"800" and ADR_I(3 downto 2) < x"C00" and ADR_I(1) = '1' else '0';
    F_PALETTE_ADR <= ADR(9 downto 2) when VCS = '1' else -- Bus access.
                     PALETTE_SEL when VIDEO_MODE = F_8BITPL else 
                     x"00" when VIDEO_MODE = F_MONO else -- We need F_PALETTE_LO(0)(0) for Inversion signal.
                     SHIFTMODE_F(3 downto 0) & PALETTE_SEL(3 downto 0); -- Colour bank selection & palette selection.

    FALCON_PALETTE: process(CLK_32M0, F_PALETTE_HI, F_PALETTE_LO)
    -- This process is written in that manner, that 8192 bits
    -- RAM will be inferred.
    variable F_PALETTE_ADR_PNTR   : integer range 0 to 255;
    begin
        if CLK_32M0 = '1' and CLK_32M0' event then
            F_PALETTE_ADR_PNTR := To_Integer(unsigned(F_PALETTE_ADR));
            if F_PALETTE_WREN_HI = '1' then
                F_PALETTE_HI(F_PALETTE_ADR_PNTR) <= DATA_IN;
            end if;
            --
            if F_PALETTE_WREN_LO = '1' then
                F_PALETTE_LO(F_PALETTE_ADR_PNTR) <= DATA_IN;
            end if;        
        end if;
        F_PALETTE_DOUT_HI <= F_PALETTE_HI(F_PALETTE_ADR_PNTR);
        F_PALETTE_DOUT_LO <= F_PALETTE_LO(F_PALETTE_ADR_PNTR);
    end process FALCON_PALETTE;
    
    VIDEO_REGISTERS: process
    -- This set of registers define the programming model of the VIDEL.
    -- This logic is conform to the VIDEL specification. See related 
    -- documents for detailed information.
    begin -- The initial setting is ST low resolution.
        wait until CLK_32M0 = '1' and CLK_32M0' event;
        if RESET = '1' then
            SYNCMODE <= '0';
            SHIFTMODE_ST <= (others => '0');
            SHIFTMODE_F <= (others => '0');
            HSCROLL <= (others => '0');
            V_MODE <= (others => '0');
            ST_PALETTE <= (others => (others => '0'));
            HHT <= "000111110"; -- x"03E".
            HBB <= "000110010"; -- x"032".
            HBE <= "000001001"; -- x"009".
            HDB <= "1000111111"; -- x"23F".
            HDE <= "000011100"; -- x"01C".
            HSS <= "000110100"; -- x"034".
            HFS <= (others => '0');
            HFE <= (others => '0');
            VFT <= "01001110001"; -- x"271".
            VBB <= "01001100101"; -- x"265".
            VBE <= "00000101111"; -- x"02F".
            VDB <= "00001101111"; -- x"06F".
            VDE <= "00111111111"; -- x"1FF".
            VSS <= "01001101011"; -- x"26B".
            VIDEO_CTRL <= "010000001"; -- x"081". Default is RGB monitor.
            LINEWIDTH <= (others => '0');
        elsif VCS = '1' and ADR_I = x"210" and RWn = '0' then -- x"FFFF8210".
            LINEWIDTH <= DATA_IN(9 downto 0);
        elsif VCS = '1' and ADR_I = x"20A" and RWn = '0' then -- x"FFFF820A".
            SYNCMODE <= DATA_IN(8);
        elsif VCS = '1' and ADR_I >= x"240" and ADR_I <= x"25E" and RWn = '0' then -- STE Pallette registers.
            case ADR_I is
                when x"25E" => ST_PALETTE(15) <= DATA_IN(11 downto 0); -- x"FFF825E - FFFF825F"
                when x"25C" => ST_PALETTE(14) <= DATA_IN(11 downto 0);
                when x"25A" => ST_PALETTE(13) <= DATA_IN(11 downto 0);
                when x"258" => ST_PALETTE(12) <= DATA_IN(11 downto 0);
                when x"256" => ST_PALETTE(11) <= DATA_IN(11 downto 0);
                when x"254" => ST_PALETTE(10) <= DATA_IN(11 downto 0);
                when x"252" => ST_PALETTE(9) <= DATA_IN(11 downto 0);
                when x"250" => ST_PALETTE(8) <= DATA_IN(11 downto 0);
                when x"24E" => ST_PALETTE(7) <= DATA_IN(11 downto 0);
                when x"24C" => ST_PALETTE(6) <= DATA_IN(11 downto 0);
                when x"24A" => ST_PALETTE(5) <= DATA_IN(11 downto 0);
                when x"248" => ST_PALETTE(4) <= DATA_IN(11 downto 0);
                when x"246" => ST_PALETTE(3) <= DATA_IN(11 downto 0);
                when x"244" => ST_PALETTE(2) <= DATA_IN(11 downto 0);
                when x"242" => ST_PALETTE(1) <= DATA_IN(11 downto 0);
                when x"240" => ST_PALETTE(0) <= DATA_IN(11 downto 0); -- x"FFF8240 - FFFF8241"
                when others =>
                    null;
            end case;
        elsif VCS = '1' and ADR_I = x"260" and RWn = '0' then -- x"FFFF8260"
            SHIFTMODE_ST <= DATA_IN(9 downto 8); -- SHIFTMODE_ST write access.

            if SHIFTMODE_F(10) = '0' and SHIFTMODE_F(8) = '0' and SHIFTMODE_F(4) = '0' then
                if VIDEO_CTRL(1 downto 0) = "10" then -- VGA monitor.
                    case DATA_IN(9 downto 8) is
                        when "00" => V_MODE <= x"5"; --4 planes/320x200 Pixels. Doubleline active.
                        when "01" => V_MODE <= x"9"; --2 planes/640x200 Pixels. Doubleline active.
                        when "10" => V_MODE <= x"8"; --1 plane /640x400 Pixels.
                        when others => V_MODE <= x"0"; -- Reserved.
                    end case;
                elsif VIDEO_CTRL(1 downto 0) = "00" then -- SM124.
                    HHT <= "000011010"; -- x"01A"
                    HDB <= "1000001111"; -- x"20F"
                    HDE <= "000001100"; -- x"00C"
                    HSS <= "000010100"; -- x"014"
                    VFT <= "01111101001"; -- x"3E9"
                    VDB <= "00001000011"; -- x"043"
                    VDE <= "01101100011"; -- x"363"
                    VSS <= "01111100111"; -- x"3E7"
                    VIDEO_CTRL(8 downto 2) <= "0100000"; -- x"080".
                    V_MODE <= x"8";
                else -- Other monitor types (RGB).
                    HHT <= "000111110"; -- x"03E"
                    HBB <= "000110010"; -- x"032"
                    HBE <= "000001001"; -- x"009"
                    HDB <= "1000111111"; -- x"23F"
                    HDE <= "000011100"; -- x"01C"
                    HSS <= "000110100"; -- x"034"
                    VFT <= "01001110001"; -- x"271"
                    VBB <= "01001100101"; -- x"265"
                    VBE <= "00000101111"; -- x"02F"
                    VDB <= "00001101111"; -- x"06F"
                    VDE <= "00111111111"; -- x"1FF"
                    VSS <= "01001101011"; -- x"26B"
                    VIDEO_CTRL(8 downto 2) <= "0100000"; -- x"081".
                    case DATA_IN(9 downto 8) is
                        when "00" => V_MODE <= x"0"; --4 planes/320x200 Pixels.
                        when "01" => V_MODE <= x"4"; --2 planes/640x200 Pixels.
                        when "10" => V_MODE <= x"6"; --1 plane /640x400 Pixels. Interlaced active.
                        when others => V_MODE <= x"0"; -- Reserved.
                    end case;
                end if;
            end if;
        elsif VCS = '1' and ADR_I = x"264" and RWn = '0' then -- x"FFFF8265"
            HSCROLL <= DATA_IN(3 downto 0);
        elsif VCS = '1' and ADR_I = x"266" and RWn = '0' then -- x"FFFF8266 - FFFF8267"
            SHIFTMODE_F <= DATA_IN(10 downto 0);

            -- The following are the default settings for RGBs like
            -- the SC1224. Be aware that these values require the 
            -- LINEWIDTH register to be written first.
            if VIDEO_CTRL(1 downto 0) = "01" then -- RGB moitor.
                if DATA_IN(10) = '1' then -- Monochrome mode 2/80.
                    HHT <= "111111110"; -- x"1FE"
                    HBB <= "110011001"; -- x"199"
                    HBE <= "001010000"; -- x"050"
                    HDB <= "1111101111"; -- x"3EF"
                    HDE <= "010100000"; -- x"0A0"
                    HSS <= "110110010"; -- x"1B2"
                elsif DATA_IN(8) = '1' and LINEWIDTH = b"10_1000_0000" then -- True colour /80 mode.
                    HHT <= "111111110"; -- x"1FE"
                    HBB <= "110011001"; -- x"199"
                    HBE <= "001010000"; -- x"050"
                    HDB <= "0001110001"; -- x"071"
                    HDE <= "100100010"; -- x"122"
                    HSS <= "110110010"; -- x"1B2"
                elsif DATA_IN(8) = '1' then -- True colour /40 mode.
                    HHT <= "011111110"; -- x"0FE"
                    HBB <= "011001011"; -- x"0CB"
                    HBE <= "000100111"; -- x"027"
                    HDB <= "0000101110"; -- x"02E"
                    HDE <= "010001111"; -- x"08F"
                    HSS <= "011011000"; -- x"0D8"
                elsif DATA_IN(4) = '1' and LINEWIDTH = b"01_0100_0000" then -- 8 bitplane (256 colour) /80 mode.
                    HHT <= "111111110"; -- x"1FE"
                    HBB <= "110011001"; -- x"199"
                    HBE <= "001010000"; -- x"050"
                    HDB <= "0001011101"; -- x"05D"
                    HDE <= "100001110"; -- x"10E"
                    HSS <= "110110010"; -- x"1B2"
                elsif DATA_IN(4) = '1' then -- 8 bitplane (256 colour) /40 mode.
                    HHT <= "011111110"; -- x"0FE"
                    HBB <= "011001011"; -- x"0CB"
                    HBE <= "000100111"; -- x"027"
                    HDB <= "0000011100"; -- x"01C"
                    HDE <= "001111101"; -- x"07D"
                    HSS <= "011011000"; -- x"0D8"
                elsif LINEWIDTH = b"00_1010_0000" then -- 4 bitplane (16 colour) /80 mode.
                    HHT <= "111111110"; -- x"1FE"
                    HBB <= "110011001"; -- x"199"
                    HBE <= "001010000"; -- x"050"
                    HDB <= "0001001101"; -- x"04D"
                    HDE <= "011111110"; -- x"0FE"
                    HSS <= "110110010"; -- x"1B2"
                else -- 4 bitplane (16 colour) /40 mode.
                    HHT <= "011111110"; -- x"0FE"
                    HBB <= "011001011"; -- x"0CB"
                    HBE <= "000100111"; -- x"027"
                    HDB <= "0000001100"; -- x"00C"
                    HDE <= "001101101"; -- x"06D"
                    HSS <= "011011000"; -- x"0D8"
                end if;

                VFT <= "01001110001"; -- x"271"
                VBB <= "01001100101"; -- x"265"
                VBE <= "00000101111"; -- x"02F"
                VDB <= "00001111111"; -- x"07F"
                VDE <= "01000001111"; -- x"20F"
                VSS <= "01001101011"; -- x"26B"
                VIDEO_CTRL(8 downto 2) <= "1100000"; -- x"181".            
            end if;
        elsif VCS = '1' and ADR_I = x"282" and RWn = '0' then -- x"FFFF8282 - FFFF8283"
            HHT <= DATA_IN(8 downto 0);
        elsif VCS = '1' and ADR_I = x"284" and RWn = '0' then -- x"FFFF8284 - FFFF8285"
            HBB <= DATA_IN(8 downto 0);
        elsif VCS = '1' and ADR_I = x"286" and RWn = '0' then -- x"FFFF8286 - FFFF8287"
            HBE <= DATA_IN(8 downto 0);
        elsif VCS = '1' and ADR_I = x"288" and RWn = '0' then -- x"FFFF8288 - FFFF8289"
            HDB <= DATA_IN(9 downto 0);
        elsif VCS = '1' and ADR_I = x"28A" and RWn = '0' then -- x"FFFF828A - FFFF828B"
            HDE <= DATA_IN(8 downto 0);
        elsif VCS = '1' and ADR_I = x"28C" and RWn = '0' then -- x"FFFF828C - FFFF828D"
            HSS <= DATA_IN(8 downto 0);
        elsif VCS = '1' and ADR_I = x"28E" and RWn = '0' then -- x"FFFF828E - FFFF828F"
            HFS <= DATA_IN(8 downto 0);
        elsif VCS = '1' and ADR_I = x"290" and RWn = '0' then -- x"FFFF8290 - FFFF82891"
            HFE <= DATA_IN(8 downto 0);
        elsif VCS = '1' and ADR_I = x"2A2" and RWn = '0' then -- x"FFFF82A2 - FFFF82A3"
            VFT <= DATA_IN(10 downto 0);
        elsif VCS = '1' and ADR_I = x"2A4" and RWn = '0' then -- x"FFFF82A4 - FFFF82A5"
            VBB <= DATA_IN(10 downto 0);
        elsif VCS = '1' and ADR_I = x"2A6" and RWn = '0' then -- x"FFFF82A6 - FFFF82A7"
            VBE <= DATA_IN(10 downto 0);
        elsif VCS = '1' and ADR_I = x"2A8" and RWn = '0' then -- x"FFFF82A8 - FFFF82A9"
            VDB <= DATA_IN(10 downto 0);
        elsif VCS = '1' and ADR_I = x"2AA" and RWn = '0' then -- x"FFFF82AA - FFFF82AB"
            VDE <= DATA_IN(10 downto 0);
        elsif VCS = '1' and ADR_I = x"2AC" and RWn = '0' then -- x"FFFF82AC - FFFF82AD"
            VSS <= DATA_IN(10 downto 0);
        elsif VCS = '1' and ADR_I = x"2C0" and RWn = '0' then -- x"FFFF82C0 - FFFF82C1"
            VIDEO_CTRL(8 downto 2) <= DATA_IN(8 downto 2);
        elsif VCS = '1' and ADR_I = x"006" and RWn = '1' then -- x"FFFF8006.
            VIDEO_CTRL(1 downto 0) <= DATA_IN(15 downto 14); -- Reading the Halfmoons set these bits.
        elsif VCS = '1' and ADR_I = x"2C2" and RWn = '0' then -- x"FFFF82C2 - FFFF82C3"
            V_MODE <= DATA_IN(3 downto 0);
        end if;
    end process VIDEO_REGISTERS;

    -- Unused bits read back as '0';
    DATA_OUT <= x"00" & "000000" & VF_50_60n & SYNCMODE when VCS = '1' and ADR_I = x"20A" and RWn = '1' else 
                x"0" & ST_PALETTE(0) when VCS = '1' and ADR_I = x"240" and RWn = '1' else
                x"0" & ST_PALETTE(1) when VCS = '1' and ADR_I = x"242" and RWn = '1' else
                x"0" & ST_PALETTE(2) when VCS = '1' and ADR_I = x"244" and RWn = '1' else
                x"0" & ST_PALETTE(3) when VCS = '1' and ADR_I = x"246" and RWn = '1' else
                x"0" & ST_PALETTE(4) when VCS = '1' and ADR_I = x"248" and RWn = '1' else
                x"0" & ST_PALETTE(5) when VCS = '1' and ADR_I = x"24A" and RWn = '1' else
                x"0" & ST_PALETTE(6) when VCS = '1' and ADR_I = x"24C" and RWn = '1' else
                x"0" & ST_PALETTE(7) when VCS = '1' and ADR_I = x"24E" and RWn = '1' else
                x"0" & ST_PALETTE(8) when VCS = '1' and ADR_I = x"250" and RWn = '1' else
                x"0" & ST_PALETTE(9) when VCS = '1' and ADR_I = x"252" and RWn = '1' else
                x"0" & ST_PALETTE(10) when VCS = '1' and ADR_I = x"254" and RWn = '1' else
                x"0" & ST_PALETTE(11) when VCS = '1' and ADR_I = x"256" and RWn = '1' else
                x"0" & ST_PALETTE(12) when VCS = '1' and ADR_I = x"258" and RWn = '1' else
                x"0" & ST_PALETTE(13) when VCS = '1' and ADR_I = x"25A" and RWn = '1' else
                x"0" & ST_PALETTE(14) when VCS = '1' and ADR_I = x"25C" and RWn = '1' else
                x"0" & ST_PALETTE(15) when VCS = '1' and ADR_I = x"25E" and RWn = '1' else
                "000000" & SHIFTMODE_ST & x"00" when VCS = '1' and ADR_I = x"260" and RWn = '1' else
                x"0" & HSCROLL & x"0" & HSCROLL when VCS = '1' and ADR_I = x"264" and RWn = '1' else -- Left is Shadow.
                "00000" & SHIFTMODE_F when VCS = '1' and ADR_I = x"266" and RWn = '1' else
                "0000000" & HHC when VCS = '1' and ADR_I = x"280" and RWn = '1' else
                "0000000" & HHT when VCS = '1' and ADR_I = x"282" and RWn = '1' else
                "0000000" & HBB when VCS = '1' and ADR_I = x"284" and RWn = '1' else
                "0000000" & HBE when VCS = '1' and ADR_I = x"286" and RWn = '1' else
                "000000" & HDB when VCS = '1' and ADR_I = x"288" and RWn = '1' else
                "0000000" & HDE when VCS = '1' and ADR_I = x"28A" and RWn = '1' else
                "0000000" & HSS when VCS = '1' and ADR_I = x"28C" and RWn = '1' else
                "0000000" & HFS when VCS = '1' and ADR_I = x"28E" and RWn = '1' else
                "0000000" & HFE when VCS = '1' and ADR_I = x"290" and RWn = '1' else
                "00000" & VFC when VCS = '1' and ADR_I = x"2A0" and RWn = '1' else
                "00000" & VFT when VCS = '1' and ADR_I = x"2A2" and RWn = '1' else
                "00000" & VBB when VCS = '1' and ADR_I = x"2A4" and RWn = '1' else
                "00000" & VBE when VCS = '1' and ADR_I = x"2A6" and RWn = '1' else
                "00000" & VDB when VCS = '1' and ADR_I = x"2A8" and RWn = '1' else
                "00000" & VDE when VCS = '1' and ADR_I = x"2AA" and RWn = '1' else
                "00000" & VSS when VCS = '1' and ADR_I = x"2AC" and RWn = '1' else
                "0000000" & VIDEO_CTRL when VCS = '1' and ADR_I = x"2C0" and RWn = '1' else
                x"000" & V_MODE when VCS = '1' and ADR_I = x"2C2" and RWn = '1' else
                F_PALETTE_DOUT_HI when VCS = '1' and ADR_I >= x"800" and ADR_I < x"C00" and ADR_I(1) = '0' and RWn = '1' else F_PALETTE_DOUT_LO;

    DATA_EN <=  '1' when VCS = '1' and RWn = '1' else '0';

    VTYPE_SWITCH: process
    -- This Flip Flop determines whether the video system
    -- works in Falcon or in ST Mode.
    begin
        wait until CLK_32M0 = '1' and CLK_32M0' event;
        if RESET = '1' then
            VTYPE <= STE;
        elsif VCS = '1' and ADR_I = x"260" and RWn = '0' then -- SHIFTMODE_ST write access.
            if SHIFTMODE_F(10) = '0' and SHIFTMODE_F(8) = '0' and SHIFTMODE_F(4) = '0' then
                VTYPE <= STE;
            end if;
        elsif VCS = '1' and ADR_I = x"266" and RWn = '0' then -- SHIFTMODE_F write access.
            VTYPE <= FALCON;
        end if;
    end process VTYPE_SWITCH;

    VFIFO: process
    -- This is the video data FIFO buffer. it works as follows:
    -- The FIFO is loaded from the VDATA bus each time a VDATA_ACK indicates new video data. The bus
    -- width of VDATA is 32 bit. The loading increments a load pointer. Each video data request forces
    -- 17 32bit wide long words to be loaded into this FIFO (in a burst) unaffected of the readout by
    -- video data requests of the shifter or the true colour mode. The VDATA_REQ is controlled in a way,
    -- that an overflow of FIFO should never appear. Nevertheless, the FIFO logic permits a further
    -- loading of video data, if it is full. This condition is indicated by the L32_PNTR value of 17.
    -- In case of a video shifter or true colour video data request, the video data is read and written 
    -- simultaneously depending on the selected video mode.
    variable L32_PNTR       : integer range 0 to 17;
    variable WORDSWAP       : boolean;
    begin
        wait until VBASE_CLK = '1' and VBASE_CLK' event;
        if VIDEO_STRB = '1' and VFC = VFT and HHC = HHT then
            WORDSWAP := false; -- Be aware that initial shift register loading sets this flip flop. Data is read from old address!
            --WORDSWAP := true; -- This is a necessary condition to start shifting  with correct data.
            L32_PNTR := 0;
        elsif (VIDEO_MODE = F_TRUEC and DE_I = '1' and SHFT_STRB = '1') or (VIDEO_MODE /= F_TRUEC and SHFT_REQ = '1') then
            case VIDEO_MODE is
                when F_8BITPL => -- Eight bitplanes. 4 LONG.
                    if L32_PNTR > 3 then
                        for i in 0 to 12 loop
                            VIDEO_BUFFER(i) <= VIDEO_BUFFER(i + 4);
                        end loop;
                        if RAM_16 = true and VDATA_ACK_I = '1' then -- There is new video data in the pipeline.
                            VIDEO_BUFFER(L32_PNTR -4) <= VDATA_IN(31 downto 0);
                            L32_PNTR := L32_PNTR - 3;
                        elsif RAM_16 = false and VDATA_ACK_I = '1' then -- There is new video data in the pipeline.
                            VIDEO_BUFFER(L32_PNTR -4) <= VDATA_IN(63 downto 32);
                            VIDEO_BUFFER(L32_PNTR -3) <= VDATA_IN(31 downto 0);
                            L32_PNTR := L32_PNTR - 2;
                        else
                            L32_PNTR := L32_PNTR - 4;
                        end if;
                    end if;
                when F_4BITPL | STE_LOW => -- Four Bitplanes. 2 LONG.
                    if L32_PNTR > 1 then
                        for i in 0 to 14 loop
                            VIDEO_BUFFER(i) <= VIDEO_BUFFER(i + 2);
                        end loop;
                        if RAM_16 = true and VDATA_ACK_I = '1' then -- There is new video data in the pipeline.
                            VIDEO_BUFFER(L32_PNTR - 2) <= VDATA_IN(31 downto 0);
                            L32_PNTR := L32_PNTR - 1;
                        elsif RAM_16 = false and VDATA_ACK_I = '1' then -- There is new video data in the pipeline.
                            VIDEO_BUFFER(L32_PNTR - 2) <= VDATA_IN(63 downto 32);
                            VIDEO_BUFFER(L32_PNTR - 1) <= VDATA_IN(31 downto 0);
                            --L32_PNTR := L32_PNTR; No change here.
                        else
                            L32_PNTR := L32_PNTR - 2;
                        end if;
                    end if;
                when STE_MID => -- Two Bitplanes, 1 LONG.
                    if L32_PNTR > 0 then
                        for i in 0 to 15 loop
                            VIDEO_BUFFER(i) <= VIDEO_BUFFER(i + 1);
                        end loop;
                        if RAM_16 = true and VDATA_ACK_I = '1' then -- There is new video data in the pipeline.
                            VIDEO_BUFFER(L32_PNTR - 1) <= VDATA_IN(31 downto 0);
                        elsif RAM_16 = false and VDATA_ACK_I = '1' then -- There is new video data in the pipeline.
                            VIDEO_BUFFER(L32_PNTR - 1) <= VDATA_IN(63 downto 32);
                            VIDEO_BUFFER(L32_PNTR) <= VDATA_IN(31 downto 0);
                            L32_PNTR := L32_PNTR + 1;
                        else
                            L32_PNTR := L32_PNTR - 1;
                        end if;    
                    end if;
                when F_MONO | STE_MONO | F_TRUEC => -- 1 LONG. We wrap around one word.
                    if WORDSWAP = false then                        
                        if RAM_16 = true and VDATA_ACK_I = '1' and L32_PNTR < 17 then -- There is new video data in the pipeline.
                            VIDEO_BUFFER(L32_PNTR) <= VDATA_IN(31 downto 0);
                            L32_PNTR := L32_PNTR + 1;
                        elsif RAM_16 = false and VDATA_ACK_I = '1' and L32_PNTR < 17 then -- There is new video data in the pipeline.
                            VIDEO_BUFFER(L32_PNTR) <= VDATA_IN(63 downto 32);
                            VIDEO_BUFFER(L32_PNTR + 1) <= VDATA_IN(31 downto 0);
                            L32_PNTR := L32_PNTR + 2;
                        end if;
                        VIDEO_BUFFER(0) <= VIDEO_BUFFER(0)(15 downto 0) & x"0000";
                        WORDSWAP := true;
                    elsif L32_PNTR > 0 then -- There is new video data in the pipeline.
                        for i in 0 to 15 loop
                            VIDEO_BUFFER(i) <= VIDEO_BUFFER(i+1);
                        end loop;
                        if RAM_16 = true and VDATA_ACK_I = '1' then
                            VIDEO_BUFFER(L32_PNTR -1) <= VDATA_IN(31 downto 0);
                        elsif RAM_16 = false and VDATA_ACK_I = '1' then
                            VIDEO_BUFFER(L32_PNTR -1) <= VDATA_IN(63 downto 32);
                            VIDEO_BUFFER(L32_PNTR) <= VDATA_IN(31 downto 0);
                            L32_PNTR := L32_PNTR + 1;
                        else
                            L32_PNTR := L32_PNTR - 1;
                        end if;
                        WORDSWAP := false;
                    end if;
            end case;
        elsif RAM_16 = true and VDATA_ACK_I = '1' and L32_PNTR < 16 then
            VIDEO_BUFFER(L32_PNTR) <= VDATA_IN(31 downto 0);
            L32_PNTR := L32_PNTR + 1;
        elsif RAM_16 = false and VDATA_ACK_I = '1' and L32_PNTR < 16 then
            VIDEO_BUFFER(L32_PNTR) <= VDATA_IN(63 downto 32);
            VIDEO_BUFFER(L32_PNTR +1) <= VDATA_IN(31 downto 0);
            L32_PNTR := L32_PNTR + 2;
        end if;
        --
        if L32_PNTR < 5 then -- Minimum of four LONG are required for eight bitplanes.
            VDATA_REQ_I <= '1';
        elsif L32_PNTR >= 16 then -- We load two LONG...
            VDATA_REQ_I <= '0';
        end if;
    end process VFIFO;

    P_SHIFTER: process
    -- These are the eight video shift registers. To simplify the logic,
    -- the registers are all loaded and shifted unaffected of the selected
    -- video mode. This behaviour does not affect the correct function
    -- because the registers of interest are selected by the video mode.
    variable SHIFTREGS      : SHIFTREG_TYPE;
    variable PIX_CNT        : integer range 0 to 15;
    variable H_SHIFT        : integer range 0 to 15;
    variable LOCK           : boolean;
    begin
        wait until VBASE_CLK = '1' and VBASE_CLK' event;
        SHFT_REQ <= '0'; -- This signal is a strobe.
        if (VIDEO_STRB = '1' and VFC = VDB - '1' and HHC = HHT) or -- This is the initial shift register load after a vertical sync.
           (DE_I = '1' and SHFT_STRB = '1' and PIX_CNT = 0) then -- This is normal shift register load.
            SHIFTREGS(7) := VIDEO_BUFFER(3)(15 downto 0);
            SHIFTREGS(6) := VIDEO_BUFFER(3)(31 downto 16);
            SHIFTREGS(5) := VIDEO_BUFFER(2)(15 downto 0);
            SHIFTREGS(4) := VIDEO_BUFFER(2)(31 downto 16);
            SHIFTREGS(3) := VIDEO_BUFFER(1)(15 downto 0);
            SHIFTREGS(2) := VIDEO_BUFFER(1)(31 downto 16);
            SHIFTREGS(1) := VIDEO_BUFFER(0)(15 downto 0);
            SHIFTREGS(0) := VIDEO_BUFFER(0)(31 downto 16);
            --
            SHFT_REQ <= '1';
            PIX_CNT := 15;
        elsif DE_I = '1' and SHFT_STRB = '1' then
            for i in 7 downto 0 loop
                SHIFTREGS(i) := SHIFTREGS(i)(14 downto 0) & '0'; -- Shift left.
            end loop;
            PIX_CNT := PIX_CNT - 1;
        end if;
        --
        H_SHIFT := To_Integer(unsigned(HSCROLL));
        --
        for i in 7 downto 0 loop
            PALETTE_SEL(i) <= SHIFTREGS(i)(15 - H_SHIFT);
        end loop;
        --
        -- This is for the monochrome modes:
        SR0_MSB <= SHIFTREGS(0)(15 - H_SHIFT);
    end process P_SHIFTER;

    SEL_STE <= Conv_Integer(PALETTE_SEL(3 downto 0)) when VIDEO_MODE = STE_LOW else 
               Conv_Integer("00" & PALETTE_SEL(1 downto 0)) when VIDEO_MODE = STE_MID else Conv_Integer("000" & PALETTE_SEL(0));
        
    -- Control outputs:
    R_PALETTE <= ST_PALETTE(SEL_STE)(10 downto 8) & ST_PALETTE(SEL_STE)(11) & x"0" when VTYPE = STE else F_PALETTE_DOUT_HI(15 downto 8);
    G_PALETTE <= ST_PALETTE(SEL_STE)(6 downto 4) & ST_PALETTE(SEL_STE)(7) & x"0" when VTYPE = STE else F_PALETTE_DOUT_HI(7 downto 0);
    B_PALETTE <= ST_PALETTE(SEL_STE)(2 downto 0) & ST_PALETTE(SEL_STE)(3) & x"0" when VTYPE = STE else F_PALETTE_DOUT_LO(7 downto 0);

    VIDEO_MODE <= F_MONO when SHIFTMODE_F(10) = '1' and VTYPE = FALCON else
                  F_TRUEC when SHIFTMODE_F(8) = '1' and VTYPE = FALCON else
                  F_8BITPL when SHIFTMODE_F(4) = '1' and VTYPE = FALCON else
                  F_4BITPL when VTYPE = FALCON else
                  STE_LOW when SHIFTMODE_ST = "00" else
                  STE_MID when SHIFTMODE_ST = "01" else STE_MONO;

    VF_50_60n <= '0' when VIDEO_CTRL(1 downto 0) = "00" else '1'; -- Monochrome (SM124) is 60Hz.

    -- Monochrome video: this signal is used for video information in the
    -- monochrome modes. It is used as overlay switch in the true colour
    -- video mode. If overlay is active in the true colour mode, bit 5 
    -- of the video buffer determines the insertion of external video.
    -- See the Developer Support Package for the Atari Falcon030 for
    -- further information.
    MONO <= '0' when DE_I = '0' else
            '0' when VFC = VDE or VFC = VDB else -- SM124: cut first and last line.
            SR0_MSB xor F_PALETTE_DOUT_LO(0) when VIDEO_MODE = F_MONO else
            SR0_MSB xor ST_PALETTE(0)(0) when VIDEO_MODE = STE_MONO else 
            '1' when VIDEO_MODE = F_TRUEC and SHIFTMODE_F(9) = '1' and VIDEO_BUFFER(0)(5) = '1' else '0'; -- Overlay.

    -- True colour is RrrrrGgggggBbbbb.
    R <= x"00" when BOARDER = '1' else
         x"FF" when VIDEO_CTRL(1 downto 0) = "01" and DE_I = '0' else -- SC1224 has white boarders.
         x"FF" when VIDEO_CTRL(1 downto 0) = "01" and VFC = VDB else -- SC1224: cut first line.
         x"FF" when VIDEO_CTRL(1 downto 0) = "01" and VFC = VDE else -- SC1224 cut last line.
         VIDEO_BUFFER(0)(31 downto 27) & "000" when VIDEO_MODE = F_TRUEC else 
         x"FF" when (SR0_MSB xor F_PALETTE_DOUT_LO(0)) = '1' and VIDEO_MODE = F_MONO else
         x"00" when VIDEO_MODE = F_MONO else
         x"FF" when (SR0_MSB xor ST_PALETTE(0)(0)) = '1' and VIDEO_MODE = STE_MONO else 
         x"00" when VIDEO_MODE = STE_MONO else R_PALETTE;

    G <= x"00" when BOARDER = '1' else
         x"FF" when VIDEO_CTRL(1 downto 0) = "01" and DE_I = '0' else -- SC1224 has white boarders.
         x"FF" when VIDEO_CTRL(1 downto 0) = "01" and VFC = VDB else -- SC1224: cut first line.
         x"FF" when VIDEO_CTRL(1 downto 0) = "01" and VFC = VDE else -- SC1224 cut last line.
         VIDEO_BUFFER(0)(26 downto 22) & "000" when VIDEO_MODE = F_TRUEC else
         x"FF" when (SR0_MSB xor F_PALETTE_DOUT_LO(0)) = '1' and VIDEO_MODE = F_MONO else
         x"00" when VIDEO_MODE = F_MONO else
         x"FF" when (SR0_MSB xor ST_PALETTE(0)(0)) = '1' and VIDEO_MODE = STE_MONO else 
         x"00" when VIDEO_MODE = STE_MONO else G_PALETTE;

    B <= x"00" when BOARDER = '1' else 
         x"FF" when VIDEO_CTRL(1 downto 0) = "01" and DE_I = '0' else -- SC1224 has white boarders.
         x"FF" when VIDEO_CTRL(1 downto 0) = "01" and VFC = VDB else -- SC1224: cut first line.
         x"FF" when VIDEO_CTRL(1 downto 0) = "01" and VFC = VDE else -- SC1224 cut last line.
         VIDEO_BUFFER(0)(20 downto 16) & "000" when VIDEO_MODE = F_TRUEC else
         x"FF" when (SR0_MSB xor F_PALETTE_DOUT_LO(0)) = '1' and VIDEO_MODE = F_MONO else
         x"00" when VIDEO_MODE = F_MONO else
         x"FF" when (SR0_MSB xor ST_PALETTE(0)(0)) = '1' and VIDEO_MODE = STE_MONO else 
         x"00" when VIDEO_MODE = STE_MONO else B_PALETTE;

    VIDEO_STROBES: process
    variable VCNT   : std_logic_vector(3 downto 0);
    begin
        wait until VBASE_CLK = '1' and VBASE_CLK' event;
        --
        VCNT := VCNT + '1';
        --
        if VTYPE = STE then -- STE compatibility mode.
            case VCNT is
                when x"0" => VIDEO_STRB <= '1'; -- VBASE_CLK/16.
                when others => VIDEO_STRB <= '0';
            end case;
        elsif VIDEO_CTRL(1 downto 0) = "10" then -- VGA monitor.
            case V_MODE(3 downto 2) is
                when "00" =>
                    case VCNT is
                        when x"0" | x"4" | x"8" | x"C" => VIDEO_STRB <= '1'; -- VBASE_CLK/4.
                        when others => VIDEO_STRB <= '0';
                    end case;
                when "01" | "10" =>
                    case VCNT is
                        when x"0" | x"2" | x"4" | x"6" | x"8" | x"A" | x"C" | x"E" => VIDEO_STRB <= '1'; -- VBASE_CLK/2.
                        when others => VIDEO_STRB <= '0';
                    end case;
                when others => VIDEO_STRB <= '0'; -- Off.
            end case;
        else -- All other video modes.
            case V_MODE(3 downto 2) is
                when "00" =>
                    case VCNT is
                        when x"0" | x"4" | x"8" | x"C" => VIDEO_STRB <= '1'; -- VBASE_CLK/4.
                        when others => VIDEO_STRB <= '0';
                    end case;
                when "01" =>
                    case VCNT is
                        when x"0" | x"2" | x"4" | x"6" | x"8" | x"A" | x"C" | x"E" => VIDEO_STRB <= '1'; -- VBASE_CLK/2.
                        when others => VIDEO_STRB <= '0';
                    end case;
                when "10" => VIDEO_STRB <= '1';
                when others => VIDEO_STRB <= '0'; -- Off.
            end case;
        end if;
        --
        case V_MODE(3 downto 2) is
            when "00" =>
                case VCNT is
                    when x"0" | x"4" | x"8" | x"C" => SHFT_STRB <= '1'; -- 4 cycles.
                    when others => SHFT_STRB <= '0';
                end case;
            when "01" =>
                case VCNT is
                    when x"0" | x"2" | x"4" | x"6" | x"8" | x"A" | x"C" | x"E" => SHFT_STRB <= '1'; -- 2 cycles.
                    when others => SHFT_STRB <= '0';
                end case;
            when "10" => SHFT_STRB <= '1'; -- One cycle.
            when others => SHFT_STRB <= '0'; -- Off.
        end case;
    end process VIDEO_STROBES;
    
    HORIZONTAL_TIMING: process
    begin
        wait until VBASE_CLK = '1' and VBASE_CLK' event;
        if VIDEO_STRB = '1' and HHC < HHT then
            HHC <= HHC + '1';
        elsif VIDEO_STRB = '1' then
            HHC <= (others => '0');
        end if;
    end process HORIZONTAL_TIMING;

    VERTICAL_TIMING: process
    begin
        wait until VBASE_CLK = '1' and VBASE_CLK' event;        
        if VIDEO_STRB = '1' and HHC = HHT and VFC < VFT then
            VFC <= VFC + '1';
        elsif VIDEO_STRB = '1' and HHC = HHT then
            VFC <= (others => '0');
            EVENn_ODD_I <= not EVENn_ODD_I; 
        end if;
    end process VERTICAL_TIMING;

    -- This half line indicator is derived from the vertical half lines.
    HILOn <= not VFC(0) when VDB(0) = '1' else VFC(0);

    COLOR_TIMING: process
    -- This logic is a simple divider by 7. If driven
    -- from a CLK_25M175 clock source it provides a
    -- COLOR signal of 3.58MHz for a video modulator 
    -- circuit such as the MC1377.
    variable TIMER  : std_logic_vector(2 downto 0);
    begin
        wait until VBASE_CLK = '1' and VBASE_CLK' event;
        if TIMER < "110" then
            TIMER := TIMER + '1';
        else
            TIMER := "000";
        end if;
        COLOR <= not TIMER(2) and (TIMER(1) or TIMER(0)); -- "001", "010", "011".
    end process COLOR_TIMING;

    HSYNC_EN <= not SHIFTMODE_F(6);
    HSYNC_POL <= VIDEO_CTRL(6);
    HSYNC <= not HSYNC_I when VIDEO_CTRL(1 downto 0) = "10" else HSYNC_I;
    HSYNC_I <= '1' when HILOn = '1' and HHC >= HSS else
               '1' when HILOn = '0' and VIDEO_CTRL(3) = '1' and HHC <= HFE and VFC < x"000000110" else -- First five lines.
               '1' when HILOn = '0' and VIDEO_CTRL(3) = '1' and HHC <= HFE and VFT - VFC  < x"000000110" else -- Last five lines.
               '1' when HILOn = '0' and VIDEO_CTRL(3) = '1' and HHC <= HFS else '0'; -- Lines in between.

    VSYNC_EN <= not SHIFTMODE_F(5);
    VSYNC_POL <= VIDEO_CTRL(5);
    VSYNC <= not VSYNC_I when VIDEO_CTRL(1 downto 0) = "10" else VSYNC_I;
    VSYNC_I <= '1' when VFC >= VSS else '0';

--    VINT_I <= '1' when VFC = VFT else '0'; -- Interrupt after last display line.
VINT_I <= '1' when VFC >= VSS else '0'; -- Interrupt after last display line.
    HINT_I <= '1' when HHC > HSS and HILOn = '1' else '0';

    BOARDER <= '0' when VIDEO_CTRL(1 downto 0) = "00" else -- Monochrome monitor.
               '1' when VFC <= VBE else
               '1' when VFC >= VBB else
               '1' when HILOn = '0' and HHC <= HBE else
               '1' when HILOn = '1' and HHC >= HBB else '0';

    CSYNC <= not(HSYNC_I or VSYNC_I);

    DISPLAY_SWITCH: process
    -- This display control logic computes the offsets for the HDB and the HDE
    -- registers. For more information refer to the excellent explanation of
    -- the DE timing in the document "THE AUTHORITATIVE GUIDE TO THE FALCON 
    -- VIDEO HARDWARE" by BY AURA AND ANIMAL MINE. Be aware, that we need no
    -- 'Divider' for the calculation of the HDB-Offset and the HDE-Offset
    -- because this process works without VIDEO_STRB directly on the VBASE_CLK.
    -- In this way the delay is measured in video cycles (one VBASE_CLK).
    -- The delays are calculated from the different settings according to the 
    -- selected video mode depending on 'Base Offset', 'Cycles/pixel' and 
    -- 'No. of planes'.
    -- The result of this some kind of complicated logic is a timing which
    -- refers to the horizontal boarder begin (HBB) and -end (HBE) signals
    -- used by the original TOS 4.04 and emuTos as follows:
    -- DE_I <= '0' when VFC <= VDB or VFC >= VDE + '1' else
    --         '1' when HHC >= HBE and HILOn = '0' and VTYPE = FALCON else
    --         '1' when HHC <= HBB and HILOn = '1' and VTYPE = FALCON else
    --         '1' when HHC > HBE and HILOn = '0' and VTYPE = STE else
    --         '1' when HHC < HBB and HILOn = '1' and VTYPE = STE else '0';
    -- Using the offsets results in a fine adjustment in a way, that the 
    -- video switch DE is switched off right before the boarder begins. In
    -- this way a fine adjustment can be done using a logic analyzer. Refer
    -- HHC, HDB, VIDEO_MODE SHIFTMODE_ST, SHIFTMODE_FALCON ... to each other.
    variable BASE_OFFSET    : std_logic_vector(11 downto 0);
    variable HDB_CYCLES     : std_logic_vector(11 downto 0);
    variable HDE_CYCLES     : std_logic_vector(11 downto 0);
    variable HDB_OFFSET     : std_logic_vector(11 downto 0);
    variable HDE_OFFSET     : std_logic_vector(11 downto 0);
    begin
        wait until VBASE_CLK = '1' and VBASE_CLK' event;

        case VIDEO_CTRL(8) is
            when '1' => -- Horizontal base offset = 64 video cycles.
                case VTYPE is
                    when STE => BASE_OFFSET := x"080"; -- + 64 cycles.
                    when others => BASE_OFFSET := x"040";
                end case;
            when others => -- Horizontal base offset = 128 video cycles.
                case VTYPE is
                    when STE => BASE_OFFSET := x"0C0"; -- + 64 cycles.
                    when others => BASE_OFFSET := x"080";
                end case;
        end case;

        case VIDEO_MODE is
            when F_TRUEC => -- This is the Falcon true colour mode.
                case V_MODE(3 downto 2) is
                    when "10" => -- 1 cycle per pixel.
                        if VIDEO_CTRL(1 downto 0) = x"10" then -- VGA monitor.
                            HDB_CYCLES := BASE_OFFSET + x"00E"; -- Adjustment required.
                        else
                            HDB_CYCLES := x"00F"; -- Adjustment required.
                        end if;
                    when "01" => HDB_CYCLES := BASE_OFFSET + x"026"; -- 2 cycles per pixel.
                    when "00" =>  HDB_CYCLES := BASE_OFFSET + x"03C"; -- 4 cycles per pixel, adjustment required.
                    when others => HDB_CYCLES := (others => '0'); -- Not valid.
                end case;
                HDE_CYCLES := x"000";
            when F_8BITPL =>
                case V_MODE(3 downto 2) is
                    when "10" => -- 1 cycle per pixel.
                        if VIDEO_CTRL(1 downto 0) = "10" then -- VGA monitor, Divider = 2.
                            HDB_CYCLES := BASE_OFFSET + x"020";
                        else -- Divider = 1.
                            HDB_CYCLES := x"021";
                        end if;
                            HDE_CYCLES := x"012";
                    when "01" => -- 2 cycles per pixel.
                        if VIDEO_CTRL(1 downto 0) = "10" then -- VGA.
                            HDB_CYCLES := BASE_OFFSET + x"042";
                        else
                            HDB_CYCLES := BASE_OFFSET + x"044";
                        end if;
                            HDE_CYCLES := x"024";
                    when "00" => -- 4 cycles per pixel.
                        if VIDEO_CTRL(1 downto 0) = "10" then -- VGA.
                            HDB_CYCLES := BASE_OFFSET + x"084";
                        else
                            HDB_CYCLES := BASE_OFFSET + x"088";
                        end if;
                            HDE_CYCLES := x"048";
                    when others => -- Not valid.
                        HDB_CYCLES := (others => '0');
                        HDE_CYCLES := (others => '0');
                end case;
            when F_4BITPL => -- This is the Falcon 16/80 and 16/40 video resolution.
                case V_MODE(3 downto 2) is
                    when "10" => -- 1 cycle per pixel.
                        if VIDEO_CTRL(1 downto 0) = "10" then -- VGA monitor, Divider = 2.
                            HDB_CYCLES := BASE_OFFSET + x"02F";
                        else -- Divider = 1.
                            HDB_CYCLES := x"04F"; -- Adjustment required.
                        end if;
                            HDE_CYCLES := x"021"; -- 1 cycles per pixel.
                    when "01" => -- 2 cycles per pixel.
                        if VIDEO_CTRL(1 downto 0) = "10" then -- VGA monitor, Divider = 2.
                            HDB_CYCLES := BASE_OFFSET + x"061";
                        else
                            HDB_CYCLES := BASE_OFFSET + x"064";
                        end if;
                            HDE_CYCLES := x"043";
                    when "00" => -- 4 cycles per pixel.
                        HDB_CYCLES := BASE_OFFSET + x"0C8";
                        HDE_CYCLES := x"088";
                    when others => -- Not valid.
                        HDB_CYCLES := (others => '0');
                        HDE_CYCLES := (others => '0');
                end case;
            when F_MONO => -- This is used for VGA and RGB monitors.
                case V_MODE(3 downto 2) is
                    when "10" => -- 1 cycle per pixel.
                        HDB_CYCLES := BASE_OFFSET + x"08F";
                        HDE_CYCLES := x"079"; -- Formula results in x"82".
                    when "01" => -- 2 cycles per pixel.
                        HDB_CYCLES := BASE_OFFSET + x"112";
                        HDE_CYCLES := x"0F4";
                    when "00" =>  -- 4 cycles per pixel.
                        HDB_CYCLES := BASE_OFFSET + x"244"; -- Adjustment required.
                        HDE_CYCLES := x"1E8"; -- Adjustment required.
                    when others => -- Not valid.
                        HDB_CYCLES := (others => '0');
                        HDE_CYCLES := (others => '0');
                end case;
            when STE_LOW => -- Four bitplanes. Used for STE low resolution and Falcon 16/80 and 16/40 mode.
                case V_MODE(3 downto 2) is
                    when "10" => -- 1 cycles per pixel.
                        HDB_CYCLES := BASE_OFFSET + x"010"; -- Adjustment required.
                        HDE_CYCLES := x"020"; -- Adjustment required.
                    when "01" => -- 2 cycles per pixel.
                        HDB_CYCLES := BASE_OFFSET + x"03F";
                        HDE_CYCLES := x"04F";
                    when "00" => -- 4 cycles per pixel.
                        HDB_CYCLES := BASE_OFFSET + x"070"; -- Adjustment required.
                        HDE_CYCLES := x"080"; -- Adjustment required.
                    when others => -- Not valid.
                        HDB_CYCLES := (others => '0');
                        HDE_CYCLES := (others => '0');
                end case;
            when STE_MID => -- Two bitplanes. Used for STE medium resolution and Falcon 4/80 and 4/40 mode.
                case V_MODE(3 downto 2) is
                    when "10" => -- 1 cycles per pixel.
                        HDB_CYCLES := BASE_OFFSET + x"03F";
                        HDE_CYCLES := x"04F";
                    when "01" => -- 2 cycles per pixel.
                        HDB_CYCLES := BASE_OFFSET + x"07F";
                        HDE_CYCLES := x"08F";
                    when "00" => -- 4 cycles per pixel.
                        HDB_CYCLES := BASE_OFFSET + x"07F";
                        HDE_CYCLES := x"08F";
                    when others => -- Not valid.
                        HDB_CYCLES := (others => '0');
                        HDE_CYCLES := (others => '0');
                end case;
            when STE_MONO => -- Used for STE mode with SM124.
                case V_MODE(3 downto 2) is
                    when "10" => -- 1 cycles per pixel.
                        --HDB_CYCLES := BASE_OFFSET + x"070";
                        HDB_CYCLES := BASE_OFFSET + x"0A0"; -- More centered.
                        --HDE_CYCLES := x"080";
                        HDE_CYCLES := x"0B0"; -- More centered.
                    when "01" => -- 2 cycles per pixel.
                        HDB_CYCLES := BASE_OFFSET + x"0F0"; -- Adjustment required.
                        HDE_CYCLES := x"100"; -- Adjustment required.
                    when "00" => -- 4 cycles per pixel.
                        HDB_CYCLES := BASE_OFFSET + x"1F0"; -- Adjustment required.
                        HDE_CYCLES := x"200"; -- Adjustment required.
                    when others => -- Not valid.
                        HDB_CYCLES := (others => '0');
                        HDE_CYCLES := (others => '0');
                end case;
        end case;

        if VFC < VDB or VFC > VDE then
            DE_I <= '0';
        elsif VIDEO_STRB = '1' and HDB = HDE and HHC = HDE and HILOn = '1' and HDB(9) = '1' then -- HDB and HDE in the second half line.
            HDB_OFFSET := (others => '0');
            HDE_OFFSET := (others => '0');
        elsif VIDEO_STRB = '1' and HHC = (HDB(8 downto 0) - '1') and HILOn = HDB(9) then -- HDB in the first or second half line.
            HDB_OFFSET := (others => '0');
            if HDE_OFFSET = HDE_CYCLES then
                HDE_OFFSET := HDE_OFFSET + '1'; 
                DE_I <= '0';
            elsif HDE_OFFSET < HDE_CYCLES then
                HDE_OFFSET := HDE_OFFSET + '1';
            end if;
        elsif VIDEO_STRB = '1' and HHC = HDE - '1' and HILOn = '1' then -- HDE always in the second half line.
            HDE_OFFSET := (others => '0');
            if HDB_OFFSET = HDB_CYCLES then
                HDB_OFFSET := HDB_OFFSET + '1';
                DE_I <= '1';
            elsif HDB_OFFSET < HDB_CYCLES then
                HDB_OFFSET := HDB_OFFSET + '1';
            end if;
        else
            if HDE_OFFSET = HDE_CYCLES then
                HDE_OFFSET := HDE_OFFSET + '1';
                DE_I <= '0';
            elsif HDE_OFFSET < HDE_CYCLES then
                HDE_OFFSET := HDE_OFFSET + '1';
            end if;
        
            if HDB_OFFSET = HDB_CYCLES then
                HDB_OFFSET := HDB_OFFSET + '1';
                DE_I <= '1';
            elsif HDB_OFFSET < HDB_CYCLES then
                HDB_OFFSET := HDB_OFFSET + '1';
            end if;
        end if;

--if VIDEO_STRB = '1' and HHC = (HDB(8 downto 0) - '1') and HILOn = HDB(9) then -- HDB in the first or second half line.
--    HDB_OFFSET := (others => '0');
--elsif VIDEO_STRB = '1' and HHC = HDE - '1' and HILOn = '1' then -- HDE always in the second half line.
--    HDE_OFFSET := (others => '0');
--end if;
--
--if VFC < VDB or VFC > VDE then
--    DE_I <= '0';
--elsif HHC >= HDB and HHC < HDE then
--    if HDB_OFFSET < HDB_CYCLES then
--        HDB_OFFSET := HDB_OFFSET + '1';
--    else
--        DE_I <= '1';
--    end if;
--elsif HHC >= HDE then
--    if HDE_OFFSET < HDE_CYCLES then
--        HDE_OFFSET := HDE_OFFSET + '1';
--    else
--        DE_I <= '0';
--    end if;        
--end if;
    end process DISPLAY_SWITCH;
end architecture BEHAVIOR;
