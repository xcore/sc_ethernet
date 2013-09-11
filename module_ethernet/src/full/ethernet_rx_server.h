// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*************************************************************************
 *
 * Ethernet MAC Layer Implementation
 * IEEE 802.3 Link Layer (Receive)
 *
 *
 *
 * Implements the Buffer management server for Ethernet Rx Frames.
 *
 * NOTE: This module does NOT implement actual buffer storage, which is
 * done in mii_buf.h/c.
 *
 * This manage the pointers to buffer and communication over channel(s)
 * to PHY & Link layers.
 *
 *************************************************************************/

#ifndef _ETHERNET_RX_SERVER_H_
#define _ETHERNET_RX_SERVER_H_
#include <xccompat.h>
// Common definations for Ethernet server.
#include "ethernet_server_def.h"


/** This implement Ethernet Rx server, with packet filtering.
 *  Each interface need to enable *filter* to receive. Each link interface
 *  can accept ethernet frames based on destination MAC address (6bytes) and/or
 *  VLAN Tag & EType (6bytes). Each bit in the 12bytes filter in turn have mask
 *  and compare bit.
 *
 *
 */

void ethernet_rx_server(
#if ETHERNET_RX_HP_QUEUE
		mii_mempool_t rxmem_hp[],
#endif
		mii_mempool_t rxmem_lp[],
		chanend link[],
		int num_links);
#endif

