extern void miiInstallHandler(int bufferAddr,
                              chanend miiChannel,
                              chanend notificationChannel);




/************ Input interface ***************/
/*
 * Inform the library of the buffer space to be used. A single array of the given number
 * of words shall be used to receive packets into.
 */
extern void miiBufferInit(chanend c_in, chanend c_notifications, int buffer[], int words);

/*
 * Blocks and waits for a packet. If called no more than 6 us after a packet is received,
 * then no packets will be lost. Packet filtering must be implemented by the caller.
 * It returns the index in the buffer and the number of bytes.
 */
{int,int} miiInPacket(chanend c_in, int buffer[]);

/*
 * Informs the input layer that the packet has been processed and that the buffer can be reused.
 * The index should be the number returned by miiInPacket
 */
extern void miiInPacketDone(chanend c_in, int index);

extern select notified(chanend notificationChannel);
void freeBuffer(int base);
{int, int} miiGetBuffer();
void miiRestartBuffer();




/** Function that initialises the transmitter of output packets. To be
 * called with the channel end that is connected to the MII Low-Level
 * Driver.
 *
 * \param cOut   output channel to the Low-Level Driver.
 */
void miiOutInit(chanend cOut);

/** Function that will cause a packet to be transmitted. It must get an
 * array with an index into the array, a length of hte packet (in bytes),
 * and a channel to the low-level driver. The low level driver will append
 * a CRC around the packet. The function returns once the preamble is on
 * the wire. The function miiOutputPacketDone() should be called to syncrhonise
 * with the end of the packet.
 *
 * \param cOut   output channel to the Low-Level Driver.
 *
 * \param buf    array that contains the message. Note that this is an
 *               array of words, that must contain the data in network order
 *               fill it using (buf, unsigned char[]).
 *
 * \param index  index into the array that contains the first byte.
 *
 * \param length length of message in bytes, excluding CRC, which will be added
 *               upon transmission.
 *
 * \returns      The time at which the message went onto the wire, measured in
 *               40-ns clock ticks of the MII clock. This time wraps around every
 *               2 ms.
 * 
 */
int miiOutPacket(chanend cOut, int buf[], int index, int length);

/** Select function that must be called after a call to miiOutPacket(). Upon
 * return of this function the packet has been put on the wire in its
 * entirety, and the interframe gap has expired - the next call to
 * miiOutPacket can be made without blocking. The function can be called in
 * one of two ways: either as an ordinary function, or as a case in a
 * select statement as in "case miiOutPacketDone(cOut);".
 *
 * \param cOut   output channel to the Low-Level Driver.
 */
select miiOutPacketDone(chanend cOut);
