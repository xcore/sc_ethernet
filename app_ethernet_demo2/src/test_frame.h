// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*************************************************************************
 *
 * Ethernet MAC Layer Client Test Code
 * IEEE 802.3 MAC Client
 *
 *   File        : test_frame.h
 *
 *************************************************************************
 *
 * Test frame routines.
 *
 *************************************************************************/

#ifndef _test_frame_h_
#define _test_frame_h_

void stamp_test_frame(unsigned char bytes[], unsigned stamp);
int generate_test_frame(unsigned char bytes[]);
int test_frame_size();
unsigned get_test_frame_stamp(const unsigned char bytes[]);

#endif
