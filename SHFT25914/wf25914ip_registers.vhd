------------------------------------------------------------------------
----                                                                ----
---- ATARI SHIFTER compatible IP Core                               ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- ST and STE compatible SHIFTER IP core.                         ----
----                                                                ----
---- Chroma registers 0 through 15.                                 ----
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
--   Initial Release.
-- Revision 2K6B  2006/11/06 WF
--   Modified Source to compile with the Xilinx ISE.
-- Revision 2K8A  2008/07/14 WF
--   Minor changes.
-- Revision 2K9A  2008/06/29 WF
--   Changes concerning the SH_MOD for multisync compatibility.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--

library ieee;
use ieee.std_logic_1164.all;
entity WF25914IP_CR_REGISTERS is
    port(
        CLK, RESETn : in std_logic;
        ADR         : in std_logic_vector (6 downto 1);
        CSn         : in std_logic;
        RWn         : in std_logic;
        DATA_IN     : in std_logic_vector(15 downto 0); -- Data.
        DATA_OUT    : out std_logic_vector(15 downto 0);
        DATA_EN     : out std_logic;
        SH_MOD      : in std_logic_vector (7 downto 0);
        SR          : in std_logic_vector (3 downto 0);
        MONO_INV    : out std_logic;
        CHROMA      : out std_logic_vector(15 downto 0)
    );
end WF25914IP_CR_REGISTERS;

architecture BEHAVIOUR of WF25914IP_CR_REGISTERS is
type REGTYPE is array(0 to 15) of std_logic_vector(15 downto 0);
signal CHROMA_REG   : REGTYPE;      
signal ADR_I        : std_logic_vector(7 downto 0);
begin
    ADR_I <= '0' & ADR & '0';
    MONO_INV <= CHROMA_REG(0)(0);

    CHROMA_D_IN: process (CLK, RESETn, ADR)
    begin
        if RESETn = '0' then
            for i in 0 to 15 loop
                -- Memory initialisation:
                CHROMA_REG(i) <= (others => '0');
            end loop;
        elsif CLK = '1' and CLK' event then
            if RWn = '0' and CSn = '0' then
                case ADR_I is
                    when x"5E" => CHROMA_REG(15) <= DATA_IN;
                    when x"5C" => CHROMA_REG(14) <= DATA_IN;
                    when x"5A" => CHROMA_REG(13) <= DATA_IN;
                    when x"58" => CHROMA_REG(12) <= DATA_IN;
                    when x"56" => CHROMA_REG(11) <= DATA_IN;
                    when x"54" => CHROMA_REG(10) <= DATA_IN;
                    when x"52" => CHROMA_REG(9) <= DATA_IN;
                    when x"50" => CHROMA_REG(8) <= DATA_IN;
                    when x"4E" => CHROMA_REG(7) <= DATA_IN;
                    when x"4C" => CHROMA_REG(6) <= DATA_IN;
                    when x"4A" => CHROMA_REG(5) <= DATA_IN;
                    when x"48" => CHROMA_REG(4) <= DATA_IN;
                    when x"46" => CHROMA_REG(3) <= DATA_IN;
                    when x"44" => CHROMA_REG(2) <= DATA_IN;
                    when x"42" => CHROMA_REG(1) <= DATA_IN;
                    when x"40" => CHROMA_REG(0) <= DATA_IN;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process CHROMA_D_IN;

    -- Read the chroma registers:
    DATA_OUT <= CHROMA_REG(15) when CSn = '0' and ADR_I = x"5E" and RWn = '1' else
                CHROMA_REG(14) when CSn = '0' and ADR_I = x"5C" and RWn = '1' else
                CHROMA_REG(13) when CSn = '0' and ADR_I = x"5A" and RWn = '1' else
                CHROMA_REG(12) when CSn = '0' and ADR_I = x"58" and RWn = '1' else
                CHROMA_REG(11) when CSn = '0' and ADR_I = x"56" and RWn = '1' else
                CHROMA_REG(10) when CSn = '0' and ADR_I = x"54" and RWn = '1' else
                CHROMA_REG(9) when CSn = '0' and ADR_I = x"52" and RWn = '1' else
                CHROMA_REG(8) when CSn = '0' and ADR_I = x"50" and RWn = '1' else
                CHROMA_REG(7) when CSn = '0' and ADR_I = x"4E" and RWn = '1' else
                CHROMA_REG(6) when CSn = '0' and ADR_I = x"4C" and RWn = '1' else
                CHROMA_REG(5) when CSn = '0' and ADR_I = x"4A" and RWn = '1' else
                CHROMA_REG(4) when CSn = '0' and ADR_I = x"48" and RWn = '1' else
                CHROMA_REG(3) when CSn = '0' and ADR_I = x"46" and RWn = '1' else
                CHROMA_REG(2) when CSn = '0' and ADR_I = x"44" and RWn = '1' else
                CHROMA_REG(1) when CSn = '0' and ADR_I = x"42" and RWn = '1' else
                CHROMA_REG(0) when CSn = '0' and ADR_I = x"40" and RWn = '1' else (others => '0');

    DATA_EN <= '1' when CSn = '0' and RWn = '1' and ADR_I >= x"40" and ADR_I <= x"5E" else '0';

    -- Chroma data output:
    DEMUX: process (SH_MOD, CHROMA_REG, SR)
    begin
        if SH_MOD = x"00" or SH_MOD = x"10" or SH_MOD = x"20" then -- Low resolution.
            case SR is
                when x"F" => CHROMA <= CHROMA_REG(15);
                when x"E" => CHROMA <= CHROMA_REG(14);
                when x"D" => CHROMA <= CHROMA_REG(13);
                when x"C" => CHROMA <= CHROMA_REG(12);
                when x"B" => CHROMA <= CHROMA_REG(11);
                when x"A" => CHROMA <= CHROMA_REG(10);
                when x"9" => CHROMA <= CHROMA_REG(9);
                when x"8" => CHROMA <= CHROMA_REG(8);
                when x"7" => CHROMA <= CHROMA_REG(7);
                when x"6" => CHROMA <= CHROMA_REG(6);
                when x"5" => CHROMA <= CHROMA_REG(5);
                when x"4" => CHROMA <= CHROMA_REG(4);
                when x"3" => CHROMA <= CHROMA_REG(3);
                when x"2" => CHROMA <= CHROMA_REG(2);
                when x"1" => CHROMA <= CHROMA_REG(1);
                when others => CHROMA <= CHROMA_REG(0);
          end case;
        elsif SH_MOD = x"01" or SH_MOD = x"11" or SH_MOD = x"21" then -- Medium resolution.
            case SR (1 downto 0) is
                when b"11" => CHROMA <= CHROMA_REG(3);
                when b"10" => CHROMA <= CHROMA_REG(2);
                when b"01" => CHROMA <= CHROMA_REG(1);
                when others => CHROMA <= CHROMA_REG(0);
            end case;
        elsif SH_MOD = x"32" or SH_MOD = x"02" then -- Monochrome; high resolution.
            CHROMA <= CHROMA_REG(0);
        else
            CHROMA <= (others=> '0'); -- Reserved.
        end if;
    end process DEMUX;
end BEHAVIOUR;
