/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    swlock.c
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

