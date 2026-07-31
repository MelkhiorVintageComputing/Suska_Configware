------------------------------------------------------------------------
----                                                                ----
---- WF5380 IP Core                                                 ----
----                                                                ----
---- Description:                                                   ----
---- This model provides an asynchronous SCSI interface compa-      ----
---- tible to the DP5380 from National Semiconductor and others.    ----
----                                                                ----
---- This file is the 5380's register model.                        ----
----                                                                ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Register description (for more information see the DP5380      ----
---- data sheet:                                                    ----
----   ODR (address 0) Output data register, write only.            ----
----   CSD (address 0) Current SCSI data, read only.                ----
----   ICR (address 1) Initiator command register, read/write.      ----
----   MR2 (address 2) Mode register 2, read/write.                 ----
----   TCR (address 3) Target command register, read/write.         ----
----   SER (address 4) Select enable register, write only.          ----
----   CSB (address 4) Current SCSI bus status, read only.          ----
----   BSR (address 5) Start DMA send, write only.                  ----
----   SDS (address 5) Bus and status, read only.                   ----
----   SDT (address 6) Start DMA target receive, write only.        ----
----   IDR (address 6) Input data register, read only.              ----
----   SDI (address 7) Start DMA initiator recive, write only.      ----
----   RPI (address 7) Reset parity / interrupts, read only.        ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2009... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K9A  2009/06/20 WF
--   Initial Release.
-- Revision 2K13B  20131224 WF
--   First implementation in Suska-III-C.
-- Revision 2K15B 20151224 WF
--   Changed the lisence for this file.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF5380_REGISTERS is
    port (
        -- System controls:
        CLK         : in std_logic;
        RESET       : in std_logic; -- System reset.

        -- Address and data:
        ADR         : in std_logic_vector(2 downto 0);
        DATA_IN     : in std_logic_vector(7 downto 0);
        DATA_OUT    : out std_logic_vector(7 downto 0);
        DATA_EN     : out std_logic;

        -- Bus and DMA controls:
        CSn         : in std_logic;
        RDn         : in std_logic;
        WRn         : in std_logic;

        -- Core controls:
        RST         : out std_logic; -- Programmed SCSI reset.
        ARB_EN      : out std_logic; -- Arstd_logicration enable.
        DMA_ACTIVE  : in std_logic; -- DMA is running.
        DMA_EN      : out std_logic; -- DMA mode enable.
        BSY_DISn    : out std_logic; -- BSY monitoring enable.
        EOP_EN      : out std_logic; -- EOP interrupt enable.
        PINT_EN     : out std_logic; -- Parity interrupt enable.
        SPER        : out std_logic; -- Parity error.
        TARG        : out std_logic; -- Target mode.
        BLK         : out std_logic; -- Block DMA mode.
        DMA_DIS     : in std_logic; -- Reset the DMA_EN by this signal.
        IDR_WR      : in std_logic; -- Write input data register during DMA.
        ODR_WR      : in std_logic; -- Write output data register, during DMA.
        CHK_PAR     : in std_logic; -- Check Parity during DMA operation.
        AIP         : in std_logic; -- Arstd_logicration in progress.
        ARB         : in std_logic; -- Arstd_logicration.
        LA          : in std_logic; -- Lost arstd_logicration.

        CSD         : in std_logic_vector(7 downto 0); -- SCSI data.
        CSB         : in std_logic_vector(7 downto 0); -- Current SCSI bus status.
        BSR         : in std_logic_vector(7 downto 0); -- Bus and status.

        ODR_OUT     : out std_logic_vector(7 downto 0); -- This is the ODR register.
        ICR_OUT     : out std_logic_vector(7 downto 0); -- This is the ICR register.
        TCR_OUT     : out std_logic_vector(3 downto 0); -- This is the TCR register.
        SER_OUT     : out std_logic_vector(7 downto 0); -- This is the SER register.

        SDS         : out std_logic; -- Start DMA send, write only.
        SDT         : out std_logic; -- Start DMA target receive, write only.
        SDI         : out std_logic; -- Start DMA initiator receive, write only.
        RPI         : out std_logic
    );
end entity WF5380_REGISTERS;

architecture BEHAVIOUR of WF5380_REGISTERS is
signal ICR  : std_logic_vector(7 downto 0); -- Initiator command register, read/write.
signal IDR  : std_logic_vector(7 downto 0); -- Input data register.
signal MR2  : std_logic_vector(7 downto 0); -- Mode register 2, read/write.
signal ODR  : std_logic_vector(7 downto 0); -- Output data register, write only.
signal SER  : std_logic_vector(7 downto 0); -- Select enable register, write only.
signal TCR  : std_logic_vector(3 downto 0); -- Target command register, read/write.
begin
    REGISTERS: process
    -- This process reflects all registers in the 5380.
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            ODR <= (others => '0');
            ICR <= (others => '0');
            MR2 <= (others => '0');
            TCR <= (others => '0');
            SER <= (others => '0');
            IDR <= x"00"; -- SCSI reset.
        elsif ADR = "000" and CSn = '0' and WRn = '0' then
            ODR <= DATA_IN;
        elsif ADR = "001" and CSn = '0' and WRn = '0' then
            ICR <= DATA_IN;
        elsif ADR = "010" and CSn = '0' and WRn = '0' then
            MR2 <= DATA_IN;
        elsif ADR = "011" and CSn = '0' and WRn = '0' then
            TCR <= DATA_IN(3 downto 0);
        elsif ADR = "100" and CSn = '0' and WRn = '0' then
            SER <= DATA_IN;
        elsif ICR(7) = '1' then -- Write is prioritized over Reset via a Flag.
            ODR <= (others => '0');
            ICR(6 downto 0) <= (others => '0');
            MR2 <= '0' & MR2(6) & "000000";
            TCR <= (others => '0');
            SER <= (others => '0');
            IDR <= x"00"; -- SCSI reset.
        elsif MR2(2) = '1' then  -- Write is prioritized over Reset via a Flag.
            ICR(5 downto 0) <= "000000";
        end if;
        --
        if ODR_WR = '1' then
            ODR <= DATA_IN;
        end if;
        --
        if IDR_WR = '1' then
            IDR <= CSD;
        end if;
        --
        if DMA_DIS = '1' then
            MR2(1) <= '0';
        end if;
    end process REGISTERS;

    PARITY: process
    -- This is the parity generating logic with it's related
    -- error generation.
    variable PAR_VAR : std_logic;
    variable LOCK : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            SPER <= '0';
            LOCK := false;
        -- Parity checked during 'Read from CSD'
        -- (registered I/O and selection/reselection):
        elsif ADR = "000" and CSn = '0' and RDn = '0' and LOCK = false then
            for i in 1 to 7 loop
                PAR_VAR := CSD(i) xor CSD(i-1);
            end loop;
            SPER <= not PAR_VAR;
            LOCK := true;
        end if;
        --
        -- Parity checking during DMA operation:
        if DMA_ACTIVE = '1' and CHK_PAR = '1' then
            for i in 1 to 7 loop
                PAR_VAR := IDR(i) xor IDR(i-1);
            end loop;
            SPER <= not PAR_VAR;
            LOCK := true;
        end if;
        --
        -- Reset parity flag:
        if MR2(5) <= '0' then -- MR2(5) = PCHK (disabled).
            SPER <= '0';
        elsif ADR = "111" and CSn = '0' and RDn = '0' then -- Reset parity/interrupts.
            SPER <= '0';
            LOCK := false;
        end if;
    end process PARITY;

    SDS <= '1' when ADR = "101" and CSn = '0' and WRn = '0' else '0';
    SDT <= '1' when ADR = "110" and CSn = '0' and WRn = '0' else '0';
    SDI <= '1' when ADR = "111" and CSn = '0' and WRn = '0' else '0';

    ICR_OUT <= ICR;
    TCR_OUT <= TCR;
    SER_OUT <= SER;
    ODR_OUT <= ODR;

    ARB_EN <= MR2(0);
    DMA_EN <= MR2(1);
    BSY_DISn <= MR2(2);
    EOP_EN <= MR2(3);
    PINT_EN <= MR2(4);
    TARG <= MR2(6);
    BLK <= MR2(7);

    RST     <= ICR(7);

    RPI <= '1' when ADR = "111" and CSn = '0' and RDn = '0' else '0'; -- Reset parity/interrupts.

    -- Readback, unused std_logic positions are read back zero.
    DATA_OUT <= CSD when ADR = "000" and CSn = '0' and RDn = '0' else -- Current SCSI data.
                ICR(7) & AIP & LA & ICR(4 downto 0) when ADR = "001" and CSn = '0' and RDn = '0' else
                MR2 when ADR = "010" and CSn = '0' and RDn = '0' else
                x"0" & TCR when ADR = "011" and CSn = '0' and RDn = '0' else
                CSB when ADR = "100" and CSn = '0' and RDn = '0' else -- Current SCSI bus status.
                BSR when ADR = "101" and CSn = '0' and RDn = '0' else -- Bus and status.
                IDR when ADR = "110" and CSn = '0' and RDn = '0' else x"00"; -- Input data register.

    DATA_EN <= '1' when ADR < "111" and CSn = '0' and RDn = '0' else '0';
end BEHAVIOUR;