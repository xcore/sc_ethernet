// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


#include <xs1.h>
#include <xclib.h>
#include <print.h>
#include "miiDriver.h"
#include "mii.h"
#include "mii_lite.h"
#include "smi.h"
#include "miiClient.h"

#ifdef ETHERNET_USE_LITE

extern void mac_set_macaddr_lite(unsigned char macaddr[]);

static void theServer(chanend cIn, chanend cOut, chanend cNotifications,
		smi_interface_t &smi, chanend ?connect_status,
		chanend appIn, chanend appOut, char mac_address[6]) {
    int havePacket = 0;
    int outBytes;
    int nBytes, a, timeStamp;
    int b[3200];
    int txbuf[400];
    timer linkcheck_timer;
    unsigned linkcheck_time;
	struct miiData miiData;
    mac_set_macaddr_lite(mac_address);

    miiBufferInit(miiData, cIn, cNotifications, b, 3200);
    miiOutInit(cOut);
    
    linkcheck_timer :> linkcheck_time;

    while (1) {
        select {
		case linkcheck_timer when timerafter(linkcheck_time) :> void :
			{
				static int phy_status = 0;
				int new_status = smi_check_link_state(smi);
				if (new_status != phy_status) {
                                  if (!isnull(connect_status)) {
                                    outuchar(connect_status, 0);
                                    outuchar(connect_status, new_status);
                                    outuchar(connect_status, 0);
                                    outct(connect_status, XS1_CT_END);
                                  }
                                    phy_status = new_status;
				}
			}
			linkcheck_time += 10000000;
			break;

        // Notification that there is a packet to receive (causes select to continue)
        case inuchar_byref(cNotifications, miiData.notifySeen):
            break;

        // Receive a packet from buffer
        case havePacket => appIn :> int _:
            for(int i = 0; i < ((nBytes + 3) >>2); i++) {
                int val;
                asm("ldw %0, %1[%2]" : "=r" (val) : "r" (a) , "r" (i));
                appIn <: val;
            }
            miiFreeInBuffer(miiData, a);
            miiRestartBuffer(miiData);
            {a,nBytes,timeStamp} = miiGetInBuffer(miiData);
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
            {a,nBytes,timeStamp} = miiGetInBuffer(miiData);
            if (a != 0) {
                havePacket = 1;
                outuint(appIn, nBytes);
            }
        }
    } 
}


void miiSingleServer(out port ?p_mii_resetn,
                     smi_interface_t &smi,
                     mii_interface_t &m,
                     chanend appIn, chanend appOut,
                     chanend connect_status, unsigned char mac_address[6]) {
    chan cIn, cOut;
    chan notifications;
	miiInitialise(p_mii_resetn, m);
#ifndef MII_NO_SMI_CONFIG
	smi_init(smi);
	eth_phy_config(1, smi);
#endif
    par {
      {asm(""::"r"(notifications));miiDriver(m, cIn, cOut);}
        theServer(cIn, cOut, notifications, smi, connect_status, appIn, appOut, mac_address);
    }

}

void ethernet_server_lite(mii_interface_t &m,
                          int mac_address[2],
                          chanend c_rx, chanend c_tx,
                          smi_interface_t &?smi,
                          chanend ?connect_status)
{
  chan cIn, cOut;
  chan notifications;
  mii_port_init(m);
#ifndef MII_NO_SMI_CONFIG
  smi_init(smi);
  eth_phy_config(1, smi);
#endif
  par {
    {asm(""::"r"(notifications));miiDriver(m, cIn, cOut);}
    theServer(cIn, cOut, notifications, smi, connect_status,
              c_rx, c_tx, (mac_address, char[]));
  }
}


#endif
