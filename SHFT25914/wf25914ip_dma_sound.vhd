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
---- DMA sound module. it is an ST enhancement of the STE.          ----
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
-- Revision 2K6A 2006/06/03 WF
--   Initial Release.
-- Revision 2K6B 2006/11/06 WF
--   Modified Source to compile with the Xilinx ISE.
-- Revision 2K8A  2008/07/14 WF
--   Minor changes.
-- Revision 2K9A 2009/06/20 WF
--   GRP_A and GRP_B have now synchronous reset to meet preset requirement.
--   AUDIO_LATCH_L and AUDIO_LATCH_R have now synchronous reset to meet preset requirement.
-- Revision 2K10B 2010/12/27 WF
--   Completely rewritten the DMA control logic.
--   There is now a FIFO with a depth of 4 and a width of 16 bits.
-- Revision 2K12A 20120620 WF
--   Changed the SDATA_L and SDATA_R from linear to 2's complement.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF25914IP_DMASOUND is
    port (
        RESETn      : in std_logic;
        CLK         : in std_logic;
        ADR         : in std_logic_vector (6 downto 1);
        CSn         : in std_logic;
        RWn         : in std_logic;
        DATA_IN     : in std_logic_vector(15 downto 0); -- Data.
        DATA_OUT    : out std_logic_vector(15 downto 0);
        DATA_EN     : out std_logic;

        SLOADn      : in std_logic;
        SREQ        : out std_logic;
        
        SCLK        : in std_logic; -- 6.4 MHz.
        FCLK        : out std_logic;

        SDATA_L     : out std_logic_vector(7 downto 0); -- Buffers implemented here.
        SDATA_R     : out std_logic_vector(7 downto 0) -- Buffers implemented here.
        );
end entity WF25914IP_DMASOUND;      

architecture BEHAVIOR of WF25914IP_DMASOUND is
type FIFOTYPE is array(1 to 4) of std_logic_vector(15 downto 0);
signal FIFO_REG             : FIFOTYPE; 
signal FIFO_RD              : std_logic;
signal FIFO_WR              : std_logic;
signal FIFO_EMPTY           : std_logic;
signal FIFO_FULL            : std_logic;
signal WR_PNT               : natural range 0 to 4;
signal ADR_I                : std_logic_vector(7 downto 0);
signal FCLK_I               : std_logic;
signal SOUND_MODE_CTRL      : std_logic_vector(7 downto 0);
signal AUDIO_DATA           : std_logic_vector(7 downto 0);
signal AUDIO_LATCH_L        : std_logic_vector(7 downto 0);
signal AUDIO_LATCH_R        : std_logic_vector(7 downto 0);
begin
    ADR_I <= '0' & ADR & '0';
    FCLK <= FCLK_I; -- Frame clock.
    SDATA_L <= AUDIO_LATCH_L;   
    SDATA_R <= AUDIO_LATCH_R;
    SREQ <= not FIFO_FULL;

    REGISTERS: process(RESETn, CLK)
    begin
        if RESETn = '0' then
            SOUND_MODE_CTRL <= (others => '0');
        elsif CLK = '1' and CLK' event then
            if CSn = '0' and RWn = '0' and ADR_I = x"20" then
                SOUND_MODE_CTRL <= DATA_IN(7 downto 0);
            end if;
        end if;
    end process REGISTERS;

    DATA_OUT <= x"00" & SOUND_MODE_CTRL when CSn = '0' and RWn = '1' and ADR_I = x"20" else (others => '0');
    DATA_EN <= '1' when CSn = '0' and RWn = '1' and ADR_I = x"20" else '0';
    
    SAMPLECLOCKS: process(RESETn, CLK, SOUND_MODE_CTRL)
    variable TEMP   : std_logic_vector(9 downto 0);
    variable LOCK   : boolean;
    begin
        if RESETn = '0' then
            TEMP := (others => '0');
            LOCK := false;
        elsif CLK = '1' and CLK' event then
            if SCLK = '1' and LOCK = false then
                LOCK := true;
                TEMP := TEMP + '1';
            elsif SCLK = '0' then
                LOCK := false;
            end if;
        end if;
        case SOUND_MODE_CTRL(1 downto 0) is
            when "00" => FCLK_I <= TEMP(9); -- Sample frequency 06258Hz.
            when "01" => FCLK_I <= TEMP(8); -- Sample frequency 12517Hz.
            when "10" => FCLK_I <= TEMP(7); -- Sample frequency 25033Hz.
            when others => FCLK_I <= TEMP(6); -- Sample frequency 50066Hz.
        end case;
    end process SAMPLECLOCKS;

    AUDIO_OUT: process
    -- These audio out registers provide the audio stream for the
    -- audio DACs. The DACs are binary coded so we need a twos
    -- complement to binary conversion by inverting the MSB.
    variable FCLK_LOCK  : boolean;
    variable TOGGLE     : std_logic;
    begin
        wait until CLK = '1' and CLK' event;
        
        FIFO_RD <= '0'; -- Default.
        
        if RESETn = '0' or (FIFO_EMPTY = '1' and FCLK_I = '1' and FCLK_LOCK = false) then
            AUDIO_LATCH_L <= x"00";
            AUDIO_LATCH_R <= x"00";
            FCLK_LOCK := false;
            TOGGLE := '0';
        elsif FCLK_I = '1' and FCLK_LOCK = false then
            FCLK_LOCK := true;
            if SOUND_MODE_CTRL(7) = '0' then -- Stereo.
                AUDIO_LATCH_L <= FIFO_REG(1)(15 downto 8);
                AUDIO_LATCH_R <= FIFO_REG(1)(7 downto 0);
                FIFO_RD <= '1';
                TOGGLE := '0';
            else -- Mono.
                TOGGLE:= not TOGGLE;
                if TOGGLE = '0' then
                    AUDIO_LATCH_L <= FIFO_REG(1)(15 downto 8);
                    AUDIO_LATCH_R <= FIFO_REG(1)(15 downto 8);
                else
                    AUDIO_LATCH_L <= FIFO_REG(1)(7 downto 0);
                    AUDIO_LATCH_R <= FIFO_REG(1)(7 downto 0);
                    FIFO_RD <= '1';
                end if;
            end if;
        elsif FCLK_I = '0' then
            FCLK_LOCK := false;
        end if;
    end process AUDIO_OUT;

    FIFO_WRITELOGIC: process (CLK, RESETn)
    subtype T_01 is natural range 0 to 1; 
    variable WRITE : T_01;
    variable READ : T_01;
    begin
        if RESETn ='0' then 
            WR_PNT <= 0;
        elsif CLK = '1' and CLK' event then
            if FIFO_WR = '1' then
                WRITE := 1;
            elsif FIFO_WR = '0' then
                WRITE := 0;
            end if;
            if FIFO_RD = '1' then
                READ := 1;
            elsif FIFO_RD = '0' then
                READ := 0;
            end if;
            if WR_PNT = 4 and WRITE = 1 and READ = 0 then
                null; -- FIFO full, no further write.
            elsif WR_PNT = 0 and WRITE = 0 and READ = 1 then
                null; -- FIFO empty, no further read.
            else
                WR_PNT <= WR_PNT + WRITE - READ;
            end if;
        end if;
    end process FIFO_WRITELOGIC;

    FIFO_WR <= not SLOADn;
    FIFO_FULL <= '1' when WR_PNT = 4 else '0';
    FIFO_EMPTY <= '1' when WR_PNT = 0 else '0';

    FIFO: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESETn = '0' then
            FIFO_REG <= (others => (others => '0'));
        else
            for i in 1 to 3 loop
                if i > WR_PNT then
                    FIFO_REG(i) <= DATA_IN;
                elsif FIFO_RD = '1' then
                    FIFO_REG(i) <= FIFO_REG(i+1);            
                end if;
            end loop;
            --
            if WR_PNT < 4 then
                FIFO_REG(4) <= DATA_IN;
            end if;
        end if;
    end process FIFO;   
end architecture BEHAVIOR;