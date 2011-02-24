/*************************************************************************
 *
 * Ethernet MAC Layer Client Test Code
 * IEEE 802.3 MAC Client
 *
 *   File        : frame_channel.hx
 *
 *************************************************************************
 *
 * Copyright (c) 2008 XMOS Ltd.
 *
 * Copyright Notice
 *
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
