// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*************************************************************************
 *
 * Ethernet MAC Layer Implementation
 * IEEE 802.3 MAC Client Interface (Send)
 *
 *
 *
 * This implement Ethernet frame sending client interface.
 *
 *************************************************************************/

#ifndef _ETHERNET_TX_CLIENT_H_
#define _ETHERNET_TX_CLIENT_H_ 1

#include "ethernet_derived_conf.h"

#ifdef ETHERNET_USE_FULL
#include "ethernet_tx_client_full.h"
#else
#include "ethernet_tx_client_lite.h"
#endif

#endif
