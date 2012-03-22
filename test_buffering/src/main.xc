// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <platform.h>
#include <stdlib.h>
#include <print.h>

extern void test_logical();
extern void test_timing_init();
extern void test_timing_read();
extern void test_timing_write();

extern unsigned counter_no_mem;
extern unsigned counter_allocated;
extern unsigned counter_freed;

void wait(unsigned mask)
{
	timer t;
	unsigned ts;
	t :> ts;
	t when timerafter(ts + (rand()&mask)) :> void;
}

int main()
{
	// Logical test
	test_logical();

    printstrln("Logical test complete\n");

	// Timing test
	test_timing_init();
	par {
		test_timing_read();
		test_timing_write();
	}

	printstr("\nAllocated: ");printuint(counter_allocated);
	printstr("\nFreed: ");printuint(counter_freed);
	printstr("\nNo mem ");printuint(counter_no_mem);

	return 0;
}


