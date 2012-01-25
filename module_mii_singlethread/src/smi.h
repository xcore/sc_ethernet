// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _smi_h_
#define _smi_h_

#include <xs1.h>
#include <xccompat.h>

#include "miiDriver.h"

/* Initilisation of SMI ports
   Must be called first */
void smi_port_init(clock clk_smi, smi_interface_t &smi);

/* Phy configuration
   If eth100 is non-zero, 100BaseT is advertised to the link peer
   Full duplex is always advertised
	 Returns 0 if no error and link established
	 Returns 1 on ID read error or config register readback error
	 Returns 2 if no error but link times out (3 sec) */
int eth_phy_config(int eth100, smi_interface_t &smi);

/* Cleanup of SMI ports */
#define smi_deinit(a,b,c)              // not needed.

/* Enable/disable phy loopback */
void smi_loopback(int enable);

/* Perform a check for the SMI link enabled bit */
int eth_phy_checklink(smi_interface_t &smi);


#endif
