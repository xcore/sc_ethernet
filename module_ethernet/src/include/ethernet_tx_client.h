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

#include "ethernet_conf_derived.h"

#include "ethernet_tx_client_lite.h"
#include "ethernet_tx_client_full.h"

/** Sends an ethernet frame. Frame includes dest/src MAC address(s), type
 *  and payload.
 *
 *
 *  \param c_mac     channel end to tx server.
 *  \param buffer[]  byte array containing the ethernet frame. *This must
 *                   be word aligned*
 *  \param nbytes    number of bytes in buffer
 *  \param ifnum     the number of the eth interface to transmit to
 *                   (use ETH_BROADCAST transmits to all ports)
 *
 */
void mac_tx(chanend c_mac, unsigned int buffer[], int nbytes, int ifnum);

#define mac_tx ADD_SUFFIX(mac_tx, ETHERNET_DEFAULT_IMPLEMENTATION)

/** Get the device MAC address.
 *
 *  This function gets the MAC address of the device (the address passed
 *  into the ethernet_server() function.
 *
 *  \param   c_mac chanend end connected to ethernet server
 *  \param   macaddr[] an array of type char where the MAC address is placed
 *                     (in network order).
 *  \return zero on success and non-zero on failure.
 */

int mac_get_macaddr(chanend c_mac, unsigned char macaddr[]);

#define mac_get_macaddr ADD_SUFFIX(mac_get_macaddr, ETHERNET_DEFAULT_IMPLEMENTATION)

#endif
