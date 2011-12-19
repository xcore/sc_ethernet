// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <print.h>
#include "miiDriver.h"
#include "miiLLD.h"
#include "mii.h"
#include "smi.h"

void miiDriver(clock clk_smi,
               out port ?p_mii_resetn,
               smi_interface_t &smi,
               mii_interface_t &m,
               chanend cIn, chanend cOut, int simulation) {
    timer tmr;
    int x;
    if (!simulation) {
        smi_init(clk_smi, p_mii_resetn, smi);
        smi_reset(p_mii_resetn, smi, tmr);
    }
    mii_init(m, simulation, tmr);
    if (!simulation) {
        x = eth_phy_config(1, smi);
    }
    miiLLD(m.p_mii_rxd, m.p_mii_rxdv, m.p_mii_txd, cIn, cOut, m.p_mii_timing, tmr);
}

