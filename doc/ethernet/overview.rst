Ethernet Layer 2 MAC Overview
=============================

The layer 2 MAC component implements a layer 2 ethernet MAC. It
provides both MII communication to the PHY and MAC transport layer for
ethernet packets and enables several clients to connect
to it and send and receive
packets.

Two independent implementations are available. The FULL implementation
runs on 5 logical cores, allows multiple clients with
independent buffering per client and supports accurate packet
timestamping, priority
queuing, and 802.1Qav traffic shaping. The LITE implementation runs on two
logical cores but is resricted to a single receive and trasnmit client
and does not support any advanced features.

Component Summary
+++++++++++++++++

.. table::
 :class: vertical-borders

 +-------------------------------------------------------------------+
 |                        **Functionality**                          |
 +-------------------------------------------------------------------+
 +-------------------------------------------------------------------+
 |  Provides MII ethernet interface and MAC with customizable        |
 |  filtering and accurate packet timestamping.                      |
 +-------------------------------------------------------------------+
 +-------------------------------------------------------------------+
 |                       **Supported Standards**                     |
 +-------------------------------------------------------------------+
 +-------------------------------+-----------------------------------+
 | Ethernet                      | IEEE 802.3u (MII)                 |
 +-------------------------------+-----------------------------------+
 +-------------------------------------------------------------------+
 |                       **Supported Devices**                       |
 +-------------------------------------------------------------------+
 +-------------------------------+-----------------------------------+
 | XMOS Devices                  | XS1-G4                            |
 +-------------------------------+-----------------------------------+
 |                               | XS1-L2                            |
 +-------------------------------+-----------------------------------+
 |                               | XS1-L1                            |
 +-------------------------------+-----------------------------------+
 +-------------------------------------------------------------------+
 |                       **Requirements**                            |
 +-------------------------------------------------------------------+
 +-------------------------------+-----------------------------------+
 | XMOS Desktop Tools            | v12.0 or later                    |
 +-------------------------------+-----------------------------------+
 | Ethernet                      | MII compatible 100Mbit PHY        |
 +-------------------------------+-----------------------------------+
 +-------------------------------------------------------------------+
 |                       **Licensing and Support**                   |
 +-------------------------------------------------------------------+
 +-------------------------------------------------------------------+
 | Component code provided without charge from XMOS.                 |
 | Component code is maintained by XMOS.                             |
 +-------------------------------------------------------------------+
