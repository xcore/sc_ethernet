#ifndef __ethernet__h__
#define __ethernet__h__

#include "ethernet_conf_derived.h"
#include "platform.h"
#include "mii.h"
#include "smi.h"

#ifndef ETHERNET_DEFAULT_TILE
  #define ETHERNET_DEFAULT_TILE tile[0]
#endif

// Ethernet Ports
#define ETHERNET_DEFAULT_MII_INIT_full { \
  ETHERNET_DEFAULT_CLKBLK_0, \
  ETHERNET_DEFAULT_CLKBLK_1, \
\
    PORT_ETH_RXCLK,                             \
    PORT_ETH_ERR,                               \
    PORT_ETH_RXD,                               \
    PORT_ETH_RXDV,                              \
    PORT_ETH_TXCLK,                             \
    PORT_ETH_TXEN,                              \
    PORT_ETH_TXD \
}

#define ETHERNET_DEFAULT_MII_INIT_lite { \
  ETHERNET_DEFAULT_CLKBLK_0, \
  ETHERNET_DEFAULT_CLKBLK_1, \
\
    PORT_ETH_RXCLK,                             \
    PORT_ETH_ERR,                               \
    PORT_ETH_RXD,                               \
    PORT_ETH_RXDV,                              \
    PORT_ETH_TXCLK,                             \
    PORT_ETH_TXEN,                              \
    PORT_ETH_TXD,                               \
    PORT_ETH_FAKE \
}


#define ETHERNET_DEFAULT_MII_INIT ADD_SUFFIX(ETHERNET_DEFAULT_MII_INIT,ETHERNET_DEFAULT_IMPLEMENTATION)


#if SMI_COMBINE_MDC_MDIO
#define ETHERNET_DEFAULT_SMI_INIT {ETHERNET_DEFAULT_PHY_ADDRESS, \
                                   PORT_ETH_MDIOC}
#else
#define ETHERNET_DEFAULT_SMI_INIT {ETHERNET_DEFAULT_PHY_ADDRESS, \
                                   PORT_ETH_MDIO,       \
                                   PORT_ETH_MDC}
#endif


#include "ethernet_server.h"
#include "ethernet_rx_client.h"
#include "ethernet_tx_client.h"
#include "ethernet_phy_reset.h"
#endif // __ethernet__h__
