#ifndef __ethernet_derived_conf_h__
#define __ethernet_derived_conf_h__

#ifdef __ethernet_conf_h_exists__
#include "ethernet_conf.h"
#endif

#ifdef __ethernet_board_defaults_h_exists__
#include "ethernet_board_defaults.h"
#endif

#ifdef __xtcp_conf_derived_h_exists__
#include "xtcp_conf_derived.h"
#endif

#if !defined(ETHERNET_USE_LITE)
#if !XTCP_SEPARATE_MAC
#define ETHERNET_USE_LITE 1
#else
#define ETHERNET_USE_LITE 0
#endif
#endif


#if !ETHERNET_USE_LITE && !defined(ETHERNET_USE_FULL)
#define ETHERNET_USE_FULL 1
#endif




#endif // __ethernet_derived_conf_h__
