// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "smi.h"
#include "mii_full.h"
#include "mii_queue.h"
#include "ethernet_server_def.h"
#include "ethernet_link_status.h"
#include "mii_malloc.h"
#include <xs1.h>
#include <xclib.h>

#ifdef AVB_MAC
#include "avb_1722_router_table.h"
#endif

#ifndef ETHERNET_TX_PHY_TIMER_OFFSET
#define ETHERNET_TX_PHY_TIMER_OFFSET 5
#endif

#define MAX_LINKS 10

#define LINK_POLL_PERIOD 10000000

#if (ETHERNET_TX_HP_QUEUE) && (ETHERNET_TRAFFIC_SHAPER)
  extern int g_mii_idle_slope[];
#endif


static void do_link_check(smi_interface_t &smi, int linkNum)
{
  int new_status = smi_check_link_state(smi);
  ethernet_update_link_status(linkNum, new_status);
}

static transaction get_packet_from_client(chanend tx,
                                          int cmd,
                                          int &length,
                                          int &dst_port,
                                          unsigned dptr[NUM_ETHERNET_PORTS],
                                          unsigned wrap_ptr[NUM_ETHERNET_PORTS])
{
  tx :> length;
  tx :> dst_port;
  if (cmd == ETHERNET_TX_REQ_OFFSET2) {
    tx :> char;
    tx :> char;
    for(int j=0;j<(length+3)>>2;j++) {
      int datum;
      tx :> datum;
      for (unsigned p=0; p<NUM_ETHERNET_PORTS; ++p) {
        mii_packet_set_data_word_imm(dptr[p], 0, byterev(datum));
        dptr[p] += 4;
        if (dptr[p] == wrap_ptr[p])
          asm("ldw %0,%0[0]":"=r"(dptr[p]));
      }
    }
    tx :> char;
    tx :> char;

    cmd = ETHERNET_TX_REQ;
  } else {
    for(int j=0;j<(length+3)>>2;j++) {
      int datum;
      tx :> datum;
      for (unsigned p=0; p<NUM_ETHERNET_PORTS; ++p) {
        mii_packet_set_data_word_imm(dptr[p], 0, datum);
        dptr[p] += 4;
        if (dptr[p] == wrap_ptr[p])
          asm("ldw %0,%0[0]":"=r"(dptr[p]));
      }
    }
  }
}

#ifdef AVB_MAC
static transaction get_and_update_avb_router(chanend tx) {
  int key0, key1, link, hash, remove_entry;
  tx :> remove_entry;
  tx :> key0;
  tx :> key1;
  tx :> link;
  tx :> hash;

  if (!remove_entry) {
    avb_1722_router_table_add_or_update_entry(key0, key1, link, hash);
  }
  else {
    avb_1722_router_table_remove_entry(key0, key1);
  }
}

static transaction get_and_update_avb_forwarding(chanend tx) {
  int key0, key1, forward_bool;
  tx :> key0;
  tx :> key1;
  tx :> forward_bool;
  avb_1722_router_table_add_or_update_forwarding(key0, key1, forward_bool);
}

static transaction get_and_update_qav_idle_slope(chanend tx) {
  int slope, port_num;
  tx :> port_num;
  tx :> slope;
  asm("stw %0,%1[%2]"::"r"(slope), "r"(g_mii_idle_slope), "r"(port_num));
}
#endif

#pragma unsafe arrays
    void ethernet_tx_server(
#if ETHERNET_TX_HP_QUEUE
                        mii_mempool_t tx_mem_hp[],
#endif
                        mii_mempool_t tx_mem_lp[],
                        int num_q,
                        mii_ts_queue_t ts_queue[],
                        const char mac_addr[],
                        chanend tx[],
                        int num_tx,
                        smi_interface_t &?smi1,
                        smi_interface_t &?smi2)
{
  unsigned buf[NUM_ETHERNET_PORTS];
  unsigned wrap_ptr[NUM_ETHERNET_PORTS];
  unsigned dptr[NUM_ETHERNET_PORTS];
  int enabled[MAX_LINKS];
  int pendingCmd[MAX_LINKS]={0};
  timer tmr;
  unsigned linkCheckTime = 0;

  tmr :> linkCheckTime;
  linkCheckTime += LINK_POLL_PERIOD;

#if (ETHERNET_TX_HP_QUEUE) && (ETHERNET_TRAFFIC_SHAPER)
  for (int i=0;i<NUM_ETHERNET_PORTS;i++) {
    asm("stw %0,%1[%2]"::"r"(11<<MII_CREDIT_FRACTIONAL_BITS), "r"(g_mii_idle_slope), "r"(i));
  }
#endif

  for (int i=0;i<num_tx;i++)
    enabled[i] = 1;

  while (1) {
    for (int i=0;i<num_tx;i++) {
      int cmd = pendingCmd[i];
      int length, dst_port, bufs_ok=1;
#if ETHERNET_TX_HP_QUEUE
      int hp=0;
#endif
      switch (cmd)
        {
        case ETHERNET_TX_REQ:
        case ETHERNET_TX_REQ_OFFSET2:
        case ETHERNET_TX_REQ_TIMED:
#if ETHERNET_TX_HP_QUEUE
        case ETHERNET_TX_REQ_HP:
        case ETHERNET_TX_REQ_OFFSET2_HP:
        case ETHERNET_TX_REQ_TIMED_HP:
#endif

#if ETHERNET_TX_HP_QUEUE
          switch (cmd) {
          case ETHERNET_TX_REQ_HP:
            cmd = ETHERNET_TX_REQ;
            hp = 1;
            break;
          case ETHERNET_TX_REQ_OFFSET2_HP:
            cmd = ETHERNET_TX_REQ_OFFSET2;
            hp = 1;
            break;
          case ETHERNET_TX_REQ_TIMED_HP:
            cmd = ETHERNET_TX_REQ_TIMED;
            hp = 1;
            break;
          }
#endif

          for (unsigned int p=0; p<NUM_ETHERNET_PORTS; ++p) {
#if ETHERNET_TX_HP_QUEUE
            if (hp) {
              buf[p] = mii_reserve_at_least(tx_mem_hp[p],
                                            MII_MALLOC_FULL_PACKET_SIZE_HP);
              wrap_ptr[p] = mii_get_wrap_ptr(tx_mem_hp[p]);
            }
            else {
              buf[p] = mii_reserve_at_least(tx_mem_lp[p],
                                            MII_MALLOC_FULL_PACKET_SIZE_LP);
              wrap_ptr[p] = mii_get_wrap_ptr(tx_mem_lp[p]);
            }
#else
              buf[p] = mii_reserve_at_least(tx_mem_lp[p],
                                            MII_MALLOC_FULL_PACKET_SIZE_LP);
              wrap_ptr[p] = mii_get_wrap_ptr(tx_mem_lp[p]);
#endif
        	  if (buf[p] == 0)
              bufs_ok=0;
            else
              dptr[p] = mii_packet_get_data_ptr(buf[p]);
          }

          if (bufs_ok) {
            master get_packet_from_client(tx[i], cmd, length, dst_port, dptr,
                                          wrap_ptr);

            for (unsigned p=0; p<NUM_ETHERNET_PORTS; ++p) {
            	if (p == dst_port || dst_port == ETH_BROADCAST) {
            		mii_packet_set_length(buf[p], length);

#if defined(ENABLE_ETHERNET_SOURCE_ADDRESS_WRITE)
            		{
                  for (int i=0;i<6;i++)
                    mii_packet_set_data_byte(buf[p], 6+i, mac_addr[i]);
            		}
#endif

            		if (cmd == ETHERNET_TX_REQ_TIMED)
            			mii_packet_set_timestamp_id(buf[p], i+1);
            		else
            			mii_packet_set_timestamp_id(buf[p], 0);


            		mii_commit(buf[p], dptr[p]);

            		mii_packet_set_tcount(buf[p], 0);
            		mii_packet_set_stage(buf[p], 1);
            	}
            }

            enabled[i] = 0;
            pendingCmd[i] = 0;
          }
          break;
        default:
          break;

        }
    }

    select {
      case tmr when timerafter(linkCheckTime) :> int:
        if (!isnull(smi1)) {
          do_link_check(smi1, 0);
        }
        if (!isnull(smi2)) {
          do_link_check(smi2, 1);
        }
        linkCheckTime += LINK_POLL_PERIOD;
        break;
      case (int i=0;i<num_tx;i++) enabled[i] => tx[i] :> int cmd:
      {
        switch (cmd)
        {
          case ETHERNET_TX_REQ:
          case ETHERNET_TX_REQ_OFFSET2:
          case ETHERNET_TX_REQ_TIMED:
#if (ETHERNET_TX_HP_QUEUE)
            case ETHERNET_TX_REQ_HP:
            case ETHERNET_TX_REQ_OFFSET2_HP:
            case ETHERNET_TX_REQ_TIMED_HP:
#endif

              pendingCmd[i] = cmd;
              break;
            case ETHERNET_GET_MAC_ADRS:
              slave {
                for (int j=0;j< 6;j++) {
                  tx[i] <: mac_addr[j];
                }
              }
              break;
#ifdef AVB_MAC
          case ETHERNET_TX_UPDATE_AVB_ROUTER:
          {
            master get_and_update_avb_router(tx[i]);
            break;
          }
          case ETHERNET_TX_UPDATE_AVB_FORWARDING:
          {
            master get_and_update_avb_forwarding(tx[i]);
            break;
          }
          case ETHERNET_TX_INIT_AVB_ROUTER:
          {
            init_avb_1722_router_table();
            break;
          }
#endif
#if (ETHERNET_TX_HP_QUEUE) && (ETHERNET_TRAFFIC_SHAPER)
          case ETHERNET_TX_SET_QAV_IDLE_SLOPE:
          {
            master get_and_update_qav_idle_slope(tx[i]);
            break;
          }
#endif
          default:
            // Unrecognized command
            break;
        }
        break;
      }
      default: {
        for (int i=0;i<num_tx;i++)
          enabled[i] = 1;
        break;
      }
    }

    // Reply with timestamps where client is requesting them
    for (unsigned p=0; p<NUM_ETHERNET_MASTER_PORTS; ++p) {
      buf[p] = get_ts_queue_entry(ts_queue[p]);
      if (buf[p] != 0) {
        int i = mii_packet_get_timestamp_id(buf[p]);
        int ts = mii_packet_get_timestamp(buf[p]);
        tx[i-1] <: ts + ETHERNET_TX_PHY_TIMER_OFFSET;
        if (get_and_dec_transmit_count(buf[p]) == 0)
          mii_free(buf[p]);
      }
    }
  }
}

