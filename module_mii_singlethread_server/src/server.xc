// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


#include <xs1.h>
#include <xclib.h>
#include <print.h>
#include "mii.h"
#include "miiClient.h"
#include "miiDriver.h"

extern char notifySeen;

static void theServer(chanend cIn, chanend cOut, chanend cNotifications, chanend appIn, chanend appOut) {
    int havePacket = 0;
    int outBytes;
    int nBytes, a;
    int b[3200];
    int txbuf[400];

    miiBufferInit(cIn, cNotifications, b, 3200);
    miiOutInit(cOut);
    
    while (1) {
        select {
        case inuchar_byref(cNotifications, notifySeen):
            break;
//        case miiNotified(cNotifications);
        case havePacket => appIn :> int _:   // Receive confirmation.
            for(int i = 0; i < ((nBytes + 3) >>2); i++) {
                int val;
                asm("ldw %0, %1[%2]" : "=r" (val) : "r" (a) , "r" (i));
                appIn <: val;
            }
//            printintln(nBytes);
            miiFreeInBuffer(a);
            miiRestartBuffer();
            {a,nBytes} = miiGetInBuffer();
            if (a == 0) {
                havePacket = 0;
            } else {
                outuint(appIn, nBytes);
            }
            break;
        case appOut :> outBytes:
            for(int i = 0; i < ((outBytes + 3) >>2); i++) {
                appOut :> txbuf[i];
            }
            if(outBytes < 64) {
                printstr("ERR ");
                printhexln(outBytes);
            }
            miiOutPacket(cOut, txbuf, 0, outBytes);
            miiOutPacketDone(cOut);
            break;
        }
        if (!havePacket) {
            {a,nBytes} = miiGetInBuffer();
            if (a != 0) {
                havePacket = 1;
                outuint(appIn, nBytes);
            }
        }
    } 
}

void miiSingleServer(chanend appIn, chanend appOut, chanend server) {
    chan cIn, cOut;
    chan notifications;
    par {
        miiDriver(cIn, cOut);
        theServer(cIn, cOut, notifications, appIn, appOut);
    }
}
