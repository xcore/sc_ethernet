Ethernet Component Change Log
=============================

2.2.3
-----
  * Fixed bug in handling SMI_HANDLE_COMBINED_PORTS define
  * Added board support for SLICEKIT-L16 and XP-MC-CTRL-L2 board
  * Moved to newer version of module_locks (now from sc_util repository)

2.2.2
-----
  * Added timer offset retrieval feature to support AVB
  * XC-2 suport fixed

2.2.1
-----
  * Minor fix to example apps (ports structures should be declared on
    a specific tile)

2.2.0
-----
  * Rearranged source code
  * Combined "full" and "lite" versions
  * Added quickstart initializers and board support code

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
