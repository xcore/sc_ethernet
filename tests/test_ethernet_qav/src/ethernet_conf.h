// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef __ethernet_conf_h__
#define __ethernet_conf_h__


#define PHY_ADDRESS 0x0

#define ETHERNET_TX_HP_QUEUE 1
#define ETHERNET_TRAFFIC_SHAPER 1
#define ETHERNET_RX_HP_QUEUE 1

#define MII_TX_BUFSIZE_HIGH_PRIORITY (4096)
#define MII_RX_BUFSIZE_HIGH_PRIORITY (4096)

#define MAX_ETHERNET_PACKET_SIZE (1518)

#define NUM_MII_RX_BUF 30
#define NUM_MII_TX_BUF 2

#define MAX_ETHERNET_CLIENTS   (4)    




#endif
