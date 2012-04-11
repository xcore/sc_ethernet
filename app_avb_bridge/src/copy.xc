// Copyright (c) 2012, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <print.h>
#include "copy.h"
#include "xs1.h"
#include "miiClient.h"

void copyManager(chanend cIn, chanend queue) {
    int b[3000];
    struct miiData miiData;
    chan cNotifications;
    
    printstr("Test started\n");
    miiBufferInit(miiData, cIn, cNotifications, b, 3000);
    printstr("IN Inited\n");
//    miiOutInit(cOut);
    printstr("OUT inited\n");
    
    while (1) {
        int nBytes, a, timeStamp;
        miiNotified(miiData, cNotifications);
        while(1) {
            {a,nBytes,timeStamp} = miiGetInBuffer(miiData);

            if (a == 0) {
                break;
            }
            // decideBuffer();
            // queue :> allocate buffer
            // copy packet to allocated buffer
            // queue <: commit buffer
            miiFreeInBuffer(miiData, a);
        }
        miiRestartBuffer(miiData);
    } 
}
