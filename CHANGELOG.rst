sc_ethernet Change Log
======================

2.3.0
-----
  * Initial Version  * Adds AVB-DC support to sc_ethernet

  * Changes to dependencies:

    - sc_util: 1.0.3rc0 -> 1.0.4rc0

      + module_logging now compiled at -Os
      + debug_printf in module_logging uses a buffer to deliver messages unfragmented
      + Fix thread local storage calculation bug in libtrycatch
      + Fix debug_printf itoa to work for unsigned values > 0x80000000

    - sc_slicekit_support: 1.0.4rc0 -> 1.0.3rc0

      + Moved from sc_util
      + Fix code that assumes tile[0] gets node ide 0
      + Fix module_slicekit_support to work with L16 target
      + No change to slicekit support (changes to sc_util where module
      + Initial Version

2.2.7
-----
  * Initial Version  * Fix buffering bug on full implementation that caused crash under
    heavy load
  * Various documentation updates

  * Changes to dependencies:

    - sc_slicekit_support: 1.0.3rc0 -> 1.0.4rc0

      + Fix to the metainfo.

2.2.6
-----
  * Initial Version  * Minor bug fixes in metainformation and support headers

2.2.5
-----
  * Initial Version  * Fixed timing issue in MII rx pins to work across different tools
    versions
  * Moved to version 1.0.3 of module_slicekit_support
  * Fixed issue with MII receive buffering that could cause a crash if a packet was dropped

  * Changes to dependencies:

    - sc_util: 1.0.2rc0 -> 1.0.3rc0

      + Remove module_slicekit_support (moved to sc_slicekit_support)
      + Update mutual_thread_comm library to avoid communication race conditions

2.2.4
-----
  * Initial Version  * Fixed timing issues in MII rx pins for cores running at 50 mips
    (with no high priority queue)
  * Improved performance MII tx pin handling code
  * Added board support for DSP4YOU module

2.2.3
-----
  * Initial Version  * Fixed bug in handling SMI_HANDLE_COMBINED_PORTS define
  * Added board support for SLICEKIT-L16 and XP-MC-CTRL-L2 board
  * Moved to newer version of module_locks (now from sc_util repository)

2.2.2
-----
  * Initial Version  * Added timer offset retrieval feature to support AVB
  * XC-2 suport fixed

2.2.1
-----
  * Initial Version  * Minor fix to example apps (ports structures should be declared on
    a specific tile)

2.2.0
-----
  * Initial Version  * Rearranged source code
  * Combined "full" and "lite" versions
  * Added quickstart initializers and board support code

2.1.2
-----
  * Initial Version  * Fix for ethernet buffering errors

2.1.1
-----
  * Initial Version   * Updated documentation and packaging for tools compatibility

2.1.0
-----
  * Initial Version   * Single thread MII driver interface added
   * Interface thread to make single thread MII driver similar to 5 thread interface
   * Reduced memory footprint

2.0.2
-----
  * Initial Version   * Fix for buffer overflow errors
   * Fix for jabber-type error when terminating frame reception early

2.0.1
-----
  * Initial Version   * Fix up makefiles to work with new tools

2.0.0
-----
  * Initial Version
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
  * Initial Version
   * Initial complete implementation
