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
---- Copyright © 2012... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K22A  20221224 WF
--   CROSSBAR_SRC and CROSSBAR_DEST have now WORD and BYTE access.
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity FDMA_SOUND_REGs is
    port(
        CLK                 : in std_logic;
        RESET               : in std_logic;

        FC                  : in std_logic_vector(2 downto 0); -- Processor function codes.
        ADR_IN              : in std_logic_vector(31 downto 1); --Adress inputs.
        LDSn                : in std_logic; -- Lower data strobe; not used so far.
        UDSn                : in std_logic; -- Upper data strobe.
        ASn                 : in std_logic; -- Adress strobe signal indicates valid adress.
        RWn                 : in std_logic; -- Read write control.

        DATA_IN             : in std_logic_vector (15 downto 0);
        DATA_OUT            : out std_logic_vector (15 downto 0);
        DATA_EN             : out std_logic;
        DTACKn              : out std_logic;

        PCM_REPLAY          : out std_logic;
        PCM_CAPTURE         : out std_logic;
        
        RP_FIFO_EMPTY       : in std_logic;
        CA_FIFO_FULL        : in std_logic;
        RP_FRAME_CNT_EN     : in std_logic;
        CA_FRAME_CNT_EN     : in std_logic;
        RP_DMA_ADR          : out std_logic_vector(31 downto 1);
        CA_DMA_ADR          : out std_logic_vector(31 downto 1);

        -- Configuration signals:
        CROSSBAR_SOURCE_OUT     : out std_logic_vector(15 downto 0);
        CROSSBAR_DEST_OUT       : out std_logic_vector(15 downto 0);
        DAC_TRACK_SEL           : out std_logic_vector(1 downto 0);
        TRACK_PLAY              : out std_logic_vector(1 downto 0);
        SMODE_FREQ              : out std_logic_vector(1 downto 0);
        SMODE_SEL               : out std_logic_vector(1 downto 0);
        FREQ_DIV_EXT_OUT        : out std_logic_vector(3 downto 0);
        FREQ_DIV_INT_OUT        : out std_logic_vector(3 downto 0);
        REC_TRACK_SEL_OUT       : out std_logic_vector(1 downto 0);
        DAC_SRC                 : out std_logic_vector(1 downto 0);
        ADC_SRC                 : out std_logic_vector(1 downto 0);
        GAIN                    : out std_logic_vector(7 downto 0);
        ATTENUATION             : out std_logic_vector(7 downto 0);
        DAC_OV                  : in std_logic; -- Overflow.
        ADC_OV                  : in std_logic; -- Overflow.       
        CODEC_TAG               : out std_logic_vector(15 downto 0);
        CODEC_ADDRESS           : out std_logic_vector(15 downto 0);
        CODEC_COMMAND           : out std_logic_vector(15 downto 0);
        CODEC_FMODEn            : out std_logic; -- ´'0' = Falcon compatible.

        -- Interrupts:
        SCNT                    : out std_logic; -- Timer A interrupt of the multi function port (MFP).
        SINT                    : out std_logic -- IO7 interrupt of the multi function port (MFP).
    );
end FDMA_SOUND_REGs;

architecture BEHAVIOR of FDMA_SOUND_REGs is
signal ADR_I                    : std_logic_vector(31 downto 0);
signal SU                       : boolean;
signal DMA_CTRL_RS              : std_logic;
signal FRAME_START_EXT_RS       : std_logic;
signal FRAME_START_HI_RS        : std_logic;
signal FRAME_START_MID_RS       : std_logic;
signal FRAME_START_LOW_RS       : std_logic;
signal FRAME_ADR_EXT_RS         : std_logic;
signal FRAME_ADR_HI_RS          : std_logic;
signal FRAME_ADR_MID_RS         : std_logic;
signal FRAME_ADR_LOW_RS         : std_logic;
signal FRAME_END_EXT_RS         : std_logic;
signal FRAME_END_HI_RS          : std_logic;
signal FRAME_END_MID_RS         : std_logic;
signal FRAME_END_LOW_RS         : std_logic;
signal DMA_CONTROL              : std_logic_vector(7 downto 0);
signal RP_FRAME_START           : std_logic_vector(31 downto 0); -- Replay.
signal RP_FRAME_START_BUFFER    : std_logic_vector(31 downto 0);
signal RP_FRAME_ADR             : std_logic_vector(31 downto 0);
signal RP_FRAME_END             : std_logic_vector(31 downto 0);
signal RP_FRAME_END_BUFFER      : std_logic_vector(31 downto 0);
signal CA_FRAME_START           : std_logic_vector(31 downto 0); -- Record.
signal CA_FRAME_START_BUFFER    : std_logic_vector(31 downto 0);
signal CA_FRAME_ADR             : std_logic_vector(31 downto 0);
signal CA_FRAME_END             : std_logic_vector(31 downto 0);
signal CA_FRAME_END_BUFFER      : std_logic_vector(31 downto 0);
signal BUFF_INT                 : std_logic_vector(7 downto 0);
signal CROSSBAR_SRC             : std_logic_vector(15 downto 0);
signal CROSSBAR_DEST            : std_logic_vector(15 downto 0);
signal TRACK_CTRL               : std_logic_vector(7 downto 0);
signal SMODE_CTRL               : std_logic_vector(7 downto 0);
signal FREQ_DIV_EXT             : std_logic_vector(3 downto 0);
signal FREQ_DIV_INT             : std_logic_vector(3 downto 0);
signal REC_TRACK_SEL            : std_logic_vector(1 downto 0);
signal CODEC_DAC_SEL            : std_logic_vector(1 downto 0);
signal CODEC_ADC_SEL            : std_logic_vector(1 downto 0);
signal CODEC_GAIN               : std_logic_vector(7 downto 0);
signal CODEC_ATTENUATION        : std_logic_vector(7 downto 0);
signal CODEC_STATUS             : std_logic_vector(1 downto 0);
signal CODEC_BUFFER             : std_logic_vector(255 downto 200);
signal BUFF_INT_RS              : std_logic;
signal TRACK_CTRL_RS            : std_logic;
signal SMODE_CTRL_RS            : std_logic;
signal CROSSBAR_SRC_RS          : std_logic;
signal CROSSBAR_DEST_RS         : std_logic;
signal REC_TRACK_SEL_RS         : std_logic;
signal CODEC_DAC_SEL_RS         : std_logic;
signal CODEC_ADC_SEL_RS         : std_logic;
signal CODEC_GAIN_RS            : std_logic;
signal CODEC_ATTENUATION_RS     : std_logic;
signal CODEC_STATUS_RS          : std_logic;
signal FREQ_DIV_EXT_RS          : std_logic;
signal FREQ_DIV_INT_RS          : std_logic;
signal A4299_RS                 : std_logic;
signal RP_ON                    : boolean;
signal CA_ON                    : boolean;
signal RP_FRAME_REPEAT          : boolean;
signal CA_FRAME_REPEAT          : boolean;
signal REPLAY_INT               : std_logic;
signal CAPTURE_INT              : std_logic;
begin
    ADR_I <= ADR_IN & '0';
    SU <= true when FC = "101" or FC = "110" else false; -- Superuser mode.

    BUFF_INT_RS <= '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8900" and RWn = '0' and SU = true else 
                   '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8900" and RWn = '1' else '0'; -- x"FFFF8900".

    DMA_CTRL_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8900" and RWn = '0' and SU = true else 
                   '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8900" and RWn = '1' else '0'; -- x"FFFF8901".

    FRAME_START_EXT_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8914" and RWn = '0' and SU = true else 
                                '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8914" and RWn = '1' else '0'; -- x"FFFF8915".
    FRAME_START_HI_RS <=  '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8902" and RWn = '0' and SU = true else 
                                '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8902" and RWn = '1' else '0'; -- x"FFFF8903".
    FRAME_START_MID_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8904" and RWn = '0' and SU = true else 
                                '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8904" and RWn = '1' else '0'; -- x"FFFF8905".
    FRAME_START_LOW_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8906" and RWn = '0' and SU = true else 
                                '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8906" and RWn = '1' else '0'; -- x"FFFF8907".

    FRAME_ADR_EXT_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8916" and RWn = '0' and SU = true else 
                              '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8916" and RWn = '1' else '0'; -- x"FFFF8917".
    FRAME_ADR_HI_RS <=  '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8908" and RWn = '0' and SU = true else 
                              '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8908" and RWn = '1' else '0'; -- x"FFFF8909".
    FRAME_ADR_MID_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF890A" and RWn = '0' and SU = true else 
                              '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF890A" and RWn = '1' else '0'; -- x"FFFF890B".
    FRAME_ADR_LOW_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF890C" and RWn = '0' and SU = true else 
                              '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF890C" and RWn = '1' else '0'; -- x"FFFF890D".

    FRAME_END_EXT_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8918" and RWn = '0' and SU = true else 
                              '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8918" and RWn = '1' else '0'; -- x"FFFF8919".
    FRAME_END_HI_RS <=  '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF890E" and RWn = '0' and SU = true else 
                              '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF890E" and RWn = '1' else '0'; -- x"FFFF890F".
    FRAME_END_MID_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8910" and RWn = '0' and SU = true else 
                              '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8910" and RWn = '1' else '0'; -- x"FFFF8911".
    FRAME_END_LOW_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8912" and RWn = '0' and SU = true else 
                              '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8912" and RWn = '1' else '0'; -- x"FFFF8913".

    TRACK_CTRL_RS <= '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8920" and RWn = '0' and SU = true else 
                     '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8920" and RWn = '1' else '0'; -- x"FFFF8920".

    SMODE_CTRL_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8920" and RWn = '0' and SU = true else 
                     '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8920" and RWn = '1' else '0'; -- x"FFFF8921".

    CROSSBAR_SRC_RS <= '1' when ASn = '0' and ADR_I = x"FFFF8930" and RWn = '0' and SU = true else 
                       '1' when ASn = '0' and ADR_I = x"FFFF8930" and RWn = '1' else '0'; -- x"FFFF8930".

    CROSSBAR_DEST_RS <= '1' when ASn = '0' and ADR_I = x"FFFF8932" and RWn = '0' and SU = true else 
                        '1' when ASn = '0' and ADR_I = x"FFFF8932" and RWn = '1' else '0'; -- x"FFFF8932".

    FREQ_DIV_EXT_RS <= '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8934" and RWn = '0' and SU = true else 
                       '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8934" and RWn = '1' else '0'; -- x"FFFF8934".

    FREQ_DIV_INT_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8934" and RWn = '0' and SU = true else 
                       '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8934" and RWn = '1' else '0'; -- x"FFFF8935".

    REC_TRACK_SEL_RS <= '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8936" and RWn = '0' and SU = true else 
                        '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8936" and RWn = '1' else '0'; -- x"FFFF8936".

    CODEC_DAC_SEL_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8936" and RWn = '0' and SU = true else 
                        '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8936" and RWn = '1' else '0'; -- x"FFFF8937".

    CODEC_ADC_SEL_RS <= '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8938" and RWn = '0' and SU = true else 
                        '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8938" and RWn = '1' else '0'; -- x"FFFF8938".

    CODEC_GAIN_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8938" and RWn = '0' and SU = true else 
                     '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8938" and RWn = '1' else '0'; -- x"FFFF8939".

    CODEC_ATTENUATION_RS <= '1' when ASn = '0' and UDSn = '0' and LDSn = '0' and ADR_I = x"FFFF893A" and RWn = '0' and SU = true else 
                            '1' when ASn = '0' and UDSn = '0' and LDSn = '0' and ADR_I = x"FFFF893A" and RWn = '1' else '0'; -- x"FFFF893B".

    CODEC_STATUS_RS <= '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF893C" and RWn = '0' and SU = true else 
                       '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF893C" and RWn = '1' else '0'; -- x"FFFF893D".

    A4299_RS <= '1' when ASn = '0' and UDSn = '0' and LDSn = '0' and ADR_I >= x"FFFF8820" and ADR_I < x"FFFF8832" and RWn = '0' and SU = true else
                '1' when ASn = '0' and UDSn = '0' and LDSn = '0' and ADR_I >= x"FFFF8820" and ADR_I < x"FFFF8832" and RWn = '1' else '0';
    
    CONTROLS: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            CODEC_DAC_SEL <= "00";
            CODEC_ADC_SEL <= "00";
            CODEC_GAIN <= x"00";
            CODEC_ATTENUATION <= x"00";
            CODEC_STATUS <= "00";
        elsif CODEC_DAC_SEL_RS = '1' and RWn = '0' then
            CODEC_DAC_SEL <= DATA_IN(1 downto 0);
        elsif CODEC_ADC_SEL_RS = '1' and RWn = '0' then
            CODEC_ADC_SEL <= DATA_IN(8 downto 7);
        elsif CODEC_GAIN_RS = '1' and RWn = '0' then
            CODEC_GAIN <= DATA_IN(7 downto 0);
        elsif CODEC_ATTENUATION_RS = '1' and RWn = '0' then
            CODEC_ATTENUATION <= DATA_IN(15 downto 8);
        elsif CODEC_STATUS_RS = '1' and RWn = '0' then
            CODEC_STATUS <= "00"; -- Clear by writing.
        elsif ADC_OV = '1' and DAC_OV = '1' then
            CODEC_STATUS <= "11";
        elsif ADC_OV = '1' then
            CODEC_STATUS <= "10";
        elsif DAC_OV = '1' then
            CODEC_STATUS <= "01";
        end if;
    end process CONTROLS;

    CODEC: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            BUFF_INT <= x"00";
            CROSSBAR_SRC <= x"0000";
            CROSSBAR_DEST <= x"0000";
            TRACK_CTRL <= x"00";
            SMODE_CTRL <= x"00";
            FREQ_DIV_EXT <= x"0";
            FREQ_DIV_INT <= x"0";
            REC_TRACK_SEL <= "00";
            CODEC_BUFFER <= (others => '0');
        elsif BUFF_INT_RS = '1' and RWn = '0' then
            BUFF_INT <= DATA_IN(15 downto 8); -- Even address.
        elsif CROSSBAR_SRC_RS = '1' and RWn = '0' then
            if UDSn = '0' then
                CROSSBAR_SRC(15 downto 8) <= DATA_IN(15 downto 8);
            end if;
            if LDSn = '0' then
                CROSSBAR_SRC(7 downto 0) <= DATA_IN(7 downto 0);
            end if;
        elsif CROSSBAR_DEST_RS = '1' and RWn = '0' then
            if UDSn = '0' then
                CROSSBAR_DEST(15 downto 8) <= DATA_IN(15 downto 8);
            end if;
            if LDSn = '0' then
                CROSSBAR_DEST(7 downto 0) <= DATA_IN(7 downto 0);
            end if;
        elsif TRACK_CTRL_RS = '1' and RWn = '0' then
            TRACK_CTRL <= DATA_IN(15 downto 8);
        elsif SMODE_CTRL_RS = '1' and RWn = '0' then
            SMODE_CTRL <= DATA_IN(7 downto 0); -- Odd address.
        elsif FREQ_DIV_EXT_RS = '1' and RWn = '0' then
            FREQ_DIV_EXT <= DATA_IN(11 downto 8);
        elsif FREQ_DIV_INT_RS = '1' and RWn = '0' then
            FREQ_DIV_INT <= DATA_IN(3 downto 0);
        elsif REC_TRACK_SEL_RS = '1' and RWn = '0' then
            REC_TRACK_SEL <= DATA_IN(9 downto 8);
        elsif A4299_RS = '1' and RWn = '0' then
            case ADR_I(7 downto 0) is
                when x"20" => CODEC_BUFFER(255 downto 240) <= DATA_IN;               -- TAG slot.
                when x"22" => CODEC_BUFFER(239 downto 224) <= DATA_IN;               -- Command address slot high.
                when x"24" => CODEC_BUFFER(223 downto 220) <= DATA_IN(15 downto 12); -- Command address slot low.
                when x"26" => CODEC_BUFFER(219 downto 204) <= DATA_IN;               -- Command data slot high.
                when x"28" => CODEC_BUFFER(203 downto 200) <= DATA_IN(15 downto 12); -- Command data slot low.
                when others => null;
            end case;
        end if;
    end process CODEC;

    DMA_CONTROL_REG: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            DMA_CONTROL <= (others => '0');
        -- Write to registers; FRAME_ADR is read only.
        elsif DMA_CTRL_RS = '1' and RWn = '0' then
            DMA_CONTROL <= DATA_IN(7 downto 0);
        elsif RP_FRAME_ADR = RP_FRAME_END_BUFFER and RP_FRAME_CNT_EN = '1' and RP_FRAME_REPEAT = false and RP_FIFO_EMPTY = '1' then
            DMA_CONTROL(0) <= '0'; -- Switch off the DMA unit when ready.
        elsif CA_FRAME_ADR = CA_FRAME_END_BUFFER and CA_FRAME_CNT_EN = '1' and CA_FRAME_REPEAT = false and CA_FIFO_FULL = '1' then
            DMA_CONTROL(0) <= '0'; -- Switch off the DMA unit when ready.
        end if;
    end process DMA_CONTROL_REG;
    
    SOUND_REGS: process(CLK, RP_FRAME_ADR, CA_FRAME_ADR)
    begin
        if CLK = '1' and CLK' event then
            if RESET = '1' then
                RP_FRAME_START <= (others => '0');
                RP_FRAME_ADR <= (others => '0');
                RP_FRAME_END <= (others => '0');
                RP_FRAME_START_BUFFER <= (others => '0');
                RP_FRAME_END_BUFFER <= (others => '0');
                CA_FRAME_START <= (others => '0');
                CA_FRAME_ADR <= (others => '0');
                CA_FRAME_END <= (others => '0');
                CA_FRAME_START_BUFFER <= (others => '0');
                CA_FRAME_END_BUFFER <= (others => '0');
            elsif FRAME_START_EXT_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '0' then
                RP_FRAME_START(31 downto 24) <= DATA_IN(7 downto 0);
            elsif FRAME_START_HI_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '0' then
                RP_FRAME_START(23 downto 16) <= DATA_IN(7 downto 0);
            elsif FRAME_START_MID_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '0' then
                RP_FRAME_START(15 downto 8) <= DATA_IN(7 downto 0);
            elsif FRAME_START_LOW_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '0' then
                RP_FRAME_START(7 downto 0) <= DATA_IN(7 downto 0);
            elsif FRAME_END_EXT_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '0' then
                RP_FRAME_END(31 downto 24) <= DATA_IN(7 downto 0);
            elsif FRAME_END_HI_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '0' then
                RP_FRAME_END(23 downto 16) <= DATA_IN(7 downto 0);
            elsif FRAME_END_MID_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '0' then
                RP_FRAME_END(15 downto 8) <= DATA_IN(7 downto 0);
            elsif FRAME_END_LOW_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '0' then
                RP_FRAME_END(7 downto 0) <= DATA_IN(7 downto 0);
            end if;
            
            if FRAME_START_EXT_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '1' then
                CA_FRAME_START(31 downto 24) <= DATA_IN(7 downto 0);
            elsif FRAME_START_HI_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '1' then
                CA_FRAME_START(23 downto 16) <= DATA_IN(7 downto 0);
            elsif FRAME_START_MID_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '1' then
                CA_FRAME_START(15 downto 8) <= DATA_IN(7 downto 0);
            elsif FRAME_START_LOW_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '1' then
                CA_FRAME_START(7 downto 0) <= DATA_IN(7 downto 0);
            elsif FRAME_END_EXT_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '1' then
                CA_FRAME_END(31 downto 24) <= DATA_IN(7 downto 0);
            elsif FRAME_END_HI_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '1' then
                CA_FRAME_END(23 downto 16) <= DATA_IN(7 downto 0);
            elsif FRAME_END_MID_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '1' then
                CA_FRAME_END(15 downto 8) <= DATA_IN(7 downto 0);
            elsif FRAME_END_LOW_RS = '1' and RWn = '0' and DMA_CONTROL(7) = '1' then
                CA_FRAME_END(7 downto 0) <= DATA_IN(7 downto 0);
            end if;

            if RP_ON = false then -- Switched off.
                RP_FRAME_START_BUFFER <= RP_FRAME_START;
                RP_FRAME_END_BUFFER <= RP_FRAME_END;
                RP_FRAME_ADR <= RP_FRAME_START_BUFFER;
            elsif RP_FRAME_ADR < RP_FRAME_END_BUFFER and RP_FRAME_CNT_EN = '1' then
                RP_FRAME_ADR <= RP_FRAME_ADR + '1'; -- Count.
            elsif RP_FRAME_CNT_EN = '1' and RP_FRAME_REPEAT = true then -- Reload.
                RP_FRAME_START_BUFFER <= RP_FRAME_START;
                RP_FRAME_END_BUFFER <= RP_FRAME_END;
                RP_FRAME_ADR <= RP_FRAME_START_BUFFER;
            end if;

            if CA_ON = false then -- Switched off.
                CA_FRAME_START_BUFFER <= CA_FRAME_START;
                CA_FRAME_END_BUFFER <= CA_FRAME_END;
                CA_FRAME_ADR <= CA_FRAME_START_BUFFER;
            elsif CA_FRAME_ADR < CA_FRAME_END_BUFFER and CA_FRAME_CNT_EN = '1' then
                CA_FRAME_ADR <= CA_FRAME_ADR + '1'; -- Count.
            elsif CA_FRAME_CNT_EN = '1' and CA_FRAME_REPEAT = true then -- Reload.
                CA_FRAME_START_BUFFER <= CA_FRAME_START;
                CA_FRAME_END_BUFFER <= CA_FRAME_END;
                CA_FRAME_ADR <= CA_FRAME_START_BUFFER;
            end if;
        end if;
        RP_DMA_ADR <= RP_FRAME_ADR(31 downto 1);
        CA_DMA_ADR <= CA_FRAME_ADR(31 downto 1);
    end process SOUND_REGS;

    -- Read from registers, unused pins are read back as '0's.
    DATA_EN <= '1' when DMA_CTRL_RS = '1' and RWn = '1' else
               '1' when FRAME_START_EXT_RS = '1' and RWn = '1' else
               '1' when FRAME_START_HI_RS = '1' and RWn = '1' else
               '1' when FRAME_START_MID_RS = '1' and RWn = '1' else
               '1' when FRAME_START_LOW_RS = '1' and RWn = '1' else
               '1' when FRAME_ADR_EXT_RS = '1' and RWn = '1' else
               '1' when FRAME_ADR_HI_RS = '1' and RWn = '1' else
               '1' when FRAME_ADR_MID_RS = '1' and RWn = '1' else
               '1' when FRAME_ADR_LOW_RS = '1' and RWn = '1' else
               '1' when FRAME_END_EXT_RS = '1' and RWn = '1' else
               '1' when FRAME_END_HI_RS = '1' and RWn = '1' else
               '1' when FRAME_END_MID_RS = '1' and RWn = '1' else
               '1' when FRAME_END_LOW_RS = '1' and RWn = '1' else
               '1' when BUFF_INT_RS = '1' and RWn = '1' else
               '1' when CROSSBAR_SRC_RS = '1' and RWn = '1' else
               '1' when CROSSBAR_DEST_RS = '1' and RWn = '1' else
               '1' when TRACK_CTRL_RS = '1' and RWn = '1' else
               '1' when SMODE_CTRL_RS = '1' and RWn = '1' else
               '1' when FREQ_DIV_EXT_RS = '1' and RWn = '1' else
               '1' when FREQ_DIV_INT_RS = '1' and RWn = '1' else
               '1' when REC_TRACK_SEL_RS = '1' and RWn = '1' else
               '1' when CODEC_DAC_SEL_RS = '1' and RWn = '1' else
               '1' when CODEC_ADC_SEL_RS = '1' and RWn = '1' else
               '1' when CODEC_GAIN_RS = '1' and RWn = '1' else
               '1' when CODEC_ATTENUATION_RS = '1' and RWn = '1' else
               '1' when CODEC_STATUS_RS = '1' and RWn = '1' else
               '1' when A4299_RS = '1' else '0';

    DATA_OUT <= x"00" & DMA_CONTROL when DMA_CTRL_RS = '1' and RWn = '1' else
                x"00" & RP_FRAME_START(31 downto 24) when FRAME_START_EXT_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '0' else
                x"00" & RP_FRAME_START(23 downto 16) when FRAME_START_HI_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '0' else
                x"00" & RP_FRAME_START(15 downto 8) when FRAME_START_MID_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '0' else
                x"00" & RP_FRAME_START(7 downto 0) when FRAME_START_LOW_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '0' else
                x"00" & RP_FRAME_ADR(31 downto 24) when FRAME_ADR_EXT_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '0' else
                x"00" & RP_FRAME_ADR(23 downto 16) when FRAME_ADR_HI_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '0' else
                x"00" & RP_FRAME_ADR(15 downto 8) when FRAME_ADR_MID_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '0' else
                x"00" & RP_FRAME_ADR(7 downto 0) when FRAME_ADR_LOW_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '0' else
                x"00" & RP_FRAME_END(31 downto 24) when FRAME_END_EXT_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '0' else
                x"00" & RP_FRAME_END(23 downto 16) when FRAME_END_HI_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '0' else
                x"00" & RP_FRAME_END(15 downto 8) when FRAME_END_MID_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '0' else
                x"00" & RP_FRAME_END(7 downto 0) when FRAME_END_LOW_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '0' else
                x"00" & CA_FRAME_START(31 downto 24) when FRAME_START_EXT_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '1' else
                x"00" & CA_FRAME_START(23 downto 16) when FRAME_START_HI_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '1' else
                x"00" & CA_FRAME_START(15 downto 8) when FRAME_START_MID_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '1' else
                x"00" & CA_FRAME_START(7 downto 0) when FRAME_START_LOW_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '1' else
                x"00" & CA_FRAME_ADR(31 downto 24) when FRAME_ADR_EXT_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '1' else
                x"00" & CA_FRAME_ADR(23 downto 16) when FRAME_ADR_HI_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '1' else
                x"00" & CA_FRAME_ADR(15 downto 8) when FRAME_ADR_MID_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '1' else
                x"00" & CA_FRAME_ADR(7 downto 0) when FRAME_ADR_LOW_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '1' else
                x"00" & CA_FRAME_END(31 downto 24) when FRAME_END_EXT_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '1' else
                x"00" & CA_FRAME_END(23 downto 16) when FRAME_END_HI_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '1' else
                x"00" & CA_FRAME_END(15 downto 8) when FRAME_END_MID_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '1' else
                x"00" & CA_FRAME_END(7 downto 0) when FRAME_END_LOW_RS = '1' and RWn = '1' and DMA_CONTROL(7) = '1' else
                BUFF_INT & x"00" when BUFF_INT_RS = '1' and RWn = '1' else
                CROSSBAR_SRC when CROSSBAR_SRC_RS = '1' and RWn = '1' else
                CROSSBAR_DEST when CROSSBAR_DEST_RS = '1' and RWn = '1' else
                TRACK_CTRL & x"00" when TRACK_CTRL_RS = '1' and RWn = '1' else
                x"00" & SMODE_CTRL when SMODE_CTRL_RS = '1' and RWn = '1' else
                x"0" & FREQ_DIV_EXT & x"00" when FREQ_DIV_EXT_RS = '1' else
                x"000" & FREQ_DIV_INT when FREQ_DIV_INT_RS = '1' else
                "000000" & REC_TRACK_SEL & x"00" when REC_TRACK_SEL_RS = '1' else
                x"000" & "00" & CODEC_DAC_SEL when CODEC_DAC_SEL_RS = '1' else
                "000000" & CODEC_ADC_SEL & x"00" when CODEC_ADC_SEL_RS = '1' else
                x"00" & CODEC_GAIN when CODEC_GAIN_RS = '1' else
                CODEC_ATTENUATION & x"00" when CODEC_ATTENUATION_RS = '1' else
                "000000" & CODEC_STATUS & x"00" when CODEC_STATUS_RS = '1' else
                CODEC_BUFFER(255 downto 240) when ADR_I(7 downto 0) = x"20" and A4299_RS = '1' and RWn = '1' else                   -- TAG slot.
                CODEC_BUFFER(239 downto 224) when ADR_I(7 downto 0) = x"22" and A4299_RS = '1' and RWn = '1' else                   -- Status address slot high.
                CODEC_BUFFER(223 downto 220) & x"000" when ADR_I(7 downto 0) = x"24" and A4299_RS = '1' and RWn = '1' else          -- Status address slot low.
                CODEC_BUFFER(219 downto 204) when ADR_I(7 downto 0) = x"26" and A4299_RS = '1' and RWn = '1' else                   -- Status data slot high.
                CODEC_BUFFER(203 downto 200) & x"000" when ADR_I(7 downto 0) = x"28" and A4299_RS = '1' and RWn = '1' else x"0000"; -- Status data slot low.

    DTACKn <= '0' when DMA_CTRL_RS = '1' else
              '0' when FRAME_START_EXT_RS = '1' else
              '0' when FRAME_START_HI_RS = '1' else
              '0' when FRAME_START_MID_RS = '1' else
              '0' when FRAME_START_LOW_RS = '1' else
              '0' when FRAME_ADR_EXT_RS = '1' else
              '0' when FRAME_ADR_HI_RS = '1' else
              '0' when FRAME_ADR_MID_RS = '1' else
              '0' when FRAME_ADR_LOW_RS = '1' else
              '0' when FRAME_END_EXT_RS = '1' else
              '0' when FRAME_END_HI_RS = '1' else
              '0' when FRAME_END_MID_RS = '1' else
              '0' when FRAME_END_LOW_RS = '1' else
              '0' when BUFF_INT_RS = '1' else
              '0' when CROSSBAR_SRC_RS = '1' else
              '0' when CROSSBAR_DEST_RS = '1' else
              '0' when TRACK_CTRL_RS = '1' else
              '0' when SMODE_CTRL_RS = '1' else
              '0' when FREQ_DIV_EXT_RS = '1' else
              '0' when FREQ_DIV_INT_RS = '1' else
              '0' when REC_TRACK_SEL_RS = '1' else
              '0' when CODEC_DAC_SEL_RS = '1' else
              '0' when CODEC_ADC_SEL_RS = '1' else
              '0' when CODEC_GAIN_RS = '1' else
              '0' when CODEC_ATTENUATION_RS = '1' else
              '0' when CODEC_STATUS_RS = '1' else
              '0' when A4299_RS = '1' else '1';

    PCM_REPLAY <= '1' when RP_ON = true else '0';
    PCM_CAPTURE <= '1' when CA_ON = true else '0';
    RP_ON <= true when DMA_CONTROL(0) = '1' else false;
    CA_ON <= true when DMA_CONTROL(4) = '1' else false;
    RP_FRAME_REPEAT <= true when DMA_CONTROL(1) = '1' else false;
    CA_FRAME_REPEAT <= true when DMA_CONTROL(5) = '1' else false;

    CROSSBAR_SOURCE_OUT <= CROSSBAR_SRC;
    CROSSBAR_DEST_OUT <= CROSSBAR_DEST;
    DAC_TRACK_SEL <= TRACK_CTRL(5 downto 4);
    TRACK_PLAY <= TRACK_CTRL(1 downto 0);
    SMODE_SEL <= SMODE_CTRL(7 downto 6);
    SMODE_FREQ <= SMODE_CTRL(1 downto 0);
    FREQ_DIV_EXT_OUT <= FREQ_DIV_EXT;
    FREQ_DIV_INT_OUT <= FREQ_DIV_INT;
    REC_TRACK_SEL_OUT <= REC_TRACK_SEL;

    SINT <= REPLAY_INT when BUFF_INT(0) = '1' else
            CAPTURE_INT when BUFF_INT(1) = '1' else
            REPLAY_INT or CAPTURE_INT when BUFF_INT(1 downto 0) = "11" else '0';

    SCNT <= REPLAY_INT when BUFF_INT(2) = '1' else
            CAPTURE_INT when BUFF_INT(3) = '1' else
            REPLAY_INT or CAPTURE_INT when BUFF_INT(3 downto 2) = "11" else '0';
    
    DAC_SRC <= CODEC_DAC_SEL;
    ADC_SRC <= CODEC_ADC_SEL;
    GAIN <= CODEC_GAIN;
    ATTENUATION <= CODEC_ATTENUATION;

    CODEC_TAG <= CODEC_BUFFER(255 downto 240);
    CODEC_ADDRESS <= CODEC_BUFFER(239 downto 224);
    CODEC_COMMAND <= CODEC_BUFFER(219 downto 204);
    CODEC_FMODEn <= TRACK_CTRL(5);

    INTERRUPTS: process
    begin
        wait until CLK = '1' and CLK' event;
        if RP_ON = false then
            REPLAY_INT <= '1';
        elsif RP_FRAME_ADR = RP_FRAME_START_BUFFER then
            REPLAY_INT <= '0';
        elsif RP_FRAME_ADR = RP_FRAME_END_BUFFER then
            REPLAY_INT <= '1';
        end if;
        if CA_ON = false then
            CAPTURE_INT <= '1';
        elsif CA_FRAME_ADR = CA_FRAME_START_BUFFER then
            CAPTURE_INT <= '0';
        elsif CA_FRAME_ADR = CA_FRAME_END_BUFFER then
            CAPTURE_INT <= '1';
        end if;
    end process INTERRUPTS;
end architecture BEHAVIOR;
