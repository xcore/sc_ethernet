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
#include "mii.h"
#include "miiClient.h"
#include "miiDriver.h"






unsigned char packet[] = {
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,  0x80, 0x00, 0, 0,
    0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,
    0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,
    0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,
    0, 0, 0, 0,   0, 0, 0, 0
};

extern int nextBuffer;

void emptyIn(chanend cIn, chanend cNotifications) {
    int b[1600];
    timer t;
    int now;
    int address = 0x1D000;

    miiBufferInit(cIn, cNotifications, b, 1600);
    asm("stw %0, %1[0]" :: "r" (b), "r" (address));

    while (1) {

        int nBytes, a;
        miiNotified(cNotifications);
        while(1) {
            {a,nBytes} = miiGetInBuffer();

            if (a == 0) {
                break;
            }
            asm("stw %0, %1[1]" :: "r" (a), "r" (address));
            asm("stw %0, %1[2]" :: "r" (nBytes), "r" (address));
            miiFreeInBuffer(a);
        }
        miiRestartBuffer();
    } 
}

on stdcore[0]: port p1k = XS1_PORT_1A;

void emptyOut(chanend cOut) {
    unsigned int txbuf[1600];
    timer t;
    int now;
    int packetLen = 64;
    int address = 0x1D000;
    int k;

    asm("ldw %0, %1[3]" : "=r" (packetLen): "r" (address));
    for(int i = 0; i < 72; i++) {
        (txbuf, unsigned char[])[i] = i;
    }
    miiOutInit(cOut);
    
    t :> now;
    while (1) {
        p1k when pinsneq(0) :> void;
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
        { miiDriver(cIn, cOut, 1);}
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
