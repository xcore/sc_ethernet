/*
 * In order to use this mii library, a 62.5 MIPS (to be checked) thread
 * needs to call the mii() function at the bottom of this file. Another one
 * or two threads can then call the Output and Input functions.
 *
 * Either the asynchronous or the synchronous input interface shall be
 * used; not a mixture. The synchronous interface has strict real time
 * requirements if packet loss is to be avoided, the asynchronous interface
 * has less restrictios (only limited by the buffer size) but this
 * interface is interrupt driven and hence shall not be used if the calling
 * thread performs real time tasks.
 *
 * There is only one output interface, at present synchronous.
 */


/************ Synchronous input interface ***************/
/*
 * Inform the library of the buffer space to be used. A single array of the given number
 * of words shall be used to receive packets into.
 */
extern void miiBufferInit(chanend c_in, int buffer[], int words);

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




/************ Asynchronous input interface ***************/
/*
 * Inform the library of the buffer space to be used. A single array of the
 * given number of words shall be used to receive packets into. The
 * doFilter parameter can be set to '0' (keep all packets until picked up
 * by miiAsyncInPacket), '1' (call a function 'miiPacketFilter), or a
 * number not equal to either (call that function with a buffer array and a
 * number of words).
 */
void miiAsyncBufferInit(chanend c_in, int buffer[], int words, int doFilter);

/*
 * Blocks and waits for a packet. If this function is not called before the
 * buffer is completely filled up with packets, then packets will be lost.
 * If a packet filter was supplied (see the previous function) then only
 * filtered packets will be stored in the buffer. It returns the index in
 * the buffer and the number of bytes.
 */
{int,int} miiAsyncInPacket();

/*
 * Informs the input layer that the packet has been processed and that the buffer can be reused.
 * The index should be the number returned by miiInPacket
 */
void miiAsycnInPacketDone(int index);




/***************** Output interface *********************/
/*
 * Init out interface
 */
void miiOutInit(chanend c_out);

/*
 * Transmit a packet, sends length bytes from word index in b.
 * Calls should be spaced by at least 960 ns (to be stuck in the library).
 */
extern void miiOutPacket(chanend c_out, int b[], int index, int length);




/***************** Thread interface *********************/
/*
 * This needs to be called from a separate thread and starts the mii manager.
 */
extern void mii(chanend INchannel, chanend OUTchannel);

extern int enableMacFilter;
extern unsigned char filterMacAddress[6];

