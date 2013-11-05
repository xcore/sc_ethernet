#ifdef __ethernet_conf_h_exists__
#include "ethernet_conf.h"
#endif

#if (NUM_ETHERNET_PORTS == 1) && !defined(ETHERNET_USE_STAR_SLOT) && !defined(ETHERNET_USE_TRIANGLE_SLOT) && !defined(ETHERNET_USE_CIRCLE_SLOT) && !defined(ETHERNET_USE_SQUARE_SLOT)
#warning No define of form ETHERNET_USE_{STAR|TRIANGLE|CIRCLE|SQUARE}_SLOT found in ethernet_conf.h
#warning Assuming ETHERNET_USE_CIRCLE_SLOT
#endif
