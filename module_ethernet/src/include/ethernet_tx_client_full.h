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

#ifndef _ETHERNET_TX_CLIENT_FULL_H_
#define _ETHERNET_TX_CLIENT_FULL_H_ 1
#include <xccompat.h>

#define ETH_BROADCAST (-1)

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
void mac_tx_full(chanend c_mac, unsigned int buffer[], int nbytes, int ifnum);


/** Sends an ethernet frame. Frame includes dest/src MAC address(s), type
 *  and payload.
 *
 *  The packet should start at offset 2 in the buffer.  This allows the packet
 *  to be constructed with alignment on a different boundary, allowing for
 *  more efficient construction where many word values are not naturally aligned
 *  on word boundaries.
 *
 *  \param c_mac     channel end to tx server.
 *  \param buffer[]  byte array containing the ethernet frame. *This must
 *                   be word aligned*
 *  \param nbytes    number of bytes in buffer
 *  \param ifnum     the number of the eth interface to transmit to
 *                   (use ETH_BROADCAST transmits to all ports)
 *
 */
void mac_tx_offset2(chanend c_mac, unsigned int buffer[], int nbytes, int ifnum);

#define ethernet_send_frame_offset2 mac_tx_offset2

/** Sends an ethernet frame and gets the timestamp of the send.
 *  Frame includes dest/src MAC address(s), type
 *  and payload.
 *
 *  This is a blocking call and returns the *actual time* the frame
 *  is sent to PHY according to the XCore 100Mhz 32-bit timer on the core
 *  the ethernet server is running.
 *
 *  \param c_mac     channel end connected to ethernet server.
 *  \param buffer[]  byte array containing the ethernet frame. *This must
 *                   be word aligned*
 *  \param nbytes    number of bytes in buffer
 *  \param ifnum     the number of the eth interface to transmit to
 *                   (use ETH_BROADCAST transmits to all ports)
 *  \param time      A reference paramater that is set to the time the
 *                   packet is sent to the phy
 *
 *  NOTE: This function will block until the packet is sent to PHY.
 */
#ifdef __XC__
void mac_tx_timed(chanend c_mac, unsigned int buffer[], int nbytes, unsigned int &time, int ifnum);
#else
void mac_tx_timed(chanend c_mac, unsigned int buffer[], int nbytes, unsigned int *time, int ifnum);
#endif

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

int mac_get_macaddr_full(chanend c_mac, unsigned char macaddr[6]);

/**
 * Initialise the ethernet routing table.
 *
 * This is used by AVB to pass routing information into the ethernet
 * filtering component.
 */
void mac_initialize_routing_table(chanend c);

void mac_1722_router_enable_forwarding(chanend c, int key0, int key1);

void mac_1722_router_disable_forwarding(chanend c, int key0, int key1);

void mac_1722_update_router(chanend c, int remove_entry, int key0, int key1, int link, int hash);

/** This function sets the transmit
 *  bandwidth restriction for Q-tagged traffic out of the mac.
 *  It covers all Q-tagged traffic out of the mac (not just
 *  traffic sent from this client) and sets the
 *  output in bits per second. This value includes the ethernet header
 *  but not the CRC, interframe gap or pre-amble.
 *
 *  The restriction is implemented by a traffic shaper using the credit
 *  based shaper algorithm specified in 802.1Qav.
 *
 *  \param   c_mac chanend connected to ethernet server
 *  \param   bits_per_seconds The allowed bandwidth in bits per second
 *
 */
void mac_set_qav_bandwidth(chanend c_mac,
                           int port_num,
                           int bits_per_second);


#ifdef __XC__
/* Select handler to check if the Ethernet link is up or down */
#pragma select handler
void mac_check_link_client(chanend c, unsigned char &linkNum, int &status);
#endif

#endif
