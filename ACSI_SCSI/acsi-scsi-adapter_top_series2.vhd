------------------------------------------------------------------------
----                                                                ----
---- ATARI IP Core peripheral Add-On				                ----
----                                                                ----
---- This file is part of the FPGA-ATARI project.                   ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- This hardware provides limeted SCSI functionality. It works    ----
---- as an add-on to the ACSI bus (ACSI-SCSI bridge).               ----
---- Linitations: There are only class 0 SCSI COMMANDs possible.    ----
----                                                                ----
---- This moddeling is inspired by a sketch (unknown author) of a   ----
---- ACSI to SCSI bridge. This sketch can be found in the docu-     ----
---- mentation of this core under 'ACSI-SCSI-Bridge'. It is also    ----
---- inspired by the original Atari ACSI-SCSI controller. The       ----
---- document is entitled "Atari ACSI/DMA Integration Guide".       ----
---- Thanks to Miroslav Nohaj 'Jookie' which did give me the        ----
---- information to find these documents.                           ----
---- The main difference of this core to all other known approa-    ----
---- ches is it's synchronous design. The core works well with      ----
---- for example 32MHz. This frequency is not necessarily syn-      ----
---- chronous to other system clocks. So use a system clock for     ----
---- it or produce the clock for example from a phase locked loop.  ----
---- The bridge features initiator identification and parity.       ----
----                                                                ----
---- The SCSI_IDn is a switch to SELCT the initiator ID of the      ----
---- SCSI controller of this core. It is inverted, so use weak      ----
---- pull up resistors for it and connect the switch to GND. In     ----
---- this case (all switches on) the SCSI_IDn of "000" will         ----
---- indicate the highest initiator id of 7.                        ----
----                                                                ----
---- It is possible to use ACSI and SCSI devices together if the    ----
---- SCSI and ACSI switch settings are correct. The adapter usage   ----
---- is identical to the original Atari ACSI-SCSI adapters.         ----
----                                                                ----
----   Recommendings for the hardware target concerning the SCSI    ----
----    interface:                                                  ----
----     Use for the outputs non inverting buffers ('541).          ----
----     Use for the data outputs tri state buffers ('541).         ----
----     Use for the data inputs tri state buffers ('541).          ----
----     SELCT for the output buffers a supply of +5V.              ----
----     SELCT for the data output buffers a supply of +5V.         ----
----     SELCT for the input buffers a supply of VCCIO of the       ----
----       SELCTed programmable logic device.                       ----
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
----	SCSI connector pinout:									    ----
----	Pin-Nr.		Name		Remarks							    ----
----	  50		I_On										    ----
----	  48		REQn										    ----
----	  46		D_Cn										    ----
----	  44		SELn										    ----
----	  42		MSGn										    ----
----	  40		RSTn										    ----
----	  38		ACKn										    ----
----	  36		BUSYn										    ----
----	  34		reserved	no connection			 		    ----
----	  32		ATNn		Pullup 220 Ohm to VCC			    ----
----	  30		reserved	no connection			 		    ----
----	  28		reserved	no connection			 		    ----
----	  26		TERMPWR		Hardwired to VCC				    ----
----	  24		reserved	no connection			 		    ----
----	  22		reserved	no connection					    ----
----	  20		reserved	no connection					    ----
----	  18		DPn			open drain                          ----
----	  16		SCSI_D7n	open drain                          ----
----	  14		SCSI_D6n	open drain                          ----
----	  12		SCSI_D5n	open drain                          ----
----	  10		SCSI_D4n	open drain                          ----
----	  8			SCSI_D3n	open drain                          ----
----	  6			SCSI_D2n	open drain                          ----
----	  4			SCSI_D1n	open drain                          ----
----	  2			SCSI_D0n	open drain                          ----
----															    ----
----	  25		reserved	no connection			 		    ----
----	  1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 27	GND		    ----
----	  29, 31, 33, 35, 37, 39, 41, 43, 46, 47, 49	GND		    ----
----															    ----
------------------------------------------------------------------------
---- This hardware works with the original ATARI				    ----
---- hard dik driver.											    ----
------------------------------------------------------------------------
-- 
-- Revision History
-- 
-- Revision 1.0  2005/09/10 WF
--   Initial Release.
-- Revision 1.1  2007/01/05 WF
--   Introduced SCSI parity.
--   Introduced Initiator identification.
--   Minor corrections.
-- Revision 2K8B 2008/12/24 WF
--   Rewritten this top level file as a wrapper for the top_soc file.
-- Revision 2K12A 20120620 WF
--   Merged to a MAX-V device.
-- Revision 2K13A 20120620 WF
--   Changed the ACSI_RDn and ACSI_WRn logic.
-- Revision 2K13A 20130620 WF
--   WF_ACSI_SCSI_IF_SOC: changed the selection timeout to work without TIMEOUT.
--   WF_ACSI_SCSI_IF_SOC: some additional minor changes.
-- Revision 2K15B 20151224 WF
--   Replaced the data Type bit by std_logic.
-- Revision 2K18A 20180620 WF
--   Changes due to the new hardware version.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF_ACSI_SCSI_IF is
port (  CLK		        : in std_logic; -- 16MHz recommended.

		-- ACSI section:		
		CR_Wn		    : in std_logic;
		CA1			    : in std_logic;
		HDCSn		    : in std_logic;
		HDACKn		    : in std_logic;
		HDINTn		    : out std_logic;
		HDRQn		    : out std_logic;
		ACSI_D		    : inout std_logic_vector(7 downto 0);
        ACSI_RESn       : in std_logic;
        ACSI_BUFFERn    : out std_logic;
        ACSI_D_EN       : out std_logic;
        ACSI_CTRL_ENn   : out std_logic;
        
		-- SCSI section:
		SCSI_BUSYn	    : in std_logic;
		SCSI_MSGn	    : in std_logic;
		SCSI_REQn	    : in std_logic;
		SCSI_DCn	    : in std_logic;
		SCSI_IOn	    : in std_logic;
		SCSI_RSTn	    : out std_logic;
		SCSI_ACKn	    : out std_logic;
		SCSI_SELn	    : out std_logic;
		SCSI_ATNn	    : out std_logic;
		SCSI_DP_IN 	    : in std_logic;
		SCSI_DP_OUT 	: out std_logic;
		SCSI_D	        : inout std_logic_vector(7 downto 0);
        SCSI_BUFFERn    : out std_logic;
        SCSI_D_EN       : out std_logic;
        SCSI_CTRL_ENn   : out std_logic;
        
		-- Others:
		SCSI_IDn	    : in std_logic_vector(2 downto 0); -- This is the initiator ID.
        P24             : out std_logic; -- Debugging.
        P25             : out std_logic -- Debugging.
      );
end WF_ACSI_SCSI_IF;

architecture BEHAVIOR of WF_ACSI_SCSI_IF is
component WF_ACSI_SCSI_IF_SOC
	port (  
		RESETn		    : in std_logic;
		CLK			    : in std_logic;
		CR_Wn		    : in std_logic;
		CA1			    : in std_logic;
		HDCSn		    : in std_logic;
		HDACKn		    : in std_logic;
		HDINTn		    : out std_logic;
		HDRQn		    : out std_logic;
		ACSI_D_IN	    : in std_logic_vector(7 downto 0);
		ACSI_D_OUT	    : out std_logic_vector(7 downto 0);
		ACSI_D_EN	    : out std_logic;
        ACSI_CTRL_ENn   : out std_logic;
		SCSI_BUSYn		: in std_logic;
		SCSI_MSGn		: in std_logic;
		SCSI_REQn		: in std_logic;
		SCSI_DCn		: in std_logic;
		SCSI_IOn		: in std_logic;
		SCSI_RSTn		: out std_logic;
		SCSI_ACKn		: out std_logic;
		SCSI_SELn		: out std_logic;
		SCSI_ATNn	    : out std_logic;
		SCSI_DP_IN 		: in std_logic;
		SCSI_DP_OUT     : out std_logic;
		SCSI_D_IN		: in std_logic_vector(7 downto 0);
		SCSI_D_OUT		: out std_logic_vector(7 downto 0);
		SCSI_D_EN		: out std_logic;
		SCSI_CTRL_EN	: out std_logic;
		SCSI_IDn		: in std_logic_vector(2 downto 0);
        P24             : out std_logic;
        P25             : out std_logic
      );
end component;
--
signal ACSI_D_OUT	    : std_logic_vector(7 downto 0);
signal ACSI_D_EN_I      : std_logic;
signal RESETn           : std_logic;
signal SCSI_D_OUT	    : std_logic_vector(7 downto 0);
signal SCSI_D_EN_I      : std_logic;
signal SCSI_CTRL_EN     : std_logic;

begin
    P_RESET: process
    variable RTIMER : integer range 0 to 255;
    begin
        wait until CLK = '1' and CLK' event;
        if RTIMER < 255 then
            RTIMER := RTIMER + 1;
            RESETn <= '0';
        else
            RESETn <= ACSI_RESn;
        end if;
    end process P_RESET;
    
    ACSI_D <= ACSI_D_OUT when ACSI_D_EN_I = '1' else (others => 'Z');
    ACSI_BUFFERn <= '0'; -- Always enabled.
    ACSI_D_EN <= ACSI_D_EN_I;

    SCSI_D <= SCSI_D_OUT when SCSI_D_EN_I = '1' else (others => 'Z');
    SCSI_BUFFERn <= '0'; -- Always enabled.
    SCSI_D_EN <= SCSI_D_EN_I;
    SCSI_CTRL_ENn <= not SCSI_CTRL_EN;

    I_ACSI_SCSI: WF_ACSI_SCSI_IF_SOC
        port map(RESETn		        => RESETn,
                 CLK			    => CLK,
                 CR_Wn		        => CR_Wn,
                 CA1			    => CA1,
                 HDCSn		        => HDCSn,
                 HDACKn		        => HDACKn,
                 HDINTn		        => HDINTn,
                 HDRQn		        => HDRQn,
                 ACSI_D_IN	        => ACSI_D,
                 ACSI_D_OUT	        => ACSI_D_OUT,
                 ACSI_D_EN	        => ACSI_D_EN_I,
                 ACSI_CTRL_ENn      => ACSI_CTRL_ENn,
                 SCSI_BUSYn		    => SCSI_BUSYn,
                 SCSI_MSGn		    => SCSI_MSGn,
                 SCSI_REQn		    => SCSI_REQn,
                 SCSI_DCn		    => SCSI_DCn,
                 SCSI_IOn		    => SCSI_IOn,
                 SCSI_RSTn		    => SCSI_RSTn,
                 SCSI_ACKn		    => SCSI_ACKn,
                 SCSI_SELn		    => SCSI_SELn,
                 SCSI_ATNn		    => SCSI_ATNn,
                 SCSI_DP_IN 		=> SCSI_DP_IN,
                 SCSI_DP_OUT 		=> SCSI_DP_OUT,
                 SCSI_D_IN		    => SCSI_D,
                 SCSI_D_OUT		    => SCSI_D_OUT,
                 SCSI_D_EN		    => SCSI_D_EN_I,
                 SCSI_CTRL_EN	    => SCSI_CTRL_EN,
                 SCSI_IDn		    => not SCSI_IDn,
                 P24                => P24,
                 P25                => P25
          );
end BEHAVIOR;
