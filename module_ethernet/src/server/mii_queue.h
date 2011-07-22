/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    mii_queue.h
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
#ifndef __mii_queue_h__
#define __mii_queue_h__

#include <xccompat.h>
#include "ethernet_conf.h"

#ifndef NUM_MII_RX_BUF 
#define NUM_MII_RX_BUF 5
#endif

#ifndef NUM_MII_TX_BUF 
#define NUM_MII_TX_BUF 5
#endif


#define MAX_NUM_QUEUES 10

#define MAX_ENTRIES ((NUM_MII_RX_BUF<NUM_MII_TX_BUF?NUM_MII_TX_BUF:NUM_MII_RX_BUF)+1)

typedef struct mii_queue_t {
  int lock;
  int rdIndex;
  int wrIndex;
  char fifo[MAX_ENTRIES];
} mii_queue_t;


void init_queue(REFERENCE_PARAM(mii_queue_t, q), int n, int m);
int get_queue_entry(REFERENCE_PARAM(mii_queue_t, q));
void add_queue_entry(REFERENCE_PARAM(mii_queue_t, q), int i);
void init_queues();
void set_transmit_count(int buf_num, int count);
int get_and_dec_transmit_count(int buf_num);
void incr_transmit_count(int buf_num, int incr);
int get_queue_entry_no_lock(REFERENCE_PARAM(mii_queue_t,q));
void free_queue_entry(int i);
#endif //__mii_queue_h__
