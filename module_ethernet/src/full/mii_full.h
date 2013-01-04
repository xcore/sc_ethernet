// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#ifndef __mii_full_h__
#define __mii_full_h__
#include <xs1.h>
#include <xccompat.h>
#include "mii.h"

#include "ethernet_conf_derived.h"

#ifndef NUM_ETHERNET_PORTS
#define NUM_ETHERNET_PORTS (1)
#endif

#ifndef NUM_ETHERNET_MASTER_PORTS
#define NUM_ETHERNET_MASTER_PORTS (1)
#endif

#ifndef MAX_ETHERNET_PACKET_SIZE
#define MAX_ETHERNET_PACKET_SIZE (1518)
#endif

#ifndef ETHERNET_RX_CRC_ERROR_CHECK
#define ETHERNET_RX_CRC_ERROR_CHECK (1)
#endif

#ifndef ETHERNET_COUNT_PACKETS
#define ETHERNET_COUNT_PACKETS (1)
#endif

#ifndef ETHERNET_RX_BUFSIZE_LOW_PRIORITY
#ifdef ETHERNET_RX_BUFSIZE
#define ETHERNET_RX_BUFSIZE_LOW_PRIORITY ETHERNET_RX_BUFSIZE
#else
#define ETHERNET_RX_BUFSIZE_LOW_PRIORITY (4096)
#endif
#endif // ETHERNET_RX_BUFSIZE_LOW_PRIORITY

#if ETHERNET_RX_HP_QUEUE
#ifndef ETHERNET_RX_BUFSIZE_HIGH_PRIORITY
#define ETHERNET_RX_BUFSIZE_HIGH_PRIORITY (2048)
#endif
#endif

#ifndef ETHERNET_TX_BUFSIZE_LOW_PRIORITY
#ifdef ETHERNET_TX_BUFSIZE
#define ETHERNET_TX_BUFSIZE_LOW_PRIORITY ETHERNET_TX_BUFSIZE
#else
#define ETHERNET_TX_BUFSIZE_LOW_PRIORITY (4096)
#endif
#endif // ETHERNET_TX_BUFSIZE_LOW_PRIORITY

#if ETHERNET_TX_HP_QUEUE
#ifndef ETHERNET_TX_BUFSIZE_HIGH_PRIORITY
#define ETHERNET_TX_BUFSIZE_HIGH_PRIORITY (2048)
#endif
#endif

#ifndef ETHERNET_MAX_TX_PACKET_SIZE
#define ETHERNET_MAX_TX_PACKET_SIZE (1518)
#endif

#ifndef ETHERNET_MAX_TX_HP_PACKET_SIZE
#define ETHERNET_MAX_TX_HP_PACKET_SIZE (1518)
#endif

#ifndef ETHERNET_MAX_TX_LP_PACKET_SIZE
#define ETHERNET_MAX_TX_LP_PACKET_SIZE (1518)
#endif


#define ETHERNET_USE_HARDWARE_LOCKS

#ifdef XCC_VERSION_MAJOR
#if XCC_VERSION_MAJOR >= 1102
#define ETHERNET_INLINE_PACKET_GET
#endif
#endif

#include "mii_queue.h"

#ifdef __XC__
void mii_init_full(REFERENCE_PARAM(mii_interface_full_t, m));
#endif


typedef struct mii_packet_t {
  #define BUF_OFFSET_length 0
  int length;                       //!< The length of the packet in bytes
  #define BUF_OFFSET_timestamp 1
  int timestamp;                    //!< The transmit or receive timestamp
  #define BUF_OFFSET_filter_result 2
  int filter_result;                //!< The bitfield of filter passes
  #define BUF_OFFSET_src_port 3
  int src_port;                     //!< The ethernet port which a packet arrived on
  #define BUF_OFFSET_timestamp_id 4
  int timestamp_id;                 //!< Client channel number which is waiting for a Tx timestamp
  #define BUF_OFFSET_stage 5
  int stage;                        //!< What stage in the Tx or Rx path the packet has reached
  #define BUF_OFFSET_tcount 6
  int tcount;                       //!< Number of remaining clients who need to be send this RX packet minus one
  #define BUF_OFFSET_crc 7
  int crc;                          //!< The calculated CRC
  #define BUF_OFFSET_forwarding 8
  int forwarding;					//!< A bitfield for tracking forwarding of the packet to other ports
  #define BUF_DATA_OFFSET 9
  unsigned int data[(MAX_ETHERNET_PACKET_SIZE+3)/4];
} mii_packet_t;

#define MII_PACKET_HEADER_SIZE (sizeof(mii_packet_t) - ((MAX_ETHERNET_PACKET_SIZE+3)/4)*4)

#define STRINGIFY0(x) #x
#define STRINGIFY(x) STRINGIFY0(x)

#ifdef ETHERNET_INLINE_PACKET_GET
// The inline assembler version of the Get breaks.  Use a C function until
// a tools fix is available
#define create_buf_getset(field) \
  inline int mii_packet_get_##field (int buf) { \
    int x; \
    __asm__("ldw %0,%1[" STRINGIFY(BUF_OFFSET_ ## field) "]":"=r"(x):"r"(buf)); \
    return x; \
 } \
 inline void mii_packet_set_##field (int buf, int x) { \
  __asm__("stw %1, %0[" STRINGIFY(BUF_OFFSET_ ## field) "]"::"r"(buf),"r"(x)); \
 }
#else
// Temporary version of the get/set to avoid compiler issue with inline assembler
#define create_buf_getset(field) \
 int mii_packet_get_##field (int buf); \
 inline void mii_packet_set_##field (int buf, int x) { \
  __asm__("stw %1, %0[" STRINGIFY(BUF_OFFSET_ ## field) "]"::"r"(buf),"r"(x)); \
 }
#endif

create_buf_getset(length)
create_buf_getset(timestamp)
create_buf_getset(filter_result)
create_buf_getset(src_port)
create_buf_getset(timestamp_id)
create_buf_getset(stage)
create_buf_getset(tcount)
create_buf_getset(crc)
create_buf_getset(forwarding)

inline int mii_packet_get_data_ptr(int buf) {
  return (buf+BUF_DATA_OFFSET*4);
}

inline void mii_packet_set_data_word(int data, int n, int v) {
  __asm__("stw %0,%1[%2]"::"r"(v),"r"(data),"r"(n));
}

#ifdef ETHERNET_INLINE_PACKET_GET
inline int mii_packet_get_data_word(int data, int n) {
  int x;
  __asm__("ldw %0,%1[%2]":"=r"(x):"r"(data),"r"(n));
  return x;
}
#else
int mii_packet_get_data_word(int data, int n);
#endif

#define mii_packet_set_data_word_imm(data, n, v) \
  asm("stw %0,%1[" STRINGIFY(n) "]"::"r"(v),"r"(data));

#define mii_packet_get_data_word_imm(data, n, v) \
  asm("ldw %0,%1[" STRINGIFY(n) "]":"=r"(v):"r"(data));


inline void mii_packet_set_data(int buf, int n, int v) {
  __asm__("stw %0,%1[%2]"::"r"(v),"r"(buf),"r"(n+BUF_DATA_OFFSET));
}

inline void mii_packet_set_data_short(int buf, int n, int v) {
  __asm__("st16 %0,%1[%2]"::"r"(v),"r"(buf),"r"(n+(BUF_DATA_OFFSET*2)));
}

inline void mii_packet_set_data_byte(int buf, int n, int v) {
  __asm__("st8 %0,%1[%2]"::"r"(v),"r"(buf),"r"(n+(BUF_DATA_OFFSET*4)));
}

#ifdef __XC__
#define PORT_PARAM(param, name) param name
#else
#define PORT_PARAM(param, name) unsigned name
#endif

#ifdef __XC__
#define CHANEND_PARAM(param, name) param name
#else
#define CHANEND_PARAM(param, name) unsigned name
#endif

#if ETHERNET_COUNT_PACKETS
void ethernet_get_mii_counts(REFERENCE_PARAM(unsigned,dropped));
#endif

void mii_rx_pins(
#if ETHERNET_RX_HP_QUEUE
      unsigned rxmem_hp,
#endif
      unsigned rxmem_lp,
      PORT_PARAM(in port, p_mii_rxdv),
      PORT_PARAM(in buffered port:32, p_mii_rxd),
      int ifnum,
      CHANEND_PARAM(streaming chanend, c));

void mii_tx_pins(
#if (NUM_ETHERNET_PORTS > 1) && !defined(DISABLE_ETHERNET_PORT_FORWARDING)
#if (NUM_ETHERNET_MASTER_PORTS > 1) && (ETHERNET_TX_HP_QUEUE)
		  unsigned hp_forward[],
#endif
		  unsigned lp_forward[],
#endif
#if ETHERNET_TX_HP_QUEUE
      unsigned hp_mempool,
#endif
      unsigned lp_mempool,
      REFERENCE_PARAM(mii_ts_queue_t, ts_queue),
      PORT_PARAM(out buffered port:32, p_mii_txd),
      int ifnum);

// MII Slave (PHY Mode)
void mii_slave_tx_pins(
     unsigned rxmem_lp,
     PORT_PARAM(in port, p_mii_rxdv),
     PORT_PARAM(in buffered port:32, p_mii_rxd),
     int ifnum,
     CHANEND_PARAM(streaming chanend, c));

void mii_slave_rx_pins(
#if (NUM_ETHERNET_PORTS > 1) && !defined(DISABLE_ETHERNET_PORT_FORWARDING)
        unsigned lp_forward[],
#endif
        unsigned lp_mempool,
        PORT_PARAM(out buffered port:32, p_mii_rxd),
        int ifnum);

#endif
