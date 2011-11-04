
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

#ifdef __XC__
/** Structure containing resources required for the SMI ethernet phy interface.
 *
 * This structure contains the resources required to communicate with
 * an ethernet phy over smi. 
 *   
 **/
typedef struct smi_interface_t {
  port p_smi_mdio;           /**< MDIO port. */
  out port p_smi_mdc;        /**< MDC port.  */
  int mdio_mux;              /**< This flag needs to be set if the MDIO port 
                                  is shared with the phy reset line. */  
} smi_interface_t;

#endif

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
extern void miiDriver(clock clk_smi,
                      out port ?p_mii_resetn,
                      smi_interface_t &smi,
                      mii_interface_t &m,
                      chanend cIn, chanend cOut, int simulation);

