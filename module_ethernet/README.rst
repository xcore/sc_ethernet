Layer 2 Ethernet MAC
====================

:scope: General Use
:description: MII interface and L2 ethernet MAC
:keywords: ethernet, mii, mac

This module contains the code for a low level ethernet interface over MII.
It has two versions: the "FULL" version which is high performance and has
features to support Ethernet AVB and uses five logical cores or the
"LITE" version which is lower perfomance but only uses two logical
cores and is still suitable for many ethernet control applications.

This module does *not* include a layer 3 TCP/IP stack. Software blocks
for that function can be found in the sc_xtcp package.

The usage of this module is fully documented in the sc_ethernet package
documentation.



