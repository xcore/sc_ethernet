Overview
========

The XMOS ethernet component provides both MII communication to the phy
and MAC transport layer for ethernet packets. It enables several
clients to connet to it and send and receive packets. The custom
filter mechanism lets user place code into the MAC to filter out and
distribute packets in arbitrary ways. In addition the MII layer will
accurately timestamp packets on ingress and egress and pass this
information through the MAC to the ethernet client.

The code supports one or two PHY devices, both connected to the same
xcore.  Currently there is no inter-port packet forwarding supported.

Component Summary
+++++++++++++++++

 +-------------------------------------------------------------------+
 |                        **Functionality**                          |
 +-------------------------------------------------------------------+
 |  Provides MII ethernet interface and MAC with customizable        |
 |  filtering and accurate packet timestamping.                      |
 +-------------------------------------------------------------------+
 |                       **Supported Standards**                     |
 +-------------------------------+-----------------------------------+
 | Ethernet                      | IEEE 802.3u (MII)                 |
 +-------------------------------+-----------------------------------+
 |                       **Supported Devices**                       |
 +-------------------------------+-----------------------------------+
 | XMOS Devices                  | | XS1-G4                          | 
 |                               | | XS1-L2                          |
 |                               | | XS1-L1                          |
 +-------------------------------+-----------------------------------+
 |                       **Requirements**                            |
 +-------------------------------+-----------------------------------+
 | XMOS Desktop Tools            | v10.4 or later                    |  
 +-------------------------------+-----------------------------------+
 | Ethernet                      | MII compatible 100Mbit PHY        |
 +-------------------------------+-----------------------------------+
 |                       **Licensing and Support**                   |
 +-------------------------------------------------------------------+
 | Component code provided without charge from XMOS.                 |
 | Component code is maintained by XMOS.                             |
 +-------------------------------------------------------------------+

module_mii_singlethread
=======================

The two subdirectories called **module_mii_singlethread** and
**app_mii_singlethread_demo** are an experimental single thread
MII controller.  The file **mii.xc** contains the definition of
the MII port pins.

The main pin control thread is hand written assembler utilising
the event branching nature of the xcore to maintain two coroutines
inside the single thread.



