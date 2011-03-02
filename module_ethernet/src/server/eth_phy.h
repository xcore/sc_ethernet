// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _eth_phy_h_
#define _eth_phy_h_
#include "smi.h"

int eth_phy_config(int eth100, smi_interface_t &smi);
int eth_phy_checklink(smi_interface_t &smi);
void eth_phy_loopback(int enable, smi_interface_t &smi);

#endif
