/**
 * Module:  app_ethernet_demo2
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    test_frame.h
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

void stamp_test_frame(unsigned char bytes[], unsigned stamp);
int generate_test_frame(unsigned char bytes[]);
int test_frame_size();
unsigned get_test_frame_stamp(const unsigned char bytes[]);

#endif
