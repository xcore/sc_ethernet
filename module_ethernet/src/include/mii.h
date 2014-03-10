#ifndef _mii_h_
#define _mii_h_

#include <xs1.h>
#include <xccompat.h>
#include "ethernet_conf_derived.h"

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
typedef struct mii_interface_full_t {
  clock clk_mii_rx;            /**< MII RX Clock Block **/
  clock clk_mii_tx;            /**< MII TX Clock Block **/

  in port p_mii_rxclk;         /**< MII RX clock wire */
  in port p_mii_rxer;          /**< MII RX error wire */
  in buffered port:32 p_mii_rxd; /**< MII RX data wire */
  in port p_mii_rxdv;          /**< MII RX data valid wire */

  in port p_mii_txclk;       /**< MII TX clock wire */
  out port p_mii_txen;       /**< MII TX enable wire */
  out buffered port:32 p_mii_txd; /**< MII TX data wire */
} mii_interface_full_t;

typedef struct mii_slave_interface_full_t {
  clock clk_mii_slave;

  out port p_mii_slave_rxclk;             /**< MII RX clock wire */
  out port p_mii_slave_rxer;              /**< MII RX error wire */
  out buffered port:32 p_mii_slave_rxd;   /**< MII RX data wire */
  out port p_mii_slave_rxdv;              /**< MII RX data valid wire */


  out port p_mii_slave_txclk;             /**< MII TX clock wire */
  in port p_mii_slave_txen;               /**< MII TX enable wire */
  in buffered port:32 p_mii_slave_txd;    /**< MII TX data wire */
} mii_slave_interface_full_t;

typedef struct mii_interface_lite_t {
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

} mii_interface_lite_t;


#ifndef ADD_SUFFIX
#define _ADD_SUFFIX(A,B) A ## _ ## B
#define ADD_SUFFIX(A,B) _ADD_SUFFIX(A,B)
#endif

#define mii_interface_t ADD_SUFFIX(ADD_SUFFIX(mii_interface,ETHERNET_DEFAULT_IMPLEMENTATION),t)

#endif // __XC__



#endif




