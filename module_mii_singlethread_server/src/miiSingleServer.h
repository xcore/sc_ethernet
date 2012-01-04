#include "miiDriver.h"

void miiSingleServer(clock clk_smi,
                     out port ?p_mii_resetn,
                     smi_interface_t &smi,
                     mii_interface_t &m,
                     chanend appIn, chanend appOut, chanend server,
                     char mac_address[6]);
