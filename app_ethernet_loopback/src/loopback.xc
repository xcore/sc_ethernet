// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <print.h>
#include <platform.h>
#include <stdlib.h>
#include "otp_board_info.h"
#include "ethernet.h"
#include "ethernet_board_support.h"
#include "frame_channel.h"
#include "mac_custom_filter.h"
#include <print.h>

on ETHERNET_DEFAULT_TILE: otp_ports_t otp_ports = OTP_PORTS_INITIALIZER;

// Here are the port definitions required by ethernet
// The intializers are taken from the ethernet_board_support.h header for
// XMOS dev boards. If you are using a different board you will need to
// supply explicit port structure intializers for these values
smi_interface_t smi = ETHERNET_DEFAULT_SMI_INIT;
mii_interface_t mii = ETHERNET_DEFAULT_MII_INIT;
ethernet_reset_interface_t eth_rst = ETHERNET_DEFAULT_RESET_INTERFACE_INIT;

void test(chanend tx, chanend rx);
void set_filter_broadcast(chanend rx);

void receiver(chanend rx, chanend loopback);
void transmitter(chanend tx, chanend loopback);

extern inline unsigned int mac_custom_filter(unsigned int data[]);

void test(chanend tx, chanend rx)
{
  unsigned time;
  chan loopback;

  printstr("Connecting...\n");
  { timer tmr; tmr :> time; tmr when timerafter(time + 600000000) :> time; }
  printstr("Ethernet initialised\n");

#if ETHERNET_DEFAULT_IS_FULL
  mac_set_custom_filter(rx, 0x1);
#endif

  printstr("Loopback running\n");

  par
    {
      transmitter(tx, loopback);
      receiver(rx, loopback);
    }
}

void receiver(chanend rx, chanend loopback)
{
  unsigned char rxbuffer[1600];

  while (1)
    {
      unsigned int src_port;
      unsigned int nbytes;
      mac_rx(rx, rxbuffer, nbytes, src_port);
      pass_frame(loopback, rxbuffer, nbytes);
    }
  set_thread_fast_mode_off();
}

void transmitter(chanend tx, chanend loopback)
{
  unsigned  int txbuffer[1600/4];

  while (1)
    {
      int nbytes;
      fetch_frame((txbuffer, unsigned char[]), loopback, nbytes);
      mac_tx(tx, txbuffer, nbytes, ETH_BROADCAST);
    }
}

int main()
{
  chan rx[1], tx[1];

  par
    {
      on ETHERNET_DEFAULT_TILE:
      {
        char mac_address[6];
        otp_board_info_get_mac(otp_ports, 0, mac_address);
        eth_phy_reset(eth_rst);
        smi_init(smi);
        eth_phy_config(1, smi);
        ethernet_server(mii,
                        smi,
                        mac_address,
                        rx, 1,
                        tx, 1);
      }
      on tile[0] : test(tx[0], rx[0]);
    }

  return 0;
}
