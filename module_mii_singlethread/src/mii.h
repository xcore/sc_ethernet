/** This funciton initialises all MII ports and returns a timestamp as to
 * when the clock blocks were turned on.
 */

extern void mii_init(mii_interface_t &m, int simulation, timer tmr);

extern void miiTimeStampInit(unsigned offset);
