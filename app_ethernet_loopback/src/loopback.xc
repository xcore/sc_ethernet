// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <print.h>
#include <platform.h>
#include <stdlib.h>
#include "ethernet_server.h"
#include "ethernet_tx_client.h"
#include "ethernet_rx_client.h"
#include "frame_channel.h"
#include "getmac.h"
#include <print.h>
#include "ethernet_quickstart.h"

otp_ports_t otp_ports = ETH_QUICKSTART_OTP_PORTS_INIT;
smi_interface_t smi = ETH_QUICKSTART_SMI_INIT;
mii_interface_t mii = ETH_QUICKSTART_MII_INIT;

void test(chanend tx, chanend rx);
void set_filter_broadcast(chanend rx);

void receiver(chanend rx, chanend loopback);
void transmitter(chanend tx, chanend loopback);

void test(chanend tx, chanend rx)
{
  unsigned time;
  chan loopback;

  printstr("Connecting...\n");
  { timer tmr; tmr :> time; tmr when timerafter(time + 600000000) :> time; }
  printstr("Ethernet initialised\n");

  mac_set_custom_filter(rx, 0x1);

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

extern unsigned int mac_custom_filter(unsigned char data[]);

int main()
{
  chan rx[1], tx[1];

  par
    {
      on stdcore[2]:
      {
        int mac_address[2];
        ethernet_getmac_otp(otp_ports,
                            (mac_address, char[]));
        smi_init(smi);
        eth_phy_config(1, smi);
        ethernet_server(mii, mac_address,
                        rx, 1,
                        tx, 1,
                        null,
                        null);
      }
      on stdcore[3] : test(tx[0], rx[0]);
    }

  return 0;
}
