------------------------------------------------------------------------
----                                                                ----
---- ATARI GLUE compatible IP Core					                ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Atari's ST Glue with all features to reach                     ----
---- ATARI STE compatibility.                                       ----
----                                                                ----
---- Direct memory access (DMA) control state machine.              ----
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
---- Copyright © 2005... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K8A  2008/02/13 WF
--   Upgraded to version V1:
--     DMA_SYNC is now foreseen to synchronize the DMA
--     transfer between MCU, GLUE and DMA.
-- Revision 2K8B  2008/12/24 WF
--   Minor changes concerning DMA_SYNC.
-- Revision 2K9A  2009/06/20 WF
--   BRN_LOGIC process has now synchronous reset to provide preset requirement.
-- Revision 2K9B  2009/12/24 WF
--   Partially rewritten the bus arbiter, removed DMA_SYNC, improved
--     the bus timing for read and write operation.
--   Fixed a bug in the BRn_LOGIC process not to start the DMA operation unintendedly.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
-- Revision 2K20A  20200620 WF
--   Numerous changes in the arbiter to use The same time slices as in the MCU controller instead of SYNC states.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF25915IP_BUS_ARBITER is
port (  RESETn	        : in std_logic; -- ST's reset signal.
		CLK		        : in std_logic; -- the ST's 8MHz clock.

		-- D8 is used for the DMA mode register.
		D8		        : in std_logic; -- Data bus bit 8.
		
		RAMn            : in std_logic; -- Indicates RAM access.
		DTACKn		    : in std_logic; -- DTACKn gives information about the MMU state.

		-- ASn, LDSn, UDSn and RWn are asserted by the arbiter during 
		-- DMA transfer.
		AS_INn			: in std_logic;
		AS_OUTn			: out std_logic;
		RWn_OUT			: out std_logic;
		LDS_OUTn		: out std_logic;
		UDS_OUTn		: out std_logic;
        FC_OUT          : out std_logic_vector(2 downto 0);
		CTRL_EN			: out std_logic;

		-- Chip select signal for the DMA mode register. This signal
		-- is generated in the adress decoder.
	    DMA_MODE_CSn	: in std_logic;

		-- RDYn is asserted by the arbiter during DMA transfer.
		-- The other signals are used for DMA transfer control.
		RDY_INn		    : in std_logic; -- DMA unit ready signal.
		RDY_OUTn	    : out std_logic; -- DMA unit ready signal.
		BGACK_INn	    : in std_logic; -- Bus grant acknowledge input.
		BGACK_OUTn	    : out std_logic; -- Bus grant acknowledge output.
		BRn			    : out std_logic; -- Bus request (open drain).
		BGIn		    : in std_logic; -- Bus grant input.
		BGOn		    : out std_logic; -- Bus grant output.
		DMAn		    : out std_logic -- DMA select signal for the MMU.
      );
end WF25915IP_BUS_ARBITER;

architecture BEHAVIOR of WF25915IP_BUS_ARBITER is
type DMA_PHASES is (IDLE, READ, WRITE);
type MATRIX_ELEMENTS is array (1 to 7, 0 to 7) of std_logic;
constant TIME_MATRIX : MATRIX_ELEMENTS := 
    (('0','0','0','0','0','0','1','1'),  -- ASn.
     ('0','0','0','0','0','0','1','1'),  -- LDS_RDn.
     ('1','1','0','0','0','0','1','1'),  -- LDS_WRn.
     ('0','0','0','0','0','0','1','1'),  -- UDS_RDn.
     ('1','1','0','0','0','0','1','1'),  -- UDS_WRn.
	 ('1','0','0','1','1','1','1','1'),  -- RDYn for read from RAM.
     ('1','1','1','1','1','0','0','1')); -- RDYn for write to RAM.

signal DMA_PHASE		: DMA_PHASES;
signal SLICE_NUMBER     : integer range 0 to 7;
signal DMA_MODE			: std_logic; -- One bit register.
signal BR_In			: std_logic;
begin
	BRn <= BR_In;
	BGOn <= '0' when BGIn = '0' and BR_In = '1' else '1';
	BGACK_OUTn <= '1' when DMA_PHASE = IDLE else '0';

	DMAn <= '0' when DMA_PHASE /= IDLE else '1';

	DMA_MODE_REG: process
	-- This is the DMA mode register in the GLUE. it is a mirror of the 
	-- original DMA mode register (the original is 8 bit wide), located
	-- in the DMA unit. This register stores the information about the
	-- DMA data transfer direction. The STs adress of this register is
	-- FF8606. The register select signal DMA_MODE_CSn is decoded in the 
	-- adress decoder. This register is write only.
	begin
        wait until CLK = '1' and CLK' event;
		if RESETn = '0' then
			DMA_MODE <= '0'; -- Default is read from ACSI / Floppy.
		elsif DMA_MODE_CSn = '0' then
			DMA_MODE <= D8;
		end if;
	end process DMA_MODE_REG;

	BRn_LOGIC: process
	-- This logic is required, because the RDYn signal 
	-- coming from the DMA unit is shortly asserted for
	-- DMA register access. Not to start the DMA we have
	-- to provide this filter.
    variable RDY_COUNT: std_logic_vector(3 downto 0);
	begin
		wait until CLK = '1' and CLK' event;
		if RESETn = '0' then
			BR_In <= '1';
            RDY_COUNT := x"0";
        elsif RDY_INn = '1' and RDY_COUNT /= x"F" then
			RDY_COUNT := RDY_COUNT + '1'; -- RDYn condition detected.
		elsif RDY_INn = '0' then -- Restart the counter.
            RDY_COUNT := x"0";
		end if;
		case RDY_COUNT is
            when x"F" | x"E" | x"D" | x"C" | x"B" | x"A" | x"9" | x"8" => BR_In <= '0'; -- DMA condition detected.
			when others => BR_In <= '1';
		end case;
	end process BRn_LOGIC;

	DMA_CTRL: process
    -- State machine for DMA sequence detection. During the DMA sequence, the
    -- signals LDSn, UDSn, ASn, RDYn and RWn are controlled via this arbiter.
    -- 'ON' condition: the machine starts if there is a bus request from this
    -- arbiter, the bus grant input is asserted by the CPU (BGIn = '0'), the 
    -- bus request came from the GLUE (BR_In = '0'), the bus is free(ASn and
    -- DTACKn are not asserted) and there is no bus access by other devices
    -- (BGACKn = '1').
    -- 'OFF' condition: the machine stops, if the RDYn is asserted by the DMA
    -- chip during the ASn is controlled high by this arbiter.
	begin
		wait until CLK = '1' and CLK' event;
		if RESETn = '0' then
			DMA_PHASE <= IDLE;
        else
			case DMA_PHASE is
                when IDLE => -- Wait for arbitrated bus.
                    if BR_In = '0' and BGIn = '0' and BGACK_INn = '1' and AS_INn = '1' and DTACKn = '1' and SLICE_NUMBER = 6 and DMA_MODE = '1' then -- Start in 6 to enable MCU-DMA in 7.
                        DMA_PHASE <= READ;
                    elsif BR_In = '0' and BGIn = '0' and BGACK_INn = '1' and AS_INn = '1' and DTACKn = '1' and SLICE_NUMBER = 6 then -- Start in 6 to enable MCU-DMA in 7.
                        DMA_PHASE <= WRITE;
                    else
                        DMA_PHASE <= IDLE;
                    end if;
                when READ =>
					if RDY_INn = '0' and SLICE_NUMBER = 4 then -- Wait for the end of the DMA cycle in Slice 4.
                        DMA_PHASE <= IDLE;
                    else
                        DMA_PHASE <= READ;
                    end if;
                when WRITE =>
                    if RDY_INn = '0' then
                        DMA_PHASE <= IDLE;
                    else
                        DMA_PHASE <= WRITE;
                    end if;
			end case;
		end if;
	end process DMA_CTRL;

    TIME_SLICES: process
    -- This counter must be synchronous to the counter in the
    -- GLUE arbiter section. It is initialized during system reset.
    -- The counter is identical to the counter in the GLUE arbiter. 
    variable TIME_SLICE_CNT : std_logic_vector(2 downto 0);
    variable LOCK   : boolean;
    begin
        wait until CLK = '1' and CLK' event;
        if RESETn = '0' then
            LOCK := false;
        elsif RAMn = '0' and LOCK = false then -- Sync once!
            LOCK := true;
            TIME_SLICE_CNT := "111";
        else
            TIME_SLICE_CNT := TIME_SLICE_CNT + '1';
        end if;
        --
        SLICE_NUMBER <= conv_integer(TIME_SLICE_CNT);
    end process TIME_SLICES;

	AS_OUTn <= TIME_MATRIX(1, SLICE_NUMBER) when DMA_PHASE /= IDLE else '1';    
	LDS_OUTn <= TIME_MATRIX(2, SLICE_NUMBER) when DMA_PHASE = READ else
				TIME_MATRIX(3, SLICE_NUMBER) when DMA_PHASE = WRITE else '1';
	UDS_OUTn <= TIME_MATRIX(4, SLICE_NUMBER) when DMA_PHASE = READ else
				TIME_MATRIX(5, SLICE_NUMBER) when DMA_PHASE = WRITE else '1';
	RDY_OUTn <= TIME_MATRIX(6, SLICE_NUMBER) when DMA_PHASE = READ else 
				TIME_MATRIX(7, SLICE_NUMBER) when DMA_PHASE = IDLE and BR_In = '0' and BGIn = '0' and BGACK_INn = '1' and AS_INn = '1' and DTACKn = '1' and DMA_MODE = '0' else -- Enter WRITE, read FIFO first.
				TIME_MATRIX(7, SLICE_NUMBER) when DMA_PHASE = WRITE else '1';

	RWn_OUT <= '0' when DMA_PHASE = WRITE else '1';

    FC_OUT <= "001"; -- Declare the DMA data as user data.
	
    -- This enables the bus control signals in DMA mode.
    CTRL_EN <= '1' when DMA_PHASE /= IDLE else '0';
end BEHAVIOR;
