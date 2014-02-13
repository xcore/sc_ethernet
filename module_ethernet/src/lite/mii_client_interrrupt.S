.cc_top mii_install_handler.func, mii_install_handler
// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>

#define EEBLE XS1_SR_EEBLE_MASK
#define IEBLE XS1_SR_IEBLE_MASK

#define KERNEL_STACK_SAVE 12         // TODO: make smaller

// call: int mii_install_handler(chanend interrupt, int buffer[])
.globl mii_install_handler.nstackwords
.globl mii_install_handler.maxthreads
.globl mii_install_handler.maxtimers
.globl mii_install_handler.maxchanends
.globl mii_install_handler.maxsync
.type  mii_install_handler, @function
.linkset mii_install_handler.locnoside, 0
.linkset mii_install_handler.nstackwords, 0
.linkset mii_install_handler.maxchanends, 0
.linkset mii_install_handler.maxtimers, 0
.linkset mii_install_handler.maxthreads, 0
.linkset mii_install_handler.maxsync, 0

.globl mii_install_handler

#define nextBuffer                0
#define packetInLLD               1
#define notificationChannelEnd    2
#define miiChannelEnd             3
#define miiPacketsOverran         4
#define kernelStackEnd            148


    .align 4
mii_install_handler:
    setd   res[r3], r3                //    synchronising interrupt routine and user land
    stw    r3, r0[notificationChannelEnd]    //    it points to itself

    stw    r2, r0[miiChannelEnd]   // Step 2: Channel end to MIILLD layer, store it
    ldap   r11, miiInterruptHandler   //         and set it up for interrupts.
    setc   res[r2], XS1_SETC_IE_MODE_INTERRUPT
    setv   res[r2], r11
    eeu    res[r2]
    or     r11, r0, r0
    setev  res[r2], r11

    ldc    r3, kernelStackEnd
    ldaw   r2, r0[r3]                  // Step 5: Set up kernel stack.
    ldaw   r11, sp[0]                  //         Save SP into R2
    set    sp, r2	                   //         Set SP, and place old SP...
    stw    r11, sp[0]                  //         ...where KRESTSP expects it
    krestsp 0	                       //         Set KSP, restore SP

    ldw    r2, r0[miiChannelEnd]   // Step 6: provide LLD with first buffer
    out    res[r2], r1
    stw    r1, r0[packetInLLD]        //         packetInLLD holds pointer passed to LLD.

    setsr  IEBLE                      // Step 7: Enable interrupts!
    retsp  0



    .align 4
miiInterruptHandler:
    kentsp KERNEL_STACK_SAVE
    stw    r3, sp[4]
    stw    r2, sp[3]
    stw    r11, sp[5]

    get    r11, ed
    ldw    r3, r11[miiChannelEnd]
    in     r2, res[r3]               // Watch out: the number of instructions between interrupt and out should be
                                     // no less than 10, no more than 40.
    stw    r1, sp[2]


    ldc    r1, 0
    out    res[r3], r1

    stw    r0, sp[1]
    stw    lr, sp[6]
    or     r0, r11, r11
    nop
    nop
    nop
    nop
    nop

    ldw    r1, r0[packetInLLD]
    ldw    r11, r0[nextBuffer]

    add    r11, r11, 1
    bt     r11, buffersAvailable
    out    res[r3], r1               // Reuse this buffer - drop current packet.
    ldw   r3, r0[miiPacketsOverran]
    add   r3, r3, 1
    stw   r3, r0[miiPacketsOverran]
    bu     returnFromInterrupt
buffersAvailable:
    sub    r11, r11, 1
    out    res[r3], r11               // Pass fresh buffer.
    stw    r11, r0[packetInLLD]
    ldw    r3, r0[notificationChannelEnd]
    // r0: struct
    // r1: base
    // r2: end
    // r3: notificationChannelEnd
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

.cc_bottom mii_install_handler.func
