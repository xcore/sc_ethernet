#include <xs1.h>
#include <xclib.h>
#include "mii_driver.h"
#include "mii_lite.h"
#include "mii_lld.h"

#include <platform.h>

#include "mii_client.h"

// Timing tuning constants
#define CLK_DELAY_TRANSMIT   7  // Note: used to be 2 (improved simulator?)


void mii_port_init(mii_interface_lite_t &m) {
	configure_clock_src(m.clk_mii_rx, m.p_mii_rxclk);
	configure_clock_src(m.clk_mii_tx, m.p_mii_txclk);

	set_clock_fall_delay(m.clk_mii_tx, CLK_DELAY_TRANSMIT);

    configure_in_port_strobed_slave(m.p_mii_rxd, m.p_mii_rxdv, m.clk_mii_rx);
    configure_out_port_strobed_master(m.p_mii_txd, m.p_mii_txen, m.clk_mii_tx, 0);

	start_clock(m.clk_mii_rx);
	start_clock(m.clk_mii_tx);
}


// Timer value used to implement reset delay
#define RESET_TIMER_DELAY 50000

void phy_reset(out port p_mii_resetn, timer tmr) {
    unsigned int  resetTime;

    p_mii_resetn <: 0;
    tmr :> resetTime;
    resetTime += RESET_TIMER_DELAY;
    tmr when timerafter(resetTime) :> void;

    p_mii_resetn <: ~0;
    tmr :> resetTime;
    resetTime += RESET_TIMER_DELAY;
    tmr when timerafter(resetTime) :> void;
}

