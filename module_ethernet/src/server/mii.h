// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef __mii_h__
#define __mii_h__
#include <xccompat.h>
#include <xs1.h>
#include "ethernet_conf.h"

#ifndef MAX_ETHERNET_PACKET_SIZE
#define MAX_ETHERNET_PACKET_SIZE (1518)
#endif

#ifndef NUM_MII_RX_BUF
#define NUM_MII_RX_BUF 5
#endif

#ifndef NUM_MII_TX_BUF
#define NUM_MII_TX_BUF 5
#endif

#include "mii_queue.h"



#ifdef __XC__
typedef struct mii_interface_t {
  clock clk_mii_rx;
  clock clk_mii_tx;

  in port p_mii_rxclk;
  in port p_mii_rxer;
  in buffered port:32 p_mii_rxd;
  in port p_mii_rxdv;


  in port p_mii_txclk;
  out port p_mii_txen;
  out buffered port:32 p_mii_txd;
} mii_interface_t;

void mii_init(REFERENCE_PARAM(mii_interface_t, m), clock clk_mii_ref);
#endif


typedef struct mii_packet_t {
  int length;
  int complete;
  int timestamp;
  unsigned int data[(MAX_ETHERNET_PACKET_SIZE+3)/4];
  int filter_result;
  int src_port;
  int timestamp_id;
  int free_pool;
} mii_packet_t;

#ifdef __XC__
void mii_rx_pins(mii_queue_t &free_queue,
                 mii_packet_t buf[],
                 in port p_mii_rxdv,
                 in buffered port:32 p_mii_rxd,
                 int ifnum,
                 streaming chanend c);
#else
void mii_rx_pins(mii_queue_t *free_queue,
                 mii_packet_t buf[],
                 port p_mii_rxdv,
                 port p_mii_rxd,
                 int ifnum,
                 chanend c);
#endif

#ifdef __XC__
void mii_tx_pins(mii_packet_t buf[],
                 mii_queue_t &in_queue,
                 mii_queue_t &free_queue,
                 mii_queue_t &ts_queue,
                 out buffered port:32 p_mii_txd,
                 int ifnum);
#else
void mii_tx_pins(mii_packet_t buf[],
                 mii_queue_t *in_queue,
                 mii_queue_t *free_queue,
                 mii_queue_t *ts_queue,
                 port p_mii_txd,
                 int ifnum);
#endif



#endif
