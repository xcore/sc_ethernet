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
  info->max_packet_size = sizeof(mii_packet_t) + sizeof(malloc_hdr_t) - (((MAX_ETHERNET_PACKET_SIZE+3)&~3)-maxsize_bytes);
  info->max_packet_size = (info->max_packet_size + 3) & ~3;
  info->start = (int *) (mempool0 + sizeof(mempool_info_t));
  info->end = (int *) (mempool0 + size);
  info->end -= (info->max_packet_size >> 2);
  info->rdptr = info->start;
  info->wrptr = info->start;
  *(info->start) = 0;
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

  // If the write pointer is at the start, then we check if the length is
  // non-zero meaning the buffer is full
  if (wrptr == info->start && *wrptr != 0) return 0;

  // If the read pointer is beyond the write pointerm we check if there
  // is enough space to avoid overwriting the tail
  if (((unsigned)rdptr - (unsigned)wrptr)-1 < info->max_packet_size) {
	  return 0;
  }
  
  hdr = (malloc_hdr_t *) wrptr;
  hdr->info = info;
  
  return (mii_buffer_t) (wrptr+(sizeof(malloc_hdr_t)>>2));
}

void mii_commit(mii_buffer_t buf, int n) {
  malloc_hdr_t *hdr = (malloc_hdr_t *) ((char *) buf - sizeof(malloc_hdr_t));
  mempool_info_t *info = (mempool_info_t *) hdr->info;
  mii_packet_t *pkt;

  unsigned size = (sizeof(malloc_hdr_t)/4) + ((n+3)>>2);

  pkt = (mii_packet_t *) buf;
  pkt->stage = 0;
#if (NUM_ETHERNET_PORTS > 1) && !defined(DISABLE_ETHERNET_PORT_FORWARDING)
  pkt->forwarding = 0;
#endif

  // This goes last - updating the write pointer is the action which enables the
  // ethernet_rx_server to start considering the packet.  The server will ignore
  // the packet initially, because the 'stage' is set to zero.  The filter thread
  // will set the stage to 1 when the filter has run, and at that point the
  // ethernet_rx_server thread will start to process it.
  {
	  int* wrptr = info->wrptr + size;
	  if (wrptr > info->end) wrptr = info->start;
	  hdr->size = size;
	  info->wrptr = wrptr;
  }

  return;
}


void mii_free(mii_buffer_t buf) {
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
      hdr = (malloc_hdr_t *) ((int *) hdr + size);
      if ((char *) hdr > (char *) info->end) hdr = (malloc_hdr_t *) info->start;
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

#ifdef MII_MALLOC_ASSERT
  // Should always be a positive size
  if (size <= 0) {
	  __builtin_trap();
  }
#endif

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

#ifdef MII_MALLOC_ASSERT
  // Should always be a positive size
  if (*rdptr <= 0) {
	  __builtin_trap();
  }
#endif

  return (mii_buffer_t) ((char *) rdptr + sizeof(malloc_hdr_t));
}
