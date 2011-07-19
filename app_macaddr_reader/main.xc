// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xclib.h>
#include <platform.h>
#include <print.h>
#include <stdlib.h>
#include "getmac.h"

// OTP Core
#ifndef ETHERNET_OTP_CORE
	#define ETHERNET_OTP_CORE 2
#endif

// OTP Ports
on stdcore[ETHERNET_OTP_CORE]: port otp_data = XS1_PORT_32B; 		// OTP_DATA_PORT
on stdcore[ETHERNET_OTP_CORE]: out port otp_addr = XS1_PORT_16C;	// OTP_ADDR_PORT
on stdcore[ETHERNET_OTP_CORE]: port otp_ctrl = XS1_PORT_16D;		// OTP_CTRL_PORT


// Program entry point
int main(void)
{
	par
	{
		on stdcore[ETHERNET_OTP_CORE] :
		{
			int mac_address[2];

			for (unsigned int n=0; n<8; n++) {
				// Get the MAC Address
				ethernet_getmac_otp_indexed(otp_data, otp_addr, otp_ctrl, (mac_address, char[]), n);

				// Print it out
				printstr("MAC Address ");
				printuint(n);
				printstr(": ");
				printhex( ( ( mac_address[0] >> 4 ) & 0xF ) );
				printhex( ( mac_address[0] & 0xF ) );
				printchar(':');
				printhex( ( ( mac_address[0] >> 12 ) & 0xF ) );
				printhex( ( ( mac_address[0] >> 8 ) & 0xF ) );
				printchar(':');
				printhex( ( ( mac_address[0] >> 20 ) & 0xF ) );
				printhex( ( ( mac_address[0] >> 16 ) & 0xF ) );
				printchar(':');
				printhex( ( ( mac_address[0] >> 28 ) & 0xF ) );
				printhex( ( ( mac_address[0] >> 24 ) & 0xF ) );
				printchar(':');
				printhex( ( ( mac_address[1] >> 4 ) & 0xF ) );
				printhex( ( mac_address[1] & 0xF ) );
				printchar(':');
				printhex( ( ( mac_address[1] >> 12 ) & 0xF ) );
				printhex( ( ( mac_address[1] >> 8 ) & 0xF ) );
				printchar('\n');
			}
		}
	}

	return 0;
}
