#ifndef __ethernet_conf_derived_h__
#define __ethernet_conf_derived_h__
#include "platform.h"

#ifdef __ethernet_conf_h_exists__
#include "ethernet_conf.h"
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

#if !defined(ETHERNET_RX_BUFSIZE) && defined(MII_RX_BUFSIZE)
#define ETHERNET_RX_BUFSIZE MII_RX_BUFSIZE
#endif

#if !defined(ETHERNET_RX_BUFSIZE_LOW_PRIORITY) && defined(MII_RX_BUFSIZE_LOW_PRIORITY)
#define ETHERNET_RX_BUFSIZE_LOW_PRIORITY MII_RX_BUFSIZE_LOW_PRIORITY
#endif

#if !defined(ETHERNET_RX_BUFSIZE_HIGH_PRIORITY) && defined(MII_RX_BUFSIZE_HIGH_PRIORITY)
#define ETHERNET_RX_BUFSIZE_HIGH_PRIORITY MII_RX_BUFSIZE_HIGH_PRIORITY
#endif

#if !defined(ETHERNET_TX_BUFSIZE) && defined(MII_TX_BUFSIZE)
#define ETHERNET_TX_BUFSIZE MII_TX_BUFSIZE
#endif

#if !defined(ETHERNET_TX_BUFSIZE_LOW_PRIORITY) && defined(MII_TX_BUFSIZE_LOW_PRIORITY)
#define ETHERNET_TX_BUFSIZE_LOW_PRIORITY MII_TX_BUFSIZE_LOW_PRIORITY
#endif

#if !defined(ETHERNET_TX_BUFSIZE_HIGH_PRIORITY) && defined(MII_TX_BUFSIZE_HIGH_PRIORITY)
#define ETHERNET_TX_BUFSIZE_HIGH_PRIORITY MII_TX_BUFSIZE_HIGH_PRIORITY
#endif


#endif // __ethernet_conf_derived_h__
