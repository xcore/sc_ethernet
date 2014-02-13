// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <mii_queue.h>
#include <mii_full.h>

#ifndef ETHERNET_USE_HARDWARE_LOCKS
#include "swlock.h"
#else
#include "hwlock.h"
#endif

extern mii_packet_t mii_packet_buf[];

#ifndef ETHERNET_USE_HARDWARE_LOCKS
swlock_t queue_locks[MAC_MAX_NUM_QUEUES];
swlock_t tc_lock = INITIAL_SWLOCK_VALUE;
#else
extern hwlock_t ethernet_memory_lock;
#endif

int get_and_dec_transmit_count(int buf0)
{
  mii_packet_t *buf = (mii_packet_t *) buf0;
  int count;
#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_acquire(&tc_lock);
#else
  hwlock_acquire(ethernet_memory_lock);
#endif
  count = buf->tcount;
  if (count)
    buf->tcount = count - 1;
#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_release(&tc_lock);
#else
  hwlock_release(ethernet_memory_lock);
#endif
  return count;
}





int mii_packet_get_and_clear_forwarding(int buf0, int ifnum)
{
  mii_packet_t *buf = (mii_packet_t *) buf0;
  int mask = (1<<ifnum);
  int ret = (buf->forwarding & mask);

#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_acquire(&tc_lock);
#else
  hwlock_acquire(ethernet_memory_lock);
#endif

  // FIXME: Was: buf->forwarding &= (~mask)
  buf->forwarding = 0;

#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_release(&tc_lock);
#else
  hwlock_release(ethernet_memory_lock);
#endif
  return ret;
}






void init_ts_queue(mii_ts_queue_t *q)
{
#ifndef ETHERNET_USE_HARDWARE_LOCKS
  static int next_qlock = 1;
  q->lock = (int) &queue_locks[next_qlock];
  next_qlock++;
  swlock_init((swlock_t *) q->lock);
#endif

  q->rdIndex = 0;
  q->wrIndex = 0;
  return;
}

int get_ts_queue_entry(mii_ts_queue_t *q)
{
  int i=0;
  int rdIndex, wrIndex;

#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_acquire((swlock_t *) q->lock);
#else
  hwlock_acquire(ethernet_memory_lock);
#endif

  rdIndex = q->rdIndex;
  wrIndex = q->wrIndex;

  if (rdIndex == wrIndex)
    i = 0;
  else {
    i = q->fifo[rdIndex];
    rdIndex++;
    rdIndex *= (rdIndex != MAC_MAX_ENTRIES);
    q->rdIndex = rdIndex;
  }
#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_release((swlock_t *) q->lock);
#else
  hwlock_release(ethernet_memory_lock);
#endif
  return i;
}

void add_ts_queue_entry(mii_ts_queue_t *q, int i)
{
  int wrIndex;

#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_acquire((swlock_t *) q->lock);
#else
  hwlock_acquire(ethernet_memory_lock);
#endif

  wrIndex = q->wrIndex;
  q->fifo[wrIndex] = i;
  wrIndex++;
  wrIndex *= (wrIndex != MAC_MAX_ENTRIES);
  q->wrIndex = wrIndex;

#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_release((swlock_t *) q->lock);
#else
  hwlock_release(ethernet_memory_lock);
#endif
  return;
}



