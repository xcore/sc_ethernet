// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

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

#include "ethernet_conf_derived.h"

#ifndef MAX_ETHERNET_CLIENTS
#define MAX_ETHERNET_CLIENTS   (4)      // Number of link layers to support
#endif

/*****************************************************************************
 *
 *  DO NOT CHANGE THESE.
 *
 *****************************************************************************/

#define ETHERNET_AVB_ENABLE_FORWARDING      1
#define ETHERNET_AVB_DISABLE_FORWARDING     0

#define ETHERNET_START_DATA              (0xA5DA1A5A) // Marker for start of data.

// Protocol definitions
typedef enum {
  ETHERNET_TX_REQ = 0x80000000,
  ETHERNET_TX_REQ_TIMED,
  ETHERNET_GET_MAC_ADRS,
  ETHERNET_TX_SET_SPACING,
  ETHERNET_TX_REQ_OFFSET2,
  ETHERNET_TX_UPDATE_AVB_ROUTER,
  ETHERNET_TX_INIT_AVB_ROUTER,
  ETHERNET_TX_REQ_HP,
  ETHERNET_TX_REQ_TIMED_HP,
  ETHERNET_TX_REQ_OFFSET2_HP,
  ETHERNET_TX_UPDATE_AVB_FORWARDING,

#if (ETHERNET_TX_HP_QUEUE) && (ETHERNET_TRAFFIC_SHAPER)
  ETHERNET_TX_SET_QAV_IDLE_SLOPE,
#endif

  ETHERNET_RX_FRAME_REQ,             // Request for ethernet complete frame,
                                     // including src/dest
  ETHERNET_RX_TYPE_PAYLOAD_REQ,      // Request for ethernet type and payload only
                                     // (i.e. strip MAC address(s))
  ETHERNET_RX_OVERFLOW_CNT_REQ,
  ETHERNET_RX_OVERFLOW_MII_CNT_REQ,
  ETHERNET_RX_FILTER_SET,
  ETHERNET_RX_DROP_PACKETS_SET,
  ETHERNET_RX_KILL_LINK,
  ETHERNET_RX_CUSTOM_FILTER_SET,
  ETHERNET_RX_QUEUE_SIZE_SET,
  ETHERNET_RX_FRAME_REQ_OFFSET2,
  ETHERNET_RX_WANTS_STATUS_UPDATES_SET,
  ETHERNET_RX_TILE_TIMER_OFFSET_REQ,

  ETHERNET_REQ_ACK,
  ETHERNET_REQ_NACK,
} ethernet_protocol_t;

#define ETH_BROADCAST (-1)


#define MII_CREDIT_FRACTIONAL_BITS 16
#endif
