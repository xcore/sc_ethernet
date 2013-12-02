Low Level Ethernet Demo Quickstart Guide
========================================

.. toctree::

Hardware Setup
--------------

To setup the hardware:

    #. Connect the XA-SK-E100 slice card to the XP-SKC-L16 sliceKIT Core Board using the connector marked with the ``CIRCLE``. 
    #. Connect the XTAG-2 USB debug adaptor to the XP-SKC-L16 sliceKIT Core Board (via the supplied adaptor board)
    #. Connect the XTAG-2 to host PC (as USB extension cable can be used if desired)
    #. Connect the power supply to the XP-SKC-L16 sliceKIT Core Board

.. figure:: images/hardware_setup.*

   Hardware Setup for XA-SK-AUDIO demo (I2S master)

Import and Build the Application
--------------------------------

   #. Open xTIMEcomposer and open the edit perspective (Window->Open Perspective->XMOS Edit).
   #. Locate the ``LOW Level Ethernet Demo`` item in the xSOFTip pane on the bottom left of the window and drag it into the Project Explorer window in the xTIMEcomposer. This will also cause the modules on which this application depends to be imported as well. 
   #. Click on the ``app_ethernet_demo`` item in the Explorer pane then click on the build icon (hammer) in xTIMEcomposer. Check the console window to verify that the application has built successfully.

Note that the Developer Column in the xTIMEcomposer on the right hand side of your screen provides information on the xSOFTip components you are using. Select the ``module_ethernet`` item in the Project Explorer, and you will see its description together with API documentation. Having done this, click the `back` icon until you return to this quickstart guide within the Developer Column.

For help in using xTIMEcomposer, try the xTIMEcomposer tutorial (See Help->Tutorials in xTIMEcomposer).

Run the Application
-------------------

To test the application a define in demo.xc (find this in the ``src`` subdirectory of the ``app_ethernet_demo`` item) needs to be set to an IP address that is routable in the network that the application is to be tested on.

.. literalinclude:: app_ethernet_demo/src/demo.xc
   :start-after: //::ip_address_define
   :end-before: //::


Once this is done, Now that the application has been compiled, the next step is to run it on the sliceKIT Core Board using the tools to load the application over JTAG (via the xTAG2 and xTAG Adaptor card) into the xCORE multicore microcontroller.

   #. Click on the ``Run`` icon (the white arrow in the green circle).   A dialog will appear asking which device to connect to. Select ``XMOS XTAG2``.
   #. The application will now be running and pinging the IP address defined in the step above should now get a response e.g.::

 PING 192.168.0.3 (192.168.0.3) 56(84) bytes of data.
 64 bytes from 192.168.0.3: icmp_seq=1 ttl=64 time=2.97 ms
 64 bytes from 192.168.0.3: icmp_seq=2 ttl=64 time=2.93 ms
 64 bytes from 192.168.0.3: icmp_seq=3 ttl=64 time=2.91 ms
 64 bytes from 192.168.0.3: icmp_seq=4 ttl=64 time=2.96 ms
 ...
  
Next Steps: Code walkthrough
----------------------------

Having successfully run the demo described above, the remainder of this documet provides a detailed walkthrough of the application code which can be examined in conjunction with the module documentation (includnig API) itself.


ethernet_conf.h
+++++++++++++++

The ethernet_conf.h file is found in the src/ directory of the
application. This file contains a series of #defines that configure
the ethernet stack. The possible #defines that can be set are
described in :ref:`sec_conf_defines`.

Within this application we set the maximum packet size we can receive
to be the maximum possible allowed in the ethernet standard and set
the number of buffers to be 5 packets for incoming packets and 5 for
outgoing.

The maximum number of ethernet clients (chanends we can connect to the
ethernet server) is set to 4 (even though we only have one client in
this example).

.. literalinclude:: app_ethernet_demo/src/ethernet_conf.h

This application has two build configurations - one for the full
implementation and one for the lite.

mac_custom_filter
+++++++++++++++++

The mac_custom_filter function allows use to decide which packets get
passed through the MAC. To do this, we have to provide the
mac_custom_filter.h header file and a definition of the
mac_custom_filter function itself.

The header file in this example just prototypes the mac_custom_filter
function itself. 

.. literalinclude:: app_ethernet_demo/src/mac_custom_filter.h

The module requires the application to provide the header to cater for
the case where the function is describe as an inline function for
performance. In this case it is just prototyped and the definition of
mac_custom_filter is in our main application code file demo.xc


.. literalinclude:: app_ethernet_demo/src/demo.xc 
  :start-after: //::custom-filter
  :end-before: //::


This function returns 0 if we do not want to handle the packet and
non-zero otherwise. The non-zero value is used later to distribute to
different clients. In this case we detect ARP packets and ICMP packets
which match our own mac address as a destination. In this case the
function returns 1. The defintions os is_broadcast, is_ethertype and
is_mac_addr are in demo.xc

Top level program structure
+++++++++++++++++++++++++++

Now that we have the basic ethernet building blocks, we can build our
application. This application is contained in demo.xc. Within this
file is the main() function which declares some variables (primarily
XC channels). It also contains a top level par construct which sets
the various functional units running that make up the program.

We run the ethernet server (this is set to run on
the tile ``ETHERNET_DEFAULT_TILE`` which is supplied by the board support
module). 
First, the function :c:func:`otp_board_info_get_mac` reads the device mac address from ROM. The
functions :c:func:`eth_phy_reset`, :c:func:`smi_config` and
:c:func:`eth_phy_config` initialize the phy and then the main function
:c:func:`ethernet_server` runs the ethernet component. The server
communicates with other tasks via the rx and tx channel arrays.

.. literalinclude:: app_ethernet_demo/src/demo.xc 
  :start-after: //::ethernet
  :end-before: //::

On tile 0 we run the demo() function as a task which takes ethernet packets and
responds to ICMP ping requests. This function is described in the next section.

.. literalinclude:: app_ethernet_demo/src/demo.xc 
  :start-after: //::demo
  :end-before: //::


Ethernet packet processing
++++++++++++++++++++++++++

The demo() function does the actual ethernet packet processing. First
the application gets the device mac address from the ethernet server.


.. literalinclude:: app_ethernet_demo/src/demo.xc
   :start-after: //::get-macaddr
   :end-before: //::


Then the packet filter is set up. The mask value passed to
:c:func:`mac_set_custom_filter` is used within the mac. After the
custom_mac_filter function is run, if the result is non-zero then the
result is and-ed against the mask. If this is non-zero then the packet
is forwarded to the client.

So in this case, the mask is 1 so all packets that get a result of 1 from
custom_mac_filter function will get passed to this client.


.. literalinclude:: app_ethernet_demo/src/demo.xc
   :start-after: //::setup-filter
   :end-before: //::

Note that this is only for build configuration that uses the FULL
configuration. If we are using the LITE configuration the filtering is
done after the client recieves the packet later on.

After we are set up to receive the correct packets we can go into the
main loop that responds to ARP and ICMP packets.

The first task in the loop is to receive a packet into the rxbuf
buffer using the :c:func:`mac_rx` function.

.. literalinclude:: app_ethernet_demo/src/demo.xc
   :start-after: //::mainloop
   :end-before: //::

Here we can see the filtering that needs to be done for the LITE configuration.

When the packet is received it may be an ARP or IP packet since both
get past our filter. First we check if it is an ARP packet, if so then
we build the response (in the txbuf array) and send it out over
ethernet using the :c:func:`mac_tx` function. The functions
is_valid_arp_packet and build_arp_response are defined demo.xc.

.. literalinclude:: app_ethernet_demo/src/demo.xc
   :start-after: //::arp_packet_check
   :end-before: //::

If the packet is not an ARP packet we check if it is an ICMP packet
and in the same way build a response and send it out. 

.. literalinclude:: app_ethernet_demo/src/demo.xc
   :start-after: //::icmp_packet_check
   :end-before: //::
