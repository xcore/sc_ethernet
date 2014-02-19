#ifndef __mii_malloc_h__
#define __mii_malloc_h__
#include "mii_full.h"
#include <xccompat.h>
typedef unsigned mii_mempool_t;
typedef unsigned mii_buffer_t;

void mii_init_mempool(mii_mempool_t mempool0, int size);

mii_buffer_t mii_reserve(mii_mempool_t mempool,
                                  REFERENCE_PARAM(unsigned, end_ptr));

mii_buffer_t mii_reserve_at_least(mii_mempool_t mempool,
                                           int min_size);

/*
 * Try to commit the buffer and return 1 if it succeeds and 0 otherwise.
 */
int mii_commit(mii_buffer_t buf, int endptr0);

void mii_free(mii_buffer_t buf);
int mii_init_my_rdptr(mii_mempool_t mempool);
int mii_update_my_rdptr(mii_mempool_t mempool, int rdptr0);
unsigned mii_get_rdptr_address(mii_mempool_t mempool);
mii_buffer_t mii_get_my_next_buf(mii_mempool_t mempool, int rdptr0);
mii_buffer_t mii_get_next_buf(mii_mempool_t mempool);
int mii_get_wrap_ptr(mii_mempool_t mempool);
unsigned mii_packet_get_data(int buf, int n);
int mii_packet_get_wrap_ptr(int buf);

#define MII_MALLOC_FULL_PACKET_SIZE_LP MII_PACKET_HEADER_SIZE+8+ETHERNET_MAX_TX_LP_PACKET_SIZE
#define MII_MALLOC_FULL_PACKET_SIZE_HP MII_PACKET_HEADER_SIZE+8+ETHERNET_MAX_TX_HP_PACKET_SIZE

#endif
