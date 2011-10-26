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
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F,
    0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F,
    0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F,
};

int verbose = 0;

int ltod;
int ltoh;
int triggerCnt = 0;
int allTriggersDone = 0;

#define MT 800

char triggerBefore[MT], triggerAfter[MT];

int setTriggers() {
    int i;
    int step = 1;
    if (step != 1) {
        fprintf(stderr, "Warning only doing 1 in every %d steps for shmoo\n", step);
    }
    for(i = ltoh*8 + 96; i >= ltoh*8 - 64; i-=step) {  // Make tail of Tx collide with head of Rx
        triggerBefore[i] = 1;
        triggerCnt++;
    }
    for(i = 128; i > 0; i-=step) {                    // Make head of Tx collide with head of Rx
        triggerBefore[i] = 1;
        triggerCnt++;
    }
    for(i = 0; i <= 128; i+=step) {                   // And tail with tail
        triggerAfter[i] = 1;
        triggerCnt++;
    }
    for(i = ltod*8 - 96; i <= ltoh*8 + 64 ; i+=step) { // and head with tail.
        triggerAfter[i] = 1;
        triggerCnt++;
    }
}

int triggerOutput(int time, int nextTXTime) {    
    int ticksAfter = time - nextTXTime;
    ticksAfter /= 10;
    if (ticksAfter < 0) {
        ticksAfter = -ticksAfter;
        if (ticksAfter < MT && triggerBefore[ticksAfter]) {
            if (verbose) printf("Before: %d\n", ticksAfter);
            triggerBefore[ticksAfter] = 0;
            triggerCnt--;
            return 1;
        }
    } else {
        if (ticksAfter < MT && triggerAfter[ticksAfter]) {
            if (verbose) printf("After: %d\n", ticksAfter);
            triggerAfter[ticksAfter] = 0;
            triggerCnt--;
            if (triggerCnt == 0) {
                allTriggersDone = 1;
            }
            return 1;
        }
    }
    return 0;
}

int main(int argc, char **argv) {
    unsigned int time = 0;
    int packetLength = 72;
    int clock = 0, cnt = 0, even = 0, oldready = 0, startTime = 0;
    int inPacketTX = 0;
    int cycleStart = 60000;
    int cycleTime = 13000;  // Do an IN and trigger an OUT each time this cycle
    int nextTXTime;
    int nibbles = 0;
    int expected = 64;
    int nbytesin = 0;
    XsiStatus status;
    int first = 1;
    int pinLowTime = -1;
    int outputRequired = 0, inputRequired = 0;
    if (argc != 4) {
        printf("Usage %s SimArgs toDeviceLen toHostLen (%d)\n", argv[0], argc);
        exit(0);
    }
    ltod = atoi(argv[2]);
    ltoh = atoi(argv[3]);
    setTriggers();
    fprintf(stdout, "@0LINES %d %d\n", cycleTime/10, triggerCnt);
    fprintf(stdout, "@0FILE images/blah_%d_%d.ppm\n", ltod, ltoh);
    fflush(stdout);
    status = xsi_create(&xsim, argv[1]);
    assert(status == XSI_STATUS_OK);
    xsi_write_mem(xsim, "stdcore[0]", 0x1D00C, 4, &ltoh);
    printf("Test %d to host, %d to device\n", ltoh, ltod);
    while (status != XSI_STATUS_DONE) {
        time++;
        if (time == cycleStart) {
            if (allTriggersDone) {
                break;
            }
            nextTXTime = time + cycleTime / 2;
            cycleStart += cycleTime;
            outputRequired = 1; // TODO
            inputRequired = 1;
            fprintf(stderr, "%3d\r", triggerCnt);
        }
        if (outputRequired) {
            if (triggerOutput(time, nextTXTime)) {
                xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_1K", 1, 1);
                pinLowTime = time + 1000;
                outputRequired = 0;
                if (verbose) printf("Trigger OUT at %d\n", time);
            }
        }
        if (time == pinLowTime) {
            xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_1K", 1, 0);            
            if (verbose) printf("UNTrigger OUT at %d\n", time);
        }
        if(time % 20 == 3) {
            clock = !clock;
            xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_1A", 1, clock);
            if (clock == 1)  {
                if (inputRequired && time >= nextTXTime) {
                    if (verbose) printf("Trigger IN at %d\n", time);
                    inputRequired = 0;
                    inPacketTX = 1;
                    cnt = 0;
                    for(int i = 64; i < ltod; i++) {
                        packet[i+8] = i;
                    }
                    switch(ltod) {
                    case 64:
                        packet[64+8] = 0x8c; packet[65+8] = 0xce; packet[66+8] = 0x0e; packet[67+8] = 0x10;
                        break;
                    case 65:
                        packet[65+8] = 0xd8; packet[66+8] = 0x6f; packet[67+8] = 0xc0; packet[68+8] = 0x40;
                        break;
                    case 66:
                        packet[66+8] = 0x02; packet[67+8] = 0x04; packet[68+8] = 0x91; packet[69+8] = 0x5b;
                        break;
                    case 67:
                        packet[67+8] = 0x19; packet[68+8] = 0x3f; packet[69+8] = 0x85; packet[70+8] = 0xa4;
                        break;
                    case 68:
                        packet[68+8] = 0x58; packet[69+8] = 0xd2; packet[70+8] = 0x18; packet[71+8] = 0x59;
                        break;
                    case 69:
                        packet[69+8] = 0x10; packet[70+8] = 0xab; packet[71+8] = 0x5a; packet[72+8] = 0xc6;
                        break;
                    case 70:
                        packet[70+8] = 0x5d; packet[71+8] = 0x10; packet[72+8] = 0xc5; packet[73+8] = 0xc9;
                        break;
                    case 71:
                        packet[71+8] = 0x71; packet[72+8] = 0xe3; packet[73+8] = 0xae; packet[74+8] = 0x58;
                        break;
                    }
                    packetLength = ltod + 8 + 4;
                }
                if (inPacketTX) {
                    if (cnt < packetLength) {
                        unsigned nibble;
                        if (cnt == 0 && !even) {
                            startTime = time;
                        }
                        nibble = even ? packet[cnt] >> 4 : packet[cnt];
                        xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_1B", 1, 1);
                        xsi_drive_port_pins(xsim, "stdcore[0]", "XS1_PORT_4A", 0xF, nibble);
//                        if (verbose) printf("%01x", nibble);
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
                                } else {
                                    if (verbose) {
                                        printf("IN seen %d at %08x\n", len, ptr);
                                    }
                                }
                                first = 0;
                                len = 0;
                                xsi_write_mem(xsim, "stdcore[0]", 0x1D008, 4, &len);
                                xsi_read_mem(xsim, "stdcore[0]", 0x1D010, 4, &rdt);
                                xsi_read_mem(xsim, "stdcore[0]", 0x1D014, 4, &wrt);
                                if (verbose) {
                                    printf("Diff %d  %d\n", wrt-rdt, rdt*10 - time);
                                }
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
                    if (verbose) printf("%01x", nibble);
                    oldready++;
                    if (oldready >=25 && oldready <=26) {
                        nbytesin = nbytesin >> 4 | nibble << 4;
                    }
                } else {
                    if (oldready) {
                        if (nibbles != ltoh*2 + 16 + 8) { // 16 nibbles preamble, 8 nibbles CRC.
                            printf("ERROR: received %d nibbles rather than 2*%d + 24\n", nibbles, expected);
                        } else {
                            if (verbose) printf("\n");
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
