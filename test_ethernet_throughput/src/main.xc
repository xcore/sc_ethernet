// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <print.h>
#include <platform.h>
#include <stdlib.h>
#include "ethernet_server.h"
#include "ethernet_rx_client.h"
#include "ethernet_tx_client.h"
#include "getmac.h"
#include "eth_phy.h"

#ifndef ETH_CORE
#define ETH_CORE 1
#endif

#define RUNTEST(name, x) printstrln("*************************** " name " ***************************"); \
							  printstrln( (x) ? "PASSED" : "FAILED" )


#define ERROR printstr("ERROR: "__FILE__ ":"); printintln(__LINE__);

#define MAX_WIRE_DELAY_LOOPBACK 92
#define MAX_WIRE_DELAY 35000 // 350 us
#define FILTER_BROADCAST 0xF0000000
#define MAX_LINKS 4
#define BUFFER_TEST_BUFSIZE NUM_MII_RX_BUF - 1

//***** Ethernet Configuration ****
// OTP Core

// OTP Ports
on stdcore[ETH_CORE]: port otp_data = XS1_PORT_32B; 		// OTP_DATA_PORT
on stdcore[ETH_CORE]: out port otp_addr = XS1_PORT_16C;	// OTP_ADDR_PORT
on stdcore[ETH_CORE]: port otp_ctrl = XS1_PORT_16D;		// OTP_CTRL_PORT

mii_interface_t mii =
  on stdcore[ETH_CORE]:
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


#ifndef PORT_ETH_RST_N
#define PORT_ETH_RST_N PORT_ETH_RSTN
#endif

#ifdef PORT_ETH_RST_N
on stdcore[ETH_CORE]: out port p_mii_resetn = PORT_ETH_RST_N;
on stdcore[ETH_CORE]: smi_interface_t smi = { PORT_ETH_MDIO, PORT_ETH_MDC, 0 };
#else
on stdcore[ETH_CORE]: smi_interface_t smi = { PORT_ETH_RST_N_MDIO, PORT_ETH_MDC, 1 };
#endif

on stdcore[ETH_CORE]: clock clk_smi = XS1_CLKBLK_5;

void wait(int ticks)
{
	timer tmr;
	unsigned t;
	tmr :> t;
	tmr when timerafter(t + ticks) :> t;
}

void print_mac_addr(chanend tx)
{
	char macaddr[6];
	mac_get_macaddr(tx, macaddr);
	printstr("MAC Address: ");
	for (int i = 0; i < 6; i++){
		printhex(macaddr[i]);
		if (i < 5)
			printstr(":");
	}
	printstrln("");
}

int init(chanend rx [], chanend tx[], int links)
{
	printstr("Connecting...\n");
	//wait(600000000);
	printstr("Ethernet initialised\n");

	print_mac_addr(tx[0]);

	for (int i = 0; i < links; ++i) {
		if (i == 0){
			mac_set_custom_filter(rx[i], FILTER_BROADCAST);
		}else{
			mac_set_custom_filter(rx[i], 0);
		}
	}

	printstr("Filter configured\n");
	return 1;
}



extern unsigned int mac_custom_filter(unsigned int data[]);


#define TEST_PACKET_SIZE	100
#define NUM_TEST_PACKETS        500000

void tx(chanend c_mac_tx, chanend c_to_receiver) {
  unsigned int buf[(TEST_PACKET_SIZE+3)>>2];
  timer tmr;
  int start_time, end_time;
  // Wait to make sure receiver is ready
  wait(10000000);
  tmr :> start_time;
  printstr("Starting TX\n");
  for (int i=0;i<NUM_TEST_PACKETS;i++) {
    mac_tx(c_mac_tx, buf, TEST_PACKET_SIZE, ETH_BROADCAST);
  }
  tmr :> end_time;
  c_to_receiver <: end_time - start_time;
}

void rx(chanend c_mac_rx, chanend c_from_transmitter) {
  timer tmr;
  unsigned char buf[1600];
  int timed_out = 0;
  int i;
  unsigned int start_time, end_time;
  int do_timeout = 0;
  tmr :> start_time;
  for(i=0;i<NUM_TEST_PACKETS && !timed_out;i++) {
    int time;
    unsigned int nbytes;
    unsigned int src_port;
    select
      {
      case mac_rx(c_mac_rx, buf, nbytes, src_port):
        tmr :> time;
        do_timeout = 1;
        break;
      case do_timeout => tmr when timerafter(time+100000000) :> int:
        timed_out = 1;
        break;
      }
  }
  tmr :> end_time;
  printstr("Received ");printintln(i);printstrln(" packets\n");
  if (i == NUM_TEST_PACKETS) {
    int tx_period;
    printintln(end_time - start_time);
    c_from_transmitter :> tx_period;
    printintln(tx_period);
  }
  else {
    printstr("ERROR: dropped ");printintln(NUM_TEST_PACKETS-i);printstr(" packets\n");
  }
}

int mac_tx_rx_data_test(chanend c_tx, chanend c_rx)
{
	int res;
        chan c;
	par
	{
          tx(c_tx, c);
          rx(c_rx, c);
	}

	return 0;
}


void runtests(chanend c_tx[], chanend c_rx[], int links)
{
	RUNTEST("init", init(c_rx, c_tx, links));
        RUNTEST("mac_tx_rx_data_test", mac_tx_rx_data_test(c_tx[0], c_rx[0]));
	printstr("Complete");
	_Exit(0);
}

int main()
{
  chan rx[MAX_LINKS], tx[MAX_LINKS];

  par
  {
      on stdcore[1]:
      {
        int mac_address[2];
        ethernet_getmac_otp(otp_data, otp_addr, otp_ctrl, (mac_address, char[]));
        phy_init(clk_smi,
#ifdef PORT_ETH_RST_N
               p_mii_resetn,
#else
               null,
#endif
                 smi,
                 mii);
        eth_phy_loopback(1, smi);
        ethernet_server(mii, mac_address,
                        rx, MAX_LINKS,
                        tx, MAX_LINKS,
                        null,
                        null);

      }

      on stdcore[0]: runtests(tx, rx, MAX_LINKS);
    }

  return 0;
}


