#ifndef __phy_reset_h__
#define __phy_reset_h__
#include "platform.h"
#ifdef __ethernet_board_conf_h_exists__
#include "ethernet_board_conf.h"
#endif
#include "ethernet_conf_derived.h"

#if !defined(PORT_ETH_RST_N) && defined(PORT_ETH_RSTN)
#define PORT_ETH_RST_N PORT_ETH_RSTN
#endif

#ifdef PORT_ETH_RST_N
#ifdef __XC__
typedef out port ethernet_reset_interface_t;
#define ETHERNET_DEFAULT_RESET_INTERFACE_INIT PORT_ETH_RST_N
void eth_phy_reset(ethernet_reset_interface_t eth_rst);
#endif
#else
typedef int ethernet_reset_interface_t;
#define ETHERNET_DEFAULT_RESET_INTERFACE_INIT 0
inline void eth_phy_reset(ethernet_reset_interface_t eth_rst) {}
#endif



#endif // __phy_reset_h__
