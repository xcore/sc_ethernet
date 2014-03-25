// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xccompat.h>
#define streaming
#include "smi.h"
#include "mii_full.h"
#include "mii_queue.h"
#include "mii_filter.h"
#include "ethernet_tx_server.h"
#include "ethernet_rx_server.h"
#include "mii_malloc.h"
#include <print.h>

// Queue of timestamps for transmitted packets
mii_ts_queue_t ts_queue[NUM_ETHERNET_MASTER_PORTS];

// This is the single ethernet hardware lock when we are using hardware locking
#ifdef ETHERNET_USE_HARDWARE_LOCKS
#include "hwlock.h"
hwlock_t ethernet_memory_lock = 0;
#endif

#if ETHERNET_RX_HP_QUEUE
#define ETHERNET_RX_HP_MEMSIZE  ((ETHERNET_RX_BUFSIZE_HIGH_PRIORITY)/4)
int rx_hp_data[NUM_ETHERNET_MASTER_PORTS][ETHERNET_RX_HP_MEMSIZE];
mii_mempool_t rx_mem_hp[NUM_ETHERNET_MASTER_PORTS];
#endif


#if ETHERNET_TX_HP_QUEUE
#define ETHERNET_TX_HP_MEMSIZE  ((ETHERNET_TX_BUFSIZE_HIGH_PRIORITY)/4)
int tx_hp_data[NUM_ETHERNET_MASTER_PORTS][ETHERNET_TX_HP_MEMSIZE];
mii_mempool_t tx_mem_hp[NUM_ETHERNET_MASTER_PORTS];
#endif

#define ETHERNET_RX_LP_MEMSIZE  ((ETHERNET_RX_BUFSIZE_LOW_PRIORITY)/4)
#define ETHERNET_TX_LP_MEMSIZE  ((ETHERNET_TX_BUFSIZE_LOW_PRIORITY)/4)

int rx_lp_data[NUM_ETHERNET_PORTS][ETHERNET_RX_LP_MEMSIZE];
int tx_lp_data[NUM_ETHERNET_PORTS][ETHERNET_TX_LP_MEMSIZE];

mii_mempool_t rx_mem_lp[NUM_ETHERNET_PORTS];
mii_mempool_t tx_mem_lp[NUM_ETHERNET_PORTS];

#ifdef ETHERNET_TX_BUFSIZE
#if ETHERNET_MAX_TX_PACKET_SIZE > ETHERNET_TX_BUFSIZE
#warning Ethernet TX may lock up (ETHERNET_MAX_TX_PACKET_SIZE > ETHERNET_TX_BUFSIZE)
#endif
#endif

void init_mii_mem() {
#ifdef ETHERNET_USE_HARDWARE_LOCKS
  ethernet_memory_lock = hwlock_alloc();
#endif

  // Initialisation of high priority and timestamp queues for master ports only
  for (int i=0; i<NUM_ETHERNET_MASTER_PORTS; ++i) {
#if ETHERNET_RX_HP_QUEUE
    rx_mem_hp[i] = (mii_mempool_t) &rx_hp_data[i][0];
    mii_init_mempool(rx_mem_hp[i], ETHERNET_RX_HP_MEMSIZE*4);
#endif


#if ETHERNET_TX_HP_QUEUE
    tx_mem_hp[i] = (mii_mempool_t) &tx_hp_data[i][0];
    mii_init_mempool(tx_mem_hp[i], ETHERNET_TX_HP_MEMSIZE*4);
#endif
    init_ts_queue(&ts_queue[i]);
  }

  // Initialisation of low priority ports for all ports
  for (int i=0; i<NUM_ETHERNET_PORTS; ++i) {
    rx_mem_lp[i] = (mii_mempool_t) &rx_lp_data[i][0];
    mii_init_mempool(rx_mem_lp[i], ETHERNET_RX_LP_MEMSIZE*4);

#if !ETHERNET_TX_NO_BUFFERING
    tx_mem_lp[i] = (mii_mempool_t) &tx_lp_data[i][0];
    mii_init_mempool(tx_mem_lp[i], ETHERNET_TX_LP_MEMSIZE*4);
#endif

  }

  return;
}

void mii_rx_pins_wr(port p1,
                    port p2,
                    int i,
                    streaming chanend c)
{
  mii_rx_pins(
#if ETHERNET_RX_HP_QUEUE
		  rx_mem_hp[i],
#endif
		  rx_mem_lp[i], p1, p2, i, c);
}

void mii_tx_pins_wr(port p,
                    int i)
{
  mii_tx_pins(
#if (NUM_ETHERNET_PORTS > 1) && !defined(DISABLE_ETHERNET_PORT_FORWARDING)
#if (NUM_ETHERNET_MASTER_PORTS > 1) && (ETHERNET_TX_HP_QUEUE)
				rx_mem_hp,
#endif
				rx_mem_lp,
#endif
#if ETHERNET_TX_HP_QUEUE
				tx_mem_hp[i],
#endif
				tx_mem_lp[i], &ts_queue[i], p, i);
}

void ethernet_tx_server_wr(const char mac_addr[], chanend tx[], int num_q, int num_tx, smi_interface_t *smi1, smi_interface_t *smi2
)
{

  ethernet_tx_server(
#if ETHERNET_TX_HP_QUEUE
                     tx_mem_hp,
#endif
                     tx_mem_lp,
                     num_q,
                     ts_queue,
                     mac_addr,
                     tx,
                     num_tx,
                     smi1,
                     smi2);
}

void ethernet_rx_server_wr(chanend rx[], int num_rx)
{
  ethernet_rx_server(
#if ETHERNET_RX_HP_QUEUE
					 rx_mem_hp,
#endif
                     rx_mem_lp,
                     rx,
                     num_rx);
}
