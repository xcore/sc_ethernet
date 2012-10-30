#ifndef __mac_filter_h__
#define __mac_filter_h__

#include "ethernet_conf_derived.h"

#ifdef ETHERNET_CUSTOM_FILTER_HEADER
#include ETHERNET_CUSTOM_FILTER_HEADER
#else
#ifdef __mac_custom_filter_h_exists__
#include "mac_custom_filter.h"
#else
int mac_custom_filter(unsigned int buf[]) {
  return 0xffffffff;
}
#endif
#endif

#endif //__mac_filter_h__
