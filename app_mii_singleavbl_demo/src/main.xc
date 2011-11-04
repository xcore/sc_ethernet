// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <platform.h>
#include "miiSingleServer.h"


// Program entry point
int main(void) {
	chan mac_rx[3], mac_tx[2], connect_status;

	par
	{
	 	on stdcore[1]: miiAVBListenerServer(mac_rx, mac_tx, connect_status);

	}
	return 0;
}
