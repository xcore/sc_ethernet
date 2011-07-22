// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*************************************************************************
 *
 * Ethernet MAC Layer Implementation
 * IEEE 802.3 Device MAC Address
 *
 *
 *
 * Retreives three bytes of MAC address from OTP.
 *
 *************************************************************************/

#ifndef _getmac_h_
#define _getmac_h_

// Retrieves least significant 24bits from MAC address stored in OTP
// Should be run on core 2
void ethernet_getmac_otp(char macaddr[]);

#endif
