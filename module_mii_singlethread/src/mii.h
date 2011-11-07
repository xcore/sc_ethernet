/** This funciton initialises all MII ports and returns a timestamp as to
 * when the clock blocks were turned on.
 */

extern unsigned mii_init(mii_interface_t &m, int simulation);

extern void miiTimeStampInit(unsigned offset);
