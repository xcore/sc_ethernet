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
#ifndef ETHERNET_OTP_CORE
	#define ETHERNET_OTP_CORE 2
#endif

// OTP Ports
on stdcore[ETHERNET_OTP_CORE]: port otp_data = XS1_PORT_32B; 		// OTP_DATA_PORT
on stdcore[ETHERNET_OTP_CORE]: out port otp_addr = XS1_PORT_16C;	// OTP_ADDR_PORT
on stdcore[ETHERNET_OTP_CORE]: port otp_ctrl = XS1_PORT_16D;		// OTP_CTRL_PORT

mii_interface_t mii =
  on stdcore[2]:
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

void transmitter(chanend tx, chanend ready)
{
	unsigned int txbuffer[1600/4];
	int len = 1000;

	generate_test_frame(len, (txbuffer, unsigned char[]));

	// Wait to make sure receiver is ready
	wait(10000000);

	while (len > 64)
	{
		ready :> int;
		mac_tx(tx, txbuffer, len, ETH_BROADCAST);
		len--;
	}
}

int receiver(chanend rx, chanend ready)
{
	unsigned char rxbuffer[1600];
	int len = 1000;

	while (len > 64)
	{
		unsigned int src_port;
		unsigned int nbytes;
		ready <: 1;
		mac_rx(rx, rxbuffer, nbytes, src_port);

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
		len--;
	}

	return 1;
}

void transmitter_timed(chanend tx, chanend ready, chanend txtime)
{
	unsigned int txbuffer[1600/4];
	int len = 1000;
	unsigned int time;

	generate_test_frame(len, (txbuffer, unsigned char[]));

	// Wait to make sure receiver is ready
	wait(10000000);

	while (len > 64)
	{
		ready :> int;
		mac_tx_timed(tx, txbuffer, len, time, ETH_BROADCAST);
		txtime <: time;
		len--;
	}
}

int receiver_timed(chanend rx, chanend ready, chanend txtime)
{
	unsigned char rxbuffer[1600];
	int len = 1000;
	unsigned int rxtime;

	while (len > 64)
	{
		unsigned int src_port;
		unsigned int nbytes;
		int t;
		ready <: 1;
		mac_rx_timed(rx, rxbuffer, nbytes, rxtime, src_port);
		txtime :> t;

		if (rxtime - t > MAX_WIRE_DELAY_LOOPBACK)
		{
			printstr("tx: ");
			printint(t);
			printstr(" rx: ");
			printint(rxtime);
			printstr(" diff = ");
			printintln(rxtime - t);
			ERROR;
			return 0;
		}

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
		len--;
	}

	return 1;
}

void transmitter_filter(chanend tx, chanend ready)
{
	unsigned int txbuffer[1600/4];
	int len = 1000;

	generate_test_frame(len, (txbuffer, unsigned char[]));

	// Wait to make sure receiver is ready
	wait(10000000);

	while (len > 64)
	{
		for (int i = 0; i < MAX_LINKS; i++)
		{
			ready :> int;
			set_ethertype((txbuffer, unsigned char[]), 0x0800 + i);
			mac_tx(tx, txbuffer, len, ETH_BROADCAST);
		}
		len--;
	}
}

int receiver_filter(chanend rx[], chanend ready, int links)
{
	unsigned char rxbuffer[1600];
	int len = 1000;

	while (len > 64)
	{
		unsigned int src_port;
		unsigned short etype;
		unsigned int nbytes;

		for (int i = 0; i < links; i++)
		{
			ready <: 1;
			mac_rx(rx[i], rxbuffer, nbytes, src_port);

			if (len != nbytes){
				printstr("Error received ");
				printint(nbytes);
				printstr(" bytes, expected ");
				printintln(len);
				return 0;
			}

			if (!check_test_frame(len, rxbuffer)){
				printstr("Error in frame contents, len = ");
				printintln(len);
				return 0;
			}

			etype = get_ethertype(rxbuffer);
			if (etype != 0x0800 + i){
				printstr("Error in ethertype. Received ");
				printhex(etype);
				printstr(" expected ");
				printhexln(0x0800 + i);
				return 0;
			}
		}

		len--;
	}

	return 1;
}

// Interframe gap is 12 bytes + 8 bytes preamble (1/100Mbps * 160) = 1.6us = 1600 ns

#define FRAME_GAP_TICKS 160

void transmitter_buffer(chanend tx, chanend sent)
{
	unsigned int txbuffer[1600/4];
	int len = 1000;

	generate_test_frame(len, (txbuffer, unsigned char[]));

	for (int i = 0; i < BUFFER_TEST_BUFSIZE; i++)
	{
		set_ethertype((txbuffer, unsigned char[]), 0x0800 + i);
		mac_tx(tx, txbuffer, len, ETH_BROADCAST);
	}

	sent <: 1;
}

int receiver_buffer(chanend rx, chanend sent)
{
	unsigned char rxbuffer[1600];
	int len = 1000;
	unsigned int src_port;
	unsigned int nbytes;
	unsigned short etype;

	sent :> int;

	for (int i = 0; i < BUFFER_TEST_BUFSIZE; i++)
	{
		mac_rx(rx, rxbuffer, nbytes, src_port);

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

		etype = get_ethertype(rxbuffer);
		if (etype != 0x0800 + i)
		{
			printstr("Error in ethertype. Received ");
			printhex(etype);
			printstr(" expected ");
			printhexln(0x0800 + i);
			return 0;
		}
	}

	return 1;
}

void transmitter_queue(chanend tx[], int links, chanend sent, int queue_size)
{
	unsigned int txbuffer[1600/4];
	int len = 1000;

	generate_test_frame(len, (txbuffer, unsigned char[]));

	// Wait to make sure receiver is ready
	wait(10000000);

	// Send queue_size frames to link 0
	for (int i = 0; i < queue_size; i++)
	{
		set_ethertype((txbuffer, unsigned char[]), 0x0800);
		(txbuffer,char[])[20] = i;
		mac_tx(tx[0], txbuffer, len, ETH_BROADCAST);
	}

	// Overflow buffers on other links
	for (int i = 1; i < links; i++)
	{
          set_ethertype((txbuffer, unsigned char[]), 0x0800 + i);
          for (int j = 0; j < queue_size * 2; ++j)
          {
            mac_tx(tx[i], txbuffer, len, ETH_BROADCAST);
          }
	}

	sent <: 1;
}

int receiver_queue(chanend rx, chanend sent, int queue_size)
{
	unsigned char rxbuffer[1600];
	int len = 1000;

	unsigned int src_port;
	unsigned short etype;
	unsigned int nbytes;

	sent :> int;

	for (int i = 0; i < queue_size; i++)
	{
		mac_rx(rx, rxbuffer, nbytes, src_port);

		if (len != nbytes)
		{
			printstr("Error received ");
			printint(nbytes);
			printstr(" bytes, expected ");
			printintln(len);
			return 0;
		}

		if (rxbuffer[20] != i)
		{
			printstr("Error in frame contents, received ");
			printint(rxbuffer[20]);
			printstr(" expected ");
			printintln(i);
			ERROR;
			return 0;
		}

		etype = get_ethertype(rxbuffer);
		if (etype != 0x0800)
		{
			printstr("Error in ethertype. Received ");
			printhex(etype);
			printstr(" expected ");
			printhexln(0x0800);
			return 0;
		}
	}

	return 1;
}


extern unsigned int mac_custom_filter(unsigned int data[]);

int mac_tx_rx_data_test(chanend tx, chanend rx)
{
	chan ready;
	int res;

	par
	{
		transmitter(tx, ready);
		res = receiver(rx, ready);
	}

	return res;
}

int mac_tx_rx_data_timed_test(chanend tx, chanend rx)
{
	chan txtime;
	chan ready;
	int res;

	par
	{
		transmitter_timed(tx, ready, txtime);
		res = receiver_timed(rx, ready, txtime);
	}

	return res;
}

int mac_rx_filter_test(chanend tx[], chanend rx[], int links)
{
	chan ready;
	int res;

	for (int i = 0; i < links; ++i)
	{
		mac_set_custom_filter(rx[i], 1 << i);
	}

	par
	{
		transmitter_filter(tx[0], ready);
		res = receiver_filter(rx, ready, links);
	}

	return res;
}

int mac_rx_buffer_test(chanend tx, chanend rx, int links)
{
	chan sent;
	int res;

	mac_set_custom_filter(rx, FILTER_BROADCAST);
	mac_set_queue_size(rx, BUFFER_TEST_BUFSIZE);

	par
	{
		transmitter_buffer(tx, sent);
		res = receiver_buffer(rx, sent);
	}

	return res;
}

int mac_rx_queue_test(chanend tx[], chanend rx[], int links)
{
	chan sent;
	int res;
    int queue_size = NUM_MII_RX_BUF / links;

    mac_set_custom_filter(rx[0], 1 << 0);
    mac_set_queue_size(rx[0], queue_size);

	for (int i = 1; i < links; ++i)
	{
		mac_set_custom_filter(rx[i], 1 << i);
        mac_set_queue_size(rx[i], 1);
	}

	par
	{
		transmitter_queue(tx, links, sent, queue_size);
		res = receiver_queue(rx[0], sent, queue_size);
	}

	return res;
}

void runtests(chanend tx[], chanend rx[], int links)
{
	RUNTEST("init", init(rx, tx, links));
	RUNTEST("mac_tx_rx_data_test", mac_tx_rx_data_test(tx[0], rx[0]));
	RUNTEST("mac_tx_rx_data_timed_test", mac_tx_rx_data_timed_test(tx[0], rx[0]));
	RUNTEST("mac_rx_buffer_test", mac_rx_buffer_test(tx[0], rx[0], links));
	RUNTEST("mac_rx_filter_test", mac_rx_filter_test(tx, rx, links));
	RUNTEST("mac_rx_queue_test", mac_rx_queue_test(tx, rx, links));
	printstr("Complete");
	_Exit(0);
}

int main()
{
  chan rx[MAX_LINKS], tx[MAX_LINKS];

  par
  {
      on stdcore[2]:
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


