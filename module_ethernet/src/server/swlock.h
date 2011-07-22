/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    swlock.h
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2009
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
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
