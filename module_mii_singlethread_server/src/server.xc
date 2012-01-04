// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


#include <xs1.h>
#include <xclib.h>
#include <print.h>
#include "miiDriver.h"
#include "mii.h"
#include "miiClient.h"

extern char notifySeen;
extern void mac_set_macaddr(unsigned char macaddr[]);

static void theServer(chanend cIn, chanend cOut, chanend cNotifications, chanend appIn, chanend appOut, char mac_address[6]) {
    int havePacket = 0;
    int outBytes;
    int nBytes, a, timeStamp;
    int b[3200];
    int txbuf[400];

    mac_set_macaddr(mac_address);

    miiBufferInit(cIn, cNotifications, b, 3200);
    miiOutInit(cOut);
    
    while (1) {
        select {
        // Notification that there is a packet to receive (causes select to continue)
        case inuchar_byref(cNotifications, notifySeen):
            break;

        // Receive a packet from buffer
        case havePacket => appIn :> int _:
            for(int i = 0; i < ((nBytes + 3) >>2); i++) {
                int val;
                asm("ldw %0, %1[%2]" : "=r" (val) : "r" (a) , "r" (i));
                appIn <: val;
            }
            miiFreeInBuffer(a);
            miiRestartBuffer();
            {a,nBytes,timeStamp} = miiGetInBuffer();
            if (a == 0) {
                havePacket = 0;
            } else {
                outuint(appIn, nBytes);
            }
            break;

        // Transmit a packet
        case appOut :> outBytes:
            for(int i = 0; i < ((outBytes + 3) >>2); i++) {
                appOut :> txbuf[i];
            }
            miiOutPacket(cOut, txbuf, 0, outBytes);
            miiOutPacketDone(cOut);
            break;
        }

        // Check that there is a packet
        if (!havePacket) {
            {a,nBytes,timeStamp} = miiGetInBuffer();
            if (a != 0) {
                havePacket = 1;
                outuint(appIn, nBytes);
            }
        }
    } 
}

void miiSingleServer(clock clk_smi,
                     out port ?p_mii_resetn,
                     smi_interface_t &smi,
                     mii_interface_t &m,
                     chanend appIn, chanend appOut,
                     chanend server, unsigned char mac_address[6]) {
    chan cIn, cOut;
    chan notifications;
    par {
        miiDriver(clk_smi, p_mii_resetn, smi, m, cIn, cOut, 0);
        theServer(cIn, cOut, notifications, appIn, appOut, mac_address);
    }
}
