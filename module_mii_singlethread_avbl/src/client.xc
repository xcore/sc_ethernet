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
    cIn :> unsigned int _;
    src_port = 0;
}

#pragma select handler
void safe_mac_rx_timed(chanend cIn, 
                        unsigned char buffer[], 
                        unsigned int &len,
                        unsigned int &time,
                        unsigned int &src_port,
                        int n) {
    inuint_byref(cIn, len);
    cIn <: 0;                             // Confirm that we take packet.
    for(int i = 0; i< ((len+3)>>2); i++) {
        cIn :> (buffer, unsigned int[]) [i];
    }
    cIn :> time;
    src_port = 0;
}

#pragma select handler
void mac_rx_offset2(chanend cIn, 
                        unsigned char buffer[], 
                        unsigned int &len,
                        unsigned int &src_port) {
    unsigned highest16, new, i;
    inuint_byref(cIn, len);
    cIn <: 0;                             // Confirm that we take packet.
    cIn :> new;
    (buffer, unsigned int[]) [i] = new >> 16;
    highest16 = new << 16;
    for(i = 1; i< ((len+3)>>2); i++) {
        cIn :> new;
        {new,highest16} = mac(new, 0x10000, highest16, 0);
        (buffer, unsigned int[]) [i] = new;
    }
    (buffer, unsigned int[]) [i] = highest16;
    cIn :> unsigned int _;
    src_port = 0;
}

int mac_get_macaddr(chanend c_mac, unsigned char macaddr[]) {
    return 1;
}

void mac_tx(chanend cOut, unsigned int buffer[], int nBytes, int ifnum) {
    cOut <: nBytes;
    cOut <: 0;  // no time.
    for(int i = 0; i< ((nBytes+3)>>2); i++) {
        cOut <: buffer[i];
    }
}

void mac_tx_timed(chanend cOut, unsigned int buffer[], int nBytes, unsigned &time, int ifnum) {
    cOut <: nBytes;
    cOut <: 1;  // get time.
    for(int i = 0; i< ((nBytes+3)>>2); i++) {
        cOut <: buffer[i];
    }
    cOut :> time;
}
