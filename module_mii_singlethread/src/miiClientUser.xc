#include <xs1.h>
#include <xclib.h>

#define POLY   0xEDB88320

int miiPacketsCRCError;
int miiPacketsReceived;
int miiPacketsOverran;
int miiPacketsTransmitted;
int nextBuffer;

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
    int address = 0x1D000;

    asm("stw %0, %1[1]" :: "r" (base), "r" (address));
    asm("stw %0, %1[2]" :: "r" (length), "r" (address));

    if (length == 0) {
        miiPacketsCRCError++;
        return 0;
    }
    // insert MAC filter here.
    miiPacketsReceived++;
    return length;
}

void miiClientUser(int base, int end) {
    int length = packetGood(base, end);
    if (length != 0) {
        // commit etc.
    } else {
        // reject etc.
    }
}
