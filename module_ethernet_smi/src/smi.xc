// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>

#include "smi.h"

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


// Clock is 4 times this rate.
#define SMI_CLOCK_DIVIDER   (100 / 10)


// Initialise the ports and clock blocks
void smi_port_init(clock clk_smi, smi_interface_t &smi) {
    configure_clock_ref(clk_smi, SMI_CLOCK_DIVIDER);
    configure_out_port_no_ready(smi.p_smi_mdc,   clk_smi, 1);
    start_clock (clk_smi);
}


// Shift in a number of data bits to or from the SMI port
static int smi_bit_shift(smi_interface_t &smi, unsigned data, unsigned count, unsigned inning) {
    int i = count, dataBit;
    while (i != 0) {
        i--;
        smi.p_smi_mdc  <: ~0;
        if (!inning) {
            smi.p_smi_mdio <: data >> i;
        }
        smi.p_smi_mdc  <: 0;
        if (inning) {
            smi.p_smi_mdio :> dataBit;
            data = (data << 1) | dataBit;
        }
        smi.p_smi_mdc  <: 0;
        smi.p_smi_mdc  <: ~0;
    }        
    return data;
}

// Start sequence: lots of 1111, then a code (read/write), phy address,
// register, and a turn-around.
static void smi_start(smi_interface_t &smi, unsigned reg, unsigned code) {
    smi_bit_shift(smi, 0xffffffff, 32, 0);         // Preamble
    smi_bit_shift(smi, code << 10 | smi.phy_address << 5 | reg, 14, 0);
    smi_bit_shift(smi, 0, 2, 1);
}


/* Register read, values are 16-bit */
static int smi_rd(int reg,  smi_interface_t &smi) {
    smi_start(smi, reg, 0x6);
    return smi_bit_shift(smi, 0, 16, 1);
}

/* Register write, data values are 16-bit */
static void smi_wr(int reg, int val, smi_interface_t &smi) {
    smi_start(smi, reg, 0x5);
    smi_bit_shift(smi, val, 16, 0);
}

int eth_phy_id(smi_interface_t &smi) {
    unsigned lo = smi_rd(PHY_ID1_REG, smi);
    unsigned hi = smi_rd(PHY_ID2_REG, smi);
    return ((hi >> 10) << 16) | lo;
}

void eth_phy_config(int eth100, smi_interface_t &smi) {
    int autoNegAdvertReg, basicControl;
    autoNegAdvertReg = smi_rd(AUTONEG_ADVERT_REG, smi);
    
    // Clear bits [9:5]
    autoNegAdvertReg &= 0xfc1f;
    
    // Set 100 or 10 Mpbs bits
    if (eth100) {
        autoNegAdvertReg |= 1 << AUTONEG_ADVERT_100_BIT;
    } else {
        autoNegAdvertReg |= 1 << AUTONEG_ADVERT_10_BIT;
    }
    
    // Write back
    smi_wr(AUTONEG_ADVERT_REG, autoNegAdvertReg, smi);
    
    basicControl = smi_rd(BASIC_CONTROL_REG, smi);
    // clear autoneg bit
    basicControl &= ~(1 << BASIC_CONTROL_AUTONEG_EN_BIT);
    smi_wr(BASIC_CONTROL_REG, basicControl, smi);
    // set autoneg bit
    basicControl |= 1 << BASIC_CONTROL_AUTONEG_EN_BIT;
    smi_wr(BASIC_CONTROL_REG, basicControl, smi);
    // restart autoneg
    basicControl |= 1 << BASIC_CONTROL_RESTART_AUTONEG_BIT;
    smi_wr(BASIC_CONTROL_REG, basicControl, smi);    
}

void eth_phy_config_noauto(int eth100, smi_interface_t &smi) {
    int basicControl = smi_rd(BASIC_CONTROL_REG, smi);
    // set duplex mode, clear autoneg and 100 Mbps.
    basicControl |= 1 << BASIC_CONTROL_FULL_DUPLEX_BIT;
    basicControl &= ~( (1 << BASIC_CONTROL_AUTONEG_EN_BIT)|
                       (1 << BASIC_CONTROL_100_MBPS_BIT));
    if (eth100) {                // Optionally set 100 Mbps
        basicControl |= 1 << BASIC_CONTROL_100_MBPS_BIT;
    }
    smi_wr(BASIC_CONTROL_REG, basicControl, smi);
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
