#include <xs1.h>
#include "ethernet_rx_client.h"
#include "ethernet_tx_client.h"

static unsigned char macaddr[6];

void mac_set_macaddr(unsigned char macaddr[]) {
	for (i=0; i<6; ++i) s_macaddr[i] = macaddr[i];
}

int mac_get_macaddr(chanend c_mac, unsigned char macaddr[]) {
	for (i=0; i<6; ++i) macaddr[i] = s_macaddr[i];
    return 1;
}
