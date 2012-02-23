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
#include "miiClient.h"
#include "miiDriver.h"
#include "smi.h"


on stdcore[2]: mii_interface_t mii0 =
  {
    XS1_CLKBLK_1, XS1_CLKBLK_2,
    PORT_ETH_RXCLK_0, PORT_ETH_RXER_0, PORT_ETH_RXD_0, PORT_ETH_RXDV_0,
    PORT_ETH_TXCLK_0, PORT_ETH_TXEN_0, PORT_ETH_TXD_0,
    XS1_PORT_8A,
  };

on stdcore[2]: mii_interface_t mii1 =
  {
    XS1_CLKBLK_3, XS1_CLKBLK_4,
    PORT_ETH_RXCLK_1, PORT_ETH_RXER_1, PORT_ETH_RXD_1, PORT_ETH_RXDV_1,
    PORT_ETH_TXCLK_1, PORT_ETH_TXEN_1, PORT_ETH_TXD_1,
    XS1_PORT_8B,
  };

on stdcore[2]: out port p_mii_resetn = PORT_ETH_RST_N;
on stdcore[2]: smi_interface_t smi0 = { 0, PORT_ETH_MDIO_0, PORT_ETH_MDC_0 };
on stdcore[2]: smi_interface_t smi1 = { 0, PORT_ETH_MDIO_1, PORT_ETH_MDC_1 };

on stdcore[2]: clock clk_smi = XS1_CLKBLK_5;

void txrx(chanend cIn, chanend cOut, chanend cNotifications,
          streaming chanend packetTx, streaming chanend packetRx) {
    int b[3200];
    int txbuf[400];
    struct miiData miiData;
    int length;

    printstr("Test started\n");
    miiBufferInit(miiData, cIn, cNotifications, b, 3200);
    miiOutInit(cOut);
    
    while (1) {
        int nBytes, a, timeStamp;
        select {
        case miiNotified(miiData, cNotifications);
        case packetTx :> length:
            for(int i = 0; i <= (length >> 2); i++) {
                packetTx :> txbuf[i];
            }
            miiOutPacket(cOut, txbuf, 0, length);
            miiOutPacketDone(cOut);
            break;
        }
        while(1) {
            {a,nBytes,timeStamp} = miiGetInBuffer(miiData);

            if (a == 0) {
                break;
            }
            packetRx <: nBytes;
            for(int i = 0; i <= (nBytes >> 2); i++) {
                int v;
                asm("ldw %0, %1[%2]" : "=r" (v) : "r" (a), "r" (i));
                packetRx <: v;
            }
            miiFreeInBuffer(miiData, a);
        }
        miiRestartBuffer(miiData);
    } 
}

static void buffer(streaming chanend tx, streaming chanend rx) {
    int buf[400];
    int length;
    unsigned int random = 0;

    while(1) {
        select {
        case rx :> length:
            for(int i = 0; i <= (length >> 2); i++) {
                rx :> buf[i];
            }
            crc32(random, ~length, 0xEDB88320);
            if ((random & 7) == 0) {
                buf[8] ^= 0xAAAAAAAA;
            }
            tx <: length;
            for(int i = 0; i <= (length >> 2); i++) {
                tx <: buf[i];
            }
            crc32(random, ~length, 0xEDB88320);
            if ((random & 7) == 0) {
                tx <: length;
                for(int i = 0; i <= (length >> 2); i++) {
                    tx <: buf[i];
                }
            }
            break;
        }
    }
}

int main() {
    chan cIn0, cOut0;
    chan cIn1, cOut1;
    chan notifications0;
    chan notifications1;
    streaming chan from0, to0, from1, to1;
    par {
        on stdcore[2]: {
        	miiInitialise(p_mii_resetn, mii0);
        	miiInitialise(p_mii_resetn, mii1);

#ifndef MII_NO_SMI_CONFIG
            smi_port_init(clk_smi, smi0);
            smi_port_init(clk_smi, smi1);
            eth_phy_config(1, smi0);
            eth_phy_config(1, smi1);
#endif
            par {
                miiDriver(mii0, cIn0, cOut0);
                miiDriver(mii1, cIn1, cOut1);
            }
        }
        on stdcore[2]: txrx(cIn0, cOut0, notifications0, from1, to1);
        on stdcore[2]: txrx(cIn1, cOut1, notifications1, from0, to0);
        on stdcore[0]: buffer(from0, to1);
        on stdcore[0]: buffer(from1, to0);
    }
	return 0;
}
