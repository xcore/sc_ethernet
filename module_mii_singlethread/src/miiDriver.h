/** This function runs the MII low level driver. It requires at least 62.5
 * MIPS in order to be able to transmit and receive MII packets
 * simultaneously. The function has two channels to interface it to the
 * client functions that must run on a different thread on the same core.
 * The input and output client functions may run in the same thread or in
 * different threads.
 *
 * \param cIn    input channel to the client thread.
 *
 * \param cOut   output channel to the client thread.
 */
extern void miiDriver(chanend cIn, chanend cOut);
