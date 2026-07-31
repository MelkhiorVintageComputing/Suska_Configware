------------------------------------------------------------------------
----                                                                ----
---- ATARI DMA compatible IP Core                                   ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- ATARI ST and STE compatible DMA controller IP core.            ----
----                                                                ----
---- This files is moddeling the DMA relevant registers.            ----
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
--   Introduced the access level register CD_2_DATA.
-- Revision 2K8B  2008/12/24 WF
--   Introduced SCSICSn and SDCSn.
--   Introduced DMA_SRC_SEL as a bit vector.
--   DMA_STATUS_REG has now synchronous reset to meet preset requirement.
-- Revision 2K9B  2009/12/24 WF
--   Changed timing of SECT_CNT_ZEROn.
--   Fixed a bug in the sector counter.
--   Fixed DMA_EN logic and replaced DMA_RDn, DMA_WRn by DMA_EN.
--   Introduced CTRL_SRC_SEL.
--   Fixed bus access timing.
-- Revision 2K13B  20131224 WF
--   Several changes due to implementation of the 5380.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--   CD_OUT is now registered - see DATA buffer.
-- Revision 2K16A  20160620 WF
--   CD_IN is now registered for timing stability.
-- Revision 2K23B 20231224 WF
--   Simplified the controller access logic.
-- Revision 2K24A  20240620 WF
--   CD bus enable signal CD_EN changes.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF25913IP_REGISTERS is
    port(
        CLK             : in std_logic;
        RESETn          : in std_logic;
        FCSn            : in std_logic;
        RWn             : in std_logic;
        A1              : in std_logic;

        FIFO_ERROR      : in std_logic;
        ACSI_DATA_REQ   : in std_logic;
        SECTOR_CNT_EN   : in std_logic;

        DATA_IN         : in std_logic_vector (9 downto 0);
        DATA_OUT        : out std_logic_vector (15 downto 0);
        DATA_EN         : out std_logic;
        CD_IN           : in std_logic_vector (7 downto 0);
        CD_OUT          : out std_logic_vector (7 downto 0);
        CD_EN           : out std_logic;

        CTRL_SRC_SEL    : out std_logic_vector(1 downto 0);
        DMA_SRC_SEL     : out std_logic_vector(1 downto 0);
        DMA_EN          : out std_logic;

        EOPn            : out std_logic;
        DMA_RWn         : out std_logic;
        HDCSn           : out std_logic;
        SCSICSn         : out std_logic;
        SDCSn           : out std_logic;
        FDCSn           : out std_logic;
        CA              : out std_logic_vector(2 downto 0);
        CTRL_ACC        : out std_logic
    );
end WF25913IP_REGISTERS;

architecture BEHAVIOR of WF25913IP_REGISTERS is
signal CTRL_ACC_EN      : std_logic;
signal DMA_STATUS_REG   : std_logic_vector(2 downto 0);
signal DMA_MODE_REG     : std_logic_vector(9 downto 0);
signal SECT_CNT_ZEROn   : std_logic;
signal SECTOR_CNT_REG   : std_logic_vector(7 downto 0);
begin
    DMA_MODE: process
    -- The DMA mode register is write only. At the same
    -- adress the DMA status register is read only.
    begin
        wait until CLK = '1' and CLK' event;
        if RESETn = '0' then
            DMA_MODE_REG <= (others => '0');
        elsif FCSn = '0' and A1 = '1' and RWn = '0' then
            DMA_MODE_REG <= DATA_IN; -- Write to register.
        end if;
    end process DMA_MODE;

    -- Wiring of the DMA mode register ($FF8606|word, W):
    --  DMA mode/status                 bit 9 8 7 6 5 4 3 2 1 0
    --  0 - HDC_FDC_EN, 1 - SCSI_SDC_EN ----'
    --  0 - read FDC/HDC, 1 - write ----------' | | | | | | | |
    --  0 - DMA with HDC/SCSI, 1 - with FDC/SD--' | | | | | | |
    --  0 - DMA on, 1 - no DMA -------------------' | | | | | |
    --  ACSI/SCSI/SD/Floppy see below --------------' | | | | |
    --  0 - controller access, 1 - sector count reg --' | | | |
    --  ACSI/SCSI/SD/Floppy see below ------------------' | | |
    --  0 - pin CA2 low, 1 - pin CA2 high ----------------' | |
    --  0 - pin CA1 low, 1 - pin CA1 high ------------------' |
    --  0 - pin CA0 low, 1 - pin CA0 high --------------------'

    -- Selection for the DMA_SRC_SEL(1) bit 7 and DMA_SRC_SEL(0) bit 5 of the DMA mode register:
    -- 00   : DMA with ACSI:
    -- 10   : DMA with FLOPPY:
    -- 01   : DMA with SCSI:
    -- 11   : DMA with SD card.

    DMA_RWn <= not DMA_MODE_REG(8);
    DMA_SRC_SEL(1) <= DMA_MODE_REG(7);
    DMA_SRC_SEL(0) <= DMA_MODE_REG(5);
    DMA_EN <= not DMA_MODE_REG(6);
    CTRL_ACC_EN <= not DMA_MODE_REG(4);
    CA <= DMA_MODE_REG(2 downto 0);

    CTRL_SRC_SEL <= "11" when DMA_MODE_REG(9) = '1' and DMA_MODE_REG(3) = '0' else -- SD card.
                    "10" when DMA_MODE_REG(9) = '0' and DMA_MODE_REG(3) = '0' else -- Floppy.
                    "01" when DMA_MODE_REG(9) = '1' and DMA_MODE_REG(3) = '1' else -- SCSI.
                    "00"; -- ACSI.

    DMA_STATUS: process
    -- The DMA status register is read only. At the same
    -- adress the DMA mode register is write only.
    begin
        wait until CLK = '1' and CLK' event;
        if RESETn = '0' then
            DMA_STATUS_REG <= "011"; -- Register is low active.
        -- Clear the status register by access (read or write)
        -- to the sector count register:
        elsif FCSn = '0' and A1 = '0' and CTRL_ACC_EN = '0' then
            DMA_STATUS_REG <= "111"; -- Clear.
        elsif FIFO_ERROR = '1' then
            DMA_STATUS_REG(0) <= '0'; -- Store the event.
        else
            DMA_STATUS_REG(2) <= ACSI_DATA_REQ; -- Update.
            DMA_STATUS_REG(1) <= SECT_CNT_ZEROn; -- Update.
        end if;
    end process DMA_STATUS;

    SECTOR_CNT: process(RESETn, CLK, SECTOR_CNT_REG)
    begin
        if RESETn = '0' then
            SECTOR_CNT_REG <= x"00";
        elsif CLK = '1' and CLK' event then
            if FCSn = '0' and A1 = '0' and RWn = '0' and CTRL_ACC_EN = '0' then
                SECTOR_CNT_REG <= DATA_IN(7 downto 0); -- Write to register.
            elsif SECTOR_CNT_EN = '1' and SECTOR_CNT_REG > x"00" then
                SECTOR_CNT_REG <= SECTOR_CNT_REG - '1'; -- Count down.
            end if;
        end if;
    end process SECTOR_CNT;

    EOPn <= '0' when SECT_CNT_ZEROn = '0' else '1';

    -- Bring the SECTOR_CNT_ZEROn information as early as possible during DMA write to target.
    SECT_CNT_ZEROn <= '0' when SECTOR_CNT_REG = x"01" and SECTOR_CNT_EN = '1' and DMA_MODE_REG(8) = '0' else
                      '0' when SECTOR_CNT_REG = x"00" else '1';

    -- Read from register:
    -- In read operation unused pins are read back as '0's:
    DATA_EN <= '1' when FCSn = '0' and RWn = '1' else '0';

    DATA_OUT <= "0000000000000" & DMA_STATUS_REG when A1 = '1' else
                x"00" & SECTOR_CNT_REG when A1 = '0' and CTRL_ACC_EN = '0' else
                x"00" & CD_IN when CTRL_ACC_EN = '1' and A1 = '0' else x"0000"; -- Controller access.

    CD_OUT <= DATA_IN(7 downto 0);
    CD_EN <= '1' when CTRL_ACC_EN = '1' and FCSn = '0' and RWn = '0' else 
             '1' when CTRL_ACC_EN = '0' and DMA_MODE_REG(8) = '1' else '0';

    CTRL_ACC <= '1' when CTRL_ACC_EN = '1' and FCSn = '0' else '0'; -- Controller access.

    FDCSn <= '0' when CTRL_ACC_EN = '1' and FCSn = '0' and A1 = '0' and DMA_MODE_REG(9) = '0' and DMA_MODE_REG(3) = '0' else '1';
    HDCSn <= '0' when CTRL_ACC_EN = '1' and FCSn = '0' and A1 = '0' and DMA_MODE_REG(9) = '0' and DMA_MODE_REG(3) = '1' else '1';
    SDCSn <= '0' when CTRL_ACC_EN = '1' and FCSn = '0' and A1 = '0' and DMA_MODE_REG(9) = '1' and DMA_MODE_REG(3) = '0' else '1';
    SCSICSn <= '0' when CTRL_ACC_EN = '1' and FCSn = '0' and A1 = '0' and DMA_MODE_REG(9) = '1' and DMA_MODE_REG(3) = '1' else '1';
end architecture BEHAVIOR;
