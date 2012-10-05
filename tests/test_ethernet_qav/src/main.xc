// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <print.h>
#include <platform.h>
#include <stdlib.h>
#include "ethernet.h"
#include "ethernet_board_support.h"
#include "otp_board_info.h"
#include "test_frame.h"

#define RUNTEST(name, x) printstrln("*************************** " name " ***************************"); \
							  printstrln( (x) ? "PASSED" : "FAILED" )


#define ERROR printstr("ERROR: "__FILE__ ":"); printintln(__LINE__);

#define MAX_WIRE_DELAY_LOOPBACK 92
#define MAX_WIRE_DELAY 35000 // 350 us
#define FILTER_BROADCAST 0xF0000000
#define MAX_LINKS 4
#define BUFFER_TEST_BUFSIZE NUM_MII_RX_BUF - 1

//***** Ethernet Configuration ****
// These ports are for accessing the OTP memory
otp_ports_t otp_ports = OTP_PORTS_INITIALIZER;

// Here are the port definitions required by ethernet
// The intializers are taken from the ethernet_board_support.h header for
// XMOS dev boards. If you are using a different board you will need to
// supply explicit port structure intializers for these values
smi_interface_t smi = ETHERNET_DEFAULT_SMI_INIT;
mii_interface_t mii = ETHERNET_DEFAULT_MII_INIT;
ethernet_reset_interface_t eth_rst = ETHERNET_DEFAULT_RESET_INTERFACE_INIT;

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

      //::ethernet
      on ETHERNET_DEFAULT_TILE:
      {
        char mac_address[6];
        otp_board_info_get_mac(otp_ports, 0, mac_address);
        eth_phy_reset(eth_rst);
        smi_init(smi);
        eth_phy_config(1, smi);
        ethernet_server(mii,
                        null,
                        mac_address,
                        rx, 1,
                        tx, 1);
      }
      //::
      on tile[0]: runtests(tx, rx, MAX_LINKS);
    }

  return 0;
}


