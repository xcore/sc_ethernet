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

//***** Ethernet Configuration ****
// OTP Core
#ifndef ETHERNET_OTP_CORE
	#define ETHERNET_OTP_CORE 2
#endif

// OTP Ports
on stdcore[ETHERNET_OTP_CORE]: port otp_data = XS1_PORT_32B; 		// OTP_DATA_PORT
on stdcore[ETHERNET_OTP_CORE]: out port otp_addr = XS1_PORT_16C;	// OTP_ADDR_PORT
on stdcore[ETHERNET_OTP_CORE]: port otp_ctrl = XS1_PORT_16D;		// OTP_CTRL_PORT

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
		ethernet_getmac_otp(otp_data, otp_addr, otp_ctrl, mac_address);
        phy_init(clk_smi, 
#ifdef PORT_ETH_RST_N
               p_mii_resetn,
#else
               null,
#endif
                 smi,
                 mii);
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
