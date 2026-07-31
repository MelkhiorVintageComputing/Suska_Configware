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
--   FIFO_WIDTH is no fixed to 16 bits.
--   Several changes / optimizations to meet the requirements for the new Falcon IP core.
-- 


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity DMA_FIFOs is
    generic(
        ACSI_FIFO_DEPTH     : integer := 16; -- Number of registers.
        REPLAY_FIFO_DEPTH   : integer := 16; -- Number of registers.
        CAPTURE_FIFO_DEPTH  : integer := 16 -- Number of registers.
        );
    port (
        RESET               : in std_logic;
        CLK                 : in std_logic;

        DATA_IN             : in std_logic_vector(15 downto 0);
        DATA_OUT            : out std_logic_vector(15 downto 0);

        CD_DATA_IN          : in std_logic_vector (7 downto 0);
        CD_DATA_OUT         : out std_logic_vector (7 downto 0);

        CAPTURE_DATA_IN     : in std_logic_vector (15 downto 0);
        REPLAY_DATA_OUT     : out std_logic_vector (15 downto 0);

        DMA_RWn             : in std_logic; -- FIFO direction '1' is peripherals to RAM.
        
        -- Control signals for the ACSI multiplexer:
        ACSI_DATA_EN        : in std_logic; -- Switch to connect the ACSI FIFO data to the bus.
        CD_HIBUF_EN         : in std_logic; -- Writes ACSI_BUF_HI.
        CD_RD_HIn           : in std_logic; -- Reads high FIFO byte to CD.
        CD_RD_LOWn          : in std_logic;  -- Reads low FIFO byte to CD.
        CAPTURE_DATA_EN     : in std_logic;  -- Switch to connect the PCM capture FIFO data to the bus.

        -- Control signals for the ACSI bus:
        ACSI_FIFO_CLRn      : in std_logic; -- Invalidate the FIFO entries.
        ACSI_FIFO_WR        : in std_logic;
        ACSI_FIFO_RD        : in std_logic;
        ACSI_FIFO_FULL      : out std_logic;
        ACSI_FIFO_LOW       : out std_logic;
        ACSI_FIFO_EMPTY     : out std_logic;
        ACSI_FIFO_ERROR     : out std_logic;

        -- Control signals for the PCM out:
        REPLAY_FIFO_CLRn    : in std_logic; -- Invalidate the FIFO entries.
        REPLAY_FIFO_WR      : in std_logic;
        REPLAY_FIFO_RD      : in std_logic;
        REPLAY_FIFO_FULL    : out std_logic;
        REPLAY_FIFO_LOW     : out std_logic;
        REPLAY_FIFO_EMPTY   : out std_logic;

        -- Control signals for the PCM in:
        CAPTURE_FIFO_CLRn   : in std_logic; -- Invalidate the FIFO entries.
        CAPTURE_FIFO_WR     : in std_logic;
        CAPTURE_FIFO_RD     : in std_logic;
        CAPTURE_FIFO_FULL   : out std_logic;
        CAPTURE_FIFO_LOW    : out std_logic;
        CAPTURE_FIFO_EMPTY  : out std_logic
    );
end entity DMA_FIFOs;  

architecture BEHAVIOR of DMA_FIFOs is
type ACSI_FIFOTYPE is array(0 to ACSI_FIFO_DEPTH) of std_logic_vector(15 downto 0);
type REPLAY_FIFOTYPE is array(0 to REPLAY_FIFO_DEPTH) of std_logic_vector(15 downto 0);
type CAPTURE_FIFOTYPE is array(0 to CAPTURE_FIFO_DEPTH) of std_logic_vector(15 downto 0);

signal ACSI_FIFO_REG            : ACSI_FIFOTYPE; 
signal REPLAY_FIFO_REG          : REPLAY_FIFOTYPE; 
signal CAPTURE_FIFO_REG         : CAPTURE_FIFOTYPE; 

signal ACSI_FIFO_DATA_IN        : std_logic_vector(15 downto 0);
signal ACSI_BUF_HI              : std_logic_vector(7 downto 0); -- CD byte buffer.

signal ACSI_WR_PNT              : natural range 0 to ACSI_FIFO_DEPTH;
signal REPLAY_WR_PNT            : natural range 0 to REPLAY_FIFO_DEPTH;
signal CAPTURE_WR_PNT           : natural range 0 to CAPTURE_FIFO_DEPTH;
begin
    P_ACSI_BUFFER: process
    -- The ACSI data bus is 8 bits wide, where the system data bus is 16 bits.
    -- To read from disk, there must sampled two ACSI bytes per system word.
    -- This process works as data pipeline for the first byte.
    begin
        wait until CLK = '1' and CLK' event;
        if ACSI_FIFO_CLRn = '0' then
            ACSI_BUF_HI <= (others => '0');
        elsif CD_HIBUF_EN = '1' then
            ACSI_BUF_HI <= CD_DATA_IN;
        end if;
    end process P_ACSI_BUFFER;

    ACSI_FIFO_DATA_IN <= DATA_IN when DMA_RWn = '0' else ACSI_BUF_HI & CD_DATA_IN;
    CD_DATA_OUT <= ACSI_FIFO_REG(0)(15 downto 8) when CD_RD_HIn = '0' else
                   ACSI_FIFO_REG(0)(7 downto 0) when CD_RD_LOWn = '0' else (others => '0');
    
    REPLAY_DATA_OUT <= REPLAY_FIFO_REG(0);
    
    DATA_OUT <= ACSI_FIFO_REG(0) when ACSI_DATA_EN = '1' else
                CAPTURE_FIFO_REG(0) when CAPTURE_DATA_EN = '1' else (others => '0');

    FIFO_WRITELOGIC: process
    subtype T_01 is natural range 0 to 1; 
    variable ACSI_WRITE : T_01;
    variable ACSI_READ : T_01;
    variable REPLAY_WRITE : T_01;
    variable REPLAY_READ : T_01;
    variable CAPTURE_WRITE : T_01;
    variable CAPTURE_READ : T_01;
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then 
            ACSI_WR_PNT <= 0;
            REPLAY_WR_PNT <= 0;
            CAPTURE_WR_PNT <= 0;
        end if;
        
        if ACSI_FIFO_WR = '1' then
            ACSI_WRITE := 1;
        elsif ACSI_FIFO_WR = '0' then
            ACSI_WRITE := 0;
        end if;
        if ACSI_FIFO_RD = '1' then
            ACSI_READ := 1;
        elsif ACSI_FIFO_RD = '0' then
            ACSI_READ := 0;
        end if;
            
        if ACSI_FIFO_CLRn = '0' then 
            ACSI_WR_PNT <= 0;
            ACSI_FIFO_ERROR <= '0';
        elsif ACSI_WR_PNT = ACSI_FIFO_DEPTH and ACSI_WRITE = 1 and ACSI_READ = 0 then
            ACSI_FIFO_ERROR <= '1'; -- FIFO full, no further write.
        elsif ACSI_WR_PNT = 0 and ACSI_WRITE = 0 and ACSI_READ = 1 then
            ACSI_FIFO_ERROR <= '1'; -- FIFO empty, no further read.
        else
            ACSI_WR_PNT <= ACSI_WR_PNT + ACSI_WRITE - ACSI_READ;
            ACSI_FIFO_ERROR <= '0';
        end if;

        if REPLAY_FIFO_WR = '1' then
            REPLAY_WRITE := 1;
        elsif REPLAY_FIFO_WR = '0' then
            REPLAY_WRITE := 0;
        end if;
        if REPLAY_FIFO_RD = '1' then
            REPLAY_READ := 1;
        elsif REPLAY_FIFO_RD = '0' then
            REPLAY_READ := 0;
        end if;
            
        if REPLAY_FIFO_CLRn = '0' then 
            REPLAY_WR_PNT <= 0;
        elsif REPLAY_WR_PNT = REPLAY_FIFO_DEPTH and REPLAY_WRITE = 1 and REPLAY_READ = 0 then
            null; -- FIFO full, no further write.
        elsif REPLAY_WR_PNT = 0 and REPLAY_WRITE = 0 and REPLAY_READ = 1 then
            null; -- FIFO empty, no further read.
        else
            REPLAY_WR_PNT <= REPLAY_WR_PNT + REPLAY_WRITE - REPLAY_READ;
        end if;

        if CAPTURE_FIFO_WR = '1' then
            CAPTURE_WRITE := 1;
        elsif CAPTURE_FIFO_WR = '0' then
            CAPTURE_WRITE := 0;
        end if;
        if CAPTURE_FIFO_RD = '1' then
            CAPTURE_READ := 1;
        elsif CAPTURE_FIFO_RD = '0' then
            CAPTURE_READ := 0;
        end if;
            
        if REPLAY_FIFO_CLRn = '0' then 
            CAPTURE_WR_PNT <= 0;
        elsif CAPTURE_WR_PNT = CAPTURE_FIFO_DEPTH and CAPTURE_WRITE = 1 and CAPTURE_READ = 0 then
            null; -- FIFO full, no further write.
        elsif CAPTURE_WR_PNT = 0 and CAPTURE_WRITE = 0 and CAPTURE_READ = 1 then
            null; -- FIFO empty, no further read.
        else
            CAPTURE_WR_PNT <= CAPTURE_WR_PNT + CAPTURE_WRITE - CAPTURE_READ;
        end if;
    end process FIFO_WRITELOGIC;

    ACSI_FIFO_FULL <= '1' when ACSI_WR_PNT = (ACSI_FIFO_DEPTH-1) and ACSI_FIFO_WR = '1' else -- We need early indication.
                      '1' when ACSI_WR_PNT = ACSI_FIFO_DEPTH else '0';
    ACSI_FIFO_LOW <= '1' when ACSI_WR_PNT < ACSI_FIFO_DEPTH/2 else '0';
    ACSI_FIFO_EMPTY <= '1' when ACSI_WR_PNT = 0 else '0';

    REPLAY_FIFO_FULL <= '1' when REPLAY_WR_PNT = REPLAY_FIFO_DEPTH else '0';
    REPLAY_FIFO_LOW <= '1' when REPLAY_WR_PNT < REPLAY_FIFO_DEPTH/2 else '0';
    REPLAY_FIFO_EMPTY <= '1' when REPLAY_WR_PNT = 0 else '0';

    CAPTURE_FIFO_FULL <= '1' when CAPTURE_WR_PNT = CAPTURE_FIFO_DEPTH else '0';
    CAPTURE_FIFO_LOW <= '1' when CAPTURE_WR_PNT < CAPTURE_FIFO_DEPTH/2 else '0';
    CAPTURE_FIFO_EMPTY <= '1' when CAPTURE_WR_PNT = 0 else '0';

    FIFOs: process
    begin
        wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            ACSI_FIFO_REG <= (others => (others => '0'));
            REPLAY_FIFO_REG <= (others => (others => '0'));
            CAPTURE_FIFO_REG <= (others => (others => '0'));
        else
            for i in 1 to ACSI_FIFO_DEPTH loop
                if i > ACSI_WR_PNT then
                    ACSI_FIFO_REG(i) <= ACSI_FIFO_DATA_IN;
                elsif ACSI_FIFO_RD = '1' then
                    if i = ACSI_WR_PNT then
                        ACSI_FIFO_REG(i) <= ACSI_FIFO_DATA_IN;
                    end if;
                    ACSI_FIFO_REG(i-1) <= ACSI_FIFO_REG(i); -- Stage 0 is a pipeline stage.
                end if;
            end loop;

            for i in 1 to REPLAY_FIFO_DEPTH loop
                if i > REPLAY_WR_PNT then
                    REPLAY_FIFO_REG(i) <= DATA_IN;
                elsif REPLAY_FIFO_RD = '1' then
                    if i = REPLAY_WR_PNT then
                        REPLAY_FIFO_REG(i) <= DATA_IN;
                    end if;
                    REPLAY_FIFO_REG(i-1) <= REPLAY_FIFO_REG(i); -- Stage 0 is a pipeline stage.
                end if;
            end loop;

            for i in 1 to CAPTURE_FIFO_DEPTH loop
                if i > CAPTURE_WR_PNT then
                    CAPTURE_FIFO_REG(i) <= CAPTURE_DATA_IN;
                elsif CAPTURE_FIFO_RD = '1' then
                    if i = CAPTURE_WR_PNT then
                        CAPTURE_FIFO_REG(i) <= CAPTURE_DATA_IN;
                    end if;
                    CAPTURE_FIFO_REG(i-1) <= CAPTURE_FIFO_REG(i); -- Stage 0 is a pipeline stage.
                end if;
            end loop;
        end if;
    end process FIFOs;
end architecture BEHAVIOR;
