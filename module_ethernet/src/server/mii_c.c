// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include "mii_queue.h"
#include "mii.h"
#include "mii_malloc.h"
#include <print.h>
#include <stdlib.h>
#include <syscall.h>
#include <xccompat.h>

void init_mii_rx_pins(port p_mii_rxdv);

void mii_rx_pins0(int k,
                  mii_packet_t *buf,
                  port p_mii_rxdv,
                  port p_mii_rxd,
                  int ifnum,
                  chanend c);

static inline int inuint(chanend c) {
  int x;
  __asm__("in %0,res[%1]":"=r"(x):"r"(c));
  return x;
}

static inline void outuint(chanend c, int x)
{
  __asm__("out res[%0], %1"::"r"(c),"r"(x));
}
#if 0
void mii_rx_pins(unsigned p_mii_rxdv,
                 unsigned p_mii_rxd,
                 int ifnum,
                 chanend c)
{
  int buf;
  init_mii_rx_pins(p_mii_rxdv);

  while (1) {
    buf = inuint(c);
    if (buf)
      mii_rx_pins0(buf, (mii_packet_t *) buf, p_mii_rxdv, p_mii_rxd, ifnum, c);
    else
      outuint(c, buf);     
  }
}
#endif
void mii_tx_pins0(int k,
                  mii_packet_t *buf,
                  mii_queue_t *ts_queue,
                  port p_mii_txd,
                  int ifnum);

void mii_tx_pins(mii_mempool_t txmem,
                 mii_queue_t *in_queue,
                 mii_queue_t *ts_queue,
                 port p_mii_txd,
                 int ifnum)                
{
  while (1) {    
    mii_packet_t *buf;
    
    //buf = get_queue_entry_no_lock(in_queue);
    buf = (mii_packet_t *) mii_get_next_buf(txmem);
    if (buf != 0 && buf->stage == 1) {                
      //      printhexln(buf);
      mii_tx_pins0((int) buf, buf, ts_queue, p_mii_txd, ifnum);
    }
  }  
}

