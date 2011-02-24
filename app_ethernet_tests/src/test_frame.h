/*************************************************************************
 *
 * Ethernet MAC Layer Client Test Code
 * IEEE 802.3 MAC Client
 *
 *   File        : test_frame.h
 *
 *************************************************************************
 *
 * Copyright (c) 2008 XMOS Ltd.
 *
 * Copyright Notice
 *
 *************************************************************************
 *
 * Test frame routines.
 *
 *************************************************************************/

#ifndef _test_frame_h_
#define _test_frame_h_

int check_test_frame(int len, unsigned char bytes[]);
void generate_test_frame(int len, unsigned char bytes[]);
unsigned short get_ethertype(unsigned char buf[]);
void set_ethertype(unsigned char buf[], unsigned short val);

#endif
