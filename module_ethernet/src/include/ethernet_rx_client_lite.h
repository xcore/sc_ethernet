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

#ifndef _ETHERNET_RX_CLIENT_LITE_H_
#define _ETHERNET_RX_CLIENT_LITE_H_ 1
#include <xccompat.h>

/** This function receives a complete frame (i.e. src/dest MAC address,
 *  type & payload),  excluding pre-amble, SoF & CRC32 from the ethernet
 *  server.
 *
 *  This function is selectable i.e. it can be used as a case in a select e.g.
 *
 *  \verbatim
 *      select {
 *         ...
 *         case mac_rx(...):
 *            break;
 *          ...
 *        }
 *  \endverbatim
 *
 *  \param c_mac      A chanend connected to the ethernet server
 *  \param buffer     The buffer to fill with the incoming packet
 *  \param src_port   A reference parameter to be filled with the ethernet
 *                   port the packet came from.
 *  \param len        A reference parameter to be filled with the length of
 *                   the received packet in bytes.
 *
 **/
#ifdef __XC__
#pragma select handler
#endif
void mac_rx_lite(chanend c_mac,
                 unsigned char buffer[],
                 REFERENCE_PARAM(unsigned int, len),
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
void safe_mac_rx_lite(chanend c_mac,
                      unsigned char buffer[],
                      REFERENCE_PARAM(unsigned int, len),
                      REFERENCE_PARAM(unsigned int, src_port),
                      int n);


#endif
