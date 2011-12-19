// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

/*************************************************************************
 *
 * Ethernet MAC Layer Implementation
 * IEEE 802.3 Link Layer (Receive)
 *
 *
 *
 * Implements the management server for Ethernet Rx Frames.
 * 
 * This manages the pointers to buffer and communication over channel(s)
 * to PHY & Link layers.
 *
 *************************************************************************/

#include <xs1.h>
#include <xclib.h>
#include "mii.h"
#include "mii_queue.h"
#include "mii_malloc.h"
#include "mii_filter.h"
#include "ethernet_rx_server.h"
#include <print.h>

// data structure to keep track of link layer status.
typedef struct
{
   unsigned dropped_pkt_cnt;
   int notified;
   int max_queue_size;
   int rdIndex;
   int wrIndex;
   int fifo[NUM_MII_RX_BUF];
} LinkLayerStatus_t;

// Local data structures.

static int custom_filter_mask[MAX_ETHERNET_CLIENTS];

static LinkLayerStatus_t link_status[MAX_ETHERNET_CLIENTS];

static inline void notify(chanend c)
{
  outct(c, XS1_CT_END);
}

/** This service incomming commands from link layer interfaces.
 */
#pragma select handler
void serviceLinkCmd(chanend link, int linkIndex, unsigned int &cmd)
{
  int renotify=0;
  int is_cmd;
  
  is_cmd = inuchar(link);
  (void) inct(link);
  if (!link_status[linkIndex].notified)
    outct(link, XS1_CT_END);
  else {
    if (!is_cmd) 
      outct(link, XS1_CT_END);
    renotify=1;
  }

  cmd = inuint(link);  
  (void) inct(link);
  outct(link, XS1_CT_END);
   
  switch (cmd)
   {
      // request for data just mark it.x
      case ETHERNET_RX_FRAME_REQ:
      case ETHERNET_RX_FRAME_REQ_OFFSET2:
      case ETHERNET_RX_TYPE_PAYLOAD_REQ:
         // Handled elsewhere.

        renotify=0;
         break;
      // filter set.
      case ETHERNET_RX_CUSTOM_FILTER_SET: {
         int filter_value;
         link :> filter_value;
         custom_filter_mask[linkIndex] = filter_value;       
       } 
      break;
#ifdef ETHERNET_COUNT_PACKETS
      // overflow count return
      case ETHERNET_RX_OVERFLOW_CNT_REQ:
         link <: link_status[linkIndex].dropped_pkt_cnt;
         break;
      case ETHERNET_RX_OVERFLOW_MII_CNT_REQ: {
    	  unsigned mii_dropped, bad_crc, bad_length, address, filter;
    	  ethernet_get_mii_counts(mii_dropped);
    	  ethernet_get_filter_counts(address, filter, bad_length, bad_crc);
          link <: mii_dropped;
          link <: bad_length;
          link <: address;
          link <: filter;
          link <: bad_crc;
         }
         break;
#endif
      case ETHERNET_RX_DROP_PACKETS_SET: {        
         int drop_packets;
         link :> drop_packets;
         if (drop_packets) {
           link_status[linkIndex].max_queue_size = 1;
         }
         else {
           link_status[linkIndex].max_queue_size = NUM_MII_RX_BUF;
         }       
         }
         break;
      case ETHERNET_RX_QUEUE_SIZE_SET: {        
         int size;
         link :> size;
         link_status[linkIndex].max_queue_size = size;
         }
         break;
     default:    // unreconised command.
         break;
   }

   if (renotify)
     notify(link);
}

/** This sent out recived frame to a given link layer, also track dropped packets.
 *
 */ 
/* C wrapper that casts the int to a pointer */
void mac_rx_send_frame(int buf,
                       chanend link,
                       unsigned cmd);

#pragma unsafe arrays
void mac_rx_send_frame0(mii_packet_t &p, 
                        chanend link, 
                        unsigned int cmd)
{
  int i, length;
  
  if (cmd == ETHERNET_RX_FRAME_REQ_OFFSET2) {
    i=0;
    length = p.length;
    slave {
      link <: p.src_port;
      link <: length-(i<<2);
      link <: (char) 0;
      link <: (char) 0;
      for (;i < (length+3)>>2;i++) {
        link <: byterev(p.data[i]);
      }
      link <: (char) 0;
      link <: (char) 0;      
      link <: p.timestamp;
    }  
    
  }
  else {
    // base on payload request need to adjust bytes to sent.
    if (cmd == ETHERNET_RX_FRAME_REQ) {
      i=0;
    } else {
      // strip source/dest MAC address, 6 bytes each.
      i=3;
    }
    
    length = p.length;
    
    slave {
      link <: p.src_port;
      link <: length-(i<<2);
      for (;i < (length+3)>>2;i++) {
        link <: p.data[i];
      }
      link <: p.timestamp;
      
    }  
  }
}

/** This apply ethernet frame filters on the recieved frame for each link.
 *  A received frame may be required to sent to more than one link layer.
 */
#pragma unsafe arrays
static void processReceivedFrame(int buf,
                                 chanend link[], 
                                 int n)
{
   int i;
   int tcount = 0;
   int result = mii_packet_get_filter_result(buf);
   // process for each link

   if (result) {
     for (i = 0; i < n; i += 1) {
         int match = 0;
         match = (custom_filter_mask[i] & result);
         
         if (match) {
             // We have a match, add the packet to the client's
             // packet queue (if there is space)
             int rdIndex = link_status[i].rdIndex;
             int wrIndex = link_status[i].wrIndex;
             int new_wrIndex;
             int queue_size;
             
             new_wrIndex = wrIndex+1;
             new_wrIndex *= (new_wrIndex != NUM_MII_RX_BUF);
             
             queue_size = wrIndex-rdIndex;
             if (queue_size < 0)
               queue_size += NUM_MII_RX_BUF;
             
             
             if (queue_size < link_status[i].max_queue_size &&
                 new_wrIndex != rdIndex) {
                 tcount++;
                 link_status[i].fifo[wrIndex] = buf;
                 link_status[i].wrIndex = new_wrIndex;
                 if (!link_status[i].notified) {
                   notify(link[i]);
                   link_status[i].notified = 1;
                 }
               } else {
                 link_status[i].dropped_pkt_cnt++;
               }
           }
       }

#if (NUM_ETHERNET_PORTS > 1) && !defined(DISABLE_ETHERNET_PORT_FORWARDING)
	   // Forward to other ports
       if (result & MII_FILTER_FORWARD_TO_OTHER_PORTS) {
    	   tcount += (NUM_ETHERNET_PORTS-1);
    	   mii_packet_set_forwarding(buf, 0xFFFFFFFF);
       }
#endif
   }
   
   if (tcount == 0) {
     //if (get_and_dec_transmit_count(buf)==0)
       mii_free(buf);
   }
   else {
     incr_transmit_count(buf, tcount-1);
   }   
   return;
}


/** This implement Ethernet Rx server, with packet filtering.
 *  Each interface need to enable *filter* to receive. Each link interface
 *  can accept ethernet frames based on destination MAC address (6bytes) and/or
 *  VLAN Tag & EType (6bytes). Each bit in the 12bytes filter in turn have mask
 *  and compare bit.
 *
 *  It interface with ethernet_rx_buf_ctl to handle frames 
 * 
 */
#pragma unsafe arrays
void ethernet_rx_server(
#ifdef ETHERNET_RX_HP_QUEUE
		mii_mempool_t rxmem_hp[],
#endif
		mii_mempool_t rxmem_lp[],
		chanend link[],
		int num_link)
{
   int i;
   unsigned int cmd;
#ifdef ETHERNET_RX_HP_QUEUE
   int rdptr_hp[NUM_ETHERNET_PORTS];
#endif
   int rdptr_lp[NUM_ETHERNET_PORTS];

   for (unsigned p=0; p<NUM_ETHERNET_PORTS; ++p) {
#ifdef ETHERNET_RX_HP_QUEUE
	   rdptr_hp[p] = mii_init_my_rdptr(rxmem_hp[p]);
#endif
	   rdptr_lp[p] = mii_init_my_rdptr(rxmem_lp[p]);
   }

   // Initialise the link filters & local data structures.
   for (i = 0; i < num_link; i += 1)
   {
      link_status[i].dropped_pkt_cnt = 0;      
      link_status[i].max_queue_size = NUM_MII_RX_BUF;
      link_status[i].rdIndex = 0;
      link_status[i].wrIndex = 0;
      link_status[i].notified = 0;
      custom_filter_mask[i] = 0;
   }

   // Main control loop.
   while (1)
   {
     int kill_link = -1;
     // Make this select ordered so we deal with any commands from the client
     // before processing a packet
#pragma ordered
     select
       {
       case (int i=0;i<num_link;i++) serviceLinkCmd(link[i], i, cmd):
         if (cmd == ETHERNET_RX_FRAME_REQ || 
             cmd == ETHERNET_RX_TYPE_PAYLOAD_REQ ||
             cmd == ETHERNET_RX_FRAME_REQ_OFFSET2)
           {
             int rdIndex = link_status[i].rdIndex;
             int wrIndex = link_status[i].wrIndex;
             int new_rdIndex;
                          
             if (rdIndex != wrIndex) {
               int buf = link_status[i].fifo[rdIndex];
               new_rdIndex=rdIndex+1;
               new_rdIndex *= (new_rdIndex != NUM_MII_RX_BUF);

               mac_rx_send_frame(buf, link[i], cmd);

               if (get_and_dec_transmit_count(buf)==0)
                 mii_free(buf);

               link_status[i].rdIndex = new_rdIndex;

               if (new_rdIndex != wrIndex) {
                 notify(link[i]);
               }
               else {
                 link_status[i].notified = 0;
               }               
             }
              else { 
               // mac request without notification
             }
           }
         break;
       default:
         {
#ifdef ETHERNET_RX_HP_QUEUE
           for (unsigned p=0; p<NUM_ETHERNET_PORTS; ++p) {
        	   int buf = mii_get_my_next_buf(rxmem_hp[p], rdptr_hp[p]);
        	   if (buf != 0 && mii_packet_get_stage(buf) == 1) {
        		   rdptr_hp[p] = mii_update_my_rdptr(rxmem_hp[p], rdptr_hp[p]);
        		   processReceivedFrame(buf, link, num_link);
        		   break;
        	   }
           }

#endif
           for (unsigned p=0; p<NUM_ETHERNET_PORTS; ++p) {
        	   int buf = mii_get_my_next_buf(rxmem_lp[p], rdptr_lp[p]);
        	   if (buf != 0 && mii_packet_get_stage(buf) == 1) {
        		   rdptr_lp[p] = mii_update_my_rdptr(rxmem_lp[p], rdptr_lp[p]);
        		   processReceivedFrame(buf, link, num_link);
                   break;
        	   }
		   }
           break;
         }
       }       
   }
}

