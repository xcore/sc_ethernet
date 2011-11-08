// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _smi_h_
#define _smi_h_

/* Initilisation of SMI ports
   Must be called first */
void smi_init(clock clk_smi, out port ?p_mii_resetn, smi_interface_t &smi);

/* Phy configuration
   If eth100 is non-zero, 100BaseT is advertised to the link peer
   Full duplex is always advertised
	 Returns 0 if no error and link established
	 Returns 1 on ID read error or config register readback error
	 Returns 2 if no error but link times out (3 sec) */
int eth_phy_config(int eth100, smi_interface_t &smi);

void smi_reset(out port ?p_mii_resetn, smi_interface_t &smi, timer tmr);

/* Cleanup of SMI ports */
void smi_deinit(clock clk_smi, out port ?p_mii_resetn, smi_interface_t &smi);

/* Enable/disable phy loopback */
void smi_loopback(int enable);

/* Returns Ethernet mode:
   0  10BaseT
   1  100BaseT */
int smi_is100();


int ethernet_is_connected();


#endif
