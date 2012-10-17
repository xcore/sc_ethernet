#ifndef __ethernet_board_support_h__
#define __ethernet_board_support_h__

#include "platform.h"

// This header file provides default port intializers for the ethernet
// for XMOS development boards, it gets the board specific defines from
// ethernet_board_conf.h which is in a board specific directory in this module
// (e.g. module_ethernet_board_support/XR-AVB-LC-BRD)

#ifdef __ethernet_board_conf_h_exists__
#include "ethernet_board_conf.h"

#include "ethernet_conf_derived.h"


#if !defined(PORT_ETH_RST_N) && defined(PORT_ETH_RSTN)
#define PORT_ETH_RST_N PORT_ETH_RSTN
#endif

#ifndef ETHERNET_DEFAULT_CLKBLK_0
#define ETHERNET_DEFAULT_CLKBLK_0 on ETHERNET_DEFAULT_TILE: XS1_CLKBLK_1
#endif

#ifndef ETHERNET_DEFAULT_CLKBLK_1
#define ETHERNET_DEFAULT_CLKBLK_1 on ETHERNET_DEFAULT_TILE: XS1_CLKBLK_2
#endif

#if !defined(PORT_ETH_MDIO) && defined(PORT_ETH_RST_N_MDIO)
#define PORT_ETH_MDIO PORT_ETH_RST_N_MDIO
#endif

#if !defined(PORT_ETH_ERR) && defined(PORT_ETH_RXER)
#define PORT_ETH_ERR PORT_ETH_RXER
#endif

#ifndef PORT_ETH_FAKE
#define PORT_ETH_FAKE on ETHERNET_DEFAULT_TILE: XS1_PORT_8C
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


#else
#warning "Using ethernet_board_conf.h but TARGET is not set to a board that module_ethernet_board_support uses"
#endif

#endif // __ethernet_board_support_h__
