# Copyright © 2008... Wolfgang Foerster - Inventronik GmbH.
# All rights reserved. No portion of this sourcecode may be  
# reproduced or transmitted in any form by any means, whether
# by electronic, mechanical, photocopying, recording or      
# otherwise, without my written permission.                  
 
# Revision History
 
# Revision 0.1 20140810 WF
#   Initial Release.
 

#**************************************************************
# Time Information
#**************************************************************

# set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

# create_clock -name CLK -period 100.000 -waveform {0.000 50.000} [get_ports {CLK}]
create_clock -period 32.000 -name CLK_32 [get_ports {CLK_32}]
create_clock -period 32.000 -name CLK_BLT [get_ports {CLK_BLT}]

derive_pll_clocks
#derive_pll_clocks -use_net_name
derive_clock_uncertainty

#set_clock_groups -exclusive -group {CLK_PLL1}
#set_clock_groups -exclusive -group {CLK_PLL2}
#set_clock_groups -exclusive -group {CODEC_SCLK}
