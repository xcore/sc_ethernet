// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef __mii_malloc_h__
#define __mii_malloc_h__
#include <mii.h>
#include <xccompat.h>

typedef unsigned mii_mempool_t;
typedef unsigned mii_buffer_t;

void mii_init_mempool(mii_mempool_t mempool0, int size, int maxsize_bytes);

/**
 *  Called to check that there is a free gap big enough to store a whole packet.
 *
 *  Sets the write pointer to the start of the packet (which typically it will
 *  be anyway, but not when the buffer needs wrapping around).
 */
mii_buffer_t mii_reserve(mii_mempool_t mempool);

/**
 *  Called to turn a reservation into an actual entry in the queue (fixing the
 *  packet size).
 *
 *  Moves the write pointer to beyond the end of the packet, ready for the
 *  next mii_reserve, and also sets the packet tcount and stage to zero.
 */
void mii_commit(mii_buffer_t buf, int n);

/**
 * Free the memory block pointed to by the argument. If the packet
 * is at the rd_ptr then the rd_ptr is moved ahead, otherwise it is
 * just marked as free.  When the rd_ptr is moved ahead, it moves
 * over all marked packets until it hits the front of the queue or
 * a packet which has not been marked free.
 */
void mii_free(mii_buffer_t);

mii_buffer_t mii_get_next_buf(mii_mempool_t mempool);

/**
 * Return the start of the mempool.  This is used by the rx_server
 * to initialize its own rdptr, which points to the data which it
 * will process.
 *
 * This is different from the mempool rd_ptr, which is the oldest
 * allocated packet in the mempool.
 */
int mii_init_my_rdptr(mii_mempool_t mempool);

/**
 *  This finds the buffer in the memory block pointed to be the
 *  rdpatr argument.  The mempool is required in case we need to
 *  wrap the pointer to the start of the buffer.
 *
 *  The rx_server uses this, and the mii_get_my_next_buf, to track
 *  the next buffer in the MII input queue which will be processed
 *  into the client queues.
 */
mii_buffer_t mii_get_my_next_buf(mii_mempool_t mempool, int rdptr);

/**
 *  The rdptr referred to in this function is owned by the rx_server
 *  thread. It tracks the last buffer which has been received by the
 *  ethernet component, but not pushed into the client fifos.
 *
 *  The mempool is required because it may be necessary to wrap the
 *  pointer around when moving it to the next packet.
 */
int mii_update_my_rdptr(mii_mempool_t mempool, int rdptr0);

#endif // __mii_malloc_h__
