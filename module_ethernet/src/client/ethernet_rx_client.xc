/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    ethernet_rx_client.xc
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
 *
 * This implement Ethernet frame receiving client interface.
 *
 *************************************************************************/
 
#include <xs1.h>
#include "ethernet_server_def.h"
#include "ethernet_rx_client.h"

/** This get *data* from server, in unified manner.
 */
static int ethernet_unified_get_data(chanend ethernet_rx_svr, unsigned char Buf[], unsigned int &rxTime, unsigned int &src_port, unsigned int Cmd)
{
  unsigned int i, j,k, rxByteCnt, transferCnt, rxData, temp;
  // sent command to request data.

  (void) inuchar(ethernet_rx_svr);
  (void) inuchar(ethernet_rx_svr);
  (void) inct(ethernet_rx_svr);

  master {
    ethernet_rx_svr <: Cmd;
  }
  slave {
    // get reply from server.
    ethernet_rx_svr :> src_port;
    ethernet_rx_svr :> rxByteCnt;
   
    // get required bytes.
    transferCnt = (rxByteCnt + 3) >> 2;
    j = 0;
    for (i = 0; i < transferCnt; i++)
      {      
        // get word data.
        ethernet_rx_svr :> rxData;
        // process each byte in word
        for (k = 0; k < 4; k++)
          {
            // only for actual bytes t
            if (j < rxByteCnt)
              {
                temp = (rxData >> (k * 8));
                Buf[j] = temp;
              }
            j += 1;
          }   
      }
    ethernet_rx_svr :> rxTime;
  }
  return (rxByteCnt);
}


/** This get a *complete* ethernet frame from PHY (i.e. src/dest MAC address, type & payload),
 *  excluding Pre-amble, SoF & CRC32.
 *
 *  NOTE:
 *  1. It is blocking call, (i.e. will wait until a complete packet is received).
 *  2. Buf[], must be big enough to store MAX_ETHERNET_FRAME_PAYLOAD_COUNT + 12
 *  3. rxTime is populated with 32bis internal timestamp @ received.
 *  4. Only the packets which pass CRC32 is processed.
 *  5. returns the number of bytes in the frame.
 *
 */
int mac_rx(chanend ethernet_rx_svr, unsigned char Buf[], unsigned int &src_port)
{
  unsigned rxTime;
  int ret;
  (void) inuchar(ethernet_rx_svr);
  ret = ethernet_unified_get_data(ethernet_rx_svr, Buf, rxTime, src_port, ETHERNET_RX_FRAME_REQ);
  return ret;
}

int mac_rx_timed(chanend ethernet_rx_svr, unsigned char Buf[], unsigned int &rxTime, unsigned int &src_port)
{
  int ret;
  (void) inuchar(ethernet_rx_svr);
  ret = ethernet_unified_get_data(ethernet_rx_svr, Buf, rxTime, src_port, ETHERNET_RX_FRAME_REQ);
  return ret;
}

int mac_rx_in_select(chanend ethernet_rx_svr, unsigned char Buf[], unsigned int &src_port)
{
  unsigned rxTime;
  int ret;
  ret = ethernet_unified_get_data(ethernet_rx_svr, Buf, rxTime, src_port, ETHERNET_RX_FRAME_REQ);
  return ret;
}

int mac_rx_timed_in_select(chanend ethernet_rx_svr, unsigned char Buf[], unsigned int &rxTime, unsigned int &src_port)
{
  int ret;
  ret = ethernet_unified_get_data(ethernet_rx_svr, Buf, rxTime, src_port, ETHERNET_RX_FRAME_REQ);
  return ret;
}



/** Setup a given filter index for *this* interface. There are MAX_MAC_FILTERS per client.
 *
 *  \para  ethernet_rx_svr : channelEnd to receive server.
 *  \para  filterIndex     : Must be between 0..NUM_FRAM_FILTERS_PER_CLIENT-1, select which filter.
 *  \para  filter          : refrence to filter data structre.
 *  \return -1 on failure and filterIndex on success.
 */
int mac_set_filter(chanend ethernet_rx_svr, int filterIndex, struct mac_filter_t &filter)
{
  int i, response;
   

  // sanity check.
  if ((filterIndex < 0) || (filterIndex >= MAX_MAC_FILTERS))
    {
      return (-1);
    }
  master {
    // sent out request to transfer filter set.
    ethernet_rx_svr <: ETHERNET_RX_FILTER_SET;
    // filter index
    ethernet_rx_svr <: filterIndex;   
    
    
    // sent filter data.
    for (i = 0; i < sizeof(struct mac_filter_t); i += 1)
      {
        ethernet_rx_svr <: (char) (filter, unsigned char[])[i];      
      }
    // check response
    
    ethernet_rx_svr :> response;
    if (response != ETHERNET_REQ_ACK) 
      {   
        filterIndex = -1; 
      }      
  }
  return (filterIndex);
}


/** Returns the number of *lost* frames between MII and Ethernet layer.
 */
int mac_get_overflowcnt(chanend ethernet_rx_svr)
{
  int result;
  
  master {
    //ethernet_rx_svr <: (unsigned int) ETHERNET_RX_OVERFLOW_CNT_REQ;
    ethernet_rx_svr <: (unsigned int) ETHERNET_RX_OVERFLOW_CNT_REQ;

    ethernet_rx_svr :> result;

    if (result == ETHERNET_REQ_ACK) {
      // get the count
      ethernet_rx_svr :> result;
    } else {
      // NACK or invalid response.
      result = -1;
    }    
  }
  return (result);
}


/** Reset the overflow counter
 */
void mac_reset_overflowcnt(chanend ethernet_rx_svr)
{
  int response;

  master {

    ethernet_rx_svr <: (unsigned int) ETHERNET_RX_OVERFLOW_CLEAR_REQ;	

    ethernet_rx_svr :> response;
  }
  return;
}

void mac_set_drop_packets(chanend mac_svr, int x)
{
  master {
    mac_svr <: (unsigned int) ETHERNET_RX_DROP_PACKETS_SET;
    mac_svr <: x;
    mac_svr :> int _; // acknowledgement
  }
  return;
}

void mac_set_queue_size(chanend mac_svr, int x)
{
  master {
    mac_svr <: (unsigned int) ETHERNET_RX_QUEUE_SIZE_SET;
    mac_svr <: x;
    mac_svr :> int _; // acknowledgement
  }
  return;
}

void mac_set_custom_filter(chanend mac_svr, int x)
{
  master {
    mac_svr <: (unsigned int) ETHERNET_RX_CUSTOM_FILTER_SET;
    mac_svr <: x;
    mac_svr :> int _; // acknowledgement
  }
  return;
}
