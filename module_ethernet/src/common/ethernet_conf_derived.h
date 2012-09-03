#ifndef __ethernet_conf_derived_h__
#define __ethernet_conf_derived_h__
#include "platform.h"

#ifdef __ethernet_conf_h_exists__
#include "ethernet_conf.h"
#endif

#ifdef __ethernet_board_conf_h_exists__
#include "ethernet_board_conf.h"
#endif

#ifdef __xtcp_conf_derived_h_exists__
#include "xtcp_conf_derived.h"
#endif

#if !defined(ETHERNET_DEFAULT_IMPLEMENTATION)
#define ETHERNET_DEFAULT_IMPLEMENTATION lite
#endif

#ifndef ADD_SUFFIX
#define _ADD_SUFFIX(A,B) A ## _ ## B
#define ADD_SUFFIX(A,B) _ADD_SUFFIX(A,B)
#endif

#define ETHERNET_is_full_full 1

#define ETHERNET_DEFAULT_IMPLEMENTATION_IS_FULL ADD_SUFFIX(ETHERNET_is_full,ETHERNET_DEFAULT_IMPLEMENTATION)

#ifndef ETHERNET_ENABLE_FULL_TIMINGS
#define ETHERNET_ENABLE_FULL_TIMINGS ETHERNET_DEFAULT_IMPLEMENTATION_IS_FULL
#endif


#if !defined(PORT_ETH_RST_N) && defined(PORT_ETH_RSTN)
#define PORT_ETH_RST_N PORT_ETH_RSTN
#endif


#ifndef ETHERNET_DEFAULT_PHY_ADDRESS
   #define ETHERNET_DEFAULT_PHY_ADDRESS (0x0)
#endif


#ifndef ETHERNET_DEFAULT_CLKBLK_0
#define ETHERNET_DEFAULT_CLKBLK_0 XS1_CLKBLK_1
#endif

#ifndef ETHERNET_DEFAULT_CLKBLK_1
#define ETHERNET_DEFAULT_CLKBLK_1 XS1_CLKBLK_2
#endif

#if !defined(PORT_ETH_MDIO) && defined(PORT_ETH_RST_N_MDIO)
#define PORT_ETH_MDIO PORT_ETH_RST_N_MDIO
#endif

#if !defined(PORT_ETH_ERR) && defined(PORT_ETH_RXER)
#define PORT_ETH_ERR PORT_ETH_RXER
#endif

#ifndef PORT_ETH_FAKE
#define PORT_ETH_FAKE XS1_PORT_8C
#endif


#endif // __ethernet_conf_derived_h__
