// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*************************************************************************
 *
 * Ethernet MAC Layer Client Test Code
 * IEEE 802.3 MAC Client
 *
 *
 *************************************************************************
 *
 * ARP/ICMP demo
 * Note: Only supports unfragmented IP packets
 *
 *************************************************************************/

#include <xs1.h>
#include <xclib.h>
#include <print.h>
#include <platform.h>
#include <stdlib.h>
#include "ethernet_server.h"
#include "ethernet_rx_client.h"
#include "ethernet_tx_client.h"
#include "checksum.h"
#include "getmac.h"

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

unsigned char own_mac_addr[6]; // MAC address on core 0
int mac_address[2]; // MAC address on core 2

unsigned char ethertype_ip[] = {0x08, 0x00};
unsigned char ethertype_arp[] = {0x08, 0x06};

//::ip_address_define
// NOTE: YOU MAY NEED TO REDEFINE THIS TO AN IP ADDRESS THAT WORKS
// FOR YOUR NETWORK
#define OWN_IP_ADDRESS {169, 254, 5, 27}
//::

#define ARP_RESPONSE 1
#define ICMP_RESPONSE 2
#define UDP_RESPONSE 3

void demo(chanend tx, chanend rx);
extern void ethernet_register_traphandler();

#pragma unsafe arrays
int is_ethertype(unsigned char data[], unsigned char type[]){
	int i = 12;
	return data[i] == type[0] && data[i + 1] == type[1];
}

#pragma unsafe arrays
int is_mac_addr(unsigned char data[], unsigned char addr[]){
	for (int i=0;i<6;i++){
#pragma xta label "sc_ethernet_is_mac_addr_1"
#pragma xta command "add loop sc_ethernet_is_mac_addr_1 6"
          if (data[i] != addr[i]){
			return 0;
		}
	}

	return 1;
}

#pragma unsafe arrays
int is_broadcast(unsigned char data[]){
	for (int i=0;i<6;i++){
#pragma xta label "sc_ethernet_is_broadcast_1"
#pragma xta command "add loop sc_ethernet_is_broadcast_1 6"
          if (data[i] != 0xFF){
			return 0;
		}
	}

	return 1;
}

//::custom-filter
int mac_custom_filter(unsigned int data[]){
	char addr[6];

	addr[0] = mac_address[0];
	addr[1] = mac_address[0] >> 8;
	addr[2] = mac_address[0] >> 16;
	addr[3] = mac_address[0] >> 24;
	addr[4] = mac_address[1];
	addr[5] = mac_address[1] >> 8;

	if (is_broadcast((data,char[])) &&
            is_ethertype((data,char[]), ethertype_arp)){
		return 1;
	}else if (is_mac_addr((data,char[]), addr) &&
                  is_ethertype((data,char[]), ethertype_ip)){          
		return 1;
	}

	return 0;
}
//::


int build_arp_response(unsigned char rxbuf[], unsigned int txbuf[], const unsigned char own_mac_addr[6])
{
  unsigned word;
  unsigned char byte;
  const unsigned char own_ip_addr[4] = OWN_IP_ADDRESS;

  for (int i = 0; i < 6; i++)
    {
      byte = rxbuf[22+i];
      (txbuf, unsigned char[])[i] = byte;
      (txbuf, unsigned char[])[32 + i] = byte;
    }
  word = (rxbuf, const unsigned[])[7];
  for (int i = 0; i < 4; i++)
    {
      (txbuf, unsigned char[])[38 + i] = word & 0xFF;
      word >>= 8;
    }

  (txbuf, unsigned char[])[28] = own_ip_addr[0];
  (txbuf, unsigned char[])[29] = own_ip_addr[1];
  (txbuf, unsigned char[])[30] = own_ip_addr[2];
  (txbuf, unsigned char[])[31] = own_ip_addr[3];

  for (int i = 0; i < 6; i++)
  {
    (txbuf, unsigned char[])[22 + i] = own_mac_addr[i];
    (txbuf, unsigned char[])[6 + i] = own_mac_addr[i];
  }
  txbuf[3] = 0x01000608;
  txbuf[4] = 0x04060008;
  (txbuf, unsigned char[])[20] = 0x00;
  (txbuf, unsigned char[])[21] = 0x02;

  // Typically 48 bytes (94 for IPv6)
  for (int i = 42; i < 64; i++)
  {
    (txbuf, unsigned char[])[i] = 0x00;
  }

  return 64;
}


int is_valid_arp_packet(const unsigned char rxbuf[], int nbytes)
{
  static const unsigned char own_ip_addr[4] = OWN_IP_ADDRESS;

  if (rxbuf[12] != 0x08 || rxbuf[13] != 0x06)
    return 0;

  printstr("ARP packet received\n");

  if ((rxbuf, const unsigned[])[3] != 0x01000608)
  {
    printstr("Invalid et_htype\n");
    return 0;
  }
  if ((rxbuf, const unsigned[])[4] != 0x04060008)
  {
    printstr("Invalid ptype_hlen\n");
    return 0;
  }
  if (((rxbuf, const unsigned[])[5] & 0xFFFF) != 0x0100)
  {
    printstr("Not a request\n");
    return 0;
  }
  for (int i = 0; i < 4; i++)
  {
    if (rxbuf[38 + i] != own_ip_addr[i])
    {
      printstr("Not for us\n");
      return 0;
    }
  }

  return 1;
}


int build_icmp_response(unsigned char rxbuf[], unsigned char txbuf[], const unsigned char own_mac_addr[6])
{
  static const unsigned char own_ip_addr[4] = OWN_IP_ADDRESS;
  unsigned icmp_checksum;
  int datalen;
  int totallen;
  const int ttl = 0x40;
  int pad;

  // Precomputed empty IP header checksum (inverted, bytereversed and shifted right)
  unsigned ip_checksum = 0x0185;

  for (int i = 0; i < 6; i++)
    {
      txbuf[i] = rxbuf[6 + i];
    }
  for (int i = 0; i < 4; i++)
    {
      txbuf[30 + i] = rxbuf[26 + i];
    }
  icmp_checksum = byterev((rxbuf, const unsigned[])[9]) >> 16;
  for (int i = 0; i < 4; i++)
    {
      txbuf[38 + i] = rxbuf[38 + i];
    }
  totallen = byterev((rxbuf, const unsigned[])[4]) >> 16;
  datalen = totallen - 28;
  for (int i = 0; i < datalen; i++)
    {
      txbuf[42 + i] = rxbuf[42+i];
    }

  for (int i = 0; i < 6; i++)
  {
    txbuf[6 + i] = own_mac_addr[i];
  }
  (txbuf, unsigned[])[3] = 0x00450008;
  totallen = byterev(28 + datalen) >> 16;
  (txbuf, unsigned[])[4] = totallen;
  ip_checksum += totallen;
  (txbuf, unsigned[])[5] = 0x01000000 | (ttl << 16);
  (txbuf, unsigned[])[6] = 0;
  for (int i = 0; i < 4; i++)
  {
    txbuf[26 + i] = own_ip_addr[i];
  }
  ip_checksum += (own_ip_addr[0] | own_ip_addr[1] << 8);
  ip_checksum += (own_ip_addr[2] | own_ip_addr[3] << 8);
  ip_checksum += txbuf[30] | (txbuf[31] << 8);
  ip_checksum += txbuf[32] | (txbuf[33] << 8);

  txbuf[34] = 0x00;
  txbuf[35] = 0x00;

  icmp_checksum = (icmp_checksum + 0x0800);
  icmp_checksum += icmp_checksum >> 16;
  txbuf[36] = icmp_checksum >> 8;
  txbuf[37] = icmp_checksum & 0xFF;

  while (ip_checksum >> 16)
  {
    ip_checksum = (ip_checksum & 0xFFFF) + (ip_checksum >> 16);
  }
  ip_checksum = byterev(~ip_checksum) >> 16;
  txbuf[24] = ip_checksum >> 8;
  txbuf[25] = ip_checksum & 0xFF;

  for (pad = 42 + datalen; pad < 64; pad++)
  {
    txbuf[pad] = 0x00;
  }
  return pad;
}


int is_valid_icmp_packet(const unsigned char rxbuf[], int nbytes)
{
  static const unsigned char own_ip_addr[4] = OWN_IP_ADDRESS;
  unsigned totallen;


  if (rxbuf[23] != 0x01)
    return 0;

  printstr("ICMP packet received\n");

  if ((rxbuf, const unsigned[])[3] != 0x00450008)
  {
    printstr("Invalid et_ver_hdrl_tos\n");
    return 0;
  }
  if (((rxbuf, const unsigned[])[8] >> 16) != 0x0008)
  {
    printstr("Invalid type_code\n");
    return 0;
  }
  for (int i = 0; i < 4; i++)
  {
    if (rxbuf[30 + i] != own_ip_addr[i])
    {
      printstr("Not for us\n");
      return 0;
    }
  }

  totallen = byterev((rxbuf, const unsigned[])[4]) >> 16;
  if (nbytes > 60 && nbytes != totallen + 14)
  {
    printstr("Invalid size\n");
    printintln(nbytes);
    printintln(totallen+14);
    return 0;
  }
  if (checksum_ip(rxbuf) != 0)
  {
    printstr("Bad checksum\n");
    return 0;
  }

  return 1;
}


void demo(chanend tx, chanend rx)
{
  unsigned char rxbuf[1600];
  unsigned int txbuf[1600];
  
  //::get-macaddr
  mac_get_macaddr(tx, own_mac_addr);
  //::

  //::setup-filter
  mac_set_custom_filter(rx, 0x1);
  //::
  printstr("Test started\n");

  //::mainloop
  while (1)
  {
    unsigned int src_port;
    unsigned int nbytes;
    mac_rx(rx, rxbuf, nbytes, src_port);
    printstr("packet\n");
   //::arp_packet_check
    if (is_valid_arp_packet(rxbuf, nbytes))
      {
        build_arp_response(rxbuf, txbuf, own_mac_addr);
        mac_tx(tx, txbuf, nbytes, ETH_BROADCAST);
        printstr("ARP response sent\n");
      }
  //::icmp_packet_check  
    else if (is_valid_icmp_packet(rxbuf, nbytes))
      {
        build_icmp_response(rxbuf, (txbuf, unsigned char[]), own_mac_addr);
        mac_tx(tx, txbuf, nbytes, ETH_BROADCAST);
        printstr("ICMP response sent\n");
      }
  //::
  }
}

int main()
{
  chan rx[1], tx[1];

  par
    {
      //::ethernet
      on stdcore[2]:
      {
		ethernet_getmac_otp(otp_data, otp_addr, otp_ctrl, (mac_address, char[]));
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
      //::

      //::demo
      on stdcore[0] : demo(tx[0], rx[0]);
      //::
    }

	return 0;
}
