Source code structure
---------------------

Source code can be found across several modules:

  * ``module_ethernet`` contains the main MAC code
  * ``module_ethernet_smi`` contains the code for controlling an
    ethernet phy via the SMI configuration protocol
  * ``module_ethernet_board_support`` contains header files for common
    XMOS development boards allowing easy initialization of port
    structures.

Which modules are compiled into the
application is controlled by the ``USED_MODULES`` define in your
application Makefile.


Key files
+++++++++

The following header files contain prototypes of all functions
required to use the ethernet component. The API is described in 
:ref:`sec_api`.

.. list-table:: Key Files
  :header-rows: 1

  * - File
    - Description
  * - ``ethernet.h``
    - Ethernet main header file (includes other headers)
  * - ``ethernet_server.h``
    - Ethernet Server API header file
  * - ``ethernet_rx_client.h``
    - Ethernet Client API header file (RX)
  * - ``ethernet_tx_client.h``
    - Ethernet Client API header file (TX)
