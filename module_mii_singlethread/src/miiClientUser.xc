// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <xclib.h>
#include <print.h>
#include "miiClient.h"
#include "miiLLD.h"

#define POLY   0xEDB88320

int miiPacketsCRCError;
int miiPacketsReceived;
int miiPacketsOverran;
int miiPacketsTransmitted;
int nextBuffer;

extern void miiInstallHandler(int bufferAddr,
                              chanend miiChannel,
                              chanend notificationChannel);


static int value(int address, int index) {
    int retVal;
    asm("ldw %0, %1[%2]" : "=r" (retVal) : "r" (address) , "r" (index)); // should be immediate index.
    return retVal;
}

static int CRCBad(int base, int end) {
    unsigned int tailLength = value(end, 1);
    unsigned int partCRC = value(end, 2);
    unsigned int tailBits = value(end, 0);
    unsigned int length = end - base + (tailLength >> 3) - 4;
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

static int packetGood(int base, int end) {
    int length = CRCBad(base, end);

    if (length == 0) {
        miiPacketsCRCError++;
        printstr("Error in packet\n");
        return 0;
    }
    // insert MAC filter here.
    miiPacketsReceived++;
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
 
static int freePtr[2], wrPtr[2], lastSafePtr[2], firstPtr[2], readPtr[2];

/* packetInLLD (maintained by the LLD) remembers which buffer is being
 * filled right now; nextBuffer (maintained byt ClientUser.xc) stores which
 * buffer is to be filled next. When receiving a packet, packetInLLD is
 * being filled with up to MAXPACKET bytes. On an interrupt, nextBuffer is
 * being given to the LLD to be filled. The assembly level interrupt
 * routine leaves packetInLLD to the contents of nextBuffer (since that is
 * being filled in by the LLD), and the user level interrupt routine must
 * leave nextBuffer to point to a fresh buffer.
 */

int nextBuffer;
static int refillBankNumber;
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

void miiBufferInit(chanend cIn, chanend cNotifications, int buffer[], int numberWords) {
    int address;
    asm("add %0, %1, 0" : "=r" (address) : "r" (buffer));
    readPtr[0] = firstPtr[0] = freePtr[0] = address ;
    readPtr[1] = firstPtr[1] = freePtr[1] = address + ((numberWords << 1) & ~3) ;
    wrPtr[0] = freePtr[0] + 4;
    wrPtr[1] = freePtr[1] + 4;
    set(freePtr[0], 1);
    set(freePtr[1], 1);
    lastSafePtr[0] = freePtr[1] - MAXPACKET;
    lastSafePtr[1] = address + (numberWords << 2) - MAXPACKET;
    nextBuffer    = wrPtr[1];
    miiInstallHandler(wrPtr[0], cIn, cNotifications);
}


/* Called from interrupt handler */

static char notifyLast = 1;
char notifySeen = 1;

void miiNotify(chanend notificationChannel) {
    if (notifyLast == notifySeen) {
        notifyLast = !notifyLast;
        outuchar(notificationChannel, notifyLast);
    }
}

select miiNotified(chanend notificationChannel) {
case inuchar_byref(notificationChannel, notifySeen):
    break;
}

static int readBank = 0;

{int, int} miiGetInBuffer() {
    int nBytes;
    for(int i = 0; i < 2; i++) {
        readBank = !readBank;
        nBytes = get(readPtr[readBank]);
        if (nBytes == 0) {
            readPtr[readBank] = firstPtr[readBank];
            nBytes = get(readPtr[readBank]);
        }
        if (nBytes != 1) {
            int retVal = readPtr[readBank] + 4;
            readPtr[readBank] += ((nBytes + 3) & ~3) + 4;
            if (get(readPtr[readBank]) == 0) {
                readPtr[readBank] = firstPtr[readBank];
            }
            return {retVal, nBytes};
        }
    }
    return {0, 0};
}

static void miiCommitBuffer(unsigned int currentBuffer, unsigned int length, chanend notificationChannel) {
    int bn = currentBuffer < firstPtr[1] ? 0 : 1;    
    set(wrPtr[bn]-4, length);       // record length of current packet.
    wrPtr[bn] = wrPtr[bn] + ((length+3)&~3) + 4; // new end pointer.
    miiNotify(notificationChannel);
    if (wrPtr[bn] > lastSafePtr[bn]) {  // This may be too far.
        if (freePtr[bn] != firstPtr[bn]) {// Test if head of buf is free
            set(wrPtr[bn]-4, 0);          // If so, record unused tail.
            wrPtr[bn] = firstPtr[bn] + 4; // and wrap to head, and record that
            set(wrPtr[bn]-4, 1);          // this is now the head of the queue.
            if (freePtr[bn] - wrPtr[bn] >= MAXPACKET) {// Test if there is room for packet
                nextBuffer = wrPtr[bn];     // if so, record packet pointer
                return;                            // fall out - default is no room
            }
        } else {
            set(wrPtr[bn]-4, 1);          // this is still the head of the queue.
        }
    } else {                                       // room in tail.
        set(wrPtr[bn]-4, 1);            // record that this is now the head of the queue.
        if (wrPtr[bn] > freePtr[bn] || // Test if there is room for a packet
            freePtr[bn] - wrPtr[bn] >= MAXPACKET) {
            nextBuffer = wrPtr[bn];           // if so, record packet pointer
            return;
        }
    }
    nextBuffer = -1;                             // buffer full - no more room for data.
    refillBankNumber = bn;
    return;
}

static void miiRejectBuffer(unsigned int currentBuffer) {
    nextBuffer = currentBuffer;
}

void miiRestartBuffer() {
    int bn;
    if (nextBuffer != -1) {
        return;
    }
    bn = refillBankNumber;

    if (wrPtr[bn] > lastSafePtr[bn]) {  // This may be too far.
        if (freePtr[bn] != firstPtr[bn]) {// Test if head of buf is free
            set(wrPtr[bn]-4, 0);          // If so, record unused tail.
            wrPtr[bn] = firstPtr[bn] + 4; // and wrap to head, and record that
            set(wrPtr[bn]-4, 1);          // this is now the head of the queue.
            if (freePtr[bn] - wrPtr[bn] >= MAXPACKET) {// Test if there is room for packet
                nextBuffer = wrPtr[bn];     // if so, record packet pointer
            }
        }
    } else {                                       // room in tail.
        if (wrPtr[bn] > freePtr[bn] || // Test if there is room for a packet
            freePtr[bn] - wrPtr[bn] >= MAXPACKET) {
            nextBuffer = wrPtr[bn];           // if so, record packet pointer
        }
    }

}

void miiFreeInBuffer(int base) {
    int bankNumber = base < firstPtr[1] ? 0 : 1;
    int modifiedFreePtr = 0;
    set(base-4, -get(base-4));
    while (1) {
        int l = get(freePtr[bankNumber]);
        if (l > 0) {
            break;
        }
        modifiedFreePtr = 1;
        if (l == 0) {
            freePtr[bankNumber] = firstPtr[bankNumber];
        } else {
            freePtr[bankNumber] += (((-l) + 3) & ~3) + 4;
        }
    }
    // Note - wrptr may have been stuck
}

void miiClientUser(int base, int end, chanend notificationChannel) {
    int length = packetGood(base, end);
    if (length != 0) {
        miiCommitBuffer(base, length, notificationChannel);
    } else {
        miiRejectBuffer(base);
    }
}

int miiOutPacket(chanend c_out, int b[], int index, int length) {
    int a, roundedLength;
    int oddBytes = length & 3;

    asm(" mov %0, %1" : "=r"(a) : "r"(b));
    
    roundedLength = length >> 2;
    b[roundedLength+1] = tailValues[oddBytes];
    b[roundedLength] &= (1 << (oddBytes << 3)) - 1;
    outuint(c_out, a + length - oddBytes - 4);
    outuint(c_out, -roundedLength + 1);
    outct(c_out, 1);
    return inuint(c_out);
}

select miiOutPacketDone(chanend c_out) {
case chkct(c_out, 1):
    break;
}

void miiOutInit(chanend c_out) {
    chkct(c_out, 1);
}
