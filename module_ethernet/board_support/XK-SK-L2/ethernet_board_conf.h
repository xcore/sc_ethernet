#ifndef __ethernet_board_defaults_h__
#define __ethernet_board_defaults_h__

#ifdef __ethernet_conf_h_exists_
#include "ethernet_conf.h"
#endif


#define ETHERNET_DEFAULT_PHY_ADDRESS 0


// This file will set the various port defines depending on which slot the
// ethernet slice is connected to

#if defined(ETHERNET_USE_SQUARE_WHITE_SLOT)

#define ETHERNET_DEFAULT_TILE tile[0]
#define PORT_ETH_RXCLK on stdcore[0]: XS1_PORT_1J
#define PORT_ETH_RXD on stdcore[0]: XS1_PORT_4E
#define PORT_ETH_TXD on stdcore[0]: XS1_PORT_4F
#define PORT_ETH_RXDV on stdcore[0]: XS1_PORT_1K
#define PORT_ETH_TXEN on stdcore[0]: XS1_PORT_1L
#define PORT_ETH_TXCLK on stdcore[0]: XS1_PORT_1I
#define PORT_ETH_MDIO on stdcore[0]: XS1_PORT_1M
#define PORT_ETH_MDC on stdcore[0]: XS1_PORT_1N
#define PORT_ETH_INT on stdcore[0]: XS1_PORT_1O
#define PORT_ETH_ERR on stdcore[0]: XS1_PORT_1P

#else
#if defined(ETHERNET_USE_SQUARE_BLACK_SLOT)

#define ETHERNET_DEFAULT_TILE tile[0]
#define PORT_ETH_RXCLK on stdcore[0]: XS1_PORT_1B
#define PORT_ETH_RXD on stdcore[0]: XS1_PORT_4A
#define PORT_ETH_TXD on stdcore[0]: XS1_PORT_4B
#define PORT_ETH_RXDV on stdcore[0]: XS1_PORT_1C
#define PORT_ETH_TXEN on stdcore[0]: XS1_PORT_1F
#define PORT_ETH_TXCLK on stdcore[0]: XS1_PORT_1G
#define PORT_ETH_MDIOC on stdcore[0]: XS1_PORT_4C
#define PORT_ETH_MDIOFAKE on stdcore[0]: XS1_PORT_8A
#define PORT_ETH_INT_ERR on stdcore[0]: XS1_PORT_4D

#else
#if defined(ETHERNET_USE_TRIANGLE_WHITE_SLOT)

#define ETHERNET_DEFAULT_TILE tile[1]
#define PORT_ETH_RXCLK on stdcore[1]: XS1_PORT_1J
#define PORT_ETH_RXD on stdcore[1]: XS1_PORT_4E
#define PORT_ETH_TXD on stdcore[1]: XS1_PORT_4F
#define PORT_ETH_RXDV on stdcore[1]: XS1_PORT_1K
#define PORT_ETH_TXEN on stdcore[1]: XS1_PORT_1L
#define PORT_ETH_TXCLK on stdcore[1]: XS1_PORT_1I
#define PORT_ETH_MDIOC on stdcore[1]: XS1_PORT_8D
#define PORT_ETH_MDIO on stdcore[1]: XS1_PORT_1M
#define PORT_ETH_MDC on stdcore[1]: XS1_PORT_1N
#define PORT_ETH_INT on stdcore[1]: XS1_PORT_1O
#define PORT_ETH_ERR on stdcore[1]: XS1_PORT_1P

#else
#if defined(ETHERNET_USE_TRIANGLE_BLACK_SLOT)

#define ETHERNET_DEFAULT_TILE tile[1]
#define PORT_ETH_RXCLK on stdcore[1]: XS1_PORT_1B
#define PORT_ETH_RXD on stdcore[1]: XS1_PORT_4A
#define PORT_ETH_TXD on stdcore[1]: XS1_PORT_4B
#define PORT_ETH_RXDV on stdcore[1]: XS1_PORT_1C
#define PORT_ETH_TXEN on stdcore[1]: XS1_PORT_1F
#define PORT_ETH_TXCLK on stdcore[1]: XS1_PORT_1G
#define PORT_ETH_MDIOC on stdcore[1]: XS1_PORT_4C
#define PORT_ETH_MDIOFAKE on stdcore[1]: XS1_PORT_8A
#define PORT_ETH_INT_ERR on stdcore[1]: XS1_PORT_4D

#else
// Default to SQUARE_WHITE

#define ETHERNET_DEFAULT_TILE tile[0]
#define PORT_ETH_RXCLK on stdcore[0]: XS1_PORT_1J
#define PORT_ETH_RXD on stdcore[0]: XS1_PORT_4E
#define PORT_ETH_TXD on stdcore[0]: XS1_PORT_4F
#define PORT_ETH_RXDV on stdcore[0]: XS1_PORT_1K
#define PORT_ETH_TXEN on stdcore[0]: XS1_PORT_1L
#define PORT_ETH_TXCLK on stdcore[0]: XS1_PORT_1I
#define PORT_ETH_MDIO on stdcore[0]: XS1_PORT_1M
#define PORT_ETH_MDC on stdcore[0]: XS1_PORT_1N
#define PORT_ETH_INT on stdcore[0]: XS1_PORT_1O
#define PORT_ETH_ERR on stdcore[0]: XS1_PORT_1P

#endif
#endif
#endif
#endif

#endif // __ethernet_board_defaults_h__
