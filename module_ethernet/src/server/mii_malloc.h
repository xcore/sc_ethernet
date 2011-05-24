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

mii_buffer_t mii_reserve(mii_mempool_t mempool);

void mii_commit(mii_buffer_t buf, int n);

void mii_free(mii_buffer_t);

mii_buffer_t mii_get_next_buf(mii_mempool_t mempool);

int mii_init_my_rdptr(mii_mempool_t mempool);

mii_buffer_t mii_get_my_next_buf(mii_mempool_t mempool, 
                                 int rdptr);

int mii_update_my_rdptr(mii_mempool_t mempool, int rdptr0);

#endif // __mii_malloc_h__
