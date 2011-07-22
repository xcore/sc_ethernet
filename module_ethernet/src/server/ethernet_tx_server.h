/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    ethernet_tx_server.h
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

