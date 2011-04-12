// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _test_frame_h_
#define _test_frame_h_

int check_test_frame(int len, unsigned char bytes[]);
void generate_test_frame(int len, unsigned char bytes[], int qtag);
unsigned short get_ethertype(unsigned char buf[]);
void set_ethertype(unsigned char buf[], unsigned short val);

#endif
