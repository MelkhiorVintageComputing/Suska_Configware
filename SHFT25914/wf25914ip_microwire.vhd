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
---- STE's microwire interface to operate the LMC1992.              ----
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
-- Revision 2K8A  2008/05/29 WF
--   Changed the rotating shift registers for MW_DATA and MW_MASK.
-- Revision 2K9A  2009/06/20 WF
--   MWD has now synchronous reset to meet preset requirement.
-- Revision 2K10B  2010/12/27 WF
--   A bunch of changes.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF25914IP_MICROWIRE is
  port(
    RESETn      : in std_logic;
    CLK         : in std_logic;
    
    RWn         : in std_logic;
    CMPCSn      : in std_logic;
    ADR         : in std_logic_vector (6 downto 1);
    DATA_IN     : in std_logic_vector(15 downto 0); -- Data.
    DATA_OUT    : out std_logic_vector(15 downto 0);
    DATA_EN     : out std_logic;

    MWK         : out std_logic;      -- Microwire clock (1MHz).
    MWD         : out std_logic;      -- Microwire data.
    MWEn        : out std_logic    -- Microwire enable (low active).
  );
end WF25914IP_MICROWIRE;

architecture BEHAVIOUR of WF25914IP_MICROWIRE is
type MW_STATUSTYPE is (IDLE, RUN);
signal MW_STATUS    : MW_STATUSTYPE; -- Locks MW registers during shift operation.
signal MW_DATA      : std_logic_vector(15 downto 0);  -- Data register $FF8922.
signal MW_MASK      : std_logic_vector(15 downto 0);  -- Mask register $FF8924.
signal MWK_MASK     : std_logic;  -- Mask for the microwire clock.
signal SHIFTCLK     : std_logic;
signal SHIFT_STRB   : std_logic;
signal BITCNT       : std_logic_vector(4 downto 0);
signal MWE			: std_logic;
begin
    -- Microwire clock is active when MWEn is asserted
    -- -> see microwire specification. Microwire starts when
    -- MWEn is asserted during MWK = '0';
    -- the MWK_MASK is somewhat ATARI specific. It enables the
    -- microwire clock only for valid Mask register bits. So
    -- it is possible to send don't care data.
    MWK <= SHIFTCLK when MWE = '1' and MWK_MASK = '1' else '0';

    PRESCALER: process(RESETn, CLK)
    variable TMP : std_logic_vector(4 downto 0);
    begin
        if RESETn = '0' then
            TMP := "00000";
        elsif CLK = '1' and CLK' event then -- 32MHz clock.
            if MW_STATUS = IDLE then
                TMP := "00000";
            else
                TMP := TMP + '1';
            end if;
            --
            SHIFTCLK <= TMP(4); -- 1MHz.
            case TMP is
                when "00001" => SHIFT_STRB <= '1';
                when others => SHIFT_STRB <= '0';
            end case;
        end if;
    end process PRESCALER;

    MWD <= MW_DATA(15);
    MWK_MASK <= MW_MASK(15);
	MWEn <= not MWE;
    MWE <= '1' when MW_STATUS = RUN else '0';

    STATES: process(RESETn, CLK)
    variable START_EN   : boolean;
    begin
        if RESETn = '0' then
            START_EN := false;
            MW_STATUS <= IDLE;
        elsif CLK = '1' and CLK' event then
            if ADR = "010001" and CMPCSn = '0' and RWn = '0' and MW_STATUS = IDLE then
                START_EN := true;
            elsif CMPCSn = '1' and START_EN = true then
                MW_STATUS <= RUN; -- Start transmission after register write.
                START_EN := false;
            elsif MW_STATUS = RUN and BITCNT = "10001" then
                MW_STATUS <= IDLE; -- Stop the shift process after 16 bits have completed.
            end if;
        end if;
    end process STATES;

    MW_REGISTERS: process(RESETn, CLK)
    begin
        if RESETn = '0' then
            MW_DATA <= (others => '0');
            MW_MASK <= (others => '0');
            BITCNT <= "00000";
        elsif CLK = '1' and CLK' event then
            if ADR = "010001" and CMPCSn = '0' and RWn = '0' and MW_STATUS = IDLE then
                MW_DATA <= DATA_IN; -- Write to register.
                BITCNT <= "00000";
            elsif ADR = "010010" and CMPCSn = '0' and RWn = '0' and MW_STATUS = IDLE then
                MW_MASK <= DATA_IN; -- Write to register.
            elsif MW_STATUS = RUN and SHIFT_STRB = '1' then
                BITCNT <= BITCNT + '1'; -- Count the shift positions.
                if BITCNT /= "00000" then -- Do not shift the first bit immediately since it is not read by the device.
                    -- Rotate the mask registers and shift out the data register.
                    -- This implementation is correct and Atari compatible.
                    MW_DATA <= MW_DATA(14 downto 0) & '0'; -- Shift left.
                    MW_MASK <= MW_MASK(14 downto 0) & MW_MASK(15); -- Rotate left.
                end if;
            end if;
        end if;
    end process MW_REGISTERS;

    -- Register read access is possible, even if microwire interface is active.
    DATA_OUT <= MW_DATA when ADR = "010001" and CMPCSn = '0' and RWn = '1' else
                MW_MASK when ADR = "010010" and CMPCSn = '0' and RWn = '1' else (others => '0'); -- Read.
    DATA_EN <=  '1' when ADR = "010001" and CMPCSn = '0' and RWn = '1' else
                '1' when ADR = "010010" and CMPCSn = '0' and RWn = '1' else '0';
end BEHAVIOUR;
