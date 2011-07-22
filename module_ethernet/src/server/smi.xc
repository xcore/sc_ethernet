/**
 * Module:  module_ethernet
 * Version: 1v3
 * Build:   d5b0bfe5e956ae7926b1afc930d8f10a4b48a88e
 * File:    smi.xc
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
/*************************************************************************
 *
 * Ethernet MAC Layer Implementation
 * IEEE 802.3 Serial Management Interface
 *
 *************************************************************************
 *
 * Copyright (c) 2008 XMOS Ltd.
 *
 * Copyright Notice
 *
 *************************************************************************
 *
 * Functions for controlling Ethernet phy management interface.
 *
 *************************************************************************/

#include <xs1.h>
#include <print.h>
#include "smi.h"

// Set SMI clock rate
//#define SMI_CLOCK_FREQ         250000      // Desired SMI clock frequency.
#define SMI_CLOCK_FREQ        1000000      // Desired SMI clock frequency.
#define REF_FREQ            100000000
// SMI code drives SMI clock directly so work at 2x rate
#define SMI_CLOCK_DIVIDER   ((REF_FREQ / SMI_CLOCK_FREQ) / 2)

// Reset duration in
#define RESET_DURATION_US 110
// Timer value used to implement reset delay
#define RESET_TIMER_DELAY ((REF_FREQ / 1000000)* RESET_DURATION_US)


// Initialise the ports and clock blocks
void smi_init(clock clk_mii_ref, clock clk_smi, out port ?p_mii_resetn, smi_interface_t &smi)
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
    p_mii_resetn <: 1;

  if (smi.mdio_mux) {
    smi.p_smi_mdio <: 0x7F;
  }

}

/* put SMI ports and clockblocks out of use */
void smi_deinit(clock clk_mii_ref, clock clk_smi, out port ?p_mii_resetn, smi_interface_t &smi)
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
void smi_reset( out port ?p_mii_resetn, smi_interface_t &smi)
{
  
  timer tmr;
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
    p_mii_resetn <: 1;

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
