// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _smi_h_
#define _smi_h_

#include <xs1.h>
#include <xccompat.h>

/** Structure containing resources required for the SMI ethernet phy interface.
 *
 * This structure contains the resources required to communicate with
 * an ethernet phy over smi. 
 *   
 **/
typedef struct smi_interface_t {
    int phy_address;           /**< Address of PHY, typically 0 or 0x1F.  */
    port p_smi_mdio;           /**< MDIO port. */
    out port p_smi_mdc;        /**< MDC port.  */
} smi_interface_t;

/** Function that configures the SMI ports. Needs a clock block that it
 * connects up to the ports. Note that there is no deinit function.
 *
 * \param clk_smi clock block used to clock the SMI pins.
 *
 * \param smi structure containing the clock and data ports for SMI.
 */
void smi_port_init(clock clk_smi, smi_interface_t &smi);

/** Function that configures the Ethernet PHY explicitly to set to
 * autonegotiate.
 *
 * \param If eth100 is non-zero, 100BaseT is advertised to the link peer
 * Full duplex is always advertised
 *
 * \param smi structure that defines the ports to use for SMI
 *
 * \returns 0 if no error and link established; 1 on ID read error or
 * config register readback error; 2 if no error but link times out (3
 * sec)
 */
int eth_phy_config(int eth100, smi_interface_t &smi);

/** Function that can enable or disable loopback in the phy.
 * 
 * \param enable boolean; set to 1 to enable loopback, or 0 to disable loopback.
 *
 * \param smi  structure containing the ports
 */
void eth_phy_loopback(int enable, smi_interface_t &smi);

/** Function that polls whether the link is alive.
 *
 * \param smi  structure containing the ports
 * 
 * \returns non-zero if the link is alive; zero otherwise.
 */
int eth_phy_checklink(smi_interface_t &smi);


#endif
