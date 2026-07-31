------------------------------------------------------------------------
----                                                                ----
---- ATARI MCU compatible IP Core                                   ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Memory management controller with all features to reach        ----
---- ATARI STE compatibility.                                       ----
----                                                                ----
---- This is the SUSKA MCU IP core top level file.                  ----
----                                                                ----
----                                                                ----
---- Important Notice concerning the clock system:                  ----
---- To use this code in a stand alone MCU chip or in a system      ----
---- on a programmable chip (SOC), the clock frequency may be       ----
---- selected via the CLKSEL setting. Use CLK_16M for the           ----
---- original MCU frequency (16MHz) or CLK_32M for the 32MHz        ----
---- SOC-GLUE.                                                      ----
---- Affected by the clock selection is the video timing and the    ----
---- DMA sound module (originally in the STE machines).             ----
----                                                                ----
---- To guarantee proper operation of the DMA interchange between   ----
---- MCU, GLUE, DMA, the clocks must be well selected. For more     ----
---- information see the Suska top level file for the SOC system    ----
---- or respective documentation for the different original types   ----
---- of ST or STE machines.                                         ----
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
---- Copyright © 2005... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- This source file may be used and distributed without           ----
---- restriction provided that this copyright statement is not      ----
---- removed from the file and that any derivative work contains    ----
---- the original copyright notice and the associated disclaimer.   ----
----                                                                ----
---- This source file is free software; you can redistribute it     ----
---- and/or modify it under the terms of the GNU Lesser General     ----
---- Public License as published by the Free Software Foundation;   ----
---- either version 2.1 of the License, or (at your option) any     ----
---- later version.                                                 ----
----                                                                ----
---- This source is distributed in the hope that it will be         ----
---- useful, but WITHOUT ANY WARRANTY; without even the implied     ----
---- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR        ----
---- PURPOSE. See the GNU Lesser General Public License for more    ----
---- details.                                                       ----
----                                                                ----
---- You should have received a copy of the GNU Lesser General      ----
---- Public License along with this source; if not, download it     ----
---- from http://www.gnu.org/licenses/lgpl.html                     ----
----                                                                ----
------------------------------------------------------------------------
-- 
-- Revision History
-- 
-- Revision 2K6A  2006/06/03 WF
--  Initial Release.
-- Revision 2K6B 2006/06/20 WF
--   Enhanced the STEs SINTn logic by the two signals SINT_TAI and SINT_IO7.
-- Revision 2K6B 2006/11/05 WF
--   Modified Source to compile with the Xilinx ISE.
-- Revision 2K7A  2007/01/02 WF
--   Changes to the clock system and related
--   hardware as sound or video control.
-- Revision 2K8B  2008/12/24 WF
--   Rewritten this top level file as a wrapper for the top_soc file.
-- Revision 2K15B  20151224 WF
--   Replaced data type bit by std_logic.
--

library work;
use work.wf25912ip_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF25912IP_TOP is
    generic(
        CLKSEL      : CLKSEL_TYPE := CLK_16M
    );
    port (
        CLK_16M     : in std_logic; -- System clock, originally 16MHz..
        
        ASn         : in std_logic; -- Bus control signals.
        LDSn, UDSn  : in std_logic; -- Bus control signals.
        RWn         : in std_logic; -- Bus control signals.

        ADR         : in std_logic_vector(23 downto 1); -- The STs address bus.

        RAMn        : in std_logic; -- RAM access control.
        DMAn        : in std_logic; -- DMA access control.
        DEVn        : in std_logic; -- Device access (A23 downto 16) = x"FF".
            
        VSYNCn      : in std_logic; -- Vertical sync.
        DE          : in std_logic; -- Horizontal or vertical sync.
                    
        DCYCn       : out std_logic; -- Shifter load signal.
        CMPCSn      : out std_logic; -- Shifter video and sound register control.

        MONO_DETECT : in std_logic; -- Monochrome monitor detector (pin 4 of the 13 pin round video plug).
        EXT_CLKSELn : in std_logic; -- Genlock clock select (pin 3 of the 13 pin round video plug, formerly GPO).
        SREQ        : in std_logic; -- Sound data request.
        SLOADn      : out std_logic;    -- DMA sound load control.
        SINTn       : out std_logic;    -- Sound frame interrupt signal.
        SINT_TAI    : out std_logic;    -- Sound frame interrupt filtered for timer A.
        SINT_IO7    : out std_logic;    -- Sound frame interrupt XORed for MFP_IO7

        RAS0n       : out std_logic; -- memory bank 1 row address strobe.
        CAS0Hn      : out std_logic; -- memory bank 1 column address strobe.
        CAS0Ln      : out std_logic; -- memory bank 1 column address strobe.

        WEn         : out std_logic; -- memory write control, low active.

        RAS1n       : out std_logic; -- memory bank 2 row address strobe.
        CAS1Hn      : out std_logic; -- memory bank 2 column address strobe.
        CAS1Ln      : out std_logic; -- memory bank 2 column address strobe.

        MAD : out std_logic_vector(9 downto 0); -- DRAM addressbus.

        RDATn       : out std_logic; -- buffer control.
        WDATn       : out std_logic; -- buffer control.
        LATCHn      : out std_logic; -- buffer control.
            
        CLK_8M      : buffer std_logic; -- clock out.
        CLK_4M      : out std_logic; -- clock out.
            
        DTACKn      : out std_logic; -- data acknowledge signal.

        DATA        : inout std_logic_vector(7 downto 0)
    );
end entity WF25912IP_TOP;

architecture STRUCTURE of WF25912IP_TOP is
component WF25912IP_CLOCKS
port (
  CLK_x2    : in std_logic;
  CLK_x1    : out std_logic;
  CLK_x05   : out std_logic
);
end component;
--
component WF25912IP_TOP_SOC
    generic(
        CLKSEL      : CLKSEL_TYPE := CLK_32M
    );
    port(  
        CLK_x2      : in std_logic;
        CLK_x1      : in std_logic;
        ASn         : in std_logic;
        LDSn, UDSn  : in std_logic;
        RWn         : in std_logic;
        ADR         : in std_logic_vector(23 downto 1);
        RAMn        : in std_logic;
        DMAn        : in std_logic;
        DEVn        : in std_logic;
        VSYNCn      : in std_logic;
        DE          : in std_logic;
        DCYCn       : out std_logic;
        CMPCSn      : out std_logic;
        MONO_DETECT : in std_logic;
        EXT_CLKSELn : in std_logic;
        SREQ        : in std_logic;
        SLOADn      : out std_logic;
        SINT_TAI    : out std_logic;
        SINT_IO7    : out std_logic;
        RAS0n       : out std_logic;
        CAS0Hn      : out std_logic;
        CAS0Ln      : out std_logic;
        WEn         : out std_logic;
        RAS1n       : out std_logic;
        CAS1Hn      : out std_logic;
        CAS1Ln      : out std_logic;
        MAD         : out std_logic_vector(9 downto 0);
        RDATn       : out std_logic;
        WDATn       : out std_logic;
        LATCHn      : out std_logic;
        DTACKn      : out std_logic;
        DATA_IN     : in std_logic_vector(7 downto 0);
        DATA_OUT    : out std_logic_vector(7 downto 0);
        DATA_EN     : out std_logic
    );
end component;
signal DATA_OUT : std_logic_vector(7 downto 0);
signal DATA_EN  : std_logic;
signal DTACK_In : std_logic;
begin
    DATA <= DATA_OUT when DATA_EN = '1' else (others => 'Z');
    DTACKn <= '0' when DTACK_In = '0' else 'Z'; -- Open drain.
    SINTn <= '1';

    I_CLOCKS: WF25912IP_CLOCKS
    port map(
      CLK_x2        => CLK_16M,
      CLK_x1        => CLK_8M,
      CLK_x05       => CLK_4M
    );

    I_MCU: WF25912IP_TOP_SOC
--        generic map(
--            CLKSEL          => CLKSEL
--        );
        port map(  
            CLK_x2          => CLK_16M,
            CLK_x1          => CLK_8M,
            ASn             => ASn,
            LDSn            => UDSn,
            UDSn            => LDSn,
            RWn             => RWn,
            ADR             => ADR,
            RAMn            => RAMn,
            DMAn            => DMAn,
            DEVn            => DEVn,
            VSYNCn          => VSYNCn,
            DE              => DE,
            DCYCn           => DCYCn,
            CMPCSn          => CMPCSn,
            MONO_DETECT     => MONO_DETECT,
            EXT_CLKSELn     => EXT_CLKSELn,
            SREQ            => SREQ,
            SLOADn          => SLOADn,
            SINT_TAI        => SINT_TAI,
            SINT_IO7        => SINT_IO7,
            RAS0n           => RAS0n,
            CAS0Hn          => CAS0Hn,
            CAS0Ln          => CAS0Ln,
            WEn             => WEn,
            RAS1n           => RAS1n,
            CAS1Hn          => CAS1Hn,
            CAS1Ln          => CAS1Ln,
            MAD             => MAD,
            RDATn           => RDATn,
            WDATn           => WDATn,
            LATCHn          => LATCHn,
            DTACKn          => DTACK_In,
            DATA_IN         => DATA,
            DATA_OUT        => DATA_OUT,
            DATA_EN         => DATA_EN
        );
end architecture STRUCTURE;
