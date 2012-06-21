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

on stdcore[ETHCORE]: smi_interface_t smi0 = { 0x80000000, XS1_PORT_8A, XS1_PORT_4C };
on stdcore[ETHCORE]: smi_interface_t smi1 = { 0, XS1_PORT_1M, XS1_PORT_1N };

void smiTest(smi_interface_t &smi) {
    timer tmr;
    int resetTime;

    tmr :> resetTime;
    resetTime += 50000000;
    tmr when timerafter(resetTime) :> void;

    smi_init(smi);
    while(1) {
        timer t;
        int t0, t1;
        int v2, v3, v18;
    t :> t0;
        v2 = smi_reg(smi, 2, 0, 1);
    t :> t1;
        v3 = smi_reg(smi, 3, 0, 1);
        v18 = smi_reg(smi, 18, 0, 1);
        if ((v2 & v3 & v18) != 0xffff) {
            printf("Phy addr %06x: reg 2, 3, 18: %04x %04x %04x, %d ref clocks\n", eth_phy_id(smi), v2, v3, v18, t1-t0);
        }
    }
}


int main() {
    par {
        on stdcore[ETHCORE]: smiTest(smi1);
        on stdcore[ETHCORE]: while(1);
        on stdcore[ETHCORE]: while(1);
        on stdcore[ETHCORE]: while(1);
        on stdcore[ETHCORE]: while(1);
        on stdcore[ETHCORE]: while(1);
        on stdcore[ETHCORE]: while(1);
        on stdcore[ETHCORE]: while(1);
    }
	return 0;
}
