#ifndef __mii_malloc_wrapping_h__
#include "mii_full.h"
#include "mii_malloc.h"
#include <xccompat.h>
void mii_init_mempool_wrapping(mii_mempool_t mempool0,
                               int size,
                               int maxsize_bytes);

mii_buffer_t mii_reserve_wrapping(mii_mempool_t mempool,
                                  REFERENCE_PARAM(unsigned, end_ptr));

mii_buffer_t mii_reserve_wrapping_at_least(mii_mempool_t mempool,
                                           REFERENCE_PARAM(unsigned, end_ptr),
                                           int min_size);

void mii_commit_wrapping(mii_buffer_t buf, int endptr0);

void mii_free_wrapping(mii_buffer_t buf);
int mii_init_my_rdptr_wrapping(mii_mempool_t mempool);
int mii_update_my_rdptr_wrapping(mii_mempool_t mempool, int rdptr0);
mii_buffer_t mii_get_my_next_buf_wrapping(mii_mempool_t mempool, int rdptr0);
mii_buffer_t mii_get_next_buf_wrapping(mii_mempool_t mempool);
int mii_get_wrap_ptr(mii_mempool_t mempool);
unsigned mii_packet_get_data_wrapping(int buf, int n);
int mii_packet_get_wrap_ptr(int buf);

#define MII_MALLOC_FULL_PACKET_SIZE MII_PACKET_HEADER_SIZE+8+1518
#endif
