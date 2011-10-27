Single threaded MII
===================

This module provides an experimental component that folds the MII layer
into a single thread (62.5 MIPS), and allows all other software to be
written in one additional thread if required. It is meant for simple
ethernet systems that do not require very high throughput and have relatively
straightforward MAC filtering.

Using single threaded MII
-------------------------

The single threaded MII comprises three basic parts: an LLD (low level
driver) that must always run in its own thread, a *packet manager* that
must run on the same core, *input access functions*  that must be called
from the same thread, and *output access functions* that must be called
from the same core. It is designed for single-core applications, and uses a
dual circular buffer to store incoming packets.

Threads
'''''''

The single threaded MII module requires at least two threads to operate,
but more threads can be utilised to increase performance. Three common
usage models are sketched below

#. Two threads: thread one runs the , and
   thread 2 runs packet management, application level packet handling
   and application level packet generation.

#. Three threads: thread one runs the LLD (low level driver),
   thread 2 runs packet management and application level packet handling, and
   thread 3 runs application level packet generation.

The thread that performs packet management also performs the MAC filtering.
MAC filtering must be completed within 5 us (TBC) otherwise packet loss will
occur. If more complexe MAC filtering is required, a proper ethernet
module should be used.

Packet storage
''''''''''''''

Incoming packets are stored in circular buffers, and if those buffers are
not emptied in time, packets will be dropped. The circular buffers are
strict FIFOs, and it is therefore imperative that the application code does
not leave old packets in the buffer - ideally all packets are dealt with in
order of arrival, and if some packets cannot be dealt with immediately,
they should be copied to out of the packet-store into an application buffer.

API
'''

.. doxygenfunction:: miiBufferInit

.. doxygenfunction:: miiGetInBuffer

.. doxygenfunction:: miiFreeInBuffer

.. doxygenfunction:: miiNotified

.. doxygenfunction:: miiRestartBuffer

.. doxygenfunction:: miiOutInit

.. doxygenfunction:: miiOutPacket

.. doxygenfunction:: miiOutPacketDone

Example minimal programs
''''''''''''''''''''''''

The minimum two-threaded program is given below::

    void pingDemo(chanend cIn, chanend cOut, chanend cNotifications) {
        int b[3200];    
        miiBufferInit(cIn, cNotifications, b, 3200);
        miiOutInit(cOut);
        while (1) {
            int nBytes, a;
            miiNotified(cNotifications);
            {a,nBytes} = miiGetInBuffer();
            while(a != 0) {
                handlePacket(cOut, a, nBytes);
                miiFreeInBuffer(a);
                {a,nBytes} = miiGetInBuffer();
            }
            miiRestartBuffer();
        } 
    }

The function ``handlePacket`` will inspect the packet of length ``nBytes``
at address ``a`` in memory, and deal with it, possibly generating other
packets using the output interface::

    int txbuf[100], nBytes;
    // build packet of length nBytes in txbuf
    miiOutPacket(cOut, txbuf, 0, nBytes);
    miiOutPacketDone(cOut);

Note that both ``miiOutPacketDone()`` and ``miiNotified()`` can be placed
inside a select statement, enabling a single select to serve input
requests, output requests, and, for example, time-outs or communication
with another thread.

Internal details on single threaded MII
---------------------------------------

LLD: MII RX/TX principles
'''''''''''''''''''''''''

The LLD thread runs code that outputs packets over MII to the Ethernet PHY,
and on interrupts receives packets from MII. The interrupt service time is
short enough so that the input and output can proceed simultaneously. CRCs
are computed on-the-fly, but the final CRC check on input has to be
performed by another thread. Similarly, on the output side, the output
thread has to perform some initial computations prior to passing control to
the MII TX thread.

Interaction between LLD and packet manager
''''''''''''''''''''''''''''''''''''''''''

The LLD and the packet manager communicate over two channels: an
input-channel and an output-channel. Both channels are streaming channels,
and the channels must reside within a core. The communication protocol is
as follows.

On the input channel, the LLD first expects a word containing a buffer
address. It will then fill the buffer with data, and finally transmit a
word containing the address of the last word that was filled. The two words
above that address contain the number of bits that are valid in the final
word, and the partial CRC up until the last word. The LLD then expects a
'0' to be transmitted to it, and then the address of the next buffer. There
are tight timing constraints: there should be a gap of at least X
instructions before sending the '0' word and another gap of at least X
instructions prior to sending the next buffer address.

On the output channel, the LLD thread will request a channel by sending a
'1' control token. It will then expect a pointer to the end of the packet
and an negative number denoting the length of the packet, followed by a '1'
control token. The LLD will then send a word denoting the timestamp
(measured in 40 ns MMI clock ticks) that the preamble was transmitted,
prior to transmitting the packet. It will then wait for the inter-packet
gap, and request the next packet using a '1' control token.

Packet buffering management
'''''''''''''''''''''''''''

The packet store comprises two circular buffers, each with *free*, *read*, and
*write* pointers. The write pointer points to the head of the buffer, where
the next packet (of unknown length) will be inputted. Upon verifying the
CRC and the MAC filtering, the write pointer is advanced, making sure that
there are at least 1520 bytes free (the maximum packet size). If not, the
buffer is denoted full. The free pointer points to the first full packet in
the buffer, it is advanced when that buffer is freed (and may be advanced
over many packets that have already been freed if they are freed out of
order). The read pointer points to the first packet that the application
code has not yet used.

Because of the time consumed in checking the CRC and packet filtering,
subsequent packets are stored in alternating buffers. Giving the MAC filter
maximum time to take a decision.

Interaction between packet management and application code
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

The packet buffer uses an interrupt to store data into the packet buffer -
that is, the write pointer is updated by means of an interrupt. Packets are
read out in the same thread, but in the normal control flow, hence the read
and free pointers are updated by the normal control flow. The interrupt
routine leaves a token in a *notification* channel if it has done something
to a buffer, and the normal control flow should, when it finds that token,
inspect the input buffers, deal with data, free any buffers that can be
freed, and finally check that any buffer overflow has been resolved by
calling ``miiRestartBuffer()``


