/**
 * Module:  app_ethernet_demo2
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    test_frame.c
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2009
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
/*************************************************************************
 *
 * Ethernet MAC Layer Client Test Code
 * IEEE 802.3 MAC Client
 *
 *   File        : test_frame.c
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
