// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

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
