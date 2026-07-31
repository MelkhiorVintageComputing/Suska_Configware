# Copyright © 2020... Wolfgang Foerster - Inventronik GmbH.
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

create_clock -period 62.500 -name CLK_IN6 [get_ports {CLK_IN6}]
create_clock -period 62.500 -name CLK_IN8 [get_ports {CLK_IN8}]

derive_pll_clocks -use_net_name
derive_clock_uncertainty

set_clock_groups -exclusive -group {CLK_IN6}
set_clock_groups -exclusive -group {CLK_IN8}
