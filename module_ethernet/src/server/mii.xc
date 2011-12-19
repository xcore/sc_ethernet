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

// Timing tuning constants
#define PAD_DELAY_RECEIVE    0
#define PAD_DELAY_TRANSMIT   0
#define CLK_DELAY_RECEIVE    0
#define CLK_DELAY_TRANSMIT   7  // Note: used to be 2 (improved simulator?)
// After-init delay (used at the end of mii_init)
#define PHY_INIT_DELAY 10000000

#define ETHERNET_IFS_AS_REF_CLOCK_COUNT  (96)   // 12 bytes


// Receive timing constraints

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

#pragma xta command "analyze endpoints mii_tx_word mii_tx_crc_0"
#pragma xta command "set required - 320 ns"

#pragma xta command "analyze endpoints mii_tx_word mii_tx_final_partword_1"
#pragma xta command "set required - 320 ns"

#pragma xta command "analyze endpoints mii_tx_word mii_tx_final_partword_2"
#pragma xta command "set required - 320 ns"

#pragma xta command "analyze endpoints mii_tx_word mii_tx_final_partword_3"
#pragma xta command "set required - 320 ns"

#pragma xta command "analyze endpoints mii_tx_final_partword_1 mii_tx_crc_1"
#pragma xta command "set required - 80 ns"

#pragma xta command "analyze endpoints mii_tx_final_partword_2 mii_tx_crc_2"
#pragma xta command "set required - 160 ns"

#pragma xta command "analyze endpoints mii_tx_final_partword_3 mii_tx_crc_3"
#pragma xta command "set required - 240 ns"

// check the transmit interframe space.  It should ideally be quite close to 1560, which will
// allow the timer check to control the transmission rather than being instruction time bound

//#pragma xta command "remove exclusion *"
//#pragma xta command "add exclusion mii_tx_sof"
//#pragma xta command "add exclusion mii_tx_buffer_not_marked_for_transmission"
//#pragma xta command "add exclusion mii_tx_not_valid_to_transmit"

//#pragma xta command "analyze endpoints mii_tx_end mii_tx_start"
//#pragma xta command "set required - 1560 ns"



#ifdef ETHERNET_COUNT_PACKETS
static unsigned int ethernet_mii_no_queue_entries = 0;

void ethernet_get_mii_counts(unsigned& dropped) {
	dropped = ethernet_mii_no_queue_entries;
}
#endif

#pragma unsafe arrays
void mii_rx_pins(
#ifdef ETHERNET_RX_HP_QUEUE
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

	p_mii_rxdv when pinseq(0) :> int lo;

	while (1)
	{
#pragma xta label "mii_rx_begin"

		unsigned i;
		int endofframe;
		unsigned crc;
		int length;
		unsigned time;
		unsigned word;
		unsigned buf, dptr;
		unsigned buf_lp, dptr_lp;
#ifdef ETHERNET_RX_HP_QUEUE
		unsigned buf_hp, dptr_hp;
#endif

#ifdef ETHERNET_RX_HP_QUEUE
		buf_hp = mii_reserve(rxmem_hp);
#endif
		buf_lp = mii_reserve(rxmem_lp);

#ifdef ETHERNET_RX_HP_QUEUE
		if (buf_hp) {
			dptr_hp = mii_packet_get_data_ptr(buf_hp);
		} else {
			dptr_hp = 0;
		}
#endif

#pragma xta endpoint "mii_rx_sof"
		p_mii_rxd when pinseq(0xD) :> int sof;

#pragma xta endpoint "mii_rx_after_preamble"
		tmr :> time;

		if (buf_lp) {
			dptr_lp = mii_packet_get_data_ptr(buf_lp);
#ifdef ETHERNET_RX_HP_QUEUE
		} else if (buf_hp) {
			dptr_lp = dptr_hp;
#endif
		} else {
#pragma xta label "mii_no_availible_buffers"
#ifdef ETHERNET_COUNT_PACKETS
			ethernet_mii_no_queue_entries++;
#endif
			p_mii_rxdv when pinseq(0) :> int hi;
			clearbuf(p_mii_rxd);
			continue;
		}

		crc = 0x9226F562;

#ifdef ETHERNET_RX_HP_QUEUE
		if (!dptr_hp) dptr_hp = dptr_lp;
#endif

#pragma xta endpoint "mii_rx_first_word"
		p_mii_rxd :> word;
		crc32(crc, word, poly);
		mii_packet_set_data_word_imm(dptr_lp, 0, word);
#ifdef ETHERNET_RX_HP_QUEUE
		mii_packet_set_data_word_imm(dptr_hp, 0, word);
#endif

#pragma xta endpoint "mii_rx_second_word"
		p_mii_rxd :> word;
		crc32(crc, word, poly);
		mii_packet_set_data_word_imm(dptr_lp, 1, word);
#ifdef ETHERNET_RX_HP_QUEUE
		mii_packet_set_data_word_imm(dptr_hp, 1, word);
#endif

#pragma xta endpoint "mii_rx_third_word"
		p_mii_rxd :> word;
		crc32(crc, word, poly);
		mii_packet_set_data_word_imm(dptr_lp, 2, word);
#ifdef ETHERNET_RX_HP_QUEUE
		mii_packet_set_data_word_imm(dptr_hp, 2, word);
#endif

#pragma xta endpoint "mii_rx_ethertype_word"
		p_mii_rxd :> word;
		crc32(crc, word, poly);
		mii_packet_set_data_word_imm(dptr_lp, 3, word);
#ifdef ETHERNET_RX_HP_QUEUE
		mii_packet_set_data_word_imm(dptr_hp, 3, word);
#endif

		{
#ifdef ETHERNET_RX_HP_QUEUE
		unsigned short etype = (unsigned short)word;

		if (etype == 0x0081) {
			buf = buf_hp;
			dptr = dptr_hp;
		}
		else {
			buf = buf_lp;
			dptr = dptr_lp;
		}
#else
		buf = buf_lp;
		dptr = dptr_lp;
#endif
		}

#pragma xta endpoint "mii_rx_fifth_word"
		p_mii_rxd :> word;
		crc32(crc, word, poly);
		mii_packet_set_data_word_imm(dptr, 4, word);

		if (!buf) {
#pragma xta label "mii_rx_correct_priority_buffer_unavailable"
			p_mii_rxdv when pinseq(0) :> int hi;
#ifdef ETHERNET_COUNT_PACKETS
			ethernet_mii_no_queue_entries++;
#endif
			clearbuf(p_mii_rxd);
			continue;
		}

#pragma xta endpoint "mii_rx_sixth_word"
		p_mii_rxd :> word;
		crc32(crc, word, poly);
		mii_packet_set_data_word_imm(dptr, 5, word);

		mii_packet_set_src_port(buf, 0);
		mii_packet_set_timestamp_id(buf, 0);
		mii_packet_set_timestamp(buf, time);

		i = 6;
		endofframe = 0;

		do
		{
#pragma xta label "mii_rx_data_inner_loop"
			select
			{
#pragma xta endpoint "mii_rx_word"                
				case p_mii_rxd :> word:
				mii_packet_set_data_word(dptr, i, word);
				crc32(crc, word, poly);
				i++;
				break;
#pragma xta endpoint "mii_rx_eof"
				case p_mii_rxdv when pinseq(0) :> int lo:
				{
#pragma xta label "mii_eof_case"
					endofframe = 1;
					break;
				}
			}
		} while (!endofframe);

		{
			unsigned tail;
			int taillen;

			taillen = endin(p_mii_rxd);

			// Calculate final length - (i-1) to not count the CRC
			length = ((i-1) << 2) + (taillen >> 3);
			mii_packet_set_length(buf, length);

			// The remainder of the CRC calculation and the test takes place in the filter thread
			mii_packet_set_crc(buf, crc);

			p_mii_rxd :> tail;

			tail = tail >> (32 - taillen);

			mii_packet_set_data_word(dptr, i, tail);

			c <: buf;
			mii_commit(buf, (length+4+(BUF_DATA_OFFSET*4)));
		}
	}

	return;
}


////////////////////////////////// TRANSMIT ////////////////////////////////


// Global for the transmit slope variable
#if defined(ETHERNET_TX_HP_QUEUE) && defined(ETHERNET_TRAFFIC_SHAPER)
int g_mii_idle_slope=(11<<MII_CREDIT_FRACTIONAL_BITS);
#endif

// Do the real-time pin wiggling for a single packet
void mii_transmit_packet(unsigned buf, out buffered port:32 p_mii_txd, timer tmr)
{
	register const unsigned poly = 0xEDB88320;
	unsigned int crc = 0;

	unsigned int word;
	unsigned int data;
	unsigned int time;
	int i = 0;
	int word_count = mii_packet_get_length(buf);
	int tail_byte_count = word_count & 3;
	word_count = word_count >> 2;

#pragma xta endpoint "mii_tx_sof"
	p_mii_txd <: 0x55555555;
	p_mii_txd <: 0x55555555;
	p_mii_txd <: 0xD5555555;

#ifndef TX_TIMESTAMP_END_OF_PACKET
	tmr :> time;
	mii_packet_set_timestamp(buf, time);
#endif
	data = mii_packet_get_data_ptr(buf);

	word = mii_packet_get_data_word(data, i);
#pragma xta endpoint "mii_tx_first_word"
	p_mii_txd <: word;
	i++;
	crc32(crc, ~word, poly);

	do {
#pragma xta label "mii_tx_loop"
		word = mii_packet_get_data_word(data, i);
		i++;
		crc32(crc, word, poly);
#pragma xta endpoint "mii_tx_word"
		p_mii_txd <: word;
	} while (i < word_count);

#ifdef TX_TIMESTAMP_END_OF_PACKET
	tmr :> time;
	mii_packet_set_timestamp(buf, time);
#endif

	switch (tail_byte_count)
	{
		case 0:
			crc32(crc, 0, poly);
			crc = ~crc;
#pragma xta endpoint "mii_tx_crc_0"
			p_mii_txd <: crc;
			break;
		case 1:
			word = mii_packet_get_data_word(data, i);
			crc8shr(crc, word, poly);
#pragma xta endpoint "mii_tx_final_partword_1"
			partout(p_mii_txd, 8, word);
			crc32(crc, 0, poly);
			crc = ~crc;
#pragma xta endpoint "mii_tx_crc_1"
			p_mii_txd <: crc;
			break;
		case 2:
			word = mii_packet_get_data_word(data, i);
#pragma xta endpoint "mii_tx_final_partword_2"
			partout(p_mii_txd, 16, word);
			word = crc8shr(crc, word, poly);
			crc8shr(crc, word, poly);
			crc32(crc, 0, poly);
			crc = ~crc;
#pragma xta endpoint "mii_tx_crc_2"
			p_mii_txd <: crc;
			break;
		case 3:
			word = mii_packet_get_data_word(data, i);
#pragma xta endpoint "mii_tx_final_partword_3"
			partout(p_mii_txd, 24, word);
			word = crc8shr(crc, word, poly);
			word = crc8shr(crc, word, poly);
			crc8shr(crc, word, poly);
			crc32(crc, 0, poly);
			crc = ~crc;
#pragma xta endpoint "mii_tx_crc_3"
			p_mii_txd <: crc;
			break;
	}
}


#pragma unsafe arrays
void mii_tx_pins(
#if (NUM_ETHERNET_PORTS > 1) && !defined(DISABLE_ETHERNET_PORT_FORWARDING)
#ifdef ETHERNET_TX_HP_QUEUE
		mii_mempool_t hp_forward[],
#endif
		mii_mempool_t lp_forward[],
#endif
#ifdef ETHERNET_TX_HP_QUEUE
		mii_mempool_t hp_queue,
#endif
		mii_mempool_t lp_queue,
		mii_ts_queue_t &ts_queue,
		out buffered port:32 p_mii_txd,
		int ifnum)
{

#if defined(ETHERNET_TX_HP_QUEUE) && defined(ETHERNET_TRAFFIC_SHAPER)
	int credit = 0;
	int credit_time;
#endif
	int prev_eof_time, time;
	timer tmr;
	int ok_to_transmit=1;

#if defined(ETHERNET_TX_HP_QUEUE) && defined(ETHERNET_TRAFFIC_SHAPER)
	tmr :> credit_time;
#endif
	while (1) {
#pragma xta label "mii_tx_main_loop"
		unsigned buf;
		int bytes_left;

		int stage;
#if defined(ETHERNET_TX_HP_QUEUE) && defined(ETHERNET_TRAFFIC_SHAPER)
		int prev_credit_time;
		int idle_slope;
		int elapsed;
#endif

#ifdef ETHERNET_TX_HP_QUEUE
		buf = mii_get_next_buf(hp_queue);

#if (NUM_ETHERNET_PORTS > 1) && !defined(DISABLE_ETHERNET_PORT_FORWARDING)
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

#ifdef ETHERNET_TRAFFIC_SHAPER
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

#if (NUM_ETHERNET_PORTS > 1) && !defined(DISABLE_ETHERNET_PORT_FORWARDING)
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

void mii_init(mii_interface_t &m) {
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

