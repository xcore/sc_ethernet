#include <stdio.h>
#include "miiDriver.h"
#include "miiLLD.h"

extern void mii_init();

extern buffered in port:32 p_mii_rxd;
extern in port p_mii_rxdv;
extern buffered out port:32 p_mii_txd;

void smi_init();
int smi_config(int);

extern void miiDriver(chanend cIn, chanend cOut) {
    mii_init();
    smi_init();
    printf("SMI INIT: %d\n", smi_config(1));
    miiLLD(p_mii_rxd, p_mii_rxdv, p_mii_txd, cIn, cOut);
}

