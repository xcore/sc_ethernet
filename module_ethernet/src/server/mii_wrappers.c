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

// Queue of timestamps for transmitted packets
mii_ts_queue_t ts_queue[NUM_ETHERNET_PORTS];

// This is the single ethernet hardware lock when we are using hardware locking
#ifdef ETHERNET_USE_HARDWARE_LOCKS
#include "hwlock.h"
hwlock_t ethernet_memory_lock = 0;
#endif

#ifdef ETHERNET_RX_HP_QUEUE

#ifndef MII_RX_BUFSIZE_HIGH_PRIORITY
#define MII_RX_BUFSIZE_HIGH_PRIORITY 256
#endif

#ifndef MII_RX_BUFSIZE_LOW_PRIORITY
#define MII_RX_BUFSIZE_LOW_PRIORITY 512
#endif

#define MII_RX_HP_MEMSIZE \
  ((MII_RX_BUFSIZE_HIGH_PRIORITY +  2*sizeof(mii_packet_t) + 20)/4)
#endif

#define MII_RX_LP_MEMSIZE \
      ((MII_RX_BUFSIZE_LOW_PRIORITY + 2*sizeof(mii_packet_t) + 20)/4)

#define MII_TX_LP_MEMSIZE \
    ((MII_TX_BUFSIZE + sizeof(mii_packet_t) + 20)/4)



#ifdef ETHERNET_TX_HP_QUEUE

#ifndef MII_TX_BUFSIZE_HIGH_PRIORITY
#define MII_TX_BUFSIZE_HIGH_PRIORITY 256
#endif

#define MII_TX_HP_MEMSIZE \
      ((MII_TX_BUFSIZE_HIGH_PRIORITY +(ETHERNET_MAX_TX_HP_PACKET_SIZE + MII_PACKET_HEADER_SIZE) + 20)/4)
#endif


#ifdef ETHERNET_RX_HP_QUEUE
int rx_hp_data[NUM_ETHERNET_PORTS][MII_RX_HP_MEMSIZE];
#endif

#ifdef ETHERNET_TX_HP_QUEUE
int tx_hp_data[NUM_ETHERNET_PORTS][MII_TX_HP_MEMSIZE];
#endif



int rx_lp_data[NUM_ETHERNET_PORTS][MII_RX_LP_MEMSIZE];
int tx_lp_data[NUM_ETHERNET_PORTS][MII_TX_LP_MEMSIZE];



#ifdef ETHERNET_RX_HP_QUEUE
mii_mempool_t rx_mem_hp[NUM_ETHERNET_PORTS];
#endif

#ifdef ETHERNET_TX_HP_QUEUE
mii_mempool_t tx_mem_hp[NUM_ETHERNET_PORTS];
#endif

mii_mempool_t rx_mem_lp[NUM_ETHERNET_PORTS];

mii_mempool_t tx_mem_lp[NUM_ETHERNET_PORTS];


void init_mii_mem() {

#ifdef ETHERNET_USE_HARDWARE_LOCKS
	ethernet_memory_lock = __hwlock_init();
#endif

	for (int i=0; i<NUM_ETHERNET_PORTS; ++i) {
#ifdef ETHERNET_RX_HP_QUEUE
		rx_mem_hp[i] = (mii_mempool_t) &rx_hp_data[i][0];
#endif
#ifdef ETHERNET_TX_HP_QUEUE
		tx_mem_hp[i] = (mii_mempool_t) &tx_hp_data[i][0];
#endif
		rx_mem_lp[i] = (mii_mempool_t) &rx_lp_data[i][0];
		tx_mem_lp[i] = (mii_mempool_t) &tx_lp_data[i][0];
#ifdef ETHERNET_RX_HP_QUEUE
		mii_init_mempool(rx_mem_hp[i], MII_RX_HP_MEMSIZE*4, 1518);
#endif
#ifdef ETHERNET_TX_HP_QUEUE
		mii_init_mempool(tx_mem_hp[i], MII_TX_HP_MEMSIZE*4, 1518);
#endif
		mii_init_mempool(rx_mem_lp[i], MII_RX_LP_MEMSIZE*4, 1518);
		mii_init_mempool(tx_mem_lp[i], MII_TX_LP_MEMSIZE*4, ETHERNET_MAX_TX_PACKET_SIZE);

		init_ts_queue(&ts_queue[i]);
	}
	return;
}

void mii_rx_pins_wr(port p1,
                    port p2,
                    int i,
                    streaming chanend c)
{
  mii_rx_pins(
#ifdef ETHERNET_RX_HP_QUEUE
		  rx_mem_hp[i],
#endif
		  rx_mem_lp[i], p1, p2, i, c);
}


void mii_tx_pins_wr(port p,
                    int i)
{
  mii_tx_pins(
#if (NUM_ETHERNET_PORTS > 1) && !defined(DISABLE_ETHERNET_PORT_FORWARDING)
#ifdef ETHERNET_TX_HP_QUEUE
				rx_mem_hp,
#endif
				rx_mem_lp,
#endif
#ifdef ETHERNET_TX_HP_QUEUE
				tx_mem_hp[i],
#endif
				tx_mem_lp[i], &ts_queue[i], p, i);
}

void ethernet_tx_server_wr(const int mac_addr[], chanend tx[], int num_q, int num_tx, smi_interface_t *smi1, smi_interface_t *smi2, chanend connect_status)
{
  ethernet_tx_server(
#ifdef ETHERNET_TX_HP_QUEUE
                     tx_mem_hp,
#endif
                     tx_mem_lp,
                     num_q,
                     ts_queue,
                     mac_addr,
                     tx,
                     num_tx,
                     smi1,
                     smi2,
                     connect_status);
}

void ethernet_rx_server_wr(chanend rx[], int num_rx)
{
  ethernet_rx_server(
#ifdef ETHERNET_RX_HP_QUEUE
					 rx_mem_hp,
#endif
                     rx_mem_lp,
                     rx,
                     num_rx);
}
