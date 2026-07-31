# Copyright © 2010... Wolfgang Foerster - Inventronik GmbH.
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

# create_clock -name CLK -period 100.000 -waveform {0.000 50.000} [get_ports {CLK}]

create_clock -period 62.500 -name CLK_PLL1 [get_ports {CLK_PLL1}]
create_clock -period 62.500 -name CLK_PLL2 [get_ports {CLK_PLL2}]
create_clock -period 62.500 -name CRT_PIN4_CLK1 [get_ports {CRT_PIN4_CLK1}]
create_clock -period 81.400 -name CODEC_SCLK [get_ports {CODEC_SCLK}]

derive_pll_clocks -use_net_name
#derive_clock_uncertainty

set_clock_groups -exclusive -group {CLK_PLL1}
set_clock_groups -exclusive -group {CLK_PLL2}
set_clock_groups -exclusive -group {CODEC_SCLK}
