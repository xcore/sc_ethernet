/*************************************************************************
 *
 * Ethernet MAC Layer Client Test Code
 * IEEE 802.3 MAC Client
 *
 *   File        : checksum.h
 *
 *************************************************************************
 *
 * Copyright (c) 2008 XMOS Ltd.
 *
 * Copyright Notice
 *
 *************************************************************************
 *
 * IP/UDP checksum routines.
 *
 * Note: tcpdump will show bad UDP checksums because they are typically
 * offloaded and computed in hardware which tcpdump doesn't see.
 *
 *************************************************************************/

#ifndef _checksum_h_
#define _checksum_h_

unsigned short checksum_ip(const unsigned char frame[]);
unsigned short checksum_udp(const unsigned char frame[], int udplen);

#endif
