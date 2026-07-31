------------------------------------------------------------------------
----                                                                ----
---- ATARI compatible IP Core	    				                ----
----                                                                ----
---- This file is part of the FPGA-ATARI project.                   ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
------------------------------------------------------------------------
---- Description:                                                   ----
---- This VHDL model is based on PERA Putnik's IDE interface	    ----
---- (version 1998-12-23) but has full decoding of the respective   ----
---- address lines The address FC0000 is used twice in the STs.     ----
---- Using it byte wide, it is the selection register to switch     ----
---- to 16MHz (see Atari Hardware Register Listing). Using it       ----
---- word wide, it is the IDE controller data register. The UDSn    ----
---- bus control signal and the lower address lines 3 downto 1      ----
---- are not used for decoding of the FC0000 address. Thus, any     ----
---- dummy information is written to the IDE controller's data      ----
---- register when FC0000 is used byte wide. This does not affect   ----
---- the proper operation of the IDE port.                          ----
----                                                                ----
---- Use external bus drivers for the connection of the IDE data    ----
---- lines as follows:                                              ----
---- Use a 16 bit wide LVTTL tri state drivers to control the       ----
---- data direction from or to an IDE device.                       ----
---- The IDE_D_EN_INn and IDE_D_EN_OUTn outputs are the respective  ----
---- tri state enables where IDE_D_EN_INn controls the tri state    ----
---- for the read operation from an IDE device and IDE_D_EN_OUTn    ----
---- controls the write operation to an IDE device.                 ----
---- Select for the output buffers a supply of +5V.                 ----
---- Select for the input buffers a supply of VCCIO of the          ----
---- selected programmable logic device.                            ----
----															    ----
---- Be aware, that only TOS 2.06 or above operating system		    ----
---- versions check for IDE drives during boot process.			    ----
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
----															    ----
----	IDE connector pinout:									    ----
----	Pin-Nr.		Name		Remarks							    ----
----	  40		GND											    ----
----	  38		CS1n										    ----
----	  36		IDE_A2		Hardwired to ATARI adress bit A4    ----
----	  34		PDIAG										    ----
----	  32		reseved										    ----
----	  30		GND											    ----
----	  28		CSEL		Cable select, hardwired to GND	    ----
----	  26		GND											    ----
----	  24		GND											    ----
----	  22		GND											    ----
----	  20		keypin		No connection				 	    ----
----	  18		IDE_D15										    ----
----	  16		IDE_D14										    ----
----	  14		IDE_D13										    ----
----	  12		IDE_D12										    ----
----	  10		IDE_D11										    ----
----	  8			IDE_D10										    ----
----	  6			IDE_D9										    ----
----	  4			IDE_D8										    ----
----	  2			GND											    ----
----	  39		DASP		LED-Cathode, host's output		    ----
----	  37		CS0n										    ----
----	  35		IDE_A0		Hardwired to ATARI adress bit A2    ----
----	  33		IDE_A1		Hardwired to ATARI adress bit A3    ----
----	  31		INTRQ										    ----
----	  29		DMACKn		Wire via 100 Ohm to VCC			    ----
----	  27		IDE_IORDYn								        ----
----	  25		IORDn										    ----
----	  23		IOWRn										    ----
----	  21		DMARQ										    ----
----	  19		GND											    ----
----	  17		IDE_D0										    ----
----	  15		IDE_D1										    ----
----	  13		IDE_D2										    ----
----	  11		IDE_D3										    ----
----	  9			IDE_D4										    ----
----	  7			IDE_D5										    ----
----	  5			IDE_D6										    ----
----	  3			IDE_D7										    ----
----	  1			IDE_RESn									    ----
----															    ----
------------------------------------------------------------------------
-- 
-- Revision History
-- 
-- Revision 1.0  2005/09/10 WF
--   Initial Release.
-- Revision 1.1  2007/01/06 WF
--   Minor enhancements.
-- Revision 1.2  2008/06/16 WF
--   Modifications to meet the STBook compatibility.
-- Revision 2K8A  2008/07/14 WF
--   Minor changes.
-- Revision 2K8B  2008/12/24 WF
--   Bug fixes to get the thing working.
-- Revision 2K9B  2009/12/24 WF
--   Removed DMAn.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--   DTACKn is now in the correct address space.
-- Revision 2K21A 20211224 UMA
--   Removed LDSn from DTACKn because the data register is word wide.
--   Address bus is now 32 bit wide.
-- Revision 2K23A 20230620 UMA
--   Implemented Udo Matthe Shadow TOS.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF_IDE is
	port (
		RESETn			: in std_logic;
        CLK             : in std_logic;

		ADR				: in std_logic_vector(31 downto 1);
        DATA_IN		    : in std_logic_vector(7 downto 0);
		
		ASn				: in std_logic;
        LDSn            : in std_logic;
		RWn				: in std_logic;
		DTACKn			: out std_logic;
		
		-- Interrupt via ACSI:
		ACSI_HDINTn		: out std_logic;
		
		-- IDE section:
		IDE_INTRQ		: in std_logic;
		IDE_IORDY		: in std_logic;
		-- PDIAG		: in std_logic; -- Not used so far.
		-- DASP			: in std_logic; -- See pinout above.
		-- DMARQ		: in std_logic; -- Not used so far.
		-- DMACKn		: out std_logic; -- See pinout above.
		IDE_RESn		: out std_logic;
		CS0n			: out std_logic;
		CS1n			: out std_logic;
		IORDn			: out std_logic;
		IOWRn			: out std_logic;
		
        IDE_BYTESWAP    : out std_logic;
		IDE_D_EN_INn	: out std_logic;
		IDE_D_EN_OUTn	: out std_logic
      );
end WF_IDE;

architecture BEHAVIOR of WF_IDE is
signal CMD_REG	: std_logic_vector(7 downto 0);
begin
    DTACKn <= '0' when ASn = '0' and ADR & '0' >= x"00F00000" and ADR & '0' <= x"00F0003A" and IDE_IORDY = '1' else '1';

	ACSI_HDINTn <= '0' when IDE_INTRQ = '1' else '1';
    IDE_RESn <= RESETn;
    
	IDE_CMD: process(RESETn, CLK)
	-- This is the command register shadow. It is used to detect the IDE command
	-- 'IDENTIFY DRIVE' in which case the data may not be byte wise swapped.
	begin
        if RESETn = '0' then
            CMD_REG <= x"00";
		elsif CLK = '1' and CLK' event then
            if ASn = '0' and ADR = x"00F0001" & "110" and RWn = '0' then -- Command register at x"F0001D".
                CMD_REG <= DATA_IN;
            end if;
        end if;
	end process IDE_CMD;

    -- Data is bytewise swapped, if the command is not 'IDENTIFY DRIVE'.
    IDE_BYTESWAP <= '1' when ASn = '0' and ADR(31 downto 2) = x"00F0000" & "00" and CMD_REG /= x"EC" else '0'; -- The data register is Long.

    IOWRn <= '0' when ASn = '0' and LDSn = '0' and ADR(31 downto 4) = x"00F0000" and RWn = '0' else
             '0' when ASn = '0' and LDSn = '0' and ADR(31 downto 4) = x"00F0001" and RWn = '0' else
             '0' when ASn = '0' and LDSn = '0' and ADR(31 downto 4) = x"00F0002" and RWn = '0' else
             '0' when ASn = '0' and LDSn = '0' and ADR(31 downto 4) = x"00F0003" and RWn = '0' else '1';

    IORDn <= '0' when ASn = '0' and LDSn = '0' and ADR(31 downto 4) = x"00F0000" and RWn = '1' else
             '0' when ASn = '0' and LDSn = '0' and ADR(31 downto 4) = x"00F0001" and RWn = '1' else
             '0' when ASn = '0' and LDSn = '0' and ADR(31 downto 4) = x"00F0002" and RWn = '1' else
             '0' when ASn = '0' and LDSn = '0' and ADR(31 downto 4) = x"00F0003" and RWn = '1' else '1';

    CS0n <= '0' when ASn = '0' and ADR(31 downto 4) = x"00F0000" else
            '0' when ASn = '0' and ADR(31 downto 4) = x"00F0001" else '1';

    CS1n <= '0' when ASn = '0' and ADR(31 downto 4) = x"00F0002" else
            '0' when ASn = '0' and ADR(31 downto 4) = x"00F0003" else '1';

    IDE_D_EN_INn <= '0' when ASn = '0' and ADR(31 downto 4) = x"00F0000" and RWn = '1' else
                    '0' when ASn = '0' and ADR(31 downto 4) = x"00F0001" and RWn = '1' else
                    '0' when ASn = '0' and ADR(31 downto 4) = x"00F0002" and RWn = '1' else
                    '0' when ASn = '0' and ADR(31 downto 4) = x"00F0003" and RWn = '1' else '1';

    IDE_D_EN_OUTn <= '0' when ASn = '0' and ADR(31 downto 4) = x"00F0000" and RWn = '0' else
                     '0' when ASn = '0' and ADR(31 downto 4) = x"00F0001" and RWn = '0' else
                     '0' when ASn = '0' and ADR(31 downto 4) = x"00F0002" and RWn = '0' else
                     '0' when ASn = '0' and ADR(31 downto 4) = x"00F0003" and RWn = '0' else '1';
end BEHAVIOR;
