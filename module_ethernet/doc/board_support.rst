XMOS Development Board Support Component
========================================

The module ``module_ethernet_board_support`` provides defines to allow
you to easily use an XMOS development board. To use the module include
the following header::

    #include "ethernet_board_support.h"

The contents of this header varies depending on the ``TARGET`` defined
in your ``Makefile``.

With this header included you can intialize ethernet port structures
using the following defines::

   smi_interface_t smi = ETHERNET_DEFAULT_SMI_INIT;
   mii_interface_t mii = ETHERNET_DEFAULT_MII_INIT;
   ethernet_reset_interface_t eth_rst = ETHERNET_DEFAULT_RESET_INTERFACE_INIT;

You can also use the define ``ETHERNET_DEFAULT_TILE`` to refer to the
tile that the ethernet ports are on.

sliceKIT Core Board
-------------------

For the sliceKIT Core Board the ethernet slice could be in any of the
four slots. To choose which slot the defines refer to you can set the
define one of the following defines to be 1 in ``ethernet_conf.h``:

  *  ``ETHERNET_USE_CIRCLE_SLOT``
  *  ``ETHERNET_USE_SQUARE_SLOT``
  *  ``ETHERNET_USE_STAR_SLOT`` (Not compatible with the 1v1 Core Board)
  *  ``ETHERNET_USE_TRIANGLE_SLOT`` (Not compatible with the 1v1 Core Board)



