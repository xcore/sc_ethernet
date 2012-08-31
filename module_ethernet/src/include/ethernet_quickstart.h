#ifndef __ethernet_quickstart_h__
#define __ethernet_quickstart_h__

#include "ethernet_derived_conf.h"
#include "platform.h"
#include "mii.h"
#include "smi.h"

#ifndef ETH_CORE
  #ifdef BOARD_DEFAULT_ETH_CORE
    #define ETH_CORE BOARD_DEFAULT_ETH_CORE
  #else
    #warning ETH_CORE not defined, assuming core 0
    #define ETH_CORE 0
  #endif
#endif

#ifndef ETH_QUICKSTART_PHY_ADDRESS
  #ifdef BOARD_DEFAULT_PHY_ADDRESS
    #define ETH_QUICKSTART_PHY_ADDRESS BOARD_DEFAULT_PHY_ADDRESS
  #else
     #warning ETH_QUICKSTART_PHY_ADDRESS not defined, assuming 0x0
     #define ETH_QUICKSTART_PHY_ADDRESS (0x0)
  #endif
#endif

#ifndef ETH_QUICKSTART_PORT_ETH_FAKE
#define ETH_QUICKSTART_PORT_ETH_FAKE XS1_PORT_8C
#endif

#ifndef ETH_QUICKSTART_CLKBLK_0
#define ETH_QUICKSTART_CLKBLK_0 XS1_CLKBLK_1
#endif

#ifndef ETH_QUICKSTART_CLKBLK_1
#define ETH_QUICKSTART_CLKBLK_1 XS1_CLKBLK_2
#endif

// Ethernet Ports

#if !defined(PORT_ETH_MDIO) && defined(PORT_ETH_RST_N_MDIO)
#define PORT_ETH_MDIO PORT_ETH_RST_N_MDIO
#endif

#if !defined(PORT_ETH_ERR) && defined(PORT_ETH_RXER)
#define PORT_ETH_ERR PORT_ETH_RXER
#endif


#define ETH_QUICKSTART_MII_FULL_INIT { \
  ETH_QUICKSTART_CLKBLK_0, \
  ETH_QUICKSTART_CLKBLK_1, \
\
    PORT_ETH_RXCLK,                             \
    PORT_ETH_ERR,                               \
    PORT_ETH_RXD,                               \
    PORT_ETH_RXDV,                              \
    PORT_ETH_TXCLK,                             \
    PORT_ETH_TXEN,                              \
  PORT_ETH_TXD \
}

#define ETH_QUICKSTART_MII_LITE_INIT { \
  ETH_QUICKSTART_CLKBLK_0, \
  ETH_QUICKSTART_CLKBLK_1, \
\
    PORT_ETH_RXCLK,                             \
    PORT_ETH_ERR,                               \
    PORT_ETH_RXD,                               \
    PORT_ETH_RXDV,                              \
    PORT_ETH_TXCLK,                             \
    PORT_ETH_TXEN,                              \
    PORT_ETH_TXD,                               \
  ETH_QUICKSTART_PORT_ETH_FAKE \
}


#if ETHERNET_USE_FULL
#define ETH_QUICKSTART_MII_INIT ETH_QUICKSTART_MII_FULL_INIT
#else
#define ETH_QUICKSTART_MII_INIT ETH_QUICKSTART_MII_LITE_INIT
#endif


#define ETH_QUICKSTART_SMI_INIT {ETH_QUICKSTART_PHY_ADDRESS, \
                                 PORT_ETH_MDIO,       \
                                 PORT_ETH_MDC}

#endif // __ethernet_quickstart_h__
