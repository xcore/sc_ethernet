#include <xs1.h>
#include "miiClient.h"
#include "miiLLD.h"

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
