/*************************************************************************
 *
 * Ethernet MAC Layer Implementation
 * IEEE 802.3 Serial Management Interface
 *
 *
 *************************************************************************
 *
 * Copyright (c) 2008 XMOS Ltd.
 *
 * Copyright Notice
 *
 *************************************************************************
 *
 * Functions for controlling Ethernet phy management interface.
 *
 *************************************************************************/

#ifndef _smi_h_
#define _smi_h_

/* Initilisation of SMI ports
   Must be called first */
void smi_init();

/* Phy configuration
   If eth100 is non-zero, 100BaseT is advertised to the link peer
   Full duplex is always advertised
	 Returns 0 if no error and link established
	 Returns 1 on ID read error or config register readback error
	 Returns 2 if no error but link times out (3 sec) */
int smi_config(int eth100);

/* Cleanup of SMI ports */
void smi_deinit();

/* Enable/disable phy loopback */
void smi_loopback(int enable);

/* Returns Ethernet mode:
   0  10BaseT
   1  100BaseT */
int smi_is100();

/* Direct SMI register access (for advanced use) */
int smi_rd(int reg);
void smi_wr(int reg, int val);

int ethernet_is_connected();

#endif
