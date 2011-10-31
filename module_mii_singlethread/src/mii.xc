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

#define NOSMIOROTHERTHINGS

#include <xs1.h>
#include <xclib.h>
#include "mii.h"
#include "smi.h"
#include "miiLLD.h"
#include "print.h"

#include <platform.h>


#define WORDS_PER_BUFFER (1600/4)
#define NBUFS 10

#include "miiClient.h"

int globalOffset;

int enableMacFilter = 0;
unsigned char filterMacAddress[6] = {0,0,0,0,0,0};

// XC-2 Port mappings

#ifndef aSIMULTATION

#define CLK_MII_RX XS1_CLKBLK_1
#define CLK_MII_TX XS1_CLKBLK_2

#define PORT_MII_RXCLK   XS1_PORT_1K
#define PORT_MII_RXD     XS1_PORT_4F
#define PORT_MII_RXDV    XS1_PORT_1G
#define PORT_MII_TXCLK   XS1_PORT_1H
#define PORT_MII_TXEN    XS1_PORT_1F
#define PORT_MII_TXD     XS1_PORT_4E
#define PORT_MII_RXER    XS1_PORT_1L
#define PORT_MII_FAKE    XS1_PORT_8C

#else

#define CLK_MII_RX XS1_CLKBLK_1
#define CLK_MII_TX XS1_CLKBLK_2

#define PORT_MII_RXCLK   XS1_PORT_1A
#define PORT_MII_RXD     XS1_PORT_4A
#define PORT_MII_RXDV    XS1_PORT_1B
#define PORT_MII_TXCLK   XS1_PORT_1C
#define PORT_MII_TXEN    XS1_PORT_1D
#define PORT_MII_TXD     XS1_PORT_4B
#define PORT_MII_RXER    XS1_PORT_1O
#define PORT_MII_FAKE    XS1_PORT_8A

#endif

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

on stdcore[1]: clock clk_mii_ref = XS1_CLKBLK_REF;
on stdcore[1]: clock clk_mii_rx = CLK_MII_RX;
on stdcore[1]: clock clk_mii_tx = CLK_MII_TX;

on stdcore[1]: in port p_mii_rxclk = PORT_MII_RXCLK;
on stdcore[1]: buffered in port:32 p_mii_rxd = PORT_MII_RXD;
on stdcore[1]: in port p_mii_rxdv = PORT_MII_RXDV;
on stdcore[1]: in port p_mii_rxer = PORT_MII_RXER;
on stdcore[1]: in port p_mii_txclk = PORT_MII_TXCLK;
on stdcore[1]: buffered out port:32 p_mii_txd = PORT_MII_TXD;
on stdcore[1]: out port p_mii_txen = PORT_MII_TXEN;
on stdcore[1]: in port p_mii_fake = PORT_MII_FAKE;
//on stdcore[1]: out port p_mii_txer = PORT_MII_TXER;
#ifdef SIMULATION
on stdcore[1]: out port p_mii_txcsn = XS1_PORT_1C;
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
  set_port_use_on(p_mii_fake);
  set_port_use_on(p_mii_txen);
  //  set_port_use_on(p_mii_txer);
  set_port_clock(p_mii_txclk, clk_mii_ref);
#ifndef HENKSIM
  set_port_clock(p_mii_txd, clk_mii_ref);
#endif
  set_port_clock(p_mii_fake, clk_mii_ref);
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
#ifndef NOSMIOROTHERTHINGS
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
