// Copyright (c) 2011, XMOS Ltd., All rights reserved
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




//***** Ethernet Configuration ****

on stdcore[2]: clock clk_mii_ref = XS1_CLKBLK_REF;

on stdcore[2]: mii_interface_t mii =
  {
    XS1_CLKBLK_1,
    XS1_CLKBLK_2,

    PORT_ETH_RXCLK,
    PORT_ETH_RXER,
    PORT_ETH_RXD,
    PORT_ETH_RXDV,

    PORT_ETH_TXCLK,
    PORT_ETH_TXEN,
    PORT_ETH_TXD,
  };


#ifdef PORT_ETH_RST_N
on stdcore[2]: out port p_mii_resetn = PORT_ETH_RST_N;
on stdcore[2]: smi_interface_t smi = { PORT_ETH_MDIO, PORT_ETH_MDC, 0 };
#else
on stdcore[2]: smi_interface_t smi = { PORT_ETH_RST_N_MDIO, PORT_ETH_MDC, 1 };
#endif

on stdcore[2]: clock clk_smi = XS1_CLKBLK_5;



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
  
  set_filter_broadcast(rx);
  printstr("Filter configured\n");
  
  printstr("Test started\n");
  
  par
    {
      transmitter(tx, loopback);
      receiver(rx, loopback);
    }
  
  printstr("Test finished\n");
}

void receiver(chanend rx, chanend loopback)
{
  int counter = 0;
  unsigned char rxbuffer[1600];
    
  while (1)
    {
      unsigned int src_port;
      int nbytes = mac_rx(rx, rxbuffer, src_port);
      pass_frame(loopback, rxbuffer, nbytes);
    }  
  set_thread_fast_mode_off();
}

void transmitter(chanend tx, chanend loopback)
{
  unsigned  int txbuffer[1600/4];
  int counter = 0;
 
 
  while (1)
    {
      int nbytes;
      fetch_frame((txbuffer, unsigned char[]), loopback, nbytes);
      (txbuffer, unsigned char[])[12] = 0xF0;
      (txbuffer, unsigned char[])[13] = 0xF0;
      mac_tx(tx, txbuffer, nbytes, ETH_BROADCAST);
    }
}

void set_filter_broadcast(chanend rx)
{
  struct mac_filter_t f;
  f.opcode = OPCODE_OR;
  for (int i = 0; i < 6; i++)
  {
    f.dmac_msk[i] = 0xFF;
    f.vlan_msk[i] = 0;
  }
  for (int i = 0; i < 6; i++)
  {
    f.dmac_val[i] = 0xFF;
  }
  if (mac_set_filter(rx, 0, f) == -1)
  {
    printstr("Filter configuration failed\n");
    exit(1);
  }
}



int main() 
{
  chan rx[1], tx[1];
 
  par
    {
      on stdcore[2]:
      {
        int mac_address[2];
        ethernet_getmac_otp((mac_address, char[]));
        phy_init(clk_smi, clk_mii_ref, 
#ifdef PORT_ETH_RST_N               
               p_mii_resetn,
#else
               null,
#endif
                 smi,
                 mii);
        ethernet_server(mii, clk_mii_ref, mac_address, 
                        rx, 1,
                        tx, 1,
                        null,
                        null);
      }
      on stdcore[0] : test(tx[0], rx[0]);
    }
  
  return 0;
}
