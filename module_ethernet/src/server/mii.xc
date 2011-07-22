// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include "mii_queue.h"
#include "mii.h"
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


#pragma unsafe arrays
void mii_rx_pins(mii_queue_t &free_queue,
                 mii_packet_t buf[],
                 in port p_mii_rxdv,
                 in buffered port:32 p_mii_rxd,
                 int ifnum,
                 streaming chanend c)
{
  const register unsigned poly = 0xEDB88320;
  timer tmr;

  p_mii_rxdv when pinseq(0) :> int lo;
  do
  {
    int endofframe = 0;
    int length = -4;
    register unsigned crc = 0x9226F562;
    unsigned time;
    unsigned word;
    unsigned i = 0, k=0;;

    //    k = get_queue_entry(free_queue);
    c :> k;

    buf[k].complete = 0;
    buf[k].src_port = ifnum;
    buf[k].timestamp_id = 0;

#pragma xta endpoint "start_of_frame"
    p_mii_rxdv when pinseq(1) :> int hi;

    p_mii_rxd when pinseq(0xD) :> int sof;

    tmr :> buf[k].timestamp;

    p_mii_rxd :> word;
    buf[k].data[i] = word;
    i++;
    length+=4;
    crc32(crc, word, poly);
    p_mii_rxd :> word;
    buf[k].data[i] = word;
    i++;
    length+=4;
    crc32(crc, word, poly);

    do
      {
        select
          {
          case p_mii_rxd :> word:
            {
              if (i >= (MAX_ETHERNET_PACKET_SIZE+3)/4) {
                // no need to do anything we have overrun the maximum packet
                // size
              }
              else {
                buf[k].data[i] = word;
                crc32(crc, word, poly);
                if (i==4)
                  c <: k;
                i++;
              }
              break;
            }
          case p_mii_rxdv when pinseq(0) :> int lo:
            {
              unsigned tail;
              int taillen;
              int endbytes;
              int error = 0;


              taillen = endin(p_mii_rxd);
#pragma xta endpoint "end_of_frame"
              p_mii_rxd :> tail;

              if (taillen & 7) {
                // odd number of nibbles in last word - alignment error
                error = 1;
              }
              else {
                length = (i-1) << 2;
                tail = tail >> (32 - taillen);
                endbytes =  (taillen >> 3);
                length += endbytes;

                buf[k].length = length;
                if (i < (MAX_ETHERNET_PACKET_SIZE+3)/4)
                  buf[k].data[i] = tail;


                switch (endbytes)
                  {
                  case 0:
                    break;
                  case 1:
                    tail = crc8shr(crc, tail, poly);
                    break;
                  case 2:
                    tail = crc8shr(crc, tail, poly);
                    tail = crc8shr(crc, tail, poly);
                    break;
                  case 3:
                    tail = crc8shr(crc, tail, poly);
                    tail = crc8shr(crc, tail, poly);
                    tail = crc8shr(crc, tail, poly);
                    break;
                  }

                if (~crc) {
                  error = 1;
                }
                else if (length < 60) {
                  error = 1;
                }

              }

              buf[k].complete = 1;

              //              if (!error && k)
              //              c <: k;

              if (i<4)
                c <: k;

              endofframe = 1;

              break;
            }
          }
      } while (!endofframe);

  } while (1);

  return;
}

#pragma unsafe arrays
void mii_tx_pins(mii_packet_t buf[],
                 mii_queue_t &in_queue,
                 mii_queue_t &free_queue,
                 mii_queue_t &ts_queue,
                 out buffered port:32 p_mii_txd,
                 int ifnum)
{
  register const unsigned poly = 0xEDB88320;
  timer tmr;
  unsigned int time;
  tmr :> time;
  while (1) {
    int bytes_left;
    unsigned int crc = 0;
    unsigned int word;
    unsigned int timestamp_id;
    unsigned int prev_length=0;
    int i=0,k=0;
    k = get_queue_entry_no_lock(in_queue);


    if (k) {
      int j=0;
      bytes_left = buf[k].length;

      p_mii_txd <: 0x55555555;
      p_mii_txd <: 0x55555555;
      p_mii_txd <: 0xD5555555;
      tmr :> buf[k].timestamp;



      word = buf[k].data[i];
      p_mii_txd <: word;
      i++;
      crc32(crc, ~word, poly);
      bytes_left -=4;
      j+=4;

      word = buf[k].data[i];
      //      while (bytes_left > 3) {
      while (!buf[k].complete || (j< (buf[k].length-3))) {
        p_mii_txd <: word;
        i++;
        crc32(crc, word, poly);
        word = buf[k].data[i];
        //bytes_left -= 4;
        j += 4;
      }
      bytes_left = buf[k].length-j;
      prev_length = buf[k].length;

      switch (bytes_left)
        {
        case 0:
          crc32(crc, 0, poly);
          crc = ~crc;
          p_mii_txd <: crc;
          break;
        case 1:
          crc8shr(crc, word, poly);
          partout(p_mii_txd, 8, word);
          crc32(crc, 0, poly);
          crc = ~crc;
          p_mii_txd <: crc;
          break;
        case 2:
          partout(p_mii_txd, 16, word);
          word = crc8shr(crc, word, poly);
          crc8shr(crc, word, poly);
          crc32(crc, 0, poly);
          crc = ~crc;
          p_mii_txd <: crc;
          break;
        case 3:
          partout(p_mii_txd, 24, word);
          word = crc8shr(crc, word, poly);
          word = crc8shr(crc, word, poly);
          crc8shr(crc, word, poly);
          crc32(crc, 0, poly);
          crc = ~crc;
          p_mii_txd <: crc;
          break;
        }
      tmr :> time;
      time+=196;
      tmr when timerafter(time) :> int tmp;

      if (get_and_dec_transmit_count(k) == 0) {


        if (buf[k].timestamp_id) {
          add_queue_entry(ts_queue, k);
        }
        else
          free_queue_entry(k);
      }
    }
  }
}

void mii_init(mii_interface_t &m, clock clk_mii_ref)
{
#ifndef SIMULATION
  timer tmr;
  unsigned t;
#endif
  set_port_use_on(m.p_mii_rxclk);
  m.p_mii_rxclk :> int x;
  set_port_use_on(m.p_mii_rxd);
  set_port_use_on(m.p_mii_rxdv);
  set_port_use_on(m.p_mii_rxer);
  set_port_clock(m.p_mii_rxclk, clk_mii_ref);
  set_port_clock(m.p_mii_rxd, clk_mii_ref);
  set_port_clock(m.p_mii_rxdv, clk_mii_ref);

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
  set_port_clock(m.p_mii_txclk, clk_mii_ref);
  set_port_clock(m.p_mii_txd, clk_mii_ref);
  set_port_clock(m.p_mii_txen, clk_mii_ref);

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




