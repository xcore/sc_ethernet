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

enum {
    THREAD_NONE = -1,
    THREAD_REST = 0,
    THREAD_PTP = 1,
    THREAD_AUDIO = 2,
};

static int calcDestinationThread(int addr) {
    int b3, result;
    asm("ldw %0, %1[3]" : "=r" (b3) : "r" (addr));
    if ((b3 & 0xffff) == 0x0081) {
        asm("ldw %0, %1[4]" : "=r" (b3) : "r" (addr));
    }

    switch (b3 & 0xFFFF) {
    case 0xF788:
        result = THREAD_PTP;
        break;
    case 0xEA22:
    case 0xF588:
    case 0xF688:
        result = THREAD_REST;
        break;
//    case 0x0608:
//    case 0x0008:
//        result = MAC_FILTER_ARPIP;
//        break;
    case 0xF022:
        result = ((b3 >> 23) & 1) ? THREAD_REST : THREAD_AUDIO;
        break;
    default:
        result = THREAD_NONE;
        break;
    }

    return result;
}

static void theServer(chanend cIn, chanend cOut, chanend cNotifications, chanend appIn[3], chanend appOut[2]) {
    int outBytes;
    int b[3200];
    int txbuf[400];
    int timeRequired, t;

    struct {
        int full;
        int addr;
        int nBytes;
        int time;
    } packetStore[3];

    miiBufferInit(cIn, cNotifications, b, 3200);
    miiOutInit(cOut);
    
    while (1) {
        select {
        case inuchar_byref(cNotifications, notifySeen):
            break;
        case (int i = 0; i < 3; i++) 
            packetStore[i].full => appIn[i] :> int _:
            for(int i = 0; i < ((packetStore[i].nBytes + 3) >>2); i++) {
                int val;
                asm("ldw %0, %1[%2]" : "=r" (val) : "r" (packetStore[i].addr) , "r" (i));
                appIn[i] <: val;
            }
            appIn[i] <: packetStore[dest].time;
            miiFreeInBuffer(packetStore[i].addr);
            miiRestartBuffer();
            packetStore[i].full = 0;
            break;
        case (int i = 0; i < 2; i++) 
            appOut[i] :> outBytes:
            appOut[i] :> timeRequired;
            for(int i = 0; i < ((outBytes + 3) >>2); i++) {
                appOut[i] :> txbuf[i];
            }
            if(outBytes < 64) {
                printstr("ERR ");
                printhexln(outBytes);
            }
            t = miiOutPacket(cOut, txbuf, 0, outBytes);
            if (timeRequired) {
                appOut[i] <: t;
            }
            miiOutPacketDone(cOut);
            break;
        }
        while (1) {
            int a, n, dest, t;
            {a,n,t} = miiGetInBuffer();
            if (a == 0) {
                break; // no packets available.
            }
            dest = calcDestinationThread(a);
            if (dest == THREAD_NONE) {
                miiFreeInBuffer(a);
                miiRestartBuffer();
                continue;
            }
            if (packetStore[dest].full) {
                miiFreeInBuffer(packetStore[dest].addr);
                miiRestartBuffer();
            }
            packetStore[dest].full = 1;
            packetStore[dest].addr = a;
            packetStore[dest].nBytes = n;
            packetStore[dest].time = t;
        }
    } 
}

void miiAVBListenerServer(chanend appIn[3], chanend appOut[2], chanend server) {
    chan cIn, cOut;
    chan notifications;
    par {
        miiDriver(cIn, cOut, 0);
        theServer(cIn, cOut, notifications, appIn, appOut);
    }
}
