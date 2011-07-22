/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    ethernet_rx_client.h
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
 * IEEE 802.3 MAC Client Interface (Receive)
 *
 *
 *************************************************************************
 *
 * This implement Ethernet frame receiving client interface.
 *
 *************************************************************************/
 
#ifndef _ETHERNET_RX_CLIENT_H_
#define _ETHERNET_RX_CLIENT_H_ 1
#include <xccompat.h>

/** Received an ethernet frame.
 *
 *  This function receives a complete frame (i.e. src/dest MAC address,
 *  type & payload),  excluding pre-amble, SoF & CRC32.
 *
 *  NOTES:
 *  1. It is blocking call, (i.e. it will wait until a complete packet is 
 *     received).
 *  2. Time is populated with 32bits internal timestamp @ received.
 *  3. Only the packets whih pass CRC32 are processed.
 *  4. Returns the number of bytes in the frame.
 *  5. The src_port return parameter returns the number of the port 
 *     the packet arrived on (if using multiple ports)
 */
int mac_rx(chanend c_mac, 
           unsigned char buffer[], 
           REFERENCE_PARAM(unsigned int, src_port));
int mac_rx_timed(chanend c_mac, 
                 unsigned char buffer[], 
                 REFERENCE_PARAM(unsigned int, time),
                 REFERENCE_PARAM(unsigned int, src_port));



/** Receive a packet within a select.
 *  
 *  This function acts as mac_rx. However, it is expected that 
 *  a select of a char (using the inuchar builtin) has been
 *  done e.g.
 * 
 *   { unsigned char tmp;
 *     select 
 *       {
 *       case inuchar_byref(c_mac, tmp):
 *         mac_rx_in_select(c_mac, buffer, src_port);
 *         ...
 *         break;
 *       ...
 *       }  
 *
 * To do this on xs1b architecture requires the -fsubword-select
 * option to be passed to the compiler.
 */
int mac_rx_in_select(chanend c_mac, 
                     unsigned char buffer[], 
                     REFERENCE_PARAM(unsigned int, src_port));
int mac_rx_timed_in_select(chanend c_mac, 
                           unsigned char buffer[], 
                           REFERENCE_PARAM(unsigned int, time),
                           REFERENCE_PARAM(unsigned int, src_port));


/*****************************************************************************
 *
 * MAC address filtering.
 *
 *****************************************************************************/

// Filter operation identifier.
#define OPCODE_NULL 0x0          // disabled.
#define OPCODE_AND  0x80000080   // Logical AND between DMAC & VLANET filter
#define OPCODE_OR   0x80000081   // Logical OR between DMAC & VLANET filter

#define FILTER_OPCODE_NULL OPCODE_NULL
#define FILTER_OPCODE_AND  OPCODE_AND
#define FILTER_OPCODE_OR   OPCODE_OR

// specify number of frame filters per interface.
#define MAX_MAC_FILTERS   4

// Frame filter
struct mac_filter_t {
   unsigned int  opcode;
   // Destination MAC address filter.
   unsigned char dmac_msk[6];
   unsigned char dmac_val[6];   
   // VLAN and EType filter.
   unsigned char vlan_msk[6];
   unsigned char vlan_val[6];   
};

#define filterOpcode opcode
#define DMAC_filterMask dmac_msk
#define DMAC_filterCompare dmac_val
#define VLANET_filterMask vlan_msk
#define VLANET_filterCompare vlan_val

/** Setup a given filter index for *this* interface. There are
 *  MAX_MAC_FILTERS per client.
 *
 *  \para  c_mac           : channelEnd to ethernet server.
 *  \para  index           : Must be between 0..MAX_MAC_FILTERS-1,
 *                           select which filter.
 *  \para  filter          : reference to filter data structre.
 *  \return -1 on failure and filterIndex on success.
 */
#ifdef __XC__
int mac_set_filter(chanend c_mac, int index, struct mac_filter_t &filter);
#else
int mac_set_filter(chanend c_mac, int index, struct mac_filter_t *filter);
#endif


#define ethernet_rx_frame_filter_set mac_set_filter
/** Setup whether a link should drop packets or block if the link is not ready
 *
 *  \para mac_svr          : chanend of receive server.
 *  \para x                : boolean value as to whether packets should 
 *                           be dropped at mac layer.
 * 
 *  NOTE: setting no dropped packets does not mean no packets will be 
 *  dropped. If packets are not dropped at the mac layer, it will block the
 *  mii fifo. The Mii fifo could possibly overflow and frames for other 
 *  links could be dropped.
 */
void mac_set_drop_packets(chanend mac_svr, int x);

#define ethernet_rx_set_drop_packets mac_set_drop_packets


/** Setup the size of the buffer queue within the mac attached to this link.
 *  \param mac_svr          : chanend connected to the mac
 *  \param x                : the required size of the queue
 */
void mac_set_queue_size(chanend mac_svr, int x);
#define ethernet_rx_set_queue_size mac_set_queue_size


/** Setup the custom filter up on a link.
 *
 *  \para mac_srv          : chanend of receive server.
 *  \para x                : filter value
 * 
 *  For each packet, the filter value is &-ed against the result of 
 *  the mac_custom_filter function. If the result is non-zero
 *  then the packet is transmitted down the link.
 */
void mac_set_custom_filter(chanend mac_svr, int x);

#define ethernet_rx_set_custom_filter mac_set_custom_filter

#endif
