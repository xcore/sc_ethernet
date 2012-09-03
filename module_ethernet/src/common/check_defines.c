#ifdef __ethernet_conf_h_exists__
#include "ethernet_conf.h"
#endif

#ifdef __ethernet_board_conf_h_exists__
#include "ethernet_board_conf.h"
#endif

#ifndef ETHERNET_DEFAULT_TILE
  #warning ETHERNET_DEFAULT_TILE not defined, assuming tile[0]
#endif

#ifndef ETHERNET_DEFAULT_PHY_ADDRESS
  #warning ETHERNET_DEFAULT_PHY_ADDRESS not defined, assuming 0x0
#endif
