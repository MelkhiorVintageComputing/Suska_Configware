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
-- Revision 2K21A 20211224 WF
--   Minor changes.
-- Revision 2K23B 20231224 WF
--   Simplified the controller access logic.
-- Revision 2K24A  20240620 WF
--   CD bus enable signal CD_EN changes.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity FDMA_ACSI_REGs is
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
        
        FIFO_ERROR          : in std_logic;
        ACSI_DATA_REQ       : in std_logic;
        SECTOR_CNT_EN       : in std_logic;

        CD_IN               : in std_logic_vector (7 downto 0);
        CD_OUT              : out std_logic_vector (7 downto 0);
        CD_EN               : out std_logic;      

        CTRL_SRC_SEL        : out std_logic_vector(1 downto 0);
        DMA_SRC_SEL         : out std_logic_vector(1 downto 0);
        DMA_EN              : out std_logic;

        DMA_RWn             : out std_logic;
        HDCSn               : out std_logic;
        SCSICSn             : out std_logic;
        SDCSn               : out std_logic;
        FDCSn               : out std_logic;
        CA                  : out std_logic_vector(2 downto 0);
        CTRL_ACC            : out std_logic;

        MDET                : in std_logic_vector(1 downto 0);
        DISKCHNG            : in std_logic;
        MODE                : out std_logic_vector(1 downto 0);
        FCCLK               : out std_logic;
        
        DMA_FRAME_CNT_EN    : in std_logic;
        DMA_ADR             : out std_logic_vector(31 downto 1)
    );
end FDMA_ACSI_REGs;

architecture BEHAVIOR of FDMA_ACSI_REGs is
signal ADR_I            : std_logic_vector(31 downto 0);
signal SU               : boolean; -- Spueruser.
signal US               : boolean; -- Normal user.
signal SECTOR_CNT_RS    : std_logic;
signal CTRL_ACC_RS      : std_logic;
signal DMA_MODE_RS      : std_logic;
signal DMA_STATUS_RS    : std_logic;
signal DMA_BASE_EXT_RS  : std_logic;
signal DMA_BASE_HI_RS   : std_logic;
signal DMA_BASE_MID_RS  : std_logic;
signal DMA_BASE_LOW_RS  : std_logic;
signal HD_REG_RS        : std_logic;
signal DMA_STATUS_REG   : std_logic_vector(2 downto 0);
signal DMA_MODE_REG     : std_logic_vector(9 downto 0);
signal SECTOR_CNT_REG   : std_logic_vector(7 downto 0);
signal SECT_CNT_ZEROn   : std_logic;
signal HD_REG           : std_logic_vector(3 downto 0);
signal DMAADR           : std_logic_vector(31 downto 1);
signal CTRL_ACC_EN      : std_logic;
begin
    ADR_I <= ADR_IN & '0';
    SU <= true when FC = "101" or FC = "110" else false; -- Superuser mode.
    US <= true when FC = "001" or FC = "010" else false; -- User mode.

    SECTOR_CNT_RS <= '1' when ASn = '0' and UDSn = '0' and LDSn = '0' and ADR_I = x"FFFF8604" and RWn = '0' and SU = true and CTRL_ACC_EN = '0' else
                     '1' when ASn = '0' and UDSn = '0' and LDSn = '0' and ADR_I = x"FFFF8604" and RWn = '1' and CTRL_ACC_EN = '0' and (SU = true or US = true) else '0';

    CTRL_ACC_RS <= '1' when ASn = '0' and UDSn = '0' and LDSn = '0' and ADR_I = x"FFFF8604" and RWn = '0' and SU = true and CTRL_ACC_EN = '1' else
                   '1' when ASn = '0' and UDSn = '0' and LDSn = '0' and ADR_I = x"FFFF8604" and RWn = '1' and CTRL_ACC_EN = '1' and (SU = true or US = true) else '0';

    -- Write only register in SU mode:
    DMA_MODE_RS <= '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8606" and RWn = '0' and SU = true else '0';
 
    -- Read only register:
    DMA_STATUS_RS <= '1' when ASn = '0' and UDSn = '0' and ADR_I = x"FFFF8606" and RWn = '1' else '0';

    -- The DMA base registers are 8 bit wide and selected via LDSn on the low data byte.
    DMA_BASE_EXT_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF860E" and RWn = '0' and SU = true else 
                       '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF860E" and RWn = '1' and (SU = true or US = true) else '0'; -- x"FFFF8607".

    DMA_BASE_HI_RS <=  '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8608" and RWn = '0' and SU = true else 
                       '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF8608" and RWn = '1' and (SU = true or US = true) else '0'; -- x"FFFF8609".
    DMA_BASE_MID_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF860A" and RWn = '0' and SU = true else 
                       '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF860A" and RWn = '1' and (SU = true or US = true) else '0'; -- x"FFFF860B".
    DMA_BASE_LOW_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF860C" and RWn = '0' and SU = true else 
                       '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF860C" and RWn = '1' and (SU = true or US = true) else '0'; -- x"FFFF860D".

    HD_REG_RS <= '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF860E" and RWn = '0' and SU = true else
                 '1' when ASn = '0' and LDSn = '0' and ADR_I = x"FFFF860E" and RWn = '1' and (SU = true or US = true) else '0'; -- x"FFFF860F".

    DMA_MODE: process
    -- The DMA mode register is write only. At the same 
    -- adress the DMA status register is read only.
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            DMA_MODE_REG <= (others => '0');
        elsif DMA_MODE_RS = '1' and RWn = '0' then
            DMA_MODE_REG <= DATA_IN(9 downto 0); -- Write to register.
        end if;
    end process DMA_MODE;

    DMA_STATUS: process
    -- The DMA status register is read only. At the same 
    -- adress the DMA mode register is write only.
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            DMA_STATUS_REG <= "011"; -- Register is low active.
        -- Clear the status register by access (read or write)
        -- to the sector count register:
        elsif SECTOR_CNT_RS = '1' then
            DMA_STATUS_REG <= "111"; -- Clear.
        elsif FIFO_ERROR = '1' then
            DMA_STATUS_REG(0) <= '0'; -- Store the event.
        else
            DMA_STATUS_REG(2) <= ACSI_DATA_REQ; -- Update.
            DMA_STATUS_REG(1) <= SECT_CNT_ZEROn; -- Update.
        end if;
    end process DMA_STATUS;
    
    SECTOR_CNT: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            SECTOR_CNT_REG <= x"00";
        elsif SECTOR_CNT_RS = '1' and RWn = '0' then
            SECTOR_CNT_REG <= DATA_IN(7 downto 0); -- Write to register.
        elsif SECTOR_CNT_EN = '1' and SECTOR_CNT_REG > x"00" then
            SECTOR_CNT_REG <= SECTOR_CNT_REG - '1'; -- Count down.
        end if;
    end process SECTOR_CNT;

    -- Bring the SECTOR_CNT_ZEROn information as early as possible during DMA write to target.
    SECT_CNT_ZEROn <= '0' when SECTOR_CNT_REG = x"01" and SECTOR_CNT_EN = '1' and DMA_MODE_REG(8) = '0' else
                      '0' when SECTOR_CNT_REG = x"00" else '1';

    DMA_REG: process(CLK, DMAADR)
    begin
        if CLK = '1' and CLK' event then
            if RESET = '1' then
                DMAADR <= (others => '0');
            elsif DMA_BASE_EXT_RS = '1' and RWn = '0' then
                DMAADR(31 downto 24) <= DATA_IN(7 downto 0);
            elsif DMA_BASE_HI_RS = '1' and RWn = '0' then
                DMAADR(23 downto 16) <= DATA_IN(7 downto 0);
            elsif DMA_BASE_MID_RS = '1' and RWn = '0' then
                DMAADR(15 downto 8) <= DATA_IN(7 downto 0);
            elsif DMA_BASE_LOW_RS = '1' and RWn = '0' then
                DMAADR(7 downto 1) <= DATA_IN(7 downto 1);
            elsif DMA_FRAME_CNT_EN = '1' then
                DMAADR <= DMAADR + '1';
            end if;
        end if;
        DMA_ADR <= DMAADR;
    end process DMA_REG;
    
    P_HD_REG: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            HD_REG <= x"0";
        elsif HD_REG_RS = '1' and RWn = '0' then
            HD_REG <= DATA_IN(5 downto 4) & DATA_IN(1 downto 0);
        end if;
    end process P_HD_REG;

    -- Read from registers, unused pins are read back as '0's.
    DATA_EN <= '1' when DMA_STATUS_RS = '1' and RWn = '1' else
               '1' when SECTOR_CNT_RS = '1' else
               '1' when HD_REG_RS = '1' and RWn = '1' else
               '1' when CTRL_ACC_RS = '1' and RWn = '1' else
               '1' when DMA_BASE_EXT_RS = '1' and RWn = '1' else
               '1' when DMA_BASE_HI_RS = '1' and RWn = '1' else
               '1' when DMA_BASE_MID_RS = '1' and RWn = '1' else
               '1' when DMA_BASE_LOW_RS = '1' and RWn = '1' else '0';

    DATA_OUT <= "0000000000000" & DMA_STATUS_REG when DMA_STATUS_RS = '1' and RWn = '1' else
                x"00" & SECTOR_CNT_REG when SECTOR_CNT_RS = '1' and RWn = '1' else
                x"00" & CD_IN when CTRL_ACC_RS = '1' and RWn = '1' else -- Controller access stuff.
                x"00" & DISKCHNG & MDET(1) & HD_REG(3 downto 2) & '1' & MDET(0) & HD_REG(1 downto 0) when HD_REG_RS = '1' and RWn = '1' else
                x"00" & DMAADR(31 downto 24) when DMA_BASE_EXT_RS = '1' and RWn = '1' else
                x"00" & DMAADR(23 downto 16) when DMA_BASE_HI_RS = '1' and RWn = '1' else
                x"00" & DMAADR(15 downto 8) when DMA_BASE_MID_RS = '1' and RWn = '1' else
                x"00" & DMAADR(7 downto 1) & '0' when DMA_BASE_LOW_RS = '1' and RWn = '1' else (others => '0');

    DTACKn <=  '0' when DMA_STATUS_RS = '1'   else
               '0' when DMA_MODE_RS = '1'     else
               '0' when CTRL_ACC_RS = '1'     else
               '0' when SECTOR_CNT_RS = '1'   else
               '0' when HD_REG_RS = '1'       else
               '0' when DMA_BASE_EXT_RS = '1' else
               '0' when DMA_BASE_HI_RS = '1'  else
               '0' when DMA_BASE_MID_RS = '1' else
               '0' when DMA_BASE_LOW_RS = '1' else '1';

    DMA_RWn <= not DMA_MODE_REG(8);
    DMA_SRC_SEL(1) <= DMA_MODE_REG(7);
    DMA_SRC_SEL(0) <= DMA_MODE_REG(5);
    DMA_EN <= not DMA_MODE_REG(6);
    CTRL_ACC_EN <= not DMA_MODE_REG(4);
    CA <= DMA_MODE_REG(2 downto 0);

    FDCSn <= '0' when CTRL_ACC_EN = '1' and CTRL_ACC_RS = '1' and ADR_I(1) = '0' and DMA_MODE_REG(9) = '0' and DMA_MODE_REG(3) = '0' else '1';
    HDCSn <= '0' when CTRL_ACC_EN = '1' and CTRL_ACC_RS = '1' and ADR_I(1) = '0' and DMA_MODE_REG(9) = '0' and DMA_MODE_REG(3) = '1' else '1';
    SDCSn <= '0' when CTRL_ACC_EN = '1' and CTRL_ACC_RS = '1' and ADR_I(1) = '0' and DMA_MODE_REG(9) = '1' and DMA_MODE_REG(3) = '0' else '1';
    SCSICSn <= '0' when CTRL_ACC_EN = '1' and CTRL_ACC_RS = '1' and ADR_I(1) = '0' and DMA_MODE_REG(9) = '1' and DMA_MODE_REG(3) = '1' else '1';

    MODE <= HD_REG(3) & HD_REG(1);

    P_FCCLK: process
    variable TMP        : std_logic_vector(1 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        TMP := TMP + '1';
        if HD_REG(2) = '0' and  HD_REG(0) = '0' then
            FCCLK <= TMP(1); -- 8MHz.
        elsif HD_REG(2) = '0' and  HD_REG(0) = '1' then
            FCCLK <= TMP(0); -- 16MHz.
        else
            FCCLK <= CLK; -- 32MHz.
        end if;
    end process;

    CD_EN <= '1' when CTRL_ACC_EN = '1' and RWn = '0' else 
             '1' when CTRL_ACC_EN = '0' and DMA_MODE_REG(8) = '1' else '0';

    CD_OUT <= DATA_IN(7 downto 0);

    CTRL_ACC <= CTRL_ACC_RS;

    -- Controller access drive selection:
    -- This configuration was chosen due to compatibility with old software.
    -- Use the same configuration as for the DMA decoding to mix CTRL_SRC_SEL
    -- easily up with DMA_SRC_SEL in the DMA top level file.
    CTRL_SRC_SEL <= "00" when DMA_MODE_REG(9) = '0' and  DMA_MODE_REG(3) = '1' else -- ACSI.
                    "01" when DMA_MODE_REG(9) = '1' and  DMA_MODE_REG(3) = '1' else -- SCSI.
                    "10" when DMA_MODE_REG(9) = '0' and  DMA_MODE_REG(3) = '0' else "11"; -- Floppy, Default: SD card.
end architecture BEHAVIOR;
