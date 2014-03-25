// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <mii_full.h>
#include <smi.h>
#include <mii_wrappers.h>
#include <mii_filter.h>

#if (NUM_ETHERNET_PORTS == 1)

void phy_init(smi_interface_t &smi0,
              mii_interface_full_t &mii0)
{
  smi_init(smi0);
  mii_init_full(mii0);
  eth_phy_config(1, smi0);
}

void ethernet_server_full(mii_interface_full_t &m,
                          smi_interface_t &?smi,
                          char mac_address[],
                          chanend rx[],
                          int num_rx,
                          chanend tx[],
                          int num_tx)
{
  streaming chan c[1];
  mii_init_full(m);
  init_mii_mem();
  par {
    // These tasks all communicate internally via shared memory
    // packet queues
    mii_rx_pins(m.p_mii_rxdv, m.p_mii_rxd, 0, c[0]);
    mii_tx_pins(m.p_mii_txd, 0);
    ethernet_tx_server(mac_address, tx, 1, num_tx, smi, null);
    ethernet_rx_server(rx, num_rx);
    ethernet_filter(mac_address, c);
  }
}
#endif

#if (NUM_ETHERNET_MASTER_PORTS == 2)
void ethernet_server_full_two_port(mii_interface_full_t &mii1,
                                   mii_interface_full_t &mii2,
                                   smi_interface_t &?smi1,
                                   smi_interface_t &?smi2,
                                   char mac_address[],
                                   chanend rx[],
                                   int num_rx,
                                   chanend tx[],
                                   int num_tx)
{
  streaming chan c[2];
  mii_init_full(mii1);
  mii_init_full(mii2);
  init_mii_mem();
  par {
    mii_rx_pins(mii1.p_mii_rxdv, mii1.p_mii_rxd, 0, c[0]);
    mii_tx_pins(mii1.p_mii_txd, 0);
    mii_rx_pins(mii2.p_mii_rxdv, mii2.p_mii_rxd, 1, c[1]);
    mii_tx_pins(mii2.p_mii_txd, 1);
    ethernet_tx_server(mac_address, tx, 2, num_tx, smi1, null);
    ethernet_rx_server(rx, num_rx);
    ethernet_filter(mac_address, c);
  }
}
#endif

