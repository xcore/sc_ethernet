.. _sec_api:

API
===

.. _sec_conf_defines:

Configuration Defines
---------------------

The file ethernet_conf.h must be provided in the application source
code. This file can set the following defines:

**MAX_ETHERNET_PACKET_SIZE**

    This define sets the largest packet size in bytes that the ethernet mac
    will receive. The default it the largest possible ethernet packet
    size (1518 bytes). Setting this to a smaller value will save
    memory but restrict the type of packets you can receieve.

**NUM_MII_RX_BUF**

    Number of incoming packets that will be buffered within the MAC.

**NUM_MII_TX_BUF**

    Number of outgoing packets that will be buffered within the MAC.

**MAX_ETHERNET_CLIENTS**

    The maximum number of clients that can be connected to the
    :c:func:`ethernet_server` function via the rx and tx channel arrays.

**NUM_ETHERNET_PORTS**

    The number of ethernet ports to support.  Maximum value is 2 in
    the current implementation.

**ETHERNET_TX_HP_QUEUE**

    Define this constant to include the high priority transmit queueing
    mechanism.  This enables frames which have an ethernet VLAN priority
    tag to be queued in a high priority queue, which in turn can be
    managed with the 802.1qav transmit traffic shaper.  

**ETHERNET_RX_HP_QUEUE**

    Define this constant to include high priority reception of ethernet
    VLAN priority tagged traffic.  This traffic will be queued into a
    fast queue and delivered to the clients ahead of non-tagged traffic. 

**ETHERNET_TRAFFIC_SHAPER**

    If high priority transmit queueing is in use (see *ETHERNET_TX_HP_QUEUE*)
    then this enables the 802.1qav traffic shaping algorithm. 

**MII_RX_BUFSIZE_HIGH_PRIORITY**

    The number of quadlets (4 byte integers) of space in the high
    priority receive buffer.  The buffer will actually be two full
    packets longer than this to avoid the need to be circular. This
    constant applies when the high priority receive queue is in use.
    
**MII_RX_BUFSIZE_LOW_PRIORITY**

    The number of quadlets (4 byte integers) of space in the low
    priority receive buffer.  The buffer will actually be two full
    packets longer than this to avoid the need to be circular. This
    constant applies when the high priority receive is in use.

**MII_RX_BUFSIZE**

    The number of quadlets (4 byte integers) of space in the low
    priority receive buffer.  The buffer will actually be two full
    packets longer than this to avoid the need to be circular. This
    constant applies when the high priority receive is not in use.

**MII_TX_BUFSIZE**

    The number of quadlets (4 byte integers) of space in the low
    priority transmit buffer.  The buffer will actually be two full
    packets longer than this to avoid the need to be circular.

**MII_TX_BUFSIZE_HIGH_PRIORITY**

    The number of quadlets (4 byte integers) of space in the high
    priority transmit buffer.  The buffer will actually be two full
    packets longer than this to avoid the need to be circular. This
    constant applies when the high priority receive is in use.


Custom Filter Function
----------------------

Every application is required to provide this function. It also needs
to be prototyped (or defined as an inline definition) in the header
file ``mac_custom_filter.h``.

.. c:function:: int mac_custom_filter(unsigned int data[])

   This function examines an ethernet packet and returns a filter
   number to allow different clients to obtain different types of packet.
   The function *must* run within 6us to allow 100Mbit filtering of
   packets.

   :param data: This array contains the ethernet packet. It does not 
                include the preamble but does include the layer 2
                header or the packet.

   :returns: 0 if the packet is not wanted by the application or        
             a number that can be registed by
             :c:func:`mac_set_custom_filter` by a client. Clients 
             register a mask so the number is usually made up of a 
             bit per unique client destination for the packet.
           


Data Structures
---------------

.. doxygenstruct:: mii_interface_t


.. doxygenstruct:: smi_interface_t


OTP MAC Address Reading
-----------------------

.. doxygenfunction:: ethernet_getmac_otp

Ethernet Phy API
----------------

.. doxygenfunction:: phy_init

.. doxygenfunction:: phy_init_two_port

MAC Server API
--------------

.. doxygenfunction:: ethernet_server

.. doxygenfunction:: ethernet_server_two_port


RX Client API
-------------

Packet Receive Functions
++++++++++++++++++++++++

.. doxygenfunction:: mac_rx

.. doxygenfunction:: mac_rx_timed

.. doxygenfunction:: safe_mac_rx

.. doxygenfunction:: safe_mac_rx_timed

.. doxygenfunction:: mac_rx_offset2

Configuration Functions
+++++++++++++++++++++++

.. doxygenfunction:: mac_set_drop_packets

.. doxygenfunction:: mac_set_queue_size

.. doxygenfunction:: mac_set_custom_filter


TX Client API
-------------

Packet Transmit Functions
+++++++++++++++++++++++++

.. doxygenfunction:: mac_tx

.. doxygenfunction:: mac_tx_timed

.. doxygenfunction:: mac_tx_offset2

+-------------------------------------------------------------+
| Synonym                      | Function                     |
+-------------------------------------------------------------+
| ethernet_send_frame          | ethernet_send_frame          |
| ethernet_send_frame_getTime  | ethernet_send_frame_getTime  |
| ethernet_send_frame_offset2  | mac_tx_offset2               |
| ethernet_get_my_mac_adrs     | mac_get_macaddr              |
+-------------------------------------------------------------+

Configuration Functions
+++++++++++++++++++++++

.. doxygenfunction:: mac_get_macaddr

