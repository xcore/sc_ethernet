/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    mii_wrappers.h
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
void init_mii_mem();

void mii_rx_pins_wr(in port p_mii_rxdv,
                    in buffered port:32 p_mii_rxd,
                    int i,
                    streaming chanend c);

#define mii_rx_pins mii_rx_pins_wr

void mii_tx_pins_wr(out buffered port:32 p,
                    int i);

#define mii_tx_pins mii_tx_pins_wr

void two_port_filter_wr(const int mac[2], streaming chanend c0, streaming chanend c1);

#define two_port_filter two_port_filter_wr

void ethernet_tx_server_wr(const int mac_addr[2], chanend tx[], int num_q, int num_tx, smi_interface_t &?smi1, smi_interface_t &?smi2, chanend ?connect_status);

#define ethernet_tx_server ethernet_tx_server_wr

void ethernet_rx_server_wr(chanend rx[], int num_rx);

#define ethernet_rx_server ethernet_rx_server_wr

void one_port_filter_wr(const int mac[2], streaming chanend c);

#define one_port_filter one_port_filter_wr
