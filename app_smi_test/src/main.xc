// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


#include <xs1.h>
#include <xclib.h>
#include <stdio.h>
#include <print.h>
#include <platform.h>
#include <stdlib.h>
#include "smi.h"

#define ETHCORE 0

on stdcore[ETHCORE]: smi_interface_t smi = { 0, XS1_PORT_1M, XS1_PORT_1N };

on stdcore[ETHCORE]: clock clk_smi = XS1_CLKBLK_1;

void smiTest() {
    timer tmr;
    int resetTime;

    tmr :> resetTime;
    resetTime += 50000000;
    tmr when timerafter(resetTime) :> void;

    smi_port_init(clk_smi, smi);
    for(int i = 0; i < 32; i++) {
        int v2, v3, v18;
        smi.phy_address = i;
        v2 = smi_reg(smi, 2, 0, 1);
        v3 = smi_reg(smi, 3, 0, 1);
        v18 = smi_reg(smi, 18, 0, 1);
        if ((v2 & v3 & v18) != 0xffff) {
            printf("Phy addr %02x: reg 2, 3, 18: %04x %04x %04x\n", i, v2, v3, v18);
        }
    }
}


int main() {
    par {
        on stdcore[ETHCORE]: smiTest();
    }
	return 0;
}
