/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    ethernet_rx_server.h
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

void ethernet_rx_server(REFERENCE_PARAM(mii_queue_t, in_q),
                        REFERENCE_PARAM(mii_queue_t, free_queue),
                        mii_packet_t buf[],
                        chanend link[],
                        int num_links);
#endif

