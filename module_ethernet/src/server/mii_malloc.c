// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "mii.h"

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


/* --------------------------------------------------------------------------------------
 *    Functions below are for the maintanance of the main packet FIFOs
 */

void mii_init_mempool(mii_mempool_t mempool0, int size, int maxsize_bytes) {
  mempool_info_t *info = (mempool_info_t *) mempool0;
  info->max_packet_size = sizeof(mii_packet_t) + sizeof(malloc_hdr_t) - (1518-maxsize_bytes);
  info->max_packet_size = (info->max_packet_size + 3) & ~3;
  info->start = (int *) (mempool0 + sizeof(mempool_info_t));
  info->end = (int *) (mempool0 + size);
  info->end -= (info->max_packet_size >> 2);
  info->rdptr = info->start;
  info->wrptr = info->start;
#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_init(&info->lock);
#endif
  return;
}

mii_buffer_t mii_reserve(mii_mempool_t mempool)
{
  mempool_info_t *info = (mempool_info_t *) mempool;
  int *rdptr = info->rdptr;
  int *wrptr = info->wrptr;

  malloc_hdr_t *hdr;
  if (wrptr > info->end) {
    if (rdptr == info->start)
    {
      return 0;
    }
    else
      wrptr = info->start;
  }

  // Test for space left in the range 1 -> mxa_packet_size
  if (((unsigned)rdptr - (unsigned)wrptr - 1) < info->max_packet_size)
  {
    return 0;
  }
  
  info->wrptr = wrptr;
  
  hdr = (malloc_hdr_t *) wrptr;
  hdr->info = info;
  
  return (mii_buffer_t) (wrptr+(sizeof(malloc_hdr_t)>>2));
}

void mii_commit(mii_buffer_t buf, int n) {
  malloc_hdr_t *hdr = (malloc_hdr_t *) ((char *) buf - sizeof(malloc_hdr_t));
  mempool_info_t *info = (mempool_info_t *) hdr->info;
  mii_packet_t *pkt;

  hdr->size = (sizeof(malloc_hdr_t)/4) + ((n+3)>>2);
  info->wrptr += (hdr->size);

  pkt = (mii_packet_t *) buf;
  pkt->tcount = 0;
  pkt->stage = 0;
  pkt->forwarding = 0;

  return;
}


void mii_free(mii_buffer_t buf) {
  malloc_hdr_t *hdr = (malloc_hdr_t *) ((char *) buf - sizeof(malloc_hdr_t));
  mempool_info_t *info = (mempool_info_t *) hdr->info;
  int free_buf = 1;

#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_acquire(&info->lock);
#else
  __hwlock_acquire(ethernet_memory_lock);
#endif

  do {
	// If we are freeing the oldest packet in the fifo then actually
	// move the rd_ptr.
    if ((char *) hdr == (char *) info->rdptr ||
                      ((char *) hdr == (char *) info->start && 
                       (char *) info->rdptr > (char *) info->end)) {

      int size = hdr->size;
      if (size < 0) size = -size;
      hdr = (malloc_hdr_t *) ((int *) hdr + size);
      info->rdptr = (int *) hdr;

      // Wrap to the start of the buffer
      if ((char *) hdr > (char *) info->end) {
        hdr = (malloc_hdr_t *) info->start;
      }

      // If we have an unfreed packet, or have hit the end of the
      // mempool fifo then stop
      if (hdr->size > 0 || (char *) hdr == (char *) info->wrptr) {
          free_buf = 0;
      }
    } else {
      // If this isn't the oldest packet in the queue then just mark it
      // as free by making the size = -size
      hdr->size = -(hdr->size);
      free_buf = 0;
    }
  } while (free_buf);

#ifndef ETHERNET_USE_HARDWARE_LOCKS
  swlock_release(&info->lock);
#else
  __hwlock_release(ethernet_memory_lock);
#endif
}

/* --------------------------------------------------------------------------------------
 *    Functions below are for the maintanance of the client FIFOs
 */

mii_buffer_t mii_get_next_buf(mii_mempool_t mempool)
{
  mempool_info_t *info = (mempool_info_t *) mempool;
  int *rdptr = info->rdptr;
  int *wrptr = info->wrptr;

  if (rdptr == wrptr) 
    return 0;


  if (rdptr > info->end) {
    if (wrptr == info->start)      
      return 0;
    else
      rdptr = info->start;
  }

  return (mii_buffer_t) ((char *) rdptr + sizeof(malloc_hdr_t));
}

int mii_init_my_rdptr(mii_mempool_t mempool) 
{
  mempool_info_t *info = (mempool_info_t *) mempool;
  return (int) info->rdptr;
}


int mii_update_my_rdptr(mii_mempool_t mempool, int rdptr0)
{
  mempool_info_t *info = (mempool_info_t *) mempool;
  int *rdptr = (int *) rdptr0;
  malloc_hdr_t *hdr;
  int size;

  if (rdptr > info->end) 
    rdptr = info->start;

  hdr = (malloc_hdr_t *) rdptr;
  size = hdr->size;
  if (size < 0) size = -size;

  rdptr = rdptr + size;  

  return (int) rdptr;
}

mii_buffer_t mii_get_my_next_buf(mii_mempool_t mempool, int rdptr0)
{
  mempool_info_t *info = (mempool_info_t *) mempool;
  int *rdptr = (int *) rdptr0;
  int *wrptr = info->wrptr;

  if (rdptr == wrptr) 
    return 0;

  if (rdptr > info->end) {
    if (wrptr == info->start)      
      return 0;
    else
      rdptr = info->start;
  }

  return (mii_buffer_t) ((char *) rdptr + sizeof(malloc_hdr_t));
}

// These are the non-inline implementations of the mii_packet member
// get functions

int mii_packet_get_data(int buf, int n)
{
	return (int)(((mii_packet_t*)buf)->data[n]);
}

int mii_packet_get_data_word(int data, int n)
{
	return ((unsigned int*)data)[n];
}

#define gen_get_field(field) \
	int mii_packet_get_##field (int buf) \
	{ \
		return ((mii_packet_t*)buf)->field; \
	}

gen_get_field(length)
gen_get_field(timestamp)
gen_get_field(filter_result)
gen_get_field(src_port)
gen_get_field(timestamp_id)
gen_get_field(stage)
gen_get_field(crc)
gen_get_field(forwarding)

