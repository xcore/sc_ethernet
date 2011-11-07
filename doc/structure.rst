Source code structure
---------------------

Directory Structure
+++++++++++++++++++

A typical ethernet application will have at least three top level
directories. The application will be contained in a directory starting
with ``app_``, the ethernet component source is in the
``module_ethernet`` directory and the directory ``module_xmos_common``
contains files required to build the application.


::
 
   app_[my_app_name]/
   module_ethernet/
   module_xmos_common

Of course the application may use other modules which can also be
directories at this level. Which modules are compiled into the
application is controlled by the ``USED_MODULES`` define in the
application Makefile.


Key Files
+++++++++

The following header files contain prototypes of all functions
required to use use the ethernet component. The API is described in 
:ref:`sec_api`.

.. list-table:: Key Files
  :header-rows: 1

  * - File
    - Description
  * - ``ethernet_server.h``
    - Ethernet Server API header file    
  * - ``ethernet_rx_client.h``
    - Ethernet Client API header file (RX)
  * - ``ethernet_tx_client.h``
    - Ethernet Client API header file (TX)
