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

#ifndef _ETHERNET_TX_CLIENT_LITE_H_
#define _ETHERNET_TX_CLIENT_LITE_H_ 1
#include <xccompat.h>

#define ETH_BROADCAST (-1)

#define ETH_LINK_IS_DOWN  (0)
#define ETH_LINK_IS_UP    (1)

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
void mac_tx_lite(chanend c_mac, unsigned int buffer[], int nbytes, int ifnum);

#define mac_tx mac_tx_lite
#define ethernet_send_frame mac_tx
#define ethernet_send_frame_getTime mac_tx_timed


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

int mac_get_macaddr_lite(chanend c_mac, unsigned char macaddr[]);

#define mac_get_macaddr mac_get_macaddr_lite
#define ethernet_get_my_mac_adrs mac_get_macaddr


#endif
