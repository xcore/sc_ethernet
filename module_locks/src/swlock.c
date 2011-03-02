// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "hwlock.h"

hwlock_t global_hwlock;

typedef unsigned swlock_t;

static void init_swlocks(void) __attribute__((constructor));

static void init_swlocks(void)
{
  global_hwlock = __hwlock_init();
}

void free_swlocks(void)
{
  __hwlock_close(global_hwlock);
}

/* Locks */

void spin_lock_init(volatile swlock_t *lock)
{
  *lock = 0;
}

void spin_lock_close(volatile swlock_t *lock)
{
  /* Do nothing */
}

void spin_lock_acquire(volatile swlock_t *lock, 
                       hwlock_t hwlock)
{
  int value;
  do {
    asm(".xtaloop 1\n");
    __hwlock_acquire(hwlock);
    value = *lock;
    *lock = 1;
    __hwlock_release(hwlock);
  } while (value);
}

int spin_lock_try_acquire(volatile swlock_t *lock,
                                 hwlock_t hwlock)
{
  int value;
  __hwlock_acquire(hwlock);
  value = *lock;
  *lock = 1;
  __hwlock_release(hwlock);
  return !value;
}

void spin_lock_release(volatile swlock_t *lock,
                                     hwlock_t hwlock)
{
  __hwlock_acquire(hwlock);
  *lock = 0;
  __hwlock_release(hwlock);
}
