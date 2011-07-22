/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    ethernet_rx_filter.xc
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
/**************************************************************************
 *
 * Ethernet MAC Layer Implementation
 * IEEE 802.3 LLC Frame Filter
 *
 *
 *
 * Implements Ethernet frame filtering.
 *
 * An Ethernet frame can be filtered either base on *destination* MAC
 * address (6 bytes) or/and VLAN tag and EType field (6 bytes) in the
 * frame. Each filter in turn has individual bit mask and compare, to
 * allow only interested portion of each filter is compared. It is also
 * useful to filter on a range of MAC address.
 *
 * Each *interface* in turn has up to NUM_FRAM_FILTERS_PER_CLIENT
 * filters, ethernet frames which matches any of the filter will be
 * passed on the specified client/interface.
 *
 * A frame may be routed to more than one client/interface base on
 * individual filters.
 *
 *************************************************************************/

#include "ethernet_rx_filter.h" 
#include <print.h>
#include <string.h>


static  int ether_filter(FrameFilterFormat_t pFilter,  unsigned char pBuf[]);


/** This clear all entries inside ethernet frame filter (i.e. filter is NOT active).
 *
 *  \para   pFilter pointer to ethernet frame filter data structure.
 *  \return none.
 */
void ethernet_frame_filter_clear(FrameFilterFormat_t &pFilter)
{  
   pFilter.filterOpcode = FILTER_OPCODE_NULL;
   for (int i=0;i<6;i++) {
     pFilter.dmac_msk[i] = 0;
     pFilter.vlan_msk[i] = 0;
     pFilter.dmac_val[i] = 0;
     pFilter.vlan_val[i] = 0;
   }
}


/** Initialise array of client frame filters.
 */
void ethernet_frame_filter_init(ClientFrameFilter_t &Filter)
{
  for (int i=0;i < MAX_MAC_FILTERS;i++) {
    ethernet_frame_filter_clear(Filter.filters[i]);
  }  
}

/** This perform filtering on a given packet  with given filter set (*pFilter).
 * 
 *  \para    *pFilter pointer to filter to use.
 *  \para    baseAdrs Absolute base address of packet buffer area.
 *  \para    startByteOffset byte offset from buffer for start of packet.
 *  \return  -1 on NO match and 0..n for match.
 */
int  ethernet_frame_filter(ClientFrameFilter_t pFilter, unsigned int mii_rx_buf[])
{
   int i;
   int result = 0;
   // for every filter bank
   for (i = 0; i < MAX_MAC_FILTERS; i++)
   {
      // only filter on the enabled filter.
      if (pFilter.filters[i].opcode != OPCODE_NULL)
      {
         // do filter on each mask/compare
        result = ether_filter( pFilter.filters[i], (mii_rx_buf,char[]));
         // check if we foud a match.
         if (result)
         {
            break;
         }
      }
   }
   
   return (result);
}

/** This perform mask/compare filter on Destination MAC address field and VLAN Tag & EtherType field.
 *
 *  \para   *pFilter filter to use.
 *  \para   *pBuf    start of buffer.
 */
static  int ether_filter(FrameFilterFormat_t pFilter, unsigned char pBuf[])
{
   int i;
   unsigned char DMACResult, VLANETResult, FinalResult;
   
   // Destination MAC address filter.
   DMACResult = 1;
   for (i = 0; i < NUM_BYTES_IN_FRAME_FILTER; i++)
   {
      DMACResult &= (pFilter.dmac_msk[i] & (unsigned char) pBuf[i]) == (pFilter.dmac_msk[i] & pFilter.dmac_val[i]);      
      
   }
   
   //  VLAN Tag and EtherType filter
   VLANETResult = 1;
   for (i = 0; i < NUM_BYTES_IN_FRAME_FILTER; i++)
   {
      VLANETResult &= (pFilter.vlan_msk[i] & pBuf[i + 12]) == (pFilter.vlan_msk[i] & pFilter.vlan_val[i]); 
      
   }

   switch (pFilter.opcode)
   {
      case OPCODE_AND:
        FinalResult = DMACResult && VLANETResult;
        break;
      case OPCODE_OR:
        FinalResult = DMACResult || VLANETResult;
        break;
      default:
        // unknown opcode
        break;
   }
  
   return FinalResult;
}
