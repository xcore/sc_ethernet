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
#include "test_frame.h"
#include "getmac.h"
#include "eth_phy.h"

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
#ifndef ETHERNET_CORE
  #define ETHERNET_CORE 1
#endif

// OTP Ports
on stdcore[ETHERNET_CORE]: port otp_data = XS1_PORT_32B; 		// OTP_DATA_PORT
on stdcore[ETHERNET_CORE]: out port otp_addr = XS1_PORT_16C;	// OTP_ADDR_PORT
on stdcore[ETHERNET_CORE]: port otp_ctrl = XS1_PORT_16D;		// OTP_CTRL_PORT

mii_interface_t mii =
  on stdcore[ETHERNET_CORE]:
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


#ifdef PORT_ETH_RSTN
#define PORT_ETH_RST_N PORT_ETH_RSTN
#endif

#ifdef PORT_ETH_RST_N
on stdcore[ETHERNET_CORE]: out port p_mii_resetn = PORT_ETH_RST_N;
on stdcore[ETHERNET_CORE]: smi_interface_t smi = { PORT_ETH_MDIO, PORT_ETH_MDC, 0 };
#else
on stdcore[ETHERNET_CORE]: smi_interface_t smi = { PORT_ETH_RST_N_MDIO, PORT_ETH_MDC, 1 };
#endif

on stdcore[ETHERNET_CORE]: clock clk_smi = XS1_CLKBLK_5;

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
	wait(600000000);
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

#define NUM_PACKETS 20
#define PACKET_LEN 100
#define TOLERANCE 100

void transmitter(chanend tx, chanend ready, int qtag)
{
	unsigned int txbuffer[1600/4];
	int len = PACKET_LEN;

	generate_test_frame(len, (txbuffer, unsigned char[]), qtag);

	// Wait to make sure receiver is ready
        ready :> int;
        for(int i=0;i<NUM_PACKETS;i++) {
          mac_tx(tx, txbuffer, len, ETH_BROADCAST);
          //          len--;
	}
}

int receiver(chanend rx, chanend ready, int expected_spacing)
{
	unsigned char rxbuffer[1600];
	int len = PACKET_LEN;
        unsigned int rtimes[NUM_PACKETS];

        mac_set_queue_size(rx, NUM_PACKETS+2);

        ready <: 1;
        for (int i=0;i<NUM_PACKETS;i++) 
	{
		unsigned int src_port;
		unsigned int nbytes;
        
		mac_rx_timed(rx, rxbuffer, nbytes, rtimes[i], src_port);

		if (len != nbytes)
		{
			printstr("Error received ");
			printint(nbytes);
			printstr(" bytes, expected ");
			printintln(len);
			return 0;
		}

		if (!check_test_frame(len, rxbuffer))
		{
			printstr("Error receiving frame, len = ");
			printintln(len);
			return 0;
		}
                //		len--;
	}

        for (int i=0;i<NUM_PACKETS-1;i++) {
          
          //          printintln((int) rtimes[i+1] - (int) rtimes[i]);
          int spacing = (int) rtimes[i+1] - (int) rtimes[i];
          int error = spacing - expected_spacing;
          if (error < 0)
            error = -error;

          if (error > TOLERANCE) 
            {
              printstr("Error in spacing\n");
              printstr("Expected ");
              printint(expected_spacing);
              printstr(" +- ");
              printintln(TOLERANCE);
              printstr("Got ");
              printintln(spacing);
            }
          
        }

	return 1;
}


extern unsigned int mac_custom_filter(unsigned int data[]);

int mac_tx_rx_data_test(chanend tx, chanend rx, int bits_per_second)
{
	chan ready;
	int res;
        int expected_spacing;
        mac_set_qav_bandwidth(tx, bits_per_second);                          
        
        printstr("Allowed bandwidth ");
        printint(bits_per_second/1000000);
        printstr("MBit\n");
        expected_spacing = PACKET_LEN*8*(100000000/bits_per_second);
        printstr("Expected spacing: ");
        printint(expected_spacing);
        printstr(" +- ");
        printintln(TOLERANCE);
	par
	{
          transmitter(tx, ready, 1);
          res = receiver(rx, ready, expected_spacing);
	}

	return res;
}

void runtests(chanend tx[], chanend rx[], int links)
{
	RUNTEST("init", init(rx, tx, links));
	RUNTEST("traffic shaper test", mac_tx_rx_data_test(tx[0], rx[0], 
                                                           50000000));
	RUNTEST("traffic shaper test", mac_tx_rx_data_test(tx[0], rx[0], 
                                                           25000000));
        //	RUNTEST("mac_tx_rx_data_test", mac_tx_rx_data_test(tx[0], rx[0], 5 << 24));
	printstr("Complete");
	_Exit(0);
}

int main()
{
  chan rx[MAX_LINKS], tx[MAX_LINKS];

  par
  {
      on stdcore[ETHERNET_CORE]:
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


