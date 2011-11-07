Ethernet Mac Description
========================

The ethernet MAC runs in 5 threads on a core communicating to client
threads over channels. The above figure shows the layout. The server
can connect to several clients and each channel connection to the
server is for either RX (receiving packets from the MAC) or TX
(transmitting packets to the MAC) operation.

.. figure:: images/mac.*
   :width: 100%

   Mac component

Buffers and Queues
++++++++++++++++++

The MAC maintains a two sets of buffers: one for incoming packets and
one for outgoing packets. These buffers are arranged into several
queues.

Incoming buffers move around the different queues as follows:

   * Empty buffers are in the incoming queue awaiting a packet coming
     in from the MII interfaces
   * Buffers received from the MII interface a filtered (see below)
     and if they need to be kept then are moved into a forwarding
     queue.
   * Buffers in the forwarding queue are moved into a client queue
     depending on which client registered for that type of
     packet. 
   * One the data from a buffer has been sent to a client the buffer
     is moved back into the incoming queue.

Outgoing buffers move around the different queues as follows:

   * Empty buffers are an empty queue awaiting a packet coming
     in from a client.
   * Once the data is received the buffer is moved into a transmit
     queue awaiting output on the MII interface.
   * Once the data is transmitted, the buffer is released back to the
     empty queue.

The number of buffers available can be set in the ``ethernet_conf.h``
configuration file (see :ref:`sec_conf_defines`).

Filtering
+++++++++

After incoming packets are received they are filtered. An initial
filter is done where the packet is dropped unless:

  #. The packet is destined for the hosts MAC address or
  #. The packet is destined for a MAC address with the broadcast bit
     set

After this initial filter, a user filter is supplied. To maintain the
maximum amount of flexibility and efficiency the application must
supply custom code to perform this filtering.

The user must supply a definition of the function
:c:func:`mac_custom_filter`. This function can inspect incoming
packets in any manner suitable for applications and then returns
either 0 if the packet is to be dropped or number which the clients
can then use to determine which packets they wish to receive (using
the client function :c:func:`mac_set_custom_filter`.

Timestamping
++++++++++++

On receipt of a ethernet frame over MII a timestamp is taken of the
100Mhz reference timer on the core that the ethernet server is
running on. The timestamp is taken at the end of the preamble
immediately before the frame itself. This timestamp will be accurate
to within 40ns. The timestamp is stored with the buffer data and can
be retrieved by the client by using the :c:func:`mac_rx_timed` function.

On transmission of a ethernet frame over MII a timestamp is also
taken. The timestamp is also taken at the end of the preamble
immediately before the frame itself and is accurate to within 40ns. 
The client can retreive the timestamp using the :c:func:`mac_tx_timed`
function. In this case the timestamp is stored on transmission and
placed in a queue to be sent back to the client thread.

MAC Address Storage
+++++++++++++++++++

The MAC address used for the server is set on instatiation of the
server (as an argument to the :c:func:`ethernet_server` function). 
This address should be unique for each device. For all XMOS develop
boards, a unique mac address is stored in the one time programmable
rom (OTP). To retreive this address the :c:func:`ethernet_getmac_otp`
function is provided.

For information on programming MAC addresses into OTP please contact
XMOS for detalis.

Resource Usage
++++++++++++++

Threads
~~~~~~~

The component uses 5 threads which must run at a minimum of 50 MIPs.

Ports
~~~~~

The MII interface uses 6 x 1 bit and 2 x 4 bit ports.

Memory
~~~~~~

The component has the following memory requirements:

.. list-table::
 :widths: 1 3

 * - Code
   - ~15k
 * - Buffers
   - (number of buffers) x ``MAX_ETHERNET_PACKET_SIZE``


Single threaded "lite" implementation (experimental)
++++++++++++++++++++++++++++++++++++++++++++++++++++

The two subdirectories called ``module_mii_singlethread`` and
``app_mii_singlethread_demo`` are an experimental single thread
MII controller.  The file``mii.xc`` contains the definition of
the MII port pins.

The main pin control thread is hand written assembler utilising
the event branching nature of the xcore to maintain two coroutines
inside the single thread.



