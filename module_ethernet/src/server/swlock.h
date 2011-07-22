// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef __swlock_h_
#define __swlock_h_
#include "hwlock.h"
typedef unsigned swlock_t;

extern hwlock_t global_hwlock;

void init_swlocks(void);
void free_swlocks(void);
void spin_lock_init(volatile swlock_t *lock);
void spin_lock_close(volatile swlock_t *lock);

static inline void spin_lock_acquire(volatile swlock_t *lock, 
                                     hwlock_t hwlock)
{
  int value;
  do {
    __hwlock_acquire(hwlock);
    value = *lock;
    *lock = 1;
    __hwlock_release(hwlock);
  } while (value);
}

static inline int spin_lock_try_acquire(volatile swlock_t *lock,
                                        hwlock_t hwlock)
{
  int value;
  __hwlock_acquire(hwlock);
  value = *lock;
  *lock = 1;
  __hwlock_release(hwlock);
  return !value;
}

static inline void spin_lock_release(volatile swlock_t *lock,
                                     hwlock_t hwlock)
{
  __hwlock_acquire(hwlock);
  *lock = 0;
  __hwlock_release(hwlock);
}

#endif
