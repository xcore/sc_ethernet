module_ethernet_smi API
=======================

This module is written to support SMI independently of the MII interface.
Typically, Ethernet PHYs are configured on reset automatically, but the SMI
interface may be useful for setting and testing register values
dynamically. 

There are two ways to interface SMI: using a pair of 1-bit ports, or using
a single multi-bit port.

Configuration Defines
---------------------

Two defines can be defined on the command line:

**SMI_MDC_BIT**

    This defines the bit number on the shared port where the MDC line is.
    Only define this if you have a port that drives both MDC and MDIO.

**SMI_MDIO_BIT**

    This defines the bit number on the shared port where the MDIO line is.
    Only define this if you have a port that drives both MDC and MDIO.


Data Structures
---------------

.. doxygenstruct:: smi_interface_t


Phy API
-------

.. doxygenfunction:: smiInit

.. doxygenfunction:: eth_phy_config

.. doxygenfunction:: eth_phy_config_noauto

.. doxygenfunction:: eth_phy_loopback

.. doxygenfunction:: eth_phy_id

.. doxygenfunction:: smiCheckLinkState

.. doxygenfunction:: smi_reg

