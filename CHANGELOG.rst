XCORE.com ETHERNET Changelog
======================

:Version:   2.0.0

Firmware
=======

module_ethernet
----------------------

2.0.2
-----
   * Fix for buffer overflow errors
   * Fix for jabber-type error when terminating frame reception early

2.0.1
-----
   * Fix up makefiles to work with new tools

2.0.0
-----

   * Memory based locking protocol or hardware locking
   * FIFO based memory allocation for lower RAM overhead
   * High priority (VLAN priority tag) queues
   * 802.1Qat traffic shaping
   * Dual port
   * Optional statistics gathering
   * Fixed max_queue_size default size bug that was causing packets to be dropped
   * Re-added RX CRC check

1.4.0
-----

   * Initial complete implementation

