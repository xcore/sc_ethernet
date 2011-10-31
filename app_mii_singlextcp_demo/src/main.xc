// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <platform.h>
#include "uip_server.h"
#include "xhttpd.h"
#include "miiSingleServer.h"

// IP Config - change this to suit your network.  Leave with all
// 0 values to use DHCP
xtcp_ipconfig_t ipconfig = {
		{ 169, 254, 13, 15 }, // ip address (eg 192,168,0,2)
		{ 255, 255, 0, 0 }, // netmask (eg 255,255,255,0)
		{ 169, 254, 11, 11 } // gateway (eg 192,168,0,1)
};

// Program entry point
int main(void) {
	chan mac_rx[1], mac_tx[1], xtcp[1], connect_status;

	par
	{
	 	on stdcore[1]: miiSingleServer(mac_rx[0], mac_tx[0], connect_status);

		// The TCP/IP server thread
		on stdcore[1]: uip_server(mac_rx[0], mac_tx[0],
				xtcp, 1, ipconfig,
				connect_status);

		// The webserver thread
		on stdcore[1]: xhttpd(xtcp[0]);

	}
	return 0;
}
