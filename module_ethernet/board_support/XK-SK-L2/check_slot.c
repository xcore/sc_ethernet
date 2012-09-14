#ifdef __ethernet_conf_h_exists_
#include "ethernet_conf.h"
#endif

#if !defined(ETHERNET_USE_SQUARE_WHITE_SLOT) && !defined(ETHERNET_USE_SQUARE_BLACK_SOT) && !defined(ETHERNET_USE_TRIANGLE_BLACK_SLOT) && !defined(ETHERNET_USE_TRIANGLE_WHITE_SLOT)
#warning No define of form ETHERNET_USE_{SQUARE|TRIANGLE}_{BLACK|WHITE}_SLOT found in ethernet_conf.h
#warning Assuming ETHERNET_USE_SQUARE_WHITE
#endif
