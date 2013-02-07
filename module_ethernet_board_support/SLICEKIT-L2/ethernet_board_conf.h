#ifndef __ethernet_board_defaults_h__
#define __ethernet_board_defaults_h__

#ifdef __ethernet_conf_h_exists__
#include "ethernet_conf.h"
#endif

#define ETHERNET_DEFAULT_PHY_ADDRESS 0

// This file will set the various port defines depending on which slot the
// ethernet slice is connected to

#if defined(ETHERNET_USE_STAR_SLOT)
#define SMI_COMBINE_MDC_MDIO 1
#define SMI_MDC_BIT 0
#define SMI_MDIO_BIT 1
#define ETHERNET_DEFAULT_TILE tile[0]
#define PORT_ETH_RXCLK on tile[0]: XS1_PORT_1B
#define PORT_ETH_RXD on tile[0]: XS1_PORT_4A
#define PORT_ETH_TXD on tile[0]: XS1_PORT_4B
#define PORT_ETH_RXDV on tile[0]: XS1_PORT_1C
#define PORT_ETH_TXEN on tile[0]: XS1_PORT_1F
#define PORT_ETH_TXCLK on tile[0]: XS1_PORT_1G
#define PORT_ETH_MDIOC on tile[0]: XS1_PORT_4C
#define PORT_ETH_MDIOFAKE on tile[0]: XS1_PORT_8A
#define PORT_ETH_ERR on tile[0]: XS1_PORT_4D


#else
#if defined(ETHERNET_USE_TRIANGLE_SLOT)
#define ETHERNET_DEFAULT_TILE tile[0]
#define PORT_ETH_RXCLK on tile[0]: XS1_PORT_1J
#define PORT_ETH_RXD on tile[0]: XS1_PORT_4E
#define PORT_ETH_TXD on tile[0]: XS1_PORT_4F
#define PORT_ETH_RXDV on tile[0]: XS1_PORT_1K
#define PORT_ETH_TXEN on tile[0]: XS1_PORT_1L
#define PORT_ETH_TXCLK on tile[0]: XS1_PORT_1I
#define PORT_ETH_MDIO on tile[0]: XS1_PORT_1M
#define PORT_ETH_MDC on tile[0]: XS1_PORT_1N
#define PORT_ETH_INT on tile[0]: XS1_PORT_1O
#define PORT_ETH_ERR on tile[0]: XS1_PORT_1P

#else
#if defined(ETHERNET_USE_CIRCLE_SLOT)
#define ETHERNET_DEFAULT_TILE tile[1]
#define PORT_ETH_RXCLK on tile[1]: XS1_PORT_1J
#define PORT_ETH_RXD on tile[1]: XS1_PORT_4E
#define PORT_ETH_TXD on tile[1]: XS1_PORT_4F
#define PORT_ETH_RXDV on tile[1]: XS1_PORT_1K
#define PORT_ETH_TXEN on tile[1]: XS1_PORT_1L
#define PORT_ETH_TXCLK on tile[1]: XS1_PORT_1I
#define PORT_ETH_MDIO on tile[1]: XS1_PORT_1M
#define PORT_ETH_MDC on tile[1]: XS1_PORT_1N
#define PORT_ETH_INT on tile[1]: XS1_PORT_1O
#define PORT_ETH_ERR on tile[1]: XS1_PORT_1P

#else
#if defined(ETHERNET_USE_SQUARE_SLOT)
#define SMI_COMBINE_MDC_MDIO 1
#define SMI_MDC_BIT 0
#define SMI_MDIO_BIT 1
#define ETHERNET_DEFAULT_TILE tile[1]
#define PORT_ETH_RXCLK on tile[1]: XS1_PORT_1B
#define PORT_ETH_RXD on tile[1]: XS1_PORT_4A
#define PORT_ETH_TXD on tile[1]: XS1_PORT_4B
#define PORT_ETH_RXDV on tile[1]: XS1_PORT_1C
#define PORT_ETH_TXEN on tile[1]: XS1_PORT_1F
#define PORT_ETH_TXCLK on tile[1]: XS1_PORT_1G
#define PORT_ETH_MDIOC on tile[1]: XS1_PORT_4C
#define PORT_ETH_MDIOFAKE on tile[1]: XS1_PORT_8A
#define PORT_ETH_ERR on tile[1]: XS1_PORT_4D

#else
// Default to CIRCLE

#define ETHERNET_DEFAULT_TILE tile[1]
#define PORT_ETH_RXCLK on tile[1]: XS1_PORT_1J
#define PORT_ETH_RXD on tile[1]: XS1_PORT_4E
#define PORT_ETH_TXD on tile[1]: XS1_PORT_4F
#define PORT_ETH_RXDV on tile[1]: XS1_PORT_1K
#define PORT_ETH_TXEN on tile[1]: XS1_PORT_1L
#define PORT_ETH_TXCLK on tile[1]: XS1_PORT_1I
#define PORT_ETH_MDIO on tile[1]: XS1_PORT_1M
#define PORT_ETH_MDC on tile[1]: XS1_PORT_1N
#define PORT_ETH_INT on tile[1]: XS1_PORT_1O
#define PORT_ETH_ERR on tile[1]: XS1_PORT_1P


#endif
#endif
#endif
#endif

#endif // __ethernet_board_defaults_h__
