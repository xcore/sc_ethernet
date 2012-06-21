#ifndef _mii_h_
#define _mii_h_

#include <xs1.h>
#include <xccompat.h>
#include "ethernet_derived_conf.h"

// This define can be used to force this header to define the mii_interface_t
// type to be the lite variant.
// You probably only want to do this if you are using both the full and
// lite versions
#ifdef MII_FORCE_USE_LITE
#ifndef ETHERNET_USE_LITE
#define ETHERNET_USE_LITE
#endif
#ifdef ETHERNET_USE_FULL
#undef ETHERNET_USE_FULL
#endif
#endif

#ifdef __XC__
/** Structure containing resources required for the MII ethernet interface.
 *
 *  This structure contains resources required to make up an MII interface. 
 *  It consists of 7 ports and 2 clock blocks.
 *
 *  The clock blocks can be any available clock blocks and will be clocked of 
 *  incoming rx/tx clock pins.
 *
 *  \sa ethernet_server()
 **/
typedef struct mii_interface_t {
    clock clk_mii_rx;            /**< MII RX Clock Block **/
    clock clk_mii_tx;            /**< MII TX Clock Block **/
    
    in port p_mii_rxclk;         /**< MII RX clock wire */
    in port p_mii_rxer;          /**< MII RX error wire */
    in buffered port:32 p_mii_rxd; /**< MII RX data wire */
    in port p_mii_rxdv;          /**< MII RX data valid wire */
    
    in port p_mii_txclk;       /**< MII TX clock wire */
    out port p_mii_txen;       /**< MII TX enable wire */
    out buffered port:32 p_mii_txd; /**< MII TX data wire */

#ifndef ETHERNET_USE_FULL
    in port p_mii_timing;   /**< A port that is not used for anything, used
                             * by the LLD for timing purposes. Must be
                             * clocked of the reference clock */
#endif
} mii_interface_t;
#endif // __XC__



#endif




