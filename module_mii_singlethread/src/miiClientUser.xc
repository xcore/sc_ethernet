#define POLY   0xEDB88320

static int CRCGood(int base, int end) {
    int tailLength = value(end, 1);
    int partCRC = value(end, 0);
    int tailBits = value(end, 2);
    int length = base - end + (tailLength >> 3);
    switch(tailLength >> 3) {
    case 0:
        break;
    case 1:
        tailBits >>= 24;
        crc8(partCRC, tailBits, tailBits, POLY);
        break;
    case 2:
        tailBits >>= 16;
        crc8(partCRC, tailBits, tailBits, POLY);
        crc8(partCRC, tailBits, tailBits, POLY);
        break;
    case 3:
        tailBits >>= 8;
        crc8(partCRC, tailBits, tailBits, POLY);
        crc8(partCRC, tailBits, tailBits, POLY);
        crc8(partCRC, tailBits, tailBits, POLY);
        break;
    }
    return ~partCRC == 0;
}

static int packetGood(int base, int end) {
    if (!CRCGood(base, end)) {
        miiPacketsCRCError++;
        return 0;
    }
    // insert MAC filter here.
    miiPacketsReceived++;
    return 1;
}

void miiClientUser(int base, int end) {
    if (packetGood(base, end)) {
        //commit etc.
    } else {
        // reject etc.
    }
}
