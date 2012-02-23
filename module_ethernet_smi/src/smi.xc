// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>

#include "smi.h"

//////////////////////
// phy constants
//////////////////////

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


// SMI code drives SMI clock directly so work at 2x rate
#define SMI_CLOCK_DIVIDER   (100 / 2)


// Initialise the ports and clock blocks
void smi_port_init(clock clk_smi, smi_interface_t &smi) {
  configure_clock_ref (clk_smi, SMI_CLOCK_DIVIDER);
  configure_in_port_no_ready (smi.p_smi_mdc,   clk_smi);
  configure_in_port_no_ready (smi.p_smi_mdio,  clk_smi);

  start_clock (clk_smi);
  
  // When MDIO is used to input data, it needs to sample at the same time that MDC is asserted,
  // i.e. implement the sample delay on the port
  set_port_sample_delay   (smi.p_smi_mdio);

  smi.p_smi_mdc <: 0;
}


////////////////////////////////////////////
// SMI bit twiddling
////////////////////////////////////////////

// Shift out a number of data bits to the SMI port
static void smi_bit_shift_out (unsigned int data, int count, smi_interface_t &smi)
{
  for (int i = count; i != 0; i--)
  {
    // is this bit a 1 or a 0
    unsigned dataBit;

      dataBit = ((data & (1<<(i -1))) != 0);
    
    // Output data and give setup time

    smi.p_smi_mdio <: dataBit;
    smi.p_smi_mdc  <: 0;

    // Rising clock edge
    smi.p_smi_mdio <: dataBit;

    smi.p_smi_mdc  <: ~0;
  }

}

// Shift in a number of data bits from the SMI port
static int smi_bit_shift_in (int count,  smi_interface_t &smi)
{
  int data = 0;
  for (int i = count; i != 0; i--)
  {
    // is this bit a 1 or a 0
    int dataBit;
    // Sample MDIO, but discard the sample.
    // This ensures MDIO is now an input, and ensures correct sample timing later
    // Schedule MDC to drive low, and sample MDIO at the same time
    smi.p_smi_mdc  <: 0;

    smi.p_smi_mdio :> void;
    // Schedule MDC rising clock edge, and sample MDIO here too
    smi.p_smi_mdc  <: ~0;

      smi.p_smi_mdio :> dataBit;

    // Shift in bit
    data = (data <<1) | dataBit;
  }

  return (data);

}


static void smi_start(int reg,  smi_interface_t &smi, int code) {
    smi.p_smi_mdc  <: 0;
    smi.p_smi_mdc  <: 0;
    smi.p_smi_mdio <: 0;

    smi_bit_shift_out(0xffffffff, 32, smi);         // Preamble
    smi_bit_shift_out(code, 4, smi);                // Start sequence & read code
    smi_bit_shift_out(smi.phy_address, 5, smi);     // phy address
    smi_bit_shift_out(reg, 5, smi);                 // register address
}


/* Register read, values are 16-bit */
static int smi_rd(int reg,  smi_interface_t &smi) {
    unsigned int    readData;

    smi_start(reg, smi, 0x6);

    // turn around for 2 clocks
    smi.p_smi_mdc  <: 0;            // clock tick 1: negate MDC

    smi.p_smi_mdio :> void;         // clock tick 1: turn MDIO port around to become an input
                                    // clock tick 2: sample MDIO

    // MDC  outs and MDIO ins should now be paired:
    // MDC  out executed first schedules out data for next clock tick
    // MDIO in  exectued second pauses and returns the sample data on the next clock tick
    
    // second turn around clock
    smi_bit_shift_in(2, smi);
    // Read the register's data
    readData = smi_bit_shift_in(16, smi);

    // End MDC clock pulse
    smi.p_smi_mdc  <: 0;
    smi.p_smi_mdio <: 0;

    return (readData);
}

/* Register write, data values are 16-bit */
static void smi_wr(int reg, int val, smi_interface_t &smi) {
    smi_start(reg, smi, 0x5);

    // turn around for 2 clocks
    smi_bit_shift_out(2, 2, smi);
    // turn around for 16 clocks
    smi_bit_shift_out(val, 16, smi);
    
    // End MDC clock pulse
    smi.p_smi_mdc  <: 0;
    smi.p_smi_mdio <: 0;
}

int eth_phy_config(int eth100, smi_interface_t &smi) {
    unsigned x;
    unsigned phyid;

    // This used to be an argument, but has been removed now
    int autoNegAdvertReg, basicControl;

    // 1. Check that the Phy ID can be read.  Return error 1 if not
    phyid = smi_rd(PHY_ID1_REG, smi);
    x = smi_rd(PHY_ID2_REG, smi);
    phyid = ((x >> 10) << 16) | phyid;
    
    if (phyid != PHY_ID) {
        return 1;
    }
    
#ifndef ETH_SMI_NOAUTONEGOTIATE
    // 2a. config for either 100 or 10 Mbps
    // Read autoNegAdvertReg
    autoNegAdvertReg = smi_rd(AUTONEG_ADVERT_REG, smi);
    
    // Clear bits [9:5]
    autoNegAdvertReg = autoNegAdvertReg & 0xfc1f;
    
    // Set 100 or 10 Mpbs bits
    if (eth100) {
        autoNegAdvertReg |= (1 << AUTONEG_ADVERT_100_BIT);
    } else {
        autoNegAdvertReg |= (1 << AUTONEG_ADVERT_10_BIT);
    }
    
    // Write back and validate
    smi_wr(AUTONEG_ADVERT_REG, autoNegAdvertReg, smi);
    if (smi_rd(AUTONEG_ADVERT_REG, smi) != autoNegAdvertReg) {
        return 2;
    }
    
    basicControl = smi_rd(BASIC_CONTROL_REG, smi);
    // clear autoneg bit
    basicControl = basicControl & ( ~(1 << BASIC_CONTROL_AUTONEG_EN_BIT));
    smi_wr(BASIC_CONTROL_REG, basicControl, smi);
    // set autoneg bit
    basicControl = basicControl | (1 << BASIC_CONTROL_AUTONEG_EN_BIT);
    smi_wr(BASIC_CONTROL_REG, basicControl, smi);
    // restart autoneg
    basicControl = basicControl | (1 << BASIC_CONTROL_RESTART_AUTONEG_BIT);
    smi_wr(BASIC_CONTROL_REG, basicControl, smi);    
#else
    basicControl = smi_rd(BASIC_CONTROL_REG, smi);
    // set duplex mode
    basicControl = basicControl | (1 << BASIC_CONTROL_FULL_DUPLEX_BIT);
    // clear autoneg bit
    basicControl = basicControl & ~( (1 << BASIC_CONTROL_AUTONEG_EN_BIT)|
                                     (1 << BASIC_CONTROL_100_MBPS_BIT));
    // now set 100 or 10 Mpbs bits
    if (eth100) {
        basicControl = basicControl | (1 << BASIC_CONTROL_100_MBPS_BIT);
    }
    smi_wr(BASIC_CONTROL_REG, basicControl, smi);
#endif

    return 0;  
}


void eth_phy_loopback(int enable, smi_interface_t &smi) {
    int controlReg = smi_rd(BASIC_CONTROL_REG, smi);
    // First clear both autoneg and loopback
    controlReg = controlReg & ~ ((1 << BASIC_CONTROL_AUTONEG_EN_BIT) |
                                 (1 << BASIC_CONTROL_LOOPBACK_BIT));
    // Now selectively set one of them
    if (enable) {
        controlReg = controlReg | (1 << BASIC_CONTROL_LOOPBACK_BIT);
    } else {
        controlReg = controlReg | (1 << BASIC_CONTROL_AUTONEG_EN_BIT);
    }  
    smi_wr(BASIC_CONTROL_REG, controlReg, smi);
}

int smiCheckLinkState(smi_interface_t &smi) {
    return smi_rd(BASIC_STATUS_REG, smi) & (1<<BASIC_STATUS_LINK_BIT);    
}
