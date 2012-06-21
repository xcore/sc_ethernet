// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


#include <xs1.h>
#include <xclib.h>
#include <stdio.h>
#include <print.h>
#include <platform.h>
#include <stdlib.h>
#include <xscope.h>

#include "miiClient.h"
#include "miiDriver.h"
#include "smi.h"


on stdcore[0]: mii_interface_t mii =
  {
    XS1_CLKBLK_1,
    XS1_CLKBLK_2,

    PORT_ETH_RXCLK,
    PORT_ETH_RXER,
    PORT_ETH_RXD,
    PORT_ETH_RXDV,

    PORT_ETH_TXCLK,
    PORT_ETH_TXEN,
    PORT_ETH_TXD,

    XS1_PORT_8C,
  };

on stdcore[0]: port p_reset = PORT_SHARED_RS;
on stdcore[0]: smi_interface_t smi = { 0, PORT_ETH_MDIO, PORT_ETH_MDC };
on stdcore[0]: clock clk_smi = XS1_CLKBLK_5;

int alignment_dummy=0;
unsigned int packet[1540/4] = {
    0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00
};

void test(chanend cIn, chanend cOut, chanend cNotifications) {
    int b[3200];
    struct miiData miiData;
	unsigned size=64;
    
    miiBufferInit(miiData, cIn, cNotifications, b, 3200);
    miiOutInit(cOut);
    
    // Send packet 1
    miiOutPacket(cOut, (packet, int[]), 0, 64);

    while (1) {
        select {

        // Notification that there is a packet to receive (causes select to continue)
        case inuchar_byref(cNotifications, miiData.notifySeen): {
			unsigned address, length, timeStamp;
			do {
				{address,length,timeStamp} = miiGetInBuffer(miiData);
				if (address != 0) {
					miiFreeInBuffer(miiData, address);
					miiRestartBuffer(miiData);
				}
			} while (address!=0);
		}
		break;

        // Transmit a packet
        case miiOutPacketDone(cOut) : {
        	unsigned t = miiOutPacket(cOut, (packet, int[]), 0, size);
        	xscope_probe_data(0, t);
        	size += 1;
        	if (size > 1500) size=64;
        }
        break;

        }
    }
}



int main() {
    chan cIn, cOut;
    chan notifications;

    par {
        on stdcore[0]: {
                char mac_address[6];

                xscope_register(1, XSCOPE_DISCRETE, "n", XSCOPE_UINT, "i");
                xscope_config_io(XSCOPE_IO_BASIC);

                // Bring PHY out of reset
                p_reset <: 0x2;

                // Start server
                {
                	miiInitialise(null, mii);

#ifndef MII_NO_SMI_CONFIG
                    smi_port_init(clk_smi, smi);
                    eth_phy_config(1, smi);
#endif
                	miiDriver(mii, cIn, cOut);
                }
        }

        on stdcore[0] : {
        	test(cIn, cOut, notifications);
        }
    }
	return 0;
}
