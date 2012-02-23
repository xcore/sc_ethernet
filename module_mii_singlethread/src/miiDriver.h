#ifndef __miiDriver_h__
#define __miiDriver_h__

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

    in port p_mii_timing;   /**< A port that is not used for anything, used
                             * by the LLD for timing purposes. Must be
                             * clocked of the reference clock */
} mii_interface_t;
#endif

/** This function intiializes the MII low level driver.
 *
 *  \param p_mii_resetn   a port to reset the PHY (optional)
 *  \param m              the MII control structure
 */
extern void miiInitialise(out port ?p_mii_resetn,
                          mii_interface_t &m);

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
extern void miiDriver(mii_interface_t &m, chanend cIn, chanend cOut);

extern void phy_reset(out port p_mii_resetn, timer tmr);

#endif


