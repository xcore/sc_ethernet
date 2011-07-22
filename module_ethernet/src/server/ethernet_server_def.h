/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    ethernet_server_def.h
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
 * IEEE 802.3 Ethernet Common Definitions
 *
 *
 *
 * Generic definations for Ethernet server/client.
 *
 *************************************************************************/
 
#ifndef _ETHERNET_SERVER_DEF_H_
#define _ETHERNET_SERVER_DEF_H_ 1
#include "ethernet_conf.h"

#ifndef MAX_ETHERNET_CLIENTS
#define MAX_ETHERNET_CLIENTS   (4)      // Number of link layers to support
#endif

#ifndef MAX_CLIENT_QUEUE_SIZE 
#define MAX_CLIENT_QUEUE_SIZE  NUM_MII_RX_BUF
#endif

/*****************************************************************************
 *
 *  DO NOT CHANGE THESE.
 *
 *****************************************************************************/

// Protocol defiantions.
#define ETHERNET_TX_REQ           (0x80000000)
#define ETHERNET_TX_REQ_TIMED     (0x80000001)
#define ETHERNET_GET_MAC_ADRS     (0x80000002)
#define ETHERNET_TX_SET_SPACING   (0x80000003)

#define ETHERNET_START_DATA	  (0xA5DA1A5A)	// Marker for start of data.

#define ETHERNET_RX_FRAME_REQ	  (0x80000010)	// Request for ethernet 
                                                // complete frame, 
                                                // including src/dest
#define ETHERNET_RX_TYPE_PAYLOAD_REQ   (0x80000011) // Request for ethernet
                                                    // type and payload only 
                                                    // (i.e. strip MAC 
                                                    //  address(s))
#define ETHERNET_RX_OVERFLOW_CNT_REQ   (0x80000012)	
#define ETHERNET_RX_OVERFLOW_CLEAR_REQ (0x80000013)
#define ETHERNET_RX_FILTER_SET         (0x80000014)
#define ETHERNET_RX_DROP_PACKETS_SET   (0x80000015)
#define ETHERNET_RX_KILL_LINK          (0x80000016)
#define ETHERNET_RX_CUSTOM_FILTER_SET  (0x80000017)
#define ETHERNET_RX_QUEUE_SIZE_SET     (0x80000018)


#define ETHERNET_REQ_ACK	       (0x80000020)	// Acknowledged
#define ETHERNET_REQ_NACK	       (0x80000021)	// Negative ack.


#define ETH_BROADCAST (-1)

#endif
