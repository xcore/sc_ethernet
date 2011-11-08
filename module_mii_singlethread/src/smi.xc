// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <print.h>
#include "miiDriver.h"
#include "smi.h"

// Set SMI clock rate
//#define SMI_CLOCK_FREQ         250000      // Desired SMI clock frequency.
#define SMI_CLOCK_FREQ        1000000      // Desired SMI clock frequency.
#define REF_FREQ            100000000
// SMI code drives SMI clock directly so work at 2x rate
#define SMI_CLOCK_DIVIDER   ((REF_FREQ / SMI_CLOCK_FREQ) / 2)

// Reset duration in
#define RESET_DURATION_US 500
// Timer value used to implement reset delay
#define RESET_TIMER_DELAY ((REF_FREQ / 1000000)* RESET_DURATION_US)


// Initialise the ports and clock blocks
void smi_init(clock clk_smi, out port ?p_mii_resetn, smi_interface_t &smi)
{
  // Set the clock rate rate
  set_clock_off(clk_smi);
  set_clock_on(clk_smi);
  configure_clock_ref (clk_smi, SMI_CLOCK_DIVIDER);
  start_clock (clk_smi);
  
  // Setup ports
  set_port_use_off(smi.p_smi_mdc);
  set_port_use_off(smi.p_smi_mdio);
  if (!isnull(p_mii_resetn))
      set_port_use_off(p_mii_resetn);
  set_port_use_on(smi.p_smi_mdc);
  set_port_use_on(smi.p_smi_mdio);
  if (!isnull(p_mii_resetn))
    set_port_use_on(p_mii_resetn);
  configure_in_port_no_ready (smi.p_smi_mdc,   clk_smi);
  configure_in_port_no_ready (smi.p_smi_mdio,  clk_smi);
  
  // When MDIO is used to input data, it needs to sample at the same time that MDC is asserted,
  // i.e. implement the sample delay on the port
  set_port_sample_delay   (smi.p_smi_mdio);
  // p_mii_resetn will be using the default reference clock
  
  // Drive MDC inactive
  smi.p_smi_mdc <: 0;
  
  // Drive RESET inactive
  if (!isnull(p_mii_resetn))
    p_mii_resetn <: 0xf;

  if (smi.mdio_mux) {
    smi.p_smi_mdio <: 0x7F;
  }

}

/* put SMI ports and clockblocks out of use */
void smi_deinit(clock clk_smi, out port ?p_mii_resetn, smi_interface_t &smi)
{
  // Set the clock rate rate
  stop_clock (clk_smi);
  set_clock_off(clk_smi);
  
  // Setup ports
  set_port_use_off(smi.p_smi_mdc);
  set_port_use_off(smi.p_smi_mdio);
  if (!isnull(p_mii_resetn))
    set_port_use_off(p_mii_resetn);
}

// Reset the MII PHY
void smi_reset( out port ?p_mii_resetn, smi_interface_t &smi, timer tmr)
{
  unsigned int  resetTime;
  
  // Assert reset;
  if (!isnull(p_mii_resetn))
    p_mii_resetn <: 0;

  if (smi.mdio_mux)
    smi.p_smi_mdio <: 0x0;

  
  // Wait
 tmr :> resetTime;
#ifdef SIMULATION
  resetTime += 100;
#else
  resetTime += RESET_TIMER_DELAY;
#endif
  tmr when timerafter(resetTime) :> int discard;
  
  // Negate reset;
  if (!isnull(p_mii_resetn))
    p_mii_resetn <: 0xf;

  if (smi.mdio_mux)
    smi.p_smi_mdio <: 0x7F;

  
  // Wait
 tmr :> resetTime;
#ifdef SIMULATION
  resetTime += 100;
#else
  resetTime += RESET_TIMER_DELAY;
#endif
  tmr when timerafter(resetTime) :> int discard;

}


////////////////////////////////////////////
// SMI bit twiddling
////////////////////////////////////////////

// Shift out a number of data bits to the SMI port
void smi_bit_shift_out (unsigned int data, int count, smi_interface_t &smi)
{
  int i;
  for ( i = count; i > 0; i--)
  {
    // is this bit a 1 or a 0
    unsigned dataBit;

    if (smi.mdio_mux) {
      dataBit = (((data & (1<<(i -1))) != 0) << 7) | 0x7F;
    }
    else {
      dataBit = ((data & (1<<(i -1))) != 0);
    }
    
    // Output data and give setup time

    smi.p_smi_mdio <: dataBit;
    smi.p_smi_mdc  <: 0;

    // Rising clock edge
    smi.p_smi_mdio <: dataBit;

    smi.p_smi_mdc  <: 1;
  }

}

// Shift in a number of data bits from the SMI port
int smi_bit_shift_in (int count,  smi_interface_t &smi)
{
  int data = 0;
  int i;
  for ( i = count; i > 0; i--)
  {
    // is this bit a 1 or a 0
    int dataBit;
    // Sample MDIO, but discard the sample.
    // This ensures MDIO is now an input, and ensures correct sample timing later
    // Schedule MDC to drive low, and sample MDIO at the same time
    smi.p_smi_mdc  <: 0;

    smi.p_smi_mdio :> int discard;
    // Schedule MDC rising clock edge, and sample MDIO here too
    smi.p_smi_mdc  <: 1;

    if (smi.mdio_mux) {
      smi.p_smi_mdio :> dataBit;
      dataBit = dataBit >> 7;
    }
    else {
      smi.p_smi_mdio :> dataBit;
    }  

    // Shift in bit
    data = (data <<1) | dataBit;
  }

  return (data);

}

/* Register read, values are 16-bit */
int smi_rd(int address, int reg,  smi_interface_t &smi)
{
  // MDIO is sampled on the rising edge of MDC, so MDIO changes on the falling edge of MDC
  // Packet: 31 1's,0, 1,(write: 0,1)(read: 1,0), PHY Addr [4:0], Reg Addr [4:0], turnaround [2], data [15:0]
  // MSBs are transferred first.

  unsigned int    readData;

  // output to the ports to ensure synchronisation with clock blocks
  smi.p_smi_mdc  <: 0;
  smi.p_smi_mdc  <: 0;

  if (smi.mdio_mux) 
    smi.p_smi_mdio <: 0x7F;
  else    
    smi.p_smi_mdio <: 0;


  // Preamble
  smi_bit_shift_out(0xffffffff, 32, smi);
  // Start sequence & read code
  smi_bit_shift_out(0x6, 4, smi);
  // phy address
  smi_bit_shift_out(address, 5, smi);
  // register address
  smi_bit_shift_out(reg, 5, smi);
  // turn around for 2 clocks

  smi.p_smi_mdc  <: 0;            // clock tick 1: negate MDC

  //  if (!smi.mdio_mux)
 smi.p_smi_mdio :> int discard;  // clock tick 1: turn MDIO port around to become an input
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
  // Turn around Mdio

  if (!smi.mdio_mux)
    smi.p_smi_mdio <: 0;

  return (readData);


}

/* Register write, data values are 16-bit */
void smi_wr(int address, int reg, int val, smi_interface_t &smi)
{
  // MDIO is sampled on the rising edge of MDC, so MDIO changes on the falling edge of MDC
  // Packet: 31 1's,0, 1,(write: 0,1)(read: 1,0), PHY Addr [4:0], Reg Addr [4:0], turnaround [2], data [15:0]
  // MSBs are transferred first.

  // output to the ports to ensure synchronisation with clock blocks
  smi.p_smi_mdc  <: 0;
  smi.p_smi_mdc  <: 0;

  if (smi.mdio_mux)
    smi.p_smi_mdio <: 0x7F;
  else
    smi.p_smi_mdio <: 0;



  // Preamble
  smi_bit_shift_out(0xffffffff, 32, smi);
  // Start sequence & write code
  smi_bit_shift_out(0x5, 4, smi);
  // phy address
  smi_bit_shift_out(address, 5, smi);
  // register address
  smi_bit_shift_out(reg, 5, smi);
  // turn around for 2 clocks
  smi_bit_shift_out(2, 2, smi);
  // turn around for 16 clocks
  smi_bit_shift_out(val, 16, smi);

  // End MDC clock pulse
  smi.p_smi_mdc  <: 0;

  if (smi.mdio_mux)
    smi.p_smi_mdio <: 0x7F;
  else
    smi.p_smi_mdio <: 0;


}












#include "smi.h"
#include <print.h>
#if __ethernet_conf_h_exists__
#include "ethernet_conf.h"
#endif

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

#ifndef PHY_ADDRESS
#define PHY_ADDRESS 0x0
#endif
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
      printhexln(phyid);
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
          return (2);
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
  {
	controlReg = controlReg | (1 << BASIC_CONTROL_LOOPBACK_BIT);
	controlReg = controlReg & ( ~(1 << BASIC_CONTROL_AUTONEG_EN_BIT));
  }
  else
  {
	controlReg = controlReg & ((-1) - (1 << BASIC_CONTROL_LOOPBACK_BIT));
	controlReg = controlReg | (1 << BASIC_CONTROL_AUTONEG_EN_BIT);
  }
  
#ifdef SIMULATION
  return;
#endif
  
  smi_wr(PHY_ADDRESS, BASIC_CONTROL_REG, controlReg, smi);
  controlReg = smi_rd(PHY_ADDRESS, BASIC_CONTROL_REG, smi);
}



