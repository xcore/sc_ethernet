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
    int nextTXTime = 30000;
    int nibbles = 0;
    int expected = 64;
    int nbytesin = 0;
    XsiStatus status = xsi_create(&xsim, argv[1]);
    int ltod;
    int ltoh;
    int first = 1;
    assert(status == XSI_STATUS_OK);
    if (argc != 4) {
        printf("Usage %s SimArgs toDeviceLen toHostLen (%d)\n", argv[0], argc);
        exit(0);
    }
    ltod = atoi(argv[2]);
    ltoh = atoi(argv[3]);
    xsi_write_mem(xsim, "stdcore[0]", 0x1D00C, 4, &ltoh);
    printf("Test %d to host, %d to device\n", ltoh, ltod);
    while (status != XSI_STATUS_DONE && time < 6000000) {
        time++;
        if(time % 20 == 3) {
            clock = !clock;
            xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_1A", 1, clock);
            if (clock == 1)  {
                if (time > nextTXTime) {
                    inPacketTX = 1;
                    nextTXTime += 7000;
                    cnt = 0;
                    switch(ltod) {
                    case 64:
                        packet[60+8] = 0x94;
                        packet[61+8] = 0x53;
                        packet[62+8] = 0x18;
                        packet[63+8] = 0x39;
                        break;
                    case 65:
                        packet[60+8] = 0x00;
                        packet[61+8] = 0x83;
                        packet[62+8] = 0xa0;
                        packet[63+8] = 0x59;
                        packet[64+8] = 0x25;
                        break;
                    case 66:
                        packet[60+8] = 0x00;
                        packet[61+8] = 0x00;
                        packet[62+8] = 0xB7;
                        packet[63+8] = 0x64;
                        packet[64+8] = 0x96;
                        packet[65+8] = 0xA6;
                        break;
                    case 67:
                        packet[60+8] = 0x00;
                        packet[61+8] = 0x00;
                        packet[62+8] = 0x00;
                        packet[63+8] = 0xC6;
                        packet[64+8] = 0x5F;
                        packet[65+8] = 0xA1;
                        packet[66+8] = 0x87;
                        break;
                    }
                    packetLength = ltod + 8;
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
                            if (cnt == 40) {
                                unsigned ptr, index, len, rdt, wrt;
                                xsi_read_mem(xsim, "stdcore[0]", 0x1D000, 4, &ptr);
                                xsi_read_mem(xsim, "stdcore[0]", 0x1D004, 4, &index);
                                xsi_read_mem(xsim, "stdcore[0]", 0x1D008, 4, &len);
                                ptr += index;
                                if (len != ltod) {
                                    if (!first) {
                                        printf("ERROR: %08x %d\n", ptr, len);
                                    }
                                }
                                first = 0;
                                len = 0;
                                xsi_write_mem(xsim, "stdcore[0]", 0x1D008, 4, &len);
                                xsi_read_mem(xsim, "stdcore[0]", 0x1D010, 4, &rdt);
                                xsi_read_mem(xsim, "stdcore[0]", 0x1D014, 4, &wrt);
//                                printf("Diff %d  %d\n", wrt-rdt, rdt*10 - time);
                            }
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
                    xsi_sample_port_pins(xsim, "stdcore[0]", "XS1_PORT_4B", 0xF, &nibble);
                    nibbles++;
//                    printf("%01x", nibble);
                    oldready++;
                    if (oldready >=25 && oldready <=26) {
                        nbytesin = nbytesin >> 4 | nibble << 4;
                    }
                } else {
                    if (oldready) {
                        if (nibbles != ltoh*2 + 16) { // 16 nibbles preamble.
                            printf("ERROR: received %d nibbles rather than 2*%d + 24\n", nibbles, expected);
                        }
                        fflush(stdout);
                        nbytesin = 0;
                        nibbles = 0;
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
