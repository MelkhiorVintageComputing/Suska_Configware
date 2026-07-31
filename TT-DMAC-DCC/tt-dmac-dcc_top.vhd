------------------------------------------------------------------------
----                                                                ----
---- This is the structural description (top level) of the TT DMAC  ----
---- and DCC chips.                                                 ----
----                                                                ----
----                                                                ----
---- Author(s):                                                     ----
---- - Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2013... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- All rights reserved. No portion of this sourcecode may be      ----
---- reproduced or transmitted in any form by any means, whether    ----
---- by electronic, mechanical, photocopying, recording or          ----
---- otherwise, without my written permission.                      ----
----                                                                ----
------------------------------------------------------------------------
-- 
-- Revision History
-- 
-- Revision 0.1 20131210 WF
--   Initial Release.
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity TT_DMAC_DCC is
    port (
        CLK             : in bit;
        
        -- Address and data:
        ADR_IN          : in std_logic_vector(31 downto 0);
        ADR_OUT         : out std_logic_vector(31 downto 0);
        FC_IN           : in std_logic_vector(2 downto 0);
        FC_OUT          : out std_logic_vector(2 downto 0);
        BUS_EN          : out bit; -- Enables ADR, FC , ASn, DSn, RWn and SIZE.
        DATA_IN         : in std_logic_vector(31 downto 0);
        DATA_OUT        : out std_logic_vector(31 downto 0);
        DATA_EN         : out bit;

        -- Aynchronous bus control:
        DSACKn          : in bit_vector(1 downto 0);
        SIZE            : out std_logic_vector(1 downto 0);
        ASn             : out bit;
        DSn             : out bit;
        RWn             : out std_logic;

        -- Synchronous bus control:
        STERMn          : in bit;

        -- Bus arbitration control:
        BRn             : out bit;
        BGIn            : in bit;
        BGOn            : out bit;
        BGACKn          : out bit

        -- System control:
        BERRn           : in bit;
        IRQn            : out bit;
        IACKn           : in bit;
        RESETn          : in bit;

        -- Peripheral controls:
        PD_IN           : in std_logic_vector(7 downto 0);
        PD_OUT          : out std_logic_vector(7 downto 0);
        PD_EN           : out bit;
        RDn             : out bit;
        WRn             : out bit;
        RQn_RQ          : in bit;
        DCn_DACKn       : out bit;
        ABn_EOPn        : out bit
    );
end entity TT_DMAC_DCC;
    
architecture STRUCTURE of TT_DMAC_DCC is
signal CEn              : bit;
signal PEn              : bit;
signal LDIn             : bit;
signal HOLDn            : bit;
signal LWRDn            : bit;
signal THRUn            : bit;
signal DAn              : bit_vector(1 downto 0);
signal CEn              : bit;
signal CEn              : bit;
signal CEn              : bit;
signal SCSI_SCCn        : bit;
signal S18x8            : bit;
begin
end architecture STRUCTURE;