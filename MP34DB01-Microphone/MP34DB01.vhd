------------------------------------------------------------------------
----                                                                ----
----  MP34DB01 controller.                                          ----
----                                                                ----
----  Author: Jens Carroll, Wolfgang Foerster                       ----
----          support@inventronk.de                                 ----
----          www.inventronik.de                                    ----
----                                                                ----
----                                                                ----
---- Description:                                                   ----
----  This module provides a controller for a MP34DB01 digital      ----
----  microphone with PDM output. The resolution is 16 bit.         ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2015... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- straﬂe 48, 70199 Stuttgart, wf@inventronik.de.                 ----
---- All rights reserved. No portion of this sourcecode may be      ----
---- reproduced or transmitted in any form by any means, whether    ----
---- by electronic, mechanical, photocopying, recording or          ----
---- otherwise, without my written permission.                      ----
----                                                                ----
------------------------------------------------------------------------
-- 
-- Revision History:
-- 
-- Revision 2K15B  20151224 WF
--   Initial release.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity MP34DB01 is
    port(
        CLK             : in std_logic; -- Use 2MHz.

        DATA            : out std_logic_vector(15 downto 0);
        
        MP34DB01_CLK    : out std_logic;
        MP34DB01_LR     : out std_logic;
        MP34DB01_D      : in std_logic
        );
end entity MP34DB01;

architecture BEHAVIOUR of MP34DB01 is
begin
    MP34DB01_LR <= '0';

    CLOCKOUT: process
    variable MP34DB01_CLK_I : std_logic;
    begin
        wait until CLK = '1' and CLK' event;
        MP34DB01_CLK_I := not MP34DB01_CLK_I;
        MP34DB01_CLK <= MP34DB01_CLK_I;
    end process CLOCKOUT;

    PDM: process
    variable RESOLUTION : std_logic_vector(15 downto 0);
    variable PDM_CNT    : std_logic_vector(15 downto 0);
    begin
        wait until CLK = '1' and CLK' event;
        RESOLUTION := RESOLUTION + '1';
        
        if RESOLUTION = x"FFFF" then
            DATA <= PDM_CNT;
            PDM_CNT := x"0000";
        else
            case MP34DB01_D is
                when '1' => PDM_CNT := PDM_CNT + '1';
                when others => null;
            end case;
        end if;
    end process PDM;
end architecture BEHAVIOUR;
