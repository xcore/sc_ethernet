// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*************************************************************************
 *
 * Ethernet MAC Layer Client Test Code
 * IEEE 802.3 MAC Client
 *
 *   File        : frame_channel.hx
 *
 *************************************************************************
 *************************************************************************
 *
 * Functions for passing an Ethernet frame over a channel.
 *
 *************************************************************************/

#ifndef _frame_channel_h_
#define _frame_channel_h_

void pass_frame(chanend c, const unsigned char buffer[], int nbytes);
void fetch_frame(unsigned char buffer[], chanend c, int &nbytes);

#endif
