// Copyright (c) 2012, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include "transmitter.h"
#include "miiClient.h"

void transmitter(streaming chanend qTransmit, chanend cOutLeft, chanend cOutRight) {
    short leftTime, rightTime, cmd, address, nBytes;
    unsigned char token;
    miiOutInit(cOutLeft);
    miiOutInit(cOutRight);
    while(1) {
        select {
        case qTransmit :> cmd:
            qTransmit :> address;
            qTransmit :> nBytes;
            if (cmd == GO_LEFT) {
                leftTime = miiOutPacket_(cOutLeft, address, nBytes);
            } else {
                rightTime = miiOutPacket_(cOutRight, address, nBytes);
            }
            break;
        case inct_byref(cOutLeft, token):
            qTransmit <: GO_LEFT | leftTime;
            break;
        case inct_byref(cOutRight, token):
            qTransmit <: GO_RIGHT | rightTime;
            break;
        }
    }
}
