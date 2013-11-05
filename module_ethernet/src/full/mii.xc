// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include "mii_queue.h"
#include "mii.h"
#include "mii_malloc.h"
#include <print.h>
#include <stdlib.h>
#include <syscall.h>
#include "ethernet_server_def.h"
#include <xclib.h>

// As a performance/worst timing fix We have to use a hwtimer in
// mii_transmit when using tools 13+.
// Hopefully we can get rid of this at a later data
#if XCC_VERSION_MAJOR >= 1300
#include "hwtimer.h"
#else
typedef timer hwtimer_t;
#endif

// As of the v12/13 xTIMEcomper tools. The compiler schedules code around a
// bit too much which violates the timing constraints. This change to the
// crc32 makes it a barrier to scheduling. This is not really
// recommended practice since it inhibits the compiler in a bit of a hacky way,
// but is perfectly safe.
#undef crc32
#define crc32(a, b, c) {__builtin_crc32(a, b, c); asm volatile (""::"r"(a):"memory");}

// Timing tuning constants
#define PAD_DELAY_RECEIVE    0
#define PAD_DELAY_TRANSMIT   0
#define CLK_DELAY_RECEIVE    0
#define CLK_DELAY_TRANSMIT   7  // Note: used to be 2 (improved simulator?)
// After-init delay (used at the end of mii_init)
#define PHY_INIT_DELAY 10000000

#define ETHERNET_IFS_AS_REF_CLOCK_COUNT  (96)   // 12 bytes

// Receive timing constraints
#if ETHERNET_ENABLE_FULL_TIMINGS
#pragma xta command "remove exclusion *"
#pragma xta command "add exclusion mii_rx_eof"
#pragma xta command "add exclusion mii_rx_begin"
#pragma xta command "add exclusion mii_eof_case"
#pragma xta command "add exclusion mii_no_availible_buffers"

// Start of frame to first word is 32 bits = 320ns
#pragma xta command "analyze endpoints mii_rx_sof mii_rx_first_word"
#pragma xta command "set required - 320 ns"

#pragma xta command "analyze endpoints mii_rx_first_word mii_rx_second_word"
#pragma xta command "set required - 320 ns"

#pragma xta command "analyze endpoints mii_rx_second_word mii_rx_third_word"
#pragma xta command "set required - 320 ns"

#pragma xta command "analyze endpoints mii_rx_third_word mii_rx_ethertype_word"
#pragma xta command "set required - 320 ns"

#pragma xta command "analyze endpoints mii_rx_ethertype_word mii_rx_fifth_word"
#pragma xta command "set required - 320 ns"

#pragma xta command "analyze endpoints mii_rx_fifth_word mii_rx_sixth_word"
#pragma xta command "set required - 320 ns"

#pragma xta command "analyze endpoints mii_rx_sixth_word mii_rx_word"
#pragma xta command "set required - 320 ns"

#pragma xta command "analyze endpoints mii_rx_word mii_rx_word"
#pragma xta command "set required - 300 ns"

// The end of frame timing is 12 octets IFS + 7 octets preamble + 1 nibble preamble = 156 bits - 1560ns
//
// note: the RXDV will come low with the start of the pre-amble, but the code
//       checks for a valid RXDV and then starts hunting for the 'D' nibble at
//       the end of the pre-amble, so we don't need to spot the rising edge of
//       the RXDV, only the point where RXDV is valid and there is a 'D' on the
//       data lines.
#pragma xta command "remove exclusion *"
#pragma xta command "add exclusion mii_rx_after_preamble"
#pragma xta command "add exclusion mii_rx_eof"
#pragma xta command "add exclusion mii_no_availible_buffers"
#pragma xta command "add exclusion mii_rx_correct_priority_buffer_unavailable"
#pragma xta command "add exclusion mii_rx_data_inner_loop"
#pragma xta command "analyze endpoints mii_rx_eof mii_rx_sof"
#pragma xta command "set required - 1560 ns"

// Transmit timing constraints

#pragma xta command "remove exclusion *"
#pragma xta command "add exclusion mii_tx_start"
#pragma xta command "add exclusion mii_tx_end"

#pragma xta command "add loop mii_tx_loop 1"

#pragma xta command "analyze endpoints mii_tx_sof mii_tx_first_word"
#pragma xta command "set required - 640 ns"

#pragma xta command "analyze endpoints mii_tx_first_word mii_tx_word"
#pragma xta command "set required - 320 ns"

#pragma xta command "analyze endpoints mii_tx_word mii_tx_word"
#pragma xta command "set required - 320 ns"

#pragma xta command "add loop mii_tx_loop 0"

#pragma xta command "analyze endpoints mii_tx_word mii_tx_final_partword_3"
#pragma xta command "set required - 320 ns"

#pragma xta command "add exclusion mii_tx_final_partword_3"
#pragma xta command "analyze endpoints mii_tx_word mii_tx_final_partword_2"
#pragma xta command "set required - 320 ns"

#pragma xta command "add exclusion mii_tx_final_partword_2"
#pragma xta command "analyze endpoints mii_tx_word mii_tx_final_partword_1"
#pragma xta command "set required - 320 ns"

#pragma xta command "add exclusion mii_tx_final_partword_1"
#pragma xta command "analyze endpoints mii_tx_word mii_tx_crc_0"
#pragma xta command "set required - 320 ns"

#pragma xta command "remove exclusion mii_tx_final_partword_3"
#pragma xta command "remove exclusion mii_tx_final_partword_2"
#pragma xta command "remove exclusion mii_tx_final_partword_1"

#pragma xta command "analyze endpoints mii_tx_final_partword_3 mii_tx_final_partword_2"
#pragma xta command "set required - 80 ns"

#pragma xta command "analyze endpoints mii_tx_final_partword_2 mii_tx_final_partword_1"
#pragma xta command "set required - 80 ns"

#pragma xta command "analyze endpoints mii_tx_final_partword_1 mii_tx_crc_0"
#pragma xta command "set required - 80 ns"

#endif
// check the transmit interframe space.  It should ideally be quite close to 1560, which will
// allow the timer check to control the transmission rather than being instruction time bound

//#pragma xta command "remove exclusion *"
//#pragma xta command "add exclusion mii_tx_sof"
//#pragma xta command "add exclusion mii_tx_buffer_not_marked_for_transmission"
//#pragma xta command "add exclusion mii_tx_not_valid_to_transmit"

//#pragma xta command "analyze endpoints mii_tx_end mii_tx_start"
//#pragma xta command "set required - 1560 ns"


#if ETHERNET_COUNT_PACKETS
static unsigned int ethernet_mii_no_queue_entries = 0;

void ethernet_get_mii_counts(unsigned& dropped) {
	dropped = ethernet_mii_no_queue_entries;
}
#endif

#pragma unsafe arrays
void mii_rx_pins(
#if ETHERNET_RX_HP_QUEUE
		mii_mempool_t rxmem_hp,
#endif
		mii_mempool_t rxmem_lp,
		in port p_mii_rxdv,
		in buffered port:32 p_mii_rxd,
		int ifnum,
		streaming chanend c)
{
	timer tmr;
	unsigned poly = 0xEDB88320;
#if ETHERNET_RX_HP_QUEUE
        unsigned wrap_ptr_hp;
#endif
        unsigned wrap_ptr_lp;

#if ETHERNET_RX_HP_QUEUE
        wrap_ptr_hp = mii_get_wrap_ptr(rxmem_hp);
#endif
        wrap_ptr_lp = mii_get_wrap_ptr(rxmem_lp);

	p_mii_rxdv when pinseq(0) :> int lo;

	while (1)
	{
#pragma xta label "mii_rx_begin"

		unsigned ii;
		int endofframe;
		unsigned crc;
		int length;
		unsigned time;
		unsigned word;
		unsigned buf, dptr, wrap_ptr, end_ptr;
		unsigned buf_lp, dptr_lp;
        unsigned end_ptr_lp;
                unsigned int sixth_word;
#if ETHERNET_RX_HP_QUEUE
		unsigned buf_hp, dptr_hp, end_ptr_hp;
#endif

#if ETHERNET_RX_HP_QUEUE
		buf_hp = mii_reserve(rxmem_hp, end_ptr_hp);
#endif
		buf_lp = mii_reserve(rxmem_lp, end_ptr_lp);

#if ETHERNET_RX_HP_QUEUE
                dptr_hp = mii_packet_get_data_ptr(buf_hp);
#endif

#pragma xta endpoint "mii_rx_sof"
		p_mii_rxd when pinseq(0xD) :> int sof;

#pragma xta endpoint "mii_rx_after_preamble"
		tmr :> time;

		if (buf_lp) {
			dptr_lp = mii_packet_get_data_ptr(buf_lp);
#if ETHERNET_RX_HP_QUEUE
		} else if (buf_hp) {
			dptr_lp = dptr_hp;
#endif
		} else {
#pragma xta label "mii_no_availible_buffers"
#if ETHERNET_COUNT_PACKETS
			ethernet_mii_no_queue_entries++;
#endif
			p_mii_rxdv when pinseq(0) :> int hi;
			clearbuf(p_mii_rxd);
			continue;
		}

		crc = 0x9226F562;

#if ETHERNET_RX_HP_QUEUE
		if (!buf_hp) {
                  dptr_hp = dptr_lp;
                }
#endif

#pragma xta endpoint "mii_rx_first_word"
		p_mii_rxd :> word;
		crc32(crc, word, poly);
		mii_packet_set_data_word_imm(dptr_lp, 0, word);
#if ETHERNET_RX_HP_QUEUE
		mii_packet_set_data_word_imm(dptr_hp, 0, word);
#endif


#pragma xta endpoint "mii_rx_second_word"
		p_mii_rxd :> word;
		crc32(crc, word, poly);
		mii_packet_set_data_word_imm(dptr_lp, 1, word);
#if ETHERNET_RX_HP_QUEUE
		mii_packet_set_data_word_imm(dptr_hp, 1, word);
#endif

#pragma xta endpoint "mii_rx_third_word"
		p_mii_rxd :> word;
		crc32(crc, word, poly);
		mii_packet_set_data_word_imm(dptr_lp, 2, word);
#if ETHERNET_RX_HP_QUEUE
		mii_packet_set_data_word_imm(dptr_hp, 2, word);
#endif
		//mii_packet_set_timestamp_id(buf, 0);

#pragma xta endpoint "mii_rx_ethertype_word"
		p_mii_rxd :> word;
		crc32(crc, word, poly);
		mii_packet_set_data_word_imm(dptr_lp, 3, word);
#if ETHERNET_RX_HP_QUEUE
		mii_packet_set_data_word_imm(dptr_hp, 3, word);
#endif
		{
#if ETHERNET_RX_HP_QUEUE
		unsigned short etype = (unsigned short)word;

		if (etype == 0x0081) {
			buf = buf_hp;
			dptr = dptr_hp;
                        wrap_ptr = wrap_ptr_hp;
                        end_ptr = end_ptr_hp;
		}
		else {
			buf = buf_lp;
			dptr = dptr_lp;
                        wrap_ptr = wrap_ptr_lp;
                        end_ptr = end_ptr_lp;
		}
#else
		buf = buf_lp;
		dptr = dptr_lp;
                wrap_ptr = wrap_ptr_lp;
                end_ptr = end_ptr_lp;
#endif
		}

#pragma xta endpoint "mii_rx_fifth_word"
		p_mii_rxd :> word;
		crc32(crc, word, poly);

		if (!buf) {
#pragma xta label "mii_rx_correct_priority_buffer_unavailable"
			p_mii_rxdv when pinseq(0) :> int hi;
#if ETHERNET_COUNT_PACKETS
			ethernet_mii_no_queue_entries++;
#endif
			clearbuf(p_mii_rxd);
			continue;
		}
		mii_packet_set_data_word_imm(dptr, 4, word);

		dptr += 6*4;
		ii = 5*4;

#pragma xta endpoint "mii_rx_sixth_word"
		p_mii_rxd :> sixth_word;
		crc32(crc, sixth_word, poly);
                // Don't store the sixth word here to save time before the main loop starts
                // Store it at the end of frame instead

		do
		{
#pragma xta label "mii_rx_data_inner_loop"
			select
			{
#pragma xta endpoint "mii_rx_word"
				case p_mii_rxd :> word:
				  if (dptr != end_ptr) {
				    mii_packet_set_data_word_imm(dptr, 0, word);
				    crc32(crc, word, poly);
				    ii+=4;
                                    dptr+=4;
                                    if (dptr == wrap_ptr)
                                      asm("ldw %0,%0[0]":"=r"(dptr));
				  }
				  endofframe = 0;
				  break;
#pragma xta endpoint "mii_rx_eof"
				case p_mii_rxdv when pinseq(0) :> int lo:
				{
#pragma xta label "mii_eof_case"
					endofframe = 1;
                                        // Store the sixth word here to save time before the main loop starts
                                        mii_packet_set_data_word(mii_packet_get_data_ptr(buf), 5, sixth_word);
					break;
				}
			}
		} while (!endofframe);

		{
			unsigned tail;
			int taillen;

			taillen = endin(p_mii_rxd);

			// Calculate final length - (i-1) to not count the CRC
                        //  length = ((i-1) << 2) + (taillen >> 3);
                        length = ii + (taillen>>3);
			mii_packet_set_length(buf, length);

			// The remainder of the CRC calculation and the test takes place in the filter thread
			mii_packet_set_crc(buf, crc);

			p_mii_rxd :> tail;

			tail = tail >> (32 - taillen);
                        mii_packet_set_timestamp(buf, time);

			if (dptr != end_ptr) {
			  mii_packet_set_data_word_imm(dptr, 0, tail);
			  if (mii_commit(buf, dptr))
                            c <: buf;
			}
		}
	}

	return;
}


////////////////////////////////// TRANSMIT ////////////////////////////////


// Global for the transmit slope variable
#if (ETHERNET_TX_HP_QUEUE) && (ETHERNET_TRAFFIC_SHAPER)
int g_mii_idle_slope=(11<<MII_CREDIT_FRACTIONAL_BITS);
#endif

#undef crc32
#define crc32(a, b, c) {__builtin_crc32(a, b, c);}


// Do the real-time pin wiggling for a single packet
void mii_transmit_packet(unsigned buf, out buffered port:32 p_mii_txd, hwtimer_t tmr)
{
	register const unsigned poly = 0xEDB88320;
	unsigned int crc = 0;

	unsigned int word;
	unsigned int dptr;
	unsigned int time;
        int i=0;
	int word_count = mii_packet_get_length(buf);
	int tail_byte_count = word_count & 3;
        int wrap_ptr;
	word_count = word_count >> 2;
	dptr = mii_packet_get_data_ptr(buf);
        wrap_ptr = mii_packet_get_wrap_ptr(buf);

#pragma xta endpoint "mii_tx_sof"
	p_mii_txd <: 0x55555555;
	p_mii_txd <: 0xD5555555;

#if !TX_TIMESTAMP_END_OF_PACKET
	tmr :> time;
	mii_packet_set_timestamp(buf, time);
#endif

	word = mii_packet_get_data_word(dptr, 0);
#pragma xta endpoint "mii_tx_first_word"
	p_mii_txd <: word;
	dptr+=4;
        i++;
	crc32(crc, ~word, poly);

	do {
#pragma xta label "mii_tx_loop"
          mii_packet_get_data_word_imm(dptr, 0, word);
          dptr+=4;
          if (dptr == wrap_ptr)
            asm("ldw %0,%0[0]":"=r"(dptr));
          i++;
          crc32(crc, word, poly);
#pragma xta endpoint "mii_tx_word"
		p_mii_txd <: word;
	} while (i < word_count);

#if TX_TIMESTAMP_END_OF_PACKET
	tmr :> time;
	mii_packet_set_timestamp(buf, time);
#endif

        if (tail_byte_count) {
          word = mii_packet_get_data_word(dptr, 0);
          switch (tail_byte_count)
            {
            default:
              __builtin_unreachable();
              break;
            #pragma fallthrough
            case 3:
#pragma xta endpoint "mii_tx_final_partword_3"
              partout(p_mii_txd, 8, word);
              word = crc8shr(crc, word, poly);
            #pragma fallthrough
            case 2:
#pragma xta endpoint "mii_tx_final_partword_2"
              partout(p_mii_txd, 8, word);
              word = crc8shr(crc, word, poly);
            case 1:
#pragma xta endpoint "mii_tx_final_partword_1"
              partout(p_mii_txd, 8, word);
              crc8shr(crc, word, poly);
              break;
            }
	}
        crc32(crc, ~0, poly);
#pragma xta endpoint "mii_tx_crc_0"
        p_mii_txd <: crc;
}

#pragma unsafe arrays
void mii_tx_pins(
#if (NUM_ETHERNET_PORTS > 1) && (DISABLE_ETHERNET_PORT_FORWARDING)
#if ETHERNET_TX_HP_QUEUE
		mii_mempool_t hp_forward[],
#endif
		mii_mempool_t lp_forward[],
#endif
#if ETHERNET_TX_HP_QUEUE
		mii_mempool_t hp_queue,
#endif
		mii_mempool_t lp_queue,
		mii_ts_queue_t &ts_queue,
		out buffered port:32 p_mii_txd,
		int ifnum)
{

#if (ETHERNET_TX_HP_QUEUE) && (ETHERNET_TRAFFIC_SHAPER)
	int credit = 0;
	int credit_time;
#endif
	int prev_eof_time, time;
	hwtimer_t tmr;
	int ok_to_transmit=1;

#if (ETHERNET_TX_HP_QUEUE) && (ETHERNET_TRAFFIC_SHAPER)
	tmr :> credit_time;
#endif
	while (1) {
#pragma xta label "mii_tx_main_loop"
		unsigned buf;
		int bytes_left;

		int stage;
#if (ETHERNET_TX_HP_QUEUE) && (ETHERNET_TRAFFIC_SHAPER)
		int prev_credit_time;
		int idle_slope;
		int elapsed;
#endif

#if ETHERNET_TX_HP_QUEUE
		buf = mii_get_next_buf(hp_queue);

#if (NUM_ETHERNET_PORTS > 1) && !(DISABLE_ETHERNET_PORT_FORWARDING)
		if (!buf || mii_packet_get_stage(buf) == 0) {
			for (unsigned int i=0; i<NUM_ETHERNET_PORTS; ++i) {
				if (i == ifnum) continue;
				buf = mii_get_next_buf(hp_forward[i]);
				if (buf) {
					if (mii_packet_get_forwarding(buf) != 0) {
						if (mii_packet_get_and_clear_forwarding(buf, ifnum)) break;
					}
				}
				buf = 0;
			}
		}
#endif

#if ETHERNET_TRAFFIC_SHAPER
		if (buf && mii_packet_get_stage(buf) == 1) {

			if (credit < 0) {
				asm("ldw %0,dp[g_mii_idle_slope]":"=r"(idle_slope));

				prev_credit_time = credit_time;
				tmr :> credit_time;

				elapsed = credit_time - prev_credit_time;
				credit += elapsed * idle_slope;
			}

			if (credit < 0)
			buf = 0;
			else {
				int len = mii_packet_get_length(buf);
				credit = credit - len << (MII_CREDIT_FRACTIONAL_BITS+3);
			}

		}
		else {
			if (credit >= 0)
			credit = 0;
			tmr :> credit_time;
		}
#endif

		if (!buf || mii_packet_get_stage(buf) != 1)
		buf = mii_get_next_buf(lp_queue);
#else
		buf = mii_get_next_buf(lp_queue);

#endif

#if (NUM_ETHERNET_PORTS > 1) && !(DISABLE_ETHERNET_PORT_FORWARDING)
		if (!buf || mii_packet_get_stage(buf) == 0) {
			for (unsigned int i=0; i<NUM_ETHERNET_PORTS; ++i) {
				if (i == ifnum) continue;
				buf = mii_get_next_buf(lp_forward[i]);
				if (buf) {
					if (mii_packet_get_forwarding(buf) != 0) {
						if (mii_packet_get_and_clear_forwarding(buf, ifnum)) break;
					}
				}
				buf = 0;
			}
		}
#endif

		// Check that we are out of the IFS period
		tmr :> time;
		if (((int) time - (int) prev_eof_time) >= ETHERNET_IFS_AS_REF_CLOCK_COUNT) {
			ok_to_transmit = 1;
		}

		if (!buf || !ok_to_transmit) {
#pragma xta endpoint "mii_tx_not_valid_to_transmit"
			continue;
		}

		if (mii_packet_get_stage(buf) != 1) {
#pragma xta endpoint "mii_tx_buffer_not_marked_for_transmission"
			continue;
		}

#pragma xta endpoint "mii_tx_start"
		mii_transmit_packet(buf, p_mii_txd, tmr);
#pragma xta endpoint "mii_tx_end"

		tmr :> prev_eof_time;
		ok_to_transmit = 0;

		if (get_and_dec_transmit_count(buf) == 0) {
			if (mii_packet_get_timestamp_id(buf)) {
				mii_packet_set_stage(buf, 2);
				add_ts_queue_entry(ts_queue, buf);
			}
			else {
				mii_free(buf);
			}
		}
	}
}


#ifdef ETH_REF_CLOCK
extern clock ETH_REF_CLOCK;
#endif

void mii_init_full(mii_interface_full_t &m) {
#ifndef SIMULATION
	timer tmr;
	unsigned t;
#endif
	set_port_use_on(m.p_mii_rxclk);
    m.p_mii_rxclk :> int x;
	set_port_use_on(m.p_mii_rxd);
	set_port_use_on(m.p_mii_rxdv);
	set_port_use_on(m.p_mii_rxer);
#ifdef ETH_REF_CLOCK
	set_port_clock(m.p_mii_rxclk, ETH_REF_CLOCK);
	set_port_clock(m.p_mii_rxd, ETH_REF_CLOCK);
	set_port_clock(m.p_mii_rxdv, ETH_REF_CLOCK);
#endif

	set_pad_delay(m.p_mii_rxclk, PAD_DELAY_RECEIVE);

	set_port_strobed(m.p_mii_rxd);
	set_port_slave(m.p_mii_rxd);

	set_clock_on(m.clk_mii_rx);
	set_clock_src(m.clk_mii_rx, m.p_mii_rxclk);
	set_clock_ready_src(m.clk_mii_rx, m.p_mii_rxdv);
	set_port_clock(m.p_mii_rxd, m.clk_mii_rx);
	set_port_clock(m.p_mii_rxdv, m.clk_mii_rx);

	set_clock_rise_delay(m.clk_mii_rx, CLK_DELAY_RECEIVE);

	start_clock(m.clk_mii_rx);

	clearbuf(m.p_mii_rxd);

	set_port_use_on(m.p_mii_txclk);
	set_port_use_on(m.p_mii_txd);
	set_port_use_on(m.p_mii_txen);
	//  set_port_use_on(m.p_mii_txer);
#ifdef ETH_REF_CLOCK
	set_port_clock(m.p_mii_txclk, ETH_REF_CLOCK);
	set_port_clock(m.p_mii_txd, ETH_REF_CLOCK);
	set_port_clock(m.p_mii_txen, ETH_REF_CLOCK);
#endif

	set_pad_delay(m.p_mii_txclk, PAD_DELAY_TRANSMIT);

	m.p_mii_txd <: 0;
	m.p_mii_txen <: 0;
	//  m.p_mii_txer <: 0;
	sync(m.p_mii_txd);
	sync(m.p_mii_txen);
	//  sync(m.p_mii_txer);

	set_port_strobed(m.p_mii_txd);
	set_port_master(m.p_mii_txd);
	clearbuf(m.p_mii_txd);

	set_port_ready_src(m.p_mii_txen, m.p_mii_txd);
	set_port_mode_ready(m.p_mii_txen);

	set_clock_on(m.clk_mii_tx);
	set_clock_src(m.clk_mii_tx, m.p_mii_txclk);
	set_port_clock(m.p_mii_txd, m.clk_mii_tx);
	set_port_clock(m.p_mii_txen, m.clk_mii_tx);

	set_clock_fall_delay(m.clk_mii_tx, CLK_DELAY_TRANSMIT);

	start_clock(m.clk_mii_tx);

	clearbuf(m.p_mii_txd);

#ifndef SIMULATION
	tmr :> t;
	tmr when timerafter(t + PHY_INIT_DELAY) :> t;
#endif

}

