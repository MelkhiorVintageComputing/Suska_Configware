# Copyright © 2011... Wolfgang Foerster - Inventronik GmbH.
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

create_clock -period 62.500 -name CLK [get_ports {CLK}]
create_clock -period 81.400 -name BIT_CLK [get_ports {BIT_CLK}]

#derive_clock_uncertainty

#derive_pll_clocks

#**************************************************************
# Clock Groups
#**************************************************************

#set_clock_groups -exclusive -group {CLK} -group {altera_reserved_tck}
set_clock_groups -exclusive -group {CLK}
set_clock_groups -exclusive -group {BIT_CLK}
