/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    smi.h
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
/*************************************************************************
 *
 * Ethernet MAC Layer Implementation
 * IEEE 802.3 Serial Management Interface
 *
 *   File        : smi.h
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
