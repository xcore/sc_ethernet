#ifndef _mii_h_
#define _mii_h_

#include <xs1.h>
#include <xccompat.h>

#include "miiDriver.h"

/**
 * This funciton initialises all MII ports
 */
extern void mii_init(mii_interface_t &m, int simulation, timer tmr);

/**
 * This funciton initializes the MII timestamp
 */
extern void miiTimeStampInit(unsigned offset);


#endif


