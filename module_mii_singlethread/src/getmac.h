// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*************************************************************************
 *
 * Ethernet MAC Layer Implementation
 * IEEE 802.3 Device MAC Address
 *
 *
 *
 * Retreives three bytes of MAC address from OTP.
 *
 *************************************************************************/

#ifndef _getmac_h_
#define _getmac_h_

#ifdef __XC__

struct otp_ports {
  port otp_data;
  out port otp_addr;
  port otp_ctrl;
};


/** Retrieves the requested indexed MAC address stored in the OTP
 *
 *  \param p Structure containing OTP ports
 *  \param macaddr Array to be filled with the retrieved MAC address
 *  \param index The index of the mac address to retreive
 *
 **/
void ethernet_getmac_otp_indexed(struct otp_ports& p, char macaddr[], unsigned index);

/** Retrieves a set of MAC addresses stored in the OTP
 *
 *  \param p Structure containing OTP ports
 *  \param macaddr Array to be filled with the retrieved MAC address
 *  \param count The number of the mac address to retreive
 *
 **/
void ethernet_getmac_otp_count(struct otp_ports& p, int macaddr[][2], unsigned count);

/** Retrieves the first MAC address stored in the OTP
 *
 *  \param p Structure containing OTP ports
 *  \param macaddr Array to be filled with the retrieved MAC address
 *
 **/
void ethernet_getmac_otp(struct otp_ports& p, char macaddr[]);

#endif

#endif
