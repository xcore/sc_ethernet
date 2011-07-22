/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    eth_phy.h
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
#ifndef _eth_phy_h_
#define _eth_phy_h_
#include "smi.h"

int eth_phy_config(int eth100, smi_interface_t &smi);
int eth_phy_checklink(smi_interface_t &smi);
void eth_phy_loopback(int enable, smi_interface_t &smi);

#endif
