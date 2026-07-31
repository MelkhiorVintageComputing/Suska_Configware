------------------------------------------------------------------------
----                                                                ----
---- ATARI GLUE compatible IP Core					                ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Atari's COMBEL with all features to reach                      ----
---- ATARI Falcon compatibility.                                    ----
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
---- Copyright © 2009... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- All rights reserved. No portion of this sourcecode may be      ----
---- reproduced or transmitted in any form by any means, whether    ----
---- by electronic, mechanical, photocopying, recording or          ----
---- otherwise, without my written permission.                      ----
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
-- Revision 1.0  2009/12/24 WF
--   Initial Release.
-- Revision 2K21A 20211224 WF
--   Removed LDSn from DTACKn because the data register is word wide.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF_IDE is
	port (
        CLK             : in std_logic;
		RESET 			: in std_logic;

		ADR				: in std_logic_vector(31 downto 1);
        DATA_IN		    : in std_logic_vector(7 downto 0);
		
		ASn				: in std_logic;
        LDSn            : in std_logic;
		RWn				: in std_logic;
		DTACKn			: out std_logic;
		
		-- Interrupt:
		HDINTn		    : out std_logic;
		
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
    DTACKn <= '0' when ASn = '0' and ADR(31 downto 4) >= x"00F0000" and ADR(31 downto 4) < x"00F0004" and IDE_IORDY = '1' else '1';

	HDINTn <= '0' when IDE_INTRQ = '1' else '1';
    IDE_RESn <= not RESET;

	IDE_CMD: process
	-- This is the command register shadow. It is used to detect the IDE command
	-- 'IDENTIFY DRIVE' in which case the data may not be byte wise swapped.
	begin
		wait until CLK = '1' and CLK' event;
        if RESET = '1' then
            CMD_REG <= x"00";
        elsif ASn = '0' and ADR = x"00F0001" & "110" and RWn = '0' then -- Command register at x"F0001D".
            CMD_REG <= DATA_IN;
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
