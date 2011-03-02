// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _checksum_h_
#define _checksum_h_

unsigned short checksum_ip(const unsigned char frame[]);
unsigned short checksum_udp(const unsigned char frame[], int udplen);

#endif
