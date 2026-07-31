------------------------------------------------------------------------
----                                                                ----
---- ATARI ST BLITTER compatible IP Core			                ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- ATARI ST and STE compatible Bit Block Transfer Processor	    ----
---- (BLITTER) IP core.									            ----
----                                                                ----
---- Top level file with component declarations.		            ----
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
-- Revision 2K6B	2006/11/05 WF
--   Modified Source to compile with the Xilinx ISE.
--   Changed several bus controls from open drain to tri state.
-- Revision 2K8B  2008/12/24 WF
--   Rewritten this top level file as a wrapper for the top_soc file.
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
-- Revision 2K21A 20211224 WF
--   Blitter can now handle 32 address bits.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity WF101643IP_TOP is
	port (
		-- System controls:
		CLK		: in std_logic;
		RESETn	: in std_logic;
		ASn		: inout std_logic;
		LDSn	: inout std_logic;
		UDSn	: inout std_logic;
		RWn		: inout std_logic;
		DTACKn	: inout std_logic; -- Open drain.
		BERRn	: in std_logic;
		FC		: inout std_logic_vector(2 downto 0);
		INTn	: out std_logic;

		-- The bus:
		ADR		: inout std_logic_vector(31 downto 1);
		DATA	: inout std_logic_vector(15 downto 0);

		-- Bus arstd_logicration:
		BGIn	: in std_logic;
		BGKIn	: in std_logic; -- Open drain.
		BRn		: out std_logic; -- Open drain.
		BGACKn	: inout std_logic; -- Open drain.
		BGOn	: out std_logic
	);
end entity WF101643IP_TOP;

architecture STRUCTURE of WF101643IP_TOP is
component WF101643IP_TOP_SOC
	port (
		CLK			: in std_logic;
		RESETn		: in std_logic;
		AS_INn		: in std_logic;
		AS_OUTn		: out std_logic;
		LDS_INn		: in std_logic;
		LDS_OUTn	: out std_logic;
		UDS_INn		: in std_logic;
		UDS_OUTn	: out std_logic;
		RWn_IN		: in std_logic;
		RWn_OUT		: out std_logic;
		DTACK_INn	: in std_logic;
		DTACK_OUTn	: out std_logic;
		BERRn		: in std_logic;
		FC_IN		: in std_logic_vector(2 downto 0);
		FC_OUT		: out std_logic_vector(2 downto 0);
		BUSCTRL_EN	: out std_logic;
		INTn		: out std_logic;
		ADR_IN		: in std_logic_vector(31 downto 1);
		ADR_OUT		: out std_logic_vector(31 downto 1);
		ADR_EN		: out std_logic;
		DATA_IN		: in std_logic_vector(15 downto 0);
		DATA_OUT	: out std_logic_vector(15 downto 0);
		DATA_EN		: out std_logic;
		BGIn		: in std_logic;
		BGKIn		: in std_logic;
		BRn			: out std_logic;
		BGACK_INn	: in std_logic;
		BGACK_OUTn	: out std_logic;
		BGOn		: out std_logic
	);
end component;
--
signal AS_OUTn		    : std_logic;
signal LDS_OUTn	        : std_logic;
signal UDS_OUTn	        : std_logic;
signal RWn_OUT		    : std_logic;
signal DTACK_OUTn       : std_logic;
signal BUSCTRL_EN_I     : std_logic;
signal FC_OUT           : std_logic_vector(2 downto 0);
signal ADR_OUT          : std_logic_vector(31 downto 1);
signal ADR_EN_I         : std_logic;
signal DATA_OUT         : std_logic_vector(15 downto 0);
signal DATA_EN_I        : std_logic;
signal BR_In	        : std_logic;
signal BGACK_OUTn       : std_logic;
begin
    DTACKn <= '0' when DTACK_OUTn = '0' else 'Z'; -- Open drain.
    RWn <= RWn_OUT when BUSCTRL_EN_I = '1' else'Z';
    ASn <= AS_OUTn when BUSCTRL_EN_I = '1' else 'Z';
    LDSn <= LDS_OUTn when BUSCTRL_EN_I = '1' else 'Z';
    UDSn <= UDS_OUTn when BUSCTRL_EN_I = '1' else 'Z';
    FC <= FC_OUT when BUSCTRL_EN_I = '1' else "ZZZ";

    ADR <= ADR_OUT when ADR_EN_I = '1' else (others => 'Z');
    DATA <= DATA_OUT when DATA_EN_I = '1' else (others => 'Z');

    BRn <= '0' when BR_In = '0' else 'Z';
    BGACKn <= '0' when BGACK_OUTn = '0' else 'Z';

    I_BLITTER: WF101643IP_TOP_SOC
        port map(CLK                => CLK,
                 RESETn             => RESETn,
                 AS_INn             => ASn,
                 AS_OUTn            => AS_OUTn,
                 LDS_INn            => LDSn,
                 LDS_OUTn           => LDS_OUTn,
                 UDS_INn            => UDSn,
                 UDS_OUTn           => UDS_OUTn,
                 RWn_IN             => RWn,
                 RWn_OUT            => RWn_OUT,
                 DTACK_INn          => DTACKn,
                 DTACK_OUTn         => DTACK_OUTn,
                 BERRn		        => BERRn,
                 FC_IN		        => FC,
                 FC_OUT		        => FC_OUT,
                 BUSCTRL_EN         => BUSCTRL_EN_I,
                 INTn		        => INTn,
                 ADR_IN		        => ADR,
                 ADR_OUT		    => ADR_OUT,
                 ADR_EN		        => ADR_EN_I,
                 DATA_IN		    => DATA,
                 DATA_OUT	        => DATA_OUT,
                 DATA_EN		    => DATA_EN_I,
                 BGIn		        => BGIn,
                 BGKIn		        => BGKIn,
                 BRn			    => BR_In,
                 BGACK_INn	        => BGACKn,
                 BGACK_OUTn	        => BGACK_OUTn,
                 BGOn		        => BGOn
        );
end architecture STRUCTURE;