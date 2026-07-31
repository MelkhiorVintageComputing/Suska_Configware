------------------------------------------------------------------------
----                                                                ----
---- USB1160 IP Core                                                ----
----                                                                ----
---- Description:                                                   ----
---- This model provides an embedded Universal Serial Bus host      ----
---- controller compatible to the Philips ISP1160.                  ----
----                                                                ----
---- This entity is the FIFO buffer.                                ----
----                                                                ----
----                                                                ----
---- This storage buffer works as a FIFO from the perspective of    ----
---- the microcontroller. To access PTD structure, the access from  ----
---- the host controller (HC) perspective is randomly resulting in  ----
---- a linear adressing by the HC.                                  ----
---- This FIFO buffer is a 4096 Byte buffer organized in a 8 bit    ----
---- buffer width. The FIFO uses a standard RAM which is controlled ----
---- as simple FIFO. It allows simultaneous access from the host    ----
---- and microcontroller side regardeless of read or write access.  ----
---- A simultaneous read and write from either host or micro-       ----
---- controller is also supported. As we use a standard RAM the     ----
---- FIFO is controlled in a pseudo dual port access using time     ----
---- multiplexing. This requires a fixed clock ratio of six clock   ----
---- cycles per access. In this way a concurrent read/write from    ----
---- the host side and from the microcontroller side is provided.   ----
---- For proper operation, the controlling signals for read and     ----
---- write are required to be strobes.                              ----
---- Be aware that a concurrent read or write access by the MC is   ----
---- handled in one go. There is no random read write access from   ----
---- the MC. The read portion of the FIFO may be different from the ----
---- write portion. To handle the head and tail counters correctly, ----
---- The TAIL is initialized during write access and the HEAD is    ----
---- initialized during the read access.                            ----
---- The FIFO has no rollover feature which is not required due to  ----
---- the predefined PTD structure and FIFO organization.            ----
----                                                                ----
---- The RAM is organized to handle both, the ATL (this is the      ----
---- acknowledged transfer list) and the ITL (this is the isochro-  ----
---- nous transfer list). A complete FIFO access cycle consists of  ----
---- host controller service (HC) and microcontroller service (MC). ----
---- As the RAM is 8 bit wide (due to requirement of USB) there are ----
---- HI and LO byte accesses. The following services are possible:  ----
---- MC and HC serviced, MC serviced - no HC, HC serviced - no MC   ----
---- and no service. For more information see below.                ----
----                                                                ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2020... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K20B  20201224 WF
--   Draft version.
-- Revision 2K22A  20221224 WF
--   Debugging version.
-- Revision 2K23A  20230620 WF
--   Initial release.
-- Revision 2K23B  20231224 WF
--   Minor changes.
-- Revision 2K24A  20240620 WF
--   State machine cycle timing optimizations.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity FIFO_BUFFER is
    port (
        CLK_48MHz           : in std_logic;
        RESET               : in std_logic;
        HCR                 : in std_logic;

        ITL_BUFF_LEN        : in std_logic_vector(11 downto 0);
        RD_ITL0_BUFF_LENGTH : buffer std_logic_vector(15 downto 0); -- Read back.
        RD_ITL1_BUFF_LENGTH : buffer std_logic_vector(15 downto 0); -- Read back.

        BUFFER_IN_MC        : in std_logic_vector(15 downto 0);
        BUFFER_IN_HC        : in std_logic_vector(15 downto 0);
        BUFFER_OUT_MC       : out std_logic_vector(15 downto 0);
        BUFFER_OUT_HC       : out std_logic_vector(15 downto 0);
        BUFFER_RDY_HC       : out std_logic;

        ATL_RD_MC           : in std_logic; -- By microprocessor.
        ATL_WR_MC           : in std_logic; -- By microprocessor.
        ITL_RD_MC           : in std_logic; -- By microprocessor.
        ITL_WR_MC           : in std_logic; -- By microprocessor.

        ATL_RD_HC           : in std_logic; -- By host controller.
        ATL_WR_HC           : in std_logic; -- By host controller.
        ITL_RD_HC           : in std_logic; -- By host controller.
        ITL_WR_HC           : in std_logic; -- By host controller.
        HC_ITL1             : in std_logic; -- By host controller.
        HC_ADR              : in std_logic_vector(11 downto 0) -- HCs FIFO address.
    );
end entity FIFO_BUFFER;

architecture BEHAVIOUR of FIFO_BUFFER is
type FIFO_TYPE is array(0 to 4095) of std_logic_vector(7 downto 0);
type FIFO_CYCLES is (IDLE, CHECK_HC, 
                     MC_ATL_WRITE_LO, MC_ATL_READ_LO, MC_ATL_WRITE_HI, MC_ATL_READ_HI, 
                     MC_ITL0_WRITE_LO, MC_ITL0_READ_LO, MC_ITL0_WRITE_HI, MC_ITL0_READ_HI, 
                     MC_ITL1_WRITE_LO, MC_ITL1_READ_LO, MC_ITL1_WRITE_HI, MC_ITL1_READ_HI, 
                     HC_ATL_WRITE_LO, HC_ATL_READ_LO, HC_ATL_WRITE_HI, HC_ATL_READ_HI, 
                     HC_ITL0_WRITE_LO, HC_ITL0_READ_LO, HC_ITL0_WRITE_HI, HC_ITL0_READ_HI, 
                     HC_ITL1_WRITE_LO, HC_ITL1_READ_LO, HC_ITL1_WRITE_HI, HC_ITL1_READ_HI);
signal FIFO_CYCLE       : FIFO_CYCLES;
signal NEXT_FIFO_CYCLE  : FIFO_CYCLES;
signal FIFO             : FIFO_TYPE;
signal FIFO_ADR         : std_logic_vector(11 downto 0);
signal FIFO_D_IN        : std_logic_vector(7 downto 0);
signal FIFO_D_OUT       : std_logic_vector(7 downto 0);
signal FIFO_WR          : std_logic;
signal ATL_HEAD         : std_logic_vector(11 downto 0);
signal ATL_TAIL         : std_logic_vector(11 downto 0);
signal ATL_RD_HC_I      : std_logic;
signal ATL_WR_HC_I      : std_logic;
signal ATL_RD_MC_I      : std_logic;
signal ATL_WR_MC_I      : std_logic;
signal ITL0_RD_MC       : std_logic;
signal ITL0_WR_MC       : std_logic;
signal ITL1_RD_MC       : std_logic;
signal ITL1_WR_MC       : std_logic;
signal ITL0_RD_HC       : std_logic;
signal ITL0_WR_HC       : std_logic;
signal ITL1_RD_HC       : std_logic;
signal ITL1_WR_HC       : std_logic;
signal ITL0_HEAD        : std_logic_vector(11 downto 0);
signal ITL0_TAIL        : std_logic_vector(11 downto 0);
signal ITL1_HEAD        : std_logic_vector(11 downto 0);
signal ITL1_TAIL        : std_logic_vector(11 downto 0);
begin

    REQUESTS: process
    -- These flip flops stores the requests of the MC or the HC.
    -- The flip flops are cleared when the request is processed.
    -- Be aware, that all control signals from the MC or the
    -- HC are strobes.
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if ATL_RD_MC = '1' then
            ATL_RD_MC_I <= '1';
        elsif FIFO_CYCLE = MC_ATL_READ_LO then
            ATL_RD_MC_I <= '0';
        end if;

        if ATL_WR_MC = '1' then
            ATL_WR_MC_I <= '1';
        elsif FIFO_CYCLE = MC_ATL_WRITE_LO then
            ATL_WR_MC_I <= '0';
        end if;

        if ATL_RD_HC = '1' then
            ATL_RD_HC_I <= '1';
        elsif FIFO_CYCLE = HC_ATL_READ_LO then
            ATL_RD_HC_I <= '0';
        end if;

        if ATL_WR_HC = '1' then
            ATL_WR_HC_I <= '1';
        elsif FIFO_CYCLE = HC_ATL_WRITE_LO then
            ATL_WR_HC_I <= '0';
        end if;

        if ITL_RD_MC = '1' and HC_ITL1 = '1' then
            ITL0_RD_MC <= '1';
        elsif FIFO_CYCLE = MC_ITL0_READ_LO then
            ITL0_RD_MC <= '0';
        end if;
            
        if ITL_RD_MC = '1' and HC_ITL1 = '0' then
            ITL1_RD_MC <= '1'; 
        elsif FIFO_CYCLE = MC_ITL1_READ_LO then
            ITL1_RD_MC <= '0';
        end if;

        if ITL_WR_MC = '1' and HC_ITL1 = '1' then
            ITL0_WR_MC <= '1';
        elsif FIFO_CYCLE = MC_ITL0_WRITE_LO then
            ITL0_WR_MC <= '0';
        end if;

        if ITL_WR_MC = '1' and HC_ITL1 = '0' then
            ITL1_WR_MC <= '1';
        elsif FIFO_CYCLE = MC_ITL1_WRITE_LO then
            ITL1_WR_MC <= '0';
        end if;

        if ITL_RD_HC = '1' and HC_ITL1 = '0' then
            ITL0_RD_HC <= '1';
        elsif FIFO_CYCLE = HC_ITL0_READ_LO then
            ITL0_RD_HC <= '0';
            end if;

        if ITL_RD_HC = '1' and HC_ITL1 = '1' then
            ITL1_RD_HC <= '1';
        elsif FIFO_CYCLE = HC_ITL1_READ_LO then
            ITL1_RD_HC <= '0';
        end if;

        if ITL_WR_HC = '1' and HC_ITL1 = '0' then
            ITL0_WR_HC <= '1';
        elsif FIFO_CYCLE = HC_ITL0_WRITE_LO then
            ITL0_WR_HC <= '0';
        end if;

        if ITL_WR_HC = '1' and HC_ITL1 = '1' then
            ITL1_WR_HC <= '1';
        elsif FIFO_CYCLE = HC_ITL1_WRITE_LO then
            ITL1_WR_HC <= '0';
        end if;
    end process REQUESTS;

    STATE_REG: process
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if RESET = '1' or HCR = '1' then
            FIFO_CYCLE <= IDLE;
        else
            FIFO_CYCLE <= NEXT_FIFO_CYCLE;
        end if;
    end process STATE_REG;

    -- The following table shows the four possibe access scenarios, coded in the state decoder.
    -- CYCLE:   0 ---------- 1 ---------- 2 ---------- 3 ---------- 4 ---------- 5 ---------- 6
    --        IDLE         MC_LO        MC_HI       CHECK_HC      HC_LO         HC_HI       IDLE  -- MC and HC serviced.
    --        IDLE         MC_LO        MC_HI       CHECK_HC                                IDLE  -- MC serviced.       
    --        IDLE         HC_LO        HC_HI                                               IDLE  -- HC serviced.       
    --        IDLE                                                                                -- No service.        

    STATE_DEC: process(FIFO_CYCLE, ATL_RD_MC_I, ATL_WR_MC_I, ITL0_RD_MC, ITL0_WR_MC, ITL1_RD_MC, ITL1_WR_MC, 
                       ATL_RD_HC_I, ATL_WR_HC_I, ITL0_RD_HC, ITL0_WR_HC, ITL1_RD_HC, ITL1_WR_HC)
    begin
        case FIFO_CYCLE is
            when IDLE =>
                if ATL_RD_MC_I = '1' then
                    NEXT_FIFO_CYCLE <= MC_ATL_READ_LO;
                elsif ATL_WR_MC_I = '1' then
                    NEXT_FIFO_CYCLE <= MC_ATL_WRITE_LO;
                elsif ITL0_RD_MC = '1' then
                    NEXT_FIFO_CYCLE <= MC_ITL0_READ_LO;
                elsif ITL0_WR_MC = '1' then
                    NEXT_FIFO_CYCLE <= MC_ITL0_WRITE_LO;
                elsif ITL1_RD_MC = '1' then
                    NEXT_FIFO_CYCLE <= MC_ITL1_READ_LO;
                elsif ITL1_WR_MC = '1' then
                    NEXT_FIFO_CYCLE <= MC_ITL1_WRITE_LO;
                elsif ATL_RD_HC_I = '1' then
                    NEXT_FIFO_CYCLE <= HC_ATL_READ_LO;
                elsif ATL_WR_HC_I = '1' then
                    NEXT_FIFO_CYCLE <= HC_ATL_WRITE_LO;
                elsif ITL0_RD_HC = '1' then
                    NEXT_FIFO_CYCLE <= HC_ITL0_READ_LO;
                elsif ITL0_WR_HC = '1' then
                    NEXT_FIFO_CYCLE <= HC_ITL0_WRITE_LO;
                elsif ITL1_RD_HC = '1' then
                    NEXT_FIFO_CYCLE <= HC_ITL1_READ_LO;
                elsif ITL1_WR_HC = '1' then
                    NEXT_FIFO_CYCLE <= HC_ITL1_WRITE_LO;
                else
                    NEXT_FIFO_CYCLE <= IDLE;
                end if;
            when MC_ATL_READ_LO =>
                NEXT_FIFO_CYCLE <= MC_ATL_READ_HI;
            when MC_ATL_READ_HI =>
                NEXT_FIFO_CYCLE <= CHECK_HC;
            when MC_ATL_WRITE_LO =>
                NEXT_FIFO_CYCLE <= MC_ATL_WRITE_HI;
            when MC_ATL_WRITE_HI =>
                NEXT_FIFO_CYCLE <= CHECK_HC;
            when MC_ITL0_READ_LO =>
                NEXT_FIFO_CYCLE <= MC_ITL0_READ_HI;
            when MC_ITL0_READ_HI =>
                NEXT_FIFO_CYCLE <= CHECK_HC;
            when MC_ITL1_READ_LO =>
                NEXT_FIFO_CYCLE <= MC_ITL1_READ_HI;
            when MC_ITL1_READ_HI =>
                NEXT_FIFO_CYCLE <= CHECK_HC;
            when MC_ITL0_WRITE_LO =>
                NEXT_FIFO_CYCLE <= MC_ITL0_WRITE_HI;
            when MC_ITL0_WRITE_HI =>
                NEXT_FIFO_CYCLE <= CHECK_HC;
            when MC_ITL1_WRITE_LO =>
                NEXT_FIFO_CYCLE <= MC_ITL1_WRITE_HI;
            when MC_ITL1_WRITE_HI =>
                NEXT_FIFO_CYCLE <= CHECK_HC;
            when CHECK_HC =>
                if ATL_RD_HC_I = '1' then
                    NEXT_FIFO_CYCLE <= HC_ATL_READ_LO;
                elsif ATL_WR_HC_I = '1' then
                    NEXT_FIFO_CYCLE <= HC_ATL_WRITE_LO;
                elsif ITL0_RD_HC = '1' then
                    NEXT_FIFO_CYCLE <= HC_ITL0_READ_LO;
                elsif ITL0_WR_HC = '1' then
                    NEXT_FIFO_CYCLE <= HC_ITL0_WRITE_LO;
                elsif ITL1_RD_HC = '1' then
                    NEXT_FIFO_CYCLE <= HC_ITL1_READ_LO;
                elsif ITL1_WR_HC = '1' then
                    NEXT_FIFO_CYCLE <= HC_ITL1_WRITE_LO;
                else
                    NEXT_FIFO_CYCLE <= IDLE;
                end if;
            when HC_ATL_READ_LO =>
                NEXT_FIFO_CYCLE <= HC_ATL_READ_HI;
            when HC_ATL_READ_HI =>
                NEXT_FIFO_CYCLE <= IDLE;
            when HC_ATL_WRITE_LO =>
                NEXT_FIFO_CYCLE <= HC_ATL_WRITE_HI;
            when HC_ATL_WRITE_HI =>
                NEXT_FIFO_CYCLE <= IDLE;
            when HC_ITL0_READ_LO =>
                NEXT_FIFO_CYCLE <= HC_ITL0_READ_HI;
            when HC_ITL0_READ_HI =>
                NEXT_FIFO_CYCLE <= IDLE;
            when HC_ITL1_READ_LO =>
                NEXT_FIFO_CYCLE <= HC_ITL1_READ_HI;
            when HC_ITL1_READ_HI =>
                NEXT_FIFO_CYCLE <= IDLE;
            when HC_ITL0_WRITE_LO =>
                NEXT_FIFO_CYCLE <= HC_ITL0_WRITE_HI;
            when HC_ITL0_WRITE_HI =>
                NEXT_FIFO_CYCLE <= IDLE;
            when HC_ITL1_WRITE_LO =>
                NEXT_FIFO_CYCLE <= HC_ITL1_WRITE_HI;
            when HC_ITL1_WRITE_HI =>
                NEXT_FIFO_CYCLE <= IDLE;
        end case;
    end process STATE_DEC;

    BUFFER_LENGTH: process
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if RESET = '1' or HCR = '1' then
            RD_ITL0_BUFF_LENGTH <= (others => '0');
        elsif FIFO_CYCLE = HC_ITL0_WRITE_LO then
            RD_ITL0_BUFF_LENGTH <= RD_ITL0_BUFF_LENGTH + '1';
        elsif FIFO_CYCLE = HC_ITL0_WRITE_HI then
            RD_ITL0_BUFF_LENGTH <= RD_ITL0_BUFF_LENGTH + '1';
        elsif FIFO_CYCLE = MC_ITL0_READ_LO then
            RD_ITL0_BUFF_LENGTH <= RD_ITL0_BUFF_LENGTH - '1';
        elsif FIFO_CYCLE = MC_ITL0_READ_HI then
            RD_ITL0_BUFF_LENGTH <= RD_ITL0_BUFF_LENGTH - '1';
        end if;

        if RESET = '1' or HCR = '1' then
            RD_ITL1_BUFF_LENGTH <= (others => '0');
        elsif FIFO_CYCLE = HC_ITL1_WRITE_LO then
            RD_ITL1_BUFF_LENGTH <= RD_ITL1_BUFF_LENGTH + '1';
        elsif FIFO_CYCLE = HC_ITL1_WRITE_HI then
            RD_ITL1_BUFF_LENGTH <= RD_ITL1_BUFF_LENGTH + '1';
        elsif FIFO_CYCLE = MC_ITL1_READ_LO then
            RD_ITL1_BUFF_LENGTH <= RD_ITL1_BUFF_LENGTH - '1';
        elsif FIFO_CYCLE = MC_ITL1_READ_HI then
            RD_ITL1_BUFF_LENGTH <= RD_ITL1_BUFF_LENGTH - '1';
        end if;
    end process BUFFER_LENGTH;

    ADR_POINTER: process
    -- This address logic provides the ITL and ATL address pointers.
    -- Be aware that the pointers (HEAD, TAIL) are incremented after
    -- the respected 16 bit access. This address logic refers to the
    -- microcontroller interface access.
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;
        if RESET = '1' or HCR = '1' then
            ATL_HEAD <= x"000";
            ITL0_HEAD <= x"000";
            ITL1_HEAD <= x"000";
            ATL_TAIL <= x"000";
            ITL0_TAIL <= x"000";
            ITL1_TAIL <= x"000";
        else
            if FIFO_CYCLE = MC_ATL_READ_LO then
                ATL_HEAD <= x"000"; -- Initialize, see file header.
            elsif FIFO_CYCLE = MC_ATL_WRITE_LO then
                ATL_HEAD <= ATL_HEAD + '1';
            elsif FIFO_CYCLE = MC_ATL_WRITE_HI then
                ATL_HEAD <= ATL_HEAD + '1';
            end if;
    
            if FIFO_CYCLE = MC_ITL0_READ_LO then
                ITL0_HEAD <= x"000"; -- Initialize, see file header.
            elsif FIFO_CYCLE = MC_ITL0_WRITE_LO then
                ITL0_HEAD <= ITL0_HEAD + '1';
            elsif FIFO_CYCLE = MC_ITL0_WRITE_HI then
                ITL0_HEAD <= ITL0_HEAD + '1';
            end if;
    
            if FIFO_CYCLE = MC_ITL1_READ_LO then
                ITL1_HEAD <= x"000"; -- Initialize, see file header.
            elsif FIFO_CYCLE = MC_ITL1_WRITE_LO then
                ITL1_HEAD <= ITL1_HEAD + '1';
            elsif FIFO_CYCLE = MC_ITL1_WRITE_HI then
                ITL1_HEAD <= ITL1_HEAD + '1';
            end if;
    
            -- We increment early due to the one clock cycle FIFO delay.
            if FIFO_CYCLE = MC_ATL_WRITE_LO then
                ATL_TAIL <= x"000"; -- Initialize, see file header.
            elsif NEXT_FIFO_CYCLE = MC_ATL_READ_LO then
                ATL_TAIL <= ATL_TAIL + '1';
            elsif NEXT_FIFO_CYCLE = MC_ATL_READ_HI then
                ATL_TAIL <= ATL_TAIL + '1';
            end if;
    
            -- We increment early due to the one clock cycle FIFO delay.
            if FIFO_CYCLE = MC_ITL0_WRITE_LO then
                ITL0_TAIL <= x"000"; -- Initialize, see file header.
            elsif NEXT_FIFO_CYCLE = MC_ITL0_READ_LO then
                ITL0_TAIL <= ITL0_TAIL + '1';
            elsif NEXT_FIFO_CYCLE = MC_ITL0_READ_HI then
                ITL0_TAIL <= ITL0_TAIL + '1';
            end if;
    
            -- We increment early due to the one clock cycle FIFO delay.
            if FIFO_CYCLE = MC_ITL1_WRITE_LO then
                ITL1_TAIL <= x"000"; -- Initialize, see file header.
            elsif NEXT_FIFO_CYCLE = MC_ITL1_READ_LO then
                ITL1_TAIL <= ITL1_TAIL + '1';
            elsif NEXT_FIFO_CYCLE = MC_ITL1_READ_HI then
                ITL1_TAIL <= ITL1_TAIL + '1';
            end if;
        end if;
    end process ADR_POINTER;

    OUTPUT_BUFFERS: process
    -- The read buffers store the FIFO output in the respective
    -- byte order. Be aware that the FIFO has a one clock 
    -- address to output delay. 
    -- Hence, for the MC access the high order byte is stored one
    -- FIFO_CYCLE state after READ_HI and the low order byte is
    -- stored in the CHECK_HC state.
    -- For the HC access, the address is switched early (one
    -- clock cycle prior). So we need no delay for storing the
    -- buffer hi byte buffer. The low byte comes directly from
    -- the FIFO.
    begin
        wait until CLK_48MHz = '1' and CLK_48MHz' event;

        -- Even FIFO address is writen to the lower buffer byte.
        if FIFO_CYCLE = MC_ATL_READ_LO then
            BUFFER_OUT_MC(7 downto 0) <= FIFO_D_OUT;
        elsif FIFO_CYCLE = MC_ATL_READ_HI then
            BUFFER_OUT_MC(15 downto 8) <= FIFO_D_OUT;
        elsif FIFO_CYCLE = MC_ITL0_READ_LO or FIFO_CYCLE = MC_ITL1_READ_LO then
            BUFFER_OUT_MC(7 downto 0) <= FIFO_D_OUT;
        elsif FIFO_CYCLE = MC_ITL0_READ_HI or FIFO_CYCLE = MC_ITL1_READ_HI then
            BUFFER_OUT_MC(15 downto 8) <= FIFO_D_OUT;
        end if;

        -- Even FIFO address is writen to the lower buffer byte.
        if FIFO_CYCLE = HC_ATL_READ_LO then
            BUFFER_OUT_HC(7 downto 0) <= FIFO_D_OUT;
        elsif FIFO_CYCLE = HC_ITL0_READ_LO or FIFO_CYCLE = HC_ITL1_READ_LO then
            BUFFER_OUT_HC(7 downto 0) <= FIFO_D_OUT;
        end if;
    end process OUTPUT_BUFFERS;

    BUFFER_OUT_HC(15 downto 8) <= FIFO_D_OUT;
    BUFFER_RDY_HC <= '1' when FIFO_CYCLE = HC_ATL_READ_HI or FIFO_CYCLE = HC_ITL0_READ_HI or FIFO_CYCLE = HC_ITL1_READ_HI else
                     '1' when FIFO_CYCLE = HC_ATL_WRITE_HI or FIFO_CYCLE = HC_ITL0_WRITE_HI or FIFO_CYCLE = HC_ITL1_WRITE_HI else '0';

    FIFO_ADR <= -- MC: (switched early for read access).
                ITL0_HEAD when FIFO_CYCLE = MC_ITL0_WRITE_LO else
                ITL0_HEAD when FIFO_CYCLE = MC_ITL0_WRITE_HI else
                ITL0_TAIL when NEXT_FIFO_CYCLE = MC_ITL0_READ_LO else
                ITL0_TAIL when NEXT_FIFO_CYCLE = MC_ITL0_READ_HI else
                ITL_BUFF_LEN(11 downto 0) + ITL1_HEAD when FIFO_CYCLE = MC_ITL1_WRITE_LO else
                ITL_BUFF_LEN(11 downto 0) + ITL1_HEAD when FIFO_CYCLE = MC_ITL1_WRITE_HI else
                ITL_BUFF_LEN(11 downto 0) + ITL1_TAIL when NEXT_FIFO_CYCLE = MC_ITL1_READ_LO else
                ITL_BUFF_LEN(11 downto 0) + ITL1_TAIL when NEXT_FIFO_CYCLE = MC_ITL1_READ_HI else
                (ITL_BUFF_LEN(10 downto 0) & '0') + ATL_HEAD when FIFO_CYCLE = MC_ATL_WRITE_LO else -- 2*ITL_BUFF_LEN + pointer.
                (ITL_BUFF_LEN(10 downto 0) & '0') + ATL_HEAD when FIFO_CYCLE = MC_ATL_WRITE_HI else -- 2*ITL_BUFF_LEN + pointer.
                (ITL_BUFF_LEN(10 downto 0) & '0') + ATL_TAIL when NEXT_FIFO_CYCLE = MC_ATL_READ_LO else -- 2*ITL_BUFF_LEN + pointer.
                (ITL_BUFF_LEN(10 downto 0) & '0') + ATL_TAIL when NEXT_FIFO_CYCLE = MC_ATL_READ_HI else -- 2*ITL_BUFF_LEN + pointer.
                -- HC: (switched early for read access).
                HC_ADR when FIFO_CYCLE = HC_ITL0_WRITE_LO else
                HC_ADR when NEXT_FIFO_CYCLE = HC_ITL0_READ_LO else
                ITL_BUFF_LEN(11 downto 0) + HC_ADR when FIFO_CYCLE = HC_ITL1_WRITE_LO else
                ITL_BUFF_LEN(11 downto 0) + HC_ADR when NEXT_FIFO_CYCLE = HC_ITL1_READ_LO else
                (ITL_BUFF_LEN(10 downto 0) & '0') + HC_ADR when FIFO_CYCLE = HC_ATL_WRITE_LO else
                (ITL_BUFF_LEN(10 downto 0) & '0') + HC_ADR when NEXT_FIFO_CYCLE = HC_ATL_READ_LO else
                HC_ADR + '1' when FIFO_CYCLE = HC_ITL0_WRITE_HI else
                HC_ADR + '1' when NEXT_FIFO_CYCLE = HC_ITL0_READ_HI else
                ITL_BUFF_LEN(11 downto 0) + HC_ADR + '1' when FIFO_CYCLE = HC_ITL1_WRITE_HI else
                ITL_BUFF_LEN(11 downto 0) + HC_ADR + '1' when NEXT_FIFO_CYCLE = HC_ITL1_READ_HI else
                (ITL_BUFF_LEN(10 downto 0) & '0') + HC_ADR + '1' when FIFO_CYCLE = HC_ATL_WRITE_HI else
                (ITL_BUFF_LEN(10 downto 0) & '0') + HC_ADR + '1';

    -- The buffer is written with the lower byte at even FIFO addresses.
    FIFO_D_IN <= BUFFER_IN_MC(7 downto 0) when FIFO_CYCLE = MC_ATL_WRITE_LO or FIFO_CYCLE = MC_ITL0_WRITE_LO or FIFO_CYCLE = MC_ITL1_WRITE_LO else 
                 BUFFER_IN_MC(15 downto 8) when FIFO_CYCLE = MC_ATL_WRITE_HI or FIFO_CYCLE = MC_ITL0_WRITE_HI or FIFO_CYCLE = MC_ITL1_WRITE_HI else 
                 BUFFER_IN_HC(7 downto 0) when FIFO_CYCLE = HC_ATL_WRITE_LO or FIFO_CYCLE = HC_ITL0_WRITE_LO or FIFO_CYCLE = HC_ITL1_WRITE_LO else BUFFER_IN_HC(15 downto 8);
    
    FIFO_WR <= '1' when FIFO_CYCLE = MC_ATL_WRITE_LO or FIFO_CYCLE = MC_ATL_WRITE_HI or FIFO_CYCLE = MC_ITL0_WRITE_LO or FIFO_CYCLE = MC_ITL0_WRITE_HI or FIFO_CYCLE = MC_ITL1_WRITE_LO or FIFO_CYCLE = MC_ITL1_WRITE_HI else
               '1' when FIFO_CYCLE = HC_ATL_WRITE_LO or FIFO_CYCLE = HC_ATL_WRITE_HI or FIFO_CYCLE = HC_ITL0_WRITE_LO or FIFO_CYCLE = HC_ITL0_WRITE_HI or FIFO_CYCLE = HC_ITL1_WRITE_LO or FIFO_CYCLE = HC_ITL1_WRITE_HI else '0'; 

    FIFO_RAM: process(CLK_48MHz, FIFO)
    variable FIFO_ADR_PNTR  : integer range 0 to 4095;
    begin
        if CLK_48MHz = '1' and CLK_48MHz' event then
            FIFO_ADR_PNTR := To_Integer(unsigned(FIFO_ADR));
            if FIFO_WR = '1' then
                FIFO(FIFO_ADR_PNTR) <= FIFO_D_IN;
            end if;
        end if;
        FIFO_D_OUT <= FIFO(FIFO_ADR_PNTR);
    end process FIFO_RAM;
end architecture BEHAVIOUR;
