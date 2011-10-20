#define USER_BUFFER_SIZE_BITS      4
#define SYSTEM_BUFFER_SIZE_BITS    4

#define USER_BUFFER_SIZE           (1<<USER_BUFFER_SIZE_BITS)
#define SYSTEM_BUFFER_SIZE         (1<<SYSTEM_BUFFER_SIZE_BITS)

#ifndef ASSEMBLER
extern void miiTBufferInit(chanend c_in, int buffer[], int words, int doFilter);
extern void miiInstallHandler(int buffer[], chanend miiChannel);
{int,int} miiReceiveBuffer(int block);
extern void miiReturnBufferToPool(int bufferAddress);

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

#endif
