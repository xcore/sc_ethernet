/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    ethernet_tx_client.h
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2009
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
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
#include <xccompat.h>

#define ETH_BROADCAST (-1)

/** This send a ethernet frame, frame includes Dest/Src MAC address(s), 
 *  type and payload.
 *  c_mac       : channelEnd to tx server.
 *  buffer[]    : Byte buffer of ethernet frame. MUST BE WORD ALIGNED.
 *  nbytes      : number of bytes in buffer.
 * 
 *  NOTE: This function will be blocked until the packet is sent to PHY.
 *
 */
void mac_tx(chanend c_mac, unsigned int buffer[], int nbytes, int ifnum);

#define ethernet_send_frame mac_tx
#define ethernet_send_frame_getTime mac_tx_timed

/** This send a ethernet frame, frame includes Dest/Src MAC address(s), type
 *  and payload.
 *  It's blocking call and return the *actual time* the frame is sent to PHY.
 *  *actual time* : 32bits XCore internal timer.
 *  c_mac         : channelEnd to tx server.
 *  buffer[]      : Byte buffer of ethernet frame. MUST BE WORD ALIGNED.
 *  nbytes	  : number of bytes in buffer.
 *  ifnum         : The number of the eth interface to transmit to 
 *                   (using ETH_BROADCAST transmits to all ports)
 *
 *  NOTE: This function will be blocked until the packet is sent to PHY.
 */
#ifdef __XC__ 
void mac_tx_timed(chanend c_mac, unsigned int buffer[], int nbytes, unsigned int &time, int ifnum);
#else
void mac_tx_timed(chanend c_mac, unsigned int buffer[], int nbytes, unsigned int *time, int ifnum);
#endif

/** This get MAC address of *this*, normally its XMOS assigned id, appended with
 *  24bits per chip, id stores in OTP.
 *
 *  \para   macaddr[] array of char, where MAC address is placed, network order.
 *  \return zero on success and non-zero on failure.
 */

int mac_get_macaddr(chanend c_mac, unsigned char macaddr[]);

#define ethernet_get_my_mac_adrs mac_get_macaddr


/** This function sets the transmit 
 *  bandwidth restriction on a link to the mac server.
 *
 *  \para   bandwitdth - The allowed bandwidth of the link in Mbps
 *
 */
int mac_set_bandwidth(chanend ethernet_tx_svr, unsigned int bandwidth);

#define ethernet_set_bandwidth mac_set_bandwidth

#endif
