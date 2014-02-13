// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

 /*************************************************************************
 *
 * Ethernet MAC Layer Implementation
 * IEEE 802.3 MAC Client Interface (Receive)
 *
 *
 *************************************************************************
 *
 * This implement Ethernet frame receiving client interface.
 *
 *************************************************************************/

#ifndef _ETHERNET_RX_CLIENT_FULL_H_
#define _ETHERNET_RX_CLIENT_FULL_H_ 1
#include <xccompat.h>


#ifdef __XC__
#pragma select handler
#endif
void mac_rx_full(chanend c_mac,
                 unsigned char buffer[],
                 REFERENCE_PARAM(unsigned int, len),
                 REFERENCE_PARAM(unsigned int, src_port));


#ifdef __XC__
#pragma select handler
#endif
void safe_mac_rx_full(chanend c_mac,
                      unsigned char buffer[],
                      REFERENCE_PARAM(unsigned int, len),
                      REFERENCE_PARAM(unsigned int, src_port),
                      int n);


/** This function receives a complete frame (i.e. src/dest MAC address,
 *  type & payload),  excluding pre-amble, SoF & CRC32. It also timestamps
 *  the arrival of the frame.
 *
 *  This function is selectable.
 *
 *  \param c_mac      A chanend connected to the ethernet server
 *  \param buffer     The buffer to fill with the incoming packet
 *  \param time       A reference parameter to be filled with the timestamp of
 *                   the packet
 *  \param len        A reference parameter to be filled with the length of
 *                   the received packet in bytes.
 *  \param src_port   A reference parameter to be filled with the ethernet
 *                   port the packet came from.
 *
 **/
#ifdef __XC__
#pragma select handler
#endif
void mac_rx_timed(chanend c_mac,
                  unsigned char buffer[],
                  REFERENCE_PARAM(unsigned int, len),
                  REFERENCE_PARAM(unsigned int, time),
                  REFERENCE_PARAM(unsigned int, src_port));


/** This function receives a complete frame (i.e. src/dest MAC address,
 *  type & payload),  excluding pre-amble, SoF & CRC32 from the ethernet
 *  server. In addition it will only fill the given buffer up to a specified
 *  length.
 *
 *  This function is selectable i.e. it can be used as a case in a select.
 *
 *  \param c_mac      A chanend connected to the ethernet server
 *  \param buffer     The buffer to fill with the incoming packet
 *  \param src_port   A reference parameter to be filled with the ethernet
 *                   port the packet came from.
 *  \param len        A reference parameter to be filled with the length of
 *                   the received packet in bytes.
 *  \param n          The maximum number of bytes to fill the supplied buffer
 *                   with.
 *
 **/
#ifdef __XC__
#pragma select handler
#endif
void safe_mac_rx_timed(chanend c_mac,
                       unsigned char buffer[],
                       REFERENCE_PARAM(unsigned int, len),
                       REFERENCE_PARAM(unsigned int, time),
                       REFERENCE_PARAM(unsigned int, src_port),
                       int n);

/** Setup whether a link should drop packets or block if the link is not ready
 *
 *  \param c_mac_svr          chanend of receive server.
 *  \param x                boolean value as to whether packets should
 *                          be dropped at mac layer.
 *
 *  NOTE: setting no dropped packets does not mean no packets will be
 *  dropped. If packets are not dropped at the mac layer, it will block the
 *  mii fifo. The Mii fifo could possibly overflow and frames for other
 *  links could be dropped.
 **/
void mac_set_drop_packets(chanend c_mac_svr, int x);


/** Setup the size of the buffer queue within the mac attached to this link.
 *  \param c_mac_svr  chanend connected to the mac
 *  \param x        the required size of the queue
 **/
void mac_set_queue_size(chanend c_mac_svr, int x);

/** Setup the custom filter up on a link.
 *
 *  \param c_mac_svr   chanend of receive server.
 *  \param x         filter value
 *
 *  For each packet, the filter value is &-ed against the result of
 *  the mac_custom_filter function. If the result is non-zero
 *  then the packet is transmitted down the link.
 **/
void mac_set_custom_filter(chanend c_mac_svr, int x);

/** Read counts of packets processed by the links
 *
 *  \param mac_svr   chanend of receive server.
 *  \param overflow  the count of the number dropped due to link fifo overflow
 */
void mac_get_link_counters(chanend mac_svr, REFERENCE_PARAM(int,overflow));

/** Read global counters
 *
 *  \param mac_svr              chanend of receive server.
 *  \param mii_overflow         MII rx couldn't allocate space in both the LP and HP fifos
 *  \param bad_length           The length of the received packet was out of the valid range
 *  \param mismatched_address   The packet was not addressed to this Mac
 *  \param filtered             The user filter function returned zero
 */
void mac_get_global_counters(chanend mac_svr,
		                     REFERENCE_PARAM(unsigned,mii_overflow),
		                     REFERENCE_PARAM(unsigned,bad_length),
		                     REFERENCE_PARAM(unsigned,mismatched_address),
		                     REFERENCE_PARAM(unsigned,filtered),
		                     REFERENCE_PARAM(unsigned,bad_crc)
		                     );

/** Get the timer offset between the Ethernet server and client.
 *  Returns 0 if the client is on the same tile.
 *
 *  \param mac_svr              chanend of receive server.
 *  \param offset               The offset in timer ticks
 */
void mac_get_tile_timer_offset(chanend mac_svr, REFERENCE_PARAM(int, offset));

/** Receive a packet starting at the second byte of a buffer
 *
 *  This is useful when the contents of the packet should be aligned on
 *  a different boundary.
 *
 *  \param c_mac   chanend of receive server.
 *  \param buffer  The buffer to fill with the incoming packet
 *  \param len        A reference parameter to be filled with the length of
 *                   the received packet in bytes.
 *  \param src_port   A reference parameter to be filled with the ethernet
 *                   port the packet came from.
 *
 */
#ifdef __XC__
#pragma select handler
#endif
void mac_rx_offset2(chanend c_mac,
                    unsigned char buffer[],
                    REFERENCE_PARAM(unsigned int, len),
                    REFERENCE_PARAM(int, user_data),
                    REFERENCE_PARAM(unsigned int, src_port));


#endif

void mac_request_status_packets(chanend c_mac);
