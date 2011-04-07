// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xccompat.h>
#define streaming 
#include "smi.h"
#include "mii.h"
#include "mii_queue.h"
#include "mii_filter.h"
#include "ethernet_tx_server.h"
#include "ethernet_rx_server.h"
#include "mii_malloc.h"

#include <print.h>


mii_queue_t filter_queue, internal_queue, ts_queue;


#ifdef ETHERNET_HP_QUEUE
#define MII_RX_HP_MEMSIZE \
      ((MII_RX_BUFSIZE_HIGH_PRIORITY + 2*sizeof(mii_packet_t) + 20)/4)
#endif

#define MII_RX_LP_MEMSIZE \
      ((MII_RX_BUFSIZE_LOW_PRIORITY + 2*sizeof(mii_packet_t) + 20)/4)

#define MII_TX_LP_MEMSIZE \
      ((MII_TX_BUFSIZE + 2*ETHERNET_MAX_TX_PACKET_SIZE + 20)/4)

#ifdef ETHERNET_TX_HP_QUEUE
#define MII_TX_HP_MEMSIZE \
      ((MII_TX_BUFSIZE_HIGH_PRIORITY + 2*sizeof(mii_packet_t) + 20)/4)
#endif


#ifdef ETHERNET_HP_QUEUE
int rx_hp_data[MII_RX_HP_MEMSIZE];
#endif

#ifdef ETHERNET_TX_HP_QUEUE
int tx_hp_data[MII_TX_HP_MEMSIZE];
#endif



int rx_lp_data[MII_RX_LP_MEMSIZE];
int tx_lp_data[MII_TX_LP_MEMSIZE];



mii_mempool_t rx_mem_hp, tx_mem_hp;


mii_mempool_t rx_mem_lp, tx_mem_lp;


void init_mii_mem() {
#ifdef ETHERNET_HP_QUEUE
  rx_mem_hp = (mii_mempool_t) &rx_hp_data[0];
#endif
#ifdef ETHERNET_TX_HP_QUEUE
  tx_mem_hp = (mii_mempool_t) &tx_hp_data[0];
#endif
  rx_mem_lp = (mii_mempool_t) &rx_lp_data[0];
  tx_mem_lp = (mii_mempool_t) &tx_lp_data[0];
#ifdef ETHERNET_HP_QUEUE
  mii_init_mempool(rx_mem_hp, MII_RX_HP_MEMSIZE*4, 1518);
#endif
#ifdef ETHERNET_TX_HP_QUEUE
  mii_init_mempool(tx_mem_hp, MII_TX_HP_MEMSIZE*4, 1518);
#endif
  mii_init_mempool(rx_mem_lp, MII_RX_LP_MEMSIZE*4, 1518);
  mii_init_mempool(tx_mem_lp, MII_TX_LP_MEMSIZE*4, ETHERNET_MAX_TX_PACKET_SIZE);

  init_queues();
  init_queue(&filter_queue);
  init_queue(&internal_queue);
  init_queue(&ts_queue);
  return;
}

void mii_rx_pins_wr(port p1,
                    port p2,
                    int i,
                    streaming chanend c)
{
  mii_rx_pins(rx_mem_hp, rx_mem_lp, p1, p2, i, c);
}


void mii_tx_pins_wr(port p,
                    int i)
{
  mii_tx_pins(
#ifdef ETHERNET_TX_HP_QUEUE
              tx_mem_hp,
#endif
              tx_mem_lp, &ts_queue, p, i);
}

#if 0
void two_port_filter_wr(const int mac[2], streaming chanend c, streaming chanend d)
{
  two_port_filter(mii_packet_buf,
                  mac,  
                  &internal_queue,
                  &tx_queue[0], 
                  &tx_queue[1],
                  c,
                  d);
}
#endif

void one_port_filter_wr(const int mac[2], streaming chanend c)
{
  one_port_filter(0,
                  mac, 
                  &internal_queue,
                  c);
}

void ethernet_tx_server_wr(const int mac_addr[2], chanend tx[], int num_q, int num_tx, smi_interface_t *smi1, smi_interface_t *smi2, chanend connect_status)
{
  ethernet_tx_server(
#ifdef ETHERNET_TX_HP_QUEUE
                     tx_mem_hp,
#endif
                     tx_mem_lp,
                     num_q,
                     &ts_queue,
                     mac_addr,
                     tx,
                     num_tx,
                     smi1,
                     smi2,
                     connect_status);
}

void ethernet_rx_server_wr(chanend rx[], int num_rx)
{
  ethernet_rx_server(rx_mem_hp,
                     rx_mem_lp,
                     &internal_queue, 
                     rx,
                     num_rx);
}
