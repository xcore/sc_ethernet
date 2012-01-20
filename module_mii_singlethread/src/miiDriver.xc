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

void miiInitialise(clock clk_smi,
        out port ?p_mii_resetn,
		smi_interface_t &smi,
		mii_interface_t &m)
{
	timer tmr;
#ifndef MII_DRIVER_SIMULATION
	smi_init(clk_smi, p_mii_resetn, smi);
	smi_reset(p_mii_resetn, smi, tmr);
    mii_init(m, 0, tmr);
	eth_phy_config(1, smi);
#else
    mii_init(m, 1, tmr);
#endif
}

void miiDriver(mii_interface_t &m, chanend cIn, chanend cOut)
{
    timer tmr;
    miiLLD(m.p_mii_rxd, m.p_mii_rxdv, m.p_mii_txd, cIn, cOut, m.p_mii_timing, tmr);
}

int miiCheckLinkState(smi_interface_t &smi)
{
	return eth_phy_checklink(smi);
}
