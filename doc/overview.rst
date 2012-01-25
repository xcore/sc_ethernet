Etehrnet Overview
=================

Two independent ethernet components are available in this repository.

The first implementation runs in 5 threads that provides both MII
communication to the PHY and MAC transport layer for ethernet packets.
It enables several clients to connet to it and send and receive
packets. The custom filter mechanism lets user place code into the
MAC to filter out and distribute packets in arbitrary ways. In addition
the MII layer will accurately timestamp packets on ingress and egress
and pass this information through the MAC to the ethernet client.

The code supports one or two PHY devices, both connected to the same
xcore.

The second implementation run in one thread, plus an interrupt handler
which runs in the context of a second thread.  It is lightweight, and
leaves the transmit buffering up to the client.  It also supports
timestamping of both received and transmitted packets.  This implementation
will only run when the MII thread has 62.5 MIPS of available processing
capacity.

A server is available which adds a second thread to the one thread
implementation, making the interface similar to the 5 thread implementation.

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
 | XMOS Desktop Tools            | v10.4 or later                    |  
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
