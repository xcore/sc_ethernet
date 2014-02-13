.cc_top miiLLD.func, miiLLD
    #include <xs1.h>
    // Two coroutines, IN  and OUT. The IN coroutine is jumped to on an IN event.
    // The OUT coroutine is jumped to from IN by jumping to R3.
    // The IN event vectors on the RXD/RXDV ports, and change the vectors depending on the
    // mode: normal (mii_rxd/mii_rxdv0), or preamble (mii_rxdv1, mii_rxd_preamble)

    // The OUT coroutine receives a packet to be transmitted on SP[0]/SP[1], and transmits them. The packet
    // Shoudl be stored at addresses SP[0]-SP[1]..SP[0], and on SP[0] it should have a byte count and then
    // the final word

    // The IN coroutine receives a pointer to a buffer to store a packet on channel R3, and it will,
    // on reception, output the pointer to the end on channel R3. At R3[0] is a CRC, at R3[1] a byte
    // count, and at R3[2] the final word.

    // Register assignments: DP/CP/LR not used, SP[0]/SP[1] contains packet to transmit.
    // R0:  IN:  RXD port
    // R1:  IN:  RXDV port
    // R2:  OUT: TXD port
    // R3:  IN:  INchannel to other layer.
    // R4:  IN:  Pointer where data is about to be written - could be replaced with DP using LDAWDP DP, DP[1] as add
    // R5:  OUT: scratch
    // R6:       Polynomial
    // R7:  OUT: top address of packet to be output
    // R8:  OUT: negative index in packet to be output
    // R9:  OUT: CRC of outputted data.
    // R10: IN:  CRC of inputted data
    // R11: IN:  scratch

    // SP[OUTchannel] OUTchannel to other layer.

     .section .cp.rodata,     "ac", @progbits

    .align 4
.cc_top miiconsts.data
    .globl polynomial

initialCRC:
    .word 0x9226F562
polynomial:
    .word 0xEDB88320
allFives:
    .word 0x55555555
DallFives:
    .word 0xD5555555
.cc_bottom miiconsts.data
    .text
    .align 4

#define STACKSIZE 19

#define SPreceivingOut 9
#define SPpreamble1 10
#define SPpreamble2 11
#define SPpreamble3 12
#define SPoutFirst 13
#define SPoutPacket 14
#define SPNOTAndTransmitCRC 15
#define SPoutIdle 16
#define SPtransmitCRC 17
#define SPfinalCRC 18

    // call: miiLLD(rxd, rxdv, txd, INchannel, OUTchannel, timingport)
.globl miiLLD.nstackwords
.globl miiLLD.maxthreads
.globl miiLLD.maxtimers
.globl miiLLD.maxchanends
.globl miiLLD.maxsync
.type  miiLLD, @function
.linkset miiLLD.maxchanends, 0
.linkset miiLLD.maxtimers, 0
.linkset miiLLD.maxthreads, 0
.linkset miiLLD.locnoside, 0
.linkset miiLLD.locnochandec, 1
.linkset miiLLD.nstackwords, STACKSIZE

    .globl miiLLD

#define OUTchannel (STACKSIZE+1)     // parameter
#define timingPort (STACKSIZE+2)     // parameter
#define theTimer   (STACKSIZE+3)     // parameter

#define EEBLE XS1_SR_EEBLE_MASK
miiLLD:
    entsp  STACKSIZE
    stw    r4, sp[1]       // Save all registers, just in case we ever want to return.
    stw    r5, sp[2]
    stw    r6, sp[3]
    stw    r7, sp[4]
    stw    r8, sp[5]
    stw    r9, sp[6]
    stw    r10, sp[7]
    stw    r11, sp[8]

    ldc    r11, 0xD
    setd   res[r0], r11
    setc   res[r0], XS1_SETC_COND_EQ
    ldap   r11, mii_rxd_preamble // Setup RXD port to jump to right data.
    setv   res[r0], r11
    edu    res[r0]
    setc   res[r0], XS1_SETC_IE_MODE_INTERRUPT

    ldap   r11, mii_rxdv0  // Initialise the rxdv port - parameter 1
    setv   res[r1], r11
    ldc    r11, 0x0
    setd   res[r1], r11
    setc   res[r1], XS1_SETC_COND_EQ
    edu    res[r1]
    setc   res[r1], XS1_SETC_IE_MODE_INTERRUPT

    // R2 does not need initialising.

    in    r4, res[r3]        // Make sure that interrupt handler is installed on other side, get a first buffer
    ldap  r11, mii_rxd_packet
    setv  res[r3], r11
    setc  res[r3], XS1_SETC_IE_MODE_INTERRUPT
    eeu   res[r3]            // These interrupts are always enabled

    // R4 does not need initialising.
    // R5 does not need initialising yet

    ldw    r6, cp[polynomial]

    // R7 does not need initialising.
    ldc   r8, 99             // Initial interframe gap reg

    // R9 does not need initialising.
    // R10 does not need initialising.
    // R11 does not need initialising.



    eeu   res[r0]            // And get going on the input side

    ldw   r11, sp[theTimer]
    setsr  XS1_SR_IEBLE_MASK

    bu     stateIdle


    //----------------------------------------------------
    // IN coroutine.


    .align 4                 // Pre condition:  res[r0] EN,  res[r1] EN,  res[r3] EN
    // Receive body of a packet
mii_rxd:
    in    r11, res[r0]       // Grab word to be loaded.
    stw   r11, r4[1]         // Write data at end of packet
    crc32 r10, r11, r6       // Update CRC
    add   r4, r4, 4
    kret                 // Post condition: res[r0] EN,  res[r1] EN,  res[r3] EN

    .align 4                 // Pre condition:  res[r0] EN,  res[r1] EN,  res[r3] EN
    // End of packet: grab last few bytes
mii_rxdv0:
    in    r11, res[r1]       // clear RXDV port
    out   res[r3], r4        // Output pointer to CRC to input layer
    edu   res[r1]
    kret                     // Post condition: res[r0] EN,  res[r1] EN,  res[r3] EN

    .align 4                 // Pre condition:  res[r0] EN,  res[r1] EN,  res[r3] EN
mii_rxLastBits:              // Jumped to from mii_rxd_packet - not an entry point.
    endin r11, res[r0]       // Get number of bits left
    stw   r11, r4[2]         // Save the number of bits left
    in    r11, res[r0]       // Grab them bits
    stw   r11, r4[1]         // Save the left over 0, 8, 16, or 24 bits.
    edu   res[r0]
    stw   r10, r4[3]         // And save CRC
    kret                 // Post condition: res[r0] DIS,  res[r1] DIS,  res[r3] EN

    .align 4                 // Pre condition:  res[r0] EN,  res[r1] EN,  res[r3] EN
mii_rxd_packet:
    in    r11, res[r3]        // Get pointer address to store data
    bf    r11, mii_rxLastBits
    or    r4, r11, r11
    eeu   res[r0]
    setc  res[r0], XS1_SETC_COND_EQ // Trigger on 0xD
    ldap  r11, mii_rxd_preamble // Setup RXD port to jump to right data.
    setv  res[r0], r11
    ldw   r11, sp[theTimer]
    kret                 // Post condition: res[r0] EN,  res[r1] DIS, res[r3] EN

    .align 4                 // Pre condition:  res[r0] EN,  res[r1] DIS, res[r3] EN
    // Received the end of the preamble.
mii_rxd_preamble:
    in    r11, res[r11]
    stw   r11, r4[0]
    in    r11, res[r0]       // Throw preamble away
    ldw   r10, cp[initialCRC]         // Initialise CRC to something. What?
    ldap  r11, mii_rxd       // And setup the RXD port for future events.
    setv  res[r0], r11
    setc  res[r1], XS1_SETC_RUN_CLRBUF
//    setc  res[r1], XS1_SETC_COND_EQ
    eeu   res[r1]
    kret                 // Post condition: res[r0] EN,  res[r1] EN,  res[r3] EN

    //----------------------------------------------------
    // OUT coroutine.

stateDone:
    clrsr  XS1_SR_IEBLE_MASK
    chkct res[r9], 1
    outct res[r9], 1
drainIn:
    testct r5, res[r3]
    bt    r5, doneDone
    int   r5, res[r3]
    bu    drainIn
doneDone:
    chkct res[r3], 1
    outct res[r3], 1
    ldw    r4, sp[1]
    ldw    r5, sp[2]
    ldw    r6, sp[3]
    ldw    r7, sp[4]
    ldw    r8, sp[5]
    ldw    r9, sp[6]
    ldw    r10, sp[7]
    ldw    r11, sp[8]
    retsp  STACKSIZE

    // Idle state, wait for a packet
stateIdle:
    ldw   r5, sp[timingPort]    // Create interframe gap
    getts r7, res[r5]           // Get current count on timing port
    add   r7, r7, r8            // Then set this to the port counter
    setpt res[r5], r7           // And wait for the port to be ready.
    in    r7, res[r5]           // This should ensure the gap


outIdle:

    // Get a pointer to the next packet
    ldw   r9, sp[OUTchannel]
    outct res[r9], 1          // Request the next packet
    testct r5, res[r9]
    bt    r5, stateDone
    in    r7, res[r9]          // Read the pointer to the packet

    ldw   r5, cp[allFives]

    // Obtain the timestamp

    ldw   r8, sp[theTimer]
    in    r8, res[r8]

    // Transmitting the preamble

    out   res[r2], r5
    ldw   r5, cp[DallFives]
    out   res[r2], r5
    out   res[r9], r8
    ldw   r9, cp[initialCRC]

    // Transmitting the first word of the packet

    ldw   r8, r7[3]
    ldw   r5, r7[r8]
    add   r8, r8, 1
    crc32 r9, r5, r6
    out   res[r2], r5

    nop
outPacket:
    ldw   r5, r7[r8]
    add   r8, r8, 1
    crc32 r9, r5, r6
    out   res[r2], r5
    bt    r8, outPacket

    ldw   r8, r7[r8]
    crc32 r9, r8, r6


    ldw   r5, r7[2]
    ldw   r7, r7[1]
    out   res[r2], r8
    // Transmitting the tail of a packet
    bau   r5          // This will jump to r5

    .align 4
Tail0:
    ldc   r8, 0
    crc32 r9, r8, r6
    not   r9, r9
    out   res[r2], r9
    ldc   r8, 98                // Interframe gap
    bu    stateIdle

    .align 4
Tail1:
    crc8  r9, r8, r7, r6
    crc32 r9, r8, r6            // NOTE : r8 is zero at this stage.
    not   r9, r9
    shl   r5, r9, 8
    or    r7, r7, r5
    out   res[r2], r7
    shr   r9, r9, 24
    outpw res[r2], r9, 8
    ldc   r8, 73                // Interframe gap
    bu    stateIdle

    .align 4
Tail2:
    crc8  r9, r8, r7, r6
    crc8  r9, r8, r8, r6
    crc32 r9, r8, r6            // NOTE : r8 is zero at this stage.
    not   r9, r9

    shl   r5, r9, 16
    or    r7, r7, r5
    out   res[r2], r7
    shr   r9, r9, 16
    outpw res[r2], r9, 16

    ldc   r8, 80                // Interframe gap
    bu    stateIdle

    .align 4
Tail3:
    crc8  r9, r8, r7, r6
    crc8  r9, r8, r8, r6
    crc8  r9, r8, r8, r6
    outpw res[r2], r7, 24       // TODO: do a shift, OR, OUT and OUTPW for smooth output
    crc32 r9, r8, r6            // NOTE : r8 must be zero
    not   r9, r9
    out   res[r2], r9

    ldc   r8, 90                // Interframe gap
    bu    stateIdle


.globl tailValues, "a(4:ui)"
.type  tailValues, @object
.section .dp.data,       "adw", @progbits
.cc_top tailValues.data
    .align    4
tailValues:
    .word Tail0
    .word Tail1
    .word Tail2
    .word Tail3
.globl tailValues.globound
.set      tailValues.globound,4
.cc_bottom tailValues.data
    .text
.cc_bottom miiLLD.func
