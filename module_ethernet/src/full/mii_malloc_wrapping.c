// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "mii_full.h"
#include "print.h"
#ifndef ETHERNET_USE_HARDWARE_LOCKS
#include "swlock.h"
#else
#include "hwlock.h"
#endif

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
#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_t lock;
#endif
  unsigned max_packet_size;
} mempool_info_t;

typedef struct malloc_hdr_t {
  int size;
  mempool_info_t *info;
} malloc_hdr_t;


#define MIN_USAGE (MII_PACKET_HEADER_SIZE+sizeof(malloc_hdr_t)+4*10)

void mii_init_mempool_wrapping(mii_mempool_t mempool0,
                               int size,
                               int maxsize_bytes)
{
  mempool_info_t *info = (mempool_info_t *) mempool0;
  info->max_packet_size = sizeof(mii_packet_t) + sizeof(malloc_hdr_t) - (((MAX_ETHERNET_PACKET_SIZE+3)&~3)-maxsize_bytes);
  info->max_packet_size = (info->max_packet_size + 3) & ~3;
  info->start = (int *) (mempool0 + sizeof(mempool_info_t));
  info->end = (int *) (mempool0 + size - 4);
  info->rdptr = info->start;
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

mii_buffer_t mii_reserve_wrapping_at_least(mii_mempool_t mempool,
                                           unsigned *end_ptr,
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

  if (space_left < min_size)
    return 0;

  hdr = (malloc_hdr_t *) wrptr;
  hdr->info = info;

  *end_ptr = (unsigned) rdptr;
  return (mii_buffer_t) (wrptr+(sizeof(malloc_hdr_t)>>2));
}

mii_buffer_t mii_reserve_wrapping(mii_mempool_t mempool,
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




void mii_commit_wrapping(mii_buffer_t buf, int endptr0)
{
  int *end_ptr = (int *) endptr0;
  malloc_hdr_t *hdr = (malloc_hdr_t *) ((char *) buf - sizeof(malloc_hdr_t));
  mempool_info_t *info = (mempool_info_t *) hdr->info;
  mii_packet_t *pkt;
  int *end = info->end;
  pkt = (mii_packet_t *) buf;
  pkt->stage = 0;
#if (NUM_ETHERNET_PORTS > 1) && !defined(DISABLE_ETHERNET_PORT_FORWARDING)
  pkt->forwarding = 0;
#endif

  if (((int) (char *) end - (int) (char *) end_ptr) < MIN_USAGE)
    end_ptr = info->start;

  hdr->size = (int) end_ptr;

  info->wrptr = end_ptr;

  return;
}

void mii_free_wrapping(mii_buffer_t buf) {
  malloc_hdr_t *hdr = (malloc_hdr_t *) ((char *) buf - sizeof(malloc_hdr_t));
  mempool_info_t *info = (mempool_info_t *) hdr->info;

#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_acquire(&info->lock);
#else
  __hwlock_acquire(ethernet_memory_lock);
#endif

  while (1) {
	// If we are freeing the oldest packet in the fifo then actually
	// move the rd_ptr.
    if ((char *) hdr == (char *) info->rdptr) {
      malloc_hdr_t *old_hdr = hdr;

      int size = hdr->size;
      if (size < 0) size = -size;

      // Move to the next packet
      hdr = (malloc_hdr_t *) size;
      info->rdptr = (int *) hdr;

      // Mark as empty
      old_hdr->size = 0;

      // If we have an unfreed packet, or have hit the end of the
      // mempool fifo then stop (order of test is important due to lock
      // free mii_commit)
      if ((char *) hdr == (char *) info->wrptr || hdr->size > 0) {
          break;
      }
    } else {
      // If this isn't the oldest packet in the queue then just mark it
      // as free by making the size = -size
      hdr->size = -(hdr->size);
      break;
    }
  };

#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_release(&info->lock);
#else
  __hwlock_release(ethernet_memory_lock);
#endif
}


int mii_init_my_rdptr_wrapping(mii_mempool_t mempool)
{
  mempool_info_t *info = (mempool_info_t *) mempool;
  return (int) info->rdptr;
}


int mii_update_my_rdptr_wrapping(mii_mempool_t mempool, int rdptr0)
{
  int *rdptr = (int *) rdptr0;
  malloc_hdr_t *hdr;
  int size;

  hdr = (malloc_hdr_t *) rdptr;
  size = hdr->size;

#ifdef MII_MALLOC_ASSERT
  // Should always be a positive size
  if (size <= 0) {
	  __builtin_trap();
  }
#endif

  return size;
}

mii_buffer_t mii_get_my_next_buf_wrapping(mii_mempool_t mempool, int rdptr0)
{
  mempool_info_t *info = (mempool_info_t *) mempool;
  int *rdptr = (int *) rdptr0;
  int *wrptr = info->wrptr;

  if (rdptr == wrptr) 
    return 0;

#ifdef MII_MALLOC_ASSERT
  // Should always be a positive size
  if (*rdptr <= 0) {
	  __builtin_trap();
  }
#endif

  return (mii_buffer_t) ((char *) rdptr + sizeof(malloc_hdr_t));
}

mii_buffer_t mii_get_next_buf_wrapping(mii_mempool_t mempool)
{
  mempool_info_t *info = (mempool_info_t *) mempool;
  int *rdptr = info->rdptr;
  int *wrptr = info->wrptr;

  if (rdptr == wrptr)
    return 0;

#ifdef MII_MALLOC_ASSERT
  // Should always be a positive size
  if (*rdptr <= 0) {
	  __builtin_trap();
  }
#endif

  return (mii_buffer_t) ((char *) rdptr + sizeof(malloc_hdr_t));
}


unsigned mii_packet_get_data_wrapping(int buf, int n)
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
