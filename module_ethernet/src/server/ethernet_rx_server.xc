/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    ethernet_rx_server.xc
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
#include "mii.h"
#include "mii_queue.h"
#include "ethernet_rx_server.h"
#include "ethernet_rx_filter.h"
#include <print.h>

#define FIFO_SIZE MAX_CLIENT_QUEUE_SIZE

// data structure to keep track of link layer status.
typedef struct
{
   unsigned dropped_pkt_cnt;
   int notified;
   int max_queue_size;
   int rdIndex;
   int wrIndex;
   int fifo[FIFO_SIZE];
} LinkLayerStatus_t;

// Local data structures.

#ifdef MAC_CUSTOM_FILTER
static int custom_filter_mask[MAX_ETHERNET_CLIENTS];
#else
// Receive frame filter structures.
static ClientFrameFilter_t link_filters[MAX_ETHERNET_CLIENTS];
#endif

static LinkLayerStatus_t link_status[MAX_ETHERNET_CLIENTS];

static inline void notify(chanend c)
{
  outuchar(c, 0); 
  outuchar(c, 0); 
  outuchar(c, 0); 
  outct(c, XS1_CT_END);
}

/** This service incomming commands from link layer interfaces.
 */
transaction serviceLinkCmd(chanend link, int linkIndex, unsigned int &cmd)
{

#ifndef MAC_CUSTOM_FILTER
  int i, filterIndex, error;
#endif

   link :> cmd;
   
   switch (cmd)
   {
      // request for data just mark it.x
      case ETHERNET_RX_FRAME_REQ:
      case ETHERNET_RX_TYPE_PAYLOAD_REQ:
         // Handled elsewhere.
         break;
      // filter set.
#ifdef MAC_CUSTOM_FILTER
      case ETHERNET_RX_CUSTOM_FILTER_SET: {
         int filter_value;
         link :> filter_value;
         custom_filter_mask[linkIndex] = filter_value;       
         link <: ETHERNET_REQ_ACK;
       } 
      break;
#else
      case ETHERNET_RX_FILTER_SET:
         // get filter index.
         link :> filterIndex;
         // sanity checking.
         error = 0;
         if (filterIndex >= MAX_MAC_FILTERS)
         {
            filterIndex = 0;
            error = 1;
         }         
         // update filter parameter from client.
         for (i = 0; i < sizeof(struct mac_filter_t); i += 1)
         {
           char c;
           link :> c;
           (link_filters[linkIndex].filters[filterIndex],unsigned char[])[i] = c;
         }
         // response.
         if (error) {
           link <: ETHERNET_REQ_NACK;
         } else {
           link <: ETHERNET_REQ_ACK;            
         }
         break;
#endif
      // overflow count return
      case ETHERNET_RX_OVERFLOW_CNT_REQ:
         link <: ETHERNET_REQ_ACK;
         link <: link_status[linkIndex].dropped_pkt_cnt;     
         break;
      case ETHERNET_RX_OVERFLOW_CLEAR_REQ:
         link <: ETHERNET_REQ_ACK;
         link_status[linkIndex].dropped_pkt_cnt = 0;
         break;
      case ETHERNET_RX_DROP_PACKETS_SET: {        
         int drop_packets;
         link :> drop_packets;
         link <: ETHERNET_REQ_ACK;
         if (drop_packets) {
           link_status[linkIndex].max_queue_size = 1;
         }
         else {
           link_status[linkIndex].max_queue_size = MAX_CLIENT_QUEUE_SIZE;
         }       
         }
         break;
      case ETHERNET_RX_QUEUE_SIZE_SET: {        
         int size;
         link :> size;
         link <: ETHERNET_REQ_ACK;
         link_status[linkIndex].max_queue_size = size;
         }
         break;

         /*      case ETHERNET_RX_KILL_LINK: {
        int j;
         link :> j;
         link_status[j].drop_packets = TRUE;
        }
        break;*/
     default:    // unreconised command.
         link <: ETHERNET_REQ_NACK;
         break;
   }
   
}

/** This sent out recived frame to a given link layer, also track dropped packets.
 *
 */ 
static void sendFrame(mii_packet_t &p, 
                      chanend link, 
                      unsigned int cmd)
{
  int i, length;
  
  while (!p.complete);

  // base on payload request need to adjust bytes to sent.
  if (cmd == ETHERNET_RX_FRAME_REQ) {
    i=0;
  } else {
    // strip source/dest MAC address, 6 bytes each.
    i=3;
  }

  length = p.length;
  
  master {
    link <: p.src_port;
    link <: length-(i<<2);
    for (;i < (length+3)>>2;i++) {
      link <: p.data[i];
    }
    link <: p.timestamp;
    
  }  
}


/** This apply ethernet frame filters on the recieved frame for each link.
 *  A received frame may be required to sent to more than one link layer.
 */
static void processReceivedFrame(mii_packet_t buf[], 
                                 int k,
                                 chanend link[], 
                                 int n)
{
   int i;
   int tcount = 0;

   // process for each link
   for (i = 0; i < n; i += 1)
     {
       int match = 0;

#ifdef MAC_CUSTOM_FILTER
       match = ((custom_filter_mask[i] & buf[k].filter_result));
#else
       match = (ethernet_frame_filter(link_filters[i],
                                      (buf[k].data, unsigned int[]))); 
#endif

       if (match) 
         {       
           // We have a match, add the packet to the client's
           // packet queue (if there is space)
           int rdIndex = link_status[i].rdIndex;
           int wrIndex = link_status[i].wrIndex;
           int new_wrIndex;
           int queue_size;

           new_wrIndex = wrIndex+1;
           new_wrIndex *= (new_wrIndex != FIFO_SIZE);

           queue_size = wrIndex-rdIndex;
           if (queue_size < 0)
             queue_size += FIFO_SIZE;

           if (queue_size < link_status[i].max_queue_size &&
               new_wrIndex != rdIndex)
             {
               tcount++;
               link_status[i].fifo[wrIndex] = k;
               link_status[i].wrIndex = new_wrIndex;
               if (!link_status[i].notified) {
                 //printstr("notify\n");
                 notify(link[i]);
                 link_status[i].notified = 1;
               }
             }
           else 
             {
               //printstr("ERROR: MAC pkt dropped, link ");
               //printintln(i);
             }
         }
     }

   
   if (tcount == 0) {
     if (get_and_dec_transmit_count(k)==0)
       free_queue_entry(k);
   }
   else {
     incr_transmit_count(k, tcount-1);
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
void ethernet_rx_server(mii_queue_t &in_q,
                        mii_queue_t &free_queue,
                        mii_packet_t buf[],
                        chanend link[],
                        int num_link)
{
   int i;
   unsigned int cmd;


   printstr("INFO: Ethernet Rx Server init..\n");
   //   ethernet_register_traphandler();

   // Initialise the link filters & local data structures.
   for (i = 0; i < num_link; i += 1)
   {
      link_status[i].dropped_pkt_cnt = 0;      
      link_status[i].max_queue_size = 1;
      link_status[i].rdIndex = 0;
      link_status[i].wrIndex = 0;
      link_status[i].notified = 0;
#ifdef MAC_CUSTOM_FILTER
      custom_filter_mask[i] = 0;
#else
      ethernet_frame_filter_init(link_filters[i]);      
#endif
   }

   printstr("INFO: Ethernet Rx Server started..\n");



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
             cmd == ETHERNET_RX_TYPE_PAYLOAD_REQ)
           {
             int rdIndex = link_status[i].rdIndex;
             int wrIndex = link_status[i].wrIndex;
             int new_rdIndex;
                          
             if (rdIndex != wrIndex) {
               int k = link_status[i].fifo[rdIndex];
               new_rdIndex=rdIndex+1;
               new_rdIndex *= (new_rdIndex != FIFO_SIZE);
               //printstr("send\n");
               sendFrame(buf[k], link[i], cmd);

               if (get_and_dec_transmit_count(k)==0)
                 free_queue_entry(k);

               link_status[i].rdIndex = new_rdIndex;

               if (new_rdIndex != wrIndex) {
                 //printstr("notify\n");
                 notify(link[i]);
               }
               else {
                 link_status[i].notified = 0;
               }               
             }
             else { 
               printstr("ERROR: mac request without notification\n");
             }
           }
         break;           
       default:
         {
           int k;
           k=get_queue_entry(in_q);
           if (k != 0) {            
             processReceivedFrame(buf, k, link, num_link);
           }   
           break;
         }
       }       
   }
   
}

