// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _ethernet_server_h_
#define _ethernet_server_h_

#include "smi.h"
#include "mii.h"

void phy_init(clock clk_smi,
              clock clk_mii_ref,
              out port ?p_mii_resetn,
              smi_interface_t &smi0,
              mii_interface_t &mii0);

void phy_init_two_port(clock clk_smi,
                       clock clk_mii_ref,
                       out port ?p_mii_resetn,
                       smi_interface_t &smi0,
                       smi_interface_t &smi1,
                       mii_interface_t &mii0,
                       mii_interface_t &mii1);

void ethernet_server(mii_interface_t &m,
                     clock clk_mii_ref,
                     int mac_address[],
                     chanend rx[],
                     int num_rx,
                     chanend tx[],
                     int num_tx,
                     smi_interface_t &?smi,
                     chanend ?connect_status);

void ethernet_server_two_port(mii_interface_t &mii1,
                              mii_interface_t &mii2,
                              clock clk_mii_ref,
                              int mac_address[],
                              chanend rx[],
                              int num_rx,
                              chanend tx[],
                              int num_tx,
                              smi_interface_t ?smi[2],
                              chanend ?connect_status);

#endif // _ethernet_server_h_
