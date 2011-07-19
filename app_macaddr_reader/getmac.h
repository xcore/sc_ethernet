// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _getmac_h_
#define _getmac_h_

// Retrieves least significant 24bits from MAC address stored in OTP
void ethernet_getmac_otp(port otp_data, out port otp_addr, port otp_ctrl, char macaddr[]);

void ethernet_getmac_otp_indexed(port otp_data, out port otp_addr, port otp_ctrl, char macaddr[], unsigned index);

#endif
