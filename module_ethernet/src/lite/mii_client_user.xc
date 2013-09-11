// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <xclib.h>
#include <print.h>
#include "mii_client.h"
#include "mii_lld.h"

#define POLY   0xEDB88320

extern void mii_install_handler(struct miiData &this,
                                int bufferAddr,
                                chanend miiChannel,
                                chanend notificationChannel);


static int value_1(int address) {
    int retVal;
    asm("ldw %0, %1[1]" : "=r" (retVal) : "r" (address));
    return retVal;
}

static int value_2(int address) {
    int retVal;
    asm("ldw %0, %1[2]" : "=r" (retVal) : "r" (address));
    return retVal;
}

static int value_3(int address) {
    int retVal;
    asm("ldw %0, %1[3]" : "=r" (retVal) : "r" (address));
    return retVal;
}

static int CRCBad(int base, int end) {
    unsigned int tailBits = value_1(end);
    unsigned int tailLength = value_2(end);
    unsigned int partCRC = value_3(end);
    unsigned int length = end - base + (tailLength >> 3);
    switch(tailLength >> 3) {
    case 0:
        break;
    case 1:
        tailBits >>= 24;
        tailBits = crc8shr(partCRC, tailBits, POLY);
        break;
    case 2:
        tailBits >>= 16;
        tailBits = crc8shr(partCRC, tailBits, POLY);
        tailBits = crc8shr(partCRC, tailBits, POLY);
        break;
    case 3:
        tailBits >>= 8;
        tailBits = crc8shr(partCRC, tailBits, POLY);
        tailBits = crc8shr(partCRC, tailBits, POLY);
        tailBits = crc8shr(partCRC, tailBits, POLY);
        break;
    }
    return ~partCRC == 0 ? length : 0;
}

static int packetGood(struct miiData &this, int base, int end) {
    int length = CRCBad(base, end);

    if (length == 0) {
        this.miiPacketsCRCError++;
        return 0;
    }
    // insert MAC filter here.
    this.miiPacketsReceived++;
    return length;
}

/* Buffer management. Each buffer consists of a single word that encodes
 * the length and the buffer status, and then (LENGTH+3)>>2 words. The
 * encoding is as follows: a positive number indicates a buffer that is in
 * use and the length is the positive number in bytes, a negative number
 * indicates a free buffer and the length is minus the negative number in
 * bytes, zero indicates that the buffer is the unused tail end of the
 * circular buffer; more allocated buffers are found wrapped around to the
 * head, one indicates that this is the write pointer.
 *
 * THere are two circular buffers, denoted Bank 0 and Bank 1. Each buffer
 * has a free pointer, a write pointer, a lastsafe pointer, and a first
 * pointer. The first pointer is the address of the first word of memory,
 * the last safe pointer is the address of the last word where a full
 * packet can be stored. These pointers are constant. The write pointer
 * points to the place where the next packet is written (that is the word
 * past the length), the free pointer points to the place that could
 * potentially next be freed. The free pointer either points to an
 * allocated buffer, or it sits right behind the write pointer. The write
 * pointer either points to enough free space to allocate a buffer, or it
 * sits too close to the free pointer for there to be room for a packet.
 */

/* packetInLLD (maintained by the LLD) remembers which buffer is being
 * filled right now; nextBuffer (maintained byt ClientUser.xc) stores which
 * buffer is to be filled next. When receiving a packet, packetInLLD is
 * being filled with up to MAXPACKET bytes. On an interrupt, nextBuffer is
 * being given to the LLD to be filled. The assembly level interrupt
 * routine leaves packetInLLD to the contents of nextBuffer (since that is
 * being filled in by the LLD), and the user level interrupt routine must
 * leave nextBuffer to point to a fresh buffer.
 */

#define MAXPACKET 1530

static void set(int addr, int value) {
    asm("stw %0, %1[0]" :: "r" (value), "r" (addr));
}

static int get(int addr) {
    int value;
    asm("ldw %0, %1[0]" : "=r" (value) : "r" (addr));
    return value;
}

/* Called once on startup */

void mii_buffer_init(struct miiData &this, chanend cIn, chanend cNotifications, int buffer[], int numberWords) {
    int address;
    this.notifySeen = 1;
    this.notifyLast = 1;
    asm("add %0, %1, 0" : "=r" (address) : "r" (buffer));
    this.readPtr[0] = this.firstPtr[0] = this.freePtr[0] = address ;
    this.readPtr[1] = this.firstPtr[1] = this.freePtr[1] = address + ((numberWords << 1) & ~3) ;
    this.wrPtr[0] = this.freePtr[0] + 4;
    this.wrPtr[1] = this.freePtr[1] + 4;
    set(this.freePtr[0], 1);
    set(this.freePtr[1], 1);
    this.lastSafePtr[0] = this.freePtr[1] - MAXPACKET;
    this.lastSafePtr[1] = address + (numberWords << 2) - MAXPACKET;
    this.nextBuffer    = this.wrPtr[1];
    this.miiPacketsOverran = 0;
    this.refillBankNumber = 0;
    this.miiPacketsTransmitted = 0;
    this.miiPacketsReceived = 0;
    this.miiPacketsCRCError = 0;
    this.readBank = 0;
    mii_install_handler(this, this.wrPtr[0], cIn, cNotifications);
}


/* Called from interrupt handler */

void miiNotify(struct miiData &this, chanend notificationChannel) {
    if (this.notifyLast == this.notifySeen) {
        this.notifyLast = !this.notifyLast;
        outuchar(notificationChannel, this.notifyLast);
    }
}

select mii_notified(struct miiData &this, chanend notificationChannel) {
case inuchar_byref(notificationChannel, this.notifySeen):
    break;
}

#pragma unsafe arrays
{unsigned, unsigned, unsigned} mii_get_in_buffer(struct miiData &this) {
    unsigned nBytes, timeStamp;
    for(int i = 0; i < 2; i++) {
        this.readBank = !this.readBank;
        nBytes = get(this.readPtr[this.readBank]);
        if (nBytes == 0) {
            this.readPtr[this.readBank] = this.firstPtr[this.readBank];
            nBytes = get(this.readPtr[this.readBank]);
        }
        if (nBytes != 1) {
            unsigned retVal = this.readPtr[this.readBank] + 4;
            this.readPtr[this.readBank] += ((nBytes + 3) & ~3) + 4;
            if (get(this.readPtr[this.readBank]) == 0) {
                this.readPtr[this.readBank] = this.firstPtr[this.readBank];
            }
            timeStamp = get(retVal);
            return {retVal+4, nBytes-4, timeStamp};
        }
    }
    return {0, 0, 0};
}

#pragma unsafe arrays
static void miiCommitBuffer(struct miiData &this, unsigned int currentBuffer, unsigned int length, chanend notificationChannel) {
    int bn = currentBuffer < this.firstPtr[1] ? 0 : 1;
    set(this.wrPtr[bn]-4, length);       // record length of current packet.
    this.wrPtr[bn] = this.wrPtr[bn] + ((length+3)&~3) + 4; // new end pointer.
    miiNotify(this, notificationChannel);
    if (this.wrPtr[bn] > this.lastSafePtr[bn]) {  // This may be too far.
        if (this.freePtr[bn] != this.firstPtr[bn]) {// Test if head of buf is free
            set(this.wrPtr[bn]-4, 0);          // If so, record unused tail.
            this.wrPtr[bn] = this.firstPtr[bn] + 4; // and wrap to head, and record that
            set(this.wrPtr[bn]-4, 1);          // this is now the head of the queue.
            if (this.freePtr[bn] - this.wrPtr[bn] >= MAXPACKET) {// Test if there is room for packet
                this.nextBuffer = this.wrPtr[bn];     // if so, record packet pointer
                return;                            // fall out - default is no room
            }
        } else {
            set(this.wrPtr[bn]-4, 1);          // this is still the head of the queue.
        }
    } else {                                       // room in tail.
        set(this.wrPtr[bn]-4, 1);            // record that this is now the head of the queue.
        if (this.wrPtr[bn] > this.freePtr[bn] || // Test if there is room for a packet
            this.freePtr[bn] - this.wrPtr[bn] >= MAXPACKET) {
            this.nextBuffer = this.wrPtr[bn];           // if so, record packet pointer
            return;
        }
    }
    this.nextBuffer = -1;                             // buffer full - no more room for data.
    this.refillBankNumber = bn;
    return;
}

static void miiRejectBuffer(struct miiData &this, unsigned int currentBuffer) {
    this.nextBuffer = currentBuffer;
}

#pragma unsafe arrays
void mii_restart_buffer(struct miiData &this) {
    int bn;
    if (this.nextBuffer != -1) {
        return;
    }
    bn = this.refillBankNumber;

    if (this.wrPtr[bn] > this.lastSafePtr[bn]) {  // This may be too far.
        if (this.freePtr[bn] != this.firstPtr[bn]) {// Test if head of buf is free
            set(this.wrPtr[bn]-4, 0);          // If so, record unused tail.
            this.wrPtr[bn] = this.firstPtr[bn] + 4; // and wrap to head, and record that
            set(this.wrPtr[bn]-4, 1);          // this is now the head of the queue.
            if (this.freePtr[bn] - this.wrPtr[bn] >= MAXPACKET) {// Test if there is room for packet
                this.nextBuffer = this.wrPtr[bn];     // if so, record packet pointer
            }
        }
    } else {                                       // room in tail.
        if (this.wrPtr[bn] > this.freePtr[bn] || // Test if there is room for a packet
            this.freePtr[bn] - this.wrPtr[bn] >= MAXPACKET) {
            this.nextBuffer = this.wrPtr[bn];           // if so, record packet pointer
        }
    }
}

#pragma unsafe arrays
void mii_free_in_buffer(struct miiData &this, int base) {
    int bankNumber = base < this.firstPtr[1] ? 0 : 1;
    int modifiedFreePtr = 0;
    base -= 4;
    set(base-4, -get(base-4));
    while (1) {
        int l = get(this.freePtr[bankNumber]);
        if (l > 0) {
            break;
        }
        modifiedFreePtr = 1;
        if (l == 0) {
            this.freePtr[bankNumber] = this.firstPtr[bankNumber];
        } else {
            this.freePtr[bankNumber] += (((-l) + 3) & ~3) + 4;
        }
    }
    // Note - wrptr may have been stuck
}

static int globalOffset;
int globalNow;

void miiTimeStampInit(unsigned offset) {
    int testOffset = 10000; // set to +/- 10000 for testing.
    globalOffset = (offset + testOffset) & 0x3FFFF;
}

#pragma unsafe arrays
void miiClientUser(struct miiData &this, int base, int end, chanend notificationChannel) {
    int length = packetGood(this, base, end);
    if (length != 0) {
        miiCommitBuffer(this, base, length, notificationChannel);
    } else {
        miiRejectBuffer(this, base);
    }
}

#pragma unsafe arrays
int mii_out_packet(chanend c_out, int b[], int index, int length) {
    int a, roundedLength;
    int oddBytes = length & 3;
    int precise;

    asm(" mov %0, %1" : "=r"(a) : "r"(b));

    roundedLength = length >> 2;
    b[roundedLength+1] = tailValues[oddBytes];
    b[roundedLength] &= (1 << (oddBytes << 3)) - 1;
    b[roundedLength+2] = -roundedLength + 1;
    outuint(c_out, a + length - oddBytes - 4);

    precise = inuint(c_out);

    // 64 takes you from the start of the preamble to the start of the destination address
    return precise + 64;
}

#define assign(base,i,c)  asm("stw %0,%1[%2]"::"r"(c),"r"(base),"r"(i))
#define assignl(c,base,i) asm("ldw %0,%1[%2]"::"r"(c),"r"(base),"r"(i))

int mii_out_packet_(chanend c_out, int a, int length) {
    int roundedLength;
    int oddBytes = length & 3;
    int precise;
    int x;

    roundedLength = length >> 2;
    assign(a, roundedLength+1, tailValues[oddBytes]);
    assignl(x, a, roundedLength);
    assign(a, roundedLength, x & (1 << (oddBytes << 3)) - 1);
    assign(a, roundedLength+2, -roundedLength + 1);
    outuint(c_out, a + length - oddBytes - 4);

    precise = inuint(c_out);

    // 64 takes you from the start of the preamble to the start of the destination address
    return precise + 64;
}

void mii_out_packet_done(chanend c_out) {
	chkct(c_out, 1);
}

void mii_out_init(chanend c_out) {
    chkct(c_out, 1);
}

static void drain(chanend c) {
    outct(c, 1);
    while(!testct(c)) {
        inuchar(c);
    }
    chkct(c, 1);
}

void mii_close(chanend cNotifications, chanend cIn, chanend cOut) {
    asm("clrsr 2");        // disable interrupts
    drain(cNotifications); // disconnect channel to ourselves
	outct(cOut, 1);        // disconnect channel to output - stops mii
    chkct(cOut, 1);
    drain(cIn);            // disconnect input side.
}
