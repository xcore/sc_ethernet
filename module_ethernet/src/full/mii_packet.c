// Copyright (c) 2012, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "mii_full.h"

// These are the non-inline implementations of the mii_packet member
// get functions

#ifdef ETHERNET_INLINE_PACKET_GET
#define create_buf_getset_external_definition(field) \
  extern inline int mii_packet_get_##field (int buf); \
  extern inline void mii_packet_set_##field (int buf, int x);
#else
#define create_buf_getset_external_definition(field) \
  int mii_packet_get_##field (int buf) \
  { \
    return ((mii_packet_t*)buf)->field; \
  } \
  extern inline void mii_packet_set_##field (int buf, int x);
#endif

create_buf_getset_external_definition(length)
create_buf_getset_external_definition(timestamp)
create_buf_getset_external_definition(filter_result)
create_buf_getset_external_definition(src_port)
create_buf_getset_external_definition(timestamp_id)
create_buf_getset_external_definition(stage)
create_buf_getset_external_definition(tcount)
create_buf_getset_external_definition(crc)
create_buf_getset_external_definition(forwarding)

extern inline int mii_packet_get_data_ptr(int buf);
extern inline void mii_packet_set_data_word(int data, int n, int v);


extern inline void mii_packet_set_data(int buf, int n, int v);
extern inline void mii_packet_set_data_short(int buf, int n, int v);
