// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#define MII_FORCE_USE_LITE
#include "ethernet_conf_derived.h"

#include "mii_driver.h"
#include "mii_lld.h"
#include "mii.h"
#include "mii_lite.h"

void mii_initialise(out port ?p_mii_resetn,
                   mii_interface_lite_t &m)
{
#ifndef MII_DRIVER_SIMULATION
#ifndef MII_NO_RESET
    if (!isnull(p_mii_resetn)) {
        timer tmr;
        phy_reset(p_mii_resetn, tmr);
    }
#endif
#endif
    mii_port_init(m);
}


// TODO: implement miiDriver straight in miiLLD.
void mii_driver(mii_interface_lite_t &m, chanend cIn, chanend cOut)
{
    timer tmr;
    miiLLD(m.p_mii_rxd, m.p_mii_rxdv, m.p_mii_txd, cIn, cOut, m.p_mii_timing, tmr);
}


