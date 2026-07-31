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
---- Video output register.                                         ----
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
-- Revision 2K9A  2008/11/25 WF
--   Introduced VGA signals in monochrome mode (see CHROMA_PORT).
--   STARTUP process has now synchronous process.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
-- Revision 2K19B  20191224 WF
--   Minor changes to help Multisyns or TFTs to synchronize
--   correctly.
-- Revision 2K21A 20211224 WF
--   The weighting of the RGB bits is now STE conform.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF25914IP_CR_OUT is
    port (
        CLK         : in std_logic;
        RESETn      : in std_logic;
        BLANKn      : in std_logic; -- Blanking signal.
        DE          : in std_logic; -- Blanking signal for the monochrome mode.
        LOADn       : in std_logic; -- Load control for the shift registers.
        SH_MOD1     : in std_logic;  -- Monochrome switch.
        SR0         : in std_logic; -- Monochrome information.
        MONO_INV    : in std_logic; -- Inversion switch.
        CHROMA      : in std_logic_vector(15 downto 0); -- Chroma bus.
        CR_1512     : out std_logic_vector(3 downto 0); -- Hi nibble of the chroma out.
        R           : out std_logic_vector(3 downto 0); -- Red video output.
        G           : out std_logic_vector(3 downto 0); -- Green video output.
        B           : out std_logic_vector(3 downto 0); -- Blue video output.
        MONO        : out std_logic             -- Monochrome video output.
    );
end WF25914IP_CR_OUT;

-------------------------------------------------------------------------------

architecture Behaviour of WF25914IP_CR_OUT is
type MASK_STATES is (STOP, IDLE, RUN);
signal MASK_STATE, MASK_NEXT_STATE: MASK_STATES;
signal CHROMA_PORT      : std_logic_vector(15 downto 0);
signal STARTUP_BLANK    : boolean;
signal MASK_CNT_EN      : boolean;
signal MASK_CNT_CLR     : boolean;
signal MONO_EN_I        : boolean; -- Mask for blanking out the monochrome signal.
begin
    CR_1512 <= CHROMA_PORT(15 downto 12);
    R <= CHROMA_PORT(10 downto 8) & CHROMA_PORT(11) when STARTUP_BLANK = false else x"0" ; -- 4 bit as in STEs.
    G <= CHROMA_PORT(6 downto 4) & CHROMA_PORT(7) when STARTUP_BLANK = false else x"0" ; -- 4 bit as in STEs.
    B <= CHROMA_PORT(2 downto 0) & CHROMA_PORT(3) when STARTUP_BLANK = false else x"0" ; -- 4 bit as in STEs.

    MONO <= '1' when (SR0 = '1' and MONO_INV = '0' and MONO_EN_I = true and STARTUP_BLANK = false) else
            '1' when (SR0 = '0' and MONO_INV = '1' and MONO_EN_I = true and STARTUP_BLANK = false) else '0'; -- Blanking out.

    STARTUP: process
    -- This routine blanks out the screen for about one second during startup
    -- or after a system reset.
    variable STARTUP_COUNT: std_logic_vector(24 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        if RESETn = '0' then
            STARTUP_COUNT := (others => '0');
            STARTUP_BLANK <= true;
        elsif STARTUP_COUNT < '1' & x"E84800" then
            STARTUP_COUNT := STARTUP_COUNT + '1';
        else
            STARTUP_BLANK <= false;
        end if;
    end process STARTUP;
    
    MASK_MEM: process(RESETn, CLK)
    begin
        if RESETn = '0' then
            MASK_STATE <= STOP;
        elsif CLK = '1' and CLK' event then
            MASK_STATE <= MASK_NEXT_STATE;
        end if;
    end process MASK_MEM;
    
    MASK_LOGIC: process(MASK_STATE, DE, LOADn)
    begin
        case MASK_STATE is
            when STOP => 
                if DE = '1' and LOADn = '0' then
                    MASK_NEXT_STATE <= IDLE;
                else
                    MASK_NEXT_STATE <= STOP;
                end if;
                MASK_CNT_EN <= true;
                MASK_CNT_CLR <= false;
            when IDLE =>
                if DE = '1' and LOADn = '1' then
                    MASK_NEXT_STATE <= RUN;
                else
                    MASK_NEXT_STATE <= IDLE;
                end if;
                MASK_CNT_EN <= false;
                MASK_CNT_CLR <= true;
            when RUN =>
                if DE = '0' then
                    MASK_NEXT_STATE <= STOP;
                else
                    MASK_NEXT_STATE <= RUN;
                end if;
                MASK_CNT_EN <= true;
                MASK_CNT_CLR <= false;
        end case;       
    end process MASK_LOGIC;
        
    MONOCHROME_MASK: process(RESETn, CLK)
    variable MASK_COUNTER: std_logic_vector(9 downto 0);
    begin
        if RESETn = '0' then
            MASK_COUNTER := (others => '0');
        elsif CLK = '1' and CLK' event then
            if MASK_CNT_EN = true and MASK_COUNTER < "1111111111" then -- Stop at count end.
                MASK_COUNTER := MASK_COUNTER + '1';
            elsif MASK_CNT_CLR = true then
                MASK_COUNTER := (others => '0');
            end if;
            -- The mask counter values are adjusted to the shift register A in 
            -- the CR_SHIFT_REG.vhd file. The values used are tested for several
            -- TFTs with reasonable results. The settings may be changed for 
            -- not correctly working Multisyncs or TFTs.
            --if MASK_COUNTER >= "0001000000" and MASK_COUNTER < "1011000000" then
            if MASK_COUNTER >= "0000010110" and MASK_COUNTER < "1010010110" then
                MONO_EN_I <= true; -- Visible window.
            else
                MONO_EN_I <= false;
            end if;
        end if;         
    end process MONOCHROME_MASK;

    OUTREG: process (RESETn, CLK)
    begin
        if RESETn = '0' then
            CHROMA_PORT <= (others => '0');
        elsif CLK = '1' and CLK' event then
            if BLANKn = '0' then
                CHROMA_PORT <= (others => '0');
            else
                if SH_MOD1 = '0' then -- Colour operation if selected via SH_MOD1.
                    CHROMA_PORT <= CHROMA;
                else
                    -- Put the monochrome information on the RGB data lines to provide signals
                    -- for multisync monitors connected to the VGA interface.
                    if MONO_EN_I = true and SR0 = '1' and MONO_INV = '0' then
                        CHROMA_PORT <= x"0FFF"; -- Set Default for monochrome mode.
                    elsif MONO_EN_I = true and SR0 = '0' and MONO_INV = '1' then
                        CHROMA_PORT <= x"0FFF"; -- Set Default for monochrome mode.
                    else
                        CHROMA_PORT <= (others => '0');
                    end if;
                end if;
            end if;
        end if;
    end process OUTREG;
end Behaviour;
