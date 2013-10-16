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

#define ETHERNET_IFS_AS_REF_CLOCK_COUNT  (96)   // 12 bytes


// Receive timing constraints

//#pragma xta command "remove exclusion *"
//#pragma xta command "add exclusion mii_rx_eof"
//#pragma xta command "add exclusion mii_rx_begin"
//#pragma xta command "add exclusion mii_eof_case"
//#pragma xta command "add exclusion mii_no_availible_buffers"

// Start of frame to first word is 32 bits = 320ns
//#pragma xta command "analyze endpoints mii_rx_sof mii_rx_first_word"
//#pragma xta command "set required - 320 ns"

//#pragma xta command "analyze endpoints mii_rx_first_word mii_rx_second_word"
//#pragma xta command "set required - 320 ns"

//#pragma xta command "analyze endpoints mii_rx_second_word mii_rx_third_word"
//#pragma xta command "set required - 320 ns"

//#pragma xta command "analyze endpoints mii_rx_third_word mii_rx_ethertype_word"
//#pragma xta command "set required - 320 ns"

//#pragma xta command "analyze endpoints mii_rx_ethertype_word mii_rx_fifth_word"
//#pragma xta command "set required - 320 ns"

//#pragma xta command "analyze endpoints mii_rx_fifth_word mii_rx_sixth_word"
//#pragma xta command "set required - 320 ns"

//#pragma xta command "analyze endpoints mii_rx_sixth_word mii_rx_word"
//#pragma xta command "set required - 320 ns"

//#pragma xta command "analyze endpoints mii_rx_word mii_rx_word"
//#pragma xta command "set required - 300 ns"

// The end of frame timing is 12 octets IFS + 7 octets preamble + 1 nibble preamble = 156 bits - 1560ns
//
// note: the RXDV will come low with the start of the pre-amble, but the code
//       checks for a valid RXDV and then starts hunting for the 'D' nibble at
//       the end of the pre-amble, so we don't need to spot the rising edge of
//       the RXDV, only the point where RXDV is valid and there is a 'D' on the
//       data lines.
//#pragma xta command "remove exclusion *"
//#pragma xta command "add exclusion mii_rx_after_preamble"
//#pragma xta command "add exclusion mii_rx_eof"
//#pragma xta command "add exclusion mii_no_availible_buffers"
//#pragma xta command "add exclusion mii_rx_correct_priority_buffer_unavailable"
//#pragma xta command "add exclusion mii_rx_data_inner_loop"
//#pragma xta command "analyze endpoints mii_rx_eof mii_rx_sof"
//#pragma xta command "set required - 1560 ns"

// Transmit timing constraints

//#pragma xta command "remove exclusion *"
//#pragma xta command "add exclusion mii_tx_start"
//#pragma xta command "add exclusion mii_tx_end"

//#pragma xta command "add loop mii_tx_loop 1"

//#pragma xta command "analyze endpoints mii_tx_sof mii_tx_first_word"
//#pragma xta command "set required - 640 ns"

//#pragma xta command "analyze endpoints mii_tx_first_word mii_tx_word"
//#pragma xta command "set required - 320 ns"

//#pragma xta command "analyze endpoints mii_tx_word mii_tx_word"
//#pragma xta command "set required - 320 ns"

//#pragma xta command "add loop mii_tx_loop 0"

//#pragma xta command "analyze endpoints mii_tx_word mii_tx_crc_0"
//#pragma xta command "set required - 320 ns"

//#pragma xta command "analyze endpoints mii_tx_word mii_tx_final_partword_1"
//#pragma xta command "set required - 320 ns"

//#pragma xta command "analyze endpoints mii_tx_word mii_tx_final_partword_2"
//#pragma xta command "set required - 320 ns"

//#pragma xta command "analyze endpoints mii_tx_word mii_tx_final_partword_3"
//#pragma xta command "set required - 320 ns"

//#pragma xta command "analyze endpoints mii_tx_final_partword_1 mii_tx_crc_1"
//#pragma xta command "set required - 80 ns"

//#pragma xta command "analyze endpoints mii_tx_final_partword_2 mii_tx_crc_2"
//#pragma xta command "set required - 160 ns"

//#pragma xta command "analyze endpoints mii_tx_final_partword_3 mii_tx_crc_3"
//#pragma xta command "set required - 240 ns"

// check the transmit interframe space.  It should ideally be quite close to 1560, which will
// allow the timer check to control the transmission rather than being instruction time bound

////#pragma xta command "remove exclusion *"
////#pragma xta command "add exclusion mii_tx_sof"
////#pragma xta command "add exclusion mii_tx_buffer_not_marked_for_transmission"
////#pragma xta command "add exclusion mii_tx_not_valid_to_transmit"

////#pragma xta command "analyze endpoints mii_tx_end mii_tx_start"
////#pragma xta command "set required - 1560 ns"

#if ETHERNET_COUNT_PACKETS
static unsigned int ethernet_mii_no_queue_entries = 0;
#endif

#pragma unsafe arrays
void mii_slave_tx_pins(
        mii_mempool_t rxmem_lp,
        in port p_mii_txen,
        in buffered port:32 p_mii_txd,
        int ifnum,
        streaming chanend c)
{
    unsigned poly = 0xEDB88320;
    unsigned wrap_ptr = mii_get_wrap_ptr(rxmem_lp);

    p_mii_txen when pinseq(0) :> int lo;

    while (1)
    {
//#pragma xta label "mii_slave_tx_begin"

        unsigned ii = 0;
        int endofframe = 0;
        unsigned crc;
        int length;
        unsigned time;
        unsigned word;
        unsigned buf, dptr, end_ptr;

        buf = mii_reserve(rxmem_lp, end_ptr);

//#pragma xta endpoint "mii_rx_sof"
        p_mii_txd when pinseq(0xD) :> int sof;

//#pragma xta endpoint "mii_rx_after_preamble"

        if (buf) {
            dptr = mii_packet_get_data_ptr(buf);
        } else {
//#pragma xta label "mii_no_availible_buffers"
#if ETHERNET_COUNT_PACKETS
            ethernet_mii_no_queue_entries++;
#endif
            p_mii_txen when pinseq(0) :> int hi;
            clearbuf(p_mii_txd);
            continue;
        }

        crc = 0x9226F562;

        do
        {
//#pragma xta label "mii_rx_data_inner_loop"
            select
            {
//#pragma xta endpoint "mii_rx_word"                
                case p_mii_txd :> word:
                {
                    if (dptr != end_ptr) {
                        mii_packet_set_data_word_imm(dptr, 0, word);
                        crc32(crc, word, poly);
                        ii += 4;
                        dptr += 4;
                    }
                    if (dptr == wrap_ptr)
                        asm("ldw %0,%0[0]":"=r"(dptr));
                    break;
                }
//#pragma xta endpoint "mii_rx_eof"
                case p_mii_txen when pinseq(0) :> int lo:
                {
//#pragma xta label "mii_eof_case"
                    endofframe = 1;
                    break;
                }
            }
        } while (!endofframe);

        {
            unsigned tail;
            int taillen;

            taillen = endin(p_mii_txd);

            // Calculate final length - (i-1) to not count the CRC
            //  length = ((i-1) << 2) + (taillen >> 3);
            length = ii + (taillen>>3);
            mii_packet_set_length(buf, length);

            // The remainder of the CRC calculation and the test takes place in the filter thread
            mii_packet_set_crc(buf, crc);

            p_mii_txd :> tail;

            tail = tail >> (32 - taillen);

            if (dptr != end_ptr) {
                mii_packet_set_timestamp(buf, time);
                mii_packet_set_data_word_imm(dptr, 0, tail);
                c <: buf;
                mii_commit(buf, dptr);
            }
        }
    }

    return;
}


void mii_slave_transmit_packet(unsigned buf, out buffered port:32 p_mii_rxd)
{
    register const unsigned poly = 0xEDB88320;
    unsigned int crc = 0;

    unsigned int word;
    unsigned int dptr;
    int i=0;
    int word_count = mii_packet_get_length(buf);
    int tail_byte_count = word_count & 3;
    int wrap_ptr;
    word_count = word_count >> 2;
    dptr = mii_packet_get_data_ptr(buf);
    wrap_ptr = mii_packet_get_wrap_ptr(buf);

//#pragma xta endpoint "mii_slave_tx_sof"
    p_mii_rxd <: 0x55555555;
    p_mii_rxd <: 0xD5555555;

    word = mii_packet_get_data_word(dptr, 0);
//#pragma xta endpoint "mii_slave_tx_first_word"
    p_mii_rxd <: word;
    dptr += 4;
    i++;
    crc32(crc, ~word, poly);

    do {
//#pragma xta label "mii_slave_tx_loop"
        mii_packet_get_data_word_imm(dptr, 0, word);
        dptr += 4;
        if (dptr == wrap_ptr)
            asm("ldw %0,%0[0]":"=r"(dptr));
        i++;
        crc32(crc, word, poly);
//#pragma xta endpoint "mii_slave_tx_word"
        p_mii_rxd <: word;
    } while (i < word_count);


    switch (tail_byte_count)
    {
        case 0:
            crc32(crc, 0, poly);
            crc = ~crc;
//#pragma xta endpoint "mii_slave_tx_crc_0"
            p_mii_rxd <: crc;
            break;
        case 1:
            word = mii_packet_get_data_word(dptr, 0);
            crc8shr(crc, word, poly);
//#pragma xta endpoint "mii_slave_tx_final_partword_1"
            partout(p_mii_rxd, 8, word);
            crc32(crc, 0, poly);
            crc = ~crc;
//#pragma xta endpoint "mii_slave_tx_crc_1"
            p_mii_rxd <: crc;
            break;
        case 2:
            word = mii_packet_get_data_word(dptr, 0);
//#pragma xta endpoint "mii_slave_tx_final_partword_2"
            partout(p_mii_rxd, 16, word);
            word = crc8shr(crc, word, poly);
            crc8shr(crc, word, poly);
            crc32(crc, 0, poly);
            crc = ~crc;
//#pragma xta endpoint "mii_slave_tx_crc_2"
            p_mii_rxd <: crc;
            break;
        case 3:
            word = mii_packet_get_data_word(dptr, 0);
//#pragma xta endpoint "mii_slave_tx_final_partword_3"
            partout(p_mii_rxd, 24, word);
            word = crc8shr(crc, word, poly);
            word = crc8shr(crc, word, poly);
            crc8shr(crc, word, poly);
            crc32(crc, 0, poly);
            crc = ~crc;
//#pragma xta endpoint "mii_slave_tx_crc_3"
            p_mii_rxd <: crc;
            break;
    }
}


#pragma unsafe arrays
void mii_slave_rx_pins(
#if (NUM_ETHERNET_PORTS > 1) && !defined(DISABLE_ETHERNET_PORT_FORWARDING)
        mii_mempool_t lp_forward[],
#endif
        mii_mempool_t lp_queue,
        out buffered port:32 p_mii_rxd,
        int ifnum)
{
    int prev_eof_time, time;
    timer tmr;
    int ok_to_transmit=1;

    while (1)
    {
//#pragma xta label "mii_slave_rx_main_loop"
        unsigned buf;
        int bytes_left;
        int stage;

        buf = mii_get_next_buf(lp_queue);

#if (NUM_ETHERNET_PORTS > 1) && !(DISABLE_ETHERNET_PORT_FORWARDING)
        if (!buf || mii_packet_get_stage(buf) == 0)
        {
            for (unsigned int i=0; i<NUM_ETHERNET_PORTS; ++i)
            {
                if (i == ifnum) continue;
                buf = mii_get_next_buf(lp_forward[i]);
                if (buf)
                {
                    if (mii_packet_get_forwarding(buf) != 0)
                    {
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
//#pragma xta endpoint "mii_slave_rx_not_valid_to_transmit"
            continue;
        }

        if (mii_packet_get_stage(buf) != 1) {
//#pragma xta endpoint "mii_slave_rx_buffer_not_marked_for_transmission"
            continue;
        }

//#pragma xta endpoint "mii_slave_rx_start"
        mii_slave_transmit_packet(buf, p_mii_rxd);
//#pragma xta endpoint "mii_slave_rx_end"

        tmr :> prev_eof_time;
        ok_to_transmit = 0;

        if (get_and_dec_transmit_count(buf) == 0) {
            mii_free(buf);
        }
    }
}

void mii_slave_init_full(mii_slave_interface_full_t &m)
{
    configure_clock_rate(m.clk_mii_slave, 100, 4);
    configure_port_clock_output(m.p_mii_slave_rxclk, m.clk_mii_slave);
    configure_port_clock_output(m.p_mii_slave_txclk, m.clk_mii_slave);
    configure_out_port(m.p_mii_slave_rxdv, m.clk_mii_slave, 0);

    configure_out_port_strobed_master(m.p_mii_slave_rxd, m.p_mii_slave_rxdv, m.clk_mii_slave, 0);
    configure_in_port_strobed_slave(m.p_mii_slave_txd, m.p_mii_slave_txen, m.clk_mii_slave);

    start_clock(m.clk_mii_slave);
}

