/**
 * @ModuleName XC-2 Ethernet UDP Demo
 * @Date 10/02/2009
 * @Version 1.0
 *
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2009
**/ 

#include <xs1.h>
#include <platform.h>
#include <print.h>
/*#ifdef XC2
#include "xc2.h"
#else
#include "xdk.h"
#endif*/
#include "smi.h"

// Set SMI clock rate
#define SMI_CLOCK_FREQ         250000      // Desired SMI clock frequency.
#define REF_FREQ            100000000
// SMI code drives SMI clock directly so work at 2x rate
#define SMI_CLOCK_DIVIDER   ((REF_FREQ / SMI_CLOCK_FREQ) / 2)

// Reset duration in
#define RESET_DURATION_US 110
// Timer value used to implement reset delay
#define RESET_TIMER_DELAY ((REF_FREQ / 1000000)* RESET_DURATION_US)


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

int PHY_ADDRESS =0x0;
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

// Define ports
// Note: XC2 v1.0 has a pull down (rather than pull up) on RSTn
// therefore we always drive on p_smi_8d
on stdcore[1] :     port p_smi_mdio   = XS1_PORT_1M;     // Bidirectional
on stdcore[1] : out port p_smi_mdc    = XS1_PORT_1J;
on stdcore[1]: out port p_mii_resetn = XS1_PORT_4C;
//#define XC2

on stdcore[1]: clock clk_smi = XS1_CLKBLK_3;           // 2x SMI clock rate

int smiIs100Mbps = 0;

// Initialise the ports and clock blocks
void smi_init(void)
{
  // Set the clock rate rate
	set_clock_off(clk_smi);
	set_clock_on(clk_smi);
  configure_clock_ref (clk_smi, SMI_CLOCK_DIVIDER);
  start_clock (clk_smi);

#ifdef XC2
	set_port_use_off(p_smi_mdc);
	set_port_use_off(p_smi_8d);
	set_port_use_on(p_smi_mdc);
	set_port_use_on(p_smi_8d);
  configure_in_port_no_ready(p_smi_mdc, clk_smi);
  configure_in_port_no_ready(p_smi_8d, clk_smi);
  set_port_sample_delay(p_smi_8d);
  p_smi_mdc <: 0;
  p_smi_8d <: 0x7F;
#else
  // Setup ports
	set_port_use_off(p_smi_mdc);
	set_port_use_off(p_smi_mdio);
	set_port_use_off(p_mii_resetn);
	set_port_use_on(p_smi_mdc);
	set_port_use_on(p_smi_mdio);
	set_port_use_on(p_mii_resetn);
  configure_in_port_no_ready (p_smi_mdc,   clk_smi);
  configure_in_port_no_ready (p_smi_mdio,  clk_smi);
  // When MDIO is used to input data, it needs to sample at the same time that MDC is asserted,
  // i.e. implement the sample delay on the port
  set_port_sample_delay   (p_smi_mdio);
  // p_mii_resetn will be using the default reference clock

  // Drive MDC inactive
  p_smi_mdc <: 0;

  // Drive RESET inactive
  p_mii_resetn <: 0xF;
#endif
}

/* put SMI ports and clockblocks out of use */
void smi_deinit(void)
{
  // Set the clock rate rate
  stop_clock (clk_smi);
	set_clock_off(clk_smi);

  // Setup ports
  set_port_use_off(p_smi_mdc);
#ifdef XC2
  set_port_use_off(p_smi_8d);
#else
  set_port_use_off(p_smi_mdio);
	set_port_use_off(p_mii_resetn);
#endif
}

// Reset the MII PHY
void smi_reset()
{
  timer tmr;
  unsigned int  resetTime;

  // Assert reset;
#ifdef XC2
  p_smi_8d <: 0;
#else
  p_mii_resetn <: 0;
#endif

  // Wait
  tmr :> resetTime;
#ifdef SIMULATION
	resetTime += 100;
#else
  resetTime += RESET_TIMER_DELAY;
#endif
  tmr when timerafter(resetTime) :> int discard;

  // Negate reset;
#ifdef XC2
  p_smi_8d <: 0x7F;
#else
  p_mii_resetn <: 0xF;
#endif

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

/* Phy configuration
   If eth100 is non-zero, 100BaseT is advertised to the link peer
   Full duple7x is always advertised
   autonegotiate is always ignored
   Returns 0 if no error and link established
   Returns 1 on ID read error or config register readback error
   Returns 2 if no error but link times out (1 sec)
*/
int smi_config(int eth100)
{
  unsigned x;
  unsigned phyid;

	// This used to be an argument, but has been removed now
	int autonegotiate = 1;

	// Make sure eth100 is either 0 or 1
	eth100 = (eth100 != 0);

	smiIs100Mbps = eth100;

  // This used to be a separate function call, but is integrated into smi_config now
  smi_reset();

#ifdef SIMULATION
	return 0;
#endif

  // 1. Check that the Phy ID can be read.  Return error 1 if not
  // 2a. autoneg advertise 100/10 then autonegotiate
  // 2b. set speed manually
  // 3. establish link or timeout (return error 2)
  // 4. short settling down delay

  // 1. Read phy ID from two regs & check it is OK
  phyid = smi_rd(PHY_ID1_REG);
  x = smi_rd(PHY_ID2_REG);
  phyid = ((x >> 10) << 16) | phyid;
#ifndef XC2
  if (phyid != PHY_ID)
  {
//      printf("PHY %x %x\n", phyid, PHY_ID);
    // PHY_ID doesn't correspond return error
    return (100);
  }
#endif

  if (autonegotiate)
  {

    // 2a. config for either 100 or 10 Mbps
    {
      // Read autoNegAdvertReg
      int autoNegAdvertReg = smi_rd(AUTONEG_ADVERT_REG);

      // Clear bits [9:5]
      autoNegAdvertReg = autoNegAdvertReg & 0xfc1f;

      // Set 100 or 10 Mpbs bits
			autoNegAdvertReg |= (eth100 << AUTONEG_ADVERT_100_BIT);
			autoNegAdvertReg |= (!eth100 << AUTONEG_ADVERT_10_BIT);

      // Write back and validate
      smi_wr(AUTONEG_ADVERT_REG, autoNegAdvertReg);
#ifndef XC2
			if (smi_rd(AUTONEG_ADVERT_REG) != autoNegAdvertReg)
				return (9);
#endif
    }
    // Autonegotiate
    {     
      int basicControl = smi_rd(BASIC_CONTROL_REG);
      // clear autoneg bit
      basicControl = basicControl & ( ~(1 << BASIC_CONTROL_AUTONEG_EN_BIT));
      smi_wr(BASIC_CONTROL_REG, basicControl);
      // set autoneg bit
      basicControl = basicControl | (1 << BASIC_CONTROL_AUTONEG_EN_BIT);
      smi_wr(BASIC_CONTROL_REG, basicControl);
      // restart autoneg
      basicControl = basicControl | (1 << BASIC_CONTROL_RESTART_AUTONEG_BIT);
      smi_wr(BASIC_CONTROL_REG, basicControl);

    }
  } else
  // 2b. Don't autoneg, set speed manually
  {
    // Not auto negotiating, setting the speed manually
    int basicControl = smi_rd(BASIC_CONTROL_REG);
    // set duplex mode
    basicControl = basicControl | (1 << BASIC_CONTROL_FULL_DUPLEX_BIT);
    // clear autoneg bit
    basicControl = basicControl & ( ~(1 << BASIC_CONTROL_AUTONEG_EN_BIT));
     // now set 100 or 10 Mpbs bits
    if (eth100)
      basicControl = basicControl |    (1 << BASIC_CONTROL_100_MBPS_BIT);
    else
      basicControl = basicControl & ( ~(1 << BASIC_CONTROL_100_MBPS_BIT));

    smi_wr(BASIC_CONTROL_REG, basicControl);

  }

  // 3. establish link or timeout
#ifdef XC2
  return 0;
#else
  {
    timer tmr;
    int now;
    int timeoutTime;
    int linkEstablished = 0;
    int timeout = 0;

    tmr :> now;
    timeoutTime = now + ESTABLISH_LINK_TIMEOUT;

    while (
            (linkEstablished == 0) &&
            (timeout == 0)
          )
    {
      // Check link status
      if (smi_rd(BASIC_STATUS_REG) & (1 << BASIC_STATUS_LINK_BIT))
        linkEstablished = 1;
      // check for timeout
      tmr :> now;
      if ((timeoutTime - now)<0)
        timeout = 1;
    }

  // 4. settling down delay
    // reuse timeoutTime
#ifdef PHY_USE_POST_CONFIG_DELAY
    tmr :> timeoutTime;
    timeoutTime += POST_CONFIG_DELAY;
    tmr when timerafter(timeoutTime) :> unsigned int discard;
#endif

    return 0;
    if (linkEstablished)
      return (0);
    else
      return (2);
  }
#endif

}


int ethernet_is_connected() 
{
  return ((smi_rd(BASIC_STATUS_REG)>>BASIC_STATUS_LINK_BIT)&1);    
}


int smi_is100()
{
	return smiIs100Mbps;
}

////////////////////////////////////////////
// Loopback
////////////////////////////////////////////
/* Enable/disable internal phy loopback */
void smi_loopback(int enable)
{
  int controlReg = smi_rd(BASIC_CONTROL_REG);
  // enable (set) or disable (clear) loopback
  if (enable)
    controlReg = controlReg | (1 << BASIC_CONTROL_LOOPBACK_BIT);
  else
    controlReg = controlReg & ((-1) - (1 << BASIC_CONTROL_LOOPBACK_BIT));

#ifdef SIMULATION
	return;
#endif

  smi_wr(BASIC_CONTROL_REG, controlReg);

}



////////////////////////////////////////////
// SMI bit twiddling
////////////////////////////////////////////

// Shift out a number of data bits to the SMI port
void smi_bit_shift_out (unsigned int data, int count)
{
  int i;
  for ( i = count; i > 0; i--)
  {
    // is this bit a 1 or a 0
#ifdef XC2
    unsigned dataBit = (((data & (1<<(i -1))) != 0) << 7) | 0x7F;
#else
    int dataBit = ((data & (1<<(i -1))) != 0);
#endif
    // Output data and give setup time
#ifdef XC2
    p_smi_8d <: dataBit;
#else
    p_smi_mdio <: dataBit;
#endif
    p_smi_mdc  <: 0;

    // Rising clock edge
#ifdef XC2
    p_smi_8d <: dataBit;
#else
    p_smi_mdio <: dataBit;
#endif
    p_smi_mdc  <: 1;
  }
}

// Shift in a number of data bits from the SMI port
int smi_bit_shift_in (int count)
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
    p_smi_mdc  <: 0;
#ifdef XC2
    // Do not input on p_smi_8d, phy would go in reset
    p_smi_8d :> int discard;
#else
    p_smi_mdio :> int discard;
#endif

    // Schedule MDC rising clock edge, and sample MDIO here too
    p_smi_mdc  <: 1;
#ifdef XC2
    // Do not input on p_smi_8d, phy would go in reset
   p_smi_8d :> dataBit;
    dataBit = dataBit >> 7;
#else
    p_smi_mdio :> dataBit;
#endif

    // Shift in bit
    data = (data <<1) | dataBit;
  }
  //#ifdef XC2
  //  data = 0x55555555 | ((1 << count) - 1);
  //#endif
  return (data);
}

/* Register read, values are 16-bit */
int smi_rd( int reg)
{
  // MDIO is sampled on the rising edge of MDC, so MDIO changes on the falling edge of MDC
  // Packet: 31 1's,0, 1,(write: 0,1)(read: 1,0), PHY Addr [4:0], Reg Addr [4:0], turnaround [2], data [15:0]
  // MSBs are transferred first.

  int    readData;

  // output to the ports to ensure synchronisation with clock blocks
  p_smi_mdc  <: 0;
  p_smi_mdc  <: 0;
#ifdef XC2
  p_smi_8d <: 0x7F;
#else
  p_smi_mdio <: 0;
#endif

  // Preamble
  smi_bit_shift_out(0xffffffff, 32);
  // Start sequence & read code
  smi_bit_shift_out(0x6, 4);
  // phy address
  smi_bit_shift_out(PHY_ADDRESS, 5);
  // register address
  smi_bit_shift_out(reg, 5);
  // turn around for 2 clocks

  p_smi_mdc  <: 0;            // clock tick 1: negate MDC
#ifdef XC2
  p_smi_8d :> int discard;
#else
  p_smi_mdio :> int discard;  // clock tick 1: turn MDIO port around to become an input
                               // clock tick 2: sample MDIO
#endif
  // MDC  outs and MDIO ins should now be paired:
  // MDC  out executed first schedules out data for next clock tick
  // MDIO in  exectued second pauses and returns the sample data on the next clock tick

  // second turn around clock
  smi_bit_shift_in(2);
  // Read the register's data
  readData = smi_bit_shift_in(16);

  // End MDC clock pulse
  p_smi_mdc  <: 0;
  // Turn around Mdio
#ifndef XC2
  p_smi_mdio <: 0;
#endif

  return (readData);

}

/* Register write, data values are 16-bit */
void smi_wr( int reg, int val)
{
  // MDIO is sampled on the rising edge of MDC, so MDIO changes on the falling edge of MDC
  // Packet: 31 1's,0, 1,(write: 0,1)(read: 1,0), PHY Addr [4:0], Reg Addr [4:0], turnaround [2], data [15:0]
  // MSBs are transferred first.

  // output to the ports to ensure synchronisation with clock blocks
  p_smi_mdc  <: 0;
  p_smi_mdc  <: 0;
#ifdef XC2
  p_smi_8d <: 0x7F;
#else
  p_smi_mdio <: 0;
#endif

  // Preamble
  smi_bit_shift_out(0xffffffff, 32);
  // Start sequence & write code
  smi_bit_shift_out(0x5, 4);
  // phy address
  smi_bit_shift_out(PHY_ADDRESS, 5);
  // register address
  smi_bit_shift_out(reg, 5);
  // turn around for 2 clocks
  smi_bit_shift_out(0, 2);
  // turn around for 16 clocks
  smi_bit_shift_out(val, 16);

  // End MDC clock pulse
  p_smi_mdc  <: 0;
  // MDIO low
#ifdef XC2
  p_smi_8d <: 0x7F;
#else
  p_smi_mdio <: 0;
#endif
}
