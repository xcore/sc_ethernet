#include <xs1.h>
#include <xccompat.h>
#include "ethernet_conf_derived.h"
#include "ethernet_rx_client.h"
#include "ethernet_tx_client.h"

static unsigned char mac_s_macaddr[6];

void mac_set_macaddr_lite(unsigned char macaddr[]) {
	for (int i=0; i<6; ++i) mac_s_macaddr[i] = macaddr[i];
}

int mac_get_macaddr_lite(chanend c_mac, unsigned char macaddr[]) {
	volatile unsigned* m = (unsigned*)mac_s_macaddr;
	while (*m==0);
	for (int i=0; i<6; ++i) macaddr[i] = mac_s_macaddr[i];
    return 1;
}

