// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "mii_full.h"
#ifndef ETHERNET_USE_HARDWARE_LOCKS
#include "swlock.h"
#else
#include "hwlock.h"
#endif
#include <xscope.h>

typedef unsigned mii_mempool_t;
typedef unsigned mii_buffer_t;

#ifdef ETHERNET_USE_HARDWARE_LOCKS
extern hwlock_t ethernet_memory_lock;
#endif

typedef struct mempool_info_t {
  int *rdptr;
  int *wrptr;
  int *start;
  int *end;
  int rdptr_at_start;
#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_t lock;
#endif
} mempool_info_t;

typedef struct malloc_hdr_t {
  int next;
  mempool_info_t *info;
} malloc_hdr_t;


#define MIN_USAGE (MII_PACKET_HEADER_SIZE+sizeof(malloc_hdr_t)+4*10)

void mii_init_mempool(mii_mempool_t mempool0, int size)
{
  mempool_info_t *info = (mempool_info_t *) mempool0;
  info->start = (int *) (mempool0 + sizeof(mempool_info_t));
  info->end = (int *) (mempool0 + size - 4);
  info->rdptr = info->start;
  info->rdptr_at_start = 1;
  info->wrptr = info->start;
  *(info->start) = 0;
  *(info->end) = (int) (info->start);
#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_init(&info->lock);
#endif
  return;
}

int mii_get_wrap_ptr(mii_mempool_t mempool)
{
  mempool_info_t *info = (mempool_info_t *) mempool;
  return (int) (info->end);
}

mii_buffer_t mii_reserve_at_least(mii_mempool_t mempool,
                                           int min_size)
{
  mempool_info_t *info = (mempool_info_t *) mempool;
  int *rdptr = info->rdptr;
  int *wrptr = info->wrptr;
  malloc_hdr_t *hdr;
  int space_left;

  space_left = (char *) rdptr - (char *) wrptr;

  if (space_left <= 0)
    space_left += (char *) info->end - (char *) info->start;

  // When the rdptr is sitting at the start of the buffer the wrptr
  // cannot be set within last MIN_USAGE bytes, otherwise it will be
  // wrapped and the buffer will look empty when it is actually nearly full.
  if (rdptr == info->start)
    min_size += MIN_USAGE;

  if (space_left < min_size)
    return 0;

  hdr = (malloc_hdr_t *) wrptr;
  hdr->info = info;

  return (mii_buffer_t) (wrptr+(sizeof(malloc_hdr_t)>>2));
}

mii_buffer_t mii_reserve(mii_mempool_t mempool,
                                  unsigned *end_ptr)
{
  mempool_info_t *info = (mempool_info_t *) mempool;
  int *rdptr = info->rdptr;
  int *wrptr = info->wrptr;
  malloc_hdr_t *hdr;
  int space_left;

  if (rdptr > wrptr) {
    space_left = (char *) rdptr - (char *) wrptr;
    if (space_left < MIN_USAGE)
      return 0;
  } else  {
    // If the wrptr is after the rdptr then the should be at least
    // MIN_USAGE between the wrptr and the end of the buffer, therefore
    // at least MIN_USAGE space left
  }

  hdr = (malloc_hdr_t *) wrptr;
  hdr->info = info;

  *end_ptr = (unsigned) rdptr;
  return (mii_buffer_t) (wrptr+(sizeof(malloc_hdr_t)>>2));
}

int mii_commit(mii_buffer_t buf, int endptr0)
{
  int *end_ptr = (int *) endptr0;
  malloc_hdr_t *hdr = (malloc_hdr_t *) ((char *) buf - sizeof(malloc_hdr_t));
  mempool_info_t *info = (mempool_info_t *) hdr->info;
  mii_packet_t *pkt;
  int *end = info->end;

  if (((int) (char *) end - (int) (char *) end_ptr) < MIN_USAGE) {
    // If committing would cause the buffer to look empty (setting
    // the wrptr to the same value as the rdptr) then discard.
    if (info->rdptr_at_start)
      return 0;

    end_ptr = info->start;
  }
  pkt = (mii_packet_t *) buf;
  pkt->stage = 0;
#if (NUM_ETHERNET_PORTS > 1) && !defined(DISABLE_ETHERNET_PORT_FORWARDING)
  pkt->forwarding = 0;
#endif

  hdr->next = (int) end_ptr;

  info->wrptr = end_ptr;

  return 1;
}

void mii_free(mii_buffer_t buf) {
  malloc_hdr_t *hdr = (malloc_hdr_t *) ((char *) buf - sizeof(malloc_hdr_t));
  mempool_info_t *info = (mempool_info_t *) hdr->info;

#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_acquire(&info->lock);
#else
  hwlock_acquire(ethernet_memory_lock);
#endif

  while (1) {
	// If we are freeing the oldest packet in the fifo then actually
	// move the rd_ptr.
    if ((char *) hdr == (char *) info->rdptr) {
      malloc_hdr_t *old_hdr = hdr;

      int next = hdr->next;
      if (next < 0) next = -next;

      // Move to the next packet
      hdr = (malloc_hdr_t *) next;
      info->rdptr = (int *) hdr;
      if (info->rdptr == info->start)
        info->rdptr_at_start = 1;
      else
        info->rdptr_at_start = 0;

      // Mark as empty
      old_hdr->next = 0;

      // If we have an unfreed packet, or have hit the end of the
      // mempool fifo then stop (order of test is important due to lock
      // free mii_commit)
      if ((char *) hdr == (char *) info->wrptr || hdr->next > 0) {
          break;
      }
    } else {
      // If this isn't the oldest packet in the queue then just mark it
      // as free by making the next = -next
      hdr->next = -(hdr->next);
      break;
    }
  };

#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_release(&info->lock);
#else
  hwlock_release(ethernet_memory_lock);
#endif
}


int mii_init_my_rdptr(mii_mempool_t mempool)
{
  mempool_info_t *info = (mempool_info_t *) mempool;
  return (int) info->rdptr;
}


int mii_update_my_rdptr(mii_mempool_t mempool, int rdptr0)
{
  int *rdptr = (int *) rdptr0;
  malloc_hdr_t *hdr;
  int next;

  hdr = (malloc_hdr_t *) rdptr;
  next = hdr->next;

#ifdef MII_MALLOC_ASSERT
  // Should always be a positive next pointer
  if (next <= 0) {
	  __builtin_trap();
  }
#endif

  return next;
}

unsigned mii_get_rdptr_address(mii_mempool_t mempool)
{
  mempool_info_t *info = (mempool_info_t *) mempool;
  return (unsigned) &(info->rdptr);
}

mii_buffer_t mii_get_my_next_buf(mii_mempool_t mempool, int rdptr0)
{
  mempool_info_t *info = (mempool_info_t *) mempool;
  int *rdptr = (int *) rdptr0;
  int *wrptr = info->wrptr;

  if (rdptr == wrptr)
    return 0;

  return (mii_buffer_t) ((char *) rdptr + sizeof(malloc_hdr_t));
}

mii_buffer_t mii_get_next_buf(mii_mempool_t mempool)
{
  mempool_info_t *info = (mempool_info_t *) mempool;
  int *rdptr = info->rdptr;
  int *wrptr = info->wrptr;

  if (rdptr == wrptr)
    return 0;


  return (mii_buffer_t) ((char *) rdptr + sizeof(malloc_hdr_t));
}


unsigned mii_packet_get_data(int buf, int n)
{
  malloc_hdr_t *hdr = (malloc_hdr_t *) (buf - sizeof(malloc_hdr_t));
  mempool_info_t *info = hdr->info;
  int *p = (int *) buf;
  p = p + n + BUF_DATA_OFFSET;
  if (p >= info->end) {
    p -= (info->end - info->start);
  }
  return *p;
}

int mii_packet_get_wrap_ptr(int buf)
{
  malloc_hdr_t *hdr = (malloc_hdr_t *) (buf - sizeof(malloc_hdr_t));
  mempool_info_t *info = hdr->info;
  return (int) (info->end);
}
