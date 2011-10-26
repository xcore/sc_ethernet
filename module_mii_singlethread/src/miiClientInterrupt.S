// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>

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
.linkset miiInstallHandler.maxchanends, 0
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
kernelStack:
    .space KERNEL_STACK_SAVE * 4 + 128 // TODO: miiClientUser.nstackwords
kernelStackEnd:
    .space 4
    .text

    .align 4
miiInstallHandler:
    setd   res[r2], r2                //    synchronising interrupt routine and user land
    stw    r2, dp[blockingChannel]    //    it points to itself

    stw    r1, dp[interruptChannelEnd]// Step 2: Channel end to MIILLD layer, store it
    ldap   r11, miiInterruptHandler   //         and set it up for interrupts.
    setc   res[r1], XS1_SETC_IE_MODE_INTERRUPT
    setv   res[r1], r11
    eeu    res[r1]

    ldaw   r1, dp[kernelStackEnd]     // Step 5: Set up kernel stack.
    ldaw   r11, sp[0]                  //         Save SP into R1
    set    sp, r1	                  //         Set SP, and place old SP...
    stw    r11, sp[0]                  //         ...where KRESTSP expects it
    krestsp 0	                      //         Set KSP, restore SP

    ldw    r1, dp[interruptChannelEnd]// Step 6: provide LLD with first buffer
    out    res[r1], r0
    stw    r0, dp[packetInLLD]        //         packetInLLD holds pointer passed to LLD.
    
    setsr  IEBLE                      // Step 7: Enable interrupts!
    retsp  0


    
    .align 4
miiInterruptHandler:
    kentsp KERNEL_STACK_SAVE
    stw    r2, sp[3] 
    stw    r1, sp[2]
    
    ldw    r2, dp[interruptChannelEnd]
    in     r1, res[r2]               // Watch out: the number of instructions between interrupt and out should be
                                     // no less than 10, no more than 40.
    stw    r0, sp[1]
    
    
    ldc    r0, 0   
    out    res[r2], r0

    stw    r3, sp[4] 
    stw    r11, sp[5] 
    stw    lr, sp[6]
    nop
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
    ldw    r2, dp[blockingChannel]
    // r0: base
    // r1: end
    // r2: blockingChannel
    bl     miiClientUser
    
returnFromInterrupt:    
    
    ldw    r0, sp[1] 
    ldw    r1, sp[2] 
    ldw    r2, sp[3] 
    ldw    r3, sp[4] 
    ldw    r11, sp[5] 
    ldw    lr, sp[6]
    krestsp KERNEL_STACK_SAVE
    
    kret

