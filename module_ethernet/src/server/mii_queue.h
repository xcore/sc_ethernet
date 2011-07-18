// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef __mii_queue_h__
#define __mii_queue_h__

#include <xccompat.h>

#ifdef __ethernet_conf_h_exists__
#include "ethernet_conf.h"
#endif

#ifndef NUM_MII_RX_BUF 
#define NUM_MII_RX_BUF 5
#endif

#ifndef NUM_MII_TX_BUF 
#define NUM_MII_TX_BUF 5
#endif


#define MAC_MAX_NUM_QUEUES 10

#define MAC_MAX_ENTRIES ((NUM_MII_RX_BUF<NUM_MII_TX_BUF?NUM_MII_TX_BUF:NUM_MII_RX_BUF)+1)

typedef struct mii_queue_t {
  int lock;
  int rdIndex;
  int wrIndex;
  unsigned fifo[MAC_MAX_ENTRIES];
} mii_queue_t;

void init_queue(REFERENCE_PARAM(mii_queue_t, q));
int get_queue_entry(REFERENCE_PARAM(mii_queue_t, q));
void add_queue_entry(REFERENCE_PARAM(mii_queue_t, q), int i);

int get_and_dec_transmit_count(int buf_num);
void incr_transmit_count(int buf_num, int incr);

#endif //__mii_queue_h__
