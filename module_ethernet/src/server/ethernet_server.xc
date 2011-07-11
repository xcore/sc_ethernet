// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <mii.h>
#include <smi.h>
#include <mii_wrappers.h>
#include <mii_filter.h>
#include "eth_phy.h"


void phy_init(clock clk_smi,
              out port ?p_mii_resetn,
              smi_interface_t &smi0,
              mii_interface_t &mii0)
{
  smi_init(clk_smi, p_mii_resetn, smi0);
  smi_reset(p_mii_resetn, smi0);
  mii_init(mii0);
  eth_phy_config(1, smi0);
}


void ethernet_server(mii_interface_t &m,
                     int mac_address[],
                     chanend rx[],
                     int num_rx,
                     chanend tx[],
                     int num_tx,
                     smi_interface_t &?smi,
                     chanend ?connect_status)
{
  streaming chan c[1];
  if (NUM_ETHERNET_PORTS != 1) return;
  init_mii_mem();
  par {
    // These thrads all communicate internally via shared memory
    // packet queues
    mii_rx_pins(m.p_mii_rxdv, m.p_mii_rxd, 0, c[0]);
    mii_tx_pins(m.p_mii_txd, 0);
    ethernet_rx_server(rx, num_rx);
    ethernet_tx_server(mac_address, tx, 1, num_tx, smi, null, connect_status);  
    ethernet_filter(mac_address, c);
  }
}

void phy_init_two_port(clock clk_smi,
                       out port ?p_mii_resetn,
                       smi_interface_t &smi0,
                       smi_interface_t &smi1,
                       mii_interface_t &mii0,
                       mii_interface_t &mii1)
{
  smi_init(clk_smi, p_mii_resetn, smi0);
  smi_init(clk_smi, p_mii_resetn, smi1);
  smi_reset(p_mii_resetn, smi0);
  mii_init(mii0);
  mii_init(mii1);
  eth_phy_config(1, smi0);
  eth_phy_config(1, smi1);
}


void ethernet_server_two_port(mii_interface_t &mii1,
                              mii_interface_t &mii2,
                              int mac_address[],
                              chanend rx[],
                              int num_rx,
                              chanend tx[],
                              int num_tx,
                              smi_interface_t ?smi[2],
                              chanend ?connect_status)
{
  streaming chan cs[2];
  if (NUM_ETHERNET_PORTS != 2) return;
  init_mii_mem();
  par {
    // These threads all communicate internally via shared memory
    // packet queues
    mii_rx_pins(mii1.p_mii_rxdv, mii1.p_mii_rxd, 0, cs[0]);
    mii_tx_pins(mii1.p_mii_txd, 0);
    mii_rx_pins(mii2.p_mii_rxdv, mii2.p_mii_rxd, 1, cs[1]);
    mii_tx_pins(mii2.p_mii_txd, 1);
    ethernet_filter(mac_address, cs);
    ethernet_rx_server(rx, num_rx);
    ethernet_tx_server(mac_address, tx, 2, num_tx, smi[0], smi[1], connect_status);
  }
}
                     
