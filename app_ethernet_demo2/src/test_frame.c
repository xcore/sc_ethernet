// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*************************************************************************
 *
 * Ethernet MAC Layer Client Test Code
 * IEEE 802.3 MAC Client
 *
 *   File        : test_frame.c
 *
 *************************************************************************
 *
 * Test frame routines.
 *
 *************************************************************************/

#include "test_frame.h"

void stamp_test_frame(unsigned char bytes[], unsigned stamp)
{
  bytes[14] = (stamp & 0xFF);
  bytes[15] = ((stamp >> 8) & 0xFF);
  bytes[16] = ((stamp >> 16) & 0xFF);
  bytes[17] = ((stamp >> 24) & 0xFF);
}

int generate_test_frame(unsigned char bytes[])
{
	int i;
  for (i = 0; i < 6; i++)
  {
    bytes[i] = 0xFF;
  }
  for (i = 6; i < 12; i++)
  {
    bytes[i] = 0xFF;
  }
  bytes[12] = 0xAB;
  bytes[13] = 0xCD;
  for (i = 18; i < 1000; i++)
  {
    bytes[i] = ((7 * i + 13) % 25) & 0xFF;
  }
  return 1000;
}

int test_frame_size()
{
	return 1000;
}

unsigned get_test_frame_stamp(const unsigned char bytes[])
{
  unsigned stamp = (bytes[14] | (bytes[15] << 8) | (bytes[16] << 16) | (bytes[17] << 24));
  return stamp;
}
