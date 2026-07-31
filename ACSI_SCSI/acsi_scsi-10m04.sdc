# Copyright © 2014... Wolfgang Foerster - Inventronik GmbH.
# All rights reserved. No portion of this sourcecode may be  
# reproduced or transmitted in any form by any means, whether
# by electronic, mechanical, photocopying, recording or      
# otherwise, without my written permission.                  
 
# Revision History
 
# Revision 2K05 WF
#   Initial Release.

#**************************************************************
# Time Information
#**************************************************************

# set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

# create_clock -name CLK -period 100.000 -waveform {0.000 50.000} [get_ports {CLK}]

create_clock -period 50.0000 -name CLK [get_ports {CLK}]

#derive_pll_clocks -use_net_name
derive_clock_uncertainty

#set_clock_groups -exclusive -group {CLK}
