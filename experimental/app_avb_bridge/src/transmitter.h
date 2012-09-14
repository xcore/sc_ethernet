// Copyright (c) 2012, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

void transmitter(streaming chanend qTransmit,
                 chanend cOutLeft, chanend cOutRight);

#define GO_LEFT           0
#define GO_RIGHT 0x80000000
