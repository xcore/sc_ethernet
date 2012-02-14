// Copyright (c) 2011, XMOS Ltd., All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include "mii.h"
#include "mii_queue.h"
#include "ethernet_server_def.h"
#include <xccompat.h>
#include <print.h>
#include "mii_malloc.h"
#include "mii_filter.h"
#include "mac_custom_filter.h"

// Smallest packet + interframe gap is 84 bytes = 6.72 us
#pragma xta command "analyze endpoints rx_packet rx_packet"
#pragma xta command "set required - 6.72 us"


int mac_custom_filter_coerce(int);


#define is_broadcast(buf) (mii_packet_get_data(buf,0) & 0x1)
#define compare_mac(buf,mac) (mii_packet_get_data(buf,0) == mac[0] && ((short) mii_packet_get_data(buf,1)) == ((short) mac[1]))

#ifdef ETHERNET_COUNT_PACKETS
static unsigned ethernet_filtered_by_address=0;
static unsigned ethernet_filtered_by_user_filter=0;
static unsigned ethernet_filtered_by_length=0;
static unsigned ethernet_filtered_by_bad_crc=0;

void ethernet_get_filter_counts(unsigned &address, unsigned &filter, unsigned &length, unsigned &crc)
{
	address = ethernet_filtered_by_address;
	filter = ethernet_filtered_by_user_filter;
	length = ethernet_filtered_by_length;
	crc = ethernet_filtered_by_bad_crc;
}
#endif


#pragma unsafe arrays
void ethernet_filter(const int mac[], streaming chanend c[NUM_ETHERNET_PORTS]) {
	int buf;

	while (1)
	{
		select
		{
#pragma xta endpoint "rx_packet"
			case (int ifnum=0; ifnum<NUM_ETHERNET_PORTS; ifnum++) c[ifnum] :> buf :
			{
				if (buf)
				{
					int length = mii_packet_get_length(buf);

#ifdef ETHERNET_RX_CRC_ERROR_CHECK
					unsigned poly = 0xEDB88320;
					unsigned crc = mii_packet_get_crc(buf);
					int endbytes;
					int tail;

					tail = mii_packet_get_data(buf,((length & 0xFFFFFFFC)/4)+1);

					endbytes = (length & 3);

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
#endif
					mii_packet_set_src_port(buf,ifnum);

					if (length < 60)
					{
#ifdef ETHERNET_COUNT_PACKETS
						ethernet_filtered_by_length++;
#endif
						mii_packet_set_filter_result(buf, 0);
						mii_packet_set_stage(buf,1);
					}
#ifdef ETHERNET_RX_CRC_ERROR_CHECK
					else if (~crc)
					{
#ifdef ETHERNET_COUNT_PACKETS
						ethernet_filtered_by_bad_crc++;
#endif
						mii_packet_set_filter_result(buf, 0);
						mii_packet_set_stage(buf,1);

					}
#endif
					else
					{
						int broadcast = is_broadcast(buf);
						int unicast = compare_mac(buf,mac);
						int res=0;
#if (NUM_ETHERNET_PORTS > 1) && !defined(DISABLE_ETHERNET_PORT_FORWARDING)
						if (!unicast) {
							res |= MII_FILTER_FORWARD_TO_OTHER_PORTS;
						}
#endif
#ifdef MAC_PROMISCUOUS
						if (1) {
#else
							if (broadcast || unicast) {
#endif
								int filter_result = mac_custom_filter_coerce(buf);
#ifdef ETHERNET_COUNT_PACKETS
								if (filter_result == 0) ethernet_filtered_by_user_filter++;
#endif
								res |= filter_result;
							} else {
#ifdef ETHERNET_COUNT_PACKETS
								ethernet_filtered_by_address++;
#endif
							}
							mii_packet_set_filter_result(buf, res);
							mii_packet_set_stage(buf, 1);
						}
					}
					break;
				} // end if (buf)
			} // end case()
		} // end select
	} // end while (1)



int mac_custom_filter_coerce1(unsigned int buf[])
{
  return mac_custom_filter(buf);
}
