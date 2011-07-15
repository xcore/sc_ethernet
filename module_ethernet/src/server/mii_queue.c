// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <swlock.h>
#include <mii_queue.h>
#include <mii.h>

extern mii_packet_t mii_packet_buf[];

swlock_t queue_locks[MAC_MAX_NUM_QUEUES];

swlock_t tc_lock = INITIAL_SWLOCK_VALUE;


int get_and_dec_transmit_count(int buf0) 
{
  mii_packet_t *buf = (mii_packet_t *) buf0;
  int count;
  swlock_acquire(&tc_lock);
  count = buf->tcount;
  if (count) 
    buf->tcount = count - 1;
  swlock_release(&tc_lock);
  return count;
}

void incr_transmit_count(int buf0, int incr) 
{
  mii_packet_t *buf = (mii_packet_t *) buf0;
  swlock_acquire(&tc_lock);
  buf->tcount += incr;
  swlock_release(&tc_lock);
}

void init_queue(mii_queue_t *q)
{
  static int next_qlock = 1;
  q->lock = (int) &queue_locks[next_qlock];
  next_qlock++;

  q->rdIndex = 0;
  q->wrIndex = 0;

  swlock_init((swlock_t *) q->lock);
  return;
}

int get_queue_entry(mii_queue_t *q) 
{
  int i=0;
  int rdIndex, wrIndex;
  swlock_acquire((swlock_t *) q->lock);
  
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
  swlock_release((swlock_t *) q->lock);
  return i;
}

int get_queue_entry_no_lock(mii_queue_t *q) 
{
  int i=0;
  int rdIndex, wrIndex;
  
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
  return i;
}

void add_queue_entry(mii_queue_t *q, int i) 
{
  int wrIndex;
  swlock_acquire((swlock_t *) q->lock); 
  wrIndex = q->wrIndex;
  q->fifo[wrIndex] = i;
  wrIndex++;
  wrIndex *= (wrIndex != MAC_MAX_ENTRIES);
  q->wrIndex = wrIndex;
  swlock_release((swlock_t *) q->lock);
  return;
}


void add_queue_entry_no_lock(mii_queue_t *q, int i) 
{
  int wrIndex;
  wrIndex = q->wrIndex;
  q->fifo[wrIndex] = i;
  wrIndex++;
  wrIndex *= (wrIndex != MAC_MAX_ENTRIES);
  q->wrIndex = wrIndex;
  return;
}

