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
#include <print.h>

void generate_test_frame(int len, unsigned char bytes[]){

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

	  for (i = 18; i < len; i++){
		  bytes[i] = i;
	  }
}

int check_test_frame(int len, unsigned char bytes[]){

	for (int i = 18; i < len; i++){
		if (bytes[i] != (i % 256)){
			return 0;
		}
	}

	return 1;
}

unsigned short get_ethertype(unsigned char buf[]){
	return ((unsigned short)buf[12]) << 8 | buf[13];
}

void set_ethertype(unsigned char buf[], unsigned short val){
    buf[12] = (val >> 8);
    buf[13] = val;
}
