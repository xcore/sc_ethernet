#include <xs1.h>
#define ASSEMBLER
#include "miiClient.h"

#define EEBLE XS1_SR_EEBLE_MASK
#define IEBLE XS1_SR_IEBLE_MASK
    
#define KERNEL_STACK_SAVE 12         // TODO: make smaller
    
// call: int miiInstallHandler(chanend interrupt, int buffer[])
.globl miiInstallHandler.nstackwords
.globl miiInstallHandler.maxthreads
.globl miiInstallHandler.maxtimers
.globl miiInstallHandler.maxchanends
.globl miiInstallHandler.maxsync
.type  miiInstallHandler, @function
.linkset miiInstallHandler.locnoside, 0
.linkset miiInstallHandler.nstackwords, 0
.linkset miiInstallHandler.maxchanends, 1
.linkset miiInstallHandler.maxtimers, 0
.linkset miiInstallHandler.maxsync, 0

.globl miiInstallHandler
.globl systemWr
    .globl miiPacketsTransmitted
    .globl miiPacketsReceived
    .globl miiPacketsCRCError
    .globl miiPacketsOverran

    .section .dp.bss,        "adw", @nobits

packetInLLD:    
    .space 4
interruptChannelEnd:
    .space 4
blockingChannel:
    .space 4
systemWr:
    .space 4
systemRd:
    .space 4
userRd:
    .space 4
userWr:
    .space 4
leftEmpty:
    .space 4
bufferAddress:
    .space 4
miiPacketsOverran: 
    .space 4
miiPacketsBlocked: 
    .space 4
miiPacketsCRCError: 
    .space 4
miiPacketsReceived: 
    .space 4
miiPacketsTransmitted:  
    .space 4
kernelStack:
    .space KERNEL_STACK_SAVE * 4
kernelStackEnd:
    .space 4
    .text

    .align 4
miiInstallHandler:
    stw    r1, dp[bufferAddress]                    // Step 1: store bufferAddress (NOT NEEDED)
    
    stw    r0, dp[interruptChannelEnd]              // Step 2: Channel end to MIILLD layer, store it
    ldap   r11, miiInterruptHandler                 //         and set it up for interrupts.
    setc   res[r0], XS1_SETC_IE_MODE_INTERRUPT
    setv   res[r0], r11
    eeu    res[r0]
    
    getr   r0, XS1_RES_TYPE_CHANEND                 // Step 3: Create an internal channel end use for
    setd   res[r0], r0                              //         synchronising interrupt routine and user land
    stw    r0, dp[blockingChannel]                  //         it points to itself and can be polled.
    eeu    res[r0]

    ldc    r0, 1                                    // Step 4: Initialise boolean leftEmpty to true.
    stw    r0, dp[leftEmpty]

    ldaw   r0, dp[kernelStackEnd]                   // Step 5: Set up kernel stack.
    ldaw   r1, sp[0]                                //         Save SP into R1
    set    sp, r0	                                //         Set SP, and place old SP...
    stw    r1, sp[0]                                //         ...where KRESTSP expects it
    krestsp 0	                                    //         Set KSP, restore SP

    ldw    r0, dp[interruptChannelEnd]              // Step 6: provide LLD with first buffer
    ldw    r1, dp[systemRd]                         //         grab buffer from system buffers
    ldaw   r2, dp[systemBuffers]                    //         and out it to the LLD
    ldw    r2, r2[r1]
    out    res[r0], r2
    stw    r2, dp[packetInLLD]                      //         packetInLLD holds pointer passed to LLD.
    add    r1, r1, 1                                //         Increment the read pointer MOD 2^n
    mkmsk  r2, SYSTEM_BUFFER_SIZE_BITS
    and    r1, r1, r2
    stw    r1, dp[systemRd]
    
    setsr  IEBLE                                    // Step 7: Enable interrupts!
    retsp  0


    
    .align 4
miiInterruptHandler:
    kentsp KERNEL_STACK_SAVE
    stw    r0, sp[1] 
    stw    r1, sp[2]
    
    ldw    r0, dp[interruptChannelEnd]
    in     r1, res[r0]               // Watch out: the number of instructions between in and out should be
                                     // no less than 10, no more than 40.
    stw    r2, sp[3] 
    stw    r3, sp[4] 
    stw    r4, sp[5] 
    stw    r5, sp[6] 

    ldw    r2, dp[packetInLLD]

    ldw    r4, dp[systemWr]
    ldw    r3, dp[systemRd]
    eq     r4, r4, r3
    bf     r4, buffersAvailable
    out    res[r0], r2               // Reuse this buffer - drop current packet.
    ldw   r0, dp[miiPacketsOverran]
    add   r0, r0, 1
    stw   r0, dp[miiPacketsOverran]
    bu     returnFromInterrupt
buffersAvailable:
    ldaw   r4, dp[systemBuffers]
    ldw    r4, r4[r3]
    out    res[r0], r4               // Pass fresh buffer.
    stw    r4, dp[packetInLLD]

    add    r3, r3, 1
    mkmsk  r4, SYSTEM_BUFFER_SIZE_BITS
    and    r3, r3, r4
    stw    r3, dp[systemRd]


    // r1 is the packet end
    // r2 is the packet base


//r0, r3, r4: scratch.
    
    
    ldw    r0, r1[0]
    ldw    r3, r1[1]
    ldw    r4, r1[2]
    stw    r4, r1[0]    // Store the tail of the packet.

    ldw    r5, cp[polynomial]
    
    sub    r1, r1, r2  // Length so far in words
//    shl    r1, r1, 2   // Length in bytes excluding the tail length
    
    shr    r3, r3, 3   // Tail lenght in Bytes
    add    r1, r1, r3  // Total length in Bytes
    
    bf     r3, tail0
    sub    r3, r3, 1
    bf     r3, tail8
    sub    r3, r3, 1
    bf     r3, tail16
tail24:
    sub    r1, r1, 4
    shr    r4, r4, 8
    crc8   r0, r4, r4, r5
    crc8   r0, r4, r4, r5
    crc8   r0, r4, r4, r5
    bu     tail0
tail16:
    sub    r1, r1, 4
    shr    r4, r4, 16
    crc8   r0, r4, r4, r5
    crc8   r0, r4, r4, r5
    bu     tail0
tail8:
    sub    r1, r1, 4
    shr    r4, r4, 24
    crc8   r0, r4, r4, r5
tail0:  
    not    r0, r0
    bt     r0, badPacketCRC

    ldw    r0, dp[enableMacFilter]  // Check if filtering is enabled
    bf     r0, goodPacket           // If not, accept packet (promiscuous mode)

    ldw    r0, r2[0]                // To MAC address - first word.
    shr    r0, r0, 24               // Bit 24 states whether this is a broadcast address
    zext   r0, 1                    // Keep just bit 24
    bt     r0, goodPacket           // If it is one, accept packet since it is a broadcast.

    ldw    r0, r2[0]                // Compare first word
    ldw    r4, dp[filterMacAddress] // With our MAC address
    eq     r0, r4, r0               // If not equal, block the packet.
    bf     r0, badPacketNotUs
    ldw    r0, r2[1]                // Compare second word
    ldw    r4, dp[filterMacAddress+4]// With second word of mac address.
    sub    r0, r4, r0               // But drop first 16 bits. (only 48 bits in MAC address)
    zext   r0, 16                   // If subtraction is not zero, block the packet.
    bt     r0, badPacketNotUs
    
    // r2: base to packet. r1: length    




    
goodPacket:
    ldw   r0, dp[miiPacketsReceived]    // Record that we received a packet
    add   r0, r0, 1
    stw   r0, dp[miiPacketsReceived]

    
    ldw   r0, dp[userRd]                // Pass this packet to the user layer
    ldw   r3, dp[userWr]
    eq    r0, r0, r3                    // Test if the buffer was empty at the moment
    bf    r0, bufferNotEmpty            
    ldw   r0, dp[blockingChannel]       // if buffer was empty, inform other side.
    outct res[r0], 7                    // Other side will now unblock itself.
bufferNotEmpty:
    ldaw  r0, dp[userBuffers]           // Need to store both the pointer to the packet
    stw   r2, r0[r3]                    // in the buffer array
    ldaw  r0, dp[userBufferLengths]     // and the length of the packet
    stw   r1, r0[r3]                    // in the length array
    add   r3, r3, 1                     // Now increment the write pointer MOD 2^n
    mkmsk  r1, USER_BUFFER_SIZE_BITS
    and   r3, r3, r1
    stw   r3, dp[userWr]
    bu    returnFromInterrupt           // Done

badPacketCRC:
    ldw   r0, dp[miiPacketsCRCError]    // Record that we had a packet with a CRC error
    add   r0, r0, 1
    stw   r0, dp[miiPacketsCRCError]
    bu    badPacket
badPacketNotUs:
    ldw   r0, dp[miiPacketsBlocked]     // Record that we have a packet with a non matching MAC
    add   r0, r0, 1
    stw   r0, dp[miiPacketsBlocked]

badPacket:                              // A packet was received that we cannot handle - reuse it.
    ldw   r4, dp[systemWr]              // Place it back into the system queue.
    ldaw  r5, dp[systemBuffers]
    stw   r2, r5[r4]
    add   r4, r4, 1                     // And increment the write pointer, MOD 2^n
    mkmsk r1, SYSTEM_BUFFER_SIZE_BITS
    and   r4, r4, r1
    stw   r4, dp[systemWr]            // r4 is the userRd index


    
returnFromInterrupt:    
    
    ldw    r0, sp[1] 
    ldw    r1, sp[2] 
    ldw    r2, sp[3] 
    ldw    r3, sp[4] 
    ldw    r4, sp[5] 
    ldw    r5, sp[6] 
    krestsp KERNEL_STACK_SAVE
    
    kret





    
    // call: int miiReceiveBuffer(int block)
.globl miiReceiveBuffer.nstackwords
.globl miiReceiveBuffer.maxthreads
.globl miiReceiveBuffer.maxtimers
.globl miiReceiveBuffer.maxchanends
.globl miiReceiveBuffer.maxsync
.type  miiReceiveBuffer, @function
.linkset miiReceiveBuffer.locnoside, 0
.linkset miiReceiveBuffer.nstackwords, 0
.linkset miiReceiveBuffer.maxchanends, 0
.linkset miiReceiveBuffer.maxtimers, 0
.linkset miiReceiveBuffer.maxsync, 0

.globl miiReceiveBuffer


    
    .align 4
miiReceiveBuffer:
    ldw   r2, dp[userRd]            // r2 is the userRd index
    add   r3, r2, 1
    mkmsk r1, USER_BUFFER_SIZE_BITS
    and   r3, r3, r1
    ldaw  r1, dp[userBuffers]           // r1 points to the buffer
    ldw   r11, dp[leftEmpty]        
    bf    r11, disableInterrupts
    ldw   r11, dp[blockingChannel]
    bt    r0, block
    ldap  r11, block
    setv  res[r0], r11
    setsr EEBLE
    clrsr EEBLE
    mkmsk r0, 32
    retsp 0
block:  
    chkct res[r11], 7
disableInterrupts:  
    ldaw  r11, dp[userBufferLengths]           // r1 points to the buffer
    clrsr IEBLE
    ldw   r0, r1[r2]
    ldw   r1, r11[r2]
    stw   r3, dp[userRd]
    ldw   r2, dp[userWr]
    setsr IEBLE
    eq    r11, r2, r3               //  leftEmpty = userWr == userRd
    stw   r11, dp[leftEmpty]
    retsp 0



    
    // call: miiReturnBufferToPool(bufferAddress)
.globl miiReturnBufferToPool.nstackwords
.globl miiReturnBufferToPool.maxthreads
.globl miiReturnBufferToPool.maxtimers
.globl miiReturnBufferToPool.maxchanends
.globl miiReturnBufferToPool.maxsync
.type  miiReturnBufferToPool, @function
.linkset miiReturnBufferToPool.locnoside, 0
.linkset miiReturnBufferToPool.nstackwords, 0
.linkset miiReturnBufferToPool.maxchanends, 0
.linkset miiReturnBufferToPool.maxtimers, 0
.linkset miiReturnBufferToPool.maxsync, 0

.globl miiReturnBufferToPool


    .align 4
miiReturnBufferToPool:
    ldw   r2, dp[systemWr]            // r2 is the userRd index
    add   r3, r2, 1
    mkmsk r1, SYSTEM_BUFFER_SIZE_BITS
    and   r3, r3, r1
    ldaw  r1, dp[systemBuffers]        // r1 points to the buffer
    clrsr IEBLE
    stw   r0, r1[r2]
    stw   r3, dp[systemWr]            // r2 is the userRd index
    setsr IEBLE
    retsp 0
