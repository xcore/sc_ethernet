/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    mii_wrappers.c
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
#include <xccompat.h>
#define streaming 
#include "smi.h"
#include "mii.h"
#include "mii_queue.h"
#include "mii_filter.h"
#include "ethernet_tx_server.h"
#include "ethernet_rx_server.h"

#include <print.h>


mii_queue_t rx_free_queue, tx_free_queue, 
  filter_queue, internal_queue, ts_queue;
mii_queue_t tx_queue[2];

mii_packet_t mii_packet_buf[NUM_MII_TX_BUF + NUM_MII_RX_BUF+1];

void init_mii_mem() {
  int i;  
  init_queues();
  init_queue(&rx_free_queue, NUM_MII_RX_BUF, 0);
  init_queue(&tx_free_queue, NUM_MII_TX_BUF, NUM_MII_RX_BUF);
  init_queue(&filter_queue, 0, 0);
  init_queue(&internal_queue, 0, 0);
  init_queue(&ts_queue, 0, 0);
  for(i=0;i<2;i++)
    init_queue(&tx_queue[i], 0, 0);
  return;
}

void mii_rx_pins_wr(port p1,
                    port p2,
                    int i,
                    streaming chanend c)
{
  mii_rx_pins(&rx_free_queue, mii_packet_buf, p1, p2, i, c);
}


void mii_tx_pins_wr(port p,
                    int i)
{
  mii_tx_pins(mii_packet_buf, &tx_queue[i], &tx_free_queue, &ts_queue, p, i);
}


void two_port_filter_wr(const int mac[2], streaming chanend c, streaming chanend d)
{
  two_port_filter(mii_packet_buf,
                  mac, 
                  &rx_free_queue, 
                  &internal_queue,
                  &tx_queue[0], 
                  &tx_queue[1],
                  c,
                  d);
}


void one_port_filter_wr(const int mac[2], streaming chanend c)
{
  one_port_filter(mii_packet_buf,
                  mac, 
                  &rx_free_queue, 
                  &internal_queue,
                  c);
}

void ethernet_tx_server_wr(const int mac_addr[2], chanend tx[], int num_q, int num_tx, smi_interface_t *smi1, smi_interface_t *smi2, chanend connect_status)
{
  ethernet_tx_server(&tx_free_queue, 
                     &tx_queue[0], 
                     &tx_queue[1], 
                     num_q,
                     &ts_queue,
                     mii_packet_buf,
                     mac_addr,
                     tx,
                     num_tx,
                     smi1,
                     smi2,
                     connect_status);
}

void ethernet_rx_server_wr(chanend rx[], int num_rx)
{
  ethernet_rx_server(&internal_queue, 
                     &rx_free_queue,
                     mii_packet_buf,
                     rx,
                     num_rx);
}
