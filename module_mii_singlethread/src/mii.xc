/*************************************************************************
 *
 * Ethernet Physical Layer Implementation
 * IEEE 802.3 Medium Independent Interface
 *
 *
 *************************************************************************/
/*
 * Copyright (c) 2008 XMOS Ltd.
 *
 * Copyright Notice
 *
 *************************************************************************/


#include <xs1.h>
#include <stdio.h>
#include <xclib.h>
#include "mii.h"
#include "smi.h"
#include "miiLLD.h"
#include "print.h"

#include <platform.h>


#define WORDS_PER_BUFFER (1600/4)
#define NBUFS 10

#include "miiClient.h"

int systemBuffers[SYSTEM_BUFFER_SIZE]; // Communicate between mii HW thread and mii Interrupt routine.
int userBuffers[USER_BUFFER_SIZE]; // Communicate between mii Interrupt routine and IP stack
int userBufferLengths[USER_BUFFER_SIZE]; // Communicate between mii Interrupt routine and IP stack
int globalOffset;

int enableMacFilter = 0;
unsigned char filterMacAddress[6] = {0,0,0,0,0,0};

// XC-2 Port mappings

#define CLK_MII_RX XS1_CLKBLK_1
#define CLK_MII_TX XS1_CLKBLK_2

// Core 2
#define PORT_MII_RXCLK   XS1_PORT_1M
#define PORT_MII_RXD     XS1_PORT_4E
#define PORT_MII_RXDV    XS1_PORT_1N
#define PORT_MII_TXCLK   XS1_PORT_1K
#define PORT_MII_TXEN    XS1_PORT_1L
#define PORT_MII_TXD     XS1_PORT_4F
#define PORT_MII_RXER    XS1_PORT_1O


// Minimum interframe gap
// smi_is100() is used to time the gap on a 100 MHz timer
#define ENFORCE_MINIMUM_GAP
#define MINIMUM_GAP_TIMER_CYCLES_100MBPS 120
#define MINIMUM_GAP_TIMER_CYCLES_10MBPS 960

// Timing tuning constants
#define PAD_DELAY_RECEIVE    0
#define PAD_DELAY_TRANSMIT   0
#define CLK_DELAY_RECEIVE    0
#define CLK_DELAY_TRANSMIT   7  // Note: used to be 2 (improved simulator?)

// After-init delay (used at the end of mii_init)
#define PHY_INIT_DELAY 10000000


extern void user_trap();

on stdcore[2]: clock clk_mii_ref = XS1_CLKBLK_REF;
on stdcore[2]: clock clk_mii_rx = CLK_MII_RX;
on stdcore[2]: clock clk_mii_tx = CLK_MII_TX;

on stdcore[2]: in port p_mii_rxclk = PORT_MII_RXCLK;
on stdcore[2]: buffered in port:32 p_mii_rxd = PORT_MII_RXD;
on stdcore[2]: in port p_mii_rxdv = PORT_MII_RXDV;
on stdcore[2]: in port p_mii_rxer = PORT_MII_RXER;
on stdcore[2]: in port p_mii_txclk = PORT_MII_TXCLK;
on stdcore[2]: buffered out port:32 p_mii_txd = PORT_MII_TXD;
on stdcore[2]: out port p_mii_txen = PORT_MII_TXEN;
//on stdcore[2]: out port p_mii_txer = PORT_MII_TXER;
#ifdef SIMULATION
on stdcore[2]: out port p_mii_txcsn = XS1_PORT_1C;
#endif

void mii_init()
{
#ifndef SIMULATION
  timer tmr;
  unsigned t;
#endif
  set_port_use_on(p_mii_rxclk);
  p_mii_rxclk :> int x;
  set_port_use_on(p_mii_rxd);
  set_port_use_on(p_mii_rxdv);
  set_port_use_on(p_mii_rxer);
  set_port_clock(p_mii_rxclk, clk_mii_ref);
  set_port_clock(p_mii_rxd, clk_mii_ref);
  set_port_clock(p_mii_rxdv, clk_mii_ref);

  set_pad_delay(p_mii_rxclk, PAD_DELAY_RECEIVE);

  set_port_strobed(p_mii_rxd);
  set_port_slave(p_mii_rxd);

  set_clock_on(clk_mii_rx);
  set_clock_src(clk_mii_rx, p_mii_rxclk);
  set_clock_ready_src(clk_mii_rx, p_mii_rxdv);
  set_port_clock(p_mii_rxd, clk_mii_rx);
  set_port_clock(p_mii_rxdv, clk_mii_rx);

  set_clock_rise_delay(clk_mii_rx, CLK_DELAY_RECEIVE);

  start_clock(clk_mii_rx);

  clearbuf(p_mii_rxd);

  set_port_use_on(p_mii_txclk);
  set_port_use_on(p_mii_txd);
  set_port_use_on(p_mii_txen);
  //  set_port_use_on(p_mii_txer);
  set_port_clock(p_mii_txclk, clk_mii_ref);
#ifndef HENKSIM
  set_port_clock(p_mii_txd, clk_mii_ref);
#endif
  set_port_clock(p_mii_txen, clk_mii_ref);

  set_pad_delay(p_mii_txclk, PAD_DELAY_TRANSMIT);

  p_mii_txd <: 0;
  p_mii_txen <: 0;
  //  p_mii_txer <: 0;
  sync(p_mii_txd);
  sync(p_mii_txen);
  //  sync(p_mii_txer);
#ifndef HENKSIM
  set_port_strobed(p_mii_txd);
  set_port_master(p_mii_txd);
  clearbuf(p_mii_txd);

  set_port_ready_src(p_mii_txen, p_mii_txd);
  set_port_mode_ready(p_mii_txen);
#endif

  set_clock_on(clk_mii_tx);
  set_clock_src(clk_mii_tx, p_mii_txclk);
#ifndef HENKSIM
  set_port_clock(p_mii_txd, clk_mii_tx);
#endif
  set_port_clock(p_mii_txen, clk_mii_tx);

  set_clock_fall_delay(clk_mii_tx, CLK_DELAY_TRANSMIT);

  start_clock(clk_mii_tx);

  clearbuf(p_mii_txd);
#ifdef SIMULATION
  set_port_use_on(p_mii_txcsn);
  p_mii_txcsn <: 0;
  sync(p_mii_txcsn);
#endif
#ifndef HENKSIM
  tmr :> t;
  tmr when timerafter(t + PHY_INIT_DELAY) :> t;
#endif
}

void mii_deinit()
{
#ifdef SIMULATION
  set_port_use_off(p_mii_txcsn);
#endif
  set_port_use_off(p_mii_rxd);
  set_port_use_off(p_mii_rxclk);
  set_port_use_off(p_mii_rxdv);
  set_clock_off(clk_mii_rx);
  set_port_use_off(p_mii_txd);
  set_port_use_off(p_mii_txclk);
#ifndef SIMULATION
  // Bug in plugin
  set_port_use_off(p_mii_txen);
#endif
  set_clock_off(clk_mii_tx);
  set_port_use_off(p_mii_rxer);
  //  set_port_use_off(p_mii_txer);
}

void miiBufferInit(chanend c_in, int buffer[], int words) {
    int bufferAddress, cnt = 0;
    asm(" mov %0, %1" : "=r"(bufferAddress) : "r"(buffer));
    globalOffset = bufferAddress;
    for(int i = 0; i < words; i += WORDS_PER_BUFFER) {
        if (i+WORDS_PER_BUFFER <= words) {
            miiInPacketDone(c_in, i);
            cnt++;
        }
    }
    miiInstallHandler(c_in);
}

{int,int} miiInPacket(chanend c_in, int buffer[]) {
    int a, b;
    {a,b} =miiReceiveBuffer(1);
    return {(a-globalOffset)>>2,b};
}

void miiInPacketDone(chanend c_in, int buffer) {
    miiReturnBufferToPool(buffer*4+globalOffset);
}

void miiOutInit(chanend c_out) {
    chkct(c_out, 1);
}

void miiOutPacket(chanend c_out, int b[], int index, int length) {
    int a, roundedLength;
    int oddBytes = length & 3;

    asm(" mov %0, %1" : "=r"(a) : "r"(b));
    
    roundedLength = length >> 2;
    b[roundedLength+1] = tailValues[oddBytes];
    b[roundedLength] &= (1 << (oddBytes << 3)) - 1;
    outuint(c_out, a + length - oddBytes);
    outuint(c_out, -roundedLength);
    outct(c_out, 1);
    chkct(c_out, 1);
}

extern void mii(chanend c_in, chanend c_out) {
    mii_init();
    smi_init();
    smi_config(1);
    miiLLD(p_mii_rxd, p_mii_rxdv, p_mii_txd, c_in, c_out);
}

