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
---- Top level file for use in systems on programmable chips.       ----
---- For a correct function of this code it is required, that the   ----
---- rising edge of the 8MHz clock is in phase with the MCU's       ----
---- rising edge of the 16MHz clock. Otherwise the arbiter does     ----
---- not work properly concerning the DMA access timing.            ----
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
--   Top level file provided for SOC (systems on programmable chips).
-- Revision 2K8A  2008/07/14 WF
--   Introduced DMA_SRC_SEL as a bit vector.
--   Some further (minor) changes.
-- Revision 2K9B  2009/12/24 WF
--   Changes concerning the new control section.
--   Changes concerning the revised register file.
--   Introduced CTRL_SRC_SEL.
--   Replaced port DMA_SRC_SEL by DRIVE_SEL.
-- Revision 2K3B  20131224 WF
--   DMA register section: several changes due to implementation of the 5380.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
-- Revision 2K20A  20200620 WF
--   Control: minor changes to meet requirements for the new bus arbiter (GLUE) and memory control (MCU).
-- Revision 2K24A  20240620 WF
--   CD bus enable signal CD_EN changes.
--

library work;
use work.WF25913IP_PKG.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF25913IP_TOP_SOC is
    port (
        -- System controls:
        RESETn      : in std_logic; -- Master reset.
        CLK         : in std_logic; -- Clock system.
        FCSn        : in std_logic; -- Adress select.
        A1          : in std_logic; -- Adress select.
        RWn         : in std_logic; -- Read write control.
        RDY_INn     : in std_logic; -- Data acknowlege control (GLUE-DMA).
        RDY_OUTn    : out std_logic; -- Data acknowlege control (GLUE-DMA).
        DATA_IN     : in std_logic_vector(15 downto 0); -- System data.
        DATA_OUT    : out std_logic_vector(15 downto 0); -- System data.
        DATA_EN     : out std_logic;

        -- Drive selection during register access and DMA:
        DRIVE_SEL   : out std_logic_vector(1 downto 0);

        -- ACSI section:
        CA2         : out std_logic;                    -- ACSI adress.
        CA1         : out std_logic;                    -- ACSI adress.
        CA0         : out std_logic;                    -- ACSI adress.
        CR_Wn       : out std_logic;                    -- ACSI read write control.
        CD_IN       : in std_logic_vector(7 downto 0);  -- ACSI data.
        CD_OUT      : out std_logic_vector(7 downto 0); -- ACSI data.
        CD_EN       : out std_logic;                    -- CD data enable.
        FDCSn       : out std_logic;                    -- FLOPPY select.
        SDCSn       : out std_logic;                    -- SD card select.
        SCSICSn     : out std_logic;                    -- SCSI device select.
        HDCSn       : out std_logic;                    -- ACSI drive select.
        FDRQ        : in std_logic;                     -- FLOPPY request.
        HDRQ        : in std_logic;                     -- ACSI drive request.
        ACKn        : out std_logic;                    -- ACSI data acknowledge.
        EOPn        : out std_logic                     -- 5380 end of process.
        );
end entity WF25913IP_TOP_SOC;

architecture STRUCTURE of WF25913IP_TOP_SOC is
signal DMA_EN               : std_logic;
signal CTRL_ACC             : std_logic;
signal DMA_SRC_SEL          : std_logic_vector(1 downto 0);
signal CTRL_SRC_SEL         : std_logic_vector(1 downto 0);
signal DMA_RWn              : std_logic;

signal FDCS_CTRL_REGn       : std_logic;
signal FDCS_DMA_ACCn        : std_logic;
signal ACSI_DATA_REQ        : std_logic;
signal SECTOR_CNT_EN        : std_logic;

signal CLRn                 : std_logic; --FIFO clear.
signal FIFO_DATA_OUT        : std_logic_vector(15 downto 0);
signal FIFO_DATA_IN         : std_logic_vector(15 downto 0);
signal FIFO_WR_ENA          : std_logic;
signal FIFO_RD_ENA          : std_logic;
signal FIFO_FULL            : std_logic;
signal FIFO_HI              : std_logic;
signal FIFO_LOW             : std_logic;
signal FIFO_EMPTY           : std_logic;
signal FIFO_ERR             : std_logic;

signal DATA_OUT_REG         : std_logic_vector(15 downto 0);
signal DATA_OUT_MUX         : std_logic_vector(15 downto 0);
signal DATA_EN_REG          : std_logic;
signal DATA_EN_MUX          : std_logic;

signal CD_OUT_REG           : std_logic_vector(7 downto 0);
signal CD_OUT_MUX           : std_logic_vector(7 downto 0);
signal CD_HIBUF_EN          : std_logic;
signal CD_RD_HIn            : std_logic;
signal CD_RD_LOWn           : std_logic;
signal CA                   : std_logic_vector(2 downto 0);
begin
    FDCSn <= '1' when (FDCS_CTRL_REGn and FDCS_DMA_ACCn) = '1' else '0';

    CA2 <= CA(2) when CTRL_ACC = '1' else '1'; -- Default is required for DMA operation of the 1772.
    CA1 <= CA(1) when CTRL_ACC = '1' else '1'; -- Default is required for DMA operation of the 1772.
    CA0 <= CA(0);

    -- Pay attention: The CTRL_ACC signal may not be deasserted
    -- prior to the respective drive chip select signals. See the
    -- controller access timing in the register section and the
    -- DTACKn logic in the GLUE which is responsible for the
    -- bus access timing.
    CR_Wn <= '1' when RWn = '1' and CTRL_ACC = '1' else
             '0' when RWn = '0' and CTRL_ACC = '1' else
             '1' when DMA_RWn = '1' else '0';

    DATA_EN <= DATA_EN_REG or DATA_EN_MUX;
    DATA_OUT <= DATA_OUT_MUX when DATA_EN_MUX = '1' else DATA_OUT_REG;

    CD_OUT <= CD_OUT_MUX when CD_RD_HIn = '0' or CD_RD_LOWn = '0' else CD_OUT_REG;

    -- Decoding for DRIVE_SEL:
    -- ACSI = "00", SCSI = "01", Floppy = "10", SD card = "11".
    DRIVE_SEL <= CTRL_SRC_SEL when CTRL_ACC = '1' else DMA_SRC_SEL;

    I_DMAREGS: WF25913IP_REGISTERS
        port map(
            CLK             => CLK,
            RESETn          => RESETn,
            FCSn            => FCSn,
            RWn             => RWn,
            A1              => A1,

            FIFO_ERROR      => FIFO_ERR,

            ACSI_DATA_REQ   => ACSI_DATA_REQ,
            SECTOR_CNT_EN   => SECTOR_CNT_EN,

            DATA_IN         => DATA_IN(9 downto 0),
            DATA_OUT        => DATA_OUT_REG,
            DATA_EN         => DATA_EN_REG,
            CD_IN           => CD_IN,
            CD_OUT          => CD_OUT_REG,
            CD_EN           => CD_EN,

            CTRL_SRC_SEL    => CTRL_SRC_SEL,
            DMA_SRC_SEL     => DMA_SRC_SEL,
            DMA_EN          => DMA_EN,

            EOPn            => EOPn,
            DMA_RWn         => DMA_RWn,
            HDCSn           => HDCSn,
            SCSICSn         => SCSICSn,
            SDCSn           => SDCSn,
            FDCSn           => FDCS_CTRL_REGn,
            CA              => CA,
            CTRL_ACC        => CTRL_ACC
        );

    I_FIFO: WF25913IP_FIFO
        port map(
            CLK             => CLK,
            CLRn            => CLRn,
            RD_ENA          => FIFO_RD_ENA,
            WR_ENA          => FIFO_WR_ENA,
            DATA_IN         => FIFO_DATA_IN,
            DATA_OUT        => FIFO_DATA_OUT,

            FIFO_FULL       => FIFO_FULL,
            FIFO_HI         => FIFO_HI,
            FIFO_LOW        => FIFO_LOW,
            FIFO_EMPTY      => FIFO_EMPTY,
            ERR             => FIFO_ERR
        );

    I_DMA_FIFO_DATAMUX: WF25913IP_FIFO_DATAMUX
        port map(
            CLK             => CLK,
            CLRn            => CLRn,
            DATA_IN         => DATA_IN,
            DATA_OUT        => DATA_OUT_MUX,
            CD_IN           => CD_IN,
            CD_OUT          => CD_OUT_MUX,
            FIFO_DATA_OUT   => FIFO_DATA_OUT,
            FIFO_DATA_IN    => FIFO_DATA_IN,
            DATA_EN         => DATA_EN_MUX,
            DMA_RWn         => DMA_RWn,
            CD_HIBUF_EN     => CD_HIBUF_EN,
            CD_RD_HIn       => CD_RD_HIn,
            CD_RD_LOWn      => CD_RD_LOWn
         );

    I_DMA_CTRL: WF25913IP_CTRL
        port map (
            CLK             => CLK,
            RESETn          => RESETn,

            RDY_INn         => RDY_INn,
            FCSn            => FCSn,
            DMA_EN          => DMA_EN,
            CTRL_ACC        => CTRL_ACC,

            DMA_RWn         => DMA_RWn,
            DMA_SRC_SEL     => DMA_SRC_SEL,
            HDRQ            => HDRQ,
            FDCRQ           => FDRQ,

            FIFO_FULL       => FIFO_FULL,
            FIFO_HI         => FIFO_HI,
            FIFO_LOW        => FIFO_LOW,
            FIFO_EMPTY      => FIFO_EMPTY,

            CLRn            => CLRn,

            FIFO_RD_ENA     => FIFO_RD_ENA,
            FIFO_WR_ENA     => FIFO_WR_ENA,

            DATA_EN         => DATA_EN_MUX,

            CD_HIBUF_EN     => CD_HIBUF_EN,
            CD_RD_HIn       => CD_RD_HIn,
            CD_RD_LOWn      => CD_RD_LOWn,

            ACSI_DATA_REQ   => ACSI_DATA_REQ,
            SECTOR_CNT_EN   => SECTOR_CNT_EN,

            FDCS_DMA_ACCn   => FDCS_DMA_ACCn,
            HD_ACKn         => ACKn,
            RDY_OUTn        => RDY_OUTn
    );
end architecture STRUCTURE;