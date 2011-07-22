/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    hwlock.h
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
#define RES_TYPE_LOCK 5
#define QUOTEAUX(x) #x
#define QUOTE(x) QUOTEAUX(x)

typedef unsigned hwlock_t;

static inline void __hwlock_acquire(hwlock_t lock)
{
  int clobber;
  __asm__ __volatile__ ("in %0, res[%1]"
                        : "=r" (clobber)
                        : "r" (lock)
                        : "r0");
}

static inline void __hwlock_release(hwlock_t lock)
{
  __asm__ __volatile__ ("out res[%0], %0"
                        : /* no output */
                        : "r" (lock));
}

static inline hwlock_t __hwlock_init()
{
  hwlock_t lock;
  __asm__ __volatile__ ("getr %0, " QUOTE(RES_TYPE_LOCK)
                        : "=r" (lock));
  return lock;
}

static inline void __hwlock_close(hwlock_t lock)
{
  __asm__ __volatile__ ("freer res[%0]"
                        : /* no output */
                        : "r" (lock));
}
