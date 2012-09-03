#ifndef _mii_lite_h_
#define _mii_lite_h_

#include <xs1.h>
#include <xccompat.h>

#include "mii_driver.h"

/**
 * This funciton initialises all MII ports
 */
extern void mii_port_init(mii_interface_lite_t &m);

/**
 * This funciton initializes the MII timestamp
 */
extern void miiTimeStampInit(unsigned offset);


#endif


