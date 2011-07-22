/**
 * Module:  app_ethernet_demo2
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    test2.xc
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2009
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
#include <xs1.h>
#include <print.h>
#include <platform.h>
#include <stdlib.h>
#include "ethernet_server.h"
#include "ethernet_rx_client.h"
#include "ethernet_tx_client.h"
#include "test_frame.h"
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

void receiver(chanend rx);
void transmitter(chanend tx);

void test(chanend tx, chanend rx)
{
	unsigned time;

	printstr("Connecting...\n");
	{ timer tmr; tmr :> time; tmr when timerafter(time + 600000000) :> time; }
	printstr("Ethernet initialised\n");

	set_filter_broadcast(rx);
	printstr("Filter configured\n");

	printstr("Test started\n");

	par
	{
		transmitter(tx);
		receiver(rx);
	}

	printstr("Test finished\n");
}

void receiver(chanend rx)
{
	unsigned char rxbuffer[1600];
	int counter = 0;


	while (counter < 10000)
	{
          unsigned int src_port;
          int nbytes = mac_rx(rx, rxbuffer, src_port);
          unsigned stamp = get_test_frame_stamp(rxbuffer);
          if (nbytes != test_frame_size() || stamp != counter)
            {
              printstr("INVALID FRAME RECEIVED\nFrame size: ");
              printhex(nbytes);
              printstr("\nCounter in frame: ");
              printhex(stamp);
              printstr("\nRunning counter: ");
              printhex(counter);
              printstr("\n");
              exit(1);
            }
          counter++;
	}
        
        printstr("Successfully received ");
        printhex(counter);
        printstr(" frames\n");
        
}

void transmitter(chanend tx)
{
  unsigned int txbuffer[1600/4];
  int counter = 0;
  int nbytes;
  
  nbytes = generate_test_frame((txbuffer, unsigned char[]));
  
  // Wait to make sure receiver is ready
  { timer tmr; unsigned t; tmr :> t; tmr when timerafter(t + 100000000) :> t; }
  
  while (counter < 10000)
    {
      stamp_test_frame((txbuffer, unsigned char[]), counter);
      mac_tx(tx, txbuffer, nbytes, ETH_BROADCAST);
      counter++;      
      // Gap to allow breathing time to memcpy frames etc.
      { timer tmr; unsigned t; tmr :> t; tmr when timerafter(t + 10000) :> t; }
    }
  
  while (1)
    ;
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
