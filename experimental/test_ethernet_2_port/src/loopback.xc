// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <xclib.h>
#include <print.h>
#include <platform.h>
#include <stdlib.h>

#include "ethernet_server.h"
#include "ethernet_tx_client.h"
#include "ethernet_rx_client.h"
#include "getmac.h"

/*
 *  For this test app - put a crossover cable between the two ports on the XC-3
 */




//***** Ethernet Configuration ****
// OTP Core
#ifndef ETHERNET_OTP_CORE
	#define ETHERNET_OTP_CORE 2
#endif

// OTP Ports
on stdcore[ETHERNET_OTP_CORE]: port otp_data = XS1_PORT_32B; 		// OTP_DATA_PORT
on stdcore[ETHERNET_OTP_CORE]: out port otp_addr = XS1_PORT_16C;	// OTP_ADDR_PORT
on stdcore[ETHERNET_OTP_CORE]: port otp_ctrl = XS1_PORT_16D;		// OTP_CTRL_PORT

on stdcore[2]: mii_interface_t mii_0 =
  {
    XS1_CLKBLK_1,
    XS1_CLKBLK_2,

    PORT_ETH_RXCLK_0,
    PORT_ETH_RXER_0,
    PORT_ETH_RXD_0,
    PORT_ETH_RXDV_0,

    PORT_ETH_TXCLK_0,
    PORT_ETH_TXEN_0,
    PORT_ETH_TXD_0,
  };

on stdcore[2]: mii_interface_t mii_1 =
  {
    XS1_CLKBLK_3,
    XS1_CLKBLK_4,

    PORT_ETH_RXCLK_1,
    PORT_ETH_RXER_1,
    PORT_ETH_RXD_1,
    PORT_ETH_RXDV_1,

    PORT_ETH_TXCLK_1,
    PORT_ETH_TXEN_1,
    PORT_ETH_TXD_1,
  };


on stdcore[2]: out port p_mii_resetn = PORT_ETH_RST_N;
on stdcore[2]: smi_interface_t smi_0 = { PORT_ETH_MDIO_0, PORT_ETH_MDC_0, 0 };
on stdcore[2]: smi_interface_t smi_1 = { PORT_ETH_MDIO_1, PORT_ETH_MDC_1, 0 };

on stdcore[2]: clock clk_smi = XS1_CLKBLK_5;

void set_filter_broadcast(chanend rx);

#define COUNT 1200


void wait_long() {
	timer tmr;
	unsigned time;
	tmr :> time;
	tmr when timerafter(time + 300000000) :> void;
}

void wait_short() {
	timer tmr;
	unsigned time;
	tmr :> time;
	tmr when timerafter(time + 50000000) :> void;
}

void receiver(chanend rx, chanend c)
{
  unsigned int rxbuffer[1600/4];
  unsigned int src_port;
  unsigned int nbytes;

  mac_set_custom_filter(rx, 0x1);

  for (unsigned n=0; n<COUNT; ++n) {
      mac_rx(rx, (rxbuffer, unsigned char[]), nbytes, src_port);

	  if (rxbuffer[4] != n) {
		  printstr("Wrong contents ");
		  printuint(rxbuffer[5]);
		  printstr("\n");
	  }
      if (src_port != (1-(n&1))) {
    	  printstr("Received on wrong port ");
    	  printuint(src_port);
    	  printstr("\n");
      }
      if (nbytes != ((n & 0x3ff)+60)) {
    	  printstr("Wrong number of bytes in packet ");
    	  printuint(nbytes);
    	  printstr("\n");
      }
      c <: 1;
  }

  printstr("Finshed direction test\n");

  for (unsigned n=0; n<COUNT; ++n) {
	  mac_rx(rx, (rxbuffer, unsigned char[]), nbytes, src_port);
	  mac_rx(rx, (rxbuffer, unsigned char[]), nbytes, src_port);

	  if (rxbuffer[4] != n) {
		  printstr("Wrong contents ");
		  printuint(rxbuffer[5]);
		  printstr("\n");
	  }
	  if (nbytes != ((n & 0x3ff)+60)) {
    	  printstr("Wrong number of bytes in packet ");
    	  printuint(nbytes);
    	  printstr("\n");
      }

      c <: 1;
  }

  printstr("Finshed broadcast test\n");

  set_thread_fast_mode_off();
}

void transmitter(chanend tx, chanend c)
{
  unsigned int txbuffer[1600/4];

  txbuffer[0] = byterev(0xffffffff);
  txbuffer[1] = byterev(0xffff0011);
  txbuffer[2] = byterev(0x22334455);
  txbuffer[3] = byterev(0x88880000);

  for (unsigned n=0; n<COUNT; ++n) {
	  txbuffer[4] = n;
      mac_tx(tx, txbuffer, (n & 0x3ff)+60, (n&1));
      c :> unsigned;
  }

  for (unsigned n=0; n<COUNT; ++n) {
	  txbuffer[4] = n;
      mac_tx(tx, txbuffer, (n & 0x3ff)+60, ETH_BROADCAST);
      c :> unsigned;
  }
}

void test(chanend tx, chanend rx)
{
  chan c;

  wait_long();
  printstr("Ethernet initialised\n");

  par
    {
      transmitter(tx, c);
      receiver(rx, c);
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
		ethernet_getmac_otp(otp_data, otp_addr, otp_ctrl, (mac_address, char[]));
		phy_init_two_port(clk_smi, p_mii_resetn, smi_0, smi_1, mii_0, mii_1);
        ethernet_server_two_port(mii_0, mii_1, mac_address, rx, 1, tx, 1, null, null, null);
      }
      on stdcore[3] : test(tx[0], rx[0]);
    }

  return 0;
}
