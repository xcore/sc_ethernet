SMI component API
=================

The module ``module_ethernet_smi``
is written to support SMI independently of the MII interface.
Typically, Ethernet PHYs are configured on reset automatically, but the SMI
interface may be useful for setting and testing register values
dynamically. 

There are two ways to interface SMI:
using a pair of 1-bit ports, or using
a single multi-bit port.

Configuration defines
---------------------
These defines can either be set in ``ethernet_conf.h`` or
``smi_conf.h`` from within your application directory.

**SMI_COMBINE_MDC_MDIO**

    This define should be set to 1 if you want to combine MDC and MDIO
    onto a single bit port.

**SMI_MDC_BIT**

    This defines the bit number on the shared port where the MDC line is.
    Only define this if you have a port that drives both MDC and MDIO.

**SMI_MDIO_BIT**

    This defines the bit number on the shared port where the MDIO line is.
    Only define this if you have a port that drives both MDC and MDIO.


Data structures
---------------

.. doxygenstruct:: smi_interface_t


Phy API
-------

.. doxygenfunction:: smi_init

.. doxygenfunction:: eth_phy_config

.. doxygenfunction:: eth_phy_config_noauto

.. doxygenfunction:: eth_phy_loopback

.. doxygenfunction:: eth_phy_id

.. doxygenfunction:: smi_check_link_state


