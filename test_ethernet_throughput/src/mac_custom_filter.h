// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#define FILTER_BROADCAST 0xF0000000

unsigned short get_ethertype(unsigned char buf[]);

static inline unsigned int mac_custom_filter(unsigned int data[]){

        return 0xffffffff;
}
