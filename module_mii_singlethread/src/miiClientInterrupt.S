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
bufferAddress:
    .space 4
kernelStack:
    .space KERNEL_STACK_SAVE * 4 + 128 // TODO: miiClientUser.nstackwords
kernelStackEnd:
    .space 4
    .text

    .align 4
miiInstallHandler:
    stw    r1, dp[bufferAddress]                    // Step 1: store bufferAddress (NOT NEEDED)
    
    stw    r3, dp[interruptChannelEnd]// Step 2: Channel end to MIILLD layer, store it
    ldap   r11, miiInterruptHandler   //         and set it up for interrupts.
    setc   res[r3], XS1_SETC_IE_MODE_INTERRUPT
    setv   res[r3], r11
    eeu    res[r3]
    
    getr   r3, XS1_RES_TYPE_CHANEND   // Step 3: Create an internal channel end use for
    setd   res[r3], r3                //         synchronising interrupt routine and user land
    stw    r3, dp[blockingChannel]    //         it points to itself and can be polled.
    eeu    res[r3]

    ldaw   r3, dp[kernelStackEnd]     // Step 5: Set up kernel stack.
    ldaw   r1, sp[0]                  //         Save SP into R1
    set    sp, r3	                  //         Set SP, and place old SP...
    stw    r1, sp[0]                  //         ...where KRESTSP expects it
    krestsp 0	                      //         Set KSP, restore SP

    ldw    r3, dp[interruptChannelEnd]// Step 6: provide LLD with first buffer
    out    res[r3], r0
    stw    r0, dp[packetInLLD]        //         packetInLLD holds pointer passed to LLD.
    
    setsr  IEBLE                      // Step 7: Enable interrupts!
    retsp  0


    
    .align 4
miiInterruptHandler:
    kentsp KERNEL_STACK_SAVE
    stw    r2, sp[3] 
    stw    r1, sp[2]
    
    ldw    r2, dp[interruptChannelEnd]
    in     r1, res[r2]               // Watch out: the number of instructions between in and out should be
                                     // no less than 10, no more than 40.
    stw    r0, sp[1]
    
    stw    r3, sp[4] 
    stw    r11, sp[5] 
    nop
    
    ldc    r0, 0   
    out    res[r2], r0

    nop
    nop
    nop
    nop

    ldw    r0, dp[packetInLLD]
    ldw    r3, dp[nextBuffer]

    add    r11, r3, 1
    bt     r11, buffersAvailable
    out    res[r2], r0               // Reuse this buffer - drop current packet.
    ldw   r2, dp[miiPacketsOverran]
    add   r2, r2, 1
    stw   r2, dp[miiPacketsOverran]
    bu     returnFromInterrupt
buffersAvailable:

    out    res[r2], r3               // Pass fresh buffer.
    stw    r3, dp[packetInLLD]

    bl     miiClientUser
    
returnFromInterrupt:    
    
    ldw    r0, sp[1] 
    ldw    r1, sp[2] 
    ldw    r2, sp[3] 
    ldw    r3, sp[4] 
    ldw    r11, sp[5] 
    ldw    r5, sp[6] 
    krestsp KERNEL_STACK_SAVE
    
    kret

