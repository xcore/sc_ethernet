// Copyright (c) 2012, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <platform.h>
#include "miiDriver.h"
#include "smi.h"

#include "copy.h"
#include "transmitter.h"
#include "queue.h"
#include "avbManager.h"

#define SWITCH_CORE 0
#define AUDIO_CORE  1

on stdcore[SWITCH_CORE]: mii_interface_t miiLeft = {
    XS1_CLKBLK_1, XS1_CLKBLK_2,
    PORT_ETH_RXCLK_0, XS1_PORT_16A, PORT_ETH_RXD_0, PORT_ETH_RXDV_0,
    PORT_ETH_TXCLK_0, PORT_ETH_TXEN_0, PORT_ETH_TXD_0,
    XS1_PORT_32A,
};

on stdcore[SWITCH_CORE]: mii_interface_t miiRight = {
    XS1_CLKBLK_3, XS1_CLKBLK_4,
    PORT_ETH_RXCLK_1, XS1_PORT_16B, PORT_ETH_RXD_1, PORT_ETH_RXDV_1,
    PORT_ETH_TXCLK_1, PORT_ETH_TXEN_1, PORT_ETH_TXD_1,
    XS1_PORT_8B,
};

on stdcore[SWITCH_CORE]: smi_interface_t smiLeft = {
    0x80000000,
    PORT_ETH_MDIOFAKE_0,
    PORT_ETH_MDIOC_0
};

on stdcore[SWITCH_CORE]: smi_interface_t smiRight = {
    0,
    PORT_ETH_MDIO_1,
    PORT_ETH_MDC_1
};

on stdcore[SWITCH_CORE]: clock clk_smi = XS1_CLKBLK_5;

static void ethernetSwitch() {
    chan cInLeft, cInRight, cOutLeft, cOutRight;
    chan qLeft, qRight, qAVB;
    streaming chan qTransmit;
    miiInitialise(null, miiLeft);
    miiInitialise(null, miiRight);
    par {
        miiDriver(miiLeft, cInLeft, cOutLeft);        // done
        miiDriver(miiRight, cInRight, cOutRight);     // done
        copyManager(cInLeft, qLeft);
        copyManager(cInRight, qRight);
        queueManager(qLeft, qRight, qTransmit, qAVB);
        transmitter(qTransmit, cOutLeft, cOutRight);  // done
        avbManager(qAVB);
    }
}

static void audio() {
}

int main(void) {
    par {
        on stdcore[SWITCH_CORE]: ethernetSwitch();
        on stdcore[AUDIO_CORE]: audio();
    }
    return 0;
}
