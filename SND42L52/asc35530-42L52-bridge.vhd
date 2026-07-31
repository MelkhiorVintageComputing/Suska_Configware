------------------------------------------------------------------------
----                                                                ----
----  42L52 audio codec controller.                                 ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- The CS42L52 audio codec is controlled via a set of registers.  ----
---- These registers are mapped to the Atari register mapping, for  ----
---- more information see the Suska register listing. All registers ----
---- written to the CODEC are write only respective to the Suska    ----
---- address mapping. All registers written by the CS4299 codec are ----
---- read only respective to the Suska address mapping. The default ----
---- initialitation of this core is master volume set to 0dB and    ----
---- not muted. The auxiliary port volume is set to 0dB and not     ----
---- muted.                                                         ----
---- Playback and capture data is possible in the following way:    ----
---- The INT output indicates the beginning of a new frame. From    ----
---- this time all registers must be updated or read within a       ----
---- total time of 20.8us. To prevent against unpredictable beha-   ----
---- viour there is a technique resulting in always consistent      ----
---- buffers as follows: The output buffer is written wordwise      ----
---- sequentially. The last word to be written is the tag slot 0    ----
---- at address x"FF8820". For playback data there is a second      ----
---- mechanism built in, the DAM transfer. If STE compatible        ----
---- sound DMA is enabled, the output buffer is automatically       ----
---- updated via the SDATA_IN and SDATA_OUT lines. In this case,    ----
---- there are no further requirements playing data. Capturing      ----
---- data via DMA access is not implemented so far.                 ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2011... Wolfgang Foerster - Inventronik GmbH.      ----
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
---- Public License along with this source; if not, down DMA_EN it  ----
---- from http://www.gnu.org/licenses/lgpl.html                     ----
----                                                                ----
------------------------------------------------------------------------
--
-- Revision History
--
-- Revision 2K12A  20120620 WF
--   Initial Release (20111228).
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ASC35530_42L52 is
    port(
        RESETn              : in std_logic;
        CLK                 : in std_logic; -- Use 16MHz+.

        ADR                 : in std_logic_vector(7 downto 1);
        A4299_CS            : in std_logic; -- Base address is x"FF88xx".
        RWn                 : in std_logic;

        DATA_IN             : in std_logic_vector(15 downto 0);
        DATA_OUT            : out std_logic_vector(15 downto 0);
        DATA_EN             : out std_logic;

        INT                 : out std_logic;
        DMA_EN              : in std_logic;
        SDATA_L             : in std_logic_vector(19 downto 0);
        SDATA_R             : in std_logic_vector(19 downto 0);

        BIT_CLK             : in std_logic; -- The bit clock is 12.288MHz.
        SYNC                : out std_logic;
        SDATA_IN            : in std_logic;
        SDATA_OUT           : out std_logic;

        -- ASC35530:
        SCLOCK              : in std_logic;
        ASCLK               : in std_logic;
        ASSYNC              : in std_logic;
        ASDOUT              : in std_logic;
        ASDIN               : out std_logic;

        -- 42L52:
        CODEC_SPKR_HP       : in std_logic;
        CODEC_MCLK          : in std_logic;
        CODEC_SDA           : in std_logic;
        CODEC_AD0           : in std_logic;
        CODEC_FS_LRCK       : in std_logic;
        CODEC_SCLK          : out std_logic;
        CODEC_SDIN          : out std_logic;
        CODEC_SDOUT         : in std_logic;
        CODEC_SCL           : in std_logic
    );
end ASC35530_42L52;

architecture BEHAVIOUR of ASC35530_42L52 is
signal ADR_I        : std_logic_vector(7 downto 0);
signal READ_EN      : std_logic;
signal WRITE_EN     : std_logic;
signal F00          : std_logic;
signal BUFFER_IN    : std_logic_vector(255 downto 0);
signal BUFFER_OUT   : std_logic_vector(255 downto 0);
signal BUFFER_VALID : boolean;
begin
-- The following signals of the ASC35530
-- are not used or hardwired in the Falcon:
-- MODESEL <= '0';
-- SUBFRAME1 <= '0';
-- SUBFRAME2 <= '0';
-- LOWPOWERn <= '1';
-- TESTEN <= '0';
-- BI(3 downto 0) <= x"0";
-- BO(3 downto 0): not used.
-- TEST2: not used

    DATA_EN <= '1' when A4299_CS = '1' and RWn = '1' else '0';

    ADR_I <= ADR & '0';

    READ_EN <= '1' when A4299_CS = '1' and RWn = '1' else '0';
    WRITE_EN <= '1' when A4299_CS = '1' and RWn = '0' else '0';

    DATA_OUT <= BUFFER_IN(255 downto 240) when ADR_I = x"20" and READ_EN = '1' else                   -- TAG slot.
                BUFFER_IN(239 downto 224) when ADR_I = x"22" and READ_EN = '1' else                   -- Status address slot high.
                BUFFER_IN(223 downto 220) & x"000" when ADR_I = x"24" and READ_EN = '1' else          -- Status address slot low.
                BUFFER_IN(219 downto 204) when ADR_I = x"26" and READ_EN = '1' else                   -- Status data slot high.
                BUFFER_IN(203 downto 200) & x"000" when ADR_I = x"28" and READ_EN = '1' else          -- Status data slot low.
                BUFFER_IN(199 downto 184) when ADR_I = x"2A" and READ_EN = '1' else                   -- PCM capture slot 3 high.
                BUFFER_IN(183 downto 180) & x"000" when ADR_I = x"2C" and READ_EN = '1' else          -- PCM capture slot 3 low.
                BUFFER_IN(179 downto 164) when ADR_I = x"2E" and READ_EN = '1' else                   -- PCM capture slot 4 high.
                BUFFER_IN(163 downto 160) & x"000" when ADR_I = x"30" and READ_EN = '1' else x"0000"; -- PCM capture slot 4 low.
                -- We do not really nead the following slots.
                -- BUFFER_IN(159 downto 144) when ADR_I = x"32" and READ_EN = '1' else                -- PCM capture slot 5 high.
                -- BUFFER_IN(143 downto 140) & x"000" when ADR_I = x"34" and READ_EN = '1' else       -- PCM capture slot 5 low.
                -- BUFFER_IN(139 downto 124) when ADR_I = x"36" and READ_EN = '1' else                -- PCM capture slot 6 high.
                -- BUFFER_IN(123 downto 120) & x"000" when ADR_I = x"38" and READ_EN = '1' else       -- PCM capture slot 6 low.
                -- BUFFER_IN(119 downto 104) when ADR_I = x"3A" and READ_EN = '1' else                -- PCM capture slot 7 high.
                -- BUFFER_IN(103 downto 100) & x"000" when ADR_I = x"3C" and READ_EN = '1' else       -- PCM capture slot 7 low.
                -- BUFFER_IN(99 downto 84) when ADR_I = x"3E" and READ_EN = '1' else                  -- PCM capture slot 8 high.
                -- BUFFER_IN(83 downto 80) & x"000" when ADR_I = x"40" and READ_EN = '1' else         -- PCM capture slot 8 low.
                -- BUFFER_IN(79 downto 64) when ADR_I = x"42" and READ_EN = '1' else                  -- PCM capture slot 9 high.
                -- BUFFER_IN(63 downto 60) & x"000" when ADR_I = x"44" and READ_EN = '1' else         -- PCM capture slot 9 low.
                -- BUFFER_IN(59 downto 44) when ADR_I = x"46" and READ_EN = '1' else                  -- PCM capture slot 10 high.
                -- BUFFER_IN(43 downto 40) & x"000" when ADR_I = x"48" and READ_EN = '1' else         -- PCM capture slot 10 low.
                -- BUFFER_IN(39 downto 24) when ADR_I = x"4A" and READ_EN = '1' else                  -- SLOT 11 high.
                -- BUFFER_IN(23 downto 20) & x"000" when ADR_I = x"4C" and READ_EN = '1' else         -- SLOT 11 low.
                -- BUFFER_IN(19 downto 4) when ADR_I = x"4E" and READ_EN = '1' else                   -- SLOT 12 high.
                -- BUFFER_IN(3 downto 0) & x"000" when ADR_I = x"50" and READ_EN = '1' else x"0000";  -- SLOT 12 low.

    OUTBUFFER: process(RESETn, CLK)
    begin
        if RESETn = '0' then
            BUFFER_OUT <= (others => '0');
            BUFFER_VALID <= false;
        elsif CLK = '1' and CLK' event then
            if WRITE_EN = '1' then
                BUFFER_VALID <= false;
                case ADR_I is
                    when x"20" =>
                        BUFFER_OUT(255 downto 240) <= DATA_IN;                          -- TAG slot.
                        BUFFER_VALID <= true;
                    when x"22" => BUFFER_OUT(239 downto 224) <= DATA_IN;                  -- Command address slot high.
                    when x"24" => BUFFER_OUT(223 downto 220) <= DATA_IN(15 downto 12);    -- Command address slot low.
                    when x"26" => BUFFER_OUT(219 downto 204) <= DATA_IN;                  -- Command data slot high.
                    when x"28" => BUFFER_OUT(203 downto 200) <= DATA_IN(15 downto 12);    -- Command data slot low.
                    when x"2A" => BUFFER_OUT(199 downto 184) <= DATA_IN;                  -- PCM playback slot 3 high.
                    when x"2C" => BUFFER_OUT(183 downto 180) <= DATA_IN(15 downto 12);    -- PCM playback slot 3 low.
                    -- when x"2E" => BUFFER_OUT(179 downto 164) <= DATA_IN;               -- PCM playback slot 4 high.
                    -- when x"30" => BUFFER_OUT(163 downto 160) <= DATA_IN(15 downto 12); -- PCM playback slot 4 low.
                    -- when x"32" => BUFFER_OUT(159 downto 144) <= DATA_IN;               -- PCM playback slot 5 high.
                    -- when x"34" => BUFFER_OUT(143 downto 140) <= DATA_IN(15 downto 12); -- PCM playback slot 5 low.
                    -- when x"36" => BUFFER_OUT(139 downto 124) <= DATA_IN;               -- PCM playback slot 6 high.
                    -- when x"38" => BUFFER_OUT(123 downto 120) <= DATA_IN(15 downto 12); -- PCM playback slot 6 low.
                    -- when x"3A" => BUFFER_OUT(119 downto 104) <= DATA_IN;               -- PCM playback slot 7 high.
                    -- when x"3C" => BUFFER_OUT(103 downto 100) <= DATA_IN(15 downto 12); -- PCM playback slot 7 low.
                    -- when x"3E" => BUFFER_OUT(99 downto 84) <= DATA_IN;                 -- PCM playback slot 8 high.
                    -- when x"40" => BUFFER_OUT(83 downto 80) <= DATA_IN(15 downto 12);   -- PCM playback slot 8 low.
                    -- when x"42" => BUFFER_OUT(79 downto 64) <= DATA_IN;                 -- PCM playback slot 9 high.
                    -- when x"44" => BUFFER_OUT(63 downto 60) <= DATA_IN(15 downto 12);   -- PCM playback slot 9 low.
                    -- when x"46" => BUFFER_OUT(59 downto 44) <= DATA_IN;                 -- PCM playback slot 10 high.
                    -- when x"48" => BUFFER_OUT(43 downto 40) <= DATA_IN(15 downto 12);   -- PCM playback slot 10 low.
                    -- when x"4A" => BUFFER_OUT(39 downto 24) <= DATA_IN;                 -- SLOT 11 high.
                    -- when x"4C" => BUFFER_OUT(23 downto 20) <= DATA_IN(15 downto 12);   -- SLOT 11 low.
                    -- when x"4E" => BUFFER_OUT(19 downto 4) <= DATA_IN;                  -- SLOT 12 high.
                    -- when x"50" => BUFFER_OUT(3 downto 0) <= DATA_IN(15 downto 12);     -- SLOT 12 low.
                    when others => null;
                end case;
            elsif DMA_EN = '1' then
                BUFFER_OUT(255 downto 200) <= x"9800_00000_00000"; -- Frame valid, slots 3 and 4 valid.
                BUFFER_OUT(199 downto 160) <= SDATA_L & SDATA_R; -- This is the PCM playback data in Slot 3 and 4.
                BUFFER_OUT(159 downto 0) <= x"00000_00000_00000_00000_00000_00000_00000_00000";
            end if;
        end if;
    end process OUTBUFFER;

    CODEC_RECEIEVE: process (RESETn, BIT_CLK)
    -- This is the input section from the codec. The data is sampled
    -- on the negative clock edge.
    variable SHIFTREG_IN  : std_logic_vector(255 downto 0);
    begin
        if RESETn = '0' then
            SHIFTREG_IN := (others => '0');
        elsif BIT_CLK = '0' and BIT_CLK' event then
            if F00 = '1' then
                SHIFTREG_IN := SHIFTREG_IN(254 downto 0) & SDATA_IN; -- MSB first.
                BUFFER_IN <= SHIFTREG_IN;
            else
                SHIFTREG_IN := SHIFTREG_IN(254 downto 0) & SDATA_IN; -- MSB first.
            end if;
        end if;
    end process CODEC_RECEIEVE;

    CODEC_TRANSMIT: process (RESETn, BIT_CLK)
    -- The transmit shift register work in the BIT_CLK clock domain. Keep attention to
    -- provide a correct clock domain crossing.
    -- The initialisation procedure for FRAMECNT 0 .. 4 is as follows:
    -- Slot0 (TAG slot) / Slot1 (Command Address) / Slot2 (Command Data):
    -- x"E000"  : Master codec; frame, slots 1 and 2 are valid (command write).
    -- x"A6000" : Read power down/controller status register.
    -- x"00000" : Command ata is ignored during read access.
    -- x"E000"  : Master codec; frame, slots 1 and 2 are valid (command write).
    -- x"02000" : Write to master volume register.
    -- x"00000" : Mute off; set primary master volume to 0dB.
    -- x"E000"  : Master codec; frame, slots 1 and 2 are valid (command write).
    -- x"16000" : Write to auxiliary volume register.
    -- x"08080" : Mute off; set primary master volume to 0dB.
    variable SHIFTREG_OUT : std_logic_vector(255 downto 0);
    variable BITCNT       : std_logic_vector(7 downto 0);
    variable FRAMECNT     : integer range 0 to 4;
    begin
        if RESETn = '0' then
            FRAMECNT := 0;
            SHIFTREG_OUT := (others => '0');
            BITCNT := x"00";
        elsif BIT_CLK = '1' and BIT_CLK' event then

            BITCNT := BITCNT + '1';

            if BITCNT = x"00" and BUFFER_IN(255) = '1' and FRAMECNT < 4 then
                -- Important! Right after startup, the power down / controller status register (26h) must be checked. bits D3 ... D0 must be set
                -- to indicate a ready analog section. Refer to the CS4299 datasheet for more information. If the codec is not ready, it will not
                -- accept any settings to the respective registers like volume or mute.
                if FRAMECNT = 1 and BUFFER_IN(254 downto 253) = "11" and BUFFER_IN(238 downto 232) = "0100110" and BUFFER_IN(207 downto 204) = x"F" then
                    FRAMECNT := FRAMECNT + 1; -- Analog ... ready
                elsif FRAMECNT /= 1 then
                    FRAMECNT := FRAMECNT + 1;
                end if;
            elsif BITCNT = x"00" and BUFFER_IN(255) = '0' then
                FRAMECNT := 0; --Loss of SYNC.
            end if;

            if BITCNT = x"FF" then -- One Frame is 256 bit.
                F00 <= '1'; -- This is the internal SYNC flag (see CODEC_RECEIEVE).
            else
                F00 <= '0';
            end if;

            if BITCNT = x"FF" then
                SYNC <= '1'; -- SYNC is asserted one bit clock before sampling data.
            elsif BITCNT = x"0F" then
                SYNC <= '0';
            end if;

            if BITCNT = x"00" then
                case FRAMECNT is
                    when 0 => null;
                    when 1 => SHIFTREG_OUT := x"E000_A6000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000"; -- Read controller status.
                    when 2 => SHIFTREG_OUT := x"E000_02000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000"; -- Write master volume.
                    when 3 => SHIFTREG_OUT := x"E000_16000_08080_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000"; -- Write aux volume.
                    when 4 =>
                        if BUFFER_VALID = true then
                            SHIFTREG_OUT := BUFFER_OUT; -- Data, MSB first.
                            INT <= '1';
                        elsif DMA_EN = '1' then
                            SHIFTREG_OUT := BUFFER_OUT; -- Data, MSB first.
                        else
                            INT <= '0';
                        end if;
                end case;
            else
                SHIFTREG_OUT := SHIFTREG_OUT(254 downto 0) & SHIFTREG_OUT(255); -- MSB first, ringbuffer.
            end if;
        end if;
        SDATA_OUT <= SHIFTREG_OUT(255);
    end process CODEC_TRANSMIT;
end BEHAVIOUR;