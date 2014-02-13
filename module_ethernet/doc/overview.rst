Ethernet layer 2 MAC overview
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
logical cores but is restricted to a single receive and trasnmit client
and does not support any advanced features.

Component summary
-----------------

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

Performance Summary
-------------------

The ethernet software block has two implementations: the "FULL" version which is high performance and has features to support Ethernet AVB and uses five logical cores or the "LITE" version which is lower perfomance but only uses two logical cores and is still suitable for many ethernet control applications.

The Full version of this module can achieve 10/100 line rate assuming that the client application is also capable of sustaining line rate. The Lite version shares resources for transmit and receive so will fall below line rate to a degree which is application dependant.

The following attributes are common to both Full and Lite Versions

----------------------------- ------ ------
Attribute                     Min    Max

Receive buffer                512    30000
Transmit buffer               512    30000
Number of Receive Clients     1      8
Number of Transmit Clients    1      8
----------------------------- ------ ------

Resource Usage
--------------

--------------- -----------------------------------
Resource        Usage
=============== ===================================
1-bit ports     8
4-bit ports     2
Clock Blocks    2
Channelends     8 + num_tx_clients +num_rx_clients
Timers          2
memory          10 KB
--------------- -----------------------------------

