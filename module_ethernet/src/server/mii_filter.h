// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef __mii_filter_h__
#define __mii_filter_h__
#include "mii.h"
#include "mii_queue.h"
#include "mii_malloc.h"

void ethernet_filter(const int mac[2], streaming chanend c[NUM_ETHERNET_PORTS]);

#ifdef ETHERNET_COUNT_PACKETS
void ethernet_get_filter_counts(REFERENCE_PARAM(unsigned,address),
								REFERENCE_PARAM(unsigned,filter),
								REFERENCE_PARAM(unsigned,length));
#endif

#endif // __mii_filter_h__
