// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

typedef unsigned swlock_t;

/* Locks */

void swlock_init(volatile swlock_t *lock)
{
  *lock = 0;
}

extern int swlock_try_acquire(volatile swlock_t *lock);

void swlock_acquire(volatile swlock_t *lock)
{  
  int value;
  do {
    value = swlock_try_acquire(lock);
  }
  while (!value);
}

void swlock_release(volatile swlock_t *lock)
{
  *lock = 0;
}

void swlock_init_xc(swlock_t *lock) { swlock_init(lock); }

int swlock_try_acquire_xc(swlock_t *lock) {return swlock_try_acquire(lock); }

void swlock_acquire_xc(swlock_t *lock) {swlock_acquire(lock);}

