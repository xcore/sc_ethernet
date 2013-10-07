// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>

#include "smi.h"
#include "print.h"

#ifndef ETHERNET_PHY_RESET_TIMER_TICKS
#define ETHERNET_PHY_RESET_TIMER_TICKS 100
#endif

#ifndef SMI_MDIO_RESET_MUX
#define SMI_MDIO_RESET_MUX 0
#endif

#ifndef SMI_MDIO_REST
#define SMI_MDIO_REST 0
#endif

#ifndef SMI_HANDLE_COMBINED_PORTS
  #if SMI_COMBINE_MDC_MDIO
     #define SMI_HANDLE_COMBINED_PORTS 1
  #else
     #define SMI_HANDLE_COMBINED_PORTS 0
  #endif
#endif

#if SMI_HANDLE_COMBINED_PORTS
  #ifndef SMI_MDC_BIT
  #warning SMI_MDC_BIT not defined in smi_conf.h - Assuming 0
  #define SMI_MDC_BIT 0
  #endif

  #ifndef SMI_MDIO_BIT
  #warning SMI_MDIO_BIT not defined in smi_conf.h - Assuming 1
  #define SMI_MDIO_BIT 1
  #endif
#else
  #ifndef SMI_MDIO_BIT
  #define SMI_MDIO_BIT 0
  #endif
  #ifndef SMI_MDC_BIT
  #define SMI_MDC_BIT 0
  #endif
#endif

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
void smi_init(smi_interface_t &smi) {

#if SMI_MDIO_RESET_MUX
  {
    timer tmr;
    int t;
    smi.p_smi_mdio <: 0x0;
    tmr :> t;tmr when timerafter(t+100000) :> void;
    smi.p_smi_mdio <: SMI_MDIO_REST;
  }
#endif

#if SMI_HANDLE_COMBINED_PORTS
  if (SMI_COMBINE_MDC_MDIO || (smi.phy_address < 0)) {
    smi.p_smi_mdc <: 1 << SMI_MDC_BIT;
    return;
  }
#endif
  smi.p_smi_mdc <: 1;
}

// Constants used in calls to smi_bit_shift and smi_reg.

#define SMI_READ 1
#define SMI_WRITE 0

// Shift in a number of data bits to or from the SMI port
static int smi_bit_shift(smi_interface_t &smi, unsigned data, unsigned count, unsigned inning) {
    int i = count, dataBit = 0, t;

#if SMI_HANDLE_COMBINED_PORTS || SMI_COMBINE_MDC_MDIO
    if (SMI_COMBINE_MDC_MDIO || (smi.phy_address < 0)) {
        smi.p_smi_mdc :> void @ t;
        if (inning) {
            while (i != 0) {
                i--;
                smi.p_smi_mdc @ (t + 30) :> dataBit;
                dataBit &= (1 << SMI_MDIO_BIT);
                #if SMI_MDIO_REST
                dataBit |= SMI_MDIO_REST;
                #endif
                smi.p_smi_mdc            <: dataBit;
                data = (data << 1) | (dataBit >> SMI_MDIO_BIT);
                smi.p_smi_mdc @ (t + 60) <: 1 << SMI_MDC_BIT | dataBit;
                smi.p_smi_mdc            :> void;
                t += 60;
            }
            smi.p_smi_mdc @ (t+30) :> void;
        } else {
          while (i != 0) {
                i--;
                dataBit = ((data >> i) & 1) << SMI_MDIO_BIT;
                #if SMI_MDIO_REST
                dataBit |= SMI_MDIO_REST;
                #endif
                smi.p_smi_mdc @ (t + 30) <:                    dataBit;
                smi.p_smi_mdc @ (t + 60) <: 1 << SMI_MDC_BIT | dataBit;
                t += 60;
            }
            smi.p_smi_mdc @ (t+30) <: 1 << SMI_MDC_BIT | dataBit;
        }
        return data;
    }

#endif

#if !SMI_COMBINE_MDC_MDIO
    smi.p_smi_mdc <: ~0 @ t;
    while (i != 0) {
        i--;
        smi.p_smi_mdc @ (t+30) <: 0;
        if (!inning) {
          int dataBit;
          dataBit = ((data >> i) & 1) << SMI_MDIO_BIT;
          #if SMI_MDIO_REST
          dataBit |= SMI_MDIO_REST;
          #endif
          smi.p_smi_mdio <: dataBit;
        }
        smi.p_smi_mdc @ (t+60) <: ~0;
        if (inning) {
          smi.p_smi_mdio :> dataBit;
          dataBit = dataBit >> SMI_MDIO_BIT;
          data = (data << 1) | dataBit;
        }
        t += 60;
    }
    smi.p_smi_mdc @ (t+30) <: ~0;
    return data;
#else
    return 0;
#endif
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

int smi_check_link_state(smi_interface_t &smi) {
    return (smi_reg(smi, BASIC_STATUS_REG, 0, SMI_READ) >> BASIC_STATUS_LINK_BIT) & 1;
}
