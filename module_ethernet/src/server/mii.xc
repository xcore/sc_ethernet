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

// Timing tuning constants
#define PAD_DELAY_RECEIVE    0
#define PAD_DELAY_TRANSMIT   0
#define CLK_DELAY_RECEIVE    0
#define CLK_DELAY_TRANSMIT   7  // Note: used to be 2 (improved simulator?)
// After-init delay (used at the end of mii_init)
#define PHY_INIT_DELAY 10000000

#pragma xta command "add exclusion mii_rx_valid_hi"
#pragma xta command "add exclusion mii_rx_eof"
#pragma xta command "add exclusion mii_rx_begin"

// This constraint is a bit tighter to make up for the slacker constraint before
#pragma xta command "analyze endpoints mii_rx_word mii_rx_word"
#pragma xta command "set required - 300 ns"

#pragma xta command "analyze endpoints mii_rx_sof mii_rx_first_word"
#pragma xta command "set required - 320 ns"

// This constaint is a bit slack but the following one is tighter so it all 
// evens out using the extra word buffer in the port
#pragma xta command "analyze endpoints mii_rx_first_word mii_rx_word"
#pragma xta command "set required - 340 ns"

#pragma xta command "remove exclusion mii_rx_valid_hi"
#pragma xta command "remove exclusion mii_rx_eof"

#pragma xta command "add exclusion mii_rx_word"
#pragma xta command "add exclusion mii_rx_after_preamble"
#pragma xta command "add exclusion mii_rx_eof"
#pragma xta command "analyze endpoints mii_rx_eof mii_rx_sof"
#pragma xta command "set required - 1520 ns"

#pragma unsafe arrays
void mii_rx_pins(mii_mempool_t rxmem_hp, mii_mempool_t rxmem_lp,
		in port p_mii_rxdv, in buffered port:32 p_mii_rxd, int ifnum,
		streaming chanend c) {
	timer tmr;
	unsigned poly = 0xEDB88320;

	p_mii_rxdv	when pinseq(0) :> int lo;

	while (1)
	{
		unsigned i = 1;
		int length;
		unsigned time;
		unsigned word;
		unsigned buf, buf_lp, dptr, dptr_lp;
		int buf_lp_valid = 1, buf_valid;
#ifdef ETHERNET_HP_QUEUE
		unsigned buf_hp, dptr_hp;
		int buf_hp_valid = 1;
#endif

		int endofframe = 0;
		unsigned crc = 0x9226F562;

#pragma xta label "mii_rx_begin"
		buf = 0;
#ifdef ETHERNET_HP_QUEUE
		buf_hp = mii_malloc(rxmem_hp);
#endif
		buf_lp = mii_malloc(rxmem_lp);

#ifdef ETHERNET_HP_QUEUE
		if (!buf_hp && !buf_lp) {
			continue;
		}

		if (!buf_hp) {
			printstrln("hp buf ovr");
			buf_hp_valid = 0;
			buf_hp = buf_lp;
		}
		else if (!buf_lp) {
			buf_lp_valid = 0;
			buf_lp = buf_hp;
		}
#else
		if (!buf_lp)
		continue;
#endif

		set_buf_src_port(buf_lp, 0);
		set_buf_timestamp_id(buf_lp, 0);
#ifdef ETHERNET_HP_QUEUE
		set_buf_src_port(buf_hp, 0);
		set_buf_timestamp_id(buf_hp, 0);
#endif

#pragma xta endpoint "mii_rx_valid_hi"                
		p_mii_rxdv when pinseq(1) :> int hi;

#pragma xta endpoint "mii_rx_sof"                    
		p_mii_rxd when pinseq(0xD) :> int sof;

#pragma xta endpoint "mii_rx_after_preamble"                    
		tmr :> time;
		set_buf_timestamp(buf_lp, time);
		dptr_lp = get_buf_data_ptr(buf_lp);
#ifdef ETHERNET_HP_QUEUE
		dptr_hp = get_buf_data_ptr(buf_hp);
		set_buf_timestamp(buf_hp, time);
#endif

#pragma xta endpoint "mii_rx_first_word"
		p_mii_rxd :> word;
		crc32(crc, word, poly);
		set_data_word_imm(dptr_lp, 0, word);
#ifdef ETHERNET_HP_QUEUE
		set_data_word_imm(dptr_hp, 0, word);
#endif

		do
		{
			select
			{
#pragma xta endpoint "mii_rx_word"                
				case p_mii_rxd :> word:
				set_data_word(dptr_lp, i, word);
#ifdef ETHERNET_HP_QUEUE
				set_data_word(dptr_hp, i, word);
#endif
				crc32(crc, word, poly);
				i++;
				break;
				case p_mii_rxdv when pinseq(0) :> int lo:
				{
					unsigned tail;
					int taillen;
					int endbytes;
					int error = 0;
#ifdef ETHERNET_HP_QUEUE
					unsigned short etype;
#endif

#ifdef ETHERNET_HP_QUEUE
					etype = (unsigned short) get_data_word(dptr_lp, 3);

					if (etype == 0x0081) {
						buf = buf_hp;
						dptr = dptr_hp;
						buf_valid = buf_hp_valid;
					}
					else {
						buf = buf_lp;
						dptr = dptr_lp;
						buf_valid = buf_lp_valid;
					}
#else
					buf = buf_lp;
					dptr = dptr_lp;
					buf_valid = buf_lp_valid;
#endif

					taillen = endin(p_mii_rxd);
#pragma xta endpoint "mii_rx_eof"                
					p_mii_rxd :> tail;

					length = (i-1) << 2;
					tail = tail >> (32 - taillen);
					endbytes = (taillen >> 3);
					length += endbytes;

					if (length < 60 || length > 1514)
					buf_valid = 0;

					set_buf_length(buf, length);

					if (buf_valid)
					c <: buf;

					set_data_word(dptr, i, tail);

					// pass the (partial) crc for upper layers to handle
					set_buf_crc(buf, crc);

					endofframe = 1;

					break;
				}
			}
		}while (!endofframe);

		if (buf && buf_valid)
		mii_realloc(buf, (length+(3+BUF_DATA_OFFSET*4))&~0x3);
	}

	return;
}

#pragma unsafe arrays
void mii_tx_pins0(int k, mii_packet_t &buf, mii_queue_t &ts_queue,
		out buffered port:32 p_mii_txd, int ifnum) {
	register const unsigned poly = 0xEDB88320;
	timer tmr;
	unsigned int time;
	int bytes_left;
	unsigned int crc = 0;
	unsigned int word;
	unsigned int prev_length = 0;
	int i = 0;
	int j = 0;

	bytes_left = buf.length;

	//  printintln(bytes_left);

	p_mii_txd <: 0x55555555;
	p_mii_txd <: 0x55555555;
	p_mii_txd <: 0xD5555555;
#ifndef TX_TIMESTAMP_END_OF_PACKET
	tmr :> buf.timestamp;
#endif

	word = buf.data[i];
	p_mii_txd <: word;
	i++;
	crc32(crc, ~word, poly);
	bytes_left -=4;
	j+=4;

	word = buf.data[i];
	//      while (bytes_left > 3) {
	//  while (!buf.complete || (j< (buf.length-3))) {
	while ((j< (buf.length-3))) {
		p_mii_txd <: word;
		i++;
		crc32(crc, word, poly);
		word = buf.data[i];
		//bytes_left -= 4;
		j += 4;
	}
#ifdef TX_TIMESTAMP_END_OF_PACKET
	tmr :> buf.timestamp;
#endif
	bytes_left = buf.length-j;
	prev_length = buf.length;

	switch (bytes_left)
	{
		case 0:
		crc32(crc, 0, poly);
		crc = ~crc;
		p_mii_txd <: crc;
		break;
		case 1:
		crc8shr(crc, word, poly);
		//p_mii_txd:8 <: word;
		partout(p_mii_txd, 8, word);
		crc32(crc, 0, poly);
		crc = ~crc;
		p_mii_txd <: crc;
		break;
		case 2:
		//p_mii_txd:16 <: word;
		partout(p_mii_txd, 16, word);
		word = crc8shr(crc, word, poly);
		crc8shr(crc, word, poly);
		crc32(crc, 0, poly);
		crc = ~crc;
		p_mii_txd <: crc;
		break;
		case 3:
		//p_mii_txd:24 <: word;
		partout(p_mii_txd, 24, word);
		word = crc8shr(crc, word, poly);
		word = crc8shr(crc, word, poly);
		crc8shr(crc, word, poly);
		crc32(crc, 0, poly);
		crc = ~crc;
		p_mii_txd <: crc;
		break;
	}

	if (get_and_dec_transmit_count(k) == 0) {
		if (buf.timestamp_id) {
			buf.stage = 2;
			add_queue_entry(ts_queue, k);
		}
		else {
			mii_free(k);
		}

	}
	tmr :> time;
	time+=196;
	tmr when timerafter(time) :> int tmp;
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

extern inline int get_buf_data(int buf, int n);
extern inline void set_buf_filter_result(int buf, int x);
extern inline int get_buf_filter_result(int buf);
