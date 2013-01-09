// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef __mii_filter_h__
#define __mii_filter_h__
#include "mii_full.h"
#include "mii_queue.h"
#include "mii_malloc.h"

//! This define is the last bit in the filter bitfield, and is set when the
//! system has to forward the packet to the other ethernet ports
#define MII_FILTER_FORWARD_TO_OTHER_PORTS (0x80000000)

#ifdef __XC__
void ethernet_filter(const char mac[], streaming chanend c[NUM_ETHERNET_PORTS]);
#endif

#if ETHERNET_COUNT_PACKETS
void ethernet_get_filter_counts(REFERENCE_PARAM(unsigned,address),
								REFERENCE_PARAM(unsigned,filter),
								REFERENCE_PARAM(unsigned,length),
								REFERENCE_PARAM(unsigned,crc));
#endif

#endif // __mii_filter_h__
