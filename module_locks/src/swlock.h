// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef __swlock_h_
#define __swlock_h_
typedef unsigned swlock_t;

#define INITIAL_SWLOCK_VALUE 0

#ifdef __XC__
void swlock_init_xc(swlock_t &lock);

int swlock_try_acquire_xc(swlock_t &lock);

void swlock_acquire_xc(swlock_t &lock);

static inline void swlock_release_xc(swlock_t &lock)
{
  lock = 0;
}
#else
void swlock_init(volatile swlock_t *lock);

int swlock_try_acquire(volatile swlock_t *lock);

void swlock_acquire(volatile swlock_t *lock);

static inline void swlock_release(volatile swlock_t *lock)
{
  *lock = 0;
}
#endif

#endif
