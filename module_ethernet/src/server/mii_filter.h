/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    mii_filter.h
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
void one_port_filter(mii_packet_t buf[],
                     const int mac[2],
                     REFERENCE_PARAM(mii_queue_t, free_queue),
                     REFERENCE_PARAM(mii_queue_t, internal_q),
                     streaming chanend c);

void two_port_filter(mii_packet_t buf[],
                     const int mac[2],
                     REFERENCE_PARAM(mii_queue_t,free_q),
                     REFERENCE_PARAM(mii_queue_t,internal_q),
                     REFERENCE_PARAM(mii_queue_t,q1),
                     REFERENCE_PARAM(mii_queue_t,q2),
                     streaming chanend c0,
                     streaming chanend c1);

