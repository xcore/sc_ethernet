// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef __mii_queue_h__
#define __mii_queue_h__

#include <xccompat.h>

#include "ethernet_conf_derived.h"

#ifndef NUM_MII_RX_BUF
#define NUM_MII_RX_BUF 5
#endif

#ifndef NUM_MII_TX_BUF
#define NUM_MII_TX_BUF 5
#endif


#define MAC_MAX_NUM_QUEUES 10

#define MAC_MAX_ENTRIES ((NUM_MII_RX_BUF<NUM_MII_TX_BUF?NUM_MII_TX_BUF:NUM_MII_RX_BUF)+1)

typedef struct mii_ts_queue_t {
  int lock;
  int rdIndex;
  int wrIndex;
  unsigned fifo[MAC_MAX_ENTRIES];
} mii_ts_queue_t;

//!@{
//! \name Functions used by the queue of packets waiting to have their timestamps reported

//! Initialise a queue
void init_ts_queue(REFERENCE_PARAM(mii_ts_queue_t, q));

//! Get the first entry in the timestamp buffer queue
int get_ts_queue_entry(REFERENCE_PARAM(mii_ts_queue_t, q));

//! Add an entry to the timestamp buffer queue
void add_ts_queue_entry(REFERENCE_PARAM(mii_ts_queue_t, q), int i);

//!@}

//!@{
//! \name Functions used for atomic modification of packet buffer properties

//! This is an atomic get and decrement of a buffers transmit counter
int get_and_dec_transmit_count(int buf_num);

//! This is an atomic test and clear of the forward to other port bit for a buffer
int mii_packet_get_and_clear_forwarding(int buf_num, int ifnum);

//!@}

#endif //__mii_queue_h__
