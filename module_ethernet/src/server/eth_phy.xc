/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    eth_phy.xc
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2009
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 *
 **/                                   
#include "smi.h"
#include <print.h>
// wait this time to establish a link (ms) before giving a connection error
// Experience suggests that 2s may not be long enough, but 3 is.
#define LINK_TIMEOUT_MS        3000
#define ESTABLISH_LINK_TIMEOUT (REF_FREQ / 1000) * LINK_TIMEOUT_MS

// After link is established, a short delay is required (ms)
// This delay is applied after phy is reset and initialised
// PCs seems to take quite long to wake up and get ready to receive
#define POST_CONFIG_DELAY_MS   5000
#define POST_CONFIG_DELAY      (REF_FREQ / 1000) * POST_CONFIG_DELAY_MS

//////////////////////
// phy constants
//////////////////////

#define PHY_ADDRESS 0x1F
#define PHY_ID      0x300007

// SMI Registers
#define BASIC_CONTROL_REG                  0
#define BASIC_STATUS_REG                   1
#define PHY_ID1_REG                        2
#define PHY_ID2_REG                        3
#define AUTONEG_ADVERT_REG                 4
#define AUTONEG_LINK_REG                   5
#define AUTONEG_EXP_REG                    6

#define BASIC_CONTROL_LOOPBACK_BIT        14
#define BASIC_CONTROL_100_MBPS_BIT        13
#define BASIC_CONTROL_AUTONEG_EN_BIT      12
#define BASIC_CONTROL_RESTART_AUTONEG_BIT  9
#define BASIC_CONTROL_FULL_DUPLEX_BIT      8

#define BASIC_STATUS_LINK_BIT              2

#define AUTONEG_ADVERT_100_BIT             8
#define AUTONEG_ADVERT_10_BIT              6




////////////////////////////////////////////

/* Phy configuration
   If eth100 is non-zero, 100BaseT is advertised to the link peer
   Full duplex is always advertised
   autonegotiate is always ignored
   Returns 0 if no error and link established
   Returns 1 on ID read error or config register readback error
   Returns 2 if no error but link times out (1 sec)
*/
int eth_phy_config(int eth100, smi_interface_t &smi)
{
  unsigned x;
  unsigned phyid;

  // This used to be an argument, but has been removed now
  int autonegotiate = 1;
  
  // Make sure eth100 is either 0 or 1
  eth100 = (eth100 != 0);
      
#ifdef SIMULATION
  return 0;
#endif
  
  // 1. Check that the Phy ID can be read.  Return error 1 if not
  // 2a. autoneg advertise 100/10 then autonegotiate
  // 2b. set speed manually
  // 3. establish link or timeout (return error 2)
  // 4. short settling down delay
  
  // 1. Read phy ID from two regs & check it is OK
  phyid = smi_rd(PHY_ADDRESS, PHY_ID1_REG, smi);
  x = smi_rd(PHY_ADDRESS, PHY_ID2_REG, smi);
  phyid = ((x >> 10) << 16) | phyid;
  
  if (phyid != PHY_ID)
    {
      // PHY_ID doesn't correspond return error
      return (1);
    }
  
  if (autonegotiate)
    {
      
      // 2a. config for either 100 or 10 Mbps
      {
        // Read autoNegAdvertReg
        int autoNegAdvertReg = smi_rd(PHY_ADDRESS, AUTONEG_ADVERT_REG, smi);
        
        // Clear bits [9:5]
        autoNegAdvertReg = autoNegAdvertReg & 0xfc1f;

        // Set 100 or 10 Mpbs bits
        autoNegAdvertReg |= (eth100 << AUTONEG_ADVERT_100_BIT);
        autoNegAdvertReg |= (!eth100 << AUTONEG_ADVERT_10_BIT);
        
        // Write back and validate
        smi_wr(PHY_ADDRESS, AUTONEG_ADVERT_REG, autoNegAdvertReg, smi);
        if (smi_rd(PHY_ADDRESS, AUTONEG_ADVERT_REG, smi) != autoNegAdvertReg)
          return (1);
      }
    // Autonegotiate
      {
        int basicControl = smi_rd(PHY_ADDRESS, BASIC_CONTROL_REG, smi);
        // clear autoneg bit
        basicControl = basicControl & ( ~(1 << BASIC_CONTROL_AUTONEG_EN_BIT));
        smi_wr(PHY_ADDRESS, BASIC_CONTROL_REG, basicControl, smi);
        // set autoneg bit
        basicControl = basicControl | (1 << BASIC_CONTROL_AUTONEG_EN_BIT);
        smi_wr(PHY_ADDRESS, BASIC_CONTROL_REG, basicControl, smi);
      // restart autoneg
        basicControl = basicControl | (1 << BASIC_CONTROL_RESTART_AUTONEG_BIT);
        smi_wr(PHY_ADDRESS, BASIC_CONTROL_REG, basicControl, smi);
        
      }
    } else
    // 2b. Don't autoneg, set speed manually
    {
      // Not auto negotiating, setting the speed manually
      int basicControl = smi_rd(PHY_ADDRESS, BASIC_CONTROL_REG, smi);
    // set duplex mode
      basicControl = basicControl | (1 << BASIC_CONTROL_FULL_DUPLEX_BIT);
      // clear autoneg bit
      basicControl = basicControl & ( ~(1 << BASIC_CONTROL_AUTONEG_EN_BIT));
      // now set 100 or 10 Mpbs bits
      if (eth100)
        basicControl = basicControl |    (1 << BASIC_CONTROL_100_MBPS_BIT);
      else
        basicControl = basicControl & ( ~(1 << BASIC_CONTROL_100_MBPS_BIT));
      
    smi_wr(PHY_ADDRESS, BASIC_CONTROL_REG, basicControl, smi);
    
    }
  return 0;  

}


int eth_phy_checklink(smi_interface_t &smi)
{
  return ((smi_rd(PHY_ADDRESS, BASIC_STATUS_REG, smi )>>BASIC_STATUS_LINK_BIT)&1);    

}


////////////////////////////////////////////
// Loopback
////////////////////////////////////////////
/* Enable/disable internal phy loopback */
void eth_phy_loopback(int enable, smi_interface_t &smi)
{
  int controlReg = smi_rd(PHY_ADDRESS, BASIC_CONTROL_REG, smi);
  // enable (set) or disable (clear) loopback
  if (enable)
    controlReg = controlReg | (1 << BASIC_CONTROL_LOOPBACK_BIT);
  else
    controlReg = controlReg & ((-1) - (1 << BASIC_CONTROL_LOOPBACK_BIT));
  
#ifdef SIMULATION
  return;
#endif
  
  smi_wr(PHY_ADDRESS, BASIC_CONTROL_REG, controlReg, smi);

}

