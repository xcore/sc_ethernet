// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xccompat.h>
#include "mii_full.h"
#include "mii_queue.h"
#include "mii_malloc.h"
#include "ethernet_conf_derived.h"

void ethernet_tx_server_no_buffer(const char mac_addr[],
                                  chanend tx[],
                                  int num_tx,
                                  #ifdef __XC__
                                  out buffered port:32 p_mii_txd,
                                  #else
                                  port p_mii_txd,
                                  #endif
                                  NULLABLE_REFERENCE_PARAM(smi_interface_t, smi1));


#ifdef __XC__
void ethernet_tx_server(
#if ETHERNET_TX_HP_QUEUE
                        mii_mempool_t tx_mem_hp[],
#endif
                        mii_mempool_t tx_mem_lp[],
                        int num_q,
                        mii_ts_queue_t ts_q[],
                        const char mac_addr[],
                        chanend tx[], int num_tx,
                        smi_interface_t &?smi1,
                        smi_interface_t &?smi2);
#else
void ethernet_tx_server(
#if ETHERNET_TX_HP_QUEUE
                        mii_mempool_t tx_mem_hp[],
#endif
                        mii_mempool_t tx_mem_lp[],
                        int num_q,
                        mii_ts_queue_t ts_q[],
                        const char mac_addr[],
                        chanend tx[], int num_tx,
                        smi_interface_t *smi1,
                        smi_interface_t *smi2);
#endif

