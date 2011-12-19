#include <xs1.h>
#include "ethernet_rx_client.h"
#include "ethernet_tx_client.h"


#pragma select handler
void safe_mac_rx(chanend cIn, 
                        unsigned char buffer[], 
                        unsigned int &len,
                        unsigned int &src_port,
                        int n) {
    inuint_byref(cIn, len);
    cIn <: 0;                             // Confirm that we take packet.
    for(int i = 0; i< ((len+3)>>2); i++) {
        cIn :> (buffer, unsigned int[]) [i];
    }
    src_port = 0;
}

void mac_set_custom_filter(chanend c_mac_svr, int x) {
}

int mac_get_macaddr(chanend c_mac, unsigned char macaddr[]) {
    return 1;
}

void mac_tx(chanend cOut, unsigned int buffer[], int nBytes, int ifnum) {
    cOut <: nBytes;
    for(int i = 0; i< ((nBytes+3)>>2); i++) {
        cOut <: buffer[i];
    }
}
