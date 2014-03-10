// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*************************************************************************
 *
 * Ethernet MAC Layer Implementation
 * IEEE 802.3 MAC Client Interface (Send)
 *
 *
 * This implement Ethernet frame sending client interface.
 *
 *************************************************************************/

#include <xs1.h>
#include <xclib.h>

#include "ethernet_conf_derived.h"
#include "ethernet_server_def.h"

#include "ethernet_tx_client_full.h"
#include "print.h"


#pragma select handler
void mac_check_link_client(chanend c, unsigned char &linkNum, int &status)
{
  inuchar_byref(c, linkNum);

  status = inuchar(c);
  (void) inuchar(c);
  (void) inct(c);
}

#if ETHERNET_TX_HP_QUEUE
static inline unsigned int ethernet_choose_hp_cmd(unsigned short etype, unsigned int Cmd)
{
  if (etype == 0x0081) {
    switch (Cmd)
    {
      case ETHERNET_TX_REQ:
        return ETHERNET_TX_REQ_HP;
      case ETHERNET_TX_REQ_TIMED:
        return ETHERNET_TX_REQ_TIMED_HP;
      case ETHERNET_TX_REQ_OFFSET2:
        return ETHERNET_TX_REQ_OFFSET2_HP;
      default:
        return Cmd;
    }
  }
  return Cmd;
}
#endif

#pragma unsafe arrays
static void ethernet_send_frame_unify(chanend ethernet_tx_svr, unsigned int Buf[], int count, unsigned int &sentTime, unsigned int Cmd, int ifnum)
{
  int i;
#if ETHERNET_TX_HP_QUEUE
  Cmd = ethernet_choose_hp_cmd(Buf[3], Cmd);
#endif
  ethernet_tx_svr <: Cmd;

  slave {
    ethernet_tx_svr <: count;
    ethernet_tx_svr <: ifnum;
    for (i=0;i<(count+3)>>2;i++)
      ethernet_tx_svr <: Buf[i];
  }

  sentTime = 0;
  if (Cmd == ETHERNET_TX_REQ_TIMED || Cmd == ETHERNET_TX_REQ_TIMED_HP) {
    ethernet_tx_svr :> sentTime;
  }

  return;
}


void mac_tx_full(chanend ethernet_tx_svr, unsigned int Buf[], int count, int ifnum)
{
  unsigned sentTime;
  ethernet_send_frame_unify(ethernet_tx_svr, Buf, count, sentTime, ETHERNET_TX_REQ, ifnum);
  return;
}

#pragma unsafe arrays
void mac_tx_offset2(chanend ethernet_tx_svr,
                    unsigned int Buf[],
                    int count,
                    int ifnum)
{
  unsigned int Cmd = ETHERNET_TX_REQ_OFFSET2;

#if ETHERNET_TX_HP_QUEUE
  Cmd = ethernet_choose_hp_cmd(Buf[3]>>16, Cmd);
#endif
  ethernet_tx_svr <: Cmd;

  slave {
    ethernet_tx_svr <: count;
    ethernet_tx_svr <: ifnum;
    for (int i=0;i<(count+7)>>2;i++)
      ethernet_tx_svr <: byterev(Buf[i]);
  }
  return;
}


void mac_tx_timed(chanend ethernet_tx_svr, unsigned int Buf[], int count, unsigned int &sentTime, int ifnum)
{
  ethernet_send_frame_unify(ethernet_tx_svr, Buf, count, sentTime, ETHERNET_TX_REQ_TIMED, ifnum);
  return;
}


int mac_get_macaddr_full(chanend ethernet_tx_svr, unsigned char Buf[6])
{
  unsigned int i;
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


#ifdef AVB_MAC

void mac_1722_router_enable_forwarding(chanend c, int key0, int key1) {
  c <: ETHERNET_TX_UPDATE_AVB_FORWARDING;
  slave {
    c <: key0;
    c <: key1;
    c <: ETHERNET_AVB_ENABLE_FORWARDING;
  }
}

void mac_1722_router_disable_forwarding(chanend c, int key0, int key1) {
  c <: ETHERNET_TX_UPDATE_AVB_FORWARDING;
  slave {
    c <: key0;
    c <: key1;
    c <: ETHERNET_AVB_DISABLE_FORWARDING;
  }
}

void mac_1722_update_router(chanend c,
                            int remove_entry,
                            int key0,
                            int key1,
                            int link,
                            int hash) {
  c <: ETHERNET_TX_UPDATE_AVB_ROUTER;
  slave {
    c <: remove_entry;
    c <: key0;
    c <: key1;
    c <: link;
    c <: hash;
  }
}

void mac_initialize_routing_table(chanend c)
{
	c <: ETHERNET_TX_INIT_AVB_ROUTER;
}

#endif

int mac_calc_idle_slope(int bps);

void mac_set_qav_bandwidth(chanend c,
                           int port_num,
                           int bps)
{
#if (ETHERNET_TX_HP_QUEUE) && (ETHERNET_TRAFFIC_SHAPER)
  int slope = mac_calc_idle_slope(bps);
  c <: ETHERNET_TX_SET_QAV_IDLE_SLOPE;
  slave {
    c <: port_num;
    c <: slope;
  }
#endif
}
