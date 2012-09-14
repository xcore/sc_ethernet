#ifndef __miiDriver_h__
#define __miiDriver_h__
#define MII_FORCE_USE_LITE
#include "mii.h"

/** This function intiializes the MII low level driver.
 *
 *  \param p_mii_resetn   a port to reset the PHY (optional)
 *  \param m              the MII control structure
 */
extern void mii_initialise(out port ?p_mii_resetn,
                           mii_interface_lite_t &m);

/** This function runs the MII low level driver. It requires at least 62.5
 * MIPS in order to be able to transmit and receive MII packets
 * simultaneously. The function has two channels to interface it to the
 * client functions that must run on a different thread on the same core.
 * The input and output client functions may run in the same thread or in
 * different threads.
 *
 *  \param m      the mii control structure
 *  \param cIn    input channel to the client thread.
 *  \param cOut   output channel to the client thread.
 */
extern void mii_driver(mii_interface_lite_t &m, chanend cIn, chanend cOut);

extern void phy_reset(out port p_mii_resetn, timer tmr);

#endif


