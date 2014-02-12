// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "mii_full.h"
#include "mii_queue.h"
#include "mii_malloc.h"

#if ETHERNET_FILTER_ENABLE_USER_DATA
int mac_custom_filter_coerce1(unsigned int buf[], unsigned int mac[2], int *user_data);
#else
int mac_custom_filter_coerce1(unsigned int buf[], unsigned int mac[2]);
#endif

#if ETHERNET_FILTER_ENABLE_USER_DATA
int mac_custom_filter_coerce(int buf0, unsigned int mac[2], int *user_data) {
#else
int mac_custom_filter_coerce(int buf0, unsigned int mac[2]) {
#endif
  mii_packet_t *buf = (mii_packet_t *) buf0;
#if ETHERNET_FILTER_ENABLE_USER_DATA
  int ret = mac_custom_filter_coerce1(buf->data, mac, user_data);
#else
  int ret = mac_custom_filter_coerce1(buf->data, mac);
#endif
  return ret;
}
