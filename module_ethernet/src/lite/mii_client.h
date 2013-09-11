// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>


#define KERNELSTACKWORDS 128

struct miiData {                    // DO NOT CHANGE LOCATIONS OR ADD ANY FIELDS.
    int nextBuffer;
    int packetInLLD;
    unsigned notificationChannelEnd;
    unsigned miiChannelEnd;
    int miiPacketsOverran;
    int refillBankNumber;
    int freePtr[2], wrPtr[2], lastSafePtr[2], firstPtr[2], readPtr[2];
    char notifyLast;
    char notifySeen;
    char pad0, pad1;
    int miiPacketsTransmitted;
    int miiPacketsReceived;
    int miiPacketsCRCError;
    int readBank;
    int kernelStack[KERNELSTACKWORDS];
};

/** This function gives the MII layer a buffer space to buffer input
 * packets into. The buffer space must be at least 1520 words, but can be
 * longer to improve performance.
 *
 * \param this  structure that contains persistent data for this MII connection.
 *
 * \param cIn channel that communicates with the low level input MII.
 *
 * \param cNotifications channel end that synchronises the interrupt and user layers.
 *
 * \param buffer    array of words that can be used for buffering.
 *
 * \param words     number of words in the array.
 */
extern void mii_buffer_init(struct miiData &this, chanend cIn, chanend cNotifications, int buffer[], int words);

/** Function that closes down the MII thread. This function should not be
 * called between ``miiOutPacket()`` and ``miiOutPacketDone()``
 *
 * \param cNotifications channel end that synchronised interrupt and user layers.
 *
 * \param cIn channel that communicates with the low level input input MII.
 *
 * \param cOut channel that communicates with the low level input output MII.
 */
void mii_close(chanend cNotifications, chanend cIn, chanend cOut);

/** This function will obtain a buffer from the input queue, or 0 if there
 * is no packet awaiting processing. When the packet has been processed,
 * freeInBuffer() should be called to free the packet buffer.
 *
 * \param this  structure that contains persistent data for this MII connection.
 *
 * \return The address of the buffer and the number of bytes.
 */
{unsigned, unsigned, unsigned} extern mii_get_in_buffer(struct miiData &this);

/** This function is called to informs the input layer that the packet has
 * been processed and that the buffer can be reused. The address should be
 * the number returned by miiInPacket. Packets should be released in a
 * timly manner, and hte buffers are organised as a strict FIFO, so not
 * processing a packet for a prolonged period of time shall lead to packet
 * loss.
 *
 * \param this  structure that contains persistent data for this MII connection.
 *
 * \param address The address of the buffer to be freed as returned by miiGetInBuffer().
 */
extern void mii_free_in_buffer(struct miiData &this, int address);

/** This function should be called to block the receiving thread. This
 * function will return when something interesting has happened at the MII
 * layer, and after its return, miiGetInBuffer can be called to test
 * whether a new packet is available, and miiRestartBuffer() must be
 * called.
 *
 * Note that this function can be one of the cases in a select statement,
 * enabling the user layer to deal with different event sources in a
 * non-deterministic manner.
 *
 * \param this  structure that contains persistent data for this MII connection.
 *
 * \param notificationChannel A channel-end that synchronises the user
 * layer with the interrupt layer
 */
extern select mii_notified(struct miiData &this, chanend notificationChannel);

/** This function must be called every time that miiNotified() has returned
 * and a buffer has been freed. It is safe to call this function more
 * often, for example, prior to every select statement that contains
 * miiNotified().
 */
extern void mii_restart_buffer(struct miiData &this);




/** Function that initialises the transmitter of output packets. To be
 * called with the channel end that is connected to the MII Low-Level
 * Driver.
 *
 * \param cOut   output channel to the Low-Level Driver.
 */
void mii_out_init(chanend cOut);

/** Function that will cause a packet to be transmitted. It must get an
 * array with an index into the array, a length of hte packet (in bytes),
 * and a channel to the low-level driver. The low level driver will append
 * a CRC around the packet. The function returns once the preamble is on
 * the wire. The function miiOutputPacketDone() should be called to syncrhonise
 * with the end of the packet.
 *
 * \param cOut   output channel to the Low-Level Driver.
 *
 * \param buf    array that contains the message. That this is an array
 *               of words, that must contain the data in network order: fill
 *               it using (buf, unsigned char[]). The last three words
 *               beyond the end of the buffer will be modified.
 *
 * \param index  index into the array that contains the first byte.
 *
 * \param length length of message in bytes, excluding CRC, which will be added
 *               upon transmission.
 *
 * \returns      The time at which the message went onto the wire, measured in
 *               reference clock periods
 *
 */
int mii_out_packet(chanend cOut, int buf[], int index, int length);

/** Function that will cause a packet to be transmitted. It must get an
 * address, a length of the packet (in bytes),
 * and a channel to the low-level driver. The low level driver will append
 * a CRC around the packet. The function returns once the preamble is on
 * the wire. The function miiOutputPacketDone() should be called to syncrhonise
 * with the end of the packet.
 *
 * \param cOut   output channel to the Low-Level Driver.
 *
 * \param buf    address that contains the message. This must be
 *               word aligned, and must contain the data in network
 *               order. The last three
 *               words beyond the end of the buffer will be modified.
 *
 * \param length length of message in bytes, excluding CRC, which will be added
 *               upon transmission.
 *
 * \returns      The time at which the message went onto the wire, measured in
 *               reference clock periods
 *
 */
int mii_out_packet_(chanend c_out, int buf, int length);

/** Select function that must be called after a call to miiOutPacket(). Upon
 * return of this function the packet has been put on the wire in its
 * entirety, and the interframe gap has expired - the next call to
 * miiOutPacket can be made without blocking. The function can be called in
 * one of two ways: either as an ordinary function, or as a case in a
 * select statement as in "case miiOutPacketDone(cOut);".
 *
 * \param cOut   output channel to the Low-Level Driver.
 */
#pragma select handler
void mii_out_packet_done(chanend cOut);
