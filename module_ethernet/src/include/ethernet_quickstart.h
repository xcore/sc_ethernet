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

#ifndef ETH_QUICKSTART_ETHERNET_INTERFACE
#ifdef PORT_ETH_RXCLK_1
#warning ETH_QUICKSTART_ETHERNET_INTERFACE not defined, assuming interface 1
#endif
#define ETH_QUICKSTART_ETHERNET_INTERFACE 1
#endif


#ifndef ETHERNET_USE_FULL
#ifndef ETH_QUICKSTART_PORT_ETH_FAKE
#define ETH_QUICKSTART_PORT_ETH_FAKE XS1_PORT_8C
#endif
#else
#define ETH_QUICKSTART_PORT_ETH_FAKE
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

#if !defined(PORT_ETH_RXCLK_0) && defined(PORT_ETH_RXCLK)
#define I(x) x
#else
#define III(x,y) x ## _ ## y
#define II(x,y) III(x,y)
#define I(x) II(x,ETH_QUICKSTART_ETHERNET_INTERFACE)
#endif

#define ETH_QUICKSTART_OTP_PORTS_INIT { \
    XS1_PORT_32B, \
    XS1_PORT_16C, \
    XS1_PORT_16D \
 };

#define ETH_QUICKSTART_MII_INIT { \
  ETH_QUICKSTART_CLKBLK_0, \
  ETH_QUICKSTART_CLKBLK_1, \
\
  I(PORT_ETH_RXCLK), \
  I(PORT_ETH_ERR), \
  I(PORT_ETH_RXD), \
  I(PORT_ETH_RXDV), \
  I(PORT_ETH_TXCLK), \
  I(PORT_ETH_TXEN), \
  I(PORT_ETH_TXD), \
  ETH_QUICKSTART_PORT_ETH_FAKE \
};


#define ETH_QUICKSTART_SMI_INIT {ETH_QUICKSTART_PHY_ADDRESS, \
                                 I(PORT_ETH_MDIO), \
                                 I(PORT_ETH_MDC)};

#endif // __ethernet_quickstart_h__
