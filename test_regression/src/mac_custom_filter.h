// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#define FILTER_BROADCAST 0xF0000000

unsigned short get_ethertype(unsigned char buf[]);

static inline unsigned int mac_custom_filter(unsigned int data[]){
	int mask = FILTER_BROADCAST;
	unsigned short etype;

	/* Unmark broadcast */
	for (int i = 0; i < 6; i++){
#pragma xta label "sc_ethernet_mac_custom_filter_1"
#pragma xta command "add loop sc_ethernet_mac_custom_filter_1 6"
          if ((data, char[])[i] != 0xFF){
			mask = 0;
			break;
		}
	}

	/* Ethertypes between 0800 and 08FF have their ls-byte copied into the filter result */
	etype = get_ethertype((data, char[]));
	if (etype >= 0x0800 && etype <= 0x080F){
		mask |= (1 << (etype & 0xFF));
	}

	return mask;
}
