// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xclib.h>
#include "checksum.h"

#define u16_t unsigned short

/**
   * This implementation exploits various properties of the internet checksum
   * described in RFC 1071.
   * It assumes a little endian machine with no support for misaligned loads.
   *
   * We do as much as possible using 16bit loads. Fetching a 16bit value
   * will swap the bytes since data is stored in network order. Therefore the
   * the resulting sum will be swapped (Byte Order Independence).
   * We also use Byte Order Independence to aligned terms of the sum.
   * The sum:
   * [A, B] +' [C, D] +' ... +' [Y, Z] [1]
   * is equal the following sum with the bytes reversed
   * [0, A] +' [B, C] +' ... +' [Z, 0] [2]
   * If the terms in sum [1] are not 16bit aligned then the terms in sum [2]
   * will be, with the exception of the first and last bytes which can be dealt
   * with seperately. By testing for 16bit alignment and choosing to group
   * terms appropriately we can use 16bit loads for the majority of the data.
   * Finally the sum uses 32bit accumulator which is folded back into 16 bits
   * This saves us having to check for carry on each iteration of the loop.
   *
   * It might be possible to improve performance using parallel summation
   * (i.e. using 32bit addition), although this would need investigation.
   */
unsigned short checksum(const unsigned char data[], int skip, unsigned short len)
{
  int swap = 1;
  unsigned accum = 0;
  data += skip;
  const unsigned char *endptr = data + len - 1;

  if (len == 0)
    return 0;

  // Test for misaligned data
  if ((int)data % sizeof(u16_t) != 0)
  {
    swap = 0;
    accum += data[0] << 8;
    data++;
  }

  // At least two more bytes
  while (data < endptr)
  {
    accum += *((u16_t*)data);
    data += 2;
  }

  // Deal with misaligned end
  if (data == endptr)
    accum += data[0];

  // Fold carry into 16bits
  while (accum >> 16)
  {
    accum = (accum & 0xFFFF) + (accum >> 16);
  }

  if (swap)
    accum = byterev(~accum) >> 16;
  else
    accum = ~accum & 0xFFFF;

  return accum;
}

unsigned short checksum_ip(const unsigned char frame[])
{
  int i;
  unsigned accum = 0;

  for (i = 14; i < 34; i += 2)
  {
    accum += *((u16_t*)(frame + i));
  }

  // Fold carry into 16bits
  while (accum >> 16)
  {
    accum = (accum & 0xFFFF) + (accum >> 16);
  }

  accum = byterev(~accum) >> 16;

  return accum;
}

unsigned short checksum_udp(const unsigned char frame[], int udplen)
{
  int i;
  const unsigned char *endptr = frame + 34 + udplen - 1;
  unsigned accum = 0x1100;

  accum += (byterev((unsigned)udplen) >> 16) << 1;
  accum += *((u16_t*)(frame + 26));
  accum += *((u16_t*)(frame + 28));
  accum += *((u16_t*)(frame + 30));
  accum += *((u16_t*)(frame + 32));
  accum += *((u16_t*)(frame + 34));
  accum += *((u16_t*)(frame + 36));
  for (i = 42; frame + i < endptr; i += 2)
  {
    accum += *((u16_t*)(frame + i));
  }

  // Deal with misaligned end
  if (frame + i == endptr)
    accum += *endptr;

  // Fold carry into 16bits
  while (accum >> 16)
  {
    accum = (accum & 0xFFFF) + (accum >> 16);
  }

  accum = byterev(~accum) >> 16;

  return accum;
}
