// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef __ethernet_rx_client_h__
#define __ethernet_rx_client_h__

#include "ethernet_derived_conf.h"

#ifdef ETHERNET_USE_FULL
#include "ethernet_rx_client_full.h"
#else
#include "ethernet_rx_client_lite.h"
#endif

#endif
