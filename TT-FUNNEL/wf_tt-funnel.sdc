# Copyright © 2009... Wolfgang Foerster - Inventronik GmbH.
# All rights reserved. No portion of this sourcecode may be  
# reproduced or transmitted in any form by any means, whether
# by electronic, mechanical, photocopying, recording or      
# otherwise, without my written permission.                  
 
#**************************************************************
# Time Information
#**************************************************************

# set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name CLK -period 100.000 -waveform {0.000 50.000} [get_ports {CLK}]

#create_clock -period 5.000 -name DDR2_CLK [get_ports {DDR2_CLK}]

#derive_pll_clocks
#derive_pll_clocks -use_net_name
derive_clock_uncertainty

#set_clock_groups -exclusive -group {CLK_PLL1}
#set_clock_groups -exclusive -group {CLK_PLL2}
#set_clock_groups -exclusive -group {CODEC_SCLK}
