// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "mii_full.h"
#include "mii_queue.h"
#include "mii_malloc.h"

int mac_custom_filter_coerce1(unsigned int buf[]);

int mac_custom_filter_coerce(int buf0) {
  mii_packet_t *buf = (mii_packet_t *) buf0;
  int ret = mac_custom_filter_coerce1(buf->data);
  return ret;
}
