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
 * This implement Ethernet frame receiving client interface.
 *
 *************************************************************************/

#include <xs1.h>
#include <xclib.h>
#include "mii_full.h"
#include "ethernet_server_def.h"
#include "ethernet_rx_client.h"
#include "ethernet_conf_derived.h"
#include <print.h>

static inline unsigned int get_tile_id_from_chanend(chanend c) {
  unsigned int ci;
  asm("shr %0, %1, 16":"=r"(ci):"r"(c));
  return ci;
}


/** This function unifies all the variants of mac_rx.
 */
#pragma unsafe arrays
static int ethernet_unified_get_data(chanend ethernet_rx_svr, unsigned char Buf[], unsigned int &rxTime,
                                     unsigned int &src_port, int &user_data, unsigned int Cmd, int n)
{
  unsigned int i, j, k, rxByteCnt, transferCnt, rxData, temp;
  // sent command to request data.

  (void) inct(ethernet_rx_svr);
  outuchar(ethernet_rx_svr, 0);
  outct(ethernet_rx_svr, XS1_CT_END);
  (void) inct(ethernet_rx_svr);
  outuint(ethernet_rx_svr, Cmd);
  outct(ethernet_rx_svr, XS1_CT_END);
  chkct(ethernet_rx_svr, XS1_CT_END);

  master {
    // get reply from server.
    ethernet_rx_svr :> src_port;
    ethernet_rx_svr :> rxByteCnt;
    ethernet_rx_svr :> user_data;

    if (rxByteCnt == STATUS_PACKET_LEN) {
      int status;
      ethernet_rx_svr :> status;
      Buf[0] = status;
    }
    else {
      if (Cmd == ETHERNET_RX_FRAME_REQ_OFFSET2)
        rxByteCnt += 4;

      // get required bytes.
      transferCnt = (rxByteCnt + 3) >> 2;
      j = 0;
      for (i = 0; i < transferCnt; i++)
        {
          // get word data.
        ethernet_rx_svr :> rxData;
          if (Cmd == ETHERNET_RX_FRAME_REQ_OFFSET2)
            rxData = byterev(rxData);
          // process each byte in word
          for (k = 0; k < 4; k++)
            {
              // only for actual bytes t
              if (j < rxByteCnt && j < n)
                {
                  temp = (rxData >> (k * 8));
                  Buf[j] = temp;
                }
              j += 1;
            }
        }
      ethernet_rx_svr :> rxTime;
    }
  }
  return (rxByteCnt);
}

void mac_rx_full(chanend ethernet_rx_svr, unsigned char Buf[],
           unsigned int &len,
           unsigned int &src_port)
{
  unsigned rxTime;
  int user_data;
  len = ethernet_unified_get_data(ethernet_rx_svr, Buf, rxTime, src_port, user_data, ETHERNET_RX_FRAME_REQ, -1);
  return;
}

void mac_rx_offset2(chanend ethernet_rx_svr, unsigned char Buf[], unsigned int &len, int &user_data, unsigned int &src_port)
{
  unsigned rxTime;
  len = ethernet_unified_get_data(ethernet_rx_svr, Buf, rxTime, src_port, user_data, ETHERNET_RX_FRAME_REQ_OFFSET2, -1);
  return;
}

void safe_mac_rx_full(chanend ethernet_rx_svr, unsigned char Buf[], unsigned int &len, unsigned int &src_port, int n)
{
  unsigned rxTime;
  int user_data;
  len = ethernet_unified_get_data(ethernet_rx_svr, Buf, rxTime, src_port, user_data, ETHERNET_RX_FRAME_REQ, n);
  return;
}

void mac_rx_timed(chanend ethernet_rx_svr, unsigned char Buf[], unsigned int &len, unsigned int &rxTime, unsigned int &src_port)
{
  int user_data;
  len = ethernet_unified_get_data(ethernet_rx_svr, Buf, rxTime, src_port, user_data, ETHERNET_RX_FRAME_REQ, -1);
  return;
}

void safe_mac_rx_timed(chanend ethernet_rx_svr, unsigned char Buf[], unsigned int &len, unsigned int &rxTime, unsigned int &src_port, int n)
{
  int user_data;
  len = ethernet_unified_get_data(ethernet_rx_svr, Buf, rxTime, src_port, user_data, ETHERNET_RX_FRAME_REQ, n);
  return;
}

static void send_cmd(chanend c, int cmd)
{
  outuchar(c, 1);
  outct(c, XS1_CT_END);
  chkct(c, XS1_CT_END);
  outuint(c, cmd);
  outct(c, XS1_CT_END);
  chkct(c, XS1_CT_END);
}


void mac_set_drop_packets(chanend mac_svr, int x)
{
  send_cmd(mac_svr, ETHERNET_RX_DROP_PACKETS_SET);
  mac_svr <: x;
  return;
}


void mac_request_status_packets(chanend mac_svr)
{
  send_cmd(mac_svr, ETHERNET_RX_WANTS_STATUS_UPDATES_SET);
  mac_svr <: 1;
  return;
}

void mac_set_queue_size(chanend mac_svr, int x)
{
  send_cmd(mac_svr, ETHERNET_RX_QUEUE_SIZE_SET);
  mac_svr <: x;
  return;
}

void mac_set_custom_filter(chanend mac_svr, int x)
{
  send_cmd(mac_svr, ETHERNET_RX_CUSTOM_FILTER_SET);
  mac_svr <: x;
  return;
}

/** Returns the number of *lost* frames between MII and Ethernet layer.
 */
void mac_get_link_counters(chanend mac_svr, int& dropped)
{
#if ETHERNET_COUNT_PACKETS
  send_cmd(mac_svr, ETHERNET_RX_OVERFLOW_CNT_REQ);
  mac_svr :> dropped;
#endif
}

void mac_get_global_counters(chanend mac_svr,
		                     unsigned& mii_overflow,
		                     unsigned& bad_length,
		                     unsigned& mismatched_address,
		                     unsigned& filtered,
		                     unsigned& bad_crc
                             )
{
#if ETHERNET_COUNT_PACKETS
  send_cmd(mac_svr, ETHERNET_RX_OVERFLOW_MII_CNT_REQ);
  mac_svr :> mii_overflow;
  mac_svr :> bad_length;
  mac_svr :> mismatched_address;
  mac_svr :> filtered;
  mac_svr :> bad_crc;
#endif
}

#if ETHERNET_RX_ENABLE_TIMER_OFFSET_REQ
void mac_get_tile_timer_offset(chanend mac_svr, int& offset)
{
  unsigned server_tile_id;
  int other_tile_now;
  int this_tile_now;
  timer tmr;

  send_cmd(mac_svr, ETHERNET_RX_TILE_TIMER_OFFSET_REQ);
  mac_svr :> server_tile_id;
  mac_svr :> other_tile_now;
  tmr :> this_tile_now;

  if (server_tile_id != get_tile_id_from_chanend(mac_svr))
  {
    offset = other_tile_now-this_tile_now-3; // 3 is an estimate of the channel + instruction latency
  }
  else
  {
    offset = 0;
  }
}
#endif
