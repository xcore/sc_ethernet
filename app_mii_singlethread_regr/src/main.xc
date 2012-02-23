// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


#include <xs1.h>
#include <xclib.h>
#include <print.h>
#include <platform.h>
#include <stdlib.h>
#include <stdio.h>
#include "miiDriver.h"
#include "miiClient.h"



#define PORT_ETH_RXCLK   XS1_PORT_1K
#define PORT_ETH_RXD     XS1_PORT_4F
#define PORT_ETH_RXDV    XS1_PORT_1G
#define PORT_ETH_TXCLK   XS1_PORT_1H
#define PORT_ETH_TXEN    XS1_PORT_1F
#define PORT_ETH_TXD     XS1_PORT_4E
#define PORT_ETH_RXER    XS1_PORT_1L
#define PORT_ETH_FAKE    XS1_PORT_8C

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

    PORT_ETH_FAKE,
  };




unsigned char packet[] = {
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,  0x80, 0x00, 0, 0,
    0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,
    0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,
    0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,
    0, 0, 0, 0,   0, 0, 0, 0
};

void emptyIn(chanend cIn, chanend cNotifications) {
    int b[1600];
    int address = 0x1C000;
    struct miiData miiData;

    miiBufferInit(miiData, cIn, cNotifications, b, 1600);
    asm("stw %0, %1[0]" :: "r" (b), "r" (address));

    while (1) {

        int nBytes, a, timeStamp;
        miiNotified(miiData, cNotifications);
        while(1) {
            {a,nBytes,timeStamp} = miiGetInBuffer(miiData);

            if (a == 0) {
                break;
            }
            asm("stw %0, %1[1]" :: "r" (a), "r" (address));
            asm("stw %0, %1[2]" :: "r" (nBytes), "r" (address));
            asm("stw %0, %1[6]" :: "r" (timeStamp), "r" (address));
            miiFreeInBuffer(miiData, a);
        }
        miiRestartBuffer(miiData);
    } 
}

on stdcore[0]: port p1k = XS1_PORT_1A;

void emptyOut(chanend cOut) {
    unsigned int txbuf[1600];
    timer t;
    int now;
    int packetLen = 64;
    int address = 0x1C000;
    int k;

    asm("ldw %0, %1[3]" : "=r" (packetLen): "r" (address));
    for(int i = 0; i < 72; i++) {
        (txbuf, unsigned char[])[i] = i;
    }
    miiOutInit(cOut);
    
    t :> now;
    while (1) {
        p1k when pinsneq(0) :> void;
        txbuf[0] = k;
        k = miiOutPacket(cOut, (txbuf,int[]), 0, packetLen);
        miiOutPacketDone(cOut);
    } 
}


void x() {
    set_thread_fast_mode_on();
}

void burn() {
    x();
    while(1);
}

void regression(void) {
    chan cIn, cOut;
    chan notifications;
    par {
        {
        	miiInitialise(null, mii);
        	miiDriver(mii, cIn, cOut);
        }
        {x(); emptyIn(cIn, notifications);}
        {x(); emptyOut(cOut);}
        {burn();}
        {burn();}
        {burn();}
        {burn();}
        {burn();}
    }
}

int main() {
    par {
        on stdcore[0]: {regression();}
    }
	return 0;
}
