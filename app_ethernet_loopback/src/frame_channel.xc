/*************************************************************************
 *
 * Ethernet MAC Layer Client Test Code
 * IEEE 802.3 MAC Client
 *
 *   File        : frame_channel.xc
 *
 *************************************************************************
 *
 * Copyright (c) 2008 XMOS Ltd.
 *
 * Copyright Notice
 *
 *************************************************************************
 *
 * Functions for passing an Ethernet frame over a channel.
 *
 *************************************************************************/

#include "frame_channel.h"
#include <print.h>

void pass_frame(chanend c, const unsigned char buffer[], int nbytes)
{
	master
	{
		int nwords;
		c <: nbytes;
		nwords = (nbytes >> 2) + 1;
#pragma unsafe arrays
		for (int i = 0; i < nwords; i++)
		{
			c <: (buffer, unsigned[])[i];
		}
	}
}

void fetch_frame(unsigned char buffer[], chanend c, int &nbytes)
{
	slave
	{
		int nwords;
		c :> nbytes;
		nwords = (nbytes >> 2) + 1;
#pragma unsafe arrays
		for (int i = 0; i < nwords; i++)
		{
			c :> (buffer, unsigned[])[i];
		}
	}
}

