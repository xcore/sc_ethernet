// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _ethernet_server_h_
#define _ethernet_server_h_

#include "smi.h"
#include "mii_full.h"
#include "ethernet_conf_derived.h"

#ifdef __XC__

#include "ethernet_server_full.h"
#include "ethernet_server_lite.h"

/** Single MII port MAC/ethernet server.
 *
 *  This function provides both MII layer and MAC layer functionality. 
 *  It runs in 5 threads and communicates to clients over the channel array 
 *  parameters. 
 *
 *  \param mii                  The mii interface resources that the
 *                              server will connect to
 *  \param mac_address          The mac_address the server will use. 
 *                              This should be a two-word array that stores the
 *                              6-byte macaddr in a little endian manner (so
 *                              reinterpreting the array as a char array is as
 *                              one would expect)
 *  \param rx                   An array of chanends to connect to clients of
 *                              the server who wish to receive packets.
 *  \param num_rx               The number of clients connected to the rx array
 *  \param tx                   An array of chanends to connect to clients of
 *                              the server who wish to transmit packets.
 *  \param num_tx               The number of clients connected to the txx array
 *  \param smi                  An optional parameter of resources to connect 
 *                              to a PHY (via SMI) to check when the link is up.
 *
 *  \param connect_status       An optional parameter of a channel that is
 *                              signalled when the link goes up or down
 *                              (requires the smi parameter to be supplied).
 *
 * The clients connected via the rx/tx channels can communicate with the
 * server using the APIs found in ethernet_rx_client.h and ethernet_tx_client.h
 *
 * If the smi and connect_status parameters are supplied then the 
 * connect_status channel will output when the link goes up or down. 
 * The channel will output a zero byte, followed by the status (1 for up,
 * 0 for down), followed by a zero byte, followed by an END control token.,
 *
 * The following code snippet is an example of how to receive this update:
 *
 * \verbatim
 *    (void) inuchar(connect_status);
 *    new_status = inuchar(c);
 *    (void) inuchar(c, 0);
 *    (void) inct(c);
 * \endverbatim
 **/
void ethernet_server(mii_interface_t &mii,
                     char mac_address[],
                     chanend rx[],
                     int num_rx,
                     chanend tx[],
                     int num_tx,
                     smi_interface_t &?smi,
                     chanend ?connect_status);


/** Single MII port MAC/ethernet server ("lite" variant")
 *
 *  This function provides both MII layer and MAC layer functionality. 
 *  It runs in 2 threads and communicates to clients over the channel array
 *  parameters. 
 *
 *  \param mii                  The mii interface resources that the
 *                              server will connect to
 *  \param mac_address          The mac_address the server will use. 
 *                              This should be a two-word array that stores the
 *                              6-byte macaddr in a little endian manner (so
 *                              reinterpreting the array as a char array is as
 *                              one would expect)
 *  \param rx                   The chanend to connect to the client of
 *                              the server who wish to receive packets.
 *  \param tx                   An chanend to connect to the client of
 *                              the server who wish to transmit packets.
 *  \param smi                  An optional parameter of resources to connect 
 *                              to a PHY (via SMI) to check when the link is up.
 *
 *  \param connect_status       An optional parameter of a channel that is
 *                              signalled when the link goes up or down
 *                              (requires the smi parameter to be supplied).
 *
 * The clients connected via the rx/tx channels can communicate with the
 * server using the APIs found in ethernet_rx_client.h and ethernet_tx_client.h
 *
 * If the smi and connect_status parameters are supplied then the 
 * connect_status channel will output when the link goes up or down. 
 * The channel will output a zero byte, followed by the status (1 for up,
 * 0 for down), followed by a zero byte, followed by an END control token.,
 *
 * The following code snippet is an example of how to receive this update:
 *
 * \verbatim
 *    (void) inuchar(connect_status);
 *    new_status = inuchar(c);
 *    (void) inuchar(c, 0);
 *    (void) inct(c);
 * \endverbatim
 **/
void ethernet_server_lite(mii_interface_t &mii,
                          char mac_address[],
                          chanend rx[],
                          int num_rx,
                          chanend tx[],
                          int num_tx,
                          smi_interface_t &?smi,
                          chanend ?connect_status);

#endif


#if !ETHERNET_USE_FULL
#define ethernet_server ethernet_server_lite
#endif

#endif // _ethernet_server_h_
