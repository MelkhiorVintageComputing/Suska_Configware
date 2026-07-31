------------------------------------------------------------------------
----                                                                ----
----  Atari Falcon compatible direct memory access coprocessor.     ----
----  This file is part of the SUSKA-ATARI clone project.           ----
----                                                                ----
----  Author: Wolfgang Foerster                                     ----
----          support@inventronk.de                                 ----
----          www.inventronik.de                                    ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â© 2012... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- All rights reserved. No portion of this sourcecode may be      ----
---- reproduced or transmitted in any form by any means, whether    ----
---- by electronic, mechanical, photocopying, recording or          ----
---- otherwise, without my written permission.                      ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Description:                                                   ----
----                                                                ----
------------------------------------------------------------------------
-- 
-- Revision History
-- 
-- Revision 2K12A  20120620 WF
--   Initial Release.
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity PCM_CTRL is
    port(
        RESET                   : in std_logic;

        CLK_32                  : in std_logic; -- 32MHz.
        SNCLK                   : in std_logic; -- 25.175MHz.
        CLK_EXT                 : in std_logic; -- External clock, 22.

        -- External serial output channel:
        PLYDATA                 : out std_logic;
        PLYCLK                  : out std_logic;
        PLYSYNC_IN              : in std_logic; -- Gated clock mode.
        PLYSYNC_OUT             : out std_logic; -- Continuous clock mode.
        PLYSYNC_EN              : out std_logic; -- Continuous clock mode.

        -- External serial input channel:
        RECDATA                 : in std_logic;
        RECCLK                  : out std_logic;
        RECSYNC_IN              : in std_logic; -- Gated clock mode.
        RECSYNC_OUT             : out std_logic; -- Continuous clock mode.
        RECSYNC_EN              : out std_logic; -- Continuous clock mode.

        -- DSP connector:
        DSP_SRD                 : out std_logic; -- DSP receives data.
        DSP_SCK                 : out std_logic; -- Transmit clockout.
        DSP_SC2_IN              : in std_logic; -- Transmit syncout.
        DSP_SC2_OUT             : out std_logic; -- Transmit syncout.
        DSP_REC_EN              : out std_logic; -- Tristate control.
        DSP_STD                 : in std_logic; -- DSP transmits data.
        DSP_SC0                 : out std_logic; -- Receive clockout.
        DSP_SC1_IN              : in std_logic; -- Receive syncout.
        DSP_SC1_OUT             : out std_logic; -- Receive syncout.
        DSP_PLY_EN              : out std_logic; -- Tristate control.

        -- Audio codec:
        SCLOCK                  : out std_logic; -- Codec clockout.
        ASCLK                   : out std_logic; -- Bitclock.
        ASSYNC                  : out std_logic;
        ASDOUT                  : in std_logic; -- Sampled on the rising edge of ASCLK.
        ASDIN                   : out std_logic; -- Sampled on the falling edge of ASCLK.

        -- PCM playback data channel:
        REPLAY_DATAREQ          : out std_logic; -- Data request from the sound device.
        REPLAY_DATACK           : in std_logic; -- Data request from the sound device.
        REPLAY_FIFO_EMPTY       : in std_logic;
        PCM_DATA_IN             : in std_logic_vector (15 downto 0);

        -- PCM capture data channel:
        CAPTURE_DATAREQ         : out std_logic; -- Data request from the sound device.
        CAPTURE_DATACK          : in std_logic; -- Data request from the sound device.
        CAPTURE_FIFO_FULL       : in std_logic;
        PCM_DATA_OUT            : out std_logic_vector (15 downto 0);

        -- Configuration signals:
        CROSSBAR_SOURCE         : in std_logic_vector(15 downto 0);
        CROSSBAR_DEST           : in std_logic_vector(15 downto 0);
        DAC_TRACK_SEL           : in std_logic_vector(1 downto 0);
        TRACK_PLAY              : in std_logic_vector(1 downto 0);
        SMODE_FREQ              : in std_logic_vector(1 downto 0);
        SMODE_SEL               : in std_logic_vector(1 downto 0);
        FREQ_DIV_EXT            : in std_logic_vector(3 downto 0);
        FREQ_DIV_INT            : in std_logic_vector(3 downto 0);
        REC_TRACK_SEL           : in std_logic_vector(1 downto 0);
        DAC_SRC                 : in std_logic_vector(1 downto 0);
        ADC_SRC                 : in std_logic_vector(1 downto 0);
        GAIN                    : in std_logic_vector(7 downto 0);
        ATTENUATION             : in std_logic_vector(7 downto 0);
        CODEC_TAG               : in std_logic_vector(15 downto 0);
        CODEC_ADDRESS           : in std_logic_vector(15 downto 0);
        CODEC_COMMAND           : in std_logic_vector(15 downto 0);
        CODEC_FMODEn            : in std_logic; -- ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â´'0' = Falcon compatible.
        DAC_OV                  : out std_logic; -- Overflow.
        ADC_OV                  : out std_logic -- Overflow.       
    );
end PCM_CTRL;

architecture BEHAVIOR of PCM_CTRL is
type STRB_SELTYPE is (M32, SM, EXT, OFF);

signal PCMREC_STRB_SEL      : STRB_SELTYPE;
signal DSPREC_STRB_SEL      : STRB_SELTYPE;
signal PLY_STRB_SEL         : STRB_SELTYPE;

signal BIT_CLK_EXT          : std_logic;
signal BIT_CLK_SM           : std_logic;
signal BIT_CLK_32M          : std_logic;

signal SAMPLE_CLK_EXT       : std_logic;
signal SAMPLE_CLK_SM        : std_logic;
signal SAMPLE_CLK_32M       : std_logic;

signal BIT_STRB_32M_N       : std_logic;
signal BIT_STRB_32M_P       : std_logic;
signal SAMPLE_STRB_32M      : std_logic;

signal BIT_STRB_SM_N        : std_logic;
signal BIT_STRB_SM_P        : std_logic;
signal SAMPLE_STRB_SM       : std_logic;

signal BIT_STRB_EXT_N       : std_logic;
signal BIT_STRB_EXT_P       : std_logic;
signal SAMPLE_STRB_EXT      : std_logic;

signal REC_BIT_STRB         : std_logic;
signal REC_SAMPLE_STRB      : std_logic;
signal RECCLK_EN            : std_logic;
signal RECCLK_I             : std_logic;

signal PLY_BIT_STRB         : std_logic;
signal PLY_SAMPLE_STRB      : std_logic;
signal PLYCLK_EN            : std_logic;
signal PLYCLK_I             : std_logic;

signal DSPPLY_BIT_STRB      : std_logic;
signal DSPPLY_SAMPLE_STRB   : std_logic;
signal DSPREC_BIT_STRB      : std_logic;
signal DSPREC_SAMPLE_STRB   : std_logic;
signal DSP_SC0_EN           : std_logic;
signal DSP_SC0_I            : std_logic;
signal DSP_SCK_EN           : std_logic;
signal DSP_SCK_I            : std_logic;

signal CODEC_BIT_STRB       : std_logic;
signal CODEC_SAMPLE_STRB    : std_logic;

signal PCMREC_BIT_STRB      : std_logic;
signal PCMREC_SAMPLE_STRB   : std_logic;
signal PCMREC_CLK_EN        : std_logic;
signal PCMREC_SYNC          : std_logic;

signal PCMPLY_BIT_STRB      : std_logic;
signal PCMPLY_SAMPLE_STRB   : std_logic;
signal PCMPLY_CLK_EN        : std_logic;
signal PCMPLY_SYNC          : std_logic;

signal PCM_STD              : std_logic;
signal AD_DATA              : std_logic;

signal CODEC_BIT_STRB_N     : std_logic;
signal CODEC_BIT_STRB_P     : std_logic;
signal F00                  : std_logic; -- Codec frame sync.
signal CODEC_BUFFER_IN      : std_logic_vector(255 downto 160);
signal CODEC_BUFFER_OUT     : std_logic_vector(255 downto 160);
begin
    -------------------------------------------------------------------------------------------------------------
    --                                             Clock system.                                               --
    -------------------------------------------------------------------------------------------------------------
    P_CLK_EXT: process
    variable DIV128         : integer range 1 to 128;
    variable BITRATE_DIV    : integer range 1 to 16;
    variable BITRATE_CNT    : integer range 1 to 16;
    begin
        wait until CLK_EXT = '1' and CLK_EXT' event;
        case FREQ_DIV_EXT is
            when x"0" =>
                case SMODE_FREQ is
                    when "00" => BITRATE_DIV := 16; -- Sample frequency 06146Hz.
                    when "01" => BITRATE_DIV := 8; -- Sample frequency 12292Hz.
                    when "10" => BITRATE_DIV := 4; -- Sample frequency 24585Hz.
                    when others => BITRATE_DIV := 2; -- Sample frequency 49170Hz.
                end case;
            when others => BITRATE_DIV := Conv_Integer(FREQ_DIV_EXT) + 1;
        end case;
            
        if BITRATE_CNT = BITRATE_DIV then
            BITRATE_CNT := 1;
            BIT_CLK_EXT <= not BIT_CLK_EXT;
            if DIV128 = 128 then
                DIV128 := 1;
            elsif DIV128 = 1 then -- Switch when BIT_CLK is low.
                DIV128 := DIV128 + 1;
                SAMPLE_CLK_EXT <= not SAMPLE_CLK_EXT;
            else
                DIV128 := DIV128 + 1;
            end if;
        else
            BITRATE_CNT := BITRATE_CNT + 1;
        end if;
    end process P_CLK_EXT;

    P_SNCLK: process
    variable DIV128         : integer range 1 to 128;
    variable BITRATE_DIV    : integer range 1 to 16;
    variable BITRATE_CNT    : integer range 1 to 16;
    begin
        wait until SNCLK = '1' and SNCLK' event;
        case FREQ_DIV_EXT is
            when x"0" =>
                case SMODE_FREQ is
                    when "00" => BITRATE_DIV := 16; -- Sample frequency 06146Hz.
                    when "01" => BITRATE_DIV := 8; -- Sample frequency 12292Hz.
                    when "10" => BITRATE_DIV := 4; -- Sample frequency 24585Hz.
                    when others => BITRATE_DIV := 2; -- Sample frequency 49170Hz.
                end case;
            when others => BITRATE_DIV := Conv_Integer(FREQ_DIV_EXT) + 1;
        end case;
            
        if BITRATE_CNT = BITRATE_DIV then
            BITRATE_CNT := 1;
            BIT_CLK_SM <= not BIT_CLK_SM;
            if DIV128 = 128 then
                DIV128 := 1;
            elsif DIV128 = 1 then -- Switch when BIT_CLK is low.
                DIV128 := DIV128 + 1;
                SAMPLE_CLK_SM <= not SAMPLE_CLK_SM;
            else
                DIV128 := DIV128 + 1;
            end if;
        else
            BITRATE_CNT := BITRATE_CNT + 1;
        end if;
    end process P_SNCLK;

    P_CLK_32M: process
    variable DIV128         : integer range 1 to 128;
    variable BITRATE_DIV    : integer range 1 to 16;
    variable BITRATE_CNT    : integer range 1 to 16;
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        case FREQ_DIV_EXT is
            when x"0" =>
                case SMODE_FREQ is
                    when "00" => BITRATE_DIV := 16; -- Sample frequency 06146Hz.
                    when "01" => BITRATE_DIV := 8; -- Sample frequency 12292Hz.
                    when "10" => BITRATE_DIV := 4; -- Sample frequency 24585Hz.
                    when others => BITRATE_DIV := 2; -- Sample frequency 49170Hz.
                end case;
            when others => BITRATE_DIV := Conv_Integer(FREQ_DIV_EXT) + 1;
        end case;
            
        if BITRATE_CNT = BITRATE_DIV then
            BITRATE_CNT := 1;
            BIT_CLK_32M <= not BIT_CLK_32M;
            if DIV128 = 128 then
                DIV128 := 1;
            elsif DIV128 = 1 then -- Switch when BIT_CLK is low.
                DIV128 := DIV128 + 1;
                SAMPLE_CLK_32M <= not SAMPLE_CLK_32M;
            else
                DIV128 := DIV128 + 1;
            end if;
        else
            BITRATE_CNT := BITRATE_CNT + 1;
        end if;
    end process P_CLK_32M;

    STROBES: process
    -- These flip flops synchronize the different clock domains.
    variable LOCK_BIT_CLK_32M_N     : boolean;
    variable LOCK_BIT_CLK_32M_P     : boolean;
    variable LOCK_SAMPLE_CLK_32M    : boolean;
    variable LOCK_BIT_CLK_SM_N      : boolean;
    variable LOCK_BIT_CLK_SM_P      : boolean;
    variable LOCK_SAMPLE_CLK_SM     : boolean;
    variable LOCK_BIT_CLK_EXT_N     : boolean;
    variable LOCK_BIT_CLK_EXT_P     : boolean;
    variable LOCK_SAMPLE_CLK_EXT    : boolean;
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        if BIT_CLK_32M = '0' and LOCK_BIT_CLK_32M_N = false then
            BIT_STRB_32M_N <= '1';
            LOCK_BIT_CLK_32M_N := true;
        elsif SAMPLE_CLK_32M = '1' then
            BIT_STRB_32M_N <= '0';
            LOCK_BIT_CLK_32M_N := false;
        else
            BIT_STRB_32M_N <= '0';
        end if;

        if BIT_CLK_32M = '1' and LOCK_BIT_CLK_32M_P = false then
            BIT_STRB_32M_P <= '1';
            LOCK_BIT_CLK_32M_P := true;
        elsif SAMPLE_CLK_32M = '0' then
            BIT_STRB_32M_P <= '0';
            LOCK_BIT_CLK_32M_P := false;
        else
            BIT_STRB_32M_P <= '0';
        end if;

        if SAMPLE_CLK_32M = '1' and LOCK_SAMPLE_CLK_32M = false then
            SAMPLE_STRB_32M <= '1';
            LOCK_SAMPLE_CLK_32M := true;
        elsif SAMPLE_CLK_32M = '0' then
            SAMPLE_STRB_32M <= '0';
            LOCK_SAMPLE_CLK_32M := false;
        else
            SAMPLE_STRB_32M <= '0';
        end if;

        if BIT_CLK_SM = '0' and LOCK_BIT_CLK_SM_N = false then
            BIT_STRB_SM_N <= '1';
            LOCK_BIT_CLK_SM_N := true;
        elsif SAMPLE_CLK_SM = '1' then
            BIT_STRB_SM_N <= '0';
            LOCK_BIT_CLK_SM_N := false;
        else
            BIT_STRB_SM_N <= '0';
        end if;

        if BIT_CLK_SM = '1' and LOCK_BIT_CLK_SM_P = false then
            BIT_STRB_SM_P <= '1';
            LOCK_BIT_CLK_SM_P := true;
        elsif SAMPLE_CLK_SM = '0' then
            BIT_STRB_SM_P <= '0';
            LOCK_BIT_CLK_SM_P := false;
        else
            BIT_STRB_SM_P <= '0';
        end if;

        if SAMPLE_CLK_SM = '1' and LOCK_SAMPLE_CLK_SM = false then
            SAMPLE_STRB_SM <= '1';
            LOCK_SAMPLE_CLK_SM := true;
        elsif SAMPLE_CLK_SM = '0' then
            SAMPLE_STRB_SM <= '0';
            LOCK_SAMPLE_CLK_SM := false;
        else
            SAMPLE_STRB_SM <= '0';
        end if;

        if BIT_CLK_EXT = '0' and LOCK_BIT_CLK_EXT_N = false then
            BIT_STRB_EXT_N <= '1';
            LOCK_BIT_CLK_EXT_N := true;
        elsif SAMPLE_CLK_EXT = '1' then
            BIT_STRB_EXT_N <= '0';
            LOCK_BIT_CLK_EXT_N := false;
        else
            BIT_STRB_EXT_N <= '0';
        end if;

        if BIT_CLK_EXT = '1' and LOCK_BIT_CLK_EXT_P = false then
            BIT_STRB_EXT_P <= '1';
            LOCK_BIT_CLK_EXT_P := true;
        elsif SAMPLE_CLK_EXT = '0' then
            BIT_STRB_EXT_P <= '0';
            LOCK_BIT_CLK_EXT_P := false;
        else
            BIT_STRB_EXT_P <= '0';
        end if;

        if SAMPLE_CLK_EXT = '1' and LOCK_SAMPLE_CLK_EXT = false then
            SAMPLE_STRB_EXT <= '1';
            LOCK_SAMPLE_CLK_EXT := true;
        elsif SAMPLE_CLK_EXT = '0' then
            SAMPLE_STRB_EXT <= '0';
            LOCK_SAMPLE_CLK_EXT := false;
        else
            SAMPLE_STRB_EXT <= '0';
        end if;
    end process STROBES;

    -------------------------------------------------------------------------------------------------------------
    --                                 External serial data input section.                                     --
    -------------------------------------------------------------------------------------------------------------
    with CROSSBAR_SOURCE(10 downto 9) select
        REC_BIT_STRB <= '0' when "11",
                        BIT_STRB_32M_N when "10",
                        BIT_STRB_EXT_N when "01",
                        BIT_STRB_SM_N when others; -- "00".

    with CROSSBAR_SOURCE(10 downto 9) select
        REC_SAMPLE_STRB <= '0' when "11",
                            SAMPLE_STRB_32M when "10",
                            SAMPLE_STRB_EXT when "01",
                            SAMPLE_STRB_SM when others; -- "00".

    with CROSSBAR_SOURCE(10 downto 9) select
        RECCLK_I <= '0' when "11",
                    BIT_CLK_32M when "10",
                    BIT_CLK_EXT when "01",
                    BIT_CLK_SM when others; -- "00".

    RECSYNC_EN <= CROSSBAR_SOURCE(8);

    RECCLK_EN <= '0' when CROSSBAR_DEST(10 downto 8) = "100" and PLYSYNC_IN = '0' else -- Destination is external in handshaking mode.
                 '0' when CROSSBAR_DEST(6 downto 4) = "100" and DSP_SC2_IN = '0' else -- Destination is the DSP in handshaking mode.
                 '0' when CROSSBAR_DEST(2 downto 0) = "100" and PCMREC_SYNC = '0' else '1'; -- Destination is PCM capture in handshaking mode.

    REC_CLOCKOUT: process
    -- The bitclock is controlled by the destination device.
    variable CNT    : integer range 0 to 16;
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        if RECCLK_EN = '1' and REC_BIT_STRB = '1' and CNT = 16 then
            CNT := 0;
            RECCLK <= RECCLK_I;
        else
            if REC_BIT_STRB = '1' and CNT < 16 then
                CNT := CNT + 1;
                RECCLK <= RECCLK_I;
            elsif REC_BIT_STRB = '1' then
                RECCLK <= '0';
            end if;
        end if;
    end process REC_CLOCKOUT;

    REC_SYNCOUT: process
    variable BITCNT             : integer range 0 to 15;
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        if REC_SAMPLE_STRB = '1' then
            RECSYNC_OUT <= '1';
            BITCNT := 0;
        elsif REC_BIT_STRB = '1' then
            case BITCNT is
                when 15 => RECSYNC_OUT <= '0';
                when others => 
                    if BITCNT < 15 then
                        BITCNT := BITCNT + 1;
                    end if; 
            end case;
        end if;
    end process REC_SYNCOUT;

    -------------------------------------------------------------------------------------------------------------
    --                                External serial data output section.                                     --
    -------------------------------------------------------------------------------------------------------------
    PLY_STRB_SEL  <= M32 when CROSSBAR_DEST(10 downto 9) = "00" and CROSSBAR_SOURCE(2 downto 1) = "10" else -- Source = PCM playback.
                     EXT when CROSSBAR_DEST(10 downto 9) = "00" and CROSSBAR_SOURCE(2 downto 1) = "01" else -- Source = PCM playback.
                     SM when CROSSBAR_DEST(10 downto 9) = "00" and CROSSBAR_SOURCE(2 downto 1) = "00" else -- Source = PCM playback.
                     M32 when CROSSBAR_DEST(10 downto 9) = "01" and CROSSBAR_SOURCE(6 downto 5) = "10" else -- Source = DSP transmit.
                     EXT when CROSSBAR_DEST(10 downto 9) = "01" and CROSSBAR_SOURCE(6 downto 5) = "01" else -- Source = DSP transmit.
                     SM when CROSSBAR_DEST(10 downto 9) = "01" and CROSSBAR_SOURCE(6 downto 5) = "00" else -- Source = DSP transmit.
                     M32 when CROSSBAR_DEST(10 downto 9) = "10" and CROSSBAR_SOURCE(10 downto 9) = "10" else -- Source = External input.
                     EXT when CROSSBAR_DEST(10 downto 9) = "10" and CROSSBAR_SOURCE(10 downto 9) = "01" else -- Source = External input.
                     SM when CROSSBAR_DEST(10 downto 9) = "10" and CROSSBAR_SOURCE(10 downto 9) = "00" else -- Source = External input.
                     M32 when CROSSBAR_DEST(10 downto 9) = "11" and CROSSBAR_SOURCE(14 downto 13) = "10" else -- Source = AD converter.
                     EXT when CROSSBAR_DEST(10 downto 9) = "11" and CROSSBAR_SOURCE(14 downto 13) = "01" else -- Source = AD converter.
                     SM when CROSSBAR_DEST(10 downto 9) = "11" and CROSSBAR_SOURCE(14 downto 13) = "00" else OFF; -- Source = AD converter.

    with PLY_STRB_SEL select
        PLY_BIT_STRB <= BIT_STRB_32M_P when M32,
                        BIT_STRB_SM_P when SM,
                        BIT_STRB_EXT_P when EXT,
                        '0' when others;

    with PLY_STRB_SEL select
        PLY_SAMPLE_STRB <= SAMPLE_STRB_32M when M32,
                           SAMPLE_STRB_SM when SM,
                           SAMPLE_STRB_EXT when EXT,
                           '0' when others;

    with PLY_STRB_SEL select
        PLYCLK_I <= BIT_CLK_32M when M32,
                    BIT_CLK_SM when SM,
                    BIT_CLK_EXT when EXT,
                    '0' when others;

    PLYSYNC_EN <= CROSSBAR_DEST(8);

    PLYCLK_EN <= '0' when CROSSBAR_DEST(10 downto 9) = "10" and CROSSBAR_SOURCE(8) = '0' and RECSYNC_IN = '0' else -- Source is external in handshaking mode.
                 '0' when CROSSBAR_DEST(10 downto 9) = "01" and CROSSBAR_SOURCE(4) = '0' and DSP_SC1_IN = '0' else -- Source is the DSP in handshaking mode.
                 '0' when CROSSBAR_DEST(10 downto 9) = "00" and CROSSBAR_SOURCE(0) = '0' and PCMPLY_SYNC = '0' else '1'; -- Source is DMA playback in handshaking mode.

    PLY_CLOCKOUT: process
    -- The bitclock is controlled by the source device.
    variable CNT    : integer range 0 to 16;
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        if PLYCLK_EN = '1' and PLY_BIT_STRB = '1' and CNT = 16 then
            CNT := 0;
            PLYCLK <= PLYCLK_I;
        else
            if PLY_BIT_STRB = '1' and CNT < 16 then
                CNT := CNT + 1;
                PLYCLK <= PLYCLK_I;
            elsif PLY_BIT_STRB = '1' then
                PLYCLK <= '0';
            end if;
        end if;
    end process PLY_CLOCKOUT;

    PLY_SYNCOUT: process
    variable BITCNT             : integer range 0 to 15;
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        if PLY_SAMPLE_STRB = '1' then
            PLYSYNC_OUT <= '1';
            BITCNT := 0;
        elsif PLY_BIT_STRB = '1' then
            case BITCNT is
                when 15 => PLYSYNC_OUT <= '0';
                when others => 
                    if BITCNT < 15 then
                        BITCNT := BITCNT + 1;
                    end if; 
            end case;
        end if;
    end process PLY_SYNCOUT;

    with CROSSBAR_DEST(10 downto 9) select
        PLYDATA <= AD_DATA when "11",
                   RECDATA when "10",
                   DSP_STD when "01",
                   PCM_STD when others;

    -------------------------------------------------------------------------------------------------------------
    --                              Digital signal processor input section.                                    --
    -------------------------------------------------------------------------------------------------------------
    with CROSSBAR_SOURCE(6 downto 5) select
        DSPPLY_BIT_STRB <= '0' when "11",
                           BIT_STRB_32M_N when "10",
                           BIT_STRB_EXT_N when "01",
                           BIT_STRB_SM_N when others;

    with CROSSBAR_SOURCE(6 downto 5) select
        DSPPLY_SAMPLE_STRB <= '0' when "11",
                              SAMPLE_STRB_32M when "10",
                              SAMPLE_STRB_EXT when "01",
                              SAMPLE_STRB_SM when others;

    with CROSSBAR_SOURCE(6 downto 5) select
        DSP_SC0_I <= '0' when "11",
                     BIT_CLK_32M when "10",
                     BIT_CLK_EXT when "01",
                     BIT_CLK_SM when others;

    DSP_SC0_EN <= '0' when CROSSBAR_DEST(10 downto 8) = "010" and PLYSYNC_IN = '0' else -- Destination is external in handshaking mode.
                  '0' when CROSSBAR_DEST(6 downto 4) = "010" and DSP_SC2_IN = '0' else -- Destination is the DSP in handshaking mode.
                  '0' when CROSSBAR_DEST(2 downto 0) = "010" and PCMREC_SYNC = '0' else '1'; -- Destination is PCM capture in handshaking mode.

    DSPPLY_CLOCKOUT: process
    -- The bitclock is controlled by the destination device.
    variable CNT    : integer range 0 to 16;
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        if DSP_SC0_EN = '1' and DSPPLY_BIT_STRB = '1' and CNT = 16 then
            CNT := 0;
            DSP_SC0 <= DSP_SC0_I;
        else
            if DSPPLY_BIT_STRB = '1' and CNT < 16 then
                CNT := CNT + 1;
                DSP_SC0 <= DSP_SC0_I;
            elsif DSPPLY_BIT_STRB = '1' then
                DSP_SC0 <= '0';
            end if;
        end if;
    end process DSPPLY_CLOCKOUT;

    DSPPLY_SYNCOUT: process
    variable BITCNT : integer range 0 to 15;
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        if DSPPLY_SAMPLE_STRB = '1' then
            DSP_SC1_OUT <= '1';
            BITCNT := 0;
        elsif DSPPLY_BIT_STRB = '1' then
            case BITCNT is
                when 15 => DSP_SC1_OUT <= '0';
                when others =>
                    if BITCNT < 15 then
                        BITCNT := BITCNT + 1;
                    end if;  
            end case;
        end if;
    end process DSPPLY_SYNCOUT;

    DSP_PLY_EN <= CROSSBAR_SOURCE(7);

    -------------------------------------------------------------------------------------------------------------
    --                              Digital signal processor output section.                                   --
    -------------------------------------------------------------------------------------------------------------
    DSPREC_STRB_SEL  <= M32 when CROSSBAR_DEST(6 downto 5) = "00" and CROSSBAR_SOURCE(2 downto 1) = "10" else -- Source = PCM playback.
                        EXT when CROSSBAR_DEST(6 downto 5) = "00" and CROSSBAR_SOURCE(2 downto 1) = "01" else -- Source = PCM playback.
                        SM when CROSSBAR_DEST(6 downto 5) = "00" and CROSSBAR_SOURCE(2 downto 1) = "00" else -- Source = PCM playback.
                        M32 when CROSSBAR_DEST(6 downto 5) = "01" and CROSSBAR_SOURCE(6 downto 5) = "10" else -- Source = DSP transmit.
                        EXT when CROSSBAR_DEST(6 downto 5) = "01" and CROSSBAR_SOURCE(6 downto 5) = "01" else -- Source = DSP transmit.
                        SM when CROSSBAR_DEST(6 downto 5) = "01" and CROSSBAR_SOURCE(6 downto 5) = "00" else -- Source = DSP transmit.
                        M32 when CROSSBAR_DEST(6 downto 5) = "10" and CROSSBAR_SOURCE(10 downto 9) = "10" else -- Source = External input.
                        EXT when CROSSBAR_DEST(6 downto 5) = "10" and CROSSBAR_SOURCE(10 downto 9) = "01" else -- Source = External input.
                        SM when CROSSBAR_DEST(6 downto 5) = "10" and CROSSBAR_SOURCE(10 downto 9) = "00" else -- Source = External input.
                        M32 when CROSSBAR_DEST(6 downto 5) = "11" and CROSSBAR_SOURCE(14 downto 13) = "10" else -- Source = AD converter.
                        EXT when CROSSBAR_DEST(6 downto 5) = "11" and CROSSBAR_SOURCE(14 downto 13) = "01" else -- Source = AD converter.
                        SM when CROSSBAR_DEST(6 downto 5) = "11" and CROSSBAR_SOURCE(14 downto 13) = "00" else OFF; -- Source = AD converter.

    with DSPREC_STRB_SEL select
        DSPREC_BIT_STRB <= BIT_STRB_32M_P when M32,
                           BIT_STRB_SM_P when SM,
                           BIT_STRB_EXT_P when EXT,
                           '0' when others;

    with DSPREC_STRB_SEL select
        DSPREC_SAMPLE_STRB <= SAMPLE_STRB_32M when M32,
                              SAMPLE_STRB_SM when SM,
                              SAMPLE_STRB_EXT when EXT,
                              '0' when others;

    with DSPREC_STRB_SEL select
        DSP_SCK_I <= BIT_CLK_32M when M32,
                     BIT_CLK_SM when SM,
                     BIT_CLK_EXT when EXT,
                     '0' when others;

    DSP_SCK_EN <= '0' when CROSSBAR_DEST(6 downto 5) = "10" and CROSSBAR_SOURCE(8) = '0' and RECSYNC_IN = '0' else -- Source is external in handshaking mode.
                  '0' when CROSSBAR_DEST(6 downto 5) = "01" and CROSSBAR_SOURCE(4) = '0' and DSP_SC1_IN = '0' else -- Source is the DSP in handshaking mode.
                  '0' when CROSSBAR_DEST(6 downto 5) = "00" and CROSSBAR_SOURCE(0) = '0' and PCMPLY_SYNC = '0' else '1'; -- Source is DMA playback in handshaking mode.

    DSPREC_CLOCKOUT: process
    -- The bitclock is controlled by the source device.
    variable CNT    : integer range 0 to 16;
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        if DSP_SCK_EN = '1' and DSPREC_BIT_STRB = '1' and CNT = 16 then
            CNT := 0;
            DSP_SCK <= DSP_SCK_I;
        else
            if DSPREC_BIT_STRB = '1' and CNT < 16 then
                CNT := CNT + 1;
                DSP_SCK <= DSP_SCK_I;
            elsif DSPREC_BIT_STRB = '1' then
                DSP_SCK <= '0';
            end if;
        end if;
    end process DSPREC_CLOCKOUT;

    DSPREC_SYNCOUT: process
    variable BITCNT             : integer range 0 to 15;
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        if DSPREC_SAMPLE_STRB = '1' then
            DSP_SC2_OUT <= '1';
            BITCNT := 0;
        elsif DSPREC_BIT_STRB = '1' then
            case BITCNT is
                when 15 => DSP_SC2_OUT <= '0';
                when others =>
                    if BITCNT < 15 then
                        BITCNT := BITCNT + 1;
                    end if;  
            end case;
        end if;
    end process DSPREC_SYNCOUT;

    DSP_REC_EN <= CROSSBAR_DEST(7);

    with CROSSBAR_DEST(6 downto 5) select
        DSP_SRD <= AD_DATA when "11",
                   RECDATA when "10",
                   DSP_STD when "01",
                   PCM_STD when others;

    -------------------------------------------------------------------------------------------------------------
    --                                              Audio codec section.                                       --
    -------------------------------------------------------------------------------------------------------------
    with CROSSBAR_SOURCE(13) select
        CODEC_BIT_STRB_N <= BIT_STRB_SM_N when '0',
                            BIT_STRB_EXT_N when others;

    with CROSSBAR_SOURCE(13) select
        CODEC_BIT_STRB_P <= BIT_STRB_SM_P when '0',
                            BIT_STRB_EXT_P when others;

    with CROSSBAR_SOURCE(13) select
        CODEC_SAMPLE_STRB <= SAMPLE_STRB_SM when '0',
                             SAMPLE_STRB_EXT when others;

    with CROSSBAR_SOURCE(13) select
        SCLOCK <= SNCLK when '0',
                  CLK_EXT when others;

    with CROSSBAR_SOURCE(13) select
        ASCLK <= BIT_CLK_SM when '0',
                 BIT_CLK_EXT when others;

    BUFFERS: process
    variable BITCNT     : integer range 0 to 16;
    variable WORDCOUNT  : integer range 1 to 7;
    variable WCNT       : integer range 0 to 8;
    variable FRAMECNT   : integer range 0 to 8;
    variable SHIFT_OUT  : std_logic_vector(15 downto 0);
    variable SHIFT_IN   : std_logic_vector(15 downto 0);
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        
        case DAC_TRACK_SEL is
            when "11" => WORDCOUNT := 7;
            when "10" => WORDCOUNT := 5;
            when "01" => WORDCOUNT := 3;
            when others => WORDCOUNT := 1;
        end case;

        if CODEC_SAMPLE_STRB = '1' then
            WCNT := 0;
            BITCNT := 0;
            FRAMECNT := 0;
        elsif CODEC_BIT_STRB_P = '1' then
            if BITCNT < 16 then
                BITCNT := BITCNT + 1;
            end if;
            case BITCNT is
                when 16 =>
                    BITCNT := 0;
                    
                    if WCNT < 16 then
                        WCNT := WCNT + 1;
                    end if;
                    
                    if FRAMECNT < 8 then
                        FRAMECNT := FRAMECNT + 1;
                    else
                        FRAMECNT := 0;
                    end if;
                    if CODEC_FMODEn = '0' then -- Send Falcon compatible control data.
                        case FRAMECNT is
                            when 1 => -- Frame valid, slots 1,2 and 4 valid, read status.
                                CODEC_BUFFER_OUT(255 downto 200) <= x"D801_A6000_00000";
                            when 2 => -- Frame valid, slots 1 to 4 valid, set master volume.
                                CODEC_BUFFER_OUT(255 downto 220) <= x"F801_02000";
                                CODEC_BUFFER_OUT(219 downto 200) <= "00" & ATTENUATION(7 downto 4) & x"0" & ATTENUATION(3 downto 0) & "000000";
                            when 3 => -- Frame valid, slots 1 to 4 valid, set ADC gain.
                                CODEC_BUFFER_OUT(255 downto 220) <= x"F801_1C000";
                                CODEC_BUFFER_OUT(219 downto 200) <=  x"0" & GAIN(7 downto 4) & x"0" & GAIN(3 downto 0) & x"0";
                            when 4 => -- Frame valid, slots 1 to 4 valid, select ADC input.
                                CODEC_BUFFER_OUT(255 downto 220) <= x"F801_1A000";
                                CODEC_BUFFER_OUT(219 downto 200) <= "00000" & ADC_SRC(1) & "0000000" & ADC_SRC(0) & "000000";
                            when others => 
                                CODEC_BUFFER_OUT(255 downto 200) <= x"9801_00000_00000"; -- Frame valid, slots 3 and 4 valid.
                        end case;
                    else -- Send enhanced control data.
                        CODEC_BUFFER_OUT(255 downto 200) <= CODEC_TAG & CODEC_ADDRESS & x"0" & CODEC_COMMAND & x"0";
                    end if;

                    if WCNT = WORDCOUNT then
                        case SMODE_SEL is
                            when "10" => -- 8 bit mono.
                                CODEC_BUFFER_OUT(199 downto 160) <= SHIFT_OUT(15 downto 8) & x"000" & SHIFT_OUT(15 downto 8) & x"000";
                            when "01" => -- 16 bitr stereo.
                                CODEC_BUFFER_OUT(199 downto 180) <= SHIFT_OUT & x"0"; -- Left data.
                            when "11" => -- 16 bit mono.
                                CODEC_BUFFER_OUT(199 downto 160) <= SHIFT_OUT & x"0" & SHIFT_OUT & x"0";
                            when others => -- 8 bit stereo.
                                CODEC_BUFFER_OUT(199 downto 160) <= SHIFT_OUT(15 downto 8) & x"000" & SHIFT_OUT(7 downto 0) & x"000";
                        end case;
                        SHIFT_IN := CODEC_BUFFER_IN(199 downto 184);   
                    elsif WCNT = WORDCOUNT + 1 then
                        case SMODE_SEL is
                            when "10" => -- 8 bit mono.
                                CODEC_BUFFER_OUT(199 downto 160) <= SHIFT_OUT(15 downto 8) & x"000" & SHIFT_OUT(15 downto 8) & x"000";
                            when "01" => -- 16 bit stereo.
                                CODEC_BUFFER_OUT(179 downto 160) <= SHIFT_OUT & x"0"; -- Right data.
                            when "11" => -- 16 bit mono.
                                CODEC_BUFFER_OUT(199 downto 160) <= SHIFT_OUT & x"0" & SHIFT_OUT & x"0";
                            when others => -- 8 bit stereo.
                                CODEC_BUFFER_OUT(199 downto 160) <= SHIFT_OUT(15 downto 8) & x"000" & SHIFT_OUT(7 downto 0) & x"000";
                        end case;
                        SHIFT_IN := CODEC_BUFFER_IN(179 downto 164);   
                    end if;
                when others =>
                    if DAC_SRC = "00" then
                        SHIFT_OUT := SHIFT_OUT(14 downto 0) & '0';
                    elsif DAC_SRC = "01" then
                        SHIFT_OUT := SHIFT_OUT(14 downto 0) & AD_DATA;
                    elsif DAC_SRC = "10" then
                        case CROSSBAR_DEST(14 downto 13) is
                            when "11" => SHIFT_OUT := SHIFT_OUT(14 downto 0) & AD_DATA;
                            when "10" => SHIFT_OUT := SHIFT_OUT(14 downto 0) & RECDATA;
                            when "01" => SHIFT_OUT := SHIFT_OUT(14 downto 0) & DSP_STD;
                            when others => SHIFT_OUT := SHIFT_OUT(14 downto 0) & PCM_STD;
                        end case;
                    else
                        case CROSSBAR_DEST(14 downto 13) is
                            when "11" => SHIFT_OUT := SHIFT_OUT(14 downto 0) & AD_DATA;
                            when "10" => SHIFT_OUT := SHIFT_OUT(14 downto 0) & (RECDATA xor AD_DATA);
                            when "01" => SHIFT_OUT := SHIFT_OUT(14 downto 0) & (DSP_STD xor AD_DATA);
                            when others => SHIFT_OUT := SHIFT_OUT(14 downto 0) & (PCM_STD xor AD_DATA);
                        end case;
                    end if;
                    SHIFT_IN := SHIFT_IN(14 downto 0) & '0';
                    AD_DATA <= SHIFT_IN(15);
            end case;
        end if;
    end process BUFFERS;

    CODEC_RECEIEVE: process
    -- This is the input section from the codec. The data is sampled
    -- on the negative clock edge.
    variable SHIFTREG_IN  : std_logic_vector(255 downto 160);
    variable BITCNT       : std_logic_vector(7 downto 0);
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        if RESET = '1' then
            SHIFTREG_IN := (others => '0');
            BITCNT := x"00";
        elsif CODEC_BIT_STRB_N = '1' and F00 = '1' then
            SHIFTREG_IN := SHIFTREG_IN(254 downto 160) & ASDOUT; -- MSB first.
            CODEC_BUFFER_IN <= SHIFTREG_IN;
            BITCNT := x"00";
        elsif CODEC_BIT_STRB_N = '1' and BITCNT < x"38" then -- Shift in 56 bits.
            BITCNT := BITCNT - '1';
            SHIFTREG_IN := SHIFTREG_IN(254 downto 160) & ASDOUT; -- MSB first.
        end if;
    end process CODEC_RECEIEVE;    

    STATUS_FLAGS: process
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        if CODEC_BUFFER_IN(255 downto 253) = "111" and CODEC_BUFFER_IN(238 downto 232) = "0100110" then
            DAC_OV <= not CODEC_BUFFER_IN(205);
            ADC_OV <= not CODEC_BUFFER_IN(204);
        end if;
    end process STATUS_FLAGS;

    CODEC_TRANSMIT: process
    variable SHIFTREG_OUT : std_logic_vector(255 downto 160);
    variable BITCNT       : std_logic_vector(7 downto 0);
    variable FRAMECNT     : integer range 0 to 4;
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        if CODEC_BIT_STRB_P = '1' and RESET = '1' then
            FRAMECNT := 0;
            SHIFTREG_OUT := (others => '0');
            BITCNT := x"00";
        elsif CODEC_BIT_STRB_P = '1' then
            BITCNT := BITCNT + '1';

            if BITCNT = x"00" and CODEC_BUFFER_IN(255) = '1' and FRAMECNT < 4 then
                -- Important! Right after startup, the power down / controller status register (26h) must be checked. bits D3 ... D0 must be set
                -- to indicate a ready analog section. Refer to the CS4299 datasheet for more information. If the codec is not ready, it will not
                -- accept any settings to the respective registers like volume or mute. 
                if FRAMECNT = 1 and CODEC_BUFFER_IN(254 downto 253) = "11" and CODEC_BUFFER_IN(238 downto 232) = "0100110" and CODEC_BUFFER_IN(207 downto 204) = x"F" then
                    FRAMECNT := FRAMECNT + 1; -- Analog ... ready
                elsif FRAMECNT /= 1 and FRAMECNT < 4 then
                    FRAMECNT := FRAMECNT + 1;
                end if;
            elsif BITCNT = x"00" and CODEC_BUFFER_IN(255) = '0' then
                FRAMECNT := 0; --Loss of SYNC.
            end if;

            if BITCNT = x"FF" then -- One Frame is 256 bit.
                F00 <= '1'; -- This is the internal SYNC flag (see CODEC_RECEIEVE).
            else
                F00 <= '0';
            end if;

            if BITCNT = x"FF" then
                ASSYNC <= '1'; -- SYNC is asserted one bit clock before sampling data.
            elsif BITCNT = x"0F" then
                ASSYNC <= '0';
            end if;

            if BITCNT = x"00" then
                case FRAMECNT is
                    when 0 => null;
                    when 1 => SHIFTREG_OUT := x"E000_A6000_00000_00000_00000"; -- Read controller status.
                    when 2 => SHIFTREG_OUT := x"E000_02000_00000_00000_00000"; -- Write master volume.
                    when 3 => SHIFTREG_OUT := x"E000_16000_08080_00000_00000"; -- Write aux volume.
                    when 4 => SHIFTREG_OUT := CODEC_BUFFER_OUT; -- Data, MSB first.
                end case;
            else
                SHIFTREG_OUT := SHIFTREG_OUT(254 downto 160) & '0'; -- MSB first.
            end if;
        end if;
        ASDIN <= SHIFTREG_OUT(255);
    end process CODEC_TRANSMIT;

    -------------------------------------------------------------------------------------------------------------
    --                                         PCM record section.                                             --
    -------------------------------------------------------------------------------------------------------------
    PCMREC_STRB_SEL  <= M32 when CROSSBAR_DEST(2 downto 1) = "00" and CROSSBAR_SOURCE(2 downto 1) = "10" else -- Source = PCM playback.
                        EXT when CROSSBAR_DEST(2 downto 1) = "00" and CROSSBAR_SOURCE(2 downto 1) = "01" else -- Source = PCM playback.
                        SM when CROSSBAR_DEST(2 downto 1) = "00" and CROSSBAR_SOURCE(2 downto 1) = "00" else -- Source = PCM playback.
                        M32 when CROSSBAR_DEST(2 downto 1) = "01" and CROSSBAR_SOURCE(6 downto 5) = "10" else -- Source = DSP transmit.
                        EXT when CROSSBAR_DEST(2 downto 1) = "01" and CROSSBAR_SOURCE(6 downto 5) = "01" else -- Source = DSP transmit.
                        SM when CROSSBAR_DEST(2 downto 1) = "01" and CROSSBAR_SOURCE(6 downto 5) = "00" else -- Source = DSP transmit.
                        M32 when CROSSBAR_DEST(2 downto 1) = "10" and CROSSBAR_SOURCE(10 downto 9) = "10" else -- Source = External input.
                        EXT when CROSSBAR_DEST(2 downto 1) = "10" and CROSSBAR_SOURCE(10 downto 9) = "01" else -- Source = External input.
                        SM when CROSSBAR_DEST(2 downto 1) = "10" and CROSSBAR_SOURCE(10 downto 9) = "00" else -- Source = External input.
                        M32 when CROSSBAR_DEST(2 downto 1) = "11" and CROSSBAR_SOURCE(14 downto 13) = "10" else -- Source = AD converter.
                        EXT when CROSSBAR_DEST(2 downto 1) = "11" and CROSSBAR_SOURCE(14 downto 13) = "01" else -- Source = AD converter.
                        SM when CROSSBAR_DEST(2 downto 1) = "11" and CROSSBAR_SOURCE(14 downto 13) = "00" else OFF; -- Source = AD converter.

    with PCMREC_STRB_SEL select
        PCMREC_BIT_STRB <= BIT_STRB_32M_N when M32,
                           BIT_STRB_SM_N when SM,
                           BIT_STRB_EXT_N when EXT,
                           '0' when others;

    with PCMREC_STRB_SEL select
        PCMREC_SAMPLE_STRB <= SAMPLE_STRB_32M when M32,
                              SAMPLE_STRB_SM when SM,
                              SAMPLE_STRB_EXT when EXT,
                              '0' when others;

    PCMREC_CLK_EN <= '0' when CROSSBAR_DEST(2 downto 1) = "10" and CROSSBAR_SOURCE(8) = '0' and RECSYNC_IN = '0' else -- Source is external in handshaking mode.
                     '0' when CROSSBAR_DEST(2 downto 1) = "01" and CROSSBAR_SOURCE(4) = '0' and DSP_SC1_IN = '0' else -- Source is the DSP in handshaking mode.
                     '0' when CROSSBAR_DEST(2 downto 1) = "00" and CROSSBAR_SOURCE(0) = '0' and PCMPLY_SYNC = '0' else '1'; -- Source is DMA playback in handshaking mode.

    PCMREC_SYNCOUT: process
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        if PCMREC_BIT_STRB = '1' and CAPTURE_FIFO_FULL = '1' then
            PCMREC_SYNC <= '0';
        elsif PCMREC_BIT_STRB = '1' then
            PCMREC_SYNC <= '1'; -- Ready.
        end if;
    end process PCMREC_SYNCOUT;

    PCMREC_DATA_IN: process
    variable BITCNT             : integer range 0 to 16;
    variable WORDCNT            : integer range 0 to 8;
    variable WCNT               : integer range 0 to 8;
    variable SHIFTREG           : std_logic_vector(15 downto 0);
    variable INIT               : boolean;
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        
        case REC_TRACK_SEL is
            when "11" => WORDCNT := 8;
            when "10" => WORDCNT := 6;
            when "01" => WORDCNT := 4;
            when others => WORDCNT := 2;
        end case;

        if PCMREC_CLK_EN = '0' then
            null; -- Wait.
        elsif PCMREC_SAMPLE_STRB = '1' and INIT = false then
            BITCNT := 0;
            WORDCNT := 0;
            INIT := true;
        elsif PCMREC_BIT_STRB = '1' and INIT = true then
            if BITCNT < 16 then
                BITCNT := BITCNT + 1;
            end if;
            case BITCNT is
                when 16 =>
                    if CAPTURE_DATACK = '1' then
                        CAPTURE_DATAREQ <= '0';
                        BITCNT := 0;
                            if WCNT < 8 then
                                WCNT := WCNT + 1;
                            end if;
                        PCM_DATA_OUT <= SHIFTREG;
                        if WCNT = WORDCNT then
                            INIT := false;
                        end if;
                    else
                        CAPTURE_DATAREQ <= '1';
                    end if;
                when others =>
                    case CROSSBAR_DEST(2 downto 1) is
                        when "11" => SHIFTREG := SHIFTREG(14 downto 0) & AD_DATA;
                        when "10" => SHIFTREG := SHIFTREG(14 downto 0) & RECDATA;
                        when "01" => SHIFTREG := SHIFTREG(14 downto 0) & DSP_STD;
                        when others => SHIFTREG := SHIFTREG(14 downto 0) & PCM_STD;
                    end case;
            end case;
        end if;
    end process PCMREC_DATA_IN;
    
    -------------------------------------------------------------------------------------------------------------
    --                                         PCM playback section.                                           --
    -------------------------------------------------------------------------------------------------------------
    with CROSSBAR_SOURCE(2 downto 1) select
        PCMPLY_BIT_STRB <= '0' when "11",
                           BIT_STRB_32M_P when "10",
                           BIT_STRB_EXT_P when "01",
                           BIT_STRB_SM_P when others;

    with CROSSBAR_SOURCE(2 downto 1) select
        PCMPLY_SAMPLE_STRB <= '0' when "11",
                              SAMPLE_STRB_32M when "10",
                              SAMPLE_STRB_EXT when "01",
                              SAMPLE_STRB_SM when others;

    PCMPLY_CLK_EN <= '0' when CROSSBAR_DEST(10 downto 8) = "000" and PLYSYNC_IN = '0' else -- Destination is external in handshaking mode.
                     '0' when CROSSBAR_DEST(6 downto 4) = "000" and DSP_SC2_IN = '0' else -- Destination is the DSP in handshaking mode.
                     '0' when CROSSBAR_DEST(2 downto 0) = "000" and PCMREC_SYNC = '0' else '1'; -- Destination is PCM capture in handshaking mode.

    PCMPLY_SYNCOUT: process
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        if PCMPLY_BIT_STRB = '1' and REPLAY_FIFO_EMPTY = '1' then
            PCMPLY_SYNC <= '0';
        elsif PCMPLY_BIT_STRB = '1' then
            PCMPLY_SYNC <= '1'; -- Ready.
        end if;
    end process PCMPLY_SYNCOUT;

    PCMPLY_DATA_OUT: process
    variable BITCNT             : integer range 0 to 16;
    variable FRAMECNT           : integer range 1 to 4;
    variable WORDCNT            : integer range 2 to 8;
    variable WCNT               : integer range 0 to 8;
    variable FCNT               : integer range 0 to 4;
    variable SHIFTREG           : std_logic_vector(15 downto 0);
    variable INIT               : boolean;
    begin
        wait until CLK_32 = '1' and CLK_32' event;
        
        case SMODE_SEL is
            when "10" => FRAMECNT := 4; -- 8 bit mono, 4 frames the same data.
            when "01" => FRAMECNT := 1; -- 16 bit stereo, 1 frame the same data.
            when "11" => FRAMECNT := 2; -- 16 bit mono, 2 frame the same data..
            when others => FRAMECNT := 2; -- 8 bit stereo, 2 frame the same data..
        end case;

        case TRACK_PLAY is
            when "11" => WORDCNT := 8;
            when "10" => WORDCNT := 6;
            when "01" => WORDCNT := 4;
            when others => WORDCNT := 2;
        end case;

        if PCMPLY_CLK_EN = '0' then
            null; -- Wait.
        elsif PCMPLY_SAMPLE_STRB = '1' and INIT = false then
            BITCNT := 0;
            WCNT := 0;
            FCNT := 0;
            REPLAY_DATAREQ <= '1';
            if REPLAY_DATACK = '1' then
                SHIFTREG := PCM_DATA_IN;
                REPLAY_DATAREQ <= '0';
                INIT := true;
            else
                INIT := false;
            end if;
        elsif PCMPLY_BIT_STRB = '1' and INIT = true then
            if BITCNT < 16 then
                BITCNT := BITCNT + 1;
            end if;
            case BITCNT is
                when 16 =>
                    if FCNT < 4 then
                        FCNT := FCNT + 1;
                    end if;
                    if REPLAY_DATACK = '1' and FCNT = FRAMECNT then
                        BITCNT := 0;
                        FCNT := 0;
                        REPLAY_DATAREQ <= '0';
                        SHIFTREG := PCM_DATA_IN;
                        if WCNT < 8 then
                            WCNT := WCNT + 1;
                        end if;
                        if WCNT = WORDCNT then
                            INIT := false;
                        end if;
                    else
                        REPLAY_DATAREQ <= '1';
                    end if;
                when others =>
                    SHIFTREG := SHIFTREG(14 downto 0) & SHIFTREG(15); -- Refill for duplicate words.
            end case;
        end if;
        PCM_STD <= SHIFTREG(15); -- MSB first.
    end process PCMPLY_DATA_OUT;
end architecture BEHAVIOR;
