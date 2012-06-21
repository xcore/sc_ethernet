#ifndef __ethernet_derived_conf_h__
#define __ethernet_derived_conf_h__

#ifdef __ethernet_conf_h_exists__
#include "ethernet_conf.h"
#endif

#ifdef __ethernet_board_defaults_h_exists__
#include "ethernet_board_defaults.h"
#endif

#ifdef __xtcp_client_conf_h_exists__
#include "xtcp_client_conf.h"
#endif

#if !defined(ETHERNET_USE_LITE) && defined(UIP_USE_SINGLE_THREADED_ETHERNET)
#define ETHERNET_USE_LITE 1
#endif

#if !defined(ETHERNET_USE_LITE) && !defined(ETHERNET_USE_FULL)
#define ETHERNET_USE_FULL 1
#endif




#endif // __ethernet_derived_conf_h__
