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

// Constants used in calls to smi_bit_shift and smi_reg.

#define SMI_READ 1
#define SMI_WRITE 0

// Shift in a number of data bits to or from the SMI port
static int smi_bit_shift(smi_interface_t &smi, unsigned data, unsigned count, unsigned inning) {
    int i = count, dataBit = 0;
#ifdef SMI_MDC_BIT
    if (smi.phy_address < 0) {
        if (!inning) {
            smi.p_smi_mdc  <: 1 << SMI_MDC_BIT | 1 << SMI_MDIO_BIT;
        }
        while (i != 0) {
            i--;
            if (inning) {
                smi.p_smi_mdc :> dataBit;
                dataBit &= (1 << SMI_MDIO_BIT);
            } else {
                dataBit = ((data >> i) & 1) << SMI_MDIO_BIT;
                smi.p_smi_mdc  <: 1 << SMI_MDC_BIT | dataBit;
            }
            smi.p_smi_mdc  <:                    dataBit;
            smi.p_smi_mdc  <:                    dataBit;
            if (inning) {
                smi.p_smi_mdc :> dataBit;
                dataBit &= (1 << SMI_MDIO_BIT);
                data = (data << 1) | (dataBit >> SMI_MDIO_BIT);
            }
            smi.p_smi_mdc  <: 1 << SMI_MDC_BIT | dataBit;
        }        
        return data;
    }
#endif
    while (i != 0) {
        i--;
        smi.p_smi_mdc  <: ~0;
        if (!inning) {
            smi.p_smi_mdio <: data >> i;
        }
        smi.p_smi_mdc  <: 0;
        smi.p_smi_mdc  <: 0;
        if (inning) {
            smi.p_smi_mdio :> dataBit;
            data = (data << 1) | dataBit;
        }
        smi.p_smi_mdc  <: ~0;
    }        
    return data;
}

// Register access: lots of 1111, then a code (read/write), phy address,
// register, and a turn-around, then data.
int smi_reg(smi_interface_t &smi, unsigned reg, unsigned val, int inning) {
    smi_bit_shift(smi, 0xffffffff, 32, SMI_WRITE);         // Preamble
    smi_bit_shift(smi, (5+inning) << 10 | smi.phy_address << 5 | reg, 14, SMI_WRITE);
    smi_bit_shift(smi, 2, 2, inning);
    return smi_bit_shift(smi, val, 16, inning);
}

int eth_phy_id(smi_interface_t &smi) {
    unsigned lo = smi_reg(smi, PHY_ID1_REG, 0, SMI_READ);
    unsigned hi = smi_reg(smi, PHY_ID2_REG, 0, SMI_READ);
    return ((hi >> 10) << 16) | lo;
}

void eth_phy_config(int eth100, smi_interface_t &smi) {
    int autoNegAdvertReg, basicControl;
    autoNegAdvertReg = smi_reg(smi, AUTONEG_ADVERT_REG, 0, SMI_READ);
    
    // Clear bits [9:5]
    autoNegAdvertReg &= 0xfc1f;
    
    // Set 100 or 10 Mpbs bits
    if (eth100) {
        autoNegAdvertReg |= 1 << AUTONEG_ADVERT_100_BIT;
    } else {
        autoNegAdvertReg |= 1 << AUTONEG_ADVERT_10_BIT;
    }
    
    // Write back
    smi_reg(smi, AUTONEG_ADVERT_REG, autoNegAdvertReg, SMI_WRITE);
    
    basicControl = smi_reg(smi, BASIC_CONTROL_REG, 0, SMI_READ);
    // clear autoneg bit
    // basicControl &= ~(1 << BASIC_CONTROL_AUTONEG_EN_BIT);
    // smi_reg(smi, BASIC_CONTROL_REG, basicControl, SMI_WRITE);
    // set autoneg bit
    basicControl |= 1 << BASIC_CONTROL_AUTONEG_EN_BIT;
    smi_reg(smi, BASIC_CONTROL_REG, basicControl, SMI_WRITE);
    // restart autoneg
    basicControl |= 1 << BASIC_CONTROL_RESTART_AUTONEG_BIT;
    smi_reg(smi, BASIC_CONTROL_REG, basicControl, SMI_WRITE);    
}

void eth_phy_config_noauto(int eth100, smi_interface_t &smi) {
    int basicControl = smi_reg(smi, BASIC_CONTROL_REG, 0, SMI_READ);
    // set duplex mode, clear autoneg and 100 Mbps.
    basicControl |= 1 << BASIC_CONTROL_FULL_DUPLEX_BIT;
    basicControl &= ~( (1 << BASIC_CONTROL_AUTONEG_EN_BIT)|
                       (1 << BASIC_CONTROL_100_MBPS_BIT));
    if (eth100) {                // Optionally set 100 Mbps
        basicControl |= 1 << BASIC_CONTROL_100_MBPS_BIT;
    }
    smi_reg(smi, BASIC_CONTROL_REG, basicControl, SMI_WRITE);
}


void eth_phy_loopback(int enable, smi_interface_t &smi) {
    int controlReg = smi_reg(smi, BASIC_CONTROL_REG, 0, SMI_READ);
    // First clear both autoneg and loopback
    controlReg = controlReg & ~ ((1 << BASIC_CONTROL_AUTONEG_EN_BIT) |
                                 (1 << BASIC_CONTROL_LOOPBACK_BIT));
    // Now selectively set one of them
    if (enable) {
        controlReg = controlReg | (1 << BASIC_CONTROL_LOOPBACK_BIT);
    } else {
        controlReg = controlReg | (1 << BASIC_CONTROL_AUTONEG_EN_BIT);
    }  
    smi_reg(smi, BASIC_CONTROL_REG, controlReg, SMI_WRITE);
}

int smiCheckLinkState(smi_interface_t &smi) {
    return (smi_reg(smi, BASIC_STATUS_REG, 0, SMI_READ) >> BASIC_STATUS_LINK_BIT) & 1;    
}
