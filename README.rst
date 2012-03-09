XCORE.com ETHERNET SOFTWARE COMPONENT
.................................

:Latest release: 2.1.1rc1
:Maintainer: DavidNorman
:Description: A complete Ethernet MII and MAC interface for 100MBps Ethernet





Key Features
============

   * RX and TX in separate threads
   * Packet filtering by extension function
   * Memory based locking protocol
   * FIFO based memory allocation for lower RAM overhead
   * High priority (VLAN priority tag) queues
   * 802.1Qat traffic shaping
   * Dual port

Firmware Overview
=================

RX and TX are defined as functions which each run in their own thread. Thread count is 5 for single
port, and 7 for dual port support.  Both ports must be MII and attached to the same xcore.

Full documentation can be found at http://xcore.github.com/sc_ethernet/

Known Issues
============

   * The rx_packet-rx_packet timing constraint may fail because of the user defined packet filters. The user
     is required to fill in the timing details inside any user specified filter in order to help the XTA
     analyze the receive filter timing correctly.

Support
=======

Issues may be submitted via the Issues tab in this github repo. Response to any issues submitted as at the discretion of the maintainer for this line.

Required software (dependencies)
================================

  * xcommon (if using development tools earlier than 11.11.0)

