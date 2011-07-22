// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xccompat.h>
#ifdef __XC__
void ethernet_tx_server(REFERENCE_PARAM(mii_queue_t,free_queue),
                        REFERENCE_PARAM(mii_queue_t,out_q1),
                        REFERENCE_PARAM(mii_queue_t,out_q2),
                        int num_q,
                        REFERENCE_PARAM(mii_queue_t,ts_q),                     
                        mii_packet_t buf[], 
                        const int mac_addr[2],
                        chanend tx[], int num_tx,
                        smi_interface_t &?smi1,
                        smi_interface_t &?smi2,
                        chanend ?connect_status);
#else
void ethernet_tx_server(REFERENCE_PARAM(mii_queue_t,free_queue),
                        REFERENCE_PARAM(mii_queue_t,out_q1),
                        REFERENCE_PARAM(mii_queue_t,out_q2),
                        int num_q,
                        REFERENCE_PARAM(mii_queue_t,ts_q),                     
                        mii_packet_t buf[], 
                        const int mac_addr[2],
                        chanend tx[], int num_tx,
                        smi_interface_t *smi1,
                        smi_interface_t *smi2,
                        chanend connect_status);
#endif

