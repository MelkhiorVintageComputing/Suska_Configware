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
----   This module provides the microwire interface of the Atari    ----
----   STE machines. It is an add on to the DMA coprocessor.        ----
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

entity FDMA_MICROWIRE is
    port(
        RESET           : in std_logic;
        CLK             : in std_logic; -- Use a 32MHz clock.
        
        FC              : in std_logic_vector(2 downto 0); -- Processor function codes.
        ADR             : in std_logic_vector(31 downto 1); --Adress inputs.
        LDSn            : in std_logic; -- Lower data strobe; not used so far.
        UDSn            : in std_logic; -- Upper data strobe.
        ASn             : in std_logic; -- Adress strobe signal indicates valid adress.
        RWn             : in std_logic; -- Read write control.

        DATA_IN         : in std_logic_vector(15 downto 0); -- Data.
        DATA_OUT        : out std_logic_vector(15 downto 0);
        DATA_EN         : out std_logic;
        DTACKn          : out std_logic;

        GPx_IN          : in std_logic_vector(2 downto 0);
        GPx_OUT         : out std_logic_vector(2 downto 0);
        GPx_EN          : out std_logic_vector(2 downto 0);

        UWC             : out std_logic; -- Microwire clock (1MHz).
        UWD             : out std_logic; -- Microwire data.
        UWEn            : buffer std_logic -- Microwire enable (low active).
    );
end FDMA_MICROWIRE;

architecture BEHAVIOUR of FDMA_MICROWIRE is
type MW_STATUSTYPE is (IDLE, RUN);
signal MW_STATUS        : MW_STATUSTYPE; -- Locks MW registers during shift operation.
signal MW_DATA          : std_logic_vector(15 downto 0);  -- Data register $FF8922.
signal MW_MASK          : std_logic_vector(15 downto 0);  -- Mask register $FF8924.
signal MWK_MASK         : std_logic;  -- Mask for the microwire clock.
signal SHIFTCLK         : std_logic;
signal SHIFT_STRB       : std_logic;
signal BITCNT           : std_logic_vector(4 downto 0);
signal MWK_I            : std_logic;
signal MWD_I            : std_logic;
signal MWE_In           : std_logic;
signal ADR_INT          : std_logic_vector(31 downto 0);
signal SU               : boolean;
signal MWD_RS           : std_logic;
signal MWK_RS           : std_logic;
signal GPx_EN_RS        : std_logic;
signal GPx_EN_REG       : std_logic_vector(3 downto 0);
signal GPx_DATA_RS      : std_logic;
signal GPx_DATA_REG     : std_logic_vector(2 downto 0);
begin
    ADR_INT <= ADR & '0';
    SU <= true when FC = "101" or FC = "110" else false; -- Superuser mode.
    MWD_RS <= '1' when ASn = '0' and UDSn = '0' and LDSn = '0' and ADR_INT = x"FFFF8922" and RWn = '0' and SU = true else
              '1' when ASn = '0' and UDSn = '0' and LDSn = '0' and ADR_INT = x"FFFF8922" and RWn = '1' else '0';
    MWK_RS <= '1' when ASn = '0' and UDSn = '0' and LDSn = '0' and ADR_INT = x"FFFF8924" and RWn = '0' and SU = true else
              '1' when ASn = '0' and UDSn = '0' and LDSn = '0' and ADR_INT = x"FFFF8924" and RWn = '1' else '0';

    GPx_EN_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_INT = x"FFFF8940" and RWn = '0' and SU = true else
                 '1' when ASn = '0' and LDSn = '0' and ADR_INT = x"FFFF8940" and RWn = '1' else '0';

    GPx_DATA_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_INT = x"FFFF8942" and RWn = '0' and SU = true else
                   '1' when ASn = '0' and LDSn = '0' and ADR_INT = x"FFFF8942" and RWn = '1' else '0';

    DTACKn <= '0' when MWD_RS = '1' or MWK_RS = '1' or GPx_EN_RS = '1' or GPx_DATA_RS = '1' else '1';

    -- Microwire clock is active when MWEn is asserted
    -- -> see microwire specification. Microwire starts when
    -- MWEn is asserted during MWK = '0';
    -- the MWK_MASK is somewhat ATARI specific. It enables the
    -- microwire clock only for valid Mask register bits. So
    -- it is possible to send don't care data.
    MWK_I <= SHIFTCLK when UWEn = '0' and MWK_MASK = '1' else '0';
    UWC <= MWK_I;

    PRESCALER: process
    variable TMP : std_logic_vector(4 downto 0);
    begin
        wait until CLK = '1' and CLK' event; -- 32MHz clock.
        if RESET = '1' then
            TMP := "00000";
        elsif MW_STATUS = IDLE then
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
    end process PRESCALER;

    MWD_I <= MW_DATA(15);
    UWD <= MWD_I;
    MWK_MASK <= MW_MASK(15);
    MWE_In <= '0' when MW_STATUS = RUN else '1';
    UWEn <= MWE_In;

    STATES: process
    variable START_EN   : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            START_EN := false;
            MW_STATUS <= IDLE;
        elsif MWD_RS = '1' and RWn = '0' and MW_STATUS = IDLE then
            START_EN := true;
        elsif MWD_RS = '0' and START_EN = true then
            MW_STATUS <= RUN; -- Start transmission after register write.
            START_EN := false;
        elsif MW_STATUS = RUN and BITCNT = "10001" then
            MW_STATUS <= IDLE; -- Stop the shift process after 16 bits have completed.
        end if;
    end process STATES;

    MW_REGISTERS: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            MW_DATA <= (others => '0');
            MW_MASK <= (others => '0');
            BITCNT <= "00000";
        elsif MWD_RS = '1' and RWn = '0' and MW_STATUS = IDLE then
            MW_DATA <= DATA_IN; -- Write to register.
            BITCNT <= "00000";
        elsif MWK_RS = '1' and RWn = '0' and MW_STATUS = IDLE then
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
    end process MW_REGISTERS;

    GPx_REGs: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            GPx_EN_REG <= x"0";
            GPx_DATA_REG <= "000";
        elsif GPx_EN_RS = '1' and RWn = '0' then
            GPx_EN_REG <= DATA_IN(3 downto 0);
        elsif GPx_DATA_RS = '1' and RWn = '0' then
            GPx_DATA_REG <= DATA_IN(2 downto 0);
        end if;
    end process GPx_REGs;

    GPx_OUT <= GPx_DATA_REG when GPx_EN_REG(3) = '0' else MWK_I & MWD_I & MWE_In;
    GPx_EN <= GPx_EN_REG(2 downto 0);

    -- Register read access is possible, even if microwire interface is active.
    DATA_OUT <= MW_DATA when MWD_RS = '1' and RWn = '1' else
                MW_MASK when MWK_RS = '1' and RWn = '1' else
                x"000" & GPx_EN_REG when GPx_EN_RS = '1' else
                x"000" & '0' & GPx_IN;
    DATA_EN <=  '1' when MWD_RS = '1' and RWn = '1' else
                '1' when MWK_RS = '1' and RWn = '1' else
                '1' when GPx_EN_RS = '1' and RWn = '1' else
                '1' when GPx_DATA_RS = '1' and RWn = '1' else '0';
end BEHAVIOUR;
