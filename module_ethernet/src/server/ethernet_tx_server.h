// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xccompat.h>
#include "mii.h"
#include "mii_queue.h"
#include "mii_malloc.h"

#ifdef __XC__
void ethernet_tx_server(mii_mempool_t tx_mem,
                        mii_queue_t out_q[],
                        int num_q,
                        REFERENCE_PARAM(mii_queue_t,ts_q),                     
                        const int mac_addr[2],
                        chanend tx[], int num_tx,
                        smi_interface_t &?smi1,
                        smi_interface_t &?smi2,
                        chanend ?connect_status);xb
#else
void ethernet_tx_server(mii_mempool_t tx_mem,
                        mii_queue_t out_q[],
                        int num_q,
                        REFERENCE_PARAM(mii_queue_t,ts_q),                     
                        const int mac_addr[2],
                        chanend tx[], int num_tx,
                        smi_interface_t *smi1,
                        smi_interface_t *smi2,
                        chanend connect_status);
#endif

