// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "hwlock.h"

hwlock_t global_hwlock;

typedef unsigned swlock_t;

void init_swlocks(void)
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

