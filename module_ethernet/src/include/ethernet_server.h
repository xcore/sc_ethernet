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
 *
 * The clients connected via the rx/tx channels can communicate with the
 * server using the APIs found in ethernet_rx_client.h and ethernet_tx_client.h
 *
 **/
void ethernet_server(mii_interface_t &mii,
                     smi_interface_t &?smi,
                     char mac_address[],
                     chanend rx[],
                     int num_rx,
                     chanend tx[],
                     int num_tx);

#define ethernet_server ADD_SUFFIX(ethernet_server, ETHERNET_DEFAULT_IMPLEMENTATION)

#endif

#endif // _ethernet_server_h_
