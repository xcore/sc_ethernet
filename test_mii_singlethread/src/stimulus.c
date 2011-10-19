// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "xsidevice.h"
#include <assert.h>
#include <stdio.h>

void *xsim = 0;

unsigned char packet[] = {
    0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0xD5,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,  0x80, 0x00, 0, 0,
    0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,
    0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,
    0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,
    0, 0, 0, 0
};

int main(int argc, char **argv) {
    unsigned int time = 0;
    int packetLength = 72;
    int clock = 0, cnt = 0, even = 0, oldready = 0, startTime = 0;
    int inPacketTX = 0;
    int nextTXTime = 20000;
    XsiStatus status = xsi_create(&xsim, argv[1]);
    assert(status == XSI_STATUS_OK);
    while (status != XSI_STATUS_DONE && time < 1000000) {
        time++;
        if(time % 20 == 3) {
            clock = !clock;
            xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_1A", 1, clock);
            if (clock == 1)  {
                if (time > nextTXTime) {
                    inPacketTX = 1;
                    nextTXTime += 7000;
                    cnt = 0;
                    switch(packetLength) {
                    case 72:
                        packet[60+8] = 0x94;
                        packet[61+8] = 0x53;
                        packet[62+8] = 0x18;
                        packet[63+8] = 0x39;
                        break;
                    case 73:
                        packet[60+8] = 0x00;
                        packet[61+8] = 0x83;
                        packet[62+8] = 0xa0;
                        packet[63+8] = 0x59;
                        packet[64+8] = 0x25;
                        break;
                    case 74:
                        packet[60+8] = 0x00;
                        packet[61+8] = 0x00;
                        packet[62+8] = 0xB7;
                        packet[63+8] = 0x64;
                        packet[64+8] = 0x96;
                        packet[65+8] = 0xA6;
                        break;
                    case 75:
                        packet[60+8] = 0x00;
                        packet[61+8] = 0x00;
                        packet[62+8] = 0x00;
                        packet[63+8] = 0xC6;
                        packet[64+8] = 0x5F;
                        packet[65+8] = 0xA1;
                        packet[66+8] = 0x87;
                        break;
                    case 76:
                        packet[60+8] = 0x00;
                        packet[61+8] = 0x00;
                        packet[62+8] = 0x00;
                        packet[63+8] = 0x00;
                        packet[64+8] = 0x57;
                        packet[65+8] = 0x29;
                        packet[66+8] = 0x82;
                        packet[67+8] = 0xA0;
                        break;
                    }
                }
                if (inPacketTX) {
                    if (cnt < packetLength) {
                        if (cnt == 0 && !even) {
                            startTime = time;
                        }
                        xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_1B", 1, 1);
                        xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_4A", 0xF, 
                                            even ? packet[cnt] >> 4 : packet[cnt]);
                        if (even) {
                            cnt++;
                        }
                        even = !even;
                    } else {
                        xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_1B", 1, 0);
                        inPacketTX = 0;
                        packetLength++;
                        if (packetLength == 77) {
                            packetLength = 72;
                        }
                    }
                }
            }
        }
        if(time % 20 == 4) {
            xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_1C", 1, clock);
            if (clock == 0) {
                unsigned ready;
                xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_1D", 1, &ready);
                if (ready) {
                    unsigned nibble;
                    if (!oldready) {
                        oldready = 1;
                    }
                    xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_4B", 0xF, &nibble);
                    printf("%01x", nibble);
                } else {
                    if (oldready) {
                        printf("\n", time);
                        oldready = 0;
                    }
                }
            }
        }
        if(time % 2 == 0) {
            status = xsi_clock(xsim);
            assert(status == XSI_STATUS_OK || status == XSI_STATUS_DONE );
        }
    }
    status = xsi_terminate(xsim);
    return 0;
}
