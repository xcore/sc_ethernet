// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "smi.h"
#include "mii.h"
#include "mii_queue.h"
#include "ethernet_server_def.h"
#include "mii_malloc.h"
#include "eth_phy.h"
#include <print.h>
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

static void mac_check_link_server(smi_interface_t &smi,
               int linkNum,
               chanend c,
               int &phy_status)
{
  int new_status = eth_phy_checklink(smi);
  if (new_status != phy_status) {
    outuchar(c, linkNum);
    outuchar(c, new_status);
    outuchar(c, 0);
    outct(c, XS1_CT_END);
    phy_status = new_status;
  }
}

#pragma unsafe arrays
void ethernet_tx_server(
#ifdef ETHERNET_TX_HP_QUEUE
                        mii_mempool_t tx_mem_hp[],
#endif
                        mii_mempool_t tx_mem_lp[],
                        int num_q, 
                        mii_ts_queue_t ts_queue[],
                        const int mac_addr[],
                        chanend tx[],
                        int num_tx,
                        smi_interface_t &?smi1, 
                        smi_interface_t &?smi2, 
                        chanend ?connect_status) 
{
  unsigned buf[NUM_ETHERNET_PORTS];
  int enabled[MAX_LINKS];
  int pendingCmd[MAX_LINKS]={0};
  timer tmr;
  unsigned linkCheckTime = 0;
  int phy_status[2] = {0};
  
  tmr :> linkCheckTime;
  linkCheckTime += LINK_POLL_PERIOD;


  for (int i=0;i<num_tx;i++) 
    enabled[i] = 1;

  while (1) {
    for (int i=0;i<num_tx;i++) {
      int cmd = pendingCmd[i];
      int length, dst_port, bufs_ok=1;
#ifdef ETHERNET_TX_HP_QUEUE
      int hp=0;
#endif
      switch (cmd) 
        {
        case ETHERNET_TX_REQ:
        case ETHERNET_TX_REQ_OFFSET2:
        case ETHERNET_TX_REQ_TIMED:      
#ifdef ETHERNET_TX_HP_QUEUE
        case ETHERNET_TX_REQ_HP:
        case ETHERNET_TX_REQ_OFFSET2_HP:
        case ETHERNET_TX_REQ_TIMED_HP:      
#endif
      
#ifdef ETHERNET_TX_HP_QUEUE    
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
#ifdef ETHERNET_TX_HP_QUEUE
        	  if (hp)
        		  buf[p] = mii_reserve(tx_mem_hp[p]);
        	  else
        		  buf[p] = mii_reserve(tx_mem_lp[p]);
#else
        	  buf[p] = mii_reserve(tx_mem_lp[p]);
#endif
        	  if (buf[p] == 0) bufs_ok=0;
          }

          if (bufs_ok) {
              master {
        		  tx[i] :> length;
        		  tx[i] :> dst_port;
            	  if (cmd == ETHERNET_TX_REQ_OFFSET2) {
            		  tx[i] :> char;
            		  tx[i] :> char;
            		  for(int j=0;j<(length+3)>>2;j++) {
            			  int datum;
            			  tx[i] :> datum;
            			  for (unsigned p=0; p<NUM_ETHERNET_PORTS; ++p) {
            				  mii_packet_set_data(buf[p], j, byterev(datum));
            			  }
            		  }
            		  tx[i] :> char;
            		  tx[i] :> char;

            		  cmd = ETHERNET_TX_REQ;
            	  } else {
            		  for(int j=0;j<(length+3)>>2;j++) {
            			  int datum;
            			  tx[i] :> datum;
            			  for (unsigned p=0; p<NUM_ETHERNET_PORTS; ++p) {
            				  mii_packet_set_data(buf[p], j, datum);
            			  }
            		  }
            	  }
            }

            for (unsigned p=0; p<NUM_ETHERNET_PORTS; ++p) {
            	if (p == dst_port || dst_port == ETH_BROADCAST) {
            		mii_packet_set_length(buf[p], length);

#if defined(ENABLE_ETHERNET_SOURCE_ADDRESS_WRITE)
            		{
            			mii_packet_set_data_short(buf[p], 3, (mac_addr,short[])[0]);
            			mii_packet_set_data_short(buf[p], 4, (mac_addr,short[])[1]);
            			mii_packet_set_data_short(buf[p], 5, (mac_addr,short[])[2]);
            		}
#endif

            		if (cmd == ETHERNET_TX_REQ_TIMED)
            			mii_packet_set_timestamp_id(buf[p], i+1);
            		else
            			mii_packet_set_timestamp_id(buf[p], 0);


            		mii_commit(buf[p], (length+(BUF_DATA_OFFSET*4)));

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
        if (!isnull(smi1) && !isnull(connect_status)) {
          mac_check_link_server(smi1, 0, connect_status, phy_status[0]);
        }
        if (!isnull(smi2) && !isnull(connect_status)) {
          mac_check_link_server(smi2, 1, connect_status, phy_status[1]);
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
#if defined(ETHERNET_TX_HP_QUEUE)
            case ETHERNET_TX_REQ_HP:
            case ETHERNET_TX_REQ_OFFSET2_HP:
            case ETHERNET_TX_REQ_TIMED_HP:
#endif

              pendingCmd[i] = cmd;
              break;
            case ETHERNET_GET_MAC_ADRS:
              slave {
                for (int j=0;j< 6;j++) {
                  tx[i] <: (char) (mac_addr,char[])[j];
                }
              }
              break;
#ifdef AVB_MAC
        case ETHERNET_TX_UPDATE_AVB_ROUTER:
          { unsigned key0, key1, link, hash;
            master {
              tx[i] :> key0;
              tx[i] :> key1;
              tx[i] :> link;
              tx[i] :> hash;
            }
            avb_1722_router_table_add_entry(key0, key1, link, hash);
          }
          break;
        case ETHERNET_TX_INIT_AVB_ROUTER:
            init_avb_1722_router_table();
          break;           
#endif
#if defined(ETHERNET_TX_HP_QUEUE) && defined(ETHERNET_TRAFFIC_SHAPER)
         case ETHERNET_TX_SET_QAV_IDLE_SLOPE:
            master
            {
              int slope;
              tx[i] :> slope;
              asm("stw %0,dp[g_mii_idle_slope]"::"r"(slope));
            }
         break;
#endif
            default:
              // Unrecognized command
              break;
            }
          break;
           }
    default:
      for (int i=0;i<num_tx;i++) 
        enabled[i] = 1; 
      break;
    }

    // Reply with timestamps where client is requesting them
    for (unsigned p=0; p<NUM_ETHERNET_PORTS; ++p) {
    	buf[p]=get_ts_queue_entry(ts_queue[p]);
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

