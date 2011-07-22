// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*************************************************************************
 *
 * Ethernet MAC Layer Implementation
 * IEEE 802.3 Serial Management Interface
 *
 *   File        : smi.h
 *
 *************************************************************************
 *************************************************************************
 *
 * Functions for controlling Ethernet phy management interface.
 *
 *************************************************************************/

#ifndef _smi_h_
#define _smi_h_
#include <xs1.h>
#include <xccompat.h>

#ifdef __XC__
typedef struct smi_interface_t {
  port p_smi_mdio;
  out port p_smi_mdc;
  int mdio_mux;
} smi_interface_t;
#else
typedef struct smi_interface_t {
  port p_smi_mdio;
  port p_smi_mdc;
  int mdio_mux;
} smi_interface_t;
#endif

#ifdef __XC__
/* Initilisation of SMI ports
   Must be called first */
void smi_init(clock clk_mii_ref, clock clk_smi, out port ?p_mii_resetn, smi_interface_t &smi);

/* Phy configuration
   If eth100 is non-zero, 100BaseT is advertised to the link peer
   Full duplex is always advertised
	 Returns 0 if no error and link established
	 Returns 1 on ID read error or config register readback error
	 Returns 2 if no error but link times out (3 sec) */
int smi_config(int eth100, smi_interface_t &smi);

// Reset the MII PHY
void smi_reset(out port ?p_mii_resetn, smi_interface_t &smi);

/* Cleanup of SMI ports */
void smi_deinit(clock clk_mii_ref, clock clk_smi, out port ?p_mii_resetn, smi_interface_t &smi);

/* Enable/disable phy loopback */
void smi_loopback(int enable, smi_interface_t &smi);

// Return 1 if link established
int smi_checklink(smi_interface_t &smi);

/* Direct SMI register access (for advanced use) */
int smi_rd(int address, int reg,  smi_interface_t &smi);
void smi_wr(int address, int reg, int val, smi_interface_t &smi);

#endif

#endif
