// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


#include <xs1.h>
#include <xclib.h>
#include <stdio.h>
#include <print.h>
#include <platform.h>
#include <stdlib.h>
#include "smi.h"
#include "miiClient.h"
#include "miiDriver.h"


on stdcore[1]: mii_interface_t mii =
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

    XS1_PORT_8A,
  };

#ifdef PORT_ETH_RST_N
on stdcore[1]: out port p_mii_resetn = PORT_ETH_RST_N;
on stdcore[1]: smi_interface_t smi = { 0, PORT_ETH_MDIO, PORT_ETH_MDC };
#else
on stdcore[1]: smi_interface_t smi = { 0, PORT_ETH_MDIO, PORT_ETH_MDC };
#endif

on stdcore[1]: clock clk_smi = XS1_CLKBLK_5;

//***** Ethernet Configuration ****

//on stdcore[2]: clock clk_mii_ref = XS1_CLKBLK_REF;



// NOTE: YOU MAY NEED TO REDEFINE THIS TO AN IP ADDRESS THAT WORKS
// FOR YOUR NETWORK
#define OWN_IP_ADDRESS { 169, 254, 93,  198}

#define ARP_RESPONSE 1
#define ICMP_RESPONSE 2
#define UDP_RESPONSE 3

void demo(chanend tx, chanend rx);

int build_arp_response(unsigned char rxbuf[], int txbuf[], const unsigned char own_mac_addr[6])
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


int is_valid_arp_packet(const unsigned char rxbuf[], int nbytes) {
    static const unsigned char own_ip_addr[4] = OWN_IP_ADDRESS;
    
    if (rxbuf[12] != 0x08 || rxbuf[13] != 0x06) {
//      printf("%02x %02x\n", rxbuf[12], rxbuf[13]);
        return 0;
    }
    
    if ((rxbuf, const unsigned[])[3] != 0x01000608) {
        printstr("Invalid et_htype\n");
        return 0;
    }
    if ((rxbuf, const unsigned[])[4] != 0x04060008) {
        printstr("Invalid ptype_hlen\n");
        return 0;
    }
    if (((rxbuf, const unsigned[])[5] & 0xFFFF) != 0x0100) {
        printstr("Not a request\n");
        return 0;
    }
    for (int i = 0; i < 4; i++) {
        if (rxbuf[38 + i] != own_ip_addr[i]) {
//        printf("Not for us: %d.%d.%d.%d\n", rxbuf[38], rxbuf[39], rxbuf[40], rxbuf[41]);
            return 0;
        }
    }
 //   printstr("ARP packet received\n");
    
    return 1;
}

#pragma unsafe arrays
int build_icmp_response(unsigned char rxbuf[], unsigned char txbuf[], const unsigned char own_mac_addr[6]) {
    static const unsigned char own_ip_addr[4] = OWN_IP_ADDRESS;
    unsigned icmp_checksum;
    int datalen;
    int totallen;
    const int ttl = 0x40;
    int pad;
    
    // Precomputed empty IP header checksum (inverted, bytereversed and shifted right)
    unsigned ip_checksum = 0x0185;
    
    for (int i = 0; i < 6; i++) {
        txbuf[i] = rxbuf[6 + i];
    }
    for (int i = 0; i < 4; i++) {
        txbuf[30 + i] = rxbuf[26 + i];
    }
    icmp_checksum = byterev((rxbuf, const unsigned[])[9]) >> 16;
    for (int i = 0; i < 4; i++) {
        txbuf[38 + i] = rxbuf[38 + i];
    }
    totallen = byterev((rxbuf, const unsigned[])[4]) >> 16;
    datalen = totallen - 28;
    for (int i = 0; i < datalen; i++) {
        txbuf[42 + i] = rxbuf[42+i];
    }  
    
    for (int i = 0; i < 6; i++) {
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
    
    while (ip_checksum >> 16) {
        ip_checksum = (ip_checksum & 0xFFFF) + (ip_checksum >> 16);
    }
    ip_checksum = byterev(~ip_checksum) >> 16;
    txbuf[24] = ip_checksum >> 8;
    txbuf[25] = ip_checksum & 0xFF;
    
    for (pad = 42 + datalen; pad < 64; pad++) {
        txbuf[pad] = 0x00;
    }
    return pad;
}

int ledStatus = 8;
on stdcore[1]: out port led = XS1_PORT_4A;

int is_valid_icmp_packet(const unsigned char rxbuf[], int nbytes)
{
  static const unsigned char own_ip_addr[4] = OWN_IP_ADDRESS;
  unsigned totallen;


  if (rxbuf[23] != 0x01)
    return 0;

//  printstr("ICMP packet received\n");

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
/*  if (checksum_ip(rxbuf) != 0)
  {
    printstr("Bad checksum\n");
    return 0;
  }*/

  led <: ledStatus; ledStatus ^= 2;

  return 1;
}

void handlePacket(chanend cOut, int a, int nBytes) {
    unsigned char own_mac_addr[6] = {0,0,12,13,14,15};
    int txbuf[400];
    unsigned char rxbuf[1600];
    led <: ledStatus; ledStatus ^= 1;
    for(int i = 0; i <= nBytes>>2; i++) {
        int v;
        asm("ldw %0, %1[%2]" : "=r" (v) : "r" (a), "r" (i));
        (rxbuf, int[])[i] = v;
    }
    if (is_valid_arp_packet(rxbuf, nBytes)) {
        nBytes = build_arp_response(rxbuf, txbuf, own_mac_addr);
        miiOutPacket(cOut, txbuf, 0, nBytes);
        miiOutPacketDone(cOut);
    } else if (is_valid_icmp_packet(rxbuf, nBytes)) {
        nBytes = build_icmp_response(rxbuf, (txbuf, unsigned char[]), own_mac_addr);
        miiOutPacket(cOut, txbuf, 0, nBytes);
        miiOutPacketDone(cOut);
    } else {
        //printf("Received %d bytes %x\n", nBytes, (rxbuf, int[])[0]);
    }
}

void pingDemo(chanend cIn, chanend cOut, chanend cNotifications) {
    int b[3200];
    struct miiData miiData;
    
    printstr("Test started\n");
    miiBufferInit(miiData, cIn, cNotifications, b, 3200);
    printstr("IN Inited\n");
    miiOutInit(cOut);
    printstr("OUT inited\n");
    
    while (1) {
        int nBytes, a, timeStamp;
        miiNotified(miiData, cNotifications);
        while(1) {
            {a,nBytes,timeStamp} = miiGetInBuffer(miiData);

            if (a == 0) {
                break;
            }
            handlePacket(cOut, a, nBytes);
            miiFreeInBuffer(miiData, a);
        }
        miiRestartBuffer(miiData);
    } 
}

unsigned char packet[] = {
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,  0x80, 0x00, 0, 0,
    0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,
    0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,
    0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,   0, 0, 0, 0,
    0, 0, 0, 0,   0, 0, 0, 0
};

    extern int nextBuffer;

void x() {
    set_thread_fast_mode_on();
}

void burn() {
    x();
    while(1);
}


void packetResponse(void) {
    chan cIn, cOut;
    chan notifications;
    par {
        {
        	miiInitialise(null, mii);
            smi_port_init(clk_smi, smi);
            eth_phy_config(1, smi);
        	miiDriver(mii, cIn, cOut);
        }
        {x(); pingDemo(cIn, cOut, notifications);}
        {burn();}
        {burn();}
        {burn();}
        {burn();}
        {burn();}
        {burn();}
    }
}














int main() {
    par {
        on stdcore[1]: {packetResponse();}
    }
	return 0;
}
