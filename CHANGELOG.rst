Ethernet Component Change Log
=============================

2.1.2
-----
  * Fix for ethernet buffering errors

2.1.1
-----
   * Updated documentation and packaging for tools compatibility

2.1.0
-----
   * Single thread MII driver interface added
   * Interface thread to make single thread MII driver similar to 5 thread interface
   * Reduced memory footprint

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
