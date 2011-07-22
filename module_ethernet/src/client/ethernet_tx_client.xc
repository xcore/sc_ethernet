/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    ethernet_tx_client.xc
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

#include <xs1.h>
#include "ethernet_server_def.h"
#include "ethernet_tx_client.h"

/** This send a ethernet frame, frame includes Dest/Src MAC address(s), 
 *  type and payload.
 *  ethernet_tx_svr 	: channelEnd to tx server.
 *  Buf[]	        : Byte buffer of ethernet frame.
 *  count		: number of bytes in buffer.
 * 
 *  This is the combine *frame send* which is invoke by differnt interfaces.
 */
static void ethernet_send_frame_unify(chanend ethernet_tx_svr, unsigned int Buf[], int count, unsigned int &sentTime, unsigned int Cmd, int ifnum)
{
  int i;
  
  sentTime = 0;

  ethernet_tx_svr <: Cmd;

  // sent the request/count to sent
  
  slave {
    ethernet_tx_svr <: count;
    ethernet_tx_svr <: ifnum;
    for (i=0;i<(count+3)>>2;i++)
      ethernet_tx_svr <: Buf[i];
  }
    

  if (Cmd == ETHERNET_TX_REQ_TIMED) {
    ethernet_tx_svr :> sentTime;
  }
  
  return; 
}


/** This send a ethernet frame, frame includes Dest/Src MAC address(s), 
 *  type and payload.
 *  ethernet_tx_svr 	: channelEnd to tx server.
 *  Buf[]		: Byte buffer of ethernet frame.
 *  count		: number of bytes in buffer.
 * 
 */
void mac_tx(chanend ethernet_tx_svr, unsigned int Buf[], int count, int ifnum)
{
  unsigned sentTime;
  ethernet_send_frame_unify(ethernet_tx_svr, Buf, count, sentTime, ETHERNET_TX_REQ, ifnum);
  return;
}



/** This send a ethernet frame, frame includes Dest/Src MAC address(s),
 *  type and payload.
 *  It's blocking call and return the *actual time* the frame is sent to PHY.
 *  *actual time* : 32bits XCore internal timer.
 *  ethernet_tx_svr 	: channelEnd to tx server.
 *  Buf[]	        : Byte buffer of ethernet frame.
 *  count               : number of bytes in buffer.
 *
 *  NOTE: This function will be blocked until the packet is sent to PHY.
 */
void mac_tx_timed(chanend ethernet_tx_svr, unsigned int Buf[], int count, unsigned int &sentTime, int ifnum)
{
  ethernet_send_frame_unify(ethernet_tx_svr, Buf, count, sentTime, ETHERNET_TX_REQ_TIMED, ifnum);
  return;
}


/** This get MAC address of *this*, normally its XMOS assigned id, appended with
 *  24bits per chip, id stores in OTP.
 *
 *  \para   Buf[] array of char, where MAC address is placed, network order.
 *  \return zero on success and non-zero on failure.
 */
int mac_get_macaddr(chanend ethernet_tx_svr, unsigned char Buf[])
{
  int i;

    
  ethernet_tx_svr <: ETHERNET_GET_MAC_ADRS;
   
  master {
    // transfer start of data.
    for (i = 0; i < 6; i++)
      {
         ethernet_tx_svr :> Buf[i];
      }
  }

  return 0;   
}

