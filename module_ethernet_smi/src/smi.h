// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef _smi_h_
#define _smi_h_

#include <xs1.h>
#include <xccompat.h>

#ifdef __ethernet_conf_derived_h_exists__
#include "ethernet_conf_derived.h"
#endif

#ifdef __ethernet_board_conf_h_exists__
#include "ethernet_board_conf.h"
#endif

#ifdef __smi_conf_h_exists__
#include "smi_conf.h"
#endif


#ifndef SMI_COMBINE_MDC_MDIO
#define SMI_COMBINE_MDC_MDIO 0
#endif


/** Structure containing resources required for the SMI ethernet phy interface.
 *
 * This structure can be filled in two ways. One indicate that the SMI
 * interface is connected using two 1-bit port, the other indicates that
 * the interface is connected using a single multi-bit port.
 *
 * If used with two 1-bit ports, set the ``phy_address``, ``p_smi_mdio``
 * and ``p_smi_mdc`` as normal.
 *
 * If SMI_COMBINE_MDC_MDIO is 1 then ``p_smi_mdio`` is ommited and ``p_mdc`` is
 * assumbed to multibit port containing both mdio and mdc.
 *
 */
typedef struct smi_interface_t {
    int phy_address;           /**< Address of PHY, typically 0 or 0x1F. */
#if !SMI_COMBINE_MDC_MDIO
    port p_smi_mdio;           /**< MDIO port. */
#endif
    port p_smi_mdc;            /**< MDC port.  */
} smi_interface_t;

/** Function that configures the SMI ports. No clock block is needed.
 * Note that there is no deinit function.
 *
 * \param smi structure containing the clock and data ports for SMI.
 */
void smi_init(REFERENCE_PARAM(smi_interface_t, smi));

#define smi_port_init(clk,smi) _Pragma("warning \"smi_port_init in module_ethernet_smi deprecated, use smiInit without clock block\"") smi_init(smi)

/** Function that configures the Ethernet PHY explicitly to set to
 * autonegotiate.
 *
 * \param eth100 if eth100 is non-zero, 100BaseT is advertised to the link peer
 * Full duplex is always advertised
 *
 * \param smi structure that defines the ports to use for SMI
 */
void eth_phy_config(int eth100, REFERENCE_PARAM(smi_interface_t, smi));

/** Function that configures the Ethernet PHY to not
 * autonegotiate.
 *
 * \param eth100 if eth100 is non-zero, it is set to 100, else to 10 Mbits/s
 *
 * \param smi structure that defines the ports to use for SMI
 */
void eth_phy_config_noauto(int eth100, REFERENCE_PARAM(smi_interface_t, smi));

/** Function that can enable or disable loopback in the phy.
 *
 * \param enable boolean; set to 1 to enable loopback, or 0 to disable loopback.
 *
 * \param smi  structure containing the ports
 */
void eth_phy_loopback(int enable, REFERENCE_PARAM(smi_interface_t, smi));

/** Function that returns the PHY identification.
 *
 * \param smi  structure containing the ports
 *
 * \returns the 32-bit identifier.
 */
int eth_phy_id(REFERENCE_PARAM(smi_interface_t, smi));

/** Function that polls whether the link is alive.
 *
 * \param smi  structure containing the ports
 *
 * \returns non-zero if the link is alive; zero otherwise.
 */
int smi_check_link_state(REFERENCE_PARAM(smi_interface_t, smi));

/**/
int smi_reg(REFERENCE_PARAM(smi_interface_t, smi), unsigned reg, unsigned val, int inning);

#endif
