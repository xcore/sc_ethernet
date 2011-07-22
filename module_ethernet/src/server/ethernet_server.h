/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    ethernet_server.h
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2009
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
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
