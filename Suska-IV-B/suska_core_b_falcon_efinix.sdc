# Copyright © 2019... Wolfgang Foerster - Inventronik GmbH.
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

create_clock -period 62.500 -name CLK_16M0 [get_ports {CLK_16M0}]
create_clock -period 31.250 -name CLK_32M0 [get_ports {CLK_32M0}]
create_clock -period 20.083 -name CLK_48M0 [get_ports {CLK_48M0}]
create_clock -period 500.000 -name CLK_2M0 [get_ports {CLK_2M0}]

set_clock_groups -exclusive -group {CLK_16M0}
set_clock_groups -exclusive -group {CLK_32M0}
set_clock_groups -exclusive -group {CLK_48M0}
set_clock_groups -exclusive -group {CLK_2M0}

#derive_pll_clocks -use_net_name
#derive_clock_uncertainty
