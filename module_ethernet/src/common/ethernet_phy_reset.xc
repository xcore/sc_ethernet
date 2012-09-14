#include <xs1.h>
#include "ethernet_phy_reset.h"

#ifndef ETHERNET_PHY_RESET_TIMER_TICKS
#define ETHERNET_PHY_RESET_TIMER_TICKS 100
#endif

#ifdef PORT_ETH_RST_N
void eth_phy_reset(ethernet_reset_interface_t p_eth_rst) {
  timer tmr;
  int t;
  tmr :> t;
  p_eth_rst <: 0;
  tmr when timerafter(t + ETHERNET_PHY_RESET_TIMER_TICKS) :> t;
  p_eth_rst <: 1;
}
#else
extern inline void eth_phy_reset(ethernet_reset_interface_t eth_rst);
#endif

